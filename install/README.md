# install

```sh
./install/bootstrap.sh headless    # CLI only
./install/bootstrap.sh desktop     # everything

DRY_RUN=1 ./install/bootstrap.sh desktop    # print the plan, change nothing
```

## Headless machine

`macos/headless.sh` sets never sleep, wake for network access, restart after a power cut.
The following items need GUI on first setup.

1. **Remote Login (SSH)** — System Settings > General > Sharing > Remote Login.

2. **Screen Sharing (VNC)** — System Settings > General > Sharing > Screen Sharing.

3. **Automatic login** — optional. `sshd` runs at the login window, so SSH works
   after a reboot without it. Only needed for an unlocked login keychain or a
   live GUI session. With FileVault on, every reboot waits for an SSH unlock,
   which defeats the power-cut restart above.

4. **Resolution with no display attached** — uncomment `displayplacer` in
   `brew/Brewfile.core`, or use a headless HDMI dummy plug.
