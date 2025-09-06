from datetime import datetime
from airflow import DAG
from aurora_to_aurora_upsert_operator import AuroraToAuroraUpsertOperator

with DAG(
    dag_id='aurora-upsert-test',
    start_date=datetime(2025, 9, 1),
    schedule_interval='0 6 * * *',
    catchup=False,
    tags=['test'],
) as dag:

    aurora_upsert = AuroraToAuroraUpsertOperator(
        task_id = "test-task",
        aurora_src_conn_id='aurora_test',
        aurora_dest_conn_id='aurora_test',
        target_table='PUBLIC.TEST2',
        source_sql="SELECT ID, DESCR FROM PUBLIC.TEST",
        upsert_key=["ID"],
        batch_fetch_size=100,
        batch_commit_size=25,
        upsert_worker_count=3,
        max_queue_size=500
    )
    
    aurora_upsert
