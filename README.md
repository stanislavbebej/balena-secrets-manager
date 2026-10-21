[![Build](https://github.com/stanislavbebej/balena-secrets-manager/actions/workflows/build.yml/badge.svg)](.github/workflows/build.yml)
[![dependabot](https://img.shields.io/badge/Dependabot-enabled-brightgreen?logo=dependabot)](.github/dependabot.yml)
[![editorconfig](https://img.shields.io/badge/EditorConfig-enabled-brightgreen?logo=editorconfig)](.editorconfig)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit)](.pre-commit-config.yaml)
[![release-please](https://img.shields.io/badge/release--please-enabled-brightgreen?logo=google)](.github/workflows/release-please.yml)

[![balena deploy button](https://www.balena.io/deploy.svg)](https://dashboard.balena-cloud.com/deploy?repoUrl=https://github.com/stanislavbebej/balena-secrets-manager)

# Secrets Manager

A balena block for centrally managing secrets across services in a fleet.

Balena does not provide a native secrets store outside of environment variables at the fleet or device level. If you want your services to use a central secrets vault, you typically have to implement retrieval logic into each service.

This block uses CyberArk [summon](https://github.com/cyberark/summon) with the [summon-secrets-manager](https://github.com/stanislavbebej-ext43345/summon-secrets-manager) provider to retrieve secrets from [Bitwarden Secrets Manager](https://bitwarden.com/help/secrets-manager-overview/) (BWS) and store them in a shared in-memory volume as files. You manage secrets in BWS, grant access to a machine account, and use its access token to retrieve them in balena. This lets you store only one token as an environment variable and automatically get updated values when rotated in BWS.

> **Note**: This block currently targets **ARM64 / aarch64** devices (e.g., Raspberry Pi 3/4/5 64-bit, generic aarch64).

## Quickstart

Add `secrets-manager` and a shared `tmpfs` volume to your `docker-compose.yml`:

```yaml
version: '2'

volumes:
  secrets:
    driver: local
    driver_opts:
      type: tmpfs
      o: size=1M
      device: tmpfs

services:
  secrets-manager:
    image: bh.cr/g_stanislav_bebej/secrets-manager
    restart: always
    environment:
      SECRETS_YML: |
        summon.files:
          - path: /secrets/default.json
            format: json
            overwrite: true
            permissions: 0640
            secrets:
              DUMMY_SECRET: !var acd2d25f-1fd2-4604-9a6e-b2a600f71a31 # secret ID from BWS
    volumes:
      - secrets:/secrets

  my-app:
    image: your-app-image
    depends_on:
      - secrets-manager
    volumes:
      - secrets:/secrets:ro
```

> See [docker-compose.yml](docker-compose.yml) for an example development configuration.

### Steps

1. **Configure `BWS_ACCESS_TOKEN`**:
   In balenaCloud, create a **Service Variable** named [`BWS_ACCESS_TOKEN`](https://github.com/stanislavbebej-ext43345/summon-secrets-manager#usage) scoped specifically to `secrets-manager` with the machine identity access token from BWS. Scoping this to `secrets-manager` ensures other services cannot read the access token directly.

2. **Define `SECRETS_YML`**:
   Define the files and secret IDs that summon should retrieve. See the [summon push-to-file documentation](https://github.com/cyberark/summon#push-to-file) for syntax and supported formats (`json`, `yaml`, `env`).

3. **Mount secrets in consumer services**:
   Mount the `secrets` volume into your application services in read-only mode (`secrets:/secrets:ro`).

   > **Tip**: Because `depends_on` only waits for `secrets-manager` to start (not for `summon` to finish fetching secrets), ensure consumer services wait or retry if `/secrets/default.json` is not yet available at boot.

## Configuration

| Variable           | Required | Default | Description                                                                                                              |
| :----------------- | :------- | :------ | :----------------------------------------------------------------------------------------------------------------------- |
| `BWS_ACCESS_TOKEN` | Yes      | —       | Bitwarden Secrets Manager machine account access token.                                                                  |
| `SECRETS_YML`      | Yes      | —       | Summon configuration defining secret mapping and target files.                                                           |
| `ROTATION_PERIOD`  | No       | `1d`    | Refresh interval (e.g., `1d`, `12h`, `30m`). After this period, the container exits and restarts to fetch fresh secrets. |

To immediately refresh secrets at any time, restart the `secrets-manager` service in the balenaCloud dashboard.
