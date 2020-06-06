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
# todo: import config from aws

# Ensure permissions are correct
chown -R minecraft:minecraft /opt/minecraft-server
chown -R minecraft:minecraft /opt/geekzone-world
chown -R minecraft:minecraft /opt/geekzone-minecraft-config

# Setup systemd unit
cat <<EOF > /etc/systemd/system/minecraft.service
[Unit]
Description=Geekzone spigot minecraft server
After=network.target

[Service]
Type=oneshot
User=minecraft
Group=minecraft
KillMode=none
SuccessExitStatus=0 1
ReadWritePaths=/opt/geekzone-minecraft-config
ReadWritePaths=/opt/geekzone-world
ReadWritePaths=/opt/minecraft-server

WorkingDirectory=/opt/geekzone-minecraft-config
ExecStart=screen -dmS minecraft java -Dcom.mojang.eula.agree=true -jar /opt/minecraft-server/spigot-1.15.2.jar nogui --world-dir /opt/geekzone-world/
ExecStop=screen -p 0 -S minecraft -X eval 'stuff "say SERVER SHUTTING DOWN IN 15 SECONDS"\015'
ExecStop=/bin/sleep 5
ExecStop=screen -p 0 -S minecraft -X eval 'stuff "say SERVER SHUTTING DOWN IN 10 SECONDS"\015'
ExecStop=/bin/sleep 5
ExecStop=screen -p 0 -S minecraft -X eval 'stuff "say SERVER SHUTTING DOWN IN 5 SECONDS"\015'
ExecStop=/bin/sleep 5
ExecStop=screen -p 0 -S minecraft -X eval 'stuff "save-all"\015'
ExecStop=screen -p 0 -S minecraft -X eval 'stuff "stop"\015'

[Install]
WantedBy=multi-user.target
EOF
systemctl enable minecraft
systemctl start minecraft
