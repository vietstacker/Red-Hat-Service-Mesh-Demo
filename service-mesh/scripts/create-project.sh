#!/bin/sh
echo "Create projects for $USERID"
oc new-project $USERID
oc new-project $USERID-istio-system
