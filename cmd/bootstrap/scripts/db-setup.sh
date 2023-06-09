#!/bin/bash

set -e

migrate -path=/migrations -database=$POSTGRES_DB_DSN up

psql -v ON_ERROR_STOP=1 $POSTGRES_DB_DSN <<-EOSQL
    DO \$\$
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname= 'crest_admin') THEN
            CREATE ROLE crest_admin WITH LOGIN PASSWORD '$CREST_ADMIN_PASSWORD';
            GRANT INSERT ON countries TO crest_admin;
            GRANT SELECT ON countries TO crest_admin;
            GRANT ALL ON SEQUENCE public.countries_id_seq TO crest_admin;
        ELSE
            RAISE NOTICE 'Role crest_admin already exists, skipping...';
        END IF;

        IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname= 'crest_api') THEN
            CREATE ROLE crest_api WITH LOGIN PASSWORD '$CREST_API_PASSWORD';
            GRANT SELECT ON countries TO crest_api;
        ELSE
            RAISE NOTICE 'Role crest_api already exists, skipping...';
        END IF;
    END 
    \$\$
    ;        

EOSQL

bootstrap -d "$POSTGRES_DB_DSN"