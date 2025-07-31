# Silverfin Linux Desktop build with BlueBuild Template &nbsp; [![bluebuild build badge](https://github.com/dadaxer/silverfin/actions/workflows/build.yml/badge.svg)](https://github.com/dadaxer/silverfin/actions/workflows/build.yml)

Silverfin is a [Bluefin-DX](https://projectbluefin.io/) based variant with some customisations.
Main changes are native Steam (with Mangohud) and some minor changes to fit my needs.

### Installed Packages

#### Native Packages
- Input Remapper
- Lutris
- Mangohud
- Steam

#### Flatpak Packages
- Flatseal (Flatpak permissions app)
- ExtensionManager (GNOME extension manager)
- Warehouse (Flatpak management app)
- Loupe (Image viewer)
- Papers (Document viewer)
- Refine (GNOME desktop settings)

## Installation

> [!WARNING]
> [This is an experimental feature](https://www.fedoraproject.org/wiki/Changes/OstreeNativeContainerStable), try at your own discretion.

To rebase an existing atomic [Fedora Silverblue](https://fedoraproject.org/atomic-desktops/silverblue/) or [Bluefin](https://projectbluefin.io/) installation to the latest build:

- First rebase to the unsigned image, to get the proper signing keys and policies installed:
  ```
  rpm-ostree rebase ostree-unverified-registry:ghcr.io/dadaxer/silverfin:stable
  ```
- Reboot to complete the rebase:
  ```
  systemctl reboot
  ```
- Then rebase to the signed image, like so:
  ```
  rpm-ostree rebase ostree-image-signed:docker://ghcr.io/dadaxer/silverfin:stable
  ```
- Reboot again to complete the installation
  ```
  systemctl reboot
  ```

The `stable` tag will automatically point to the stable build. That build will still always use the Fedora version specified in `recipe.yml`, so you won't get accidentally updated to the next major version.

## ISO

At the moment there is no ISO for Silverfin, maybe in the future. Rebasing from Fedora Silverblue or Bluefin is recommended.

## Verification

These images are signed with [Sigstore](https://www.sigstore.dev/)'s [cosign](https://github.com/sigstore/cosign). You can verify the signature by downloading the `cosign.pub` file from this repo and running the following command:

```bash
cosign verify --key cosign.pub ghcr.io/dadaxer/silverfin
```
