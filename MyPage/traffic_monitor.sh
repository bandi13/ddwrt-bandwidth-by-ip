#!/bin/sh
# Bandwidth Download/Upload Rate Counter
LAN_IFACE=$(nvram get lan_ifname)
LAN_TYPE=$(nvram get lan_ipaddr | sed -e "s/\.\d\.\d$//")

if [ -f /tmp/traffic_monitor.lock ]; then
  if [ ! -d /proc/$(cat /tmp/traffic_monitor.lock) ]; then
    echo "WARNING : Lockfile detected but process $(cat /tmp/traffic_monitor.lock) does not exist. Reinitialising lock file!"
    rm -f /tmp/traffic_monitor.lock
  else
    echo "WARNING : Process is already running as $(cat /tmp/traffic_monitor.lock), aborting!"
    exit
  fi
fi

echo $$ > /tmp/traffic_monitor.lock
echo "Monitoring network ${LAN_TYPE}.x.255"

# Check the number of ip_conntrack fields
CONNTRACK=$(tail -n1 /proc/net/ip_conntrack | awk 'END { print NF; }')

if [ -f /tmp/traffic.dat ]; then
  rm /tmp/traffic.dat
fi

while :
do
  # Load in configuration
  source /tmp/MyPage/config.sh

  #Create the RRDIPT CHAIN (it doesn't matter if it already exists).       
  iptables -N RRDIPT 2> /dev/null                                          
                                                                                 
  #Add the RRDIPT CHAIN to the FORWARD chain (if non existing).               
  iptables -L FORWARD --line-numbers -n | grep "RRDIPT" | grep "1" > /dev/null
  if [ $? -ne 0 ]; then                                                       
    iptables -L FORWARD -n | grep "RRDIPT" > /dev/null                  
    if [ $? -eq 0 ]; then                                               
      iptables -D FORWARD -j RRDIPT                               
    fi                                                                  
  iptables -I FORWARD -j RRDIPT                                       
  fi                                                                          
                                                                                    
  #For each host in the ARP table                                             
  grep ${LAN_TYPE} /proc/net/arp | while read IP TYPE FLAGS MAC MASK IFACE   
  do                                                                           
    #Add iptable rules (if non existing).                               
    iptables -nL RRDIPT | grep "${IP}[[:space:]]" > /dev/null                     
    if [ $? -ne 0 ]; then                                               
      iptables -I RRDIPT -d ${IP} -j RETURN                       
      iptables -I RRDIPT -s ${IP} -j RETURN                       
    fi                                                                  
  done                                                                        

  grep ${LAN_TYPE} /proc/net/arp | awk 'BEGIN { printf "{arp::"} { printf "'\''%s'\'','\''%s'\'',",$1,$4; } END { print "'\''-'\''}"}' >> /tmp/traffic.dat
  #awk 'BEGIN { printf "{hosts::"} { printf "'\''%s'\'','\''%s'\'',",$1,$2; } END { print "'\''<% show_wanipinfo(); %>'\''}"}' /tmp/hosts >> /tmp/traffic.dat
  if [ $DO_ACTIVE == 1 ]; then
    if [ $CONNTRACK -eq 19 ]; then
      awk 'BEGIN { printf "{ip_conntrack::"} { gsub(/(src|dst|sport|dport|mark)=/, ""); if ($1 == "tcp") { printf "'\''%s'\'','\''%s'\'','\''%s'\'','\''%s'\'','\''%s'\'',%s,",$1,$5,$7,$6,$8,$(NF-1); } else { printf "'\''%s'\'','\''%s'\'','\''%s'\'','\''%s'\'','\''%s'\'',%s,",$1,$4,$6,$5,$7,$(NF-1); } } END { print "'\''-'\''}"}' /proc/net/ip_conntrack >> /tmp/traffic.dat
    else
      awk 'BEGIN { printf "{ip_conntrack::"} { gsub(/(src|dst|sport|dport|mark)=/, ""); if ($1 == "tcp") { printf "'\''%s'\'','\''%s'\'','\''%s'\'','\''%s'\'','\''%s'\'',%s,",$1,$5,$7,$6,$8,$(NF-2); } else { printf "'\''%s'\'','\''%s'\'','\''%s'\'','\''%s'\'','\''%s'\'',%s,",$1,$4,$6,$5,$7,$(NF-2); } } END { print "'\''-'\''}"}' /proc/net/ip_conntrack >> /tmp/traffic.dat
    fi
  else
    echo "{ip_contrack::'-','','','','',''}" >> /tmp/traffic.dat
  fi
  iptables -L RRDIPT -vnx -t filter | grep ${LAN_TYPE} | awk 'BEGIN { printf "{bw_table::" } { if (NR % 2 == 1) printf "'\''%s'\'','\''%s'\'',",$8,$2; else printf "'\''%s'\'',",$2;}' >> /tmp/traffic.dat
  uptime | awk '{ printf "'\''-'\'','\''%s'\''}\n{uptime::%s}\n", $1, $0 } END { print "{ipinfo::<% show_wanipinfo(); %>}" }' >> /tmp/traffic.dat
  # enable below to log every update to syslog (going to use a LOT of disk space on your syslog server
  #cat /tmp/traffic.dat | logger
  mv -f /tmp/traffic.dat /tmp/www/traffic.asp
  sleep 1
done
