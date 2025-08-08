#!/bin/bash

# Colores
YELLOW="\033[1;33m"
NC="\033[0m" # Sin color

# Este script automatiza la instalación de Argo CD en un clúster de Minikube
# que se pasa como argumento.
#
# Uso: ./instalar_argocd.sh <nombre-del-cluster>
# Ejemplo: ./instalar_argocd.sh lab-istio

# --- PASO 1: Validar que se haya pasado un nombre de clúster ---
if [ -z "$1" ]; then
    echo -e "${YELLOW}Error: Debes proporcionar el nombre del cluster de Minikube.${NC}"
    echo -e "${YELLOW}Uso: $0 <nombre-del-cluster>${NC}"
    exit 1
fi

CLUSTER_NAME=$1

# --- PASO 2: Verificar e iniciar el clúster de Minikube ---
echo -e "${YELLOW}Verificando si el cluster de Minikube '$CLUSTER_NAME' ya existe y está corriendo...${NC}"
if minikube status -p "$CLUSTER_NAME" > /dev/null 2>&1; then
    echo -e "${YELLOW}El cluster '$CLUSTER_NAME' ya existe y está listo. Saltando el 'minikube start'.${NC}"
else
    echo -e "${YELLOW}El cluster '$CLUSTER_NAME' no existe o no está corriendo. Iniciándolo...${NC}"
    minikube start --driver=docker --memory=8192 --cpus=4 -p "$CLUSTER_NAME"
fi

# --- PASO 3: Crear el namespace 'argocd' ---
echo -e "${YELLOW}Creando el namespace 'argocd'...${NC}"
kubectl create namespace argocd

# --- PASO 4: Instalar Argo CD en el clúster ---
echo -e "${YELLOW}Aplicando los manifiestos de instalación de Argo CD...${NC}"
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Esperamos a que los pods de Argo CD estén listos
echo -e "${YELLOW}Esperando a que los pods de Argo CD estén listos. Esto puede tardar un momento...${NC}"
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s

# --- PASO 5: Obtener la contraseña inicial de 'admin' ---
echo -e "${YELLOW}--------------------------------------------------------${NC}"
echo -e "${YELLOW}Obteniendo la contraseña inicial del usuario 'admin'...${NC}"
ARGO_CD_PASSWORD=$(kubectl get secret argocd-initial-admin-secret -n argocd -o yaml | grep password | cut -d ':' -f 2 | tr -d ' ' | base64 -d)
echo -e "${YELLOW}Contraseña de admin: $ARGO_CD_PASSWORD${NC}"
echo -e "${YELLOW}Guarda esta contraseña, ya que la necesitarás para iniciar sesión.${NC}"
echo -e "${YELLOW}--------------------------------------------------------${NC}"

# --- PASO 6: Acceder a la UI de Argo CD a través de port-forward ---
echo -e "${YELLOW}Ejecutando port-forward para acceder a la interfaz web de Argo CD en https://localhost:8080${NC}"
echo -e "${YELLOW}Presiona Ctrl+C para detener el port-forward.${NC}"
kubectl port-forward svc/argocd-server -n argocd 8080:443
