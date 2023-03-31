# ubuntu:latest as of 2023-02-27
FROM ubuntu@sha256:67211c14fa74f070d27cc59d69a7fa9aeff8e28ea118ef3babc295a0428a6d21

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

COPY phpcs.json /tmp/phpcs.json
COPY bin/phpcs-init.sh main.sh entrypoint.sh /usr/local/bin/

RUN useradd -m -s /bin/bash $DOCKER_USER \
  && mkdir -p $ACTION_WORKDIR \
  && chown -R $DOCKER_USER $ACTION_WORKDIR

RUN set -ex \
  && savedAptMark="$(apt-mark showmanual)" \
  && apt-mark auto '.*' > /dev/null \
  && apt-get update && apt-get install -y --no-install-recommends git curl rsync jq gnupg software-properties-common \
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
  && curl -SL https://github.com/staabm/annotate-pull-request-from-checkstyle/releases/latest/download/cs2pr -o /usr/local/bin/cs2pr \
  && chmod +x /usr/local/bin/cs2pr \
  && bash /usr/local/bin/phpcs-init.sh ${ACTION_WORKDIR} /tmp \
  # cleanup
  && apt-get remove git curl gnupg software-properties-common -y \
  && rm -rf bin/phpcs-init.sh /tmp/phpcs.json \
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
  && ${ACTION_WORKDIR}/phpcs/bin/phpcs -i \
  && php -v;

USER $DOCKER_USER

WORKDIR $ACTION_WORKDIR

ENTRYPOINT ["bash", "/usr/local/bin/entrypoint.sh"]
