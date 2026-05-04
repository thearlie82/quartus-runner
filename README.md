# Quartus Runner

[![Build Quartus Runner Image](https://github.com/thearlie82/quartus-runner/actions/workflows/build.yml/badge.svg)](https://github.com/thearlie82/quartus-runner/actions/workflows/build.yml)
[![Test Quartus Runner Image](https://github.com/thearlie82/quartus-runner/actions/workflows/test.yml/badge.svg)](https://github.com/thearlie82/quartus-runner/actions/workflows/test.yml)

Containerised Intel Quartus Pro environment for FPGA synthesis in CI/CD pipelines and local development. Builds on top of the official `alterafpga/quartuspro-v25.1` images with additional tooling, CA certificates, and runtime fixes for headless/containerised operation.

## Docker Images

Published to `ghcr.io/thearlie82/quartus-runner:<tag>`.

| Tag | Device Family | Base Image |
|-----|---------------|------------|
| `agilex3` | Intel Agilex 3 | `alterafpga/quartuspro-v25.1:agilex3` |
| `agilex5` | Intel Agilex 5 | `alterafpga/quartuspro-v25.1:agilex5` |
| `agilex7` | Intel Agilex 7 | `alterafpga/quartuspro-v25.1:agilex7` |

### Dockerfiles

| File | Description |
|------|-------------|
| `Dockerfile` | Extends the official Quartus image directly (glibc 2.39 base). Installs git, Python 3, PowerShell, CA certs, and uses jemalloc as an `LD_PRELOAD` workaround for glibc 2.39 `mremap_chunk` heap corruption. |
| `Dockerfile.ubuntu22` | Two-stage build that copies `/opt/altera` from the official image into a clean Ubuntu 22.04 base (glibc 2.35). Installs X11/GUI libraries, PowerShell, CA certs, and removes `libudev` to prevent a `realloc()` crash in containerised environments. This is the image used in CI. |

## Scripts

| File | Description |
|------|-------------|
| `build-and-run.ps1` | PowerShell script for local Windows development. Supports `-Build`, `-Run`, `-Push`, and `-Mount` parameters. Builds the Ubuntu 22.04 image, optionally pushes to GHCR, and launches an interactive container with license server connectivity and optional project mounts. |
| `setup.sh` | Provisioning script for `Dockerfile`. Installs git, CA certificates, PowerShell, and jemalloc. Handles both apt (Debian/Ubuntu) and dnf/yum (RHEL/Fedora) package managers. |
| `ubuntu22-setup.sh` | Provisioning script for `Dockerfile.ubuntu22`. Installs system packages, X11 libraries, PowerShell, CA certificates, removes `libudev`, and verifies glibc 2.35. |

## Certificates

The repository includes internal CA certificates that are installed into the container trust store:

- `adt-rootcert01-ca.crt` — Root CA
- `adt-certserv01-ca.crt` — Intermediate CA
- `adt-git01-leaf.crt` — Git server leaf certificate

## GitHub Actions Workflows

### Build (`build.yml`)

Builds and pushes all three device-family images to GHCR on every push to `main` or manual dispatch. Uses a matrix strategy to run `agilex3`, `agilex5`, and `agilex7` builds in parallel. Each image is tagged with the device family name and a SHA-prefixed tag for traceability.

### Test (`test.yml`)

Validates the built `agilex3` image against the stock Altera image. Runs on push to `main` or manual dispatch. Tests include:

- Tool verification (git, PowerShell, Python 3, Quartus version)
- Synthesis of a minimal Verilog design with various container configurations
- Comparison with/without `libudev` to validate the removal workaround
- Comparison with/without `--net=host` to test network namespace behaviour

## Dev Container

The `.devcontainer/` directory provides a VS Code Dev Container configuration using `docker-compose.yaml`. It builds the Ubuntu 22.04 image locally and mounts the repository at `/workspace` with license server environment variables preconfigured.

```bash
# Set device family (default: agilex3)
export QUARTUS_TAG=agilex7
# Open in VS Code Dev Container or:
docker compose -f .devcontainer/docker-compose.yaml up -d
```

## Local Usage (Windows)

```powershell
# Build for agilex7
.\build-and-run.ps1 -Build -Tag agilex7

# Run interactive shell with project mounted
.\build-and-run.ps1 -Run -Tag agilex7 -Mount ..\my-project

# Build and push to GHCR
.\build-and-run.ps1 -Build -Push -Tag agilex7
```
