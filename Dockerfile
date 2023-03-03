# ubuntu:latest as of 2023-02-27
FROM ubuntu:latest

LABEL "com.github.actions.icon"="check-circle"
LABEL "com.github.actions.color"="green"
LABEL "com.github.actions.name"="PHPCS CI"
LABEL "com.github.actions.description"="Run PHPCS on your codebase"
LABEL "org.opencontainers.image.source"="https://github.com/thelovekesh/phpcs-ci"

ARG DEFAULT_PHP_VERSION=8.1
ARG PHP_BINARIES_TO_PREINSTALL='7.4 8.0 8.1 8.2'

ENV DOCKER_USER=loki
ENV ACTION_WORKDIR=/home/$DOCKER_USER
ENV DEBIAN_FRONTEND=noninteractive

RUN useradd -m -s /bin/bash $DOCKER_USER \
  && mkdir -p $ACTION_WORKDIR \
  && chown -R $DOCKER_USER $ACTION_WORKDIR

RUN set -ex \
  && savedAptMark="$(apt-mark showmanual)" \
  && apt-mark auto '.*' > /dev/null \
  && apt-get update && apt-get install -y --no-install-recommends git ca-certificates curl rsync gnupg jq software-properties-common \
  && LC_ALL=C.UTF-8 add-apt-repository ppa:ondrej/php \
  && apt-get update \
  && for v in $PHP_BINARIES_TO_PREINSTALL; do \
      apt-get install -y --no-install-recommends \
      php"$v" \
      php"$v"-curl \
      php"$v"-tokenizer \
      php"$v"-simplexml \
      php"$v"-xmlwriter; \
    done \
  && update-alternatives --set php /usr/bin/php${DEFAULT_PHP_VERSION} \
  # cleanup
  && apt-get remove software-properties-common -y \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && { [ -z "$savedAptMark" ] || apt-mark manual $savedAptMark > /dev/null; } \
  && find /usr/local -type f -executable -exec ldd '{}' ';' \
      | awk '/=>/ { print $(NF-1) }' \
      | sort -u \
      | xargs -r dpkg-query --search \
      | cut -d: -f1 \
      | sort -u \
      | xargs -r apt-mark manual \
  && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
  # smoke test
  && for v in $PHP_BINARIES_TO_PREINSTALL; do \
      php"$v" -v; \
    done \
  && php -v;

COPY bin/phpcs-init.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/phpcs-init.sh

USER $DOCKER_USER

WORKDIR $ACTION_WORKDIR

RUN /usr/local/bin/phpcs-init.sh
