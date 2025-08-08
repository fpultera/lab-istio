minikube start --driver=docker --memory=8192 --cpus=4 -p lab-istio


kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

kubectl get secret argocd-initial-admin-secret -n argocd -o yaml | grep password | cut -d ':' -f 2 | tr -d ' ' | base64 -d


kubectl port-forward svc/argocd-server -n argocd 8080:443

kubectl apply -f applications/nginx-app-from-git.yaml

