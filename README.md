# Script d'Installation et de Configuration SNMP
Ce script Bash automatise l'installation et la configuration de SNMP sur un système Debian. Il effectue les tâches suivantes :

* Vérifie si l'utilisateur est root.
* Sauvegarde les fichiers de configuration sources.list et snmpd.conf.
* Commente ou décommente des lignes spécifiques dans sources.list.
* Installe les paquets SNMP.
* Ajoute ou modifie des configurations spécifiques dans snmpd.conf.
* Redémarre le service SNMP et vérifie son statut.

## Prérequis
Ce script doit être exécuté en tant que root.
Le système doit être basé sur Debian (par exemple, Debian, Ubuntu).
Utilisation
Téléchargez le script sur votre machine.
Rendez le script exécutable :
```
chmod +x EnableSNMP.sh
```

Exécutez le script :
```
sudo ./EnableSNMP.sh
```

## Fonctionnalités
* Vérification des privilèges root : Le script s'assure qu'il est exécuté en tant que root.
* Sauvegarde des fichiers de configuration : Les fichiers sources.list et snmpd.conf sont sauvegardés avant toute modification.
* Commentaire et décommentaire des lignes : Le script peut commenter ou décommenter des lignes spécifiques dans sources.list.
* Installation des paquets SNMP : Le script installe les paquets snmp et snmpd.
* Configuration de snmpd.conf : Le script ajoute ou modifie des configurations spécifiques dans snmpd.conf.
* Redémarrage du service SNMP : Le script redémarre le service SNMP et vérifie son statut.

## Journalisation
Toutes les actions et messages d'erreur sont journalisés dans /var/log/snmp_install.log.
