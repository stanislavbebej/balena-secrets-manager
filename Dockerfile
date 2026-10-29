FROM alpine:3.24.3@sha256:be2656061b536c1883c4034790e21d0a09c5aaaf51968b89368a3c0371ea2c9a

ARG SUMMON_SECRETS_MANAGER_VERSION=1.0.0
ARG SUMMON_VERSION=0.13.1

# Install CyberArk Summon
RUN wget -qO - https://github.com/cyberark/summon/releases/download/v${SUMMON_VERSION}/summon-linux-arm64.tar.gz | tar -zxf - -C /usr/local/bin summon

# Install Summon providers
RUN mkdir -p /usr/local/lib/summon \
    && wget -qO /usr/local/lib/summon/summon-secrets-manager https://github.com/stanislavbebej-ext43345/summon-secrets-manager/releases/download/v${SUMMON_SECRETS_MANAGER_VERSION}/summon-secrets-manager-linux-arm64 \
    && chmod +x /usr/local/lib/summon/summon-secrets-manager

CMD /bin/sh -c 'echo "Getting secrets ..." && summon --yaml "${SECRETS_YML:-"DUMMY_SECRET: default123"}" sleep ${ROTATION_PERIOD:-1d}'
