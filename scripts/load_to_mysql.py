"""
load_to_mysql.py
Loads data/cleaned/matches_cleaned.csv and deliveries_cleaned.csv into the MySQL ipl_db database.

Before running:
  1. Run notebooks/02_data_cleaning_eda.ipynb (creates the cleaned CSVs)
  2. Run sql/01_create_database.sql in MySQL Workbench (creates the tables)

Run from the project folder (with the venv activated):
  python scripts/load_to_mysql.py

The script asks for your MySQL password. The password is never saved or hard-coded.
"""
import getpass
import os
import sys

import mysql.connector
import pandas as pd

# ---------- connection settings (change them here, or set environment variables) ----------
HOST = os.environ.get("MYSQL_HOST", "localhost")
PORT = int(os.environ.get("MYSQL_PORT", "3306"))
USER = os.environ.get("MYSQL_USER", "root")
DATABASE = "ipl_db"

PROJECT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CLEAN_DIR = os.path.join(PROJECT_DIR, "data", "cleaned")

BATCH_SIZE = 5000   # send rows to MySQL in groups of 5000 (much faster than one at a time)


def read_clean_csv(filename, rename):
    """Read a cleaned CSV, rename columns to match the MySQL table and turn NaN into None (NULL)."""
    path = os.path.join(CLEAN_DIR, filename)
    if not os.path.exists(path):
        sys.exit(f"File not found: {path}\nRun notebooks/02_data_cleaning_eda.ipynb first.")
    df = pd.read_csv(path).rename(columns=rename)
    # MySQL does not understand NaN, so blank cells must be sent as None (which becomes NULL)
    df = df.astype(object).where(df.notna(), None)
    return df


def insert_dataframe(cursor, conn, table, df):
    """INSERT every row of df into table, in batches."""
    columns = ", ".join(f"`{c}`" for c in df.columns)
    placeholders = ", ".join(["%s"] * len(df.columns))      # %s = "a value goes here"
    sql = f"INSERT INTO {table} ({columns}) VALUES ({placeholders})"

    rows = [tuple(r) for r in df.itertuples(index=False, name=None)]
    for start in range(0, len(rows), BATCH_SIZE):
        cursor.executemany(sql, rows[start:start + BATCH_SIZE])
        conn.commit()                                        # save this batch permanently
        print(f"  {table}: {min(start + BATCH_SIZE, len(rows)):,} / {len(rows):,} rows", end="\r")
    print()


def main():
    password = os.environ.get("MYSQL_PASSWORD")
    if password is None:
        password = getpass.getpass(f"MySQL password for {USER}@{HOST}: ")   # typing is hidden

    conn = mysql.connector.connect(host=HOST, port=PORT, user=USER, password=password, database=DATABASE)
    cursor = conn.cursor()
    print(f"Connected to MySQL {conn.server_info} / database '{DATABASE}'")

    matches = read_clean_csv("matches_cleaned.csv", {"id": "match_id", "date": "match_date"})
    deliveries = read_clean_csv("deliveries_cleaned.csv", {"over": "over_index"})

    # Empty the tables first so that running the script twice does not create duplicate rows.
    # deliveries is the child table, so it must be emptied before matches.
    cursor.execute("DELETE FROM deliveries")
    cursor.execute("DELETE FROM matches")
    conn.commit()

    print("Loading matches ...")
    insert_dataframe(cursor, conn, "matches", matches)        # parent table first
    print("Loading deliveries ... (about 1 minute)")
    insert_dataframe(cursor, conn, "deliveries", deliveries)  # then the child table

    for table in ["teams", "matches", "deliveries"]:
        cursor.execute(f"SELECT COUNT(*) FROM {table}")
        print(f"{table:<11}: {cursor.fetchone()[0]:>7,} rows")

    cursor.close()
    conn.close()
    print("Done! Expected: teams 15, matches 1,095, deliveries 260,920")


if __name__ == "__main__":
    main()
