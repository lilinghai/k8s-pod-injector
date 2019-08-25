FROM alpine:latest

ADD kube-mutating-webhook-sidecar /kube-mutating-webhook-sidecar
ENTRYPOINT ["./kube-mutating-webhook-sidecar"]
