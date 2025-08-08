#!/bin/bash

# Este script automatiza la instalación de Argo CD en un clúster de Minikube
# que se pasa como argumento.
#
# Uso: ./instalar_argocd.sh <nombre-del-cluster>
# Ejemplo: ./instalar_argocd.sh lab-istio

# --- PASO 1: Validar que se haya pasado un nombre de clúster ---
if [ -z "$1" ]; then
    echo "Error: Debes proporcionar el nombre del cluster de Minikube."
    echo "Uso: $0 <nombre-del-cluster>"
    exit 1
fi

CLUSTER_NAME=$1

# --- PASO 2: Verificar e iniciar el clúster de Minikube ---
echo "Verificando si el cluster de Minikube '$CLUSTER_NAME' ya existe y está corriendo..."
if minikube status -p "$CLUSTER_NAME" > /dev/null 2>&1; then
    echo "El cluster '$CLUSTER_NAME' ya existe y está listo. Saltando el 'minikube start'."
else
    echo "El cluster '$CLUSTER_NAME' no existe o no está corriendo. Iniciándolo..."
    minikube start --driver=docker --memory=8192 --cpus=4 -p "$CLUSTER_NAME"
fi

# --- PASO 3: Crear el namespace 'argocd' ---
echo "Creando el namespace 'argocd'..."
kubectl create namespace argocd

# --- PASO 4: Instalar Argo CD en el clúster ---
echo "Aplicando los manifiestos de instalación de Argo CD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Esperamos a que los pods de Argo CD estén listos
echo "Esperando a que los pods de Argo CD estén listos. Esto puede tardar un momento..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s

# --- PASO 5: Obtener la contraseña inicial de 'admin' ---
echo "--------------------------------------------------------"
echo "Obteniendo la contraseña inicial del usuario 'admin'..."
ARGO_CD_PASSWORD=$(kubectl get secret argocd-initial-admin-secret -n argocd -o yaml | grep password | cut -d ':' -f 2 | tr -d ' ' | base64 -d)
echo "Contraseña de admin: $ARGO_CD_PASSWORD"
echo "Guarda esta contraseña, ya que la necesitarás para iniciar sesión."
echo "--------------------------------------------------------"

# --- PASO 6: Acceder a la UI de Argo CD a través de port-forward ---
# Este comando se quedará ejecutando y bloqueará la terminal.
# Para detenerlo y volver al prompt, presiona Ctrl+C.
echo "Ejecutando port-forward para acceder a la interfaz web de Argo CD en https://localhost:8080"
echo "Presiona Ctrl+C para detener el port-forward."
kubectl port-forward svc/argocd-server -n argocd 8080:443
