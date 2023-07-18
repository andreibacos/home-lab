# home-lab

### 1. Install OS (Ubuntu 22.04)
### 2. Partition data drives
### 3. MergerFS fstab
```
/dev/disk/by-id/ata-ST8000NT001-3LZ101_WWZ29H9G-part1 /mnt/disk1 xfs defaults 0 1
/dev/disk/by-id/ata-ST8000NT001-3LZ101_WRQ1K284-part1 /mnt/disk2 xfs defaults 0 1
/dev/disk/by-id/ata-ST8000NT001-3LZ101_WRQ1KS8X-part1 /mnt/disk3 xfs defaults 0 1
/dev/disk/by-id/ata-ST8000NT001-3LZ101_WWZ29HCH-part1 /mnt/parity1 xfs defaults 0 1
/mnt/disk1:/mnt/disk2:/mnt/disk3 /data fuse.mergerfs defaults,ignorepponrename=true,nonempty,allow_other,use_ino,cache.files=full,moveonenospc=true,dropcacheonclose=true,minfreespace=200G,fsname=mergerfs 0 0
```
### 4. SnapRAID /etc/snapraid.conf
```
# Excludes hidden files and directories
exclude *.unrecoverable
exclude /tmp/
exclude /lost+found/
exclude download/
exclude appdata/
exclude *.!sync

parity /mnt/parity/snapraid.parity
content /var/snapraid/snapraid.content
content /mnt/disk1/snapraid.content
content /mnt/disk2/snapraid.content
data d1 /mnt/disk1/
data d2 /mnt/disk2/
data d3 /mnt/disk3/
```

### 5. SnapRAID cronjobs (root)
```
0 4 * * * snapraid sync
0 3 * * * snapraid scrub --plan 20 --older-than 10
```

### 6. smartd.conf
```
/dev/sda -a -I 194 -W 4,45,55 -R 5  -s S/../.././04 -m email@domain
/dev/sdb -a -I 194 -W 4,45,55 -R 5  -s S/../.././04 -m email@domain
/dev/sdc -a -I 194 -W 4,45,55 -R 5  -s S/../.././04 -m email@domain
/dev/sdd -a -I 194 -W 4,45,55 -R 5  -s S/../.././04 -m email@domain
```

### 7. ssmtp.conf
```
root=user@gmail
mailhub=smtp.gmail.com:465
FromLineOverride=YES
AuthUser=user@gmail.com
AuthPass=pass
UseTLS=YES
```

### 8. Run Ansible
```
sudo apt install ansible
ansible-galaxy install -r requirements.yml
ansible-playbook nas.yml --ask-vault-password --become --ask-become-pass --verbose
```