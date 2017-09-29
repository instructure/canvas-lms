#!/bin/bash
set -e
#This syncs with -f all branches except VSTS branches that have 'vsts-pr' as name prefixes. Must pass repo name TODO: validate repo name is being passed.
echo "=============================================================================="
echo "Fetching branches from Strongmind/Github remote"
git branch -r | grep -v '\->' | while read -r remote; do git branch --track "${remote#origin/}" "$remote"; done
git remote add vsts https://strongmind.visualstudio.com/Strongmind/_git/"$1"
echo "Syncing changes to VSTS"
git branch -r | grep -v 'vsts-p.' | grep -v '\->' | while read -r remote; do git -c http.extraheader="AUTHORIZATION: bearer $SYSTEM_ACCESSTOKEN" push -u -f vsts "${remote#origin/}"; done
echo -e "Sync completed succesfully.\nCheers!\n"
echo "     （ ^_^）o自自o（^_^ ）    "
echo "=============================================================================="
