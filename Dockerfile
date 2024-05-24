# Use a specific version of Debian to ensure compatibility
FROM debian:buster-slim

ARG SNMPD_VERSION=5.9.4

EXPOSE 161 161/udp

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    ca-certificates \
    libssl-dev \
    libperl-dev \
    libwrap0-dev \
    libreadline-dev \
    libsnmp-dev \
    file

# Download and extract net-snmp
RUN mkdir -p /etc/snmp \
    && curl -L "https://sourceforge.net/projects/net-snmp/files/net-snmp/$SNMPD_VERSION/net-snmp-$SNMPD_VERSION.tar.gz/download" -o net-snmp.tgz \
    && tar zxvf net-snmp.tgz \
    && rm net-snmp.tgz

# Build and install net-snmp
RUN cd net-snmp-$SNMPD_VERSION \
    && find . -type f -print0 | xargs -0 sed -i 's/\"\/proc/\"\/host_proc/g' \
    && ./configure --prefix=/usr/local --disable-ipv6 --disable-snmpv1 --with-defaults \
    && make \
    && make install \
    && cd .. \
    && rm -rf net-snmp-$SNMPD_VERSION

# Remove build dependencies to keep the image size small
RUN apt-get purge -y --auto-remove \
    build-essential \
    curl

COPY snmpd.conf /etc/snmp

CMD [ "/usr/local/sbin/snmpd", "-f", "-c", "/etc/snmp/snmpd.conf" ]
