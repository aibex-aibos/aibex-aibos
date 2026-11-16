# setup of worker-test-script: one program in $AIBOS_WORKER_DIR/bin (spec 07, kind script)
[ -n "$AIBOS_TEST_SETUP_FAIL" ] && { echo "setup fails on purpose"; exit 3; }
mkdir -p "$AIBOS_WORKER_DIR/bin" || exit 1
printf '#!/bin/bash\necho "aibos-test-script $*"\n' > "$AIBOS_WORKER_DIR/bin/aibos-test-script"
chmod +x "$AIBOS_WORKER_DIR/bin/aibos-test-script"
echo "setup done in $AIBOS_WORKER_DIR"
