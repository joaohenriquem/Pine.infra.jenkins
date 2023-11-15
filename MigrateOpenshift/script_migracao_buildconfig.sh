#!/bin/bash

#Get Openshift Credentials
source_cluster="https://lxcpnhhopen01.pine.com.br:8443"
dest_cluster="https://openshiftmasters.hml.pine.com:8443"

echo Usuario Openshift: 
read OpenshiftCRED_USR

oc login -u=$OpenshiftCRED_USR --insecure-skip-tls-verify=true $dest_cluster
destcreds_token=$(oc whoami -t)

oc login -u=$OpenshiftCRED_USR --insecure-skip-tls-verify=true $source_cluster
sourcecreds_token=$(oc whoami -t)

srccreds="$OpenshiftCRED_USR:$sourcecreds_token"
destcreds="$OpenshiftCRED_USR:$destcreds_token"

clear

echo "Script para migracao de buildconfigs Openshift"
echo " "
echo " "

#Get list DC
buildconfigs_list=$(oc get buildconfigs |awk '{print $1}' |grep prd)

for buildname in $buildconfigs_list
do
    echo " "
	echo "1 - Exportando BuildConfigs"
	echo " "
	
	build_file="$buildname"
	build_file+="_build.yaml"
	
	export_build=$(oc export buildconfigs $buildname -n cicd -o yaml)
	
	echo "$export_build" > "$build_file"
    
done

oc login -u=$OpenshiftCRED_USR --insecure-skip-tls-verify=true $dest_cluster

for buildname in $buildconfigs_list
do
	echo " "
	echo "3 - Deploy dos Buildsconfigs "
	echo " "
	
	build_file="$buildname"
	build_file+="_build.yaml"

	oc create -f $build_file -n cicd

done

oc login -u=$OpenshiftCRED_USR --insecure-skip-tls-verify=true $source_cluster
