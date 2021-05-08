#!/bin/bash

ARCH=$(uname -m)
RELEASE="1"
ALIEN_BIN="alien"
SED_BIN="sed"
URL="https://aea-manager.fetch.ai"
ALIEN_CMD="sudo $ALIEN_BIN -r -g -c -k"
SUMMARY_TAG="Summary:"
MOD_SUMMARY_TAG="Summary: Autonomous Economic Agents (AEA) Manager to easily build your agents."
RPMDIR_TAG="%define _rpmdir ..\/"
MOD_RPMDIR_TAG="%define _rpmdir .\/"
#RPM_FILENAME_TAG="%define _rpmfilename %%{NAME}-%%{VERSION}-%%{RELEASE}.%%{ARCH}.rpm"
#MOD_RPM_FILENAME_TAG="%define _rpmfilename %%{NAME}-%%{VERSION}-%%{RELEASE}.%%{ARCH}.rpm"
DESCRIPTION="Software created to simplify the creation of agents (AEA) for those who are not\nfamiliar with programming but also gives the possibility to edit the code for those\nwho are experts, adding the environment for execution and management.\n"
DESKTOP_FILE_TAG="Icon=aea_manager"
MOD_DESKTOP_FILE_TAG="Icon=\/usr\/share\/icons\/hicolor\/0x0\/apps\/aea_manager.png"
declare -a dir_tags=("%dir\s\\\"\/\\\"" "%dir\\s\\\"\/usr\/\\\"" "%dir\\s\\\"\/usr\/share\/\\\"" "%dir\\s\\\"\/usr\/share\/applications\/\\\"" "%dir\\s\\\"\/usr\/share\/icons\/\\\"" "%dir\\s\\\"\/usr\/share\/icons\/hicolor\/\\\"" "%dir\\s\\\"\/usr\/share\/icons\/hicolor\/0x0\/\\\"" "%dir\\s\\\"\/usr\/share\/icons\/hicolor\/0x0\/apps\/\\\"" "%dir\\s\\\"\/usr\/share\/doc\/\\\"" "%dir\\s\"\/opt\/\\\"")

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

## If sed is not installed the execution ends:
if ! command -v $SED_BIN &> /dev/null; then 
   echo -e "\nCommand \"${SED_BIN}\" could not be found."
   echo -e "You need to install the \"${SED_BIN}\" package before continuing.\n"
   exit 1
fi

## Run alien with the -g option which generates a folder with all the package
## files but does not build the package. This is necessary because inside the spec 
## file the "Summary:" tag does not contain a value and makes it impossible to create 
## the rpm package:
echo "* Running command: ${ALIEN_CMD} $1"
ALIEN_OUT=($($ALIEN_CMD $1))
if [[ ${ALIEN_OUT} != "" ]] && [[ "${ALIEN_OUT[2]}" == "prepared." ]] && [ ${#ALIEN_OUT[@]} -eq 3 ]; then
   echo "${ALIEN_OUT[@]}"
  else
   exit 1
fi

## Extract the package folder and the package spec from the alien output:
ALIEN_DIR=${ALIEN_OUT[1]}
ALIEN_SPEC="${ALIEN_DIR}/${ALIEN_DIR}-${RELEASE}.spec"

## Old code. Use grep to search for a string in a file, if found, it returns the line number:
#SUMMARY_GREP_CMD="grep -n ${SUMMARY_TAG} ${ALIEN_DIR}/${ALIEN_DIR}-${RELEASE}.spec"
#SUMMARY_GREP_OUT=$(${SUMMARY_GREP_CMD})
#SUMMARY_LINE=${SUMMARY_GREP_OUT%%:*}

## Using sed to replace the line containing "Summary:":
SED_SUMMARY_CMD="sudo sed -i 's/^${SUMMARY_TAG}/${MOD_SUMMARY_TAG}/' ${ALIEN_SPEC}"
bash -c "${SED_SUMMARY_CMD}"

## Add URL tag
bash -c "sudo sed -i '/^${SUMMARY_TAG}.*/a URL: ${URL}' ${ALIEN_SPEC}"

## Using sed to replace the line containing "%define _rpmdir ../", to create the rpm package
## in the same folder where the script is located:
SED_RPMDIR_CMD="sudo sed -i 's/^${RPMDIR_TAG}/${MOD_RPMDIR_TAG}/' ${ALIEN_SPEC}"
bash -c "${SED_RPMDIR_CMD}"

## Using sed to replace the line containing "%define _rpmfilename %%{NAME}-%%{VERSION}-%%{RELEASE}.%%{ARCH}.rpm"
#SED_FILENAME_CMD="sudo sed -i 's/^${RPM_FILENAME_TAG}/${MOD_RPM_FILENAME_TAG}/' ${ALIEN_SPEC}"
#bash -c "${SED_FILENAME_CMD}"

## Add description
sudo sed -i -e '/^%description$/,/^%.*/{//!d}' ${ALIEN_SPEC}
bash -c "sudo sed -i -e '/^%description$/a ${DESCRIPTION}' ${ALIEN_SPEC}"


## Using sed to replace the line containing " <project description>"
SED_DESCRIPTION_CMD="sudo sed -i 's/^${DESCRIPTION_TAG}/${MOD_DESCRIPTION_TAG}/' ${ALIEN_SPEC}"
bash -c "${SED_DESCRIPTION_CMD}"

## Using sed to fix the path for application icon
DESKTOP_FILE=${ALIEN_DIR}"/usr/share/applications/aea_manager.desktop"
SED_DESKTOP_FILE_CMD="sudo sed -i 's/^${DESKTOP_FILE_TAG}/${MOD_DESKTOP_FILE_TAG}/' ${DESKTOP_FILE}"
bash -c "${SED_DESKTOP_FILE_CMD}"

## Remove unnecessary dirs
for dir in ${dir_tags[@]}; do
  bash -c "sudo sed -i '/^${dir}/d' ${ALIEN_SPEC}"
done

## Starting rpmbuild to build the rpm package:
CURR_DIR=`pwd`
RPMBUILD_CMD="sudo rpmbuild --buildroot='${CURR_DIR}/${ALIEN_DIR}' -ba ${ALIEN_SPEC}"
echo "* Running command: ${RPMBUILD_CMD}"
bash -c "${RPMBUILD_CMD}"

## Delete a file generated during package building:
echo "* Delete file: /root/rpmbuild/SRPMS/${ALIEN_DIR}-${RELEASE}.src.rpm"
sudo rm /root/rpmbuild/SRPMS/${ALIEN_DIR}-${RELEASE}.src.rpm

## Change the owner of the rpm package:
SUDO_USER=$(sudo printenv SUDO_USER)
echo "* Change package owner (${SUDO_USER}): ${CURR_DIR}/${ALIEN_DIR}-${RELEASE}.${ARCH}.rpm"
sudo chown ${SUDO_USER}:${SUDO_USER} ${CURR_DIR}/${ALIEN_DIR}-${RELEASE}.${ARCH}.rpm

## Python version warning, distributions like fedora have too recent versions of the software
## making aea-manager unusable:
echo "* The first version of aea-manager needs python 3.8 (Fedora 34: dnf install python3.8)"

## Other notices:
echo "** Script tested on fedora 34 **"

exit 0
