#!/bin/bash

echo "🛠 Raspberry Pi WEP-Hotspot wird eingerichtet..."

# Pakete installieren
apt update
apt install -y hostapd dnsmasq iptables

# hostapd config
cat > /etc/hostapd/hostapd.conf <<EOF
interface=wlan0
driver=nl80211
ssid=DSi-Hotspot
hw_mode=g
channel=6
auth_algs=1
wep_default_key=0
wep_key0=1234567890
EOF

# hostapd aktivieren
sed -i 's|#DAEMON_CONF=""|DAEMON_CONF="/etc/hostapd/hostapd.conf"|' /etc/default/hostapd

# wlan0 statisch konfigurieren
ip link set wlan0 up
ip addr flush dev wlan0
ip addr add 192.168.4.1/24 dev wlan0

# dnsmasq config sichern & neu erstellen
mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig 2>/dev/null
cat > /etc/dnsmasq.conf <<EOF
interface=wlan0
dhcp-range=192.168.4.2,192.168.4.20,255.255.255.0,24h
EOF

# IP-Forwarding aktivieren
sed -i 's|#net.ipv4.ip_forward=1|net.ipv4.ip_forward=1|' /etc/sysctl.conf
sysctl -p

# iptables NAT konfigurieren
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sh -c "iptables-save > /etc/iptables.ipv4.nat"

# rc.local für NAT wiederherstellen (falls fehlt)
if [ ! -f /etc/rc.local ]; then
  cat > /etc/rc.local <<EOF
#!/bin/bash
iptables-restore < /etc/iptables.ipv4.nat
exit 0
EOF
  chmod +x /etc/rc.local
fi

# Dienste aktivieren
systemctl unmask hostapd
systemctl enable hostapd
systemctl enable dnsmasq

echo "✅ Einrichtung abgeschlossen. Jetzt neustarten:"
echo "    sudo reboot"
