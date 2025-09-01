from airflow.hooks.base import BaseHook
from aws_advanced_python_wrapper import AwsWrapperConnection
from airflow.models import Connection
from typing import List, Optional, Tuple, Any
from psycopg2.extensions import cursor as PsycopgCursor


# https://github.com/aws/aws-advanced-python-wrapper

# todo: logging and error handling


class AwsAuroraHook(BaseHook):

    def __init__(self, conn_id):
        # todo - import type for conn
        self.conn_id = conn_id

    def get_conn(self) -> Connection:
        conn = self.get_connection(self.aurora_conn_id)
        return conn

    def connect(self) -> AwsWrapperConnection:
        aurora_conn = self.get_conn()
        conn = AwsWrapperConnection.connect(
            user=aurora_conn.login,
            password=aurora_conn.password,
            host=aurora_conn.host,
            port=aurora_conn.port,
            autocommit=self.auto_commit,
            database=aurora_conn.schema,
        )

        return conn

    def fetch_batch(self, cursor: PsycopgCursor, batch_size: int = 5000) -> List[Tuple]:
        try:
            batch = cursor.fetchmany(size=batch_size)
            return batch
        except:
            cursor.close()
            raise

    def execute_read(
        self,
        conn: AwsWrapperConnection,
        sql: str,
    ) -> PsycopgCursor:
        cursor = conn.cursor()
        try:
            cursor.execute(sql)
            return cursor
        except:
            cursor.close()
            raise

    def execute_write(
        self,
        cursor: PsycopgCursor,
        sql: str,
        params: List[Tuple[Any, ...]],
    ) -> int:
        try:
            cursor.executemany(sql, params)
            return cursor.rowcount
        except:
            cursor.close()
            raise

    def get_cursor(conn: AwsWrapperConnection) -> PsycopgCursor:
        return conn.cursor()

    def get_column_mapping(cursor: PsycopgCursor) -> Tuple:
        return tuple(desc[0] for desc in cursor.description)

    def close(
        self, conn: AwsWrapperConnection, cursor: Optional[PsycopgCursor] = None
    ) -> None:
        try:
            if cursor is not None:
                cursor.close()
        finally:
            conn.close()
