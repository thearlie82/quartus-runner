ARG QUARTUS_TAG=agilex3
FROM alterafpga/quartuspro-v25.1:${QUARTUS_TAG}

USER root

COPY adt-git01-leaf.crt /tmp/
COPY adt-certserv01-ca.crt /tmp/
COPY adt-rootcert01-ca.crt /tmp/
COPY setup.sh /tmp/
RUN chmod +x /tmp/setup.sh && /tmp/setup.sh && rm /tmp/setup.sh

# Questa FPGA Edition (not yet enabled in production)
# COPY QuestaSetup-25.1.0.129-linux.run /tmp/
# COPY install-questa.sh /tmp/
# RUN chmod +x /tmp/install-questa.sh && /tmp/install-questa.sh
# ENV QUESTA_ROOTDIR=/opt/altera/questa_fe
# ENV PATH=$QUESTA_ROOTDIR/bin:$PATH

# Set Quartus environment
ENV QUARTUS_ROOTDIR=/opt/altera/quartus
# Workaround glibc 2.39 mremap_chunk heap corruption with Quartus
ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2

# Ensure Node.js (used by actions/checkout) also trusts the certs
ENV NODE_EXTRA_CA_CERTS=/etc/ssl/certs/ca-certificates.crt

USER 1001
