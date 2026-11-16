# setup of worker-test-anders: the program of worker-test, from another package (conflict, F9)
mkdir -p "$AIBOS_WORKER_DIR/bin" || exit 1
printf '#!/bin/bash\necho "anders $*"\n' > "$AIBOS_WORKER_DIR/bin/aibos-test-tool"
chmod +x "$AIBOS_WORKER_DIR/bin/aibos-test-tool"
