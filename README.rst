How to use
===========

::

    docker run -v /path/to/data:/var/lib/postgresql/data -p 5432:5432 yicodeplayer/pg-pipelinedb-timescaledb:pg11-timescaledb-1.3.2

Edit ``/path/to/data/postgresql.conf``: ::

    shared_preload_libraries = 'pipelinedb, timescaledb'

Enjoy.
