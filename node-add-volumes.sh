#!/bin/bash

# Installs Oracle OCI and attaches 2 created block volumes to the node
# Required Policy Changes
# - Allow dynamic-group <group> to manage volume-family in compartment <compartment>
# - Allow dynamic-group <group> to manage instances in compartment <compartment>
# - Allow dynamic-group <group> to manage volume-attachments in compartment <compartment>

sudo dnf install -y python39-oci-cli

# Get instance information
instance=$(curl -H "Authorization: Bearer Oracle" http://169.254.169.254/opc/v2/instance/ --no-progress-meter | jq -r .id)
compartment=$(curl -H "Authorization: Bearer Oracle" http://169.254.169.254/opc/v2/instance/ --no-progress-meter | jq -r .compartmentId)
ad=$(curl -H "Authorization: Bearer Oracle" http://169.254.169.254/opc/v2/instance/ --no-progress-meter | jq .availabilityDomain)

# Create a block volume
volume1=$(oci bv volume create --compartment-id $compartment --availability-domain $ad --size-in-gbs 350 --wait-for-state AVAILABLE --auth instance_principal | jq -r '.data.id')
volume2=$(oci bv volume create --compartment-id $compartment --availability-domain $ad --size-in-gbs 200 --wait-for-state AVAILABLE --auth instance_principal | jq -r '.data.id')

# Attach the block volumes to the instance
oci bv volume attach --volume-id $volume1 --instance-id $instance --device /dev/oracleoci/oraclevdb --wait-for-state ATTACHED --auth instance_principal
oci bv volume attach --volume-id $volume2 --instance-id $instance --device /dev/oracle/oraclevdc --wait-for-state ATTACHED --auth instance_principal

# Format the attached volumes
sudo mkfs.xfs /dev/oracle/sdb
sudo mkfs.xfs /dev/oracle/sdc

# Mount the attached volumes
sudo mkdir /mnt/volume1
sudo mount /dev/oracle/sdb /mnt/volume1
sudo mkdir /mnt/volume2
sudo mount /dev/oracle/sdc /mnt/volume2