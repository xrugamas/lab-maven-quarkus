#!/usr/bin/env bash
# Laboratorio Maven + Quarkus · Paso 1: herramientas del sistema (pide tu contraseña de sudo)
# Ejecutar con:  bash ~/labs/lab-maven-quarkus/scripts/01-instalar-herramientas.sh
set -euo pipefail

echo "== 1/2 Paquetes de Ubuntu: zip (lo exige SDKMAN), tree y la CLI de GitHub (gh)"
sudo apt update
sudo apt install -y zip unzip tree gh

echo "== 2/2 Descargar el instalador de SDKMAN para REVISARLO antes de ejecutarlo"
curl -s "https://get.sdkman.io" -o /tmp/sdkman-install.sh
echo
echo "Instalador guardado en /tmp/sdkman-install.sh"
echo "Revísalo (less /tmp/sdkman-install.sh) y, si todo está bien, ejecútalo con:"
echo "    bash /tmp/sdkman-install.sh && source ~/.sdkman/bin/sdkman-init.sh"
echo "Luego sigue con la Parte 1.3 de GUIA.md (Java 21, Maven y Quarkus CLI)."
