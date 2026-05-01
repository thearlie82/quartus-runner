ARG QUARTUS_TAG=agilex3
FROM alterafpga/quartuspro-v25.1:${QUARTUS_TAG}

USER root

COPY adt-git01-leaf.crt /tmp/
COPY adt-certserv01-ca.crt /tmp/
COPY adt-rootcert01-ca.crt /tmp/
COPY setup.sh /tmp/
RUN chmod +x /tmp/setup.sh && /tmp/setup.sh && rm /tmp/setup.sh

# Set Quartus environment
ENV QUARTUS_ROOTDIR=/opt/altera/quartus
# Workaround glibc 2.39 mremap_chunk heap corruption with Quartus
ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2

# Ensure Node.js (used by actions/checkout) also trusts the certs
ENV NODE_EXTRA_CA_CERTS=/etc/ssl/certs/ca-certificates.crt

USER 1001
