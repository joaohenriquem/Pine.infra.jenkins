#!/bin/bash

echo Nome da aplicacao: 
read deployment

echo Nome do projeto:
read project

cp template-image-pipeline-hml-digital.yaml hml-$deployment-$project-pipeline-template.yaml

#validabc=$(oc get bc '$deployment'-pipeline -n cicd)

#if [$validabc]; then
oc delete bc $deployment-pipeline -n cicd
#fi

oc project cicd

sed -i 's/appnameS/'$deployment'/g' hml-$deployment-$project-pipeline-template.yaml
sed -i 's/projetoS/'$project'/g' hml-$deployment-$project-pipeline-template.yaml

oc create -f hml-$deployment-$project-pipeline-template.yaml

#rm -f hml-$deployment-$project-pipeline-template.yaml
