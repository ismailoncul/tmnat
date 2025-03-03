#!/bin/bash

if [ "$#" -lt 1 ]; then
    echo "tmnat help"
    exit 1
fi

HOME_IP=$2
VPS_IP=$3
INTERFACE_NAME=$4

ADD_COMMAND_DNAT="iptables -t nat -A PREROUTING -d $VPS_IP -j DNAT --to-destination $HOME_IP"
ADD_COMMAND_SNAT="iptables -t nat -A POSTROUTING -s $HOME_IP -j SNAT --to-source $VPS_IP"
REMOVE_COMMAND_DNAT="iptables -t nat -D PREROUTING -d $VPS_IP -j DNAT --to-destination $HOME_IP"
REMOVE_COMMAND_SNAT="iptables -t nat -D POSTROUTING -s $HOME_IP -j SNAT --to-source $VPS_IP"
SAVE_COMMAND="iptables-save > /etc/iptables/rules.v4"
ADD_MASK="iptables -t nat -A POSTROUTING -s $HOME_IP -o $INTERFACE_NAME -j MASQUERADE"

case "$1" in
    list)
        echo ""
        echo "Mevcut NAT Kuralları"
        echo "--------------------------------------------------------------"

        iptables -t nat -L PREROUTING -v -n | grep "DNAT" | while read -r line; do
            IN_IF=$(echo $line | awk '{print $3}')
            DST_IP=$(echo $line | awk '{print $8}')
            TARGET_IP=$(echo $line | awk -F'to:' '{print $2}')
            echo "[PREROUTING]    ${IN_IF} : ${DST_IP} → ${TARGET_IP}"
        done

        echo "--------------------------------------------------------------"

        iptables -t nat -L POSTROUTING -v -n | grep "SNAT" | while read -r line; do
            OUT_IF=$(echo $line | awk '{print $3}')
            SRC_IP=$(echo $line | awk '{print $8}')
            NAT_IP=$(echo $line | awk -F'to:' '{print $2}')
            echo "[POSTROUTING]   ${OUT_IF} : ${SRC_IP} → ${NAT_IP}"
        done

        echo "--------------------------------------------------------------"

        iptables -t nat -L POSTROUTING -v -n | grep "MASQUERADE" | while read -r line; do
            OUT_IF=$(echo $line | awk '{print $7}')
            SRC_IP=$(echo $line | awk '{print $8}')
            DST_IP=$(echo $line | awk '{print $9}')
            echo "[MASQUERADE]    ${OUT_IF} : ${SRC_IP} → ${DST_IP}"
        done

        echo "--------------------------------------------------------------"
        echo ""
        ;;
    
    add)
        if [ -z "$HOME_IP" ] || [ -z "$VPS_IP" ]; then
            echo "Geçersiz kullanım: tmnat add <ev_ip> <vps_ip>"
            exit 1
        fi
        echo "DNAT ve SNAT kuralları ekleniyor: $VPS_IP → $HOME_IP"
        eval "$ADD_COMMAND_DNAT"
        eval "$ADD_COMMAND_SNAT"
        eval "$SAVE_COMMAND"
        echo "Kurallar başarıyla eklendi."
        ;;

    remove)
        if [ -z "$HOME_IP" ] || [ -z "$VPS_IP" ]; then
            echo "Geçersiz kullanım: tmnat remove <ev_ip> <vps_ip>"
            exit 1
        fi
        echo "DNAT ve SNAT kuralları siliniyor: $VPS_IP → $HOME_IP"
        eval "$REMOVE_COMMAND_DNAT"
        eval "$REMOVE_COMMAND_SNAT"
        eval "$SAVE_COMMAND"
        echo "Kurallar başarıyla silindi."
        ;;

    save)
        echo "iptables kuralları kaydediliyor..."
        eval "$SAVE_COMMAND"
        echo "Kurallar başarıyla kaydedildi."
        ;;

    mask)
        if [ -z "$HOME_IP" ] || [ -z "$INTERFACE_NAME" ]; then
            echo "Geçersiz kullanım: tmnat mask <ev_ip> <interface>"
            exit 1
        fi
        echo "MASQUERADE kuralı ekleniyor: $HOME_IP → 0.0.0.0/0 via $INTERFACE_NAME"
        eval "$ADD_MASK"
        eval "$SAVE_COMMAND"
        echo "MASQUERADE kuralı başarıyla eklendi."
        ;;

    version)
        echo "tmnat v0.1"
        ;;

    help)
        echo "tmnat list   -> Kuralları listele"
        echo "tmnat add <ev_ip> <vps_ip>    -> Kural ekle"
        echo "tmnat remove <ev_ip> <vps_ip> -> Kural sil"
        echo "tmnat save   -> Kuralları kaydet"
        echo "tmnat mask <ev_ip> <interface> -> MASQUERADE kuralı ekle"
        echo "tmnat version   -> Script Versionu"
        ;;

    *)
        echo "Geçersiz komut. Tüm komut kullanımları :"
        echo "$0 list   -> Kuralları listele"
        echo "$0 add <ev_ip> <vps_ip>    -> Kural ekle"
        echo "$0 remove <ev_ip> <vps_ip> -> Kural sil"
        echo "$0 save   -> Kuralları kaydet"
        echo "$0 mask <ev_ip> <interface> -> MASQUERADE kuralı ekle"
        echo "$0 version   -> Script Versionu"
        ;;
esac
