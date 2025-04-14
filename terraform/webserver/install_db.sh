#!/bin/bash
yum update -y
yum install -y postgresql-server
postgresql-setup initdb
systemctl start postgresql
systemctl enable postgresql
sudo -u postgres psql -c "CREATE USER myuser WITH PASSWORD 'mypassword';"
sudo -u postgres psql -c "CREATE DATABASE mydb;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE mydb TO myuser;"
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /var/lib/pgsql/data/postgresql.conf
cat << EOF > /var/lib/pgsql/data/pg_hba.conf
local   all   all   md5
host    all   all   10.1.0.0/16   md5
EOF
systemctl restart postgresql
