#!/bin/bash

# Ask for Organization and Package names if they weren't provided
if [ $# -eq 0 ]
    then
     read -p  'Organization Name:' ORGANIZATION_NAME
     read -p 'Package Name:' PACKAGE_DISPLAY_NAME
    else
     ORGANIZATION_NAME=$1
     PACKAGE_DISPLAY_NAME=$(echo $2 | tr '-' ' ')
fi

ORGANIZATION_NAME=${ORGANIZATION_NAME//[^[:alnum:]]/}
PACKAGE_NAME=${PACKAGE_DISPLAY_NAME//[^[:alnum:]]/}
FULL_NAME=$(echo "com.${ORGANIZATION_NAME}.${PACKAGE_NAME}" | tr '[:upper:]' '[:lower:]')

# Edit package.json.
sed -i.bak "s/com.organization.package/${FULL_NAME}/" package.json
sed -i.bak "s/Package/${PACKAGE_DISPLAY_NAME}/" package.json

# Assign Organization and Pacakge names in asmdef files.
find . -name "*.asmdef" -exec sed -i.bak "s/Package/${PACKAGE_NAME}/g" {} \;
find . -name "*.asmdef" -exec sed -i.bak "s/Organization/${ORGANIZATION_NAME}/g" {} \;

# Rename assembly definition files and their .meta files
for f in */*.asmdef* ; do mv $f $(echo "${f/Organization.Package/${ORGANIZATION_NAME}.${PACKAGE_NAME}}") ; done;

# Clear README
echo "# ${PACKAGE_DISPLAY_NAME}" > README.md

# Delete .github folder
rm -rf .github

# Delete generated .bak files
find . -name "*.bak" -type f -delete

echo "Package is Initialized"

#Deletes itself
rm -- "$0"