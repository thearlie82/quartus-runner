ARG QUARTUS_TAG=agilex3
FROM alterafpga/quartuspro-v25.3:${QUARTUS_TAG}

USER root

# Install ADT CA certificates (one cert per file)
COPY adt-git01-leaf.crt /usr/local/share/ca-certificates/
COPY adt-certserv01-ca.crt /usr/local/share/ca-certificates/
COPY adt-rootcert01-ca.crt /usr/local/share/ca-certificates/
RUN update-ca-certificates

USER 1001
