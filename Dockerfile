FROM postgres:latest as builder

ENV DEPS "git build-essential cmake postgresql-server-dev-11 libssl-dev libkrb5-dev wget libtool autoconf automake pkg-config ca-certificates"
# Set up a build environment
RUN set -ex;\
    deps="$DEPS";\
    sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list;\
    apt-get update;\
	apt-get install -y --no-install-recommends $deps;

WORKDIR /
RUN set -ex;\
    wget https://github.com/zeromq/libzmq/releases/download/v4.2.5/zeromq-4.2.5.tar.gz; \
    tar -xvf zeromq-4.2.5.tar.gz; \
    cd zeromq-4.2.5/; \
    ./autogen.sh;\
    ./configure CPPFLAGS=-DPIC CFLAGS=-fPIC CXXFLAGS=-fPIC LDFLAGS=-fPIC --prefix=/usr ; \
    make ;\
    make install

ADD ./pipelinedb /pipelinedb
WORKDIR /pipelinedb
RUN make USE_PGXS=1

ADD ./timescaledb /timescaledb
WORKDIR /timescaledb
RUN set -ex;\
    mkdir build;\
    cd build;\
    cmake -DREGRESS_CHECKS=OFF ..;\
    make

# Package the runner
FROM postgres:latest

COPY --from=builder /pipelinedb/pipelinedb.so /usr/lib/postgresql/11/lib/
COPY --from=builder /pipelinedb/pipelinedb.control /pipelinedb/pipelinedb--1.0.0--1.1.0.sql /pipelinedb/pipelinedb--1.0.0.sql /usr/share/postgresql/11/extension/

COPY --from=builder /timescaledb/build/src/timescaledb-1.3.2.so /timescaledb/build/tsl/src/timescaledb-tsl-1.3.2.so /timescaledb/build/src/loader/timescaledb.so /usr/lib/postgresql/11/lib/
COPY --from=builder /timescaledb/build/timescaledb.control /timescaledb/build/sql/timescaledb--1.3.2.sql /usr/share/postgresql/11/extension/

RUN sed -i -e"s/^#shared_preload_libraries = ''.*$/shared_preload_libraries = 'timescaledb, pipelinedb, pg_stat_statements'/" /usr/share/postgresql/$PG_MAJOR/postgresql.conf.sample; \
    sed -i -e"s/^#max_worker_processes =.*$/max_worker_processes = 20/" /usr/share/postgresql/$PG_MAJOR/postgresql.conf.sample
