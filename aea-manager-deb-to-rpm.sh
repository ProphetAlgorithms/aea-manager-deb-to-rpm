#!/bin/bash

## Author: Gianfranco Semeraro
## Email: prophet.algorithms@gmail.com

ARCH=$(uname -m)
ALIEN_BIN="alien"
ALIEN_CMD="sudo $ALIEN_BIN -r -g -c -k"
SUMMARY_TAG="Summary:"
MOD_RPMDIR_TAG="%define _rpmdir .\/"
RPMDIR_TAG="%define _rpmdir ..\/"

## If the parameters are != 1 the execution ends:
if [ "$#" -ne 1 ]; then
    echo -e "\nOnly one parameter accepted: the name of the deb package.\n"
    exit 1
fi

## If alien is not installed the execution ends:
if ! command -v $ALIEN_BIN &> /dev/null; then 
   echo -e "\nCommand \"${ALIEN_BIN}\" could not be found."
   echo -e "You need to install the \"${ALIEN_BIN}\" package before continuing.\n"
   exit 1
fi

## Run alien with the -g option which generates a folder with all the package
## files but does not build the package. This is necessary because inside the spec 
## file the "Summary:" tag does not contain a value and makes it impossible to create 
## the rpm package:
echo "*Running command: ${ALIEN_CMD} $1"
ALIEN_OUT=($($ALIEN_CMD $1))
if [[ ${ALIEN_OUT} != "" ]] && [[ "${ALIEN_OUT[2]}" == "prepared." ]] && [ ${#ALIEN_OUT[@]} -eq 3 ]; then
   echo "${ALIEN_OUT[@]}"
  else
   exit 1
fi

## Extract the package folder end the package spec from the alien output:
ALIEN_DIR=${ALIEN_OUT[1]}
ALIEN_SPEC="${ALIEN_DIR}/${ALIEN_DIR}-1.spec"

## Old code. Use grep to search for a string in a file, if found, it returns the line number:
#SUMMARY_GREP_CMD="grep -n ${SUMMARY_TAG} ${ALIEN_DIR}/${ALIEN_DIR}-1.spec"
#SUMMARY_GREP_OUT=$(${SUMMARY_GREP_CMD})
#SUMMARY_LINE=${SUMMARY_GREP_OUT%%:*}

## Using sed to replace the line containing "Summary:":
SED_SUMMARY_CMD="sudo sed -i 's/${SUMMARY_TAG}/${SUMMARY_TAG} aea-manager/' ${ALIEN_SPEC}"
bash -c "${SED_SUMMARY_CMD}"

## Using sed to replace the line containing "%define _rpmdir ../", to create the rpm package
## in the same folder where the script is located:
SED_RPMDIR_CMD="sudo sed -i 's/${RPMDIR_TAG}/${MOD_RPMDIR_TAG}/' ${ALIEN_SPEC}"
bash -c "${SED_RPMDIR_CMD}"

## Starting rpmbuild to build the rpm package:
CURR_DIR=`pwd`
RPMBUILD_CMD="sudo rpmbuild --buildroot='${CURR_DIR}/${ALIEN_DIR}' -ba ${ALIEN_SPEC}"
echo "*Running command: ${RPMBUILD_CMD}"
bash -c "${RPMBUILD_CMD}"

## Delete a file generated during package building:
echo "*Delete file: /root/rpmbuild/SRPMS/${ALIEN_DIR}-1.src.rpm"
sudo rm -rf /root/rpmbuild/SRPMS/${ALIEN_DIR}-1.src.rpm

## Change the owner of the rpm package:
SUDO_USER=$(sudo printenv SUDO_USER)
echo "*Change package owner (${SUDO_USER}): ${CURR_DIR}/${ALIEN_DIR}-1.${ARCH}.rpm"
sudo chown ${SUDO_USER} ${CURR_DIR}/${ALIEN_DIR}-1.${ARCH}.rpm

## Python version warning, distributions like fedora have too recent versions of the software
## making aea-manager unusable:
echo "*The first version of aea-manager needs python 3.8 (Fedora 34: dnf install python3.8)"

## Other notices:
echo "** Script tested on fedora 34 **"

exit 0
