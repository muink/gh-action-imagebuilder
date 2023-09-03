# OpenWrt GitHub Action ImageBuilder

GitHub CI action to build image via ImageBuilder using official OpenWrt ImageBuilder
Docker containers.

## Example usage

The following YAML code can be used to build image and store created image files
as artifacts.

```yaml
name: Test Build

on:
  pull_request:
    branches:
      - main

jobs:
  build:
    name: ${{ matrix.target[0] }}-${{ matrix.target[1] }} build
    runs-on: ubuntu-latest
    strategy:
      matrix:
        target:
          - ['x86', '64']
          - ['ath79', 'nand']
        include:
          - target: ['ath79', 'nand']
            profile: netgear_wndr4300

    steps:
      - uses: actions/checkout@v2
        with:
          fetch-depth: 0

      - name: Generate full target name
        env:
          TARGET: ${{ format('{0}-{1}', matrix.target[0], matrix.target[1]) }}
        run: |
          echo "Full target name is $TARGET"
          echo "TARGET=$TARGET" >> $GITHUB_ENV

      - name: Build
        uses: muink/gh-action-imagebuilder@master
        env:
          ARCH: ${{ env.TARGET }}
          PROFILE: ${{ matrix.profile}}
          REPO_DIR: ${{ github.workspace }}/releases
          PACKAGES: bash natmapt

      - name: Store images
        uses: actions/upload-artifact@v2
        with:
          name: ${{ env.TARGET }}-${{ matrix.profile }}-images
          path: bin/targets/${{ matrix.target[0] }}/${{ matrix.target[1] }}/
```

## Environmental variables

The action reads a few env variables:

* `ARCH` determines the used OpenWrt ImageBuilder Docker container.
* `ARTIFACTS_DIR` determines where built images are saved.
  Defaults to the default working directory (`GITHUB_WORKSPACE`).
* `CONTAINER` can set other ImageBuilder containers than `openwrt/imagebuilder`.
* `EXTRA_REPOS` are added to the `repositories.conf`, where `|` are replaced by white
  spaces.
* `NO_DEFAULT_REPOS` disable adding the default ImageBuilder repos
* `NO_LOCAL_REPOS` disable adding the default working directory as repo
* `REPO_DIR` used to add current repo to `repositories.conf`. Defaults to
  the default working directory (`GITHUB_WORKSPACE`).
* `KEY_BUILD` can be a private Signify/`usign` key to sign the images.
* `KEY_BUILD_PUB` the paired public key of the above private key.
* `KEY_VERIFY` public keys for `usign` used to verify repos. Format is `'<key1 string>'
  '<key2 string>' '<key3 string>'`. key string must be preprocessed into base64 str
* `NO_SIGNATURE_CHECK` not check packages signature. If your repos is not
  signed by `usign`, please enable this.
* `DISABLED_SERVICES` which services in `/etc/init.d/` should be disabled
* `PROFILE` override the default target profile. List available via `make info`.
* `PACKAGES` packages to be installed.
