# minecraft-server
The Geek.Zone/Minecraft server

## Requirements
> This has only been run on linux so far

* python 3.6 or higher
* python virtualenv
* [AWS Cloud Development Kit](https://docs.aws.amazon.com/cdk/latest/guide/getting_started.html)

## Running infrastructure locally (on linux)
```
# todo: figure out why creds file isn't working
export AWS_ACCESS_KEY_ID=key-id-here
export AWS_SECRET_ACCESS_KEY=secret-access-key-here
cd infrastructure
source .env/bin/activate
pip install -r requirements.txt
cdk synth
```

## Creating machine images
At the moment we are using a basic ubuntu 20.04 image. My plan is to generate an AMI with all
of the require stuff inside of it using something like Packer.

For now this is managed in the userdata script.

## Accessing the console
At the moment this can be done by logging into the minecraft server and entering the screen session.
```
sudo su - minecraft
screen -r minecraft
```
When you are finished with the console press `ctrl-a d` to detach from the screen session.

## Creating a manual backup

Backups are scheduled to run automatically, but if you need to manually backup the server to install a plugin or update minecraft you can run the following commands as the `ubuntu` user.

```sh
sudo systemctl stop minecraft
sudo /opt/minecraft-utils/backup-minecraft.sh
```

## How to install a plugin

Plugins are located at `/opt/geekzone-minecraft-config/plugins/`. To install a plugin simply copy the `.jar` file to this directory.

Most plugin jar files can be downloaded with wget. Here is an example plugin installation.

```ssh
sudo su minecraft
wget https://github.com/webbukkit/dynmap/releases/download/v3.1-beta-2/Dynmap-3.1-beta-2-spigot.jar
# Restart the minecraft server world to load the plugin
sudo systemctl restart minecraft
```
