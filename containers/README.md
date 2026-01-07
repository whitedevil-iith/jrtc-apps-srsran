
# 1. Preparation

To build required imagesm run in the project root:
```sh
./init_submodules.sh
```

This will initialise all submodules.

__Note that for the Docker/srsRAN_apps submodule, it is also patched with all files from folder "Docker/for_srsRAN_apps"__.


# 2. Build images

To build required images:
```sh
./init_submodules.sh
cd containers/Docker
sudo ./build.base.sh [-b <base-image-tag>]
sudo ./build_srs_jbpf.sh [-b <base-image-tag>] [-s <srs-image-tag>] [-c]   # Use -c for '--no-cache'
sudo ./build_srs_jbpf_sdk.sh [-s <srs-image-tag>]
```

# 3. Built Components

After building the `srs-jbpf` image, the following binaries are available with JRTC/JBPF support:

- **gnb** - Monolithic gNB (default deployment)
- **srscu** - Combined CU (CU-CP + CU-UP)
- **srscucp** - CU Control Plane
- **srscuup** - CU User Plane
- **srsdu** - Distributed Unit

All binaries are installed to `/usr/local/bin/` and have JBPF hooks enabled.

For detailed information about disaggregated deployments, see [docs/disaggregated-ran.md](../../docs/disaggregated-ran.md).
