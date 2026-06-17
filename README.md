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

## More utilities

Additional scripts will be added to this repo over time. Each will be documented in its own section above.
