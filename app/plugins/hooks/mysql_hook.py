from airflow.hooks.base import BaseHook
from airflow.models.connection import Connection
from custom_exceptions import ConnectionNotFoundException

from mysql import connector
import CannotInitializeHookException

# tocheck - commit transactions? 
# todo - multiple processes
# todo - add retries

# todo - can i create a sidecar that holds a mysql connection pool?

# class MySqlHook(BaseHook):
class MySqlHook:
    
    def __init__(self, my_sql_conn):
        # todo - import type for conn
        self.my_sql_conn=my_sql_conn

        # todo - can i have typing on this list?
        self.opened_cursors = []

    def fetch_all(self, sql: str):
        pass

    def fetch_batch(self,sql: str, batch_size: 5000):
        pass

    def execute(self, sql: str):
        pass


class MySqlContext(BaseHook):

    def __init__(self, mysql_conn_id: str, auto_commit: bool=True, *args, **kwargs):
        self.mysql_conn_id=mysql_conn_id
        self.auto_commit=auto_commit
        super(MySqlContext, self).__init__(*args,**kwargs)

    def __enter__(self) -> MySqlHook:
        mysql_hook = self.get_mysql_hook()
        self.conn = connector(user="", password="", host="", port="", autocommit="", database="")

        try:
            self.mySqlHook=MySqlHook(my_sql_conn=self.conn)
            return self.MySqlHook

        except:
            self.conn.close()
            raise CannotInitializeHookException("Unable to initalize the MySql hook.")

    def __exit__(self,exc_type, exc_value, exc_traceback):
        # todo - can i improve error handling here? what if a cursor can't close?
        try:
            for cursor in self.MySqlHook.opened_cursors:
                cursor.close()
        finally:
            self.conn.close()





    # todo - check what happens when the requested conn_id isn't found. is not None? Will my Exceptions work?
    # make custom_exceptions importable everywhere with a namespace package
    def get_mysql_hook(self) -> Connection:
        conn = self.get_connection(self.mysql_conn_id)
        assert isinstance(conn, Connection), raise ConnectionNotFoundException
        return self.get_connection(self.mysql_conn_id)




    