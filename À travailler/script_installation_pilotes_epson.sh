#!/usr/bin/bash

# Indiquer l'adresse à laquelle aller chercher les pilotes
printf "Rendez vous à cette adresse : https://download.ebz.epson.net/dsc/search/01/search/?OSC=LX (ctrl + clic pour l’ouvrir directement)\n"

# Demander à entrer l'adresse où télécharger les pilotes
read -p "Et entrez l'adresse exacte de téléchargement du pilote de l'imprimante :"$'\n' printer_driver_url
echo "Voici l'adresse des pilotes : $printer_driver_url"

# Déclarer les variables
#printer_driver_url=
#scanner_driver_url=

https://www.openprinting.org
