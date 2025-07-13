# 🛡️ OpenSCAP CIS Compliance Scan for Ubuntu 24.04

This repository provides a Bash script that automates the process of auditing a Ubuntu 24.04 server against the CIS Level 1 Server Benchmark using [OpenSCAP](https://www.open-scap.org/) and [SCAP Security Guide](https://github.com/ComplianceAsCode/content). The resulting compliance report is then hosted on a local Nginx server with basic authentication.

---

## 📋 Description

This script:

* Installs required build tools, libraries, and SCAP dependencies
* Builds and installs OpenSCAP from source (if not already installed)
* Clones and builds SCAP Security Guide for Ubuntu 24.04
* Runs a compliance scan using the CIS Level 1 Server profile
* Stores HTML and XML results in `/var/www/compliance/`
* Configures Nginx to serve the report with HTTP Basic Authentication
* Provides access to the report at: `http://<your-server-ip>/compliance/`

🔐 Default credentials:

* **Username:** `funky`
* **Password:** `funky`

---

## ✅ Prerequisites

* Ubuntu Server 24.04
* Root or sudo access
* Outbound internet connectivity (to download packages and source code)
* A free TCP port (defaults to Nginx on port 80)

> ✅ Note: The script will install and configure dependencies including `OpenSCAP`, `nginx`, `git`, `cmake`, and more.

---

## 🚀 How to Use

1. **Clone the Repository**

   ```bash
   git clone https://github.com/your-user/your-repo.git
   cd your-repo
   ```

2. **Make the Script Executable**

   ```bash
   chmod +x openscap_cis_level1_ubuntu24.sh
   ```

3. **Run the Script**

   > ⚠️ Requires sudo privileges

   ```bash
   sudo ./openscap_cis_level1_ubuntu24.sh
   ```

4. **View the Report**

   * Open a browser and navigate to:

     ```
     http://<your-server-ip>/compliance/
     ```
   * Log in using the default credentials: `funky` / `funky`

---

## 📁 Output Files

* HTML report: `/var/www/compliance/openscap_cis_level1_server_report_<timestamp>.html`
* XML results: `/var/www/compliance/openscap_cis_level1_server_results_<timestamp>.xml`

---

## 🔐 Security Note

For production use:

* Change the default credentials in the script (`htpasswd` line)
* Restrict Nginx access by IP or TLS
* Consider integrating OpenSCAP results into a central compliance dashboard

---

## 📚 References

* [OpenSCAP](https://www.open-scap.org/)
* [SCAP Security Guide](https://github.com/ComplianceAsCode/content)
* [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks/)
