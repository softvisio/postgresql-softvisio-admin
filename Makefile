EXTENSION = softvisio_admin
DATA =	\
	softvisio_admin--1.0.0.sql

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
