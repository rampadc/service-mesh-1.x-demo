# Customer gateway, virtual service, and destination rule
oc apply -f kube/customer/Gateway-no-virtual-service.yml 
oc apply -f kube/customer/destination-rule-customer-v1-v2.yml 
oc apply -f kube/customer/virtual-service-customer-v1_and_v2.yml 

# Add the preference virtual service and destination rule (mostly for making sure no retry on error)
oc apply -f kube/preference/destination-rule-preference.yml 
oc apply -f kube/preference/virtual-service-preference.yml 

# Add the destination rule and virtual service for Recommendation
oc apply -f istiofiles/destination-rule-recommendation-v1-v2.yml 
oc apply -f istiofiles/virtual-service-recommendation-v1_and_v2_initial.yml 
