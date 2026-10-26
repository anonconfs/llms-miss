# File created by chatgpt. This script will run automatically when the PostgreSQL container starts for the first time and create a new database.


#!/bin/bash
set -e

# Connect to PostgreSQL and create the database
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
    CREATE DATABASE sample_db;
EOSQL
