# v1-tester — TNT/V1 Protocol Tester (Termux)

Tests **TNT / no-load SSH tunnel configs** on Termux: auto-SNI selection, payload generation,
and SSH tunnel bring-up, with a styled terminal UI.

## Run (Termux)

```bash
chmod +x v1-tester.sh
./v1-tester.sh
```

> The shebang targets Termux (`/data/data/com.termux/files/usr/bin/bash`) — run it inside Termux on Android.

## What it does

1. Generates HTTP payloads for no-load tunneling
2. Brings up an SSH tunnel with the selected SNI/host
3. Reports connection status with colored output

## Files

| File | Purpose |
|---|---|
| `v1-tester.sh` | The tester (single script) |

## Notes

- Payloads are for testing your own tunnels / educational use.
- If a payload stops working, ISPs rotate their filters — regenerate.
