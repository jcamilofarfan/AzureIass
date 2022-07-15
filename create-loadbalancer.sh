#!/bin/bash

# Verificar si existe la carpte ./logs
if [ ! -d "./logs" ]; then
    mkdir logs
fi

# si no existe la carpeta logs, exit
if [ ! -d "./logs" ]; then
    echo "No existe la carpeta logs"
    exit 1
fi


nameGroup=$1
instancesNumber=$2

if [ $# -ne 2 ]
then
    echo "Se necesitan dos parametros"
    echo "Ejemplo: ./create-loadbalancer.sh nombre-grupo numero-instancias"
    exit 1
fi

if [[ $nameGroup =~ ^[a-zA-Z]+$ ]]
then
    echo "El nombre del grupo es correcto"
else
    echo "El nombre del grupo no es correcto"
    echo "Debe se una palabra sin espacios"
    exit 1
fi

# el segundo parametro debe ser un numero
if [[ $instancesNumber =~ ^[1-9]+$ ]]
then
    echo "El numero de instancias es correcto"
else
    echo "El numero de instancias no es correcto"
    echo "Debe ser un numero entero positivo"
    exit 1
fi

nameIpPublic=ipP$nameGroup
nameLoadBalancer=lb$nameGroup
frontendIpName=front$nameGroup
backendIpName=back$nameGroup
probeRule=probe$nameGroup
loadBalancerRule=lbR$nameGroup
vNetName=vN$nameGroup
vSubNetName=vSN$nameGroup
myNetworkSecurityGroup=nsg$nameGroup
myNetworkSecurityGroupRule=nsgR$nameGroup
myAvailabilitySet=as$nameGroup

echo "{" >> ./logs/create-group-$nameGroup.json

# Create a group resource
echo "Creating a group resource..."
echo '"group resource":' >> ./logs/create-group-$nameGroup.json
az group create --name $nameGroup --location eastus >> ./logs/create-group-$nameGroup.json
echo "Group resource created."
echo ',' >> ./logs/create-group-$nameGroup.json


# Create a Ip Public
echo "Creating a Ip Public..."
echo '"Ip Public":' >> ./logs/create-group-$nameGroup.json
az network public-ip create -g $nameGroup --name $nameIpPublic >> ./logs/create-group-$nameGroup.json
echo "Ip Public created."
echo ',' >> ./logs/create-group-$nameGroup.json

# Create a load balancer
echo "Creating a load balancer..."
echo '"load balancer":' >> ./logs/create-group-$nameGroup.json
az network lb create -g $nameGroup -n $nameLoadBalancer --frontend-ip-name $frontendIpName --backend-pool-name $backendIpName --public-ip-address $nameIpPublic >> ./logs/create-group-$nameGroup.json
echo "Load balancer created."
echo ',' >> ./logs/create-group-$nameGroup.json

# configure balancer performance monitoring
echo "Configure balancer performance monitoring..."
echo '"probe rule":' >> ./logs/create-group-$nameGroup.json
az network lb probe create -g $nameGroup --lb-name $nameLoadBalancer --name $probeRule --protocol tcp --port 80 >> ./logs/create-group-$nameGroup.json
echo "Balancer performance monitoring configured."
echo ',' >> ./logs/create-group-$nameGroup.json

# Set an inbound rule in the network security group
echo "Set an inbound rule in the network security group..."
echo '"load balancer rule":' >> ./logs/create-group-$nameGroup.json
az network lb rule create -g $nameGroup --lb-name $nameLoadBalancer -n $loadBalancerRule --protocol tcp --frontend-port 80 --backend-port 80 --frontend-ip-name $frontendIpName --backend-pool-name $backendIpName --probe-name $probeRule >> ./logs/create-group-$nameGroup.json
echo "Inbound rule set in the network security group."
echo ',' >> ./logs/create-group-$nameGroup.json

# create a virtual network
echo "Creating a virtual network..."
echo '"virtual network":' >> ./logs/create-group-$nameGroup.json
az network vnet create -g $nameGroup -n $vNetName --subnet-name $vSubNetName >> ./logs/create-group-$nameGroup.json
echo "Virtual network created."
echo ',' >> ./logs/create-group-$nameGroup.json

# Create a network security group
echo "Creating a network security group..."
echo '"network security group":' >> ./logs/create-group-$nameGroup.json
az network nsg create -g $nameGroup -n $myNetworkSecurityGroup >> ./logs/create-group-$nameGroup.json
echo "Network security group created."
echo ',' >> ./logs/create-group-$nameGroup.json

# Set an inbound rule in the network security group.
echo "Set an inbound rule in the network security group..."
echo '"network security group rule":' >> ./logs/create-group-$nameGroup.json
az network nsg rule create -g $nameGroup --nsg-name $myNetworkSecurityGroup --name $myNetworkSecurityGroupRule --priority 1001 --protocol tcp --destination-port-range 80 >> ./logs/create-group-$nameGroup.json
echo "Network security group rule created."
echo ',' >> ./logs/create-group-$nameGroup.json

# Create $instancesNumber network interfaces, one for each virtual machine
echo "Creating network interfaces, one for each virtual machine..." $instancesNumber
echo '"network interfaces": {' >> ./logs/create-group-$nameGroup.json

for ((i=1; i<=$instancesNumber; i++))
do
    echo "Creating a network interface..."
    echo '"network interface'$i'":'  >> ./logs/create-group-$nameGroup.json
    az network nic create  -g $nameGroup --name myNic$i --vnet-name $vNetName --subnet $vSubNetName --network-security-group $myNetworkSecurityGroup --lb-name $nameLoadBalancer --lb-address-pools $backendIpName >> ./logs/create-group-$nameGroup.json
    echo "Network interface created."
    if [ $i -eq $instancesNumber ]
    then
        echo '}' >> ./logs/create-group-$nameGroup.json
    else
        echo ',' >> ./logs/create-group-$nameGroup.json
    fi
done
echo "Network interfaces created."
echo ',' >> ./logs/create-group-$nameGroup.json

# Create an availability set.
echo "Creating an availability set..."
echo '"availability set":' >> ./logs/create-group-$nameGroup.json
az vm availability-set create -g $nameGroup -n $myAvailabilitySet >> ./logs/create-group-$nameGroup.json
echo "Availability set created."
echo ',' >> ./logs/create-group-$nameGroup.json

# Create 3 virtual machines.
echo "Creating  virtual machines..." $instancesNumber
for ((i=1; i<=$instancesNumber; i++))
do
    az vm create -g $nameGroup --name myVM$i --availability-set $myAvailabilitySet --nics myNic$i --image UbuntuLTS --admin-username azureuser --generate-ssh-key --custom-data cloud-init.txt --no-wait
done
echo "Virtual machines created."
echo '"virtual machines": "'$instancesNumber'"' >> ./logs/create-group-$nameGroup.json

echo "}" >> ./logs/create-group-$nameGroup.json

# get the public IP address of the load balancer
echo "Getting the public IP address of the load balancer..."
az network public-ip show -g $nameGroup --name $nameIpPublic --query [ipAddress] --output tsv