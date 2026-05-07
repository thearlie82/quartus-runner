# Questa FPGA Edition Install (Interactive Test)

## 1. Start container with installer mounted

From `quartus-runner/` directory on Windows:

```powershell
docker rm -f quartus_runner; .\build-and-run.ps1 -Run -Mount .
```

## 2. Run the installer

Inside the container:

```bash
chmod +x /quartus-runner/QuestaSetup-23.4.0.79-linux.run

/quartus-runner/QuestaSetup-23.4.0.79-linux.run \
  --mode unattended \
  --unattendedmodeui minimal \
  --installdir /opt/altera \
  --questa_edition questa_fe \
  --accept_eula 1
```

## 3. Verify

```bash
find /opt/altera/questa_fe -name "vsim" -type f
/opt/altera/questa_fe/bin/vsim -version
/opt/altera/questa_fe/bin/vlog -version
du -sh /opt/altera/questa_fe
```

## 4. Test PATH setup

```bash
export QUESTA_ROOTDIR=/opt/altera/questa_fe
export PATH=$QUESTA_ROOTDIR/bin:$PATH
vsim -version
```
