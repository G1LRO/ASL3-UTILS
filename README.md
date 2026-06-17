# ASL3 Utilities

A collection of small utility scripts for [AllStarLink 3 (ASL3)](https://allstarlink.org/) / Asterisk node maintenance.

---

## cleardev.sh

Clears the `devstr=` value in `simpleusb.conf` and restarts Asterisk.

### Purpose

When you swap the USB sound device on an ASL3 node (e.g. fitting a new AIOC, CM108-class fob, or other USB sound card), `simpleusb.conf` may still be pointing at the old device's `devstr` identifier. `cleardev.sh` blanks this value so Asterisk falls back to auto-detecting the active USB sound device, rather than continuing to look for the one that's no longer there.

### What it does

1. Backs up `/etc/asterisk/simpleusb.conf` with a timestamp
2. Clears the `devstr=` value (leaves the key in place, blank)
3. Restarts Asterisk so the change takes effect

A backup is created on every run, e.g.:

```
/etc/asterisk/simpleusb.conf.bak.20260601_120000
```

### Requirements

- AllStarLink 3 / Asterisk installed
- Run as root (or with `sudo`)

### Usage

```bash
wget -O cleardev.sh https://raw.githubusercontent.com/G1LRO/ASL3-UTILS/main/cleardev.sh
sudo bash cleardev.sh
```

### When to run this

- After physically swapping the USB sound device on your node (e.g. replacing one AIOC with another, or changing to a different USB sound fob)
- If Asterisk fails to find the expected USB device after a hardware change

---

## More utilities

Additional scripts will be added to this repo over time. Each will be documented in its own section above.
