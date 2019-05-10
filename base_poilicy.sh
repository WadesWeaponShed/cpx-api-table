printf  "This script will walk through setup using the R80 REST API.\nLogin to SmartDashboard to watch the creation of items.\nIf for any reason you make a typo and need to exit use CTRL+C.\nPress ENTER  to continue"
read ANYKEY

HOSTNAME=$(hostname)

mgmt_cli -r true login > id.txt
printf "\nAdding Gateway and Activating Blades\n"
mgmt_cli -r true set simple-gateway name $HOSTNAME anti-bot true anti-virus true application-control true data-awareness true firewall true ips true threat-emulation true version R80.10 url-filtering true interfaces.1.name eth1 interfaces.1.ipv4-address 10.10.10.1 interfaces.1.ipv4-mask-length 24 interfaces.1.topology external interfaces.1.anti-spoofing false interfaces.2.name Mgmt interfaces.2.ipv4-address 192.168.1.1 interfaces.2.ipv4-mask-length 24 interfaces.2.topology internal interfaces.2.anti-spoofing false interfaces.2.topology-settings.ip-address-behind-this-interface 'network defined by the interface ip and net mask' -s id.txt


printf "\nBuilding base Network Access Policy and Detect Only Threat Policy.\n"
mgmt_cli -r true add package access True threat-prevention True name Policy_CPX
mgmt_cli -r true set access-layer name "Policy_CPX Network" applications-and-url-filtering true data-awareness true
mgmt_cli -r true add threat-profile name poc active-protections-performance-impact "high" active-protections-severity "low or above" ips-settings.exclude-protection-with-severity false confidence-level-low "detect" confidence-level-medium "detect" confidence-level-high "detect" threat-emulation true anti-virus true anti-bot true ips true ips-settings.newly-updated-protections "staging" ips-settings.exclude-protection-with-performance-impact false ips-settings.exclude-protection-with-performance-impact-mode "high or lower"
mgmt_cli -r true set package threat-prevention True name Policy_CPX
mgmt_cli -r true set threat-rule rule-number 1 layer 'Policy_CPX Threat Prevention' action poc
mgmt_cli -r true set ips-update-schedule enabled true time 02:00

printf "\nAdding Network Rules\n"
mgmt_cli -r true add network name internal-subnet-192.168.1.0 subnet 192.168.1.0 mask-length 24 nat-settings.auto-rule true nat-settings.method "hide" nat-settings.hide-behind "gateway" -s id.txt
mgmt_cli -r true add group name "Internal-Subnets" members "internal-subnet-192.168.1.0" -s id.txt
mgmt_cli -r true add access-rule layer 'Policy_CPX Network' position top name 'internal to internet' source Internal-Subnets destination Internet service.1 http service.2 https service.3 HTTP_and_HTTPS_proxy  action accept track 'log' -s id.txt
mgmt_cli -r true add access-rule layer 'Policy_CPX Network' position.above 'internal to internet' name 'Internal to Internal' source Internal-Subnets destination Internal-Subnets action accept track 'log' -s id.txt
mgmt_cli -r true add access-section layer 'Policy_CPX Network' position.above "Internal to Internal" name 'Internal Access' -s id.txt
mgmt_cli -r true add access-rule layer 'Policy_CPX Network' position top  name 'stealth rule' source any destination $HOSTNAME action drop track 'log' -s id.txt
mgmt_cli -r true add access-section layer 'Policy_CPX Network' position.above "stealth rule" name 'Access to Gateway' -s id.txt
mgmt_cli -r true add access-section layer 'Policy_CPX Network' position.above "internal to internet" name 'Outbound Access' -s id.txt

printf "\nCreating DNS Hosts.\n"
mgmt_cli -r true add host name DNS_1 ip-address 192.168.1.20 -s id.txt
mgmt_cli -r true add group name "DNS-Servers" members "DNS_1" -s id.txt

printf "\nSetting up DNS Server access rules\n"
mgmt_cli -r true add access-layer name "Network Services Layer" applications-and-url-filtering true data-awareness true -s id.txt
mgmt_cli -r true add access-rule layer 'Policy_CPX Network' position.below "stealth rule" name 'Network Services' source any destination any service DNS action "Apply Layer" inline-layer "Network Services Layer" track 'log' -s id.txt
mgmt_cli -r true add access-rule layer 'Network Services Layer' position top name 'Internal DNS Access' source Internal-Subnets destination DNS-Servers service DNS action accept track 'log' -s id.txt
mgmt_cli -r true add access-rule layer 'Network Services Layer' position.above "Internal DNS Access" name 'DNS Outbound' source DNS-Servers destination any service DNS  action accept track 'log' -s id.txt


mgmt_cli -r true add host name DNS_2 ip-address 192.168.1.21 -s id.txt
mgmt_cli -r true set group name "DNS-Servers" members.add "DNS_2" -s id.txt

printf "\nAdding NTP Servers\n"
mgmt_cli -r true add host name NTP_1 ip-address 192.168.1.30 -s id.txt
mgmt_cli -r true add group name "NTP-Servers" members "NTP_1" -s id.txt

printf "\nSetting up NTP Server access rules\n"
mgmt_cli -r true set access-rule layer 'Policy_CPX Network' name 'Network Services' service.add ntp -s id.txt
mgmt_cli -r true add access-rule layer 'Network Services Layer' position.below "Internal DNS Access" name 'NTP Outbound' source NTP-Servers destination any service ntp action accept track 'none' -s id.txt
mgmt_cli -r true add access-rule layer 'Network Services Layer' position.below "NTP Outbound" name 'Internal NTP Access' source Internal-Subnets destination NTP-Servers service ntp action accept track 'none' -s id.txt


mgmt_cli -r true add host name AD_1 ip-address 192.168.1.10 -s id.txt
mgmt_cli -r true add group name "AD-Servers" members "AD_1" -s id.txt

printf  "\nSetting up AD Access Rules.\nThe Allowed ports are specified in Windows Article\nSearch MSFT Article dd772723\n"
mgmt_cli -r true add service-tcp name "ldap-gc-3268" port 3268 -s id.txt
mgmt_cli -r true add service-tcp name "ldap-gc-ssl-3269" port 3269 -s id.txt
mgmt_cli -r true add service-tcp name "tcp-135" port 135 -s id.txt
mgmt_cli -r true add service-tcp name "AD-file-replication-5722" port 5722 -s id.txt
mgmt_cli -r true add service-tcp name "Kerberos-tcp-464" port 464 -s id.txt
mgmt_cli -r true add service-udp name "Kerberos-udp-464" port 464 -s id.txt
mgmt_cli -r true add service-tcp name "AD-DS-web-9389" port 9389 -s id.txt
mgmt_cli -r true add service-tcp name "AD-Dynamic-1025-5000" port 1025-5000 -s id.txt
mgmt_cli -r true add service-tcp name "AD-Dynamic-49152-65535" port 49152-65535
mgmt_cli -r true add service-group name "AD-Services" members.1 "ldap-gc-3268" members.2 "ldap-gc-ssl-3269" members.3 "tcp-135" members.4 "AD-file-replication-5722" members.5 "Kerberos-tcp-464" members.6 "Kerberos-udp-464" members.7 "AD-DS-web-9389" members.8 "ldap" members.9 "ldap-ssl" members.10 "ldap-ssl" members.11 "Kerberos_v5_TCP" members.12 "Kerberos_v5_UDP" members.13 "microsoft-ds" members.14 "microsoft-ds-udp" members.15 "smtp" members.16 "nbdatagram" members.17 "nbname" members.18 "nbsession" members.19 "domain-tcp" members.20 "domain-udp" members.21 "ntp-tcp" members.22 "ntp-udp" members.23 "DCOM-IWbemLevel1Login" members.24 "DCOM-IRemUnknown" members.25 "IWbemServices" members.26 "IWbemFetchSmartEnum" members.27 "IWbemWCOSmartEnum" members.28 "IenumWbemClassObject" members.29 "AD-Dynamic-1025-5000" members.30 "AD-Dynamic-49152-65535" -s id.txt
mgmt_cli -r true add access-rule layer 'Policy_CPX Network' position.above "Network Services" name 'Internal Access to AD' source Internal-Subnets destination AD-Servers service AD-Services action accept track 'log' -s id.txt
mgmt_cli -r true add access-rule layer 'Policy_CPX Network' position.above "Internal Access to AD" name 'AD to AD Access' source AD-Servers destination AD-Servers service AD-Services action accept track 'log' -s id.txt
mgmt_cli -r true add access-section layer 'Policy_CPX Network' position.above "AD to AD Access" name 'AD Server Rules' -s id.txt
mgmt_cli -r true add access-section layer 'Policy_CPX Network' position.above "Network Services" name 'Network Services Rules' -s id.txt

printf "\nSetting up Admin Access.\n"
mgmt_cli -r true add access-rule layer 'Policy_CPX Network' position.above "stealth rule" name 'Admin Net to GW/Managment' source internal-subnet-192.168.1.0 destination $HOSTNAME  action accept track 'log' -s id.txt


printf "\nFinalizing and Installing Policy to $HOSTNAME\n"
mgmt_cli -r true add access-rule layer 'Policy_CPX Network' position.above "Cleanup rule" name "Don't log noise" source any destination any service NBT action accept track 'none' -s id.txt
mgmt_cli -r true add access-section layer 'Policy_CPX Network' position.above "Don't log noise" name 'Clean-up Rules' -s id.txt
mgmt_cli -r true publish -s id.txt
mgmt_cli -r true install-policy policy-package "Policy_CPX" access True threat-prevention False targets.1 "$HOSTNAME" -s id.txt
mgmt_cli -r true install-policy policy-package "Policy_CPX" access True threat-prevention True targets.1 "$HOSTNAME" -s id.txt
mgmt_cli -r true logout -s id.txt
