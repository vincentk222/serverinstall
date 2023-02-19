#!/bin/bash

if [ "$EUID" -eq 0 ]
  then echo "Please do not run this script as root or using sudo."
  exit
fi

# Update and upgrade existing packages
sudo apt-get update
sudo apt-get dist-upgrade -y

# Install necessary packages
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add the Docker repository to APT sources
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update the APT package index
sudo apt-get update

# Remove old versions of Docker and associated components
sudo apt remove -y docker docker-engine docker.io containerd runc

# Install Docker and Docker Compose
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Download the latest version of Docker Compose
LATEST_VERSION=$(curl --silent https://api.github.com/repos/docker/compose/releases/latest | jq .name -r)
sudo curl -L "https://github.com/docker/compose/releases/download/${LATEST_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# Clean up existing packages
sudo apt-get autoremove -y
sudo apt-get autoclean -y

# Add the current user to the docker group
if getent group docker | grep &>/dev/null "\b$(whoami)\b"; then
  echo -e "\033[0;32mUser '$(whoami)' is already in the 'docker' group\033[0m"
else
  read -p "Do you want to add the current user to the 'docker' group? [Y/n] " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    usermod -aG docker "$(whoami)"
    echo -e "\033[0;32mUser '$(whoami)' has been added to the 'docker' group\033[0m"
  fi
fi

# Install webmin
echo "deb https://download.webmin.com/download/repository sarge contrib" | sudo tee /etc/apt/sources.list.d/webmin.list > /dev/null
wget -q http://www.webmin.com/jcameron-key.asc -O- | sudo apt-key add -
sudo apt-get update
sudo apt-get install -y webmin

# Download Docker Bench for Security
sudo git clone https://github.com/docker/docker-bench-security.git
cd docker-bench-security
sudo bash docker-bench-security.sh