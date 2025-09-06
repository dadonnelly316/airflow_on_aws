from airflow.models import BaseOperator
from queue import Queue
from typing import Tuple, List, Any
import threading
import time
from queue import Queue
from aurora_hook import AwsAuroraHook

SENTINEL = object()

# todo: logging and error handling
# todo: fix type annotation for tules
# todo: need to allow queue to exit when i hit a write exception. otherwise it will hang
# need a more efficient way to fetch batches and flatten without using O(n) operations. For example, i flatten batches in reader. Then i loop through and flatten rows in worker

# todo: use var named uncommited_batchs_buffer
class AuroraUpsertWorker(threading.Thread):

    def __init__(
        self,
        queue: Queue[Tuple],
        db_hook: AwsAuroraHook,
        upsert_sql: str,
        num_cols: int,
    ):
        super().__init__()
        self.queue = queue
        self.db_hook = db_hook
        self.upsert_sql = upsert_sql
        self.num_cols = num_cols

    # note: this is hanging when we get write errors. Specifically with cursor already closed error. also handle it to exit right away. Figure out why
    def run(self):
        conn = self.db_hook.connect()
        cursor = None

        try:
            cursor = self.db_hook.get_cursor(conn)
            while True:
                batch = self.queue.get()
                try:
                    if batch is SENTINEL:
                        break
                    self.db_hook.execute_write(cursor, self.upsert_sql, batch)
                finally:
                    self.queue.task_done()
        except:
            raise

        finally:
            self.db_hook.close(conn, cursor)


class AuroraToAuroraUpsertOperator(BaseOperator):

    def __init__(
        self,
        aurora_src_conn_id: str,
        aurora_dest_conn_id: str,
        target_table: str,
        source_sql: str,
        upsert_key: List[str],
        batch_fetch_size: int = 10000,
        buffer_size: int = 10,
        upsert_worker_count: int = 3,
        add_loadtime: bool = True,
        *args,
        **kwargs,
    ):
        super().__init__(**kwargs)

        self.aurora_src_conn_id = aurora_src_conn_id
        self.aurora_dest_conn_id = aurora_dest_conn_id
        self.target_table = target_table
        self.source_sql = source_sql
        self.upsert_key = upsert_key
        self.batch_fetch_size = batch_fetch_size
        self.buffer_size = buffer_size
        self.upsert_worker_count = upsert_worker_count
        self.add_loadtime = add_loadtime

    def _build_upsert_sql(self, column_mappings: Tuple) -> str:
        # here is where i'll build upsert SQL and validate the order of the columns in the fetch using cursor
        # need to check add_loadtime param. also throw error if LOADTIME is in cursor fetch since it's reserved

        sql = f"""
            MERGE INTO {self.target_table} AS tgt
            USING (VALUES %s ) AS src ({','.join(column_mappings)})
                ON {' AND '.join([f'tgt.{col} = src.{col}' for col in self.upsert_key])}
            WHEN MATCHED THEN
                UPDATE SET
                    {', '.join([f'{col} = src.{col}' for col in column_mappings])}
            WHEN NOT MATCHED THEN
                INSERT ({','.join(column_mappings)})
                VALUES ({','.join([f'src.{x}' for x in column_mappings])});
        """

        return sql

    def _cleanup_workers(self, w: threading.Thread):
        try:
            w.join()
            return True
        except Exception as e:
            # todo: log here
            return False

    def execute(self, context):
        src_hook = AwsAuroraHook(conn_id=self.aurora_src_conn_id)
        dest_hook = AwsAuroraHook(conn_id=self.aurora_dest_conn_id)
        read_cursor = None
        src_conn = src_hook.connect()
        workers = []

        try:
            read_cursor = src_hook.execute_read(src_conn, self.source_sql)
            column_mappings = src_hook.get_column_mapping(read_cursor)
            upsert_sql = self._build_upsert_sql(column_mappings)

            q = Queue()
            workers = [
                AuroraUpsertWorker(
                    queue=q,
                    db_hook=dest_hook,
                    upsert_sql=upsert_sql,
                    num_cols=len(column_mappings),
                )
                for _ in range(self.upsert_worker_count)
            ]

            for w in workers:
                w.start()

            while True:

                while q.qsize() > self.buffer_size:
                    # todo: add logging to say we're waiting for the workers to catch up
                    time.sleep(1)

                batch = src_hook.fetch_batch(read_cursor, self.batch_fetch_size)
                if not batch:
                    break

                q.put(batch)

            for _ in workers:
                q.put(SENTINEL)

            q.join()

        finally:
            all_workers_closed = True
            # todo: workers might've not been created yet...
            for w in workers:
                all_workers_closed = all_workers_closed and self._cleanup_workers(w)

            src_hook.close(src_conn, read_cursor)
            if all_workers_closed is False:
                # todo: logging/error handling
                raise
