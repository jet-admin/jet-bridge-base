FROM python:3.7.6-alpine3.11

RUN apk add --no-cache \
    mariadb-dev>=10.4.15-r0 \
    jpeg-dev>=8-r6 \
    zlib-dev>=1.2.11-r3 \
    gcc>=9.3.0-r0 \
    g++>=9.3.0-r0 \
    make>=4.2.1-r2 \
    musl-dev>=1.1.24-r3 \
    postgresql-dev>=12.5-r0 \
    postgresql-libs>=12.5-r0 \
    unixodbc-dev>=2.3.7-r2 \
    freetds-dev>=1.1.20-r0 \
    gdal-dev>=3.0.3-r0 \
    geos-dev>=3.8.0-r0 \
    proj-dev>=6.2.1-r0 \
    libffi-dev>=3.2.1-r6 \
    autoconf>=2.69-r2 \
    bash>=5.0.11-r1 \
    bison>=3.4.2-r0 \
    boost-dev>=1.71.0-r1 \
    cmake>=3.15.5-r0 \
    flex>=2.6.4-r2 \
    libressl-dev>=3.0.2-r0 \
    openssh>=8.1_p1-r1

#RUN addgroup -S jet && adduser -S -G jet jet
ENV CRYPTOGRAPHY_DONT_BUILD_RUST=1
RUN pip install --no-cache-dir \
    bcrypt==3.2.2 \
    psycopg2==2.8.4 \
    mysqlclient==1.4.6 \
    pyodbc==4.0.30 \
    GeoAlchemy2==0.6.2 \
    Shapely==1.6.4 \
    cryptography==3.4.1 \
    SQLAlchemy==1.4.27 \
    paramiko==2.8.1 \
    sshtunnel==0.4.0 \
    graphene==2.1.9 \
    six==1.16.0 \
    pytest==7.1.1 \
    numpy==1.21.6 \
    cython==0.29.28 \
    sentry-sdk==1.13.0 \
    aiocontextvars==0.2.2

RUN mkdir /arrow \
    && wget -q https://github.com/apache/arrow/archive/apache-arrow-6.0.1.tar.gz -O /tmp/apache-arrow.tar.gz \
    && tar -xvf /tmp/apache-arrow.tar.gz -C /arrow --strip-components 1 \
    && mkdir -p /arrow/cpp/build \
    && cd /arrow/cpp/build \
    && cmake -DCMAKE_BUILD_TYPE=release \
        -DOPENSSL_ROOT_DIR=/usr/local/ssl \
        -DCMAKE_INSTALL_LIBDIR=lib \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        -DARROW_WITH_BZ2=ON \
        -DARROW_WITH_ZLIB=ON \
        -DARROW_WITH_ZSTD=ON \
        -DARROW_WITH_LZ4=ON \
        -DARROW_WITH_SNAPPY=ON \
        -DARROW_PARQUET=ON \
        -DARROW_PYTHON=ON \
        -DARROW_PLASMA=ON \
        -DARROW_BUILD_TESTS=OFF \
        .. \
    && make -j$(nproc) \
    && make install \
    && cd /arrow/python \
    && python setup.py build_ext --build-type=release --with-parquet \
    && python setup.py install \
    && rm -rf /arrow /tmp/apache-arrow.tar.gz

RUN pip install sqlalchemy-bigquery==1.4.3 grpcio-status==1.56.2

RUN mkdir /snowflake \
    && wget -q https://github.com/snowflakedb/snowflake-connector-python/archive/refs/tags/v2.7.4.zip -O /tmp/snowflake-connector-python.zip \
    && unzip /tmp/snowflake-connector-python.zip -d /snowflake \
    && cd /snowflake/snowflake-connector-python-2.7.4 \
    && ln -s /usr/local/lib/libarrow.so.600 /usr/local/lib/python3.7/site-packages/pyarrow-6.0.1-py3.7-linux-x86_64.egg/pyarrow/libarrow.so.600 \
    && ln -s /usr/local/lib/libarrow_python.so.600 /usr/local/lib/python3.7/site-packages/pyarrow-6.0.1-py3.7-linux-x86_64.egg/pyarrow/libarrow_python.so.600 \
    && python setup.py install \
    && rm -rf /snowflake /tmp/snowflake-connector-python.zip

RUN pip install snowflake-sqlalchemy==1.3.4

RUN printf "[FreeTDS]\nDescription=FreeTDS Driver\nDriver=/usr/lib/libtdsodbc.so\n" > /etc/odbcinst.ini

RUN apk add --no-cache \
    libaio>=0.3.112-r1 \
    libnsl>=1.2.0-r1 \
    libc6-compat>=1.1.24-r3 && \
    cd /tmp && \
    wget -q https://download.oracle.com/otn_software/linux/instantclient/instantclient-basiclite-linuxx64.zip -O /tmp/instantclient-basiclite.zip && \
    unzip instantclient-basiclite.zip && \
    mv instantclient*/ /usr/lib/instantclient && \
    rm instantclient-basiclite.zip && \
    ln -s /usr/lib/instantclient/libclntsh.so.21.1 /usr/lib/libclntsh.so && \
    ln -s /usr/lib/instantclient/libocci.so.21.1 /usr/lib/libocci.so && \
    ln -s /usr/lib/instantclient/libociicus.so /usr/lib/libociicus.so && \
    ln -s /usr/lib/instantclient/libnnz21.so /usr/lib/libnnz21.so && \
    ln -s /usr/lib/libnsl.so.2 /usr/lib/libnsl.so.1 && \
    ln -s /lib/libc.so.6 /usr/lib/libresolv.so.2 && \
    ln -s /lib64/ld-linux-x86-64.so.2 /usr/lib/ld-linux-x86-64.so.2

ENV LD_LIBRARY_PATH /usr/lib/instantclient

RUN pip install cx_oracle==8.3.0
RUN pip install sqlalchemy-cockroachdb==2.0.2
RUN pip install clickhouse-sqlalchemy==0.2.7
RUN pip install databricks-sql-connector[sqlalchemy]==2.9.6
RUN pip install PyAthena==2.25.2
