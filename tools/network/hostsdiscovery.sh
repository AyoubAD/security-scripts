#!/bin/bash
# Autor: Ayoub - Inspirado en s4vitar - Academia Hack4u  

: <<'DESCRIPTION'
hostdiscover.sh - Script para descubrir hosts activos en una red local, los que responden al ping.

Este script detecta automáticamente la IP y la máscara de subred de la interfaz de red activa,
calcula el rango de direcciones IP disponibles y realiza un escaneo de ping para identificar
hosts activos en la red.

Uso:
    ./hostdiscover.sh

No se requieren parámetros. 

Requisitos:
    - ipcalc
    - ping

DESCRIPTION

# Función para manejar la interrupción con Ctrl+C
function ctrl_c(){
    echo -e "\n\n[!] Saliendo...\n"
    tput cnorm # Recuperar la visibilidad del cursor
    exit 1
}

# Captura la señal SIGINT (Ctrl+C) y llama a la función ctrl_c
trap ctrl_c SIGINT

# Obtener la IP y la máscara de red de la interfaz activa
ip_info=$(ip -o -f inet addr show | awk '/scope global/ {print $4}')
if [ -z "$ip_info" ]; then
    echo -e "[!] No se pudo detectar la IP y la máscara de red."
    exit 1
fi

# Extraer la IP y la máscara de red
ip_address=$(echo "$ip_info" | cut -d '/' -f 1)
subnet_mask=$(echo "$ip_info" | cut -d '/' -f 2)

# Usar ipcalc para obtener la información de la red
network_info=$(ipcalc -n -b $ip_address/$subnet_mask)

# Verificar si ipcalc devolvió la información correctamente
if [ -z "$network_info" ]; then
    echo -e "[!] Error al calcular la red con ipcalc."
    exit 1
fi

# Extraer la dirección de red y la máscara
network=$(echo "$network_info" | grep "Network" | awk '{print $2}')
subnet_mask=$(echo "$network_info" | grep "Netmask" | awk '{print $2}')

# Extraer la base de la red sin la máscara
IFS='.' read -r n1 n2 n3 n4 <<< "$network"
network_base="${n1}.${n2}.${n3}"

# Calcular el rango de direcciones IP basado en la máscara de subred
IFS='.' read -r m1 m2 m3 m4 <<< "$subnet_mask"
hosts=$(( (256 - $m4) - 2 ))

echo -e "\n[*] IP detectada: $ip_address"
echo -e "[*] Red detectada: $network"
echo -e "[*] Máscara de subred: $subnet_mask"
echo -e "[*] Número de direcciones disponibles: $hosts"

echo -e "\n[*] Escaneando la red: ${network}\n"

# Ocultar el cursor para mejorar la apariencia mientras se ejecuta el escaneo
tput civis 

# Escanear los hosts en la red
for i in $(seq 1 $hosts); do
    timeout 1 bash -c "ping -c 1 ${network_base}.$i" &>/dev/null && echo "[+] Host ${network_base}.$i - ACTIVE" &
done

wait

tput cnorm # Recuperar la visibilidad del cursor