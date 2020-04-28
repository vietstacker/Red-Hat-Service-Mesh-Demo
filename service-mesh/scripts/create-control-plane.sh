#!/bin/sh
echo "Create Control Plane for $USERID"
echo "All istio's pods will run in project $USERID-istio-system"
oc apply -f install/basic-install.yml -n $USERID-istio-system
watch oc get pods -n $USERID-istio-system
