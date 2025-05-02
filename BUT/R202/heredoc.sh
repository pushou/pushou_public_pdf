#!/bin/bash

cat << EOF > /etc/netplan/01-netcfg.yaml
network:
    version: 2
    renderer: networkd
    ethernets:
        eth0:
            dhcp4: true
            link-local: [ ipv4 ]
            dhcp4-overrides:
              use-dns: false
            nameservers:
              addresses:
              - 10.6.255.106
              search:
              - iutbeziers.fr
EOF

cat << EOF > /etc/systemd/network/05-eth0.network
[Match]
Name=eth0
[Network]
DHCP=yes
DNS=8.8.8.8 1.1.1.1
Domains=iutbeziers.fr
EOF

cat << EOF > /etc/netplan/01-netcfg.yaml
network:
    version: 2
    renderer: networkd
    ethernets:
                eth0:
                    dhcp4: true
                    dhcp4-overrides:
                      use-dns: false
                    link-local: [ ipv4 ]
                eth1:
                    dhcp4: true
                    dhcp4-overrides:
                      use-dns: false
                    link-local: [ ipv4 ]    
EOF


cat << EOF > /etc/systemd/resolved.conf
[Resolve]
FallbackDNS=9.9.9.9#dns.quad9.net
EOF


cat << EOF > /etc/netplan/01-netcfg.yaml
network:
    version: 2
    renderer: networkd
    ethernets:
                eth0:
                    dhcp4: true
                    dhcp4-overrides:
                      use-dns: false
                    link-local: [ ipv4 ]
                eth1:
                    dhcp4: true
                    dhcp4-overrides:
                      use-dns: false
                    link-local: [ ipv4 ]
                    nameservers:
                      addresses:
                      - 10.6.255.106
                      search:
                      - iutbeziers.fr
EOF

cat << EOF > /etc/systemd/resolved.conf
[Resolve]
DNS=10.6.255.24
EOF

#!/bin/bash
INTERFACE=resolver0
# Add your search domains here
SEARCH_DOMAINS="~umontpellier.fr"
resolvectl domain "$INTERFACE" $SEARCH_DOMAINS
resolvectl dns $INTERFACE 10.6.255.106