#! /usr/bin/env bash

set -ex

function update_cs_versions(){
  local phpcs_metadata_file="phpcs.json" # Path to CodeSniffer which has repo and version info.
  local standards=$(jq -r '.standards | keys | .[]' $phpcs_metadata_file) # Standards to fetch version info for.

  for standard in $standards; do
    local repo=$(jq -r ".standards.\"$standard\".repo" $phpcs_metadata_file)
    local version=$(jq -r ".standards.\"$standard\".version" $phpcs_metadata_file)
    local latest_version=$(curl -s https://api.github.com/repos/$repo/releases/latest | jq -r '.tag_name')

    # Exit with error if latest version is not found.
    if [[ "$latest_version" == "null" ]]; then
      echo "Latest version not found for $standard."
      exit 1
    fi

    # Update version in phpcs.json.
    if [[ "$version" != "$latest_version" ]]; then
      jq ".standards.\"$standard\".version = \"$latest_version\"" $phpcs_metadata_file > $phpcs_metadata_file.tmp
      mv $phpcs_metadata_file.tmp $phpcs_metadata_file
    fi
  done;
}

function update_phpcs_version(){
  local phpcs_metadata_file="phpcs.json" # Path to CodeSniffer which has repo and version info.
  local repo=$(jq -r '.phpcs.repo' $phpcs_metadata_file)
  local version=$(jq -r '.phpcs.version' $phpcs_metadata_file)
  local latest_version=$(curl -s https://api.github.com/repos/$repo/releases/latest | jq -r '.tag_name')

  # Exit with error if latest version is not found.
  if [[ "$latest_version" == "null" ]]; then
    echo "Latest version not found for CodeSniffer."
    exit 1
  fi

  # Update version in phpcs.json.
  if [[ "$version" != "$latest_version" ]]; then
    jq '.phpcs.version = "'$latest_version'"' $phpcs_metadata_file > $phpcs_metadata_file.tmp
    mv $phpcs_metadata_file.tmp $phpcs_metadata_file
  fi
}

# Update CodeSniffer version.
update_phpcs_version

# Update Standards versions.
update_cs_versions
