ARG QUARTUS_TAG=agilex3
FROM alterafpga/quartuspro-v25.1:${QUARTUS_TAG}

USER root

# Install git (needed by actions/checkout to use git clone instead of REST API download)
# and CA certificates tooling
COPY adt-git01-leaf.crt /tmp/
COPY adt-certserv01-ca.crt /tmp/
COPY adt-rootcert01-ca.crt /tmp/

RUN if command -v apt-get >/dev/null 2>&1; then \
      apt-get update && apt-get install -y --no-install-recommends git ca-certificates && rm -rf /var/lib/apt/lists/*; \
      cp /tmp/*.crt /usr/local/share/ca-certificates/; \
      update-ca-certificates; \
    elif command -v dnf >/dev/null 2>&1 || command -v yum >/dev/null 2>&1; then \
      (dnf install -y git ca-certificates 2>/dev/null || yum install -y git ca-certificates 2>/dev/null || true); \
      cp /tmp/*.crt /etc/pki/ca-trust/source/anchors/ 2>/dev/null || true; \
      (update-ca-trust 2>/dev/null || true); \
    fi && \
    # Fallback: append certs directly to common bundle locations
    for bundle in /etc/ssl/certs/ca-certificates.crt /etc/pki/tls/certs/ca-bundle.crt /etc/ssl/cert.pem; do \
      if [ -f "$bundle" ]; then \
        cat /tmp/*.crt >> "$bundle"; \
      fi; \
    done && \
    rm /tmp/*.crt

# Ensure Node.js (used by actions/checkout) also trusts the certs
ENV NODE_EXTRA_CA_CERTS=/etc/ssl/certs/ca-certificates.crt

USER 1001
