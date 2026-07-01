# Fe02-OS

This project provides custom OS images based on [Fedora bootC](https://docs.fedoraproject.org/en-US/fedora-coreos/bootc/), branded as Fe02-OS.

The images are built automatically using GitHub Actions and are available on `ghcr.io`.

## Getting Started

You can switch your OS to one of the Fe02-OS images using the `bootc` command.

**Warning:** This will replace your current operating system with the selected Fe02-OS image.

### Fe02-OS KDE

```bash
sudo bootc switch ghcr.io/m-fe02/fe02-os:kde
```

### Fe02-OS KDE (Gaming)

```bash
sudo bootc switch ghcr.io/m-fe02/fe02-os:kde-gaming
```

### Fe02-OS GNOME

```bash
sudo bootc switch ghcr.io/m-fe02/fe02-os:gnome
```

### Fe02-OS GNOME (Gaming)

```bash
sudo bootc switch ghcr.io/m-fe02/fe02-os:gnome-gaming
```

### Fe02-OS Cosmic

```bash
sudo bootc switch ghcr.io/m-fe02/fe02-os:cosmic
```

### Fe02-OS Cosmic (Gaming)

```bash
sudo bootc switch ghcr.io/m-fe02/fe02-os:cosmic-gaming
```

### Fe02-OS Sway

```bash
sudo bootc switch ghcr.io/m-fe02/fe02-os:sway
```

### Fe02-OS Sway (Gaming)

```bash
sudo bootc switch ghcr.io/m-fe02/fe02-os:sway-gaming
```

## Post-Installation Utilities

After you have switched to a Fe02-OS image and rebooted, there are two utilities available to you: `seal-os` and `fe02`.

### `seal-os`

The `seal-os` utility enables signature verification for OS updates. This ensures that your system will only accept signed updates from the `ghcr.io/m-fe02/fe02-os` repository.

To seal your system, run the following command:

```bash
sudo seal-os
```

You will be prompted to reboot after the process is complete.

### `fe02` (Fe02-OS Switcher)

The `fe02` utility is a simple script to switch between the different Fe02-OS desktop variants.

**Usage:**

```bash
fe02 [variant | command]
```

**Variants:**

*   `kde`: Switch to the Fe02-OS KDE variant.
*   `kde-gaming`: Switch to the Fe02-OS KDE (Gaming) variant.
*   `gnome`: Switch to the Fe02-OS GNOME variant.
*   `gnome-gaming`: Switch to the Fe02-OS GNOME (Gaming) variant.
*   `cosmic`: Switch to the Fe02-OS Cosmic variant.
*   `cosmic-gaming`: Switch to the Fe02-OS Cosmic (Gaming) variant.
*   `sway`: Switch to the Fe02-OS Sway variant.
*   `sway-gaming`: Switch to the Fe02-OS Sway (Gaming) variant.

**Commands:**

*   `status`: Show the current booted and staged images.
*   `upgrade`: Upgrade to the latest version of the current image.

**Example:**

To switch to the Kinoite variant, run the following command:

```bash
fe02 kde
```

You will be prompted to reboot after the switch is staged.
