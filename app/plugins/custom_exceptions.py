
class ConnectionNotFoundException(Exception):
    """
    Raised when BaseHook.get_connection(conn_id: str) is called, but an Airflow Connection is not returned.
    """
    pass

class CannotInitializeHookException(Exception):
    """
    Raised when we are unable to initalize a custom hook.
    """
    def __init__(self,message="Unable to initalize a custom hook."):
        self.message=message
        super().__init__(self.message)



class MsSqlHookException(Exception):
    """
    Raised when we are unable to initalize a custom hook.
    """
    def __init__(self,message="Unable to initalize a custom hook."):
        self.message=message
        super().__init__(self.message)