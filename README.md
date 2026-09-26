# ASL3 Utilities

A collection of small utility scripts for [AllStarLink 3 (ASL3)](https://allstarlink.org/) / Asterisk node maintenance.

---

## cleardev.sh

Clears the `devstr=` value in `simpleusb.conf` and restarts Asterisk.

### What this is for

If you swap the USB sound device on your ASL3 node — for example, fitting a new AIOC, or replacing one USB sound fob with another — Asterisk can get confused. It may still be looking for the old device by its unique ID (`devstr`), even though that device is no longer plugged in.

Running this script clears that stored ID, so Asterisk goes back to automatically detecting whatever USB sound device is currently connected.

### What it actually does, step by step

1. Makes a safety copy of `/etc/asterisk/simpleusb.conf` (just in case)
2. Clears the old `devstr=` value in that file
3. Restarts Asterisk so the change takes effect

You don't need to do any of this manually — the script does all three steps for you.

Each time you run it, a fresh timestamped backup is created, for example:

```
/etc/asterisk/simpleusb.conf.bak.20260601_120000
```

### Before you start

- This is for AllStarLink 3 / Asterisk nodes
- You'll need `sudo` access on your node

### Usage

**1. Download the script**

```bash
wget -O cleardev.sh https://raw.githubusercontent.com/G1LRO/ASL3-UTILS/main/cleardev.sh
```

**2. Run it**

```bash
sudo bash cleardev.sh
```

That's it — the script handles the backup, the config edit, and the Asterisk restart for you.

### When should I run this?

- Right after you've physically swapped your USB sound device (e.g. a new AIOC, or a different USB radio interface fob)
- If Asterisk doesn't seem to notice your new device after a hardware swap

---

## switch-interface.sh (RLNZ2 fix: external CM108 behind a USB hub)

An updated version of the RLNZ2 `switch-interface.sh` that lets the external radio interface work when the CM108 sound device is connected **through a USB hub**.

### What this is for

On an RLNZ2 node, an external CM108 interface plugged **directly** into the external USB port works fine. But if the interface has its own built-in USB hub (or you plug it in through a hub), switching to external/Radio mode doesn't work. Asterisk can't find the device, so there's no receive or transmit audio.

The cause: the original setup assumes the external device is always at USB path `1-1.3:1.0`. Behind a hub, the same device appears one level deeper (for example `1-1.3.4:1.0`), so Asterisk looks in the wrong place.

This updated script finds the sound device wherever it is on the external port, directly or behind a hub, and points Asterisk at it.

### What it actually does, step by step

When you switch to external (either from the display menu or by running the script):

1. Looks for the USB sound device anywhere on the external port (`1-1.3`), including behind hubs
2. If the saved device path in `/etc/asterisk/simpleusb.conf` is different, makes a safety copy of that file and updates `devstr` in the `[NODE-external]` section **only**. Your tuning and all other settings are left alone
3. Switches `rxchannel` in `rpt.conf` to the external interface, as before
4. Restarts Asterisk

If it finds **no** sound device on the external port, or **more than one**, it stops with an error and does **not** restart Asterisk.

Switching back to internal works exactly as it did before.

### Before you start

- This is for **RLNZ2** nodes (AllStarLink 3) that already have `switch-interface.sh` installed in `/home/rln`
- You'll need `sudo` access on your node

### Usage

**1. Download the updated script** (replaces your existing copy)

```bash
wget -O ~/switch-interface.sh https://raw.githubusercontent.com/G1LRO/ASL3-UTILS/main/switch-interface.sh
chmod +x ~/switch-interface.sh
```

**2. Plug in your external interface, then switch to external**

Use **Radio** mode on the RLNZ2 display as normal, or run:

```bash
sudo ~/switch-interface.sh external
```

You should see a line like this:

```
External devstr: 1-1.3:1.0 -> 1-1.3.4:1.0 (backup /etc/asterisk/simpleusb.conf.bak.20260926_121158)
```

To go back to the internal radio:

```bash
sudo ~/switch-interface.sh internal
```

### When should I run this?

- Once, to install the fix
- **Whenever you swap external interfaces while in Radio mode** (for example, from one plugged in directly to one with a hub). The device path is only detected when you switch to external, so switch to Internal and back to Radio, or re-run `sudo ~/switch-interface.sh external`

---

## More utilities

Additional scripts will be added to this repo over time. Each will be documented in its own section above.
