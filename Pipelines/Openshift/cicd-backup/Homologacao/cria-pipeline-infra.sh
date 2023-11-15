#!/bin/bash

echo Nome da aplicacao: 
read deployment

echo Nome do projeto:
read project

jobname=$deployment-prd

cp template-image-pipeline-prd-infra.yaml prod-$deployment-$project-pipeline-template.yaml

#validabc=$(oc get bc '$deployment'-pipeline -n cicd)

#if [$validabc]; then
#oc delete bc $deployment-pipeline -n cicd
#fi

oc project cicd

sed -i 's/appnameS/'$deployment'/g' prod-$deployment-$project-pipeline-template.yaml
sed -i 's/projetoS/'$project'/g' prod-$deployment-$project-pipeline-template.yaml
sed -i 's/jobnameS/'$jobname'/g' prod-$deployment-$project-pipeline-template.yaml

oc create -f prod-$deployment-$project-pipeline-template.yaml

#rm -f hml-$deployment-$project-pipeline-template.yaml
