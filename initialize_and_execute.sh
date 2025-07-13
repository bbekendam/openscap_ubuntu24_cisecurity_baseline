#!/bin/bash
set -euo pipefail

# OpenSCAP + CIS Level 1 Server + Nginx password protected report for Ubuntu 24.04

REPORT_DIR="/var/www/compliance"
DATETIME=$(date +"%Y-%m-%d_%H-%M-%S")
PROFILE="xccdf_org.ssgproject.content_profile_cis_level1_server"
REPORT_HTML="${REPORT_DIR}/openscap_cis_level1_server_report_${DATETIME}.html"
RESULTS_XML="${REPORT_DIR}/openscap_cis_level1_server_results_${DATETIME}.xml"
AUTH_FILE="/etc/nginx/.htpasswd"
NGINX_SITE="/etc/nginx/sites-available/compliance"
SCAP_CONTENT_DIR="/opt/ssg"
SCAP_FILE="${SCAP_CONTENT_DIR}/ssg-ubuntu2404-ds.xml"

echo "[*] Updating package list and installing build dependencies..."
sudo apt update
sudo apt install -y \
  build-essential cmake pkg-config git python3-setuptools \
  libxml2-dev libxslt1-dev libcurl4-gnutls-dev libgcrypt20-dev libgpgme-dev \
  libpcre2-dev libyaml-dev rpm libselinux1-dev swig \
  libxmlsec1-dev libxmlsec1t64-openssl libbz2-dev libxml2-utils xsltproc nginx apache2-utils curl

# Build and install OpenSCAP from source
if ! command -v oscap >/dev/null 2>&1; then
  echo "[*] Cloning and building OpenSCAP from source..."
  cd /tmp
  rm -rf openscap
  git clone https://github.com/OpenSCAP/openscap.git
  cd openscap
  rm -rf build
  mkdir build
  cd build
  cmake ..
  make -j$(nproc)
  sudo make install
  sudo ldconfig
else
  echo "[✓] OpenSCAP already installed."
fi

# Download and prepare SCAP Security Guide content for Ubuntu 24.04
if [[ ! -f "$SCAP_FILE" ]]; then
  echo "[*] Downloading and building SCAP Security Guide content..."
  mkdir -p "$SCAP_CONTENT_DIR"
  cd "$SCAP_CONTENT_DIR"
  if [[ -d content ]]; then
    cd content
    git reset --hard
    git clean -fdx
    git pull origin master
  else
    git clone https://github.com/ComplianceAsCode/content.git
    cd content
  fi

  ./build_product ubuntu2404

  if [[ ! -f "build/ssg-ubuntu2404-ds.xml" ]]; then
    echo "[✗] SCAP content build failed or file missing."
    exit 1
  fi

  sudo cp build/ssg-ubuntu2404-ds.xml "$SCAP_FILE"
else
  echo "[✓] SCAP content XML found at $SCAP_FILE"
fi

# Ensure report directory exists
sudo mkdir -p "$REPORT_DIR"
sudo chmod 755 "$REPORT_DIR"

# Run the compliance scan with error tolerated
echo "[*] Running OpenSCAP CIS Level 1 Server compliance scan..."
if ! sudo oscap xccdf eval \
    --profile "$PROFILE" \
    --results "$RESULTS_XML" \
    --report "$REPORT_HTML" \
    "$SCAP_FILE"; then
  echo "[!] OpenSCAP scan returned non-zero exit code, but continuing with the script."
fi

echo "[✓] Scan complete."
echo "    XML results: $RESULTS_XML"
echo "    HTML report: $REPORT_HTML"

# Setup HTTP Basic Auth for Nginx
echo "[*] Creating HTTP Basic Auth credentials..."
sudo htpasswd -bc "$AUTH_FILE" funky funky

# Configure Nginx site
echo "[*] Writing Nginx configuration..."
sudo tee "$NGINX_SITE" > /dev/null <<EOF
server {
    listen 80;
    server_name _;

    location /compliance/ {
        alias $REPORT_DIR/;
        index $(basename "$REPORT_HTML");

        auth_basic "Restricted Access";
        auth_basic_user_file $AUTH_FILE;
    }
}
EOF

# Enable site and reload Nginx
sudo ln -sf "$NGINX_SITE" /etc/nginx/sites-enabled/compliance
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx

IP=$(hostname -I | awk '{print $1}')
echo ""
echo "🚀 Compliance report available at: http://$IP/compliance/"
echo "🔐 Login with username: funky and password: funky"
