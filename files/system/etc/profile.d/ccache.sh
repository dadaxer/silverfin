# Use ccache by default.  Users who don't want that can set the CCACHE_DISABLE
# environment variable in their personal profile.

case ":${PATH:-}:" in
    *:/usr/lib64/ccache:*) ;;
    *) PATH="/usr/lib64/ccache${PATH:+:$PATH}" ;;
esac

# If /var/cache/ccache is writable, use a shared cache there, except for root.
# Users who don't want that even if they have the write permission can set
# the CCACHE_DIR environment variable to another location and possibly unset
# the CCACHE_UMASK environment variables in their personal profile.

if [ -n "${CCACHE_DIR:-}" ] ; then
    if [ ! -w "$CCACHE_DIR" ] ; then
        # Reset broken settings maybe inherited when switching users (#651023).
        unset CCACHE_DIR
        unset CCACHE_UMASK
    fi
elif [ "${EUID:-}" != 0 ] ; then
    if [ -w /var/cache/ccache ] && [ -d /var/cache/ccache ] ; then
        # Set up the shared cache.
        export CCACHE_DIR=/var/cache/ccache
        export CCACHE_UMASK=002
        unset CCACHE_HARDLINK
    fi
fi
