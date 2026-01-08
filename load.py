import pandas as pd
from sqlalchemy import create_engine

engine = create_engine(
    "mssql+pyodbc://sa:StrongPass123@localhost:1433/MondayCoffee"
    "?driver=ODBC+Driver+18+for+SQL+Server"
    "&TrustServerCertificate=yes"
)

files = [
    ("data/city.csv", "city"),
    ("data/products.csv", "products"),
    ("data/customers.csv", "customers"),
    ("data/sales.csv", "sales"),
]

for csv, table in files:
    df = pd.read_csv(csv)
    df.columns = df.columns.str.strip().str.lower()
    df.to_sql(table, engine, if_exists="append", index=False)
    print(f"Loaded {table}")
