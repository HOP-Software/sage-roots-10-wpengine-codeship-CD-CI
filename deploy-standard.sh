#!/bin/bash
# If any commands fail (exit code other than 0) entire script exits
set -e

# Check for required environment variables and make sure they are setup
: ${PROD_INSTALL_IP?"PROD_INSTALL_IP Missing"}   # IP for production install
: ${DEV_INSTALL_IP?"DEV_INSTALL_IP Missing"}   # IP for development install
: ${REPO_NAME?"REPO_NAME Missing"}    # theme repo name (Typically the folder name of the project)
: ${SSH_USERNAME?"SSH_USERNAME Missing"}    # Username for the SSH connection
: ${DEV_SSH_USERNAME?"DEV_SSH_USERNAME Missing"}    # Username for the SSH connection

# Set repo based on current branch, by default main=production, develop=staging
# @todo support custom branches

if [ "$CI_BRANCH" == "master" && "main" ]
then
    target_install=${PROD_INSTALL_IP}
    target_ssh=${SSH_USERNAME}
else
    target_install=${DEV_INSTALL_IP}
    target_ssh=${DEV_SSH_USERNAME}
fi

# Get official list of files/folders that are not meant to be on production if $EXCLUDE_LIST is not set.
if [[ -z "${EXCLUDE_LIST}" ]];
then
    wget https://raw.githubusercontent.com/HOP-Software/sage-roots-10-wpengine-codeship-CD-CI/main/exclude-list.txt
else
    # @todo validate proper url?
    wget ${EXCLUDE_LIST}
fi

# Loop over list of files/folders and remove them from deployment
ITEMS=`cat exclude-list.txt`
for ITEM in $ITEMS; do
    if [[ $ITEM == *.* ]]
    then
        find . -depth -name "$ITEM" -type f -exec rm "{}" \;
    else
        find . -depth -name "$ITEM" -type d -exec rm -rf "{}" \;
    fi
done

# Remove exclude-list file
rm exclude-list.txt

# Rsync to directory on server
# Create theme directory if not exist
ssh ${target_ssh}@${target_install} 'mkdir -p ~/public_html/wp-content/themes/${REPO_NAME}'

echo "Syncing theme to server: ${target_ssh}@${target_install}:~/public_html/wp-content/themes/${REPO_NAME}"
rsync -avz -e "ssh" ~/clone/ ${target_ssh}@${target_install}:~/public_html/wp-content/themes/${REPO_NAME} --delete
