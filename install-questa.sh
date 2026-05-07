#!/bin/bash
set -e

QUESTA_INSTALLER="QuestaSetup-25.1.0.129-linux.run"
INSTALL_DIR="/opt/altera"
QUESTA_EDITION="questa_fe"

chmod +x /tmp/${QUESTA_INSTALLER}

/tmp/${QUESTA_INSTALLER} \
  --mode unattended \
  --unattendedmodeui minimal \
  --installdir ${INSTALL_DIR} \
  --questa_edition ${QUESTA_EDITION} \
  --accept_eula 1

rm /tmp/${QUESTA_INSTALLER}

# Verify installation
if [ ! -d "${INSTALL_DIR}/${QUESTA_EDITION}/bin" ]; then
    echo "ERROR: Questa installation failed - bin directory not found"
    exit 1
fi

echo "Questa installed successfully:"
${INSTALL_DIR}/${QUESTA_EDITION}/bin/vsim -version
