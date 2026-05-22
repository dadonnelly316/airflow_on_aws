from airflow.models import BaseOperator
from queue import Queue
from typing import Tuple, List, Any, Union
import threading
import time
from queue import Queue
from aurora_hook import AwsAuroraHook
from datetime import datetime, timezone

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
    ):
        super().__init__()
        self.queue = queue
        self.db_hook = db_hook
        self.upsert_sql = upsert_sql

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
        updated_timestamp: bool = False,
        created_timestamp: bool = False,
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
        self.updated_timestamp = updated_timestamp
        self.created_timestamp = created_timestamp
        
        self.reserved_columns = ["UPDATED_TIMESTAMP",'CREATED_TIMESTAMP']
        
    # I'm going to set ts directly in merge to not waste read I/O by including in select
    # Also, i don't want to add it in params because looping through to add there is an extra O(n) operation
    def __check_ts_sql_injection(self, timestamp: datetime):
        
        if not isinstance(timestamp, datetime):
            raise Exception("SQL injection detected")
        
        if timestamp.year < 1 or timestamp.year > 9999:
            raise Exception("SQL injection dectected")
        
        return f"'{timestamp.isoformat()}'"
    

    def __validate_columns(self, target_table: str, src_query_cols: list[str], dest_hook: AwsAuroraHook) -> List[str]:
        err_msgs = []
        conn = dest_hook.connect()

        try:
            with dest_hook.get_cursor(conn) as cursor:
                cursor.execute("SELECT UPPER(COLUMN_NAME) AS COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE UPPER(TABLE_SCHEMA) || '.' || UPPER(TABLE_NAME) = %s", (target_table.upper(),))
                tgt_tbl_cols = {row[0] for row in cursor.fetchall()}
        finally:
            dest_hook.close(conn)
        
        invalid_columns = [col for col in src_query_cols if col not in tgt_tbl_cols]
        if invalid_columns:
            err_msgs.append(f"Invalid column names {','.join(invalid_columns)} is not valid in {target_table}. Valid options are {','.join(tgt_tbl_cols)}")
        
        reserved_columns = [col for col in src_query_cols if col in self.reserved_columns]
        if reserved_columns:
            err_msgs.append(f"Reserved column names {','.join(self.reserved_columns)} cannot be present in the source query")
        
        if self.created_timestamp and "CREATED_TIMESTAMP" not in tgt_tbl_cols:
            err_msgs.append(f"task set created_timestamp to True, but CREATED_TIMESTAMP column is not present in {target_table}")
            
        if self.updated_timestamp and "UPDATED_TIMESTAMP" not in tgt_tbl_cols:
            err_msgs.append(f"task set updated_timestamp to True, but UPDATED_TIMESTAMP column is not present in {target_table}")
            
        return err_msgs
 

    def _build_upsert_sql(self, column_mappings: Tuple) -> str:
        
        utc_now = datetime.now(timezone.utc)
        updated_ts = f",UPDATED_TIMESTAMP = {self.__check_ts_sql_injection(utc_now)}" if self.updated_timestamp else ""
        
        if self.created_timestamp:
            created_ts = f",CREATED_TIMESTAMP = {self.__check_ts_sql_injection(utc_now)}"
        elif self.created_timestamp is False and self.updated_timestamp is True:
            created_ts= ",UPDATED_TIMESTAMP = {self.__check_ts_sql_injection(utc_now)}" if self.updated_timestamp else ""
        else:
           created_ts= ""
        
        
        

        sql = f"""
            MERGE INTO {self.target_table} AS tgt
            USING (VALUES %s ) AS src ({','.join(column_mappings)})
                ON {' AND '.join([f'tgt.{col} = src.{col}' for col in self.upsert_key])}
            WHEN MATCHED THEN
                UPDATE SET
                    {', '.join([f'{col} = src.{col}' for col in column_mappings])} {updated_ts}
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
            err_msgs = self.__validate_columns(target_table=self.target_table, src_query_cols=column_mappings, dest_hook=dest_hook)
            
            if err_msgs:
                raise Exception("\n".join(err_msgs))
            
            
            upsert_sql = self._build_upsert_sql(column_mappings)

            q = Queue()
            workers = [
                AuroraUpsertWorker(
                    queue=q,
                    db_hook=dest_hook,
                    upsert_sql=upsert_sql,
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
