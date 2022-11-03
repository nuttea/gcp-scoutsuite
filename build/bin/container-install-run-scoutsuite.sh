#!/bin/bash

# =====================================
# install ScoutSuite
# =====================================

WORKDIR=/root
TMPDIR=/tmp

cd ${WORKDIR}
pip install scoutsuite

echo -e "\n\nScoutsuite Installation Complete!\n\n"

# =====================================
# Run ScoutSuite
# =====================================

scout gcp --no-browser --report-dir /reports -u --$SCOPE

echo -e "\n\nScoutsuite Run Complete!\n\n"