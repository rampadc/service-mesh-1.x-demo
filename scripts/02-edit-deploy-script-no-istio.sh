#
# Customer 
#
# version 1
oc apply -f kube/customer/Deployment.yml

# version 2
oc apply -f kube/customer/Deployment-v2.yml

# uncomment for a dotnet version of customer v2
# oc apply -f kube/customer/Deployment-v2-dotnet-customer.yml

oc apply -f kube/customer/Service.yml

# create a route (eventually replaced with an instio gateway)
# oc expose svc customer

#
# Preference Service
#
oc apply -f kube/preference/Deployment.yml
oc apply -f kube/preference/Service.yml

# open a route for demonstration purposes
# oc expose svc preference

#
# Recommendation Service
#
# version 1
oc apply -f kube/recommendation/Deployment.yml 

# version 2
oc create is recommendation-v2
oc import-image recommendation-v2 --from=quay.io/mhildenb/sm-demo-recommendation:v2-buggy --reference-policy=local --confirm=true
sed "s/rh-example/rh-example/g" kube/recommendation/Deployment-v2-buggy-only.yml | oc apply -f -

# version 3 
# This is setup so that we can update the image stream and trigger an update on the version
# Notice that the options are based on a jib build, as per https://github.com/GoogleContainerTools/jib/blob/master/docs/faq.md#how-do-i-set-parameters-for-my-image-at-runtime
oc create is recommendation-v3
oc import-image recommendation-v3 --from=quay.io/mhildenb/sm-demo-recommendation:v3 --reference-policy=local --confirm=true
oc new-app recommendation-v3 -l app=recommendation,version=v3,app.kubernetes.io/part-of=Recommendation \
    -e JAVA_TOOL_OPTIONS="-Xdebug -Xrunjdwp:transport=dt_socket,address=5005,server=y,suspend=n"
sleep 1
# ensure sidecar injection
oc patch dc/recommendation-v3 --patch '{"spec":{"template":{"metadata":{"annotations": { "sidecar.istio.io/inject":"true" }}}}}'