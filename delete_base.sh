HOSTNAME=$(hostname)

mgmt_cli -r true login >id.txt
printf "\nDeleting Network Objects\n"
mgmt_cli -r true delete package name Policy_CPX
mgmt_cli -r true delete group name "Internal-Subnets" 
mgmt_cli -r true delete network name internal-subnet-192.168.1.0
mgmt_cli -r true delete threat-profile name poc

printf "\nDeleting DNS Hosts.\n"
mgmt_cli -r true delete group name "DNS-Servers" -s id.txt
mgmt_cli -r true delete host name DNS_1 -s id.txt
mgmt_cli -r true delete host name DNS_2 -s id.txt


printf "\nDeleting NTP Servers\n"
mgmt_cli -r true delete group name "NTP-Servers" -s id.txt
mgmt_cli -r true delete host name NTP_1 -s id.txt
mgmt_cli -r true delete group name "AD-Servers" -s id.txt
mgmt_cli -r true delete host name AD_1 -s id.txt


printf  "Deleting  AD Access Rules.\nThe Allowed ports are specified in Windows Article\nSearch MSFT Article dd772723\n"
mgmt_cli -r true delete service-group name "AD-Services"
mgmt_cli -r true delete service-tcp name "ldap-gc-3268" -s id.txt
mgmt_cli -r true delete service-tcp name "ldap-gc-ssl-3269" -s id.txt
mgmt_cli -r true delete service-tcp name "tcp-135" -s id.txt
mgmt_cli -r true delete service-tcp name "AD-file-replication-5722" -s id.txt
mgmt_cli -r true delete service-tcp name "Kerberos-tcp-464" -s id.txt
mgmt_cli -r true delete service-udp name "Kerberos-udp-464" -s id.txt
mgmt_cli -r true delete service-tcp name "AD-DS-web-9389" -s id.txt
mgmt_cli -r true delete service-tcp name "AD-Dynamic-1025-5000" -s id.txt
mgmt_cli -r true delete service-tcp name "AD-Dynamic-49152-65535" -s id.txt



echo "Finalizing and Installing Policy to $HOSTNAME"
mgmt_cli -r true publish -s id.txt
mgmt_cli -r true logout -s id.txt
