from airflow.hooks.base import BaseHook
from airflow.models.connection import Connection
from custom_exceptions import ConnectionNotFoundException, MsSqlHookException

from mysql import connector
import CannotInitializeHookException

# tocheck - commit transactions? 
# todo - multiple processes
# todo - add retries

# todo - can i create a sidecar that holds a mysql connection pool?

# get mysql hook warnings/and errors

# do concurrent upserts

# class MySqlHook(BaseHook):
class MySqlHook:
    
    def __init__(self, my_sql_conn):
        # todo - import type for conn
        self.my_sql_conn=my_sql_conn

        # todo - can i have typing on this list?
        self.opened_cursors = {}

    def open_cursor(self, is_buffered: bool = True)-> int:
        cursor = self.my_sql_conn.cursor(buffered=is_buffered)
        try:
            memory_address=id(cursor)
            self.opened_cursors[memory_address]=cursor
            return memory_address
        except:
            cursor.close()
            raise MsSqlHookException

    def fetch_all(self, sql: str, cursor_id: int):
        cursor=self.opened_cursors[cursor_id]
        try:
            cursor.execute(sql)
            output=cursor.fetchall()
        finally:
            cursor.close()
            del self.opened_cursors[cursor_id]

        return output

    def fetch_batch(self, cursor_id: int, batch_size: int = 5000):
        try:
            batch = self.opened_cursors[cursor_id].fetchmany(size=batch_size)
            if batch is None:
                self.opened_cursors[cursor_id].close()
                del self.opened_cursors[cursor_id]

            return batch
        
        except:
            self.opened_cursors[cursor_id].close()
            raise MsSqlHookException
            
        

    def execute(self, cursor_id: int, sql: str):
        try:
            self.opened_cursors[cursor_id].execute(sql)
        except:
            self.opened_cursors[cursor_id].close()
            raise MsSqlHookException


class MySqlContext(BaseHook):

    def __init__(self, mysql_conn_id: str, auto_commit: bool=True, *args, **kwargs):
        self.mysql_conn_id=mysql_conn_id
        self.auto_commit=auto_commit
        super(MySqlContext, self).__init__(*args,**kwargs)

    def __call__(self, raise_on_warnings: bool = False):
        self.self.raise_on_warnings = True
        return self

    def __enter__(self) -> MySqlHook:
        mysql_hook = self.get_mysql_hook()
        self.conn = connector(user="", password="", host="", port="", autocommit="", database="")

        try:
            self.conn.raise_on_warnings=self.raise_on_warnings
            self.mySqlHook=MySqlHook(my_sql_conn=self.conn)
            return self.MySqlHook

        except:
            self.conn.close()
            raise CannotInitializeHookException("Unable to initalize the MySql hook.")

    def __exit__(self,exc_type, exc_value, exc_traceback):
        # todo - can i improve error handling here? what if a cursor can't close?
        try:
            for cursor in self.MySqlHook.opened_cursors.values():
                cursor.close()
        finally:
            self.conn.close()





    # todo - check what happens when the requested conn_id isn't found. is not None? Will my Exceptions work?
    # make custom_exceptions importable everywhere with a namespace package
    def get_mysql_hook(self) -> Connection:
        conn = self.get_connection(self.mysql_conn_id)
        assert isinstance(conn, Connection), raise ConnectionNotFoundException
        return self.get_connection(self.mysql_conn_id)




    