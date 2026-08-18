#!/bin/sh
# Run on the Kindle after unpacking the git tree.
# git-remote-https is a musl ELF whose interpreter is /lib/ld-musl-armhf.so.1
# (not present on Kindle). Wrap it so HTTPS remotes work.
set -e
CORE=/mnt/us/opt/git/libexec/git-core
ROOT=/mnt/us/opt/git
cd "$CORE" || exit 1

if [ -f git-remote-http ] && [ ! -f git-remote-http.bin ]; then
  mv git-remote-http git-remote-http.bin
fi
rm -f git-remote-https
cat > git-remote-http <<'W'
#!/bin/sh
ROOT=/mnt/us/opt/git
exec "$ROOT/lib/ld-musl-armhf.so.1" --library-path "$ROOT/lib" \
  "$ROOT/libexec/git-core/git-remote-http.bin" "$@"
W
cp git-remote-http git-remote-https
chmod 0755 git-remote-http git-remote-https git-remote-http.bin
echo "wrapped git-remote-http(s)"
