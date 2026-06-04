#!/bin/bash
# ==============================================================================
# Version Customization Module
# ==============================================================================

# Source common functions
MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$MODULE_DIR/common.sh"

# Customize kernel version
customize_version() {
    # Generate AOSP-style git version
    if git rev-parse --git-dir >/dev/null 2>&1; then
        GIT_COUNT=$(git rev-list --count HEAD)
        GIT_HASH=$(git rev-parse --short=12 HEAD)
        GIT_VER=$(printf "%05d-g%s" "$GIT_COUNT" "$GIT_HASH")
    else
        GIT_VER="00021-g6f2f96be86b9"
    fi

    CUSTOM_VERSION="-android13-8-$GIT_VER-ab13729987"
    
    log "Customizing Kernel Version to: $CUSTOM_VERSION"
    
    GKI_DEFCONFIG="$KERNEL_SRC/arch/arm64/configs/gki_defconfig"
    
    # Update CONFIG_LOCALVERSION in gki_defconfig
    # Replace existing CONFIG_LOCALVERSION="..." with our custom version
    if grep -q "CONFIG_LOCALVERSION=" "$GKI_DEFCONFIG"; then
        sed -i 's/CONFIG_LOCALVERSION=".*"/CONFIG_LOCALVERSION="'"$CUSTOM_VERSION"'"/' "$GKI_DEFCONFIG"
    else
        echo "CONFIG_LOCALVERSION=\"$CUSTOM_VERSION\"" >> "$GKI_DEFCONFIG"
    fi
    
    # Remove '-maybe-dirty' suffix by hacking stamp.bzl
    # The Bazel build system (Kleaf) forces LOCALVERSION="-maybe-dirty" for non-stamped builds.
    # We change it to empty string so it doesn't append anything, and lets CONFIG_LOCALVERSION take precedence.
    if [ -f "$STAMP_BZL" ]; then
        log "Patching stamp.bzl to remove -maybe-dirty..."
        sed -i 's/export LOCALVERSION="-maybe-dirty"/export LOCALVERSION=""/' "$STAMP_BZL"
    else
        warn "stamp.bzl not found at $STAMP_BZL. Version might still include -maybe-dirty."
    fi
}
