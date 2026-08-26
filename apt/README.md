# APT configuration

The files under `sources.list.d/` are a snapshot of the active APT sources on
the current WSL/Ubuntu machine.

They are intentionally not linked by `deploy.sh`: APT configuration is
system-owned, distribution-specific and depends on system keyrings. Apply
these files manually, after checking the Ubuntu release and installing the
corresponding keyrings.
