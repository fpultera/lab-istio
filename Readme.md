# Ejemplo de laboratorio de Istio con ArgoCD y Hola Mundo

Este proyecto te guía para instalar Istio en Minikube usando ArgoCD, desplegar aplicaciones de ejemplo y probar el balanceo de tráfico con Istio.

---

## Requisitos

- Minikube instalado y corriendo.
- `kubectl` configurado para tu cluster Minikube.
- Acceso a terminal / consola.
- Permisos para ejecutar scripts.

---


## Instrucciones de instalación

### 1. Instalar Istio con ArgoCD

- Abre una terminal y ejecuta:

```bash
chmod +x scripts/argocd-install.sh
sh scripts/argocd-install.sh lab-istio
```
- Al finalizar verás un mensaje con la contraseña del usuario admin para ArgoCD, por ejemplo:

```bash
--------------------------------------------------------
Obteniendo la contraseña inicial del usuario 'admin'...
Contraseña de admin: -g4FECa1eksxZAgC
Guarda esta contraseña, ya que la necesitarás para iniciar sesión.
--------------------------------------------------------
```

### 2. Levantar el túnel de Minikube para Istio

- Abre una nueva terminal (no cierres la anterior) y ejecuta:

```bash
minikube tunnel -p lab-istio
```

### 3. Aplicar configuración de Istio

```bash
kubectl apply -f infra/istio.yaml
```

- Luego verifica en la UI de ArgoCD que las aplicaciones de Istio estén sincronizadas.

- Si alguna app de isitio no sincroniza, deletea el pod.

### 4. Obtener la IP externa del istio-ingressgateway

- Ejecuta:

```bash
kubectl get svc -n istio-system
```

- SI el tunnel no esta creado, el svc no va a levantar el cluster-ip

### 5. Vault

Para instalar vault en tu cluster de minikube, ejecuta:

```bash
❯ kubectl apply -f apps/vault.yaml
❯ kubectl apply -f apps/vault-domain.yaml
❯ kubectl apply -f apps/vault-storage.yaml
```

### 6. Configurar /etc/hosts

```bash
10.110.47.29 hola-mundo-final.local vault.local

```

- Busca la IP en la columna EXTERNAL-IP para el servicio istio-ingressgateway. Ejemplo:

```bash
NAME                   TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)                                      AGE
istio-ingressgateway   LoadBalancer   10.110.47.229   10.110.47.229   15021:32375/TCP,80:31856/TCP,443:31773/TCP   3m21s
```

### 7. instala el cliente de vault en tu notebookubectllocal. Pacman, dpkg, apt, apk, lo que prefieras.

```bash
export VAULT_ADDR='http://vault.local'
vault login root
```

### 8. Habilitar el método de autenticación (si no lo hiciste antes)

```bash
vault auth enable kubernetes
```

## Obtener el token

```bash
export VAULT_SA_TOKEN=$(kubectl get secret vault-token -n vault -o jsonpath="{.data.token}" | base64 --decode)
```

## Obtener el certificado CA del ServiceAccount

```bash
export VAULT_CA_CERT=$(kubectl get secret vault-token -n vault -o jsonpath="{.data['ca\.crt']}" | base64 --decode)
```

## Configurar el backend

```bash
vault write auth/kubernetes/config \
    token_reviewer_jwt="$VAULT_SA_TOKEN" \
    kubernetes_host="https://kubernetes.default.svc.cluster.local" \
    kubernetes_ca_cert="$VAULT_CA_CERT"
```

## Crear una política de Vault para hola-mundo y hola-mundo-v2:

```bash
vault policy write my-policy-hola-mundo - <<EOF
path "secret/data/hola-mundo/config" {
  capabilities = ["read"]
}
EOF

vault policy write my-policy-hola-mundo-v2 - <<EOF
path "secret/data/hola-mundo-v2/config" {
  capabilities = ["read"]
}
EOF
```

## Crear y vincular el rol de Kubernetes para hola-mundo y hola-mundo-v2:

```bash
vault write auth/kubernetes/role/my-role-hola-mundo \
    bound_service_account_names=hola-mundo-sa \
    bound_service_account_namespaces=hola-mundo \
    policies=my-policy-hola-mundo \
    ttl=3000h

vault write auth/kubernetes/role/my-role-hola-mundo-v2 \
    bound_service_account_names=hola-mundo-sa-v2 \
    bound_service_account_namespaces=hola-mundo-v2 \
    policies=my-policy-hola-mundo-v2 \
    ttl=3000h
```

## crear un vault secret:

```bash
vault kv put secret/hola-mundo/config url=asd.local
vault kv put secret/hola-mundo-v2/config url=asddgf.local
```

## como ver el secret:

```bash
hola-mundo
kubectl exec -it <nombre-del-pod> -n <namespace> -- /bin/sh
cd /mnt/secrets-store/secret/data/hola-mundo
cat config

hola-mundo-v2
kubectl exec -it <nombre-del-pod> -n <namespace> -- /bin/sh
cd /mnt/secrets-store/secret/data/hola-mundo-v2
cat config
```

## Si entras con bash podes instalar el jq.

```bash
apt pdate
apt update
apt install jq -y

cat /mnt/secrets-store/secret/data/hola-mundo-v2/config |jq .
```

### 9. Desplegar aplicaciones de ejemplo

```bash
kubectl apply -f apps/hola-mundo.yaml
kubectl apply -f apps/hola-mundo-v2.yaml
```

### 10. Probar balanceo con Istio

- Para balanceo basado en peso:

```bash
kubectl apply -f apps/hola-mundo-final-weight.yaml
```

- Para balanceo basado en headers HTTP:

```bash
kubectl apply -f apps/hola-mundo-final-headers.yaml
```

### 11. Pruebas con curl
- Balanceo por Headers si aplicaste el yaml hola-mundo-final-headers.yaml

```bash
curl -H "x-version-app: v2" hola-mundo-final.local
<html>
  <body>
    <h1>Hola Mundo v2 desde Istio 🚀</h1>
  </body>
</html>

curl -H "x-version-app: v1" hola-mundo-final.local
<html>
  <body>
    <h1>Hola Mundo v1 desde Istio 🚀</h1>
  </body>
</html>
```

- Balanceo por Peso si aplicaste el yaml hola-mundo-final-weight.yaml

```bash
curl hola-mundo-final.local
# Respuestas alternadas entre Hola Mundo v1 y v2
```

- Ejemplo de respuesta:

```bash
<html>
  <body>
    <h1>Hola Mundo v2 desde Istio 🚀</h1>
  </body>
</html>

<html>
  <body>
    <h1>Hola Mundo desde Istio 🚀</h1>
  </body>
</html>
```

- Balanceo por Peso si aplicaste el yaml hola-mundo-final-queryparameter.yaml

```bash
curl "http://hola-mundo-final.local/?Id=1234"
# Respuestas alternadas entre Hola Mundo
curl "http://hola-mundo-final.local/?Id=5678"
# Respuestas alternadas entre Hola Mundo v2
```

- Ejemplo de respuesta:

```bash
❯ curl "http://hola-mundo-final.local/?Id=1234"
<html>
  <body>
    <h1>Hola Mundo desde Istio 🚀</h1>
  </body>
</html>

❯ curl "http://hola-mundo-final.local/?Id=5678"
<html>
  <body>
    <h1>Hola Mundo v2 desde Istio 🚀</h1>
  </body>
</html>
```

- Balanceo por User Parameter ID si aplicaste el yaml hola-mundo-final-userparameterid.yaml

```bash
curl -H "http://hola-mundo-final.local/"
# Respuesta default v1
curl -H "user-session-id: v1" "http://hola-mundo-final.local/"
# Respuestas alternadas entre Hola Mundo
curl -H "user-session-id: v2" "http://hola-mundo-final.local/"
# Respuestas alternadas entre Hola Mundo v2
```

- Ejemplo de respuesta:

```bash
❯ curl -H "user-session-id: v1" "http://hola-mundo-final.local/"
<html>
  <body>
    <h1>Hola Mundo desde Istio 🚀</h1>
  </body>
</html>

❯ curl -H "user-session-id: v2" "http://hola-mundo-final.local/"
<html>
  <body>
    <h1>Hola Mundo v2 desde Istio 🚀</h1>
  </body>
</html>
```

Una ves 

Notas importantes:

- No cierres las terminales donde ejecutaste minikube tunnel ni el script de instalación, ya que mantienen servicios activos.

- Guarda la contraseña del usuario admin para acceder a ArgoCD UI.

- Para acceder a ArgoCD UI, abre un navegador en http://localhost:8080 (o el puerto configurado).

