#!/usr/bin/env bash

if [[ "$GITHUB_EVENT_NAME" != "pull_request" ]]; then
  echo "::warning ::This action only runs on pull_request events. Refer https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows#pull_request for more information."

  exit 0
fi

if [[ $(cat "$GITHUB_EVENT_PATH" | jq -r .pull_request.body) == *"[do-not-scan]"* ]]; then
  echo "::notice ::[do-not-scan] found in PR description. Skipping PHPCS scan."

  exit 0
fi

PHPCS_CLI="$ACTION_WORKDIR/phpcs/bin/phpcs" # This is where the phpcs binary is situated.
DOCKER_GITHUB_WORKSPACE="$ACTION_WORKDIR/workspace"

rsync -a "$GITHUB_WORKSPACE/" "$DOCKER_GITHUB_WORKSPACE"

CMD=( 'php' )

# Give user freedom to use any version of PHP.
if [[ -n "$PHPCS_PHP_VERSION" ]]; then
  if [[ -z "$( command -v php$PHPCS_PHP_VERSION )" ]]; then
    echo $( warning_message "php$PHPCS_PHP_VERSION is not available. Using default php runtime...." )

    phpcs_php_path=$( command -v php )
  else
    phpcs_php_path=$( command -v php$PHPCS_PHP_VERSION )
  fi

  CMD=( "$phpcs_php_path" )
fi

# Set phpcs path.
CMD+=( "$PHPCS_CLI" )

# Set phpcs standard.
phpcs_standard=''

defaultFiles=(
  '.phpcs.xml'
  'phpcs.xml'
  '.phpcs.xml.dist'
  'phpcs.xml.dist'
)

phpcsfilefound=1

for phpcsfile in "${defaultFiles[@]}"; do
  if [[ -f "$DOCKER_GITHUB_WORKSPACE/$phpcsfile" ]]; then
      phpcs_standard="$DOCKER_GITHUB_WORKSPACE/$phpcsfile"
      phpcsfilefound=0
  fi
done

if [[ $phpcsfilefound -ne 0 ]]; then
    if [[ -n "$1" ]]; then
      phpcs_standard="$1"
    else
      phpcs_standard="WordPress"
    fi
fi

if [[ -n "$PHPCS_STANDARD_FILE_NAME" ]] && [[ -f "$DOCKER_GITHUB_WORKSPACE/$PHPCS_STANDARD_FILE_NAME" ]]; then
  phpcs_standard="$DOCKER_GITHUB_WORKSPACE/$PHPCS_STANDARD_FILE_NAME"
fi;

CMD+=( "--standard=$phpcs_standard" )

# Set report type.
CMD+=( "--report=checkstyle" )

# Run PHPCS quietly.
CMD+=( "-q" )

# Set ignore_errors_on_exit to 1 to avoid exiting with a non-zero status code.
CMD+=( "--runtime-set" )
CMD+=( "ignore_errors_on_exit" )
CMD+=( "1" )

# Set ignore_warnings_on_exit to 1 to avoid exiting with a non-zero status code.
CMD+=( "--runtime-set" )
CMD+=( "ignore_warnings_on_exit" )
CMD+=( "1" )

# Set directory to scan.
CMD+=( "$DOCKER_GITHUB_WORKSPACE" )

# Run only if cs2pr is enabled.
if [[ "$CS2PR" == "false" ]]; then
  echo "::group::Run ${CMD[@]}"
  "${CMD[@]}"
  echo "::endgroup::"
else
  cs2pr_flags='-graceful-warnings'
  if [[ -n "$PHPCS_CS2PR_FLAGS" ]]; then
    cs2pr_flags="$PHPCS_CS2PR_FLAGS"
  fi

  echo "::group::Run ${CMD[@]}"
  "${CMD[@]}"
  echo "::endgroup::"

  echo "::group::Run cs2pr $cs2pr_flags"
  cs2pr $cs2pr_flags
  echo "::endgroup::"
fi;
