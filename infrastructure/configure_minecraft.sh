set -e

# System updates and dependencies
apt update -y && apt upgrade -y
apt install openjdk-11-jdk awscli -y

# Setup directory structure and users
mkdir /opt/minecraft-server
mkdir /opt/geekzone-minecraft-config
useradd -s /bin/bash -d /home/minecraft -m minecraft

# Download and install spigot
export HOME=/root # buildtools fails without this
cd /opt/minecraft-server
curl -o BuildTools.jar https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/BuildTools.jar
java -jar BuildTools.jar

# Import the geekzone world and config from s3
#  -- todo: pass bucket name in as parameter
aws s3 cp s3://minecraft-backup-mcbackup40c441f6-15b0akb5r6j18/current-world/ /opt/geekzone-world --recursive
aws s3 cp s3://minecraft-backup-mcbackup40c441f6-15b0akb5r6j18/current-config/ /opt/geekzone-minecraft-config --recursive

# Ensure permissions are correct
chown -R minecraft:minecraft /opt/minecraft-server
chown -R minecraft:minecraft /opt/geekzone-world
chown -R minecraft:minecraft /opt/geekzone-minecraft-config

# Create backup script
mkdir /opt/minecraft-utils
cat <<EOF > /opt/minecraft-utils/backup-minecraft.sh
#!/bin/bash
set -e

if [ ! \$(whoami) = "root" ]; then
    echo "Backup script must be run as root or using sudo"
    echo "currently logged in as \$(whoami)"
    exit 1
fi

set -x

DATETIME=\$(date +"%F-%H-%M-%S")
BUCKET=minecraft-backup-mcbackup40c441f6-15b0akb5r6j18

# Move current-world and current-config to new location
aws s3 mv s3://\$BUCKET/current-world s3://\$BUCKET/world-\$DATETIME --recursive
aws s3 mv s3://\$BUCKET/current-config s3://\$BUCKET/config-\$DATETIME --recursive

# Upload the current config on the server
aws s3 cp /opt/geekzone-world s3://\$BUCKET/current-world --recursive
aws s3 cp /opt/geekzone-minecraft-config s3://\$BUCKET/current-config --recursive
EOF
chmod +x /opt/minecraft-utils/backup-minecraft.sh

# Setup backup systemd unit
cat <<EOF > /etc/systemd/system/minecraft-backup.service
[Unit]
Description=Stop and backup the minecraft server

[Service]
Type=oneshot
ExecStart=systemctl stop minecraft
ExecStart=/opt/minecraft-utils/backup-minecraft.sh
ExecStop=systemctl start minecraft
EOF

# Setup backup systemd timer
cat <<EOF > /etc/systemd/system/minecraft-backup.timer
[Unit]
Description=Backup the minecraft server once a day

[Timer]
OnCalendar=*-*-* 02:00:00
Unit=minecraft-backup.service

[Install]
WantedBy=multi-user.target
EOF
systemctl enable minecraft-backup.timer
systemctl start minecraft-backup.timer

# Setup minecraft systemd unit
cat <<EOF > /etc/systemd/system/minecraft.service
[Unit]
Description=Geekzone spigot minecraft server
After=network.target

[Service]
Type=forking
User=minecraft
Group=minecraft
KillMode=none
SuccessExitStatus=0 1
ReadWritePaths=/opt/geekzone-minecraft-config
ReadWritePaths=/opt/geekzone-world
ReadWritePaths=/opt/minecraft-server

WorkingDirectory=/opt/geekzone-minecraft-config
ExecStart=screen -dmS minecraft java -server -Xms512M -Xmx2048M -XX:+UseG1GC -Dcom.mojang.eula.agree=true -jar /opt/minecraft-server/spigot-1.15.2.jar nogui --world-dir /opt/geekzone-world/
ExecStop=screen -p 0 -S minecraft -X eval 'stuff "say SERVER SHUTTING DOWN IN 15 SECONDS"\015'
ExecStop=/bin/sleep 5
ExecStop=screen -p 0 -S minecraft -X eval 'stuff "say SERVER SHUTTING DOWN IN 10 SECONDS"\015'
ExecStop=/bin/sleep 5
ExecStop=screen -p 0 -S minecraft -X eval 'stuff "say SERVER SHUTTING DOWN IN 5 SECONDS"\015'
ExecStop=/bin/sleep 5
ExecStop=screen -p 0 -S minecraft -X eval 'stuff "save-all"\015'
ExecStop=screen -p 0 -S minecraft -X eval 'stuff "stop"\015'
ExecStop=sh /opt/minecraft-utils/backup-minecraft.sh

[Install]
WantedBy=multi-user.target
EOF
systemctl enable minecraft
systemctl start minecraft
