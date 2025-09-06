from airflow.hooks.base import BaseHook
from airflow.models import Connection
from typing import List, Optional, Tuple, Any
from psycopg2.extensions import cursor as PsycopgCursor, connection
from tenacity import retry, stop_after_attempt, wait_exponential
import psycopg2


# https://github.com/aws/aws-advanced-python-wrapper

# todo: logging and error handling
# todo: use aws advanced wrapper


class AwsAuroraHook(BaseHook):

    def __init__(
        self, conn_id, auto_commit: bool = True, target_driver: str = "psycopg2"
    ):
        # todo - import type for conn
        self.conn_id = conn_id
        self.auto_commit = auto_commit
        self.target_driver = target_driver

    def get_conn(self) -> Connection:
        conn = self.get_connection(self.conn_id)
        return conn

    @retry(
        stop=(stop_after_attempt(5)), wait=wait_exponential(multiplier=2, min=4, max=10)
    )
    def connect(self) -> connection:
        aurora_conn = self.get_conn()
        conn = None

        try:

            conn = psycopg2.connect(
                user=aurora_conn.login,
                password=aurora_conn.password,
                host=aurora_conn.host,
                port=aurora_conn.port,
                dbname=aurora_conn.schema,
            )

            conn.autocommit = self.auto_commit

            return conn

        except Exception as e:
            if conn is not None:
                conn.close()
            raise

    @retry(
        stop=(stop_after_attempt(5)), wait=wait_exponential(multiplier=2, min=4, max=10)
    )
    def fetch_batch(self, cursor: PsycopgCursor, batch_size: int = 5000) -> List[Tuple]:
        try:
            batch = cursor.fetchmany(size=batch_size)
            return batch
        except:
            cursor.close()
            # todo: logging/error handling
            raise

    @retry(
        stop=(stop_after_attempt(5)), wait=wait_exponential(multiplier=2, min=4, max=10)
    )
    def execute_read(
        self,
        conn: connection,
        sql: str,
    ) -> PsycopgCursor:
        cursor = conn.cursor()
        try:
            cursor.execute(sql)
            return cursor
        except:
            cursor.close()
            # todo: logging/error handling
            raise

    # todo: connection isn't being closed properly here
    @retry(
        stop=(stop_after_attempt(5)), wait=wait_exponential(multiplier=2, min=4, max=10)
    )
    def execute_write(
        self,
        cursor: PsycopgCursor,
        sql: str,
        params: List[Tuple[Any, ...]],
    ) -> int:
        try:
            cursor.execute(sql, params)
            return cursor.rowcount
        except Exception as e:
            print(e)
            cursor.close()
            # todo: logging/error handling
            raise

    @retry(
        stop=(stop_after_attempt(5)), wait=wait_exponential(multiplier=2, min=4, max=10)
    )
    def get_cursor(self, conn: connection) -> PsycopgCursor:
        return conn.cursor()

    @retry(
        stop=(stop_after_attempt(5)), wait=wait_exponential(multiplier=2, min=4, max=10)
    )
    def get_column_mapping(self, cursor: PsycopgCursor) -> Tuple:
        return tuple(desc[0] for desc in cursor.description)

    @retry(
        stop=(stop_after_attempt(5)), wait=wait_exponential(multiplier=2, min=4, max=10)
    )
    def close(self, conn: connection, cursor: Optional[PsycopgCursor] = None) -> None:
        try:
            if cursor is not None:
                cursor.close()
        finally:
            conn.close()
