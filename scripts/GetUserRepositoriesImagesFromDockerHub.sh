#!/usr/bin/env bash
# Return all images and tags associated to an user account on docker hub.
# Requires 'jq': https://stedolan.github.io/jq/
# need docker hub username and password!!!
set -e

# install jp
sudo apt-get install -y jq

# set username and password
UNAME="timsli"
UPASS="Bza2Eth1"

# aquire token
TOKEN=$(curl -s -H "Content-Type: application/json" -X POST -d '{"username": "'${UNAME}'", "password": "'${UPASS}'"}' https://hub.docker.com/v2/users/login/ | jq -r .token)

# get list of repositories for the user account
REPO_LIST=$(curl -s -H "Authorization: JWT ${TOKEN}" https://hub.docker.com/v2/repositories/${UNAME}/?page_size=100 | jq -r '.results|.[]|.name')
# build a list of all images & tags
for i in ${REPO_LIST}; do
  # get tags for repo
  IMAGE_TAGS=$(curl -s -H "Authorization: JWT ${TOKEN}" https://hub.docker.com/v2/repositories/${UNAME}/${i}/tags/?page_size=100 | jq -r '.results|.[]|.name')
  # build a list of images from tags
  for j in ${IMAGE_TAGS};  do
    # add each tag to list
    FULL_IMAGE_LIST="${FULL_IMAGE_LIST} ${UNAME}/${i}:${j}"
   done
 done
# output
printf "List of $UNAME images on docker hub informat repository:image\n"
for i in ${FULL_IMAGE_LIST};do  printf "\t${i}\n"; done

