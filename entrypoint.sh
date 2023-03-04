#!/usr/bin/env bash

# custom path for files to override default files
custom_path="$GITHUB_WORKSPACE/.github/phpcs-ci/"

if [[ -d "$custom_path" ]]; then
    rsync -a "$custom_path" /tmp/phpcs-ci/

    bash /tmp/phpcs-ci/main.sh "$@"
else
    bash /usr/local/bin/main.sh "$@"
fi
