# Istio Lab with ArgoCD and Hola Mundo Example

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

Abre una terminal y ejecuta:

```bash
chmod +x scripts/argocd-install.sh
sh scripts/argocd-install.sh lab-istio
```
Al finalizar verás un mensaje con la contraseña del usuario admin para ArgoCD, por ejemplo:

```bash
--------------------------------------------------------
Obteniendo la contraseña inicial del usuario 'admin'...
Contraseña de admin: -g4FECa1eksxZAgC
Guarda esta contraseña, ya que la necesitarás para iniciar sesión.
--------------------------------------------------------
```

### 2. Levantar el túnel de Minikube para Istio

Abre una nueva terminal (no cierres la anterior) y ejecuta:

```bash
minikube tunnel -p lab-istio
```

### 3. Aplicar configuración de Istio

```bash
kubectl apply -f infra/istio.yaml
```

Luego verifica en la UI de ArgoCD que las aplicaciones de Istio estén sincronizadas.

### 4. Desplegar aplicaciones de ejemplo

```bash
kubectl apply -f apps/hola-mundo.yaml
kubectl apply -f apps/hola-mundo-v2.yaml
```

### 5. Probar balanceo con Istio

Para balanceo basado en peso:

```bash
kubectl apply -f apps/hola-mundo-final-weight.yaml
```

Para balanceo basado en headers HTTP:

```bash
kubectl apply -f apps/hola-mundo-final-headers.yaml
```

### 6. Obtener la IP externa del istio-ingressgateway

Ejecuta:

```bash
kubectl get svc -n istio-system
```

Busca la IP en la columna EXTERNAL-IP para el servicio istio-ingressgateway. Ejemplo:

```bash
NAME                   TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)                                      AGE
istio-ingressgateway   LoadBalancer   10.110.47.229   10.110.47.229   15021:32375/TCP,80:31856/TCP,443:31773/TCP   3m21s
```

### 7. Configurar /etc/hosts

```bash
10.110.47.29 hola-mundo-final.local
```

### 8. Pruebas con curl
Balanceo por Headers si aplicaste el yaml hola-mundo-final-headers.yaml

```bash
curl -H "x-version-app: v2" hola-mundo-final.local
# Devuelve Hola Mundo v2

curl -H "x-version-app: v1" hola-mundo-final.local
# Devuelve Hola Mundo v1
```

Balanceo por Peso si aplicaste el yaml hola-mundo-final-weight.yaml

```bash
curl hola-mundo-final.local
# Respuestas alternadas entre Hola Mundo v1 y v2
```

Ejemplo de respuesta:

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

Notas importantes
. No cierres las terminales donde ejecutaste minikube tunnel ni el script de instalación, ya que mantienen servicios activos.
. Guarda la contraseña del usuario admin para acceder a ArgoCD UI.
. Para acceder a ArgoCD UI, abre un navegador en http://localhost:8080 (o el puerto configurado).

