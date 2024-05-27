
import snowflake.connector
import openpyxl
import csv
import uuid
import glob
import os

from objects import OBJECTS

conn = snowflake.connector.connect(
    user = os.environ.get("SNOWFLAKE_USER", None),
    password = os.environ.get("SNOWFLAKE_PASSWORD", None),
    account = os.environ.get("SNOWFLAKE_ACCOUNT", None)
)

def generate_snowflake(conn):
    conn.cursor().execute("CREATE WAREHOUSE IF NOT EXISTS x_payment_devices_wh")
    conn.cursor().execute("USE WAREHOUSE x_payment_devices_wh")

    conn.cursor().execute("CREATE DATABASE IF NOT EXISTS x_payment_devices")
    conn.cursor().execute("USE DATABASE x_payment_devices")

    conn.cursor().execute("CREATE SCHEMA IF NOT EXISTS load")
    conn.cursor().execute("USE SCHEMA load")

def generate_create_table_sql(table_name, columns):
    columns_sql = ", ".join([f"{col_name} {col_type}" for col_name, col_type in columns.items()])
    create_table_sql = f"CREATE OR REPLACE TABLE {table_name} ({columns_sql});"
    return create_table_sql

def get_file_paths(base_dir, object):
    
    folder_path = os.path.join(base_dir, object)
    file_paths = glob.glob(os.path.join(folder_path, '*'))
    return file_paths

def convert_xlsx_to_csv(xlsx_file):
    wb = openpyxl.load_workbook(xlsx_file, data_only=True)
    sh = wb.active

    csv_filepath = f"/tmp/{uuid.uuid4()}.csv"

    with open(csv_filepath, 'w', newline="") as file_handle:
        csv_writer = csv.writer(file_handle)
        for row in sh.iter_rows(): # generator; was sh.rows
            csv_writer.writerow([str(cell.value) for cell in row])

    return csv_filepath

if __name__ == "__main__":

    generate_snowflake(conn)
    for table_name, columns in OBJECTS.items():
        create_table_sql = generate_create_table_sql(table_name, columns)
        print(f"Creating table : {table_name}")
        conn.cursor().execute(create_table_sql)

    SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
    FILES_DIR = os.path.join(SCRIPT_DIR, '..', 'files')

    for table in OBJECTS.keys():
        print(f"Processing {table} files...")
        files = get_file_paths(FILES_DIR, table)
        for file in files:
            print(f"Processing file : {file}")
            converted_file = convert_xlsx_to_csv(file)

            conn.cursor().execute(f'''PUT file://{converted_file} @%{table}''')
            conn.cursor().execute(f'''COPY INTO {table} FILE_FORMAT = (TYPE = 'CSV' FIELD_DELIMITER = ',' SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '\"')''')
            print(f"File uploaded!")
            os.remove(converted_file)

    print("All done!")

