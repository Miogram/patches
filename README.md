# Miogram patches

Downstream patches used by Miogram build automation.

## TDLib

TDLib patches are applied in the order listed by `tdlib/series`:

```bash
./tdlib/apply.sh /path/to/td
```

Patch application is strict and fails if the upstream checkout is dirty or a
patch no longer applies cleanly.
