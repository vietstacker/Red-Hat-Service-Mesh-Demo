# Microservices Deployment Lab

<!-- TOC -->

- [Microservices Deployment Lab](#microservices-deployment-lab)
  - [Frontend and Backend app](#frontend-and-backend-app)
  - [Deploy Frontend and Backend app](#deploy-frontend-and-backend-app)
    - [Deploy Applications](#deploy-applications)
    - [OpenShift Developer Console](#openshift-developer-console)
    - [Test Appliation](#test-appliation)
  - [Next Topic](#next-topic)

<!-- /TOC -->

## Frontend and Backend app

In this demo, we are going to deploy microservices applications to OpenShift Container Platform.
When applications are deployed, Service Mesh sidecar will be injected into each microservice pod. In the nutshell, the sidecar term describes the configuration of the sidecare proxy that mediates inbound and outbound communication to the pod it is attached to.

There are two microservices in this lab that you will deploy to OpenShift. In a later lab of this course, you will manage the interactions between these microservices using Red Hat OpenShift Service Mesh.

![Microservice Diagram](../images/microservices-initial.png)

### Remark: All the resources of Frontend and Backend app have to be deployed in $USERID project which we have created before. Make sure that if you create the following yaml files, you have to apply them in $USERID project

## Deploy Backend app
You start by deploying the catalog service to OpenShift. The sidecar proxy is automatically injected by annotated deployment with 

```yaml
sidecar.istio.io/inject: "true"
```

Create a yaml file as below or use the pre-prepared file for backed-v1 deployment [deployment of backend v1](../ocp/backend-v1-deployment.yml). Check the "annotations" section within yaml file, we can see how we use Service Mesh sidecar injection.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-v1
  annotations:
    app.openshift.io/vcs-ref: master
    app.openshift.io/vcs-uri: 'https://gitlab.com/ocp-demo/backend_quarkus.git'
  labels:
    app.kubernetes.io/component: backend
    app.kubernetes.io/instance: backend
    app.kubernetes.io/name: java
    app.kubernetes.io/part-of: App-X
    app.openshift.io/runtime: java
    app.openshift.io/runtime-version: '8'
spec:
  replicas: 1
  selector:
    matchLabels:
      app: backend
      version: v1
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: backend
        version: v1
      annotations:
        sidecar.istio.io/inject: "true"
    spec:
      containers:
      - name: backend
        image: quay.io/voravitl/backend-native:v1
        imagePullPolicy: Always
        resources:
          requests:
            cpu: "0.05"
            memory: 40Mi
          limits:
            cpu: "0.2"
            memory: 120Mi
        env:
          - name: APP_BACKEND
            value: https://httpbin.org/status/200
          - name: APP_VERSION
            value: v1
        ports:
        - containerPort: 8080
```
Create a yaml file as below or use the pre-prepared file for backed-v2 deployment [deployment of backend v2](../ocp/backend-v2-deployment.yml).

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-v2
  annotations:
    app.openshift.io/vcs-ref: master
    app.openshift.io/vcs-uri: 'https://gitlab.com/ocp-demo/backend_quarkus.git'
  labels:
    app.kubernetes.io/component: backend
    app.kubernetes.io/instance: backend
    app.kubernetes.io/name: java
    app.kubernetes.io/part-of: App-X
    app.openshift.io/runtime: java
    app.openshift.io/runtime-version: '8'
spec:
  replicas: 1
  selector:
    matchLabels:
      app: backend
      version: v2
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: backend
        version: v2
      annotations:
        sidecar.istio.io/inject: "true"
    spec:
      containers:
      - name: backend
        image: quay.io/voravitl/backend-native:v1
        imagePullPolicy: Always
        resources:
          requests:
            cpu: "0.05"
            memory: 60Mi
          limits:
            cpu: "0.2"
            memory: 120Mi
        env:
          - name: APP_BACKEND
            value: https://httpbin.org/delay/5
          - name: APP_VERSION
            value: v2
        ports:
        - containerPort: 8080
```

Review configuration of backend v1 and v2. 
* Backend v1 is configured to call https://httpbin.org/status/200 
  ```yaml
        env:
          - name: app.backend
            value: https://httpbin.org/status/200
  ```
* Backend v2 is configured to call https://httpbin.org/delay/5. This will caused Backend v2 delay 5 sec to respose back to Frontend
  ```yaml
        env:
          - name: app.backend
            value: https://httpbin.org/delay/5 
  ```

Create a yaml file as below for Service of backend app [service of backend](../ocp/backend-service.yml).

```yaml
apiVersion: v1
kind: Service
metadata:
  name: backend
  labels:
    app: backend
spec:
  ports:
  - port: 8080
    name: http
    targetPort: 8080
  selector:
    app: backend
```

## Deploy Frontend app

Create a yaml file as below for Frontend deployment and apply it. This yaml file is stored within ../ocp/frontend-v1-deployment.yml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-v1
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
      version: v1
  template:
    metadata:
      labels:
        app: frontend
        version: v1
      annotations:
        sidecar.istio.io/inject: "true"
    spec:
      containers:
      - name: frontend
        image: quay.io/voravitl/frontend-js:v1
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
The below are Service and Route of the above Frontend app:

Route.yaml

```yaml
apiVersion: v1
kind: Route
metadata:
  name: frontend
spec:
  port:
    targetPort: http
  to:
    kind: Service
    name: frontend
    weight: 100
  wildcardPolicy: None
```

Service.yaml
```yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend
  labels:
    app: frontend
spec:
  ports:
  - port: 8080
    name: http
    targetPort: 8080
  selector:
    app: frontend
```
### Remark: The whole files of Frontend and Backend app are stored within /ocp directory. You can easily apply them as below

```bash
oc apply -f ocp/frontend-v1-deployment.yml -n $USERID
oc apply -f ocp/frontend-service.yml -n $USERID
oc apply -f ocp/frontend-route.yml -n $USERID
oc apply -f ocp/backend-v1-deployment.yml -n $USERID
oc apply -f ocp/backend-v2-deployment.yml -n $USERID
oc apply -f ocp/backend-service.yml -n $USERID
```

or just run [deploy.sh](../scripts/deploy.sh) shell script

```bash
scripts/deploy.sh
```

Sample outout
```bash
deployment.extensions/frontend created
service/frontend created
route.route.openshift.io/frontend created
deployment.extensions/backend-v1 created
deployment.extensions/backend-v2 created
service/backend created
```

Monitor the deployment of the pods:
```bash
oc get pods -w -n $USERID
#Or use watch command 
watch oc get pods -n $USERID
```

Wait until the Ready column displays 2/2 pods and the Status column displays Running:
Press Control-C to exit.

You can also view pods status using OpenShift Developer Console Topology view

![Topology View](../images/deploy-app.gif)

### OpenShift Developer Console

Login to OpenShift Web Console. Then select Developer Console and select menu Topology

![Developer Console](../images/developer-console.png)

Both Frontend and Backend app are shown as follow

![Topology View](../images/topology-view.png)

Check for backend pod memory and cpu usage by click on donut, select tab resources and then select pod

![Select Pod](../images/backend-select-pod.png)

CPU and memory usage of backend pod show as follow

![Select Pod](../images/backend-pod-cpu-memory.png)

Review container section that backend pod consists of 2 containers

![Backend Pod's containers](../images/backend-containers.png)


### Test Appliation
Test frontend app by

```bash
export FRONTEND_URL=http://$(oc get route frontend -n $USERID -o jsonpath='{.status.ingress[0].host}')
curl $FRONTEND_URL
```
**Remark: You can use [get-urls.sh](../scripts/get-urls.sh) for display and set environment variables for all URLs used through out labs**

```bash
. ./scripts/get-urls.sh
##Remark that you need to use source (.) instead of run shell script
##for set environment variables
```

You can also get Frontend Route from Developer Console

![Frontend Route](../images/frontend-route.png)

Sample outout
```bash
Frontend version: v1 => [Backend: http://backend:8080, Response: 200, Body: Backend version:v2, Response:200, Host:backend-v2-7d69c678b4-7r4bb, Status:200, Message: Hello, World]
```
Explain result:

- Frontend version v1 call Backend service (with URL http://backend:8080)
- Response code is 200
- Response from Backend are
- version is v2
- pod backend-v2-7d69c678b4-7r4bb
- Response message from Backend is Hello World!!

Verify that [backend-service.yml](../ocp/backend-service.yml) is set to just app label. This will included both backend v1 in v2 into this backend service

```yaml
  selector:
    app: backend
```

Try to run cURL command again and check that response from backend will round-robin between v1 and v2 and v2 is elapsed time is slightly more than 5 sec.


You also can use following cURL for check response time
```bash
curl $FRONTEND_URL -s -w "\nElapsed Time:%{time_total}"
```

Sample output
```bash
Frontend version: v1 => [Backend: http://backend:8080, Response: 200, Body: Backend version:v1, Response:200, Host:backend-v1-797cf7f7b4-b9lnh, Status:200, Message: Hello, World]
Elapsed Time:1.034145
...

Frontend version: v1 => [Backend: http://backend:8080, Response: 200, Body: Backend version:v2, Response:200, Host:backend-v2-7d69c678b4-nrqmj, Status:200, Message: Hello, World]
Elapsed Time:6.095179
```

## Next Topic
[Observability with Kiali and Jaeger](./03-observability.md)
