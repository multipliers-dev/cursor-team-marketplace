#!/usr/bin/env sh
# Portable session PATH prepend (team-harness marketplace primitive).
# Prepend /usr/local/bin so Cloud Build-installed Node is visible in agent shells.
# Idempotent — safe to source repeatedly.
#
# Do not rewrite /usr/bin/node or Cursor exec-daemon binaries; only adjust PATH.

case ":${PATH}:" in
  *:/usr/local/bin:*) ;;
  *) export PATH="/usr/local/bin:${PATH}" ;;
esac
