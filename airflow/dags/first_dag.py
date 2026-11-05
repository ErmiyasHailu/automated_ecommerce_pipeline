
from airflow.sdk import dag, task
from airflow.sdk.bases.hook import BaseHook
from datetime import datetime
import subprocess


@dag(
    dag_id="first_dag",
    start_date=datetime(2026, 11, 4),
    schedule=None,
    catchup=False
)
def my_first_dag():

    @task
    def extract():
        print("Starting API extraction...")

        subprocess.run(
            ["python", "/opt/airflow/project/src/extract.py"],
            check=True
        )

        print("API extraction completed successfully!")

    @task
    def load():
        print("Checking Snowflake connection...")

        conn = BaseHook.get_connection("snowflake_default")

        print("Snowflake connection found!")
        print("Host:", conn.host)
        print("Login:", conn.login)
        print("Schema:", conn.schema)

        print("Ready to load data into Snowflake.")

    @task
    def transform():
        print("Transform task is ready.")
        print("Next: execute SQL transformations in Snowflake.")

    extract_task = extract()
    load_task = load()
    transform_task = transform()

    extract_task >> load_task >> transform_task


my_first_dag()
