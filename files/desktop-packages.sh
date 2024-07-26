#!/bin/bash

#### firefox
wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" | tee -a /etc/apt/sources.list.d/mozilla.list > /dev/null
echo '
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
' | sudo tee /etc/apt/preferences.d/mozilla 
apt update -y
DEBIAN_FRONTEND=noninteractive apt install -y firefox-esr
rm -rf /var/lib/apt/lists/*

#### google chrome
# additional from https://github.com/kasmtech/workspaces-images/blob/develop/src/ubuntu/install/chrome/install_chrome.sh
curl -fsSL https://dl-ssl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/googlechrome.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/googlechrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | tee -a /etc/apt/sources.list.d/google-chrome.list > /dev/null
apt update -y
DEBIAN_FRONTEND=noninteractive apt install -y google-chrome-stable
rm -rf /var/lib/apt/lists/*

# configuration options
CHROME_ARGS="--password-store=basic --no-sandbox --ignore-gpu-blocklist --user-data-dir --no-first-run --simulate-outdated-no-au='Tue, 31 Dec 2099 23:59:59 GMT'"
sed -i 's/-stable//g' /usr/share/applications/google-chrome.desktop
mv /usr/bin/google-chrome /usr/bin/google-chrome-orig
cat >/usr/bin/google-chrome <<EOL
#!/usr/bin/env bash
if ! pgrep chrome > /dev/null;then
  rm -f \$HOME/.config/google-chrome/Singleton*
fi
sed -i 's/"exited_cleanly":false/"exited_cleanly":true/' ~/.config/google-chrome/Default/Preferences
sed -i 's/"exit_type":"Crashed"/"exit_type":"None"/' ~/.config/google-chrome/Default/Preferences
if [ -f /opt/VirtualGL/bin/vglrun ] && [ ! -z "\${KASM_EGL_CARD}" ] && [ ! -z "\${KASM_RENDERD}" ] && [ -O "\${KASM_RENDERD}" ] && [ -O "\${KASM_EGL_CARD}" ] ; then
    echo "Starting Chrome with GPU Acceleration on EGL device \${KASM_EGL_CARD}"
    vglrun -d "\${KASM_EGL_CARD}" /opt/google/chrome/google-chrome ${CHROME_ARGS} "\$@" 
else
    echo "Starting Chrome"
    /opt/google/chrome/google-chrome ${CHROME_ARGS} "\$@"
fi
EOL
chmod +x /usr/bin/google-chrome
cp /usr/bin/google-chrome /usr/bin/chrome

sed -i 's@exec -a "$0" "$HERE/google-chrome" "$\@"@@g' /usr/bin/x-www-browser
cat >>/usr/bin/x-www-browser <<EOL
exec -a "\$0" "\$HERE/chrome" "${CHROME_ARGS}"  "\$@"
EOL

mkdir -p /etc/opt/chrome/policies/managed/
cat >>/etc/opt/chrome/policies/managed/default_managed_policy.json <<EOL
{"CommandLineFlagSecurityWarningsEnabled": false, "DefaultBrowserSettingEnabled": false}
EOL


#### VS Code
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/microsoftprod.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoftprod.gpg] https://packages.microsoft.com/repos/code/ stable main" | tee -a /etc/apt/sources.list.d/vscode.list > /dev/null
apt update -y
DEBIAN_FRONTEND=noninteractive apt install -y code seahorse
rm -rf /var/lib/apt/lists/*

# Desktop icon fixups
mkdir -p /usr/share/icons/hicolor/apps
wget -O /usr/share/icons/hicolor/apps/vscode.svg https://kasm-static-content.s3.amazonaws.com/icons/vscode.svg
sed -i '/Icon=/c\Icon=/usr/share/icons/hicolor/apps/vscode.svg' /usr/share/applications/code.desktop
sed -i 's#/usr/share/code/code#/usr/share/code/code --no-sandbox##' /usr/share/applications/code.desktop

#### Thonny
apt update -y 
DEBIAN_FRONTEND=noninteractive apt install -y python3 python3-pip python3-tk cython3 python3-guizero python3-numpy python3-requests python3-pil python3-scipy python3-matplotlib python3-pgzero python3-gpiozero python3-pygame python3-flask python3-pytest python3-colorama python3-pandas python3-bs4 python3-lxml python3-openpyxl python3-xlsxwriter python3-xlrd python3-xlwt python3-html5lib python3-odf thonny
rm -rf /var/lib/apt/lists/*
cat << EOF > /usr/share/applications/thonny.desktop
[Desktop Entry]
Type=Application
Name=Thonny
Comment=Thonny Python3 Integrated Development Environment
Icon=/usr/share/pixmaps/python3.xpm
Exec=/usr/bin/thonny
Terminal=false
Categories=Development;IDE
Name[en]=Thonny
NoDisplay=false
EOF

#### TSGL for CS112
apt update -y 
DEBIAN_FRONTEND=noninteractive apt install -y tsgl
rm -rf /var/lib/apt/lists/*

#### Misc packages
apt update -y
DEBIAN_FRONTEND=noninteractive apt install -y filezilla gnuplot
rm -rf /var/lib/apt/lists/*