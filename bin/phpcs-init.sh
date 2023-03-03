#! /usr/bin/env bash

set -e

if [ "$USERNAME" == "root" ] ; then
	echo "Will not run as root, exiting"
	exit 1
fi

# Donwload from GitHub and unzip to a directory.
function setup_from_release() {
  local repo="$1"
  local download_path="$2"
  local unzip_path="$3"

  local repo_owner=${repo%/*}
  local repo_name=${repo#*/}
  local standard_name=${repo_name#*-}

  for var in repo_owner repo_name standard_name download_path unzip_path; do
    if [ -z "${!var}" ]; then
      echo "No $var specified"
      exit 1
    fi
  done

  local zip_url=$(curl --silent "https://api.github.com/repos/$repo_owner/$repo_name$/releases/latest" | jq -r '.zipball_url')

  if [ -z "$zip_url" ] ; then
    echo "No zip URL found"
    exit 1
  fi

  local zip_file="$download_path/$standard_name.zip"

  if [ -f "$zip_file" ] ; then
    rm "$zip_file"
  fi

  curl -L -o "$zip_file" "$zip_url"

  if [ -d "$unzip_path" ] ; then
    rm -rf "$unzip_path"
  fi

  unzip -q "$zip_file" -d "$unzip_path"
}

################################################################################
#                                  Setup PHPCS                                 #
################################################################################
PHPCS_REPO="squizlabs/PHP_CodeSniffer/phpcs"
PHPCS_STANDARDS_PATH="$HOME/phpcs/src/Standards"

setup_from_release "$PHPCS_REPO" "/tmp" "$HOME/phpcs"

################################################################################
#                             Setup PHPCS Standards                            #
################################################################################

PHPCS_STANDARDS_REPO=(
  'WPTT/WPThemeReview/WPThemeReview'
  'PHPCSStandards/PHPCSUtils/PHPCSUtils'
  'automattic/vip-coding-standards/vipwpcs'
  'WordPress/WordPress-Coding-Standards/wpcs'
  'phpcompatibility/phpcompatibility/php-compatibility'
  'phpcompatibility/phpcompatibilitywp/phpcompatibility-wp'
  'sirbrillig/phpcs-variable-analysis/phpcs-variable-analysis'
  'phpcompatibility/phpcompatibilityparagonie/phpcompatibility-paragonie'
)

for standard in "${PHPCS_STANDARDS_REPO[@]}" ; do
  setup_from_release "$standard" "/tmp" "$PHPCS_STANDARDS_PATH"
done
