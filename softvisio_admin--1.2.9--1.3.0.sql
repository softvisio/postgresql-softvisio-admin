\echo 'You need to use the following commands:'
\echo 'CREATE EXTENSION IF NOT EXISTS softvisio_admin CASCADE;'
\echo 'ALTER EXTENSION softvisio_admin UPDATE;'
\echo \quit

DROP PROCEDURE create_database ( text, text );

CREATE OR REPLACE PROCEDURE create_database ( p_name text, p_collate text DEFAULT 'C.UTF-8' ) AS $$
DECLARE
    v_password text;

BEGIN

    PERFORM dblink_connect( '_create_database_current', 'dbname=' || current_database() );

    -- check database exists
    IF EXISTS ( SELECT FROM pg_database WHERE datname = p_name ) THEN
        RAISE EXCEPTION 'Database already exists';
    END IF;

    -- if user is not exists
    IF NOT EXISTS ( SELECT FROM pg_roles WHERE rolname = p_name ) THEN

        -- generate password
        v_password := ( SELECT translate( encode( gen_random_bytes( 16 ), 'base64' ), '+/=', '-_' ) AS password );

        RAISE NOTICE 'Password: %', v_password;

        -- create user
        PERFORM dblink_exec( '_create_database_current', 'CREATE USER ' || quote_ident( p_name ) || ' WITH ENCRYPTED PASSWORD ' || quote_literal( v_password ), FALSE );
    ELSE
        RAISE NOTICE 'User already exists, you can set password manually';
    END IF;

    -- create database
    PERFORM dblink_exec( '_create_database_current', 'CREATE DATABASE ' || quote_ident( p_name ) || ' ENCODING ''UTF8'' LC_COLLATE ' || quote_literal( p_collate ) || ' LC_CTYPE ' || quote_literal( p_collate ) || ' TEMPLATE template0', FALSE );

    -- change database owner
    PERFORM dblink_exec( '_create_database_current', 'ALTER DATABASE ' || quote_ident( p_name ) || ' OWNER TO ' || quote_ident( p_name ), FALSE );

    -- grant user permissions to create schemas
    PERFORM dblink_exec( '_create_database_current', 'GRANT ALL PRIVILEGES ON DATABASE ' || quote_ident( p_name ) || ' TO ' || quote_ident( p_name ), FALSE );

    PERFORM dblink_connect( '_create_database', 'dbname=' || p_name );

    -- create schema
    PERFORM dblink_exec( '_create_database', 'CREATE SCHEMA AUTHORIZATION ' || quote_ident( p_name ), FALSE );

    -- create extensions in "public" schema
    -- PERFORM dblink_exec( '_create_database', 'CREATE EXTENSION pgcrypto CASCADE', FALSE );
    -- PERFORM dblink_exec( '_create_database', 'CREATE EXTENSION timescaledb CASCADE', FALSE );
    -- PERFORM dblink_exec( '_create_database', 'CREATE EXTENSION pg_hashids CASCADE', FALSE );

    PERFORM dblink_disconnect( '_create_database' );
    PERFORM dblink_disconnect( '_create_database_current' );

EXCEPTION WHEN OTHERS THEN
    IF '_create_database' = ANY ( dblink_get_connections() ) THEN
        PERFORM dblink_disconnect( '_create_database' );
    END IF;

    IF '_create_database_current' = ANY ( dblink_get_connections() ) THEN
        PERFORM dblink_disconnect( '_create_database_current' );
    END IF;

    RAISE;

END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION outdated_extensions () RETURNS TABLE (
    database text,
    extension text,
    installed_version text,
    default_version text
) AS $$
DECLARE
    _database text;
BEGIN
    CREATE TEMP TABLE _outdated_extensions_tmp (
        database text,
        extension text,
        installed_version text,
        default_version text
    ) ON COMMIT DROP;

    FOR _database IN
        SELECT datname FROM pg_database WHERE datistemplate = FALSE
    LOOP
        PERFORM dblink_connect( '_outdated_extensions', 'dbname=' || _database );

        INSERT INTO
            _outdated_extensions_tmp
        SELECT
            _database,
            *
        FROM dblink( '_outdated_extensions', '
            SELECT
                name,
                installed_version,
                default_version
            FROM
                pg_available_extensions
            WHERE
                installed_version IS NOT NULL
                AND installed_version != default_version
        ' ) AS t (
            extension text,
            installed_version text,
            default_version text
        );

        PERFORM dblink_disconnect( '_outdated_extensions' );
    END LOOP;

    RETURN QUERY SELECT * FROM _outdated_extensions_tmp;

EXCEPTION WHEN OTHERS THEN
    IF '_outdated_extensions' = ANY ( dblink_get_connections() ) THEN
        PERFORM dblink_disconnect( '_outdated_extensions' );
    END IF;

    RAISE;

END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_extensions () RETURNS TABLE (
    database text,
    extension text,
    old_version text,
    installed_version text,
    default_version text
) AS $$
DECLARE
    v_row record;
BEGIN
    CREATE TEMP TABLE _update_extensions_tmp (
        database text,
        extension text,
        old_version text,
        installed_version text,
        default_version text
    ) ON COMMIT DROP;

    FOR v_row IN
        SELECT * FROM outdated_extensions()
    LOOP
        PERFORM dblink_connect( '_update_extensions', 'dbname=' || v_row.database );

        -- test query, required to avoid exceptions when some extension can't be loaded
        IF ( SELECT * FROM dblink( '_update_extensions', 'SELECT 1', FALSE ) AS t ( test int2 ) ) THEN END IF;

        -- postgis
        IF v_row.extension = 'postgis' THEN
            IF ( ( SELECT * FROM dblink( '_update_extensions', 'SELECT postgis_extensions_upgrade()', FALSE ) AS t ( result text ) ) = '' ) THEN END IF;

        -- other extension
        ELSE
            PERFORM dblink_exec( '_update_extensions', 'ALTER EXTENSION ' || quote_ident( v_row.extension ) || ' UPDATE', FALSE );
        END IF;

        INSERT INTO
            _update_extensions_tmp
        ( database, extension, old_version, installed_version, default_version )
        VALUES
        (
            v_row.database,
            v_row.extension,
            v_row.installed_version,
            ( SELECT t.installed_version FROM dblink( '_update_extensions', 'SELECT installed_version FROM pg_available_extensions WHERE name = ' || quote_literal( v_row.extension ), FALSE ) AS t ( installed_version text ) ),
            v_row.default_version
        );

        PERFORM dblink_disconnect( '_update_extensions' );
    END LOOP;

    RETURN QUERY SELECT * FROM _update_extensions_tmp;

EXCEPTION WHEN OTHERS THEN
    IF '_update_extensions' = ANY ( dblink_get_connections() ) THEN
        PERFORM dblink_disconnect( '_update_extensions' );
    END IF;

    RAISE;

END;
$$ LANGUAGE plpgsql;
