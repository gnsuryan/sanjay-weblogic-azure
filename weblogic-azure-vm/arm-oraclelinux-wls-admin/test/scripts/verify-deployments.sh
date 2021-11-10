#!/bin/bash
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

#read arguments from stdin
read prefix location template repoPath testbranchName scriptsDir

groupName=${prefix}-preflight

# create Azure resources for preflight testing
az group create --verbose --name $groupName --location ${location}

# generate parameters for testing differnt cases
parametersList=()
# parameters for cluster
bash ${scriptsDir}/gen-parameters.sh <<< "${scriptsDir}/parameters.json $repoPath $testbranchName"
parametersList+=(${scriptsDir}/parameters.json)

# parameters for cluster+db
bash ${scriptsDir}/gen-parameters-db.sh <<< "${scriptsDir}/parameters-db.json $repoPath $testbranchName"
parametersList+=(${scriptsDir}/parameters-db.json)

# parameters for cluster+aad
bash ${scriptsDir}/gen-parameters-aad.sh <<< "${scriptsDir}/parameters-aad.json $repoPath $testbranchName"
parametersList+=(${scriptsDir}/parameters-aad.json)

# parameters for admin+elk
bash ${scriptsDir}/gen-parameters-elk.sh <<< "${scriptsDir}/parameters-elk.json $repoPath $testbranchName"
parametersList+=(${scriptsDir}/parameters-elk.json)

# parameters for cluster+db+aad
bash ${scriptsDir}/gen-parameters-db-aad.sh <<< "${scriptsDir}/parameters-db-aad.json $repoPath $testbranchName"
parametersList+=(${scriptsDir}/parameters-db-aad.json)

# run preflight tests
success=true
for parameters in "${parametersList[@]}";
do
    az deployment group validate -g ${groupName} -f ${template} -p @${parameters} --no-prompt
    if [[ $? != 0 ]]; then
        echo "deployment validation for ${parameters} failed!"
        success=false
    fi
done

# release Azure resources
az group delete --yes --no-wait --verbose --name $groupName

if [[ $success == "false" ]]; then
    exit 1
else
    exit 0
fi
