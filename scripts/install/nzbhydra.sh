#!/bin/bash
#
# swizzin Copyright (C) 2020 swizzin.ltd
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
#

if [[ -f /tmp/.install.lock ]]; then
  log="/root/logs/install.log"
else
  log="/root/logs/swizzin.log"
fi

. /etc/swizzin/sources/functions/utils

username=$(_get_master_username)

echo "Checking depends ..."
LIST='default-jre-headless unzip'
apt_install $LIST

latest=$(curl -s https://api.github.com/repos/theotherp/nzbhydra2/releases/latest | grep -E "browser_download_url" | grep linux | head -1 | cut -d\" -f 4)
latestversion=$(echo $latest | grep -oP 'v\d+\.\d+\.\d+')

echo "Installing NZBHydra ${latestversion}"
cd /opt
mkdir nzbhydra2
cd nzbhydra2
wget -O nzbhydra2.zip ${latest} >> ${log} 2>&1
unzip nzbhydra2.zip >> ${log} 2>&1
rm -f nzbhydra2.zip

chmod +x nzbhydra2
chown -R ${username}: /opt/nzbhydra2

if [[ $active == "active" ]]; then
    systemctl restart nzbhydra
fi

mkdir -p /home/${user}/.config/nzbhydra2

chown ${user}: /home/${user}/.config
chown ${user}: /home/${user}/.config/nzbhydra2

cat > /etc/systemd/system/nzbhydra.service <<EOH2
[Unit]
Description=NZBHydra2 Daemon
Documentation=https://github.com/theotherp/nzbhydra2
After=network.target

[Service]
User=${username}
Type=simple
# Set to the folder where you extracted the ZIP
WorkingDirectory=/opt/nzbhydra2


# NZBHydra stores its data in a "data" subfolder of its installation path
# To change that set the --datafolder parameter:
# --datafolder /path-to/datafolder
ExecStart=/opt/nzbhydra2/nzbhydra2 --nobrowser --datafolder /home/${username}/.config/nzbhydra2 --nopidfile

Restart=always

[Install]
WantedBy=multi-user.target
EOH2

systemctl enable --now nzbhydra >> ${log} 2>&1

if [[ -f /install/.nginx.lock ]]; then
  sleep 30
  bash /usr/local/bin/swizzin/nginx/nzbhydra.sh
  systemctl reload nginx
fi

systemctl restart nzbhydra
touch /install/.nzbhydra.lock

