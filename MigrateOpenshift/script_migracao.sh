#!/bin/bash

echo "Script para migracao de projetos Openshift"
echo " "
echo " "

#Get Namespace
echo Namespace: 
read namespace
echo " "
echo " "

#Get Openshift Credentials
source_cluster="https://openshiftmasters.pine.com.br:8443"
dest_cluster="https://openshiftmaster.pine.com:8443"

echo Usuario Openshift: 
read OpenshiftCRED_USR

oc login -u=$OpenshiftCRED_USR --insecure-skip-tls-verify=true $dest_cluster
destcreds_token=$(oc whoami -t)

oc login -u=$OpenshiftCRED_USR --insecure-skip-tls-verify=true $source_cluster
sourcecreds_token=$(oc whoami -t)

srccreds="$OpenshiftCRED_USR:$sourcecreds_token"
destcreds="$OpenshiftCRED_USR:$destcreds_token"

clear

echo "Script para migracao de projetos Openshift"
echo " "
echo " "

#Environments
registry_source="docker://openregistry.pine.com/$namespace/"
registry_destination="docker://openregistry.pine.com.br/$namespace/"

#Get list DC
dc_list=$(oc get dc -n $namespace |awk '{print $1}' | tail -n +2)

[ ! -d "$namespace" ] && mkdir $namespace

for dcname in $dc_list
do
    source_name_imagestream=$(oc describe dc $dcname -n $namespace |grep Triggers:|awk 'FNR==1 {print $2}' |cut -d'(' -f 2|sed -r 's/[,]//g' |sed -r 's/[@]/:/g')
	source_imagestream="$registry_source$source_name_imagestream"
	dest_imagestream="$registry_destination$source_name_imagestream"
	
    echo " "
	echo "1 - Exportando Deployment, Service e Route"
	echo " "
	
	dc_file="$dcname"
	dc_file+="_dc.yaml"
	svc_file="$dcname"
	svc_file+="_svc.yaml"
	route_file="$dcname"
	route_file+="_route.yaml"
	
	export_dc=$(oc export dc $dcname -n $namespace -o yaml)
	export_svc=$(oc export svc $dcname -n $namespace -o yaml)
	export_route=$(oc export route $dcname -n $namespace -o yaml)
	
	echo "$export_dc" > "$namespace/$dc_file"
	echo "$export_svc" > "$namespace/$svc_file"
	echo "$export_route" > "$namespace/$route_file"
	
	echo " "
	echo "2 - Copiando imagem docker para novo registry"
	echo " "
	
	skopeo --tls-verify=false copy --dest-creds "$destcreds" --src-creds "$srccreds" "$source_imagestream" "$dest_imagestream"
    
done

oc login -u=$OpenshiftCRED_USR --insecure-skip-tls-verify=true $dest_cluster

for dcname in $dc_list
do
	echo " "
	echo "3 - Deploy da aplicacao "
	echo " "
	
	dc_file="$dcname"
	dc_file+="_dc.yaml"
	svc_file="$dcname"
	svc_file+="_svc.yaml"
	route_file="$dcname"
	route_file+="_route.yaml"

	oc create -f $namespace/$dc_file -n $namespace
	oc create -f $namespace/$svc_file -n $namespace
	oc create -f $namespace/$route_file -n $namespace

done

oc policy add-role-to-user edit system:serviceaccount:cicd:jenkins -n $namespace
oc policy add-role-to-user registry-editor system:anonymous -n $namespace
oc policy add-role-to-user edit system:serviceaccount:cicd:default -n $namespace

oc login -u=$OpenshiftCRED_USR --insecure-skip-tls-verify=true $source_cluster
