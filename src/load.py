
import os
import json
from pathlib import Path

import snowflake.connector
from dotenv import load_dotenv


# STEP 1: Set project paths
BASE_DIR = Path(__file__).resolve().parent.parent
RAW_FOLDER = BASE_DIR / "data" / "raw"

# Load environment variables
load_dotenv(BASE_DIR / ".env")


# STEP 2: Connect to Snowflake
conn = snowflake.connector.connect(
    account=os.getenv("SNOWFLAKE_ACCOUNT"),
    user=os.getenv("SNOWFLAKE_USER"),
    password=os.getenv("SNOWFLAKE_PASSWORD"),
    warehouse=os.getenv("SNOWFLAKE_WAREHOUSE"),
    database=os.getenv("SNOWFLAKE_DATABASE"),
    schema=os.getenv("SNOWFLAKE_SCHEMA")
)

print("Successfully connected to Snowflake!")

cursor = conn.cursor()


try:

    # STEP 3: Automatically create raw tables

    tables = ["PRODUCTS", "USERS", "CARTS"]

    for table in tables:

        create_sql = f"""
        CREATE TABLE IF NOT EXISTS {table}_RAW (
            DATA VARIANT,
            SOURCE_FILE VARCHAR,
            LOADED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
        )
        """

        cursor.execute(create_sql)

        print(f"{table}_RAW table is ready!")


    # STEP 4: Connect JSON files to Snowflake tables

    files = {
        "PRODUCTS": "data_products.json",
        "USERS": "data_users.json",
        "CARTS": "data_carts.json"
    }


    # STEP 5: Read and load JSON records

    for table, filename in files.items():

        file_path = RAW_FOLDER / filename

        # Check if the file exists
        if not file_path.exists():
            raise FileNotFoundError(f"File not found: {file_path}")

        # Read JSON data
        with open(file_path, "r") as file:
            records = json.load(file)

        # Remove previous records from this source file
        cursor.execute(
            f"DELETE FROM {table}_RAW WHERE SOURCE_FILE = %s",
            (filename,)
        )

        # Insert JSON records into Snowflake
        insert_sql = f"""
        INSERT INTO {table}_RAW (DATA, SOURCE_FILE)
        SELECT PARSE_JSON(%s), %s
        """

        for record in records:

            json_record = json.dumps(record)

            cursor.execute(
                insert_sql,
                (json_record, filename)
            )

        print(f"Loaded {len(records)} records into {table}_RAW!")


    # STEP 6: Commit changes
    conn.commit()

    print("All JSON data loaded successfully!")


except Exception as error:

    conn.rollback()

    print("Error loading data:", error)
    raise

finally:

    # STEP 7: Close connection
    cursor.close()
    conn.close()

    print("Snowflake connection closed!")
