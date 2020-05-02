# Egress Gateway

<!-- TOC -->

- [Egress Gateway](#egress-gateway)
  - [Setup](#setup)
  - [Istio Egress Gateway](#istio-egress-gateway)
    - [ALLOW_ANY or REGISTRY_ONLY](#allowany-or-registryonly)
    - [Service Entry](#service-entry)
  - [Clean Up](#clean-up)
  - [Next Topic](#next-topic)

<!-- /TOC -->

## Setup

Deploy Frontend and Backend App. Make sure that frontend-v1, frontend-service, frontend-route, backend-v1/v2, backend-service are created as in previous labs. These file are also stored in /ocp directory. Apply those files or just run [deploy.sh](../scripts/deploy.sh) shell script
```bash
scripts/deploy.sh
```

## Istio Egress Gateway

### ALLOW_ANY or REGISTRY_ONLY

By default Istio allows requests to go outside Service Mesh. This configuration is in configmap **istio** within Istio Control Plane project.

Check configmap **istio**
```bash
oc get configmap istio -n ${USERID}-istio-system -o jsonpath='{.data.mesh}' | grep "mode: ALLOW_ANY"
```
You will get output similar to this
```yaml
mode: ALLOW_ANY
```
We can change this behavior of Istio to **locking-by-default** policy by change from *ALLOW_ANY* to *REGISTRY_ONLY*. The mode *REGISTRY_ONLY* ONLY allows outbound traffic to services defined in the service registry as well as those defined through ServiceEntries. Modify the Istio ConfigMap to change to *REGISTRY_ONLY*:

```bash
 oc get configmap istio -n ${USERID}-istio-system -o yaml \
  | sed 's/mode: ALLOW_ANY/mode: REGISTRY_ONLY/g' \
  | oc replace -n ${USERID}-istio-system -f -
```
Test with cURL to Frontend.
```bash
curl -v ${FRONTEND_URL}

#Sample output - response with 503 error 
Frontend version: v1 => [Backend: http://backend:8080, Response: 503, Body: Backend version:v2, Response:503, Host:backend-v2-549bbcbdd6-q2wfs, Status:503, Message: Remote host terminated the handshake]* Closing connection 0
```
Run [run-50.sh](../scripts/run-50.sh) and Check Kiali Console Graph

![Kiali Console REGISTRY_ONLY](../images/kiali-console-egress-registry-only.png)

### Service Entry
As we can see that REGISTRY_ONLY mode does not allow all the traffics. In order to allow those traffics to external addresses, we need to create ServiceEntry resource. Let create a ServiceEntry to allow egress traffic to httpbin.org and allow only HTTPS and port 443. 

Check for [egress-serviceentry.yml](../istio-files/egress-serviceentry.yml)
```yaml
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: http.bin
spec:
  hosts:
  - httpbin.org
  ports:
  - number: 443
    name: https
    protocol: HTTPS
  resolution: DNS
  location: MESH_EXTERNAL
```

This file is also created and stored in [egress-serviceentry.yml](../istio-files/egress-serviceentry.yml).
Test again with cURL to Frontend
```bash
oc apply -f istio-files/egress-serviceentry.yml -n $USERID
curl ${FRONTEND_URL}
# Check that Response code is 200
```
Run [run-50.sh](../scripts/run-50.sh) and Check Kiali Console Graph

![Kiali Console Egress ServiceEntry](../images/kiali-console-egress-service-entry.png)

## Clean Up
Reconfigure istio configmap back to ALLOW_ANY
```bash
 oc get configmap istio -n ${USERID}-istio-system -o yaml \
  | sed 's/mode: REGISTRY_ONLY/mode: ALLOW_ANY/g' \
  | oc replace -n ${USERID}-istio-system -f -
```

Delete the Egress ServiceEntry created before or just run "oc delete" command with yaml file of ServiceEntry stored within istio-files.

```bash
oc delete -f istio-files/egress-serviceentry.yml -n $USERID

```

## Next Topic

[Timeout](./07-timeout.md)
