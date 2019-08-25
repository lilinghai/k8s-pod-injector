# k8s inject sidecar to pod with Mutating Admission Webhook and CRD

## Environment
- minikube version: v1.3.1
```
1. MutatingAdmissionWebhook admission controllers should be added in the admission-control flag of kube-apiserve
2. kubectl api-versions | grep admissionregistration.k8s.io/v1beta1 
The result should be:
admissionregistration.k8s.io/v1beta1
```
- docker version: 19.03.1
- go version go1.12.9
- go dep version: v0.5.4

## Build
build webhook server and push docker image
```
./build
```

## Deploy

- Create a signed cert/key pair and store it in a Kubernetes `secret` that will be consumed by sidecar deployment
```
./deployment/webhook-create-signed-cert.sh \
    --service sidecar-injector-webhook-svc \
    --secret sidecar-injector-webhook-certs \
    --namespace default
```
- Patch the `MutatingWebhookConfiguration` by set `caBundle` with correct value from Kubernetes cluster
```
cat deployment/mutatingwebhook.yaml | \
    deployment/webhook-patch-ca-bundle.sh > \
    deployment/mutatingwebhook-ca-bundle.yaml
```

- create serviceaccount
```
./serviceaccount.sh
```

- Deploy resources
```
kubectl create -f crd.yaml
kubectl create -f deployment/sidecar.yaml
kubectl create -f deployment/deployment.yaml
kubectl create -f deployment/service.yaml
kubectl create -f deployment/mutatingwebhook-ca-bundle.yaml
```

## Verify

1. The sidecar inject webhook should be running
```
[root@mstnode ~]# kubectl get pods
NAME                                                   READY   STATUS    RESTARTS   AGE
sidecar-injector-webhook-deployment-857664f948-gj568   2/2     Running   0          40m

[root@mstnode ~]# kubectl get deployment
NAME                                  READY   UP-TO-DATE   AVAILABLE   AGE
sidecar-injector-webhook-deployment   1/1     1            1           41m
```

2. Label the default namespace with `sidecar-injector=enabled`
```
kubectl label namespace default sidecar-injector=enabled
[root@mstnode ~]# kubectl get namespace -L sidecar-injector
NAME          STATUS    AGE       SIDECAR-INJECTOR
default       Active    18h       enabled
kube-public   Active    18h
kube-system   Active    18h
```

3. Deploy an app in Kubernetes cluster, take `sleep` app as an example
```
[root@mstnode ~]# cat <<EOF | kubectl create -f -
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: sleep
spec:
  replicas: 1
  template:
    metadata:
      annotations:
        sidecar-injector-webhook.morven.me/inject: "yes"
      labels:
        app: sleep
        injector: simplehttp
    spec:
      containers:
      - name: sleep
        image: tutum/curl
        command: ["/bin/sleep","infinity"]
        imagePullPolicy: 
EOF
```

4. Verify sidecar container injected
```
[root@mstnode ~]# kubectl get pods
NAME                                                   READY   STATUS    RESTARTS   AGE
sidecar-injector-webhook-deployment-857664f948-gj568   2/2     Running   0          40m
sleep-85d76c97dc-78rnc                                 2/2     Running   0          39m
```
