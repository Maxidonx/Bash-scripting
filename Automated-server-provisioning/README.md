# Automatated server provisioning and Deployment.

This repository contains a Bash script for automating the deployment of a web application using Docker, Docker Compose, Nginx, and MySQL. It also supports optional SSL configuration via Let's Encrypt and database setup (local or remote).

## Prerequisites
Before running the script, ensure that the following prerequisites are met:

1. **Operating System**: The script is designed for Ubuntu or Debian-based systems.

2. **Root Privileges**: You must have root or sudo access.

3. **Network Configuration**: Ensure the server has internet access to download dependencies.

## Features
- Updates the system and installs necessary dependencies.

- Configures the firewall to allow SSH and Nginx traffic.

- Clones a specified application repository.

- Creates and configures a docker-compose.yml file.

- Builds and runs Docker containers for the application and database.

- Configures Nginx with optional SSL via Let's Encrypt.

- Sets up a local or remote MySQL database (optional).

- Cleans up unused Docker resources.


## Variables
The script uses the following variables:
```
APP_NAME="my-web-app"
APP_REPO="https://github.com/username/my-web-app.git"
APP_DIR="/var/www/$APP_NAME"
DOCKER_IMAGE="$APP_NAME:latest"
DOMAIN="example.com"
PORT=${PORT:-8000}
USE_DB=true
USE_REMOTE_DB=false
DB_HOST=${DB_HOST:-"localhost"}
DB_PORT=${DB_PORT:-3306}
DB_NAME=${DB_NAME:-"my_database"}
DB_USER=${DB_USER:-"my_user"}
DB_PASSWORD=${DB_PASSWORD:-"secure_password"}
ADMIN_EMAIL=${ADMIN_EMAIL:-"admin@example.com"}
```
Modify these variables as needed to suit your deployment.

## Usage
1. **Clone the Repository:**
```
git clone https://github.com/Maxidonx/Bash-scripting.git
cd Automated-server-provisioning
```
2. **Make the Script Executable:**
```
chmod +x Script.sh
```
3. **Run the Script:**
```
./Script.sh
```
## Steps Performed by the Script

1. **System Update and Dependency Installation**

    - Updates the system packages.

    - Installs Nginx, Git, Docker, Docker Compose, Certbot, and MySQL client.

2. **Firewall Configuration**

    - Configures UFW to allow SSH and Nginx traffic.

3. **Clone Application Repository**

    - Clones the specified repository into /var/www/$APP_NAME.

    - Pulls the latest changes if the directory already exists.

4. **Generate Docker Compose File**

    - Creates a docker-compose.yml file in the application directory.

5. **Build and Run Docker Containers**

    - Uses Docker Compose to build and run containers for the application and database.

6. **Configure Nginx with SSL**

    - Creates an Nginx configuration file for the application.

    - Sets up SSL using Certbot and Let's Encrypt.

7. **Database Configuration**

    - Configures a local or remote MySQL database based on the USE_REMOTE_DB flag.

8. **Cleanup**

    - Removes unused Docker containers and images.

## Accessing the Application

After the script is completed, visit the application at:

```
https://<your-domain>
```
Replace `<your-domain>` with the value of the `DOMAIN` variable.

## Logs and Troubleshooting
- Logs are displayed on the terminal during script execution.

- Check system logs for detailed information:
```
Logs are displayed on the terminal during script execution.

Check system logs for detailed information:
```