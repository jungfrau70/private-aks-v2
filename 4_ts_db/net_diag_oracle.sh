#!/bin/bash

DB_IP="10.241.185.68"
DB_PORT=1521
LOG="net_diag_$(date +%Y%m%d%H%M%S).log"

echo "🔍 Oracle DB Network Diagnostics" | tee $LOG
echo "Target: $DB_IP:$DB_PORT" | tee -a $LOG

echo -e "\n[1] ✅ ICMP Ping Test" | tee -a $LOG
ping -c 4 $DB_IP | tee -a $LOG

echo -e "\n[2] 🚪 TCP Port Check (nc)" | tee -a $LOG
nc -zvw5 $DB_IP $DB_PORT | tee -a $LOG

echo -e "\n[3] 🛰 Traceroute (L3 hop-by-hop path)" | tee -a $LOG
traceroute -n $DB_IP | tee -a $LOG

echo -e "\n[4] 🌐 Outbound Public IP from Pod" | tee -a $LOG
curl -s ifconfig.me | tee -a $LOG

echo -e "\n[5] 📋 Pod Route Table" | tee -a $LOG
ip route show | tee -a $LOG

echo -e "\n[6] 🧩 DNS Resolution Check (Optional)" | tee -a $LOG
getent hosts $DB_IP | tee -a $LOG

echo -e "\n[7] 🔐 Check DNS, egress restrictions (e.g., NSG/Firewall)" | tee -a $LOG
echo "If TCP/ICMP blocked, NSG/Firewall/ACL may be cause." | tee -a $LOG

echo -e "\n🔚 Diagnostics complete: $LOG"
