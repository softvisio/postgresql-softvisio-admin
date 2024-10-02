\echo 'You need to use the following commands:'
\echo 'CREATE EXTENSION IF NOT EXISTS softvisio_admin CASCADE;'
\echo 'ALTER EXTENSION softvisio_admin UPDATE;'
\echo \quit

CREATE FUNCTION outdated_extensions() RETURNS TABLE (
    database text,
    extension text,
    installed_version text,
    default_version text
) AS $$
DECLARE
    _database text;
BEGIN
    CREATE TEMP TABLE tmp (
        database text,
        extension text,
        installed_version text,
        default_version text
    ) ON COMMIT DROP;


    FOR _database IN
        SELECT datname FROM pg_database WHERE datistemplate = FALSE
    LOOP
        PERFORM dblink_connect( 'dbname=' || _database );

        INSERT INTO
            tmp
        SELECT
            _database,
            *
        FROM dblink( '
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

        PERFORM dblink_disconnect();
    END LOOP;

    RETURN QUERY SELECT * FROM tmp;
END;
$$ LANGUAGE plpgsql;
