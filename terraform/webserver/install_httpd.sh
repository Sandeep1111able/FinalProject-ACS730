#!/bin/bash
sudo yum -y update
sudo yum -y install httpd
myip=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
echo "<h1>Welcome to ACS730 Final Project!</h1><br>My private IP is $myip<br><p>Built by Sandeep, Bishal, Kushal and Ajay!</p>" > /var/www/html/index.html
sudo systemctl start httpd
sudo systemctl enable httpd
