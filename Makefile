EXTENSION = softvisio_admin
DATA =	\
	softvisio_admin--1.2.0.sql \
	softvisio_admin--1.2.0-1.2.1.sql

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
