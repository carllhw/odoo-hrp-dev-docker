FROM carllhw/odoo-dev:8.0

LABEL maintainer="Haiwei Liu <carllhw@gmail.com>"

USER root

RUN set -x \
        && apt-get update \
        && apt-get install -y --no-install-recommends \
            freetds-dev \
            libffi-dev \
        && apt-get -y install -f --no-install-recommends \
        && rm -rf /var/lib/apt/lists/*

# cx_Oracle
ENV ORACLE_HOME /opt/oracle/instantclient_12_1
ENV LD_RUN_PATH=$ORACLE_HOME
RUN set -x \
        && curl -o /tmp/instantclient-basic-linux.x64-12.1.0.2.0.zip -SL http://files.saas.hand-china.com/oracle/instantclient/instantclient-basic-linux.x64-12.1.0.2.0.zip \
        && curl -o /tmp/instantclient-sdk-linux.x64-12.1.0.2.0.zip -SL http://files.saas.hand-china.com/oracle/instantclient/instantclient-sdk-linux.x64-12.1.0.2.0.zip \
        && mkdir -p /opt/oracle \
        && unzip "/tmp/instantclient*.zip" -d /opt/oracle \
        && ln -s $ORACLE_HOME/libclntsh.so.12.1 $ORACLE_HOME/libclntsh.so \
        && rm -rf /tmp/instantclient*.zip

# The URL to download the MQ installer from in tar.gz format
ARG MQ_URL=http://public.dhe.ibm.com/ibmdl/export/pub/software/websphere/messaging/mqadv/mqadv_dev90_linux_x86-64.tar.gz

# The MQ packages to install
ARG MQ_PACKAGES="MQSeriesRuntime-*.rpm MQSeriesClient-*.rpm MQSeriesSDK*.rpm"

RUN export DEBIAN_FRONTEND=noninteractive \
  # Optional: Update the command prompt
  && echo "mq:9.0" > /etc/debian_chroot \
  # Install additional packages required by MQ, this install process and the runtime scripts
  && apt-get update -y \
  && apt-get install -y --no-install-recommends \
    bash \
    bc \
    coreutils \
    curl \
    debianutils \
    findutils \
    gawk \
    grep \
    libc-bin \
    mount \
    passwd \
    procps \
    rpm \
    sed \
    tar \
    util-linux \
  # Download and extract the MQ installation files
  && mkdir -p /tmp/mq \
  && cd /tmp/mq \
  && curl -LO $MQ_URL \
  && tar -zxvf ./*.tar.gz \
  # Recommended: Create the mqm user ID with a fixed UID and group, so that the file permissions work between different images
  && groupadd --gid 1000 mqm \
  && useradd --uid 1000 --gid mqm --home-dir /var/mqm mqm \
  && usermod -G mqm root \
  && cd /tmp/mq/MQServer \
  # Accept the MQ license
  && ./mqlicense.sh -text_only -accept \
  # Install MQ using the RPM packages
  && rpm -ivh --force-debian $MQ_PACKAGES \
  # Recommended: Set the default MQ installation (makes the MQ commands available on the PATH)
  && /opt/mqm/bin/setmqinst -p /opt/mqm -i \
  # Clean up all the downloaded files
  && rm -rf /tmp/mq \
  && rm -rf /var/lib/apt/lists/*

ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/mqm/lib64/

COPY ./requirements.txt /code/hrp/
RUN pip install -r /code/hrp/requirements.txt

USER odoo
