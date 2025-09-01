from airflow.models import BaseOperator
from queue import Queue
from typing import Tuple, List, Any

import threading
from queue import Queue
from aurora_hook import AwsAuroraHook

SENTINEL = object()

# todo: logging and error handling


class AuroraUpsertWorker(threading.Thread):

    def __init__(
        self,
        queue: Queue[Tuple],
        db_hook: AwsAuroraHook,
        upsert_sql: str,
        batch_commit_size: int,
    ):
        super().__init__()
        self.queue = queue
        self.db_hook = db_hook
        self.upsert_sql = upsert_sql
        self.batch_commit_size = batch_commit_size

    def run(self):
        conn = self.db_hook.connect()
        cursor = None
        batch: List[Tuple[Any, ...]] = []

        try:
            cursor = self.db_hook.get_cursor()
            while True:
                item = self.queue.get()
                try:
                    if item is SENTINEL:
                        if batch:
                            self.db_hook.execute_write(cursor, self.upsert_sql, batch)
                        break

                    batch.append(item)

                    if len(batch) >= self.batch_commit_size:
                        self.db_hook.execute_write(cursor, self.upsert_sql, batch)
                        batch.clear()
                finally:
                    self.queue.task_done()

        finally:
            self.db_hook.close(conn, cursor)


class AuroraToAuroraUpsertOperator(BaseOperator):

    def __init__(
        self,
        aurora_src_conn_id: str,
        aurora_dest_conn_id: str,
        target_table: str,
        source_sql: str,
        batch_fetch_size: int = 10000,
        batch_commit_size: int = 1000,
        upsert_worker_count: int = 3,
        *args,
        **kwargs,
    ):
        super().__init__(self, *args, **kwargs)

        self.aurora_src_conn_id = aurora_src_conn_id
        self.aurora_dest_conn_id = aurora_dest_conn_id
        self.target_table = target_table
        self.source_sql = source_sql
        self.batch_fetch_size = batch_fetch_size
        self.batch_commit_size = batch_commit_size
        self.upsert_worker_count = upsert_worker_count

    def _build_upsert_sql(self):
        # here is where i'll build upsert SQL and validate the order of the columns in the fetch using cursor
        raise NotImplementedError

    def _cleanup_workers(self, w: threading.Thread):
        try:
            w.join()
            return True
        except Exception as e:
            # todo: log here
            return False

    def execute(self, context):

        upsert_sql = self._build_upsert_sql()

        src_hook = AwsAuroraHook(self.aurora_src_conn_id)
        dest_hook = AwsAuroraHook(self.aurora_dest_conn_id)
        read_cursor = None
        src_conn = src_hook.connect()

        try:
            read_cursor = src_hook.execute_read(src_conn, self.source_sql)

            q = Queue()
            workers = [
                AuroraUpsertWorker(q, dest_hook, upsert_sql, self.batch_commit_size)
                for _ in range(self.upsert_worker_count)
            ]

            for w in workers:
                w.start()

            while True:
                batch = src_hook.fetch_batch(read_cursor, self.batch_fetch_size)
                if not batch:
                    break
                for row in batch:
                    q.put(row)

            for _ in workers:
                q.put(SENTINEL)

            q.join()

        finally:
            all_workers_closed = True
            for w in workers:
                all_workers_closed = all_workers_closed and self._cleanup_workers(w)
                
            src_hook.close(src_conn, read_cursor)
            if all_workers_closed is False:
                # todo: logging/error handling
                raise
