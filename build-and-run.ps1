<#
.SYNOPSIS
    Build and run the Quartus Runner Docker image.

.DESCRIPTION
    Builds the Ubuntu 22.04 based Quartus container image and optionally
    runs an interactive shell or a synthesis command.

.PARAMETER Tag
    Device family tag (agilex3, agilex5, agilex7). Default: agilex3

.PARAMETER Build
    Build the Docker image.

.PARAMETER Run
    Start an interactive bash shell.

.PARAMETER Mount
    One or more paths to mount into the container. Each folder is mounted
    at its leaf name (e.g. C:\work\agilex7dk -> /agilex7dk).

.PARAMETER Push
    Push the built image to GHCR.

.EXAMPLE
    .\build-and-run.ps1 -Build -Tag agilex3
    .\build-and-run.ps1 -Run
    .\build-and-run.ps1 -Run -Mount ..\PR_SPARROW, ..\work\agilex7dk
    .\build-and-run.ps1 -Build -Push -Tag agilex3
#>

param(
    [ValidateSet("agilex3", "agilex5", "agilex7")]
    [string]$Tag = "agilex7",

    [switch]$Build,
    [switch]$Run,
    [string[]]$Mount,
    [switch]$Push
)

$ErrorActionPreference = "Stop"
$ImageName = "quartus-runner:$Tag"
$GhcrImage = "ghcr.io/thearlie82/quartus-runner:$Tag"

# --- Build ---
if ($Build) {
    Write-Host "Building $ImageName (Dockerfile.ubuntu22, QUARTUS_TAG=$Tag)..." -ForegroundColor Cyan
    docker build -f Dockerfile.ubuntu22 --build-arg QUARTUS_TAG=$Tag -t $ImageName .
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Docker build failed."
        exit 1
    }
    Write-Host "Build complete: $ImageName" -ForegroundColor Green
}

# --- Push ---
if ($Push) {
    Write-Host "Tagging and pushing to GHCR..." -ForegroundColor Cyan
    docker tag $ImageName $GhcrImage
    docker push $GhcrImage
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Docker push failed."
        exit 1
    }
    Write-Host "Pushed: $GhcrImage" -ForegroundColor Green
}

# --- Run ---
if ($Run) {
    $ContainerName = "quartus_runner"

    # Check if container already exists and is running
    $existing = docker ps -aq -f "name=^${ContainerName}$" 2>$null
    if ($existing) {
        $running = docker ps -q -f "name=^${ContainerName}$" 2>$null
        if ($running) {
            Write-Host "Attaching to existing container '$ContainerName'..." -ForegroundColor Cyan
            docker exec -it $ContainerName bash
            exit $LASTEXITCODE
        } else {
            Write-Host "Removing stopped container '$ContainerName'..." -ForegroundColor Yellow
            docker rm $ContainerName | Out-Null
        }
    }

    # Build docker run arguments
    $dockerArgs = @(
        "run", "--rm", "-it",
        "--name", $ContainerName,
        "--hostname", $ContainerName,
        "-e", "HOME=/tmp",
        "-e", "LM_LICENSE_FILE=1717@adt-quartuslic.ad.adt.com.au",
        "-e", "QUARTUS_ROOTDIR=/opt/altera/quartus",
        "-e", "QUARTUS_DISABLE_DDM=1",
        "--shm-size=1g"
    )

    if ($Mount) {
        foreach ($m in $Mount) {
            $AbsPath = (Resolve-Path $m).Path
            $FolderName = Split-Path $AbsPath -Leaf
            $dockerArgs += "-v"
            $dockerArgs += "${AbsPath}:/${FolderName}"
            Write-Host "Mounting: $AbsPath -> /$FolderName" -ForegroundColor Cyan
        }
    }

    $dockerArgs += $ImageName
    $dockerArgs += "bash"

    Write-Host "Starting container '$ContainerName'..." -ForegroundColor Cyan
    & docker @dockerArgs
    exit $LASTEXITCODE
}

# --- No action specified ---
if (-not $Build -and -not $Run -and -not $Push) {
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  .\build-and-run.ps1 -Build              # Build the image"
    Write-Host "  .\build-and-run.ps1 -Run                # Launch interactive shell"
    Write-Host "  .\build-and-run.ps1 -Run -Project <path> # Shell with project mounted"
    Write-Host "  .\build-and-run.ps1 -Build -Push        # Build and push to GHCR"
}

# SIG # Begin signature block
# MIIPBgYJKoZIhvcNAQcCoIIO9zCCDvMCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCD16KB05b8STw/d
# JK9xFLCXdjCki1z1tR442pEQjkXBmKCCDCQwggWTMIIEe6ADAgECAhMVAAAADN3h
# /u6SpLxBAAEAAAAMMA0GCSqGSIb3DQEBDQUAMCMxITAfBgNVBAMTGEFEVC1ST09U
# Q0VSVDAxLUFEVENBMjAyMDAeFw0yNTA4MDIwMTE2MzVaFw0yNzA4MDIwMTI2MzVa
# MG4xEjAQBgoJkiaJk/IsZAEZFgJhdTETMBEGCgmSJomT8ixkARkWA2NvbTETMBEG
# CgmSJomT8ixkARkWA2FkdDESMBAGCgmSJomT8ixkARkWAmFkMRowGAYDVQQDExFB
# RFQtQ0VSVFNFUlYwMS1DQTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIB
# AL6P1UrMkHTnG1evDDfqGvsy6icsIOta4cob/wjg/fwtGoSdTUduQ2VO/IZAsEzk
# ElQ991VBDwh/NUGQEcRe8fDhywHfmrdG4ZbqQG48d+ScxTp0YRg/uMW9/yL4Spaq
# 9FhBV5xIS3EpPZ69iwPn7DDpQrsNuaYLv11w925XBMfV8dImW+2iYjusAjQmyDhs
# puT+UsJmUIhmvT6y/dkoGfZNzkoj4leDn+Q98SItWnHgjvkh4EyLu7qAZeHrOjSV
# xiYmd33j28wPVTS03RL73Gpmq2zQFo70dR/EkFVGgQE9IqUMCkGLbYCR/vgKuxJs
# 33B/UfmQCBpWW/cRCOqnDNy1yn5VAV6KOBp4vAZhC7FA6rqrzR1aWAxVbY7Tx3Gq
# IztZc+PvpWPV7Ryp6nxM/7Cb6aDPg2Z+HtsaHjxsWoJMjyI76XHpTut34xn2fwXL
# CuQJW2VLpIUvFjucg8lw1dndmouMJcFJw9UVPRM1SLHZPxZLHOWSxbchY1b+6UTm
# M2vgCnaswbVaQ9k7OnQwdD58JHU4cNUhDAkf3kDmkVpIeRA+LjlidgrRDad22EJq
# /sMAgwNOz95CkjAyna3NYbmz+8nTrJ59/1kKOF/4H73t1gJXop3p7YOiSiFsY1fH
# WuCwPztXIwdGup3zZ1QFOhNHyz3hOcqZc/QzK9PzS3mHAgMBAAGjggFzMIIBbzAS
# BgkrBgEEAYI3FQEEBQIDBQAFMCMGCSsGAQQBgjcVAgQWBBSwxdg2dvdKbVB38lEJ
# dWCkmKQKtzAdBgNVHQ4EFgQUWtUTArkO4Y1h6B60uvF0Wq2iD/8wGQYJKwYBBAGC
# NxQCBAweCgBTAHUAYgBDAEEwCwYDVR0PBAQDAgGGMA8GA1UdEwEB/wQFMAMBAf8w
# HwYDVR0jBBgwFoAUXxzTJNDtZRfxF1ZguHxeFpt59QcwTgYDVR0fBEcwRTBDoEGg
# P4Y9aHR0cDovL2NybC5hZHQuY29tLmF1L0NlcnRFbnJvbGwvQURULVJPT1RDRVJU
# MDEtQURUQ0EyMDIwLmNybDBrBggrBgEFBQcBAQRfMF0wWwYIKwYBBQUHMAKGT2h0
# dHA6Ly9jcmwuYWR0LmNvbS5hdS9DZXJ0RW5yb2xsL0FEVC1ST09UQ0VSVDAxX0FE
# VC1ST09UQ0VSVDAxLUFEVENBMjAyMCgxKS5jcnQwDQYJKoZIhvcNAQENBQADggEB
# ADbTjDairSWgPpZIYUZEQJ9Kgkpjzl1IxYurHlQnsk/bXJgzRFxGuNVesGBNOLEn
# HS7wW4aDTo/q+HuCJI1KPD9eDPMLzla5wA6REMH0KC0c6NAVNuCOaRPj7lkt09j1
# FeI/hDluczWt0MV2xNo/XwY+b9iNCQ9ROzUZEoSuP8FIKFZ+JXSJ8K+s33hzSkSk
# UR4/CinxRYVRQzw5riuPYPUSRcHhJRzJjbQNfW/bvtwD+rJIdTe1f5+O53LhIaM6
# pbLZE7F6QANNJFrvvkCnrqDzmVH0RNlkNd8Up0r4Lb74U9fU+x6jV95scGS5H7lj
# DIzFL3ZMqkECBjD7lXlK4N0wggaJMIIEcaADAgECAhM6AAANjY4JaNaeQm2jAAUA
# AA2NMA0GCSqGSIb3DQEBDQUAMG4xEjAQBgoJkiaJk/IsZAEZFgJhdTETMBEGCgmS
# JomT8ixkARkWA2NvbTETMBEGCgmSJomT8ixkARkWA2FkdDESMBAGCgmSJomT8ixk
# ARkWAmFkMRowGAYDVQQDExFBRFQtQ0VSVFNFUlYwMS1DQTAeFw0yNTA5MDIwNjQx
# MDBaFw0yNjA5MDIwNjQxMDBaMIGFMRIwEAYKCZImiZPyLGQBGRYCYXUxEzARBgoJ
# kiaJk/IsZAEZFgNjb20xEzARBgoJkiaJk/IsZAEZFgNhZHQxEjAQBgoJkiaJk/Is
# ZAEZFgJhZDEMMAoGA1UECxMDQURUMQ4wDAYDVQQLEwVVc2VyczETMBEGA1UEAxMK
# QWxleCBCaW5vczCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAM59V5hg
# 8rdkX3w1zK414trpvuy7hoBn1tAoWvFOadWpVPzu+v0C1/968ab53UdHnyAO5p6C
# z3LE/Uanxoqdp+/hs2nZPNnL/Y5u0lp3A2Si6hfBE1c/AfrBKAswTSFdswZzR7vr
# 4fsBEZIRILQHHXJPmju/RxA+0njHY6TqOoiG5+UjruBfRJ1IpMq3akFLoD1GGxM0
# 3NkWTuo8NPU7KHy2IlHe9ah9t5JCd4qWTVO69uht6okOH7r2ljdwtIrdjcHlzW1f
# tIxQZzYaoaG7gCUSfN+KORU+7Zo74MrOAMoArhsKZ2/vjMWT99NPOAISJgS/Y1cJ
# yHj2rUE0QweJ+aUCAwEAAaOCAgYwggICMDwGCSsGAQQBgjcVBwQvMC0GJSsGAQQB
# gjcVCIHFzmaEooQyhp2TA4OvgHDe+TFTg53GGYH74HMCAWQCAQYwEwYDVR0lBAww
# CgYIKwYBBQUHAwMwDgYDVR0PAQH/BAQDAgeAMBsGCSsGAQQBgjcVCgQOMAwwCgYI
# KwYBBQUHAwMwTgYJKwYBBAGCNxkCBEEwP6A9BgorBgEEAYI3GQIBoC8ELVMtMS01
# LTIxLTE2NDYxNjY2MDQtMTg3Mzc3NDM1OC03NTk4OTk2MTUtMjI0MTAwBgNVHREE
# KTAnoCUGCisGAQQBgjcUAgOgFwwVYWxleC5iaW5vc0BhZHQuY29tLmF1MB0GA1Ud
# DgQWBBQ/Ql/4Vqh+GZCjTTTYFvmslVAvSDAfBgNVHSMEGDAWgBRa1RMCuQ7hjWHo
# HrS68XRaraIP/zBKBgNVHR8EQzBBMD+gPaA7hjlodHRwOi8vY3JsLmFkdC5jb20u
# YXUvQ2VydEVucm9sbC9BRFQtQ0VSVFNFUlYwMS1DQSg1KS5jcmwwcgYIKwYBBQUH
# AQEEZjBkMGIGCCsGAQUFBzAChlZodHRwOi8vY3JsLmFkdC5jb20uYXUvQ2VydEVu
# cm9sbC9BRFQtQ0VSVFNFUlYwMS5hZC5hZHQuY29tLmF1X0FEVC1DRVJUU0VSVjAx
# LUNBKDUpLmNydDANBgkqhkiG9w0BAQ0FAAOCAgEAP3L4Rmtyf7V9P2YS7N7LtJ2L
# 3rX1VwvwkJRWRde63mJii+qv/Z5dL9+fJwOHbFST1mulBpESXx1TDvx2ZikTJBMs
# lH1ZIUfLdAZ6Uz1677BAe7lrRX9Pdy+dWRNRZlSBibJNVl3qstOaeqNnigxn/SYz
# mc5VZ11oPB9bHSp7uOpCjUWiYXqqXDI0nZNF+2SHjizhEr7sWAXXOTr5wa5iA0pv
# 7xeHSoZRObdcXWgBf0BBZ9M21SBqhtR0Yg5Qp1eabuFw837YOdgizEotze1d93rf
# bHakJit+wENsItP/8qvydeWjCcQrAagGq2KzWihf6htKRkwvC1Pig4GniDjpEw0A
# 4/L7If7QV4KYeO41a6JQDCOyXuRze91GNszwFOvxvPcs8zaZGGN0TV1034CQ7DV9
# R2s4YLQRmcZJsbmAqUoZZvKq9wPBoZhPvnV4J8kC91V2ycGcVtioMux2MwK6lcrW
# jQFhwKT1LhkiZDnyduaTdkeMXZ8raijjm3Dy4mAZGSxPGbvSkil1L+vO0ZWI/U8L
# 5cAfavw+7Vu4yScXRx7SxM6MEJoId7oNiboYyEiLk/7inSAOv2QKJAJ6E0q11KZZ
# 2NNnGt/aDaKUN2ZAMMsEHLCaC7IxjYi+UCdWem+8yU0A0uGc+8Cwfbc+CrF475KO
# E/Cn1zWmXNw1IFrUJd0xggI4MIICNAIBATCBhTBuMRIwEAYKCZImiZPyLGQBGRYC
# YXUxEzARBgoJkiaJk/IsZAEZFgNjb20xEzARBgoJkiaJk/IsZAEZFgNhZHQxEjAQ
# BgoJkiaJk/IsZAEZFgJhZDEaMBgGA1UEAxMRQURULUNFUlRTRVJWMDEtQ0ECEzoA
# AA2Njglo1p5CbaMABQAADY0wDQYJYIZIAWUDBAIBBQCggYQwGAYKKwYBBAGCNwIB
# DDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEE
# AYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgQCF366LU++Mo
# dUUiGeHvNqiN9P4h72pUy3R2upvteFkwDQYJKoZIhvcNAQEBBQAEggEAWt0uiRLn
# zSkL2SilcGtHmmgtxtEougcSkmO6hCyeKl8EwHOTFwQFdHQ2ONOEPN5PkKXH6nSj
# pJBLrFPMUJJyUvelpxGO2jnMXqEeAXvLgSV76a3YyKJs1OOTvQSK1niDu9FfDGoS
# VS3AjfEELVUVCluMKZjYblzk4e1iVb9DWS9v0cptir3nuRgp0LyXcNJQkO+yh91K
# KOhm5MrQZRaC7npePjZR6fOC11Cffu+VR2xCyWsx1Pln38qYXixlRz/18k2Aarzm
# I1XVz5VBi123y3s0YL/7Kgsq8IpYhcX6Bpr6dB+uNvepsrv+p1+s/5I1yFyjAqyg
# ltsy7QOgUh5DpQ==
# SIG # End signature block
