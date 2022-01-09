# PostgreSQL admin package

## Install / update / drop

```
CREATE EXTENSION IF NOT EXISTS softvisio_admin CASCADE;

ALTER EXTENSION softvisio_admin UPDATE;

DROP EXTENSION IF EXISTS softvisio_admin;
```

## Build

```
gmake USE_PGXS=1 install
```

## Procedures

### create_database( database_name, collate? )

-   `database_name` <text\> Name of the database to create.
-   `collate?` <text> Database collate. Default: `"C.UTF-8"`.

-   Creates user with the random password, if not exists.
-   Creates database.
-   Grant priviledges.

Example:

```
CALL create_database( 'test', 'ru_UA.UTF-8' );
```

### update_extensions()

Updates currently installed extensions for all databases in the cluster.

Example:

```
CALL update_extensions();
```
