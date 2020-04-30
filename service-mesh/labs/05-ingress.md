# Istio Gateway and Routing by HTTP header

<!-- TOC -->

- [Istio Gateway and Routing by HTTP header](#istio-gateway-and-routing-by-http-header)
  - [Setup](#setup)
  - [Istio Ingress Gateway](#istio-ingress-gateway)
  - [Routing by incoming HTTP header](#routing-by-incoming-http-header)
    - [Destination Rule](#destination-rule)
    - [Virtual Service](#virtual-service)
    - [Test](#test)
  - [Fault Injection](#fault-injection)
  - [Test](#test-1)
  - [Cleanup](#cleanup)
  - [Next Topic](#next-topic)

<!-- /TOC -->

Configure service mesh gateway to control traffic that entering mesh.

![Microservice with Ingress Diagram](../images/microservices-with-ingress.png)

## Setup
Create a frontend-v2 as below. This file is also created as ocp/frontend-v2-deployment.yml:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-v2
  annotations:
    app.openshift.io/vcs-ref: master
    app.openshift.io/vcs-uri: 'https://gitlab.com/ocp-demo/frontend-js.git'
  labels:
    app.kubernetes.io/component: frontend
    app.kubernetes.io/instance: frontend
    app.kubernetes.io/name: nodejs
    app.kubernetes.io/part-of: App-X
    app.openshift.io/runtime: nodejs
    app.openshift.io/runtime-version: '10'
spec:
  replicas: 1
  selector:
    matchLabels:
      app: frontend
      version: v2
  template:
    metadata:
      labels:
        app: frontend
        version: v2
      annotations:
        sidecar.istio.io/inject: "true"
    spec:
      containers:
      - name: frontend
        image: quay.io/voravitl/frontend-js:v2
        imagePullPolicy: Always
        env:
          - name: BACKEND_URL
            value: http://backend:8080
        resources:
          requests:
            cpu: "0.1"
            memory: 60Mi
          limits:
            cpu: "0.2"
            memory: 100Mi
        ports:
        - containerPort: 8080
```
Deploy frontend v2 and remove backend v2

```bash
oc apply -f ocp/frontend-v2-deployment.yml -n $USERID
oc delete -f ocp/backend-v2-deployment.yml -n $USERID
watch oc get pods -n $USERID 
#Or using oc get pods -w -n $USERID
#Sample Output
NAME                           READY   STATUS              RESTARTS   AGE
backend-v1-989c648f4-klsvl     2/2     Running             0          37m
backend-v2-549bbcbdd6-shw2j    0/2     Terminating         0          37m
frontend-v1-77b8699f6d-6vd56   2/2     Running             0          37m
frontend-v2-5c4bf794bd-vnjk6   0/2     ContainerCreating   0          13s
```

## Istio Ingress Gateway
An Istio Ingress Gateway describes a load balancer operating at the edge of the mesh that receives incoming HTTP/TCP connections. Create a Gateway using Istio IngressGateway as below:
```yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: frontend-gateway
spec:
  selector:
    istio: ingressgateway # use istio default controller
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - '*'
```
This file is also stored in [frontend-gateway.yml](../istio-files/frontend-gateway.yml)

Run oc apply command to create Istio Gateway.

```bash
oc apply -f istio-files/frontend-gateway.yml -n $USERID
```

Sample outout

```bash
gateway.networking.istio.io/frontend-gateway created
```

<!-- **Remark: You can also using [Kiali Console to create Gateway](#create-gateway-using-kiali-console)** -->



## Routing by incoming HTTP header

### Destination Rule
We create a DestinationRule for routing traffic to Frontend from Ingress Gateway by matching label "app" and "version". This file is also stored within [destination-rule-frontend-v1-v2.yml](../istio-files/destination-rule-frontend-v1-v2.yml)  

DestinationRule.yml
```yaml
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: frontend-destination-rule
spec:
  host: frontend
  subsets:
  - name: v1
    labels:
      app: frontend
      version: v1
    trafficPolicy:
      loadBalancer:
        simple: ROUND_ROBIN
  - name: v2
    labels:
      app: frontend
      version: v2
    trafficPolicy:
      loadBalancer:
        simple: ROUND_ROBIN
```

Run oc apply command to create Istio Gateway.

```bash
oc apply -f istio-files/destination-rule-frontend-v1-v2.yml -n $USERID
```

Sample outout

```bash
destinationrule.networking.istio.io/frontend created
```

### Virtual Service
Create a new Istio's virtual service configuration file to configure routes for traffic comming from Gateway by matching headers "foo/bar". The yaml file is stored in [virtual-service-frontend-header-foo-bar-to-v1.yml](../istio-files/virtual-service-frontend-header-foo-bar-to-v1.yml)

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: frontend-virtual-service
spec:
  hosts:
  - '*'
  gateways:
  - frontend-gateway
  http:
  - match:
    - headers:
        foo:
          exact: bar
    route:
    - destination:
        host: frontend
        subset: v1
  - route:
    - destination:
        host: frontend
        subset: v2
```

Run oc apply command to apply Istio virtual service policy.

```bash
oc apply -f istio-files/virtual-service-frontend-header-foo-bar-to-v1.yml -n $USERID
```

Sample output

```bash
virtualservice.networking.istio.io/frontend created
```
<!-- ## Create Gateway using Kiali Console
Login to the Kiali web console. Select "Services" on the left menu. Then select frontend service

* On the main screen of backend service. Click Action menu on the top right and select "Create Matching Routing"
![](../images/service-frontend-create-matching.png)

* Input Header name foo to exact match with value bar and then add rule
![](../images/service-frontend-set-match.png)

* Verify that header matching rule is added.
![](../images/service-frontend-set-match-added.png)

* Add Gateway by enable Advanced Option then select Add Gateway  -->

### Test

Get URL of Istio Gateway and set to environment variable by using following command

```bash
export GATEWAY_URL=$(oc -n $USERID-istio-system get route istio-ingressgateway -o jsonpath='{.spec.host}')
```

Verify that environment variable GATEWAY is set correctly.

```bash
echo $GATEWAY_URL

```

Sample output

```bash
istio-ingressgateway-user1-istio-system.apps.cluster-bkk77-eeb3.bkk77-eeb3.example.opentlc.com
```

Test with cURL by setting header name foo with value bar. Response will always from Frontend v1

```bash
curl -v -H foo:bar $GATEWAY_URL
```

Check for header foo in HTTP request

![foo](../images/curl-http-header.png)

Sample outout

```bash
Frontend version: v1 => [Backend: http://backend:8080, Response: 200, Body: Backend version:v1, Response:200, Host:backend-v1-797cf7f7b4-b9lnh, Status:200, Message: Hello, World]
```

Test again witout specified parameter -H. Response will always from Frontend v2

Sample outout

```bash
Frontend version: v2 => [Backend: http://backend:8080, Response: 200, Body: Backend version:v1, Response:200, Host:backend-v1-797cf7f7b4-b9lnh, Status:200, Message: Hello, World]
```

You can also run script to generate round-robin request between frontend-v1 and frontend-v2
 as below. The file is stored as [run-50-foo-bar.sh](../scripts/run-50-foo-bar.sh) 
```bash
#!/bin/sh
COUNT=0
MAX=50
VERSION1=0
VERSION2=0
#TARGET_URL=$FRONTEND_URL
TARGET_URL=$GATEWAY_URL
while [ $COUNT -lt $MAX ];
do
  EVEN=$(expr $COUNT % 2)
  if [ $EVEN -eq 0 ];
  then
    OUTPUT=$(curl -s -H foo:bar  $TARGET_URL )
  else
    OUTPUT=$(curl -s $TARGET_URL)
  fi
  VERSION=$(echo $OUTPUT|awk -F'=>' '{print $1}')
  echo $VERSION
  COUNT=$(expr $COUNT + 1)
done
```
```bash
scripts/run-50-foo-bar.sh
```

Sample output

```bash
...
Frontend version: v2
Frontend version: v1
Frontend version: v2
Frontend version: v1
Frontend version: v2
...
```

Kiali Graph show that requests are from ingress gateway. (Comparing with "Unknown" from previous lab)

![Kiali Graph with Ingress](../images/kiali-graph-ingress.png)

Check virtual service configuration 

![Kiali Conditional Routing Rule](../images/kiali-conditional-routing-rule.png)

## Fault Injection

Fault injection is strategy to test resiliency of your service.

We will remove frontend v2 and update destination rule to not included frontend v2 and apply virtual service with fault injection when header foo is equal to bar

Update Frontend DestinationRule
```yaml
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: frontend-destination-rule
spec:
  host: frontend
  trafficPolicy:
    loadBalancer:
      simple: ROUND_ROBIN
```
Update Frontend-virtual-service
```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: frontend-virtual-service
spec:
  hosts:
  - '*'
  gateways:
  - frontend-gateway
  http:
  - fault:
      abort:
        # Return HTTP 500 for every request
        httpStatus: 500
        percentage:
          value: 100
    # When header foo = bar
    match:
    - headers:
        foo:
          exact: bar
    route:
    - destination:
        host: frontend
  - route:
    - destination:
        host: frontend
```
Those files are also stored within istio-files
```bash
oc apply -f istio-files/destination-rule-frontend.yml -n ${USERID}
oc apply -f istio-files/virtual-service-frontend-fault-inject.yml -n $USERID
oc delete -f ocp/frontend-v2-deployment.yml -n ${USERID}
watch oc get pods -n ${USERID}
```


Check virtual service configuration in Kiali console

![Kiali Fault Injection](..images/../../images/kiali-fault-injection.png)

## Test

You can use previous cURL command for test fault injection.

```bash
curl -v -H foo:bar  $GATEWAY_URL
```

Sample output

```bash
...
> User-Agent: curl/7.64.1
> Accept: */*
> foo:bar
>
< HTTP/1.1 500 Internal Server Error
< content-length: 18
< content-type: text/plain

...
```

Test again with header foo not equal to bar

```bash
curl -v -H foo:bar1  $GATEWAY_URL
```

Sample output

```bash
...
> User-Agent: curl/7.64.1
> Accept: */*
> foo:bar1
>
< HTTP/1.1 200 OK
...
```

## Cleanup
Run oc delete command to remove Istio policy.

```bash
oc delete -f istio-files/frontend-gateway.yml -n $USERID
oc delete -f istio-files/virtual-service-frontend-header-foo-bar-to-v1.yml -n $USERID
oc delete -f istio-files/destination-rule-frontend-v1-v2.yml -n $USERID
```

## Next Topic

[Egress](./06-gress.md)
