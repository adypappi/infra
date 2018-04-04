#!/usr/bin/env bash
# Create on given device the given number of partition by diving its size in equal parts. 
#
#
#args:mandatory
#
#
#
#
#
# version: 
#   1.0 09/2017  A. DJIGUIBA
# Dependencies: pakcage sgdisk parted
if [[ $# -ne 5 ]]; then
   echo -e "Usage:\n$0 block_device nbPartitionsToCreate indexOfFirstPartitionToCreate numberOfSectorsPerPartition partitionsLabelPrefix"
   echo -e "Using this script by example creating a partition on device:\nExample: $0 /dev/sdb 5 4 45129810 zfs_future"
   echo -e "Create Five partitions of equal number of sectors 45129810. The first partition number in device is indexOfFirstPartitionToCreate with zfs_future as partition prefix"        
   echo -e "If no sector size is provided to this script the total free sectors on the bloc device is used"
   echo "The number of partition must be <= 128 (as gpt spec). Warning the 10% of total free sector on the device are reserved." 
   echo -e "\n!!!Avoid using this script you can loose all of your system at your own risk" 
  echo "!!!For your device safety pay attention to the two sectors given to this script otherwise you can loose all your data"
   exit 1
fi
 
# BINARY PATH 
BIN_DIR=/bin
USR_BIN_DIR=/usr/bin
SBIN_DIR=/sbin
GDISK=gdisk
SGDISK=sgdisk
FDISK=fdisk
PARTPROBE=partprobe


# Here we define the Full Qualified Path of the File: Absolute path
GDISK_BIN_FQP=$SBIN_DIR/$GDISK
FDISK_BIN_FQP=$SBIN_DIR/$FDISK
SGDISK_BIN_FQP=$SBIN_DIR/$SGDISK
PARTPROBE_BIN_FQP=$SBIN_DIR/$PARTPROBE
LS_BIN_FQP=${BIN_DIR}/ls
WC_BIN_FQP=${USR_BIN_DIR}/wc

# Reserved Some sectors for future work: 10% of block device size
PERCENTAGE_SECTORS_KEEP=10

# CHECK FDISK and GDISK
echo "Cheeck that the tools $FDISK $GDISK $PARTPROBE $SGDISK are installed" 
for binary in $FDISK $GDISK $PARTPROBE $SGDISK; do
  if [[ $(which $binary) != */$binary ]]; then 
     echo "This script depends on binary $binary. Please install it before running this script"
     exit -1
  fi
done

# Set script parameters
device=$1
nbPartitions=$2
startParitionNumber=$3
nbSectorsPerPartition=$4
partitionsLabelPrefix=$5

# Total sector of partitions to create
nbTotalSectorsToUse=$(( nbPartitions * nbSectorsPerPartition )) 

# Get the last and the first usable sector of the device. 
deviceUsableSectorLimits=($( ${GDISK_BIN_FQP} -l $device  | grep "First" | grep -oP "(\d+)" )) || exit $?
echo  "The first sector usable=${deviceUsableSectorLimits[0]} the last sector usable=${deviceUsableSectorLimits[1]}"

# Get the number of existing paritions 
nbExistingPartition=$(${LS_BIN_FQP} ${device}[0-9]* 2>/dev/null | ${WC_BIN_FQP} -l) || exit $?
echo "Number of Existing paritions on device $device=$nbExistingPartition"

# Partition alignement boundary 
DEVICE_SECTOR_BOUNDARY_SIZE=${deviceUsableSectorLimits[0]}

# Get the max partition attributes (number, beginSector, endSector)c
deviceMaxPartitionAttributes=($( $GDISK_BIN_FQP -l $device | grep -Po "^\s+(\d+)\s+(\d+)\s+(\d+)" |sort -n -k3,3|tail -1 ))  || exit $?
echo  "The max partition on block device $device (${deviceMaxPartitionAttributes[0]}, ${deviceMaxPartitionAttributes[1]}, ${deviceMaxPartitionAttributes[2]})"

# if there is no existing partition set latest partition attributes (number, blockDeviceBeginUsableSector, blodkDeviceEndUsableSector).
if [[ "${nbExistingPartition}" == "0"  ]]; then
 deviceMaxPartitionAttributes=(0 ${deviceUsableSectorLimits[0]}  ${deviceUsableSectorLimits[0]})
fi

# MEASURE UNITS
unit=1024
scale=10
keepSpace=$(( scale * unit * unit * unit )) # 100GB
mega=$(( unit * unit ))

# Compute the total number of usable block device's sectors and the number of free sectors  partionnable (minus PERCENTAGE_SECTORS_KEEP).
devNbTotalSectorsUsable=$(( deviceUsableSectorLimits[1] - deviceMaxPartitionAttributes[0] ))
devNbTotalSectorsToSplit=$(( ( 100 - PERCENTAGE_SECTORS_KEEP ) * devNbTotalSectorsUsable  / 100 ))
devNbSectorsPerPartition=$(( devNbTotalSectorsToSplit / nbPartitions ))

# Check partition size agains device free sector available
if [[ "$nbSectorsPerPartition" -gt "$devNbSectorsPerPartition" ]]; then
  echo -e "Since the number of sectors per partition provided $nbSectorsPerPartition is superiror to $devNbSectorsPerPartition"
  echo -e "\tThe total free sectors $devNbTotalSectorsToSplit on block device $device is partioned into\n\t---$nbPartitions partition(s) of $devNbSectorsPerPartition sectors---"
  nbSectorsPerPartition=$devNbSectorsPerPartition
elif [[ "$nbSectorsPerPartition" -eq "" ]]; then
  # User do not provide a specific number of sector per partition so split the usable free sectors of equal size. 
  echo -e "Since no number of sectors per partition provided use $devNbSectorsPerPartition per partition ---"
  nbSectorsPerPartition=$devNbSectorsPerPartition
fi
 
echo "Processing Create $nbPartitions Partitions of $nbSectorsPerPartition on the block device $device"

partitionCmd=${SGDISK_BIN_FQP}

existingMaxPartitionIndex=${deviceMaxPartitionAttributes[0]}
partitionToCreateStartSector=$(( deviceMaxPartitionAttributes[2] + DEVICE_SECTOR_BOUNDARY_SIZE ))
startPartIndex=$((existingMaxPartitionIndex + 1 )) 
endPartIndex=$(( existingMaxPartitionIndex + nbPartitions ))

for (( i=$startPartIndex; i<=$endPartIndex; i++ )); do
  partitionFirstSector=$(( ((i - $startPartIndex) * nbSectorsPerPartition)  + partitionToCreateStartSector ))
  partitionLastSector=$(( partitionFirstSector + nbSectorsPerPartition ))
  if [[ $partitionLastSector -lt ${deviceUsableSectorLimits[1]} ]]; then
    partitionCmd="$partitionCmd -n $i:$((partitionFirstSector+1)):$partitionLastSector -t $i:8300 -c $i:${partitionsLabelPrefix}_$i"
  else
   echo -e "=====>The partition $i can not be created  because it's max sector $partitionLastSector is superior to block device max free usable sector ${deviceUsableSectorLimits[1]}"
  fi
done

partitionCmd="$partitionCmd -p $device"    

read -p "WARNING!!! execute this partition command $partitionCmd Enter 'y' to process and 'n' to leave?" yesOrNo
if [[ "$yesOrNo" = "y" ]];then
  $(echo $partitionCmd)
else
    echo "No action taken on $device is safe. "
    exit 3
fi

# Make partprobe to ensure that the rerun of this script use the correct partitions state for all block devices
${PARTPROBE_BIN_FQP} || exit $?


