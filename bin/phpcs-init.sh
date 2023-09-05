#! /usr/bin/env bash

set -ex

if [ "$USERNAME" == "root" ] ; then
	echo "Will not run as root, exiting"
	exit 1
fi

function cleaner(){
  local path_to_clean=$1

  local files_to_clean=(
    '.git'
    '.github'
    '.gitignore'
    '.gitattributes'
    'composer.json'
    'composer.lock'
    'package.json'
    'package-lock.json'
    'CHANGELOG.md'
    'phpcs.xml.dist.sample'
    '.gitmodules'
    '.travis.yml'
    'phpcs.xml.dist'
    'phpunit.xml.dist'
    'README.md'
    'tests'
    'phpstan.neon.dist'
    'phpstan.neon'
    'CONTRIBUTING.md'
    '.cspell.json'
    '.coveralls.yml'
    '.scrutinizer.yml'
    'Tests'
    'Test'
    'docs'
    '.phpcs.xml.dist'
    '.phpdoc.xml.dist'
    '.remarkrc'
    '.remarkignore'
    'psalm.xml'
    'psalm-autoloader.php'
    '.markdownlint-cli2.yaml'
    '.yamllint.yml'
    '.editorconfig'
    'package.xml'
    'CodeSniffer.conf.dist'
  )

  for file in "${files_to_clean[@]}"; do
    rm -rf $path_to_clean/$file
  done;

  # Delete scripts dir from CodeSniffer
  if [ -d "$path_to_clean/scripts" ] && [ -f "$path_to_clean/scripts/build-phar.php" ]; then
    rm -rf "$path_to_clean/scripts"
  fi

  # Remove bin dir from Standards and not from CodeSniffer
  if [ -d "$path_to_clean/bin" ] && { [ -f "$path_to_clean/bin/generate-forbidden-names-test-files" ] || [ -f "$path_to_clean/bin/php-lint" ] || [ -f "$path_to_clean/bin/pre-commit" ]; }; then
    rm -rf "$path_to_clean/bin"
  fi
}

function install_phpcs {
  local phpcs_path="$1/phpcs" # Path to CodeSniffer
  local phpcs_metadata_file="$2/phpcs.json" # Path to CodeSniffer which has repo and version info
  local phpcs_standards_path="$phpcs_path/src/Standards" # Path to CodeSniffer Standards
  local standards=$(jq -r '.standards | keys | .[]' $phpcs_metadata_file) # Standards to install

  # Delete old CodeSniffer
  rm -rf $phpcs_path

  # Get CodeSniffer
  local repo=$(jq -r '.phpcs.repo' $phpcs_metadata_file)
  local version=$(jq -r '.phpcs.version' $phpcs_metadata_file)

  git clone -c advice.detachedHead=false https://github.com/$repo.git $phpcs_path --branch $version --depth 1 --quiet

  cleaner $phpcs_path

  installed_paths=''

  # Get Standards
  for standard in $standards; do
    local repo=$(jq -r ".standards.\"$standard\".repo" $phpcs_metadata_file)
    local version=$(jq -r ".standards.\"$standard\".version" $phpcs_metadata_file)

    git -c advice.detachedHead=false clone https://github.com/$repo.git $phpcs_standards_path/$standard --branch $version --depth 1 --quiet

    installed_paths+=",./src/Standards/$standard"

    cleaner $phpcs_standards_path/$standard
  done;

  # Set installed_paths using phpcs --config-set
  $phpcs_path/bin/phpcs --config-set installed_paths $installed_paths
}

# $1 - Path to install CodeSniffer at.
# $2 - Path to phpcs.json file.
install_phpcs $1 $2
