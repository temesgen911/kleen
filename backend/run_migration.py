"""Script to execute 0001_initial_schema.sql directly on Supabase PostgreSQL."""

import os
import sys
import psycopg2
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("SYNC_DATABASE_URL")
if not DATABASE_URL:
    print("Error: SYNC_DATABASE_URL is not set.")
    sys.exit(1)

SQL_FILE = os.path.join(os.path.dirname(__file__), "migrations", "0001_initial_schema.sql")

def run_migration():
    print(f"Connecting to Supabase PostgreSQL...")
    try:
        conn = psycopg2.connect(DATABASE_URL)
        conn.autocommit = True
        cursor = conn.cursor()
        
        print(f"Reading {SQL_FILE}...")
        with open(SQL_FILE, "r", encoding="utf-8") as f:
            sql = f.read()
        
        print("Executing migration statements on Supabase...")
        cursor.execute(sql)
        
        # Verify created tables
        cursor.execute("""
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public' 
            ORDER BY table_name;
        """)
        tables = [row[0] for row in cursor.fetchall()]
        print(f"\nMigration successful! Tables in public schema ({len(tables)}):")
        for t in tables:
            print(f"  - {t}")
            
        cursor.close()
        conn.close()
        print("\nAll tables and RLS policies created successfully on Supabase!")
    except Exception as e:
        print(f"Migration error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    run_migration()
