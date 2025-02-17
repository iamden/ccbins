unalias curl
alias curl="$curlalias"

require_old_magisk() {
  ui_print "**********************************"
  ui_print " Not compatible with Magisk v27+  "
  ui_print "**********************************"
  exit 1
}

require_new_ksu() {
  ui_print "**********************************"
  ui_print " Please install KernelSU v0.6.6+! "
  ui_print "**********************************"
  exit 1
}

test_connection() {
  ui_print "- Testing internet connection"
  [ -f $MODPATH/doh ] && test_connection_doh || test_connection_main
  [ $? -eq 0 ] && return 0 || return 1
}

test_connection_doh() {
  for i in google baidu; do
    if curl --connect-timeout 3 -I https://www.$i.com --dns-servers $dns | grep -q 'HTTP/.* 200' || ping -q -c 1 -W 1 $i.com >/dev/null 2>&1; then
      return 0
    fi
  done
  return 1  
}

test_connection_main() {
  for i in google,1.1.1.1,1.0.0.1 baidu,223.5.5.5,223.6.6.6; do # Cloudflare or Ali DNS
    local domain=$(echo $i | cut -d , -f1) ip=$(echo $i | cut -d , -f2-)
    if curl --connect-timeout 3 -I https://www.$domain.com --dns-servers $ip | grep -q 'HTTP/.* 200' || ping -q -c 1 -W 1 $domain.com >/dev/null 2>&1; then
      export dns="$ip"
      return 0
    fi
  done
  return 1  
}

download_file() {
  rm -f $MODPATH/dlerror
  local file="$1" url="$2"
  rm -f "$file"
  curl -o "$file" "$url"
  if [ "$file" == "$MODPATH/.checksums" ]; then
    [ "$(head -n1 "$file" 2>/dev/null)" == "checksums.txt" ] && return 0 || return 1
  else
    grep -Fwq "`md5sum "$file" | awk '{print $1}'`" $MODPATH/.checksums || { rm -f "$file"; touch $MODPATH/dlerror; ui_print "Download error for $file!"; }
  fi
}

install_ncursesw() {
  download_file $MODPATH/.ncursesver https://raw.githubusercontent.com/Zackptg5/Cross-Compiled-Binaries-Android/$branch/ncursesw/version.txt
  [ -f $MODPATH/dlerror ] && { echo "Binary update check failed!"; return 0; }
  download_file $MODPATH/system/ncursesw.zip https://raw.githubusercontent.com/Zackptg5/Cross-Compiled-Binaries-Android/$branch/ncursesw/ncursesw-$ARCH.zip
  if [ ! -f $MODPATH/dlerror ]; then
    unzip -qod $MODPATH/system $MODPATH/system/ncursesw.zip
    rm -f $MODPATH/system/ncursesw.zip
  else
    rm -f $MODPATH/system/ncursesw.zip
  fi
}