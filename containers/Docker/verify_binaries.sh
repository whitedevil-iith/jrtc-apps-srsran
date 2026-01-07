#!/bin/bash
# Verify all srsRAN binaries with JBPF support are installed

BINARIES="gnb srscu srscucp srscuup srsdu"
ALL_FOUND=true

echo "Verifying srsRAN binaries with JBPF support..."
echo "=============================================="

for binary in $BINARIES; do
    if command -v $binary &> /dev/null; then
        echo "✓ $binary found at $(which $binary)"
    else
        echo "✗ $binary NOT FOUND"
        ALL_FOUND=false
    fi
done

if [ "$ALL_FOUND" = true ]; then
    echo ""
    echo "✓ All binaries found successfully!"
    exit 0
else
    echo ""
    echo "✗ Some binaries are missing!"
    exit 1
fi
