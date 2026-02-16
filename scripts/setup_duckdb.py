#!/usr/bin/env python3
"""
Setup script to initialize DuckDB with required extensions.
This should be run once after installing dependencies.
"""
import duckdb
import sys
from pathlib import Path

def setup_duckdb_extensions(db_path='db_de.db'):
    """Install and load required DuckDB extensions."""
    print(f"Setting up DuckDB extensions for {db_path}...")

    try:
        con = duckdb.connect(db_path)

        # Install and load spatial extension
        print("Installing spatial extension...")
        con.execute('INSTALL spatial')
        con.execute('LOAD spatial')

        print("✓ Spatial extension installed and loaded successfully")

        con.close()
        return True

    except Exception as e:
        print(f"✗ Error setting up DuckDB extensions: {e}", file=sys.stderr)
        return False

if __name__ == '__main__':
    db_path = sys.argv[1] if len(sys.argv) > 1 else 'db_de.db'
    success = setup_duckdb_extensions(db_path)
    sys.exit(0 if success else 1)
