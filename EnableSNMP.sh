#!/bin/bash

# Définition des couleurs pour une meilleure lisibilité
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Définition des chemins
SOURCES_LIST="/etc/apt/sources.list"
SNMPD_CONF="/etc/snmp/snmpd.conf"
LOG_FILE="/var/log/snmp_install.log"

# Fonction pour logger les messages
log_message() {
    local message="$1"
    local level="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} - ${level}: ${message}" >> "$LOG_FILE"
    
    case "$level" in
        "INFO") echo -e "${GREEN}[INFO]${NC} $message" ;;
        "ERROR") echo -e "${RED}[ERROR]${NC} $message" ;;
        "WARNING") echo -e "${YELLOW}[WARNING]${NC} $message" ;;
    esac
}

# Fonction pour vérifier si l'utilisateur est root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_message "Ce script doit être exécuté en tant que root" "ERROR"
        exit 1
    fi
}

# Fonction pour sauvegarder les fichiers de configuration
backup_files() {
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    if [ -f "$SOURCES_LIST" ]; then
        cp "$SOURCES_LIST" "${SOURCES_LIST}.backup_${timestamp}"
        log_message "Sauvegarde de sources.list créée" "INFO"
    fi
    if [ -f "$SNMPD_CONF" ]; then
        cp "$SNMPD_CONF" "${SNMPD_CONF}.backup_${timestamp}"
        log_message "Sauvegarde de snmpd.conf créée" "INFO"
    fi
}

# Fonction pour commenter les lignes spécifiques
comment_lines() {
    log_message "Commentaire des lignes dans sources.list" "INFO"
    if ! sed -i 's/^deb http:\/\/deb.debian.org\/debian bookworm main contrib/#deb http:\/\/deb.debian.org\/debian bookworm main contrib/' "$SOURCES_LIST"; then
        log_message "Erreur lors du commentaire des lignes dans sources.list" "ERROR"
        return 1
    fi
    if ! sed -i 's/^deb http:\/\/deb.debian.org\/debian bookworm-updates main contrib/#deb http:\/\/deb.debian.org\/debian bookworm-updates main contrib/' "$SOURCES_LIST"; then
        log_message "Erreur lors du commentaire des lignes de mise à jour dans sources.list" "ERROR"
        return 1
    fi
    return 0
}

# Fonction pour décommenter les lignes spécifiques
uncomment_lines() {
    log_message "Décommentage des lignes dans sources.list" "INFO"
    if ! sed -i 's/^#deb http:\/\/deb.debian.org\/debian bookworm main contrib/deb http:\/\/deb.debian.org\/debian bookworm main contrib/' "$SOURCES_LIST"; then
        log_message "Erreur lors du décommentage des lignes dans sources.list" "ERROR"
        return 1
    fi
    if ! sed -i 's/^#deb http:\/\/deb.debian.org\/debian bookworm-updates main contrib/deb http:\/\/deb.debian.org\/debian bookworm-updates main contrib/' "$SOURCES_LIST"; then
        log_message "Erreur lors du décommentage des lignes de mise à jour dans sources.list" "ERROR"
        return 1
    fi
    return 0
}

# Fonction pour ajouter la ligne rocommunity
add_rocommunity() {
    log_message "Ajout de la configuration rocommunity" "INFO"
    if ! grep -q "^rocommunity H3Campus" "$SNMPD_CONF"; then
        if ! echo "rocommunity H3Campus  192.168.1.252/32  -V systemview" >> "$SNMPD_CONF"; then
            log_message "Erreur lors de l'ajout de rocommunity" "ERROR"
            return 1
        fi
    else
        log_message "La configuration rocommunity existe déjà" "WARNING"
    fi
    return 0
}

# Fonction pour remplacer agentaddress
replace_agentaddress() {
    log_message "Modification de l'agentaddress" "INFO"
    if ! sed -i 's/^agentaddress\s*127.0.0.1,\[\:\:1]/agentaddress udp:161/' "$SNMPD_CONF"; then
        log_message "Erreur lors du remplacement de l'agentaddress" "ERROR"
        return 1
    fi
    return 0
}

# Fonction pour remplacer sysContact
replace_syscontact() {
    log_message "Modification du sysContact" "INFO"
    if ! sed -i 's/^sysContact     Me <me@example.org>/sysContact     AdminH3 <admin@h3campus.fr>/' "$SNMPD_CONF"; then
        log_message "Erreur lors du remplacement du sysContact" "ERROR"
        return 1
    fi
    return 0
}

# Fonction pour installer les paquets
install_packages() {
    log_message "Installation des paquets SNMP" "INFO"
    if ! apt update; then
        log_message "Erreur lors de la mise à jour des paquets" "ERROR"
        return 1
    fi
    if ! apt install -y snmp snmpd; then
        log_message "Erreur lors de l'installation des paquets SNMP" "ERROR"
        return 1
    fi
    return 0
}

# Fonction principale
main() {
    check_root
    log_message "Début de l'installation SNMP" "INFO"
    
    backup_files
    
    # Exécution des étapes avec vérification des erreurs
    uncomment_lines || exit 1
    install_packages || exit 1
    add_rocommunity || exit 1
    replace_agentaddress || exit 1
    replace_syscontact || exit 1
    comment_lines || exit 1
    
    log_message "Redémarrage du service SNMP" "INFO"
    if ! systemctl restart snmpd.service; then
        log_message "Erreur lors du redémarrage du service SNMP" "ERROR"
        exit 1
    fi
    
    # Vérification du statut du service
    if systemctl is-active --quiet snmpd.service; then
        log_message "Service SNMP démarré avec succès" "INFO"
    else
        log_message "Le service SNMP n'a pas démarré correctement" "ERROR"
        exit 1
    fi
    
    log_message "Installation terminée avec succès" "INFO"
}

# Exécution du script
main
