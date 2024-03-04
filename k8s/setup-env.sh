#!/bin/bash

export Environment=Development

SetupVariables() {
    if [ "$1" = "--no-credentials" ]; then
        printf "\n\033[0;33mSkipping 'az aks get-credentials' command.\033[0m\n"
    else
        printf "\n\033[0;32maz aks get-credentials
        --resource-group %s
        --name %s \033[0m \n\n" \
        $(terraform output -raw resource_group_name) $(terraform output -raw aks_cluster_name)
        
        az aks get-credentials \
        --resource-group $(terraform output -raw resource_group_name) \
        --name $(terraform output -raw aks_cluster_name)
    fi
    
    export POSTGRES_PASSWORD=$(terraform output -json key-vault-secrets | jq -r '.[] | select(.name == "'$Environment'-POSTGRES-PASSWORD") | .value')
    if [ -z "$POSTGRES_PASSWORD" ]; then
        printf "\033[0;31mNo POSTGRES_PASSWORD found!\033[0m%s\n"
    else
        printf "POSTGRES_PASSWORD:\t\t\t%s\n" "$(echo $POSTGRES_PASSWORD | sed 's/./\*/g')"
    fi
    
    export CLUSTER_NAME=$(terraform output -raw aks_cluster_name)
    printf "CLUSTER_NAME:\t\t\t\t%s\n" "$CLUSTER_NAME"
    
    export AZURE_DISK_NAME=$(terraform output -raw managed_disk_name)
    printf "AZURE_DISK_NAME:\t\t\t%s\n" "$AZURE_DISK_NAME"

    export AZURE_DISK_SIZE_GB=$(terraform output -raw managed_disk_size_gb)
    printf "AZURE_DISK_SIZE_GB:\t\t\t%s\n" "$AZURE_DISK_SIZE_GB"

    export SONARQUBE_AZURE_DISK_NAME=$(terraform output -raw sonarqube_managed_disk_name)
    printf "SONARQUBE_AZURE_DISK_NAME:\t\t%s\n" "$SONARQUBE_AZURE_DISK_NAME"

    export SONARQUBE_POSTGRES_AZURE_DISK_NAME=$(terraform output -raw sonarqube_postgres_managed_disk_name)
    printf "SONARQUBE_POSTGRES_AZURE_DISK_NAME:\t%s\n" "$SONARQUBE_POSTGRES_AZURE_DISK_NAME"

    export GRAFANA_AZURE_DISK_NAME=$(terraform output -raw grafana_managed_disk_name)
    printf "GRAFANA_AZURE_DISK_NAME:\t\t%s\n" "$GRAFANA_AZURE_DISK_NAME"

    export PROMETHEUS_AZURE_DISK_NAME=$(terraform output -raw prometheus_managed_disk_name)
    printf "PROMETHEUS_AZURE_DISK_NAME:\t\t%s\n" "$PROMETHEUS_AZURE_DISK_NAME"
    
    export AZURE_RESOURCE_GROUP=$(terraform output -raw resource_group_name)
    printf "AZURE_RESOURCE_GROUP:\t\t\t%s\n" "$AZURE_RESOURCE_GROUP"
    
    # --- 💁‍♂️ not required anymore, as far as resources we create are static. ---
    # export AZURE_DATA_P_KEY=$(az keyvault key list --vault-name $(terraform output -json key-vault-name | jq -r '.') --query "[?contains(name, 'DataProtection')].kid" -o tsv)
    # printf "\nAZURE_DATA_P_KEY:\t\t $AZURE_DATA_P_KEY"
    
    # --- 💁‍♂️ not required anymore, as far as resources we create are static. ---
    # export AZURE_DATA_P_KEY_STORE=$(az keyvault key list --vault-name $(terraform output -json key-vault-name | jq -r '.') --query "[?contains(name, 'DataProtection')].kid" -o tsv)
    # printf "\nAZURE_DATA_P_KEY_STORE:\t\t $AZURE_DATA_P_KEY_STORE"
    
    export AZURE_SUBSCRIPTION_ID=$(az account list --query "[?isDefault].id" -o tsv)
    printf "AZURE_SUBSCRIPTION_ID:\t\t\t%s\n" "$(echo $AZURE_SUBSCRIPTION_ID | sed 's/./\*/g')"
    
    export AZURE_TENANT_ID=$(az account show --query tenantId -o tsv)
    printf "AZURE_TENANT_ID:\t\t\t%s\n" "$AZURE_TENANT_ID"
    
    export AZURE_CLIENT_RESOURCE_ID=$(terraform output -json kubelet_identity | jq -r '.user_assigned_identity_id')
    printf "AZURE_CLIENT_RESOURCE_ID:\t\t%s\n" "$(echo $AZURE_CLIENT_RESOURCE_ID | sed -n 's/.*\(MC_[^/]*\).*/\1/p')"
    
    export AZURE_CLIENT_ID=$(terraform output -json kubelet_identity | jq -r '.client_id')
    printf "AZURE_CLIENT_ID:\t\t\t%s\n" "$AZURE_CLIENT_ID"
    
    export DNS_RESOURCE_GROUP=$(az group list --query "[?contains(name, 'DNS')].name" -o tsv)
    count=$(echo "$DNS_RESOURCE_GROUP" | wc -l)
    if [ $count -gt 1 ]; then
        printf "DNS_RESOURCE_GROUP:\t\t \033[0;31mMore than one resource group found!\033[0m\n"
    elif [ -z "$DNS_RESOURCE_GROUP" ]; then
        printf "DNS_RESOURCE_GROUP:\t\t \033[0;31mNo DNS_RESOURCE_GROUP found!\033[0m\n"
    else
        printf "DNS_RESOURCE_GROUP:\t\t\t%s\n" "$DNS_RESOURCE_GROUP"
    fi
    
    export ACR=$(az acr list --resource-group $AZURE_RESOURCE_GROUP --query "[].loginServer" -o tsv)
    if [ -z "$ACR" ]; then
        printf "ACR:\t\t\t\t \033[0;31mNo ACR found!\033[0m\n"
    else
        printf "ACR:\t\t\t\t\t%s\n" "$ACR"
    fi
    
    export POSTGRES_SERVICE=$(kubectl get svc -A -o jsonpath="{range .items[*]}{@.metadata.namespace}/{@.metadata.name}:{@.spec.type}:{range @.spec.ports[*]}{@.name}:{@.port}:{@.protocol}{'\n'}{end}{end}" --all-namespaces | grep "postgres*.*NodePort.*5432" | sed -E 's/^([^:]+).*/\1/')
    
    if [ -z "$POSTGRES_SERVICE" ]; then
        printf "POSTGRES_SERVICE:\t\t\t\033[0;33mNo POSTGRES_SERVICE found!\033[0m\n"
    else
        printf "POSTGRES_SERVICE:\t\t\t%s\n" "$POSTGRES_SERVICE"
    fi

    export GITHUB_PRIVATE_SSH_KEY=$(terraform output -json github_private_ssh_key | jq -r '.' | base64)
    if [ -z "$GITHUB_PRIVATE_SSH_KEY" ]; then
        printf "\033[0;31mGITHUB_PRIVATE_SSH_KEY:\t\t\tError: No Data Found!\033[0m\n"
    else
        printf "GITHUB_PRIVATE_SSH_KEY:\t\t\t%s\n" "***"
    fi

    export GITHUB_PUBLIC_SSH_KEY=$(terraform output -json github_public_ssh_key | jq -r '.' | base64)
    if [ -z "$GITHUB_PUBLIC_SSH_KEY" ]; then
        printf "\033[0;31mGITHUB_PUBLIC_SSH_KEY:\t\t\tError: No Data Found!\033[0m\n"
    else
        printf "GITHUB_PUBLIC_SSH_KEY:\t\t\t%s\n" "***"
    fi

    export AZURE_STORAGE_ACCOUNT=$(terraform output -json storage_blob_name | jq -r '.')
    printf "AZURE_STORAGE_ACCOUNT:\t\t\t%s\n" "$AZURE_STORAGE_ACCOUNT"
    
    export AZURE_STORAGE_KEY=$(terraform output -json storage_blob_primary_access_key | jq -r '.')
    printf "AZURE_STORAGE_KEY:\t\t\t%s\n" "$(echo $AZURE_STORAGE_KEY | sed 's/./\*/g')"

    export AZURE_STORAGE_AIRFLOW_CONTAINER=$(terraform output -json storage_blob_containers | jq -r 'to_entries[] | select(.key | contains("airflow")).value[] | .name')
    if [ -z "$AZURE_STORAGE_AIRFLOW_CONTAINER" ]; then
        printf "\033[0;31mAZURE_STORAGE_AIRFLOW_CONTAINER:\t\t\tError: No Data Found!\033[0m\n"
    else
        printf "AZURE_STORAGE_AIRFLOW_CONTAINER:\t%s\n" "$AZURE_STORAGE_AIRFLOW_CONTAINER"
    fi
}

cd ../azure
SetupVariables $1
cd ../k8s