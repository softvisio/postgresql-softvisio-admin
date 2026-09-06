EXTENSION = softvisio_admin
DATA =	\
	softvisio_admin--1.2.0.sql \
	softvisio_admin--1.2.0--1.2.1.sql \
	softvisio_admin--1.2.1--1.2.2.sql \
	softvisio_admin--1.2.2--1.2.3.sql \
	softvisio_admin--1.2.3--1.2.4.sql \
	softvisio_admin--1.2.4--1.2.5.sql \
	softvisio_admin--1.2.5--1.2.6.sql \
	softvisio_admin--1.2.6--1.2.9.sql \
	softvisio_admin--1.2.9--1.3.0.sql \
	softvisio_admin--1.3.0--1.3.1.sql \
	softvisio_admin--1.3.1--1.4.0.sql \
	softvisio_admin--1.4.0.sql \
	softvisio_admin--1.4.0--1.4.1.sql \
	softvisio_admin--1.4.1--1.4.2.sql \
	softvisio_admin--1.4.2--1.5.0.sql \
	softvisio_admin--1.5.0.sql \
	softvisio_admin--1.5.0--1.5.1.sql

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
