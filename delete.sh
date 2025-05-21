#!/bin/bash

# --- Configuration ---
OWNER_TYPE="orgs"
OWNER="elastic-ee"
PACKAGE_TYPE="container"
PACKAGE_NAME="elasticsearch"
TAG_TO_DELETE="$1"

# --- 1. Find the Package Version ID for the specified tag ---
echo "Fetching version ID for package '${PACKAGE_NAME}' with tag '${TAG_TO_DELETE}' from owner '${OWNER}'..."

# The --jq query filters the versions to find the one with the matching tag.
# The '?' after 'tags[]' makes it safer if the 'tags' array is null or missing for some versions.
# 'head -n 1' is used in case (though unlikely for unique tags) a tag might appear in multiple listed versions.
PACKAGE_VERSION_ID=$(gh api \
  "/${OWNER_TYPE}/${OWNER}/packages/${PACKAGE_TYPE}/${PACKAGE_NAME}/versions" \
  --jq ".[] | select(.metadata.container.tags[]? == \"${TAG_TO_DELETE}\") | .id" | head -n 1)

# --- 2. Check if the Version ID was found ---
if [ -z "$PACKAGE_VERSION_ID" ]; then
  echo "Error: Could not find a package version ID for tag '${TAG_TO_DELETE}' in package '${OWNER}/${PACKAGE_NAME}'."
  echo "Please check if the tag and package details are correct, and that you have read permissions for packages in this organization."
  exit 1
fi

echo "Found package version ID: ${PACKAGE_VERSION_ID} associated with tag '${TAG_TO_DELETE}'."

# --- 3. Confirm Deletion ---
read -p "Are you sure you want to delete package version ${PACKAGE_VERSION_ID} (tag '${TAG_TO_DELETE}') from GHCR at ${OWNER}/${PACKAGE_NAME}? (yes/NO): " CONFIRMATION

if [[ "${CONFIRMATION}" != "yes" ]]; then
  echo "Deletion aborted by user."
  exit 0
fi

# --- 4. Delete the Package Version ---
echo "Attempting to delete package version ID '${PACKAGE_VERSION_ID}'..."
gh api \
  --method DELETE \
  "/${OWNER_TYPE}/${OWNER}/packages/${PACKAGE_TYPE}/${PACKAGE_NAME}/versions/${PACKAGE_VERSION_ID}"

# Check the exit status of the delete command
if [ $? -eq 0 ]; then
  echo "Successfully requested deletion of package version '${PACKAGE_VERSION_ID}' (tag '${TAG_TO_DELETE}')."
  echo "Note: The deletion might take a short while to reflect in the GitHub UI and for storage to be fully reclaimed by GHCR's garbage collection."
else
  echo "Error: Failed to delete package version '${PACKAGE_VERSION_ID}'."
  echo "Please verify your permissions (ensure your PAT has 'delete:packages' scope and you have rights in the '${OWNER}' organization)."
  echo "Also, check if the package version still exists."
fi
