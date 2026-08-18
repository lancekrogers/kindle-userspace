# POSIX ash wrappers for camp/fest on a Kindle.
# Not `camp shell-init bash` — that needs real bash. /bin/bash on modern
# Kindles is often busybox.
#
# HOME is usually /mnt/us when dropbear is started with -H /mnt/us.
# Source from $HOME/.profile and set ENV for kTerm:
#   . /mnt/us/.ash_camp
#   export ENV=/mnt/us/.ash_camp

export PATH=/mnt/us/bin:${PATH}

camp() {
  dest=""
  case "$1" in
    switch|sw)
      shift
      passthrough=0
      for arg in "$@"; do
        case "$arg" in
          --help|-h|--json|--json=*|--print|--print=*) passthrough=1; break ;;
        esac
      done
      if [ "$passthrough" -eq 1 ]; then
        command camp switch "$@"
        return
      fi
      line=$(command camp switch "$@" --shell-connect) || return "$?"
      eval "$line"
      ;;
    go|g)
      shift
      passthrough=0
      for arg in "$@"; do
        case "$arg" in
          --help|-h|--json|--json=*|--print|--print=*) passthrough=1; break ;;
        esac
      done
      if [ "$passthrough" -eq 1 ]; then
        command camp go "$@"
        return
      fi
      if [ $# -eq 0 ]; then
        dest=$(command camp go --print)
        status=$?
        if [ -n "$dest" ]; then
          cd "$dest" || return 1
        elif [ "$status" -ne 0 ]; then
          return "$status"
        fi
      elif [ "$1" = "-c" ]; then
        command camp go "$@"
      else
        dest=$(command camp go "$@" --print)
        status=$?
        if [ -n "$dest" ]; then
          cd "$dest" || return 1
        elif [ "$status" -ne 0 ]; then
          return "$status"
        else
          echo "camp: not found: $*" >&2
          return 1
        fi
      fi
      ;;
    *)
      command camp "$@"
      ;;
  esac
}

fest() {
  case "$1" in
    go|g)
      shift
      dest=$(command fest go "$@" --print 2>/dev/null) || return $?
      if [ -n "$dest" ] && [ -d "$dest" ]; then
        cd "$dest" || return 1
      fi
      ;;
    *)
      command fest "$@"
      ;;
  esac
}

cgo() { camp go "$@"; }
csw() { camp switch "$@"; }
fgo() { fest go "$@"; }
