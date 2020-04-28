#!bin/sh
export FRONTEND_URL=$(oc get route frontend -n $USERID -o jsonpath='{.spec.host}')
export GATEWAY_URL=$(oc get route istio-ingressgateway -o jsonpath='{.spec.host}' -n $USERID-istio-system)
export KIALI_URL=$(oc get route kiali -o jsonpath='{.spec.host}' -n $USERID-istio-system)
export JAEGER_URL=$(oc get route jaeger -o jsonpath='{.spec.host}' -n $USERID-istio-system)
echo "FRONTEND_URL=$(oc get route frontend -n $USERID -o jsonpath='{.spec.host}')"
echo "GATEWAY_URL=$(oc get route istio-ingressgateway -o jsonpath='{.spec.host}' -n $USERID-istio-system)"
echo "KIALI_URL=$(oc get route kiali -o jsonpath='{.spec.host}' -n $USERID-istio-system)"
echo "JAEGER_URL=$(oc get route jaeger -o jsonpath='{.spec.host}' -n $USERID-istio-system)"
