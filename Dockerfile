FROM continuumio/miniconda3:4.6.14

ENV DEBIAN_FRONTEND noninteractive
ENV TERM linux

ENV MLFLOW_HOME  /usr/app/mlflow
ENV MLFLOW_USER  mlflow
ENV MLFLOW_UID   5055
ENV MLFLOW_GROUP ${MLFLOW_USER}
ENV MLFLOW_GID   ${MLFLOW_UID}
ENV MLFLOW_SHELL /bin/bash

WORKDIR /workspace
COPY pyproject.toml .
COPY poetry.lock .

RUN set -ex \
 && buildDeps=' \
        build-essential \
        default-libmysqlclient-dev \
    ' \
 && apt-get update -yqq \
 && apt-get install -yqq --no-install-recommends \
        $buildDeps \
        mysql-client \
        gnupg \
        openjdk-8-jre-headless \
        locales \
 && sed -i 's/^# en_US.UTF-8 UTF-8$/en_US.UTF-8 UTF-8/g' /etc/locale.gen \
 && locale-gen \
 && update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 \
 && mkdir -p $(dirname ${MLFLOW_HOME}) \
 && groupadd -r -g ${MLFLOW_GID} ${MLFLOW_GROUP} \
 && useradd -r -m -N \
        -d ${MLFLOW_HOME} \
        -g ${MLFLOW_GROUP} \
        -s ${MLFLOW_SHELL} \
        -u ${MLFLOW_UID} \
        ${MLFLOW_USER} \
 && pip --disable-pip-version-check --no-cache-dir install poetry \
 && poetry config settings.virtualenvs.create false \
 && poetry install --no-interaction --no-ansi \
 && apt-get remove --purge -yqq $buildDeps \
 && apt-get clean \
 && rm -rf \
        /var/lib/apt/lists/* \
        /tmp/* \
        /var/tmp/* \
        /usr/share/man \
        /usr/share/doc \
        /usr/share/doc-base

USER mlflow
WORKDIR ${MLFLOW_HOME}
RUN mkdir ./mlruns
ENTRYPOINT ["mlflow"]
