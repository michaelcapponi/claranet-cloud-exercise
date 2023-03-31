#!/bin/bash
curl -sL https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.0/install.sh -o install_nvm.sh
bash install_nvm.sh
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
source ~/.bash_profile
sudo nvm install 8.11.1
sudo yum install git -y
git clone https://github.com/claranet-ch/cloud-phoenix-kata.git
cd cloud-phoenix-kata/
sudo npm install
sudo amazon-linux-extras list | grep nginx
sudo amazon-linux-extras enable nginx1
sudo yum clean metadata
sudo yum -y install nginx
sudo systemctl start nginx
wget https://s3.amazonaws.com/rds-downloads/rds-combined-ca-bundle.pem
ls -l
source ~/.bash_profile
sudo sed -i '/^    }\s*$/i \        location \/ {\n            proxy_set_header  X-Real-IP  $remote_addr;\n            proxy_set_header  Host       $http_host;\n            proxy_pass        http:\/\/127.0.0.1:8080;\n        }' /etc/nginx/nginx.conf
sudo systemctl restart nginx
echo "Waiting for DocumentDB cluster to become available..."
until aws docdb describe-db-instances --db-instance-identifier $db_name --region $region --query 'DBInstances[*].DBInstanceStatus' --output text | grep -q 'available'
do
    echo "DocumentDB instance is not available yet. Retrying in few seconds..."
    sleep 20
done
echo "DocumentDB instance is now available!"
export DB_CONNECTION_STRING='mongodb://${db_user}:${db_pwd}@${db_endpoint}:27017/?ssl=true&ssl_ca_certs=rds-combined-ca-bundle.pem&replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=false'
export PORT=8080
echo "Starting app..."
sudo npm i -g pm2
sudo pm2 start 'npm start'
sudo pm2 status
sudo pm2 save