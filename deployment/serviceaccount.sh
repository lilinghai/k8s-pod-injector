#!/bin/bash
kubectl create serviceaccount sidecar-injector
kubectl create clusterrolebinding sidecar-injector --clusterrole=cluster-admin --serviceaccount=default:sidecar-injector
