"""
export_for_powerbi.py
Exports the 3 tables from the MySQL ipl_db database into ONE Excel workbook
(data/powerbi/ipl_powerbi.xlsx) for Power BI in the browser (app.powerbi.com).

Each table goes on its own sheet and is formatted as an Excel *Table*.
Power BI's Excel import only picks up data that is formatted as a Table.

Run from the project folder (venv active):
  python scripts/export_for_powerbi.py              # reads from MySQL (recommended)
  python scripts/export_for_powerbi.py --from-csv   # reads data/cleaned/*.csv instead

Linux/Ubuntu with the ipl_user account:
  MYSQL_USER=ipl_user python scripts/export_for_powerbi.py
"""
import getpass
import os
import sys
from urllib.parse import quote_plus

import pandas as pd

PROJECT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(PROJECT_DIR, "data", "powerbi")
OUT_FILE = os.path.join(OUT_DIR, "ipl_powerbi.xlsx")


def load_from_mysql():
    from sqlalchemy import create_engine

    host = os.environ.get("MYSQL_HOST", "localhost")
    port = os.environ.get("MYSQL_PORT", "3306")
    user = os.environ.get("MYSQL_USER", "root")
    password = os.environ.get("MYSQL_PASSWORD")
    if password is None:
        password = getpass.getpass(f"MySQL password for {user}@{host}: ")

    # quote_plus() makes special characters in the password (like @ or #) safe inside the URL
    url = f"mysql+mysqlconnector://{user}:{quote_plus(password)}@{host}:{port}/ipl_db"
    engine = create_engine(url)

    tables = {}
    for name in ["teams", "matches", "deliveries"]:
        print(f"Reading {name} from MySQL ...")
        query = f"SELECT * FROM {name}"
        if name == "deliveries":
            query += " ORDER BY delivery_id"
        tables[name] = pd.read_sql(query, engine)
    engine.dispose()
    return tables


def load_from_csv():
    clean = os.path.join(PROJECT_DIR, "data", "cleaned")
    print("Reading cleaned CSV files ...")
    matches = pd.read_csv(os.path.join(clean, "matches_cleaned.csv"))
    deliveries = pd.read_csv(os.path.join(clean, "deliveries_cleaned.csv"))
    teams = pd.read_csv(os.path.join(PROJECT_DIR, "data", "reference", "teams.csv"))
    # Use the same column names as the MySQL tables
    matches = matches.rename(columns={"id": "match_id", "date": "match_date"})
    deliveries = deliveries.rename(columns={"over": "over_index"})
    matches["match_date"] = pd.to_datetime(matches["match_date"])
    for col in ["result_margin", "target_runs", "toss_winner_won"]:
        matches[col] = matches[col].astype("Int64")
    return {"teams": teams, "matches": matches, "deliveries": deliveries}


def write_workbook(tables):
    os.makedirs(OUT_DIR, exist_ok=True)
    print(f"Writing {OUT_FILE} (2-3 minutes, please wait) ...")
    with pd.ExcelWriter(OUT_FILE, engine="xlsxwriter",
                        datetime_format="yyyy-mm-dd", date_format="yyyy-mm-dd") as writer:
        for name, df in tables.items():
            if "match_date" in df.columns:
                df["match_date"] = pd.to_datetime(df["match_date"])
            # Write the data WITHOUT a header row; add_table() writes the header for us
            df.to_excel(writer, sheet_name=name, index=False, header=False, startrow=1)
            sheet = writer.sheets[name]
            rows, cols = df.shape
            sheet.add_table(0, 0, rows, cols - 1, {
                "name": name,                                   # the table name Power BI shows
                "columns": [{"header": c} for c in df.columns],
                "style": "Table Style Light 9",
            })
            sheet.freeze_panes(1, 0)
            print(f"  sheet '{name}': {rows:,} rows x {cols} columns")
    size_mb = os.path.getsize(OUT_FILE) / 1_000_000
    print(f"Done! {OUT_FILE} ({size_mb:.1f} MB)")


if __name__ == "__main__":
    data = load_from_csv() if "--from-csv" in sys.argv else load_from_mysql()
    write_workbook(data)
