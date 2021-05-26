#!/bin/bash

# Define variables  
red='\e[1;31m%s\e[0m\n'
green='\e[1;32m%s\e[0m\n'
blue='\e[1;34m%s\e[0m\n'

# Variables
SUBSCRIPTION=xxxxxxxxxxx
ENVIRONMENT=dev
RG_NAME="rg-secureThreeTier-${ENVIRONMENT}"
LOCATION=northeurope
PARAM_FILE="./deploy.parameters.${ENVIRONMENT}.json"


# Code - do not change anything here on deployment
# 1. Set the right subscription
printf "$blue"  "*** Setting the subsription to $SUBSCRIPTION ***"
az account set --subscription "$SUBSCRIPTION"


# 2. Create main Resource group if not exists
az group create --name $RG_NAME --location $LOCATION
printf "$green"  "*** Resource Group $SUBSCRIPTION created (or Existed) ***"

# 3. start the BICEP deployment
printf "$blue"  "starting BICEP deployment for ENV: $ENVIRONMENT"
az deployment group create \
    -f ./deploy.bicep \
    -g $RG_NAME \
    -c \
    -p $PARAM_FILE


printf "$green"  "*** Deployment finished for ENV: $ENVIRONMENT ***"