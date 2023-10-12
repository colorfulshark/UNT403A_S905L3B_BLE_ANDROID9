#!/system/bin/sh
if ! applypatch -c EMMC:/dev/block/recovery:17463296:e19ce9c9f34134e2b4a38578e9b5948163c298d2; then
  applypatch  EMMC:/dev/block/boot:11585536:e4b331e00e9f424106f2664d693527a3f5444b99 EMMC:/dev/block/recovery e19ce9c9f34134e2b4a38578e9b5948163c298d2 17463296 e4b331e00e9f424106f2664d693527a3f5444b99:/system/recovery-from-boot.p && log -t recovery "Installing new recovery image: succeeded" || log -t recovery "Installing new recovery image: failed"
else
  log -t recovery "Recovery image already installed"
fi
