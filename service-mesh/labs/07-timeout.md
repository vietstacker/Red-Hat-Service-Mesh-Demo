# Control Traffic with Timeout

<!-- TOC -->

- [Control Traffic with Timeout](#control-traffic-with-timeout)
  - [Setup](#setup)
- [Virtual Service](#virtual-service)
  - [Cleanup](#cleanup)
  - [Next Topic](#next-topic)

<!-- /TOC -->

## Setup

Currently backend v2 is set to delay response in 6 sec. We will set backend virtual service to wait for 3 sec (timeout 3 sec).  Frontend will received HTTP response with Gateway Timeout (504) if elapsed time is longer than timeout period.

NOTE: Before moving on, make sure that the egress traffic mode of Istio is configured back to ALLOW_ANY and ServiceEntry is deleted from lab 6.

![Timeout 3s](../images/microservices-timeout-3s.png)

Again, make sure that frontend-v1 deployment, frontend service, frontend route, backend-v1/v2-deployment, backend service are created as previous labs. These files are stored in /ocp directory.

# Virtual Service

Create a VirtualService that has 3s timeout. If you have created this virtualservice in the previous labs, running the below yaml file will update the existing virtualservice. This file is stored in [virtual-service-backend-v1-v2-50-50-3s-timeout.yml](../istio-files/virtual-service-backend-v1-v2-50-50-3s-timeout.yml)

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: backend-virtual-service
spec:
  hosts:
  - backend
  http:
  - timeout: 3s
    route:
    - destination:
        host: backend
        subset: v1
      weight: 50
    - destination:
        host: backend
        subset: v2
      weight: 50
```

Also create a DestinationRule for backend
```yaml
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: backend-destination-rule
spec:
  host: backend
  subsets:
  - name: v1
    labels:
      app: backend
      version: v1
    trafficPolicy:
      loadBalancer:
        simple: ROUND_ROBIN
  - name: v2
    labels:
      app: backend
      version: v2
    trafficPolicy:
      loadBalancer:
        simple: ROUND_ROBIN
```
These yaml files are stored in /istio-files directory.

Test again with cURL and check for 504 response code from backend version v2

```bash
curl $FRONTEND_URL
```

Result

```bash
Frontend version: v1 => [Backend: http://backend:8080, Response: 504, Body: upstream request timeout]
```

Run [run-50.sh](../scripts/run-50.sh)

```bash
scripts/run-50.sh
```

Sample output
```log
...
Backend:v1, Response Code: 200, Host:backend-v1-6ddf9c7dcf-pppzc, Elapsed Time:0.774024 sec
Backend:, Response Code: 504, Host:, Elapsed Time:3.193873 sec
Backend:v1, Response Code: 200, Host:backend-v1-6ddf9c7dcf-pppzc, Elapsed Time:0.787584 sec
Backend:, Response Code: 504, Host:, Elapsed Time:3.724406 sec
Backend:, Response Code: 504, Host:, Elapsed Time:3.147017 sec
Backend:, Response Code: 504, Host:, Elapsed Time:3.207459 sec
========================================================
Total Request: 50
Version v1: 25
Version v2: 0
========================================================
...
```

Check Graph in Kiali Console with Response time.
![](../images/kiali-graph-timeout.png)



## Cleanup
Run oc delete command to remove Istio policy.

```bash
oc delete -f istio-files/virtual-service-backend-v1-v2-80-20.yml -n $USERID
oc delete -f istio-files/destination-rule-backend-v1-v2.yml -n $USERID
```

## Next Topic

[Circuit Breaker](./08-circuit-breaker.md)
