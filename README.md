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

For now this is managed by hand to get us off the existing minecraft host which is a little small for our needs.

Manual steps to reproduce (ubuntu 20.04 based image)
```
sudo apt install openjdk-11-jdk
mkdir minecraft-server
cd minecraft-server
curl -o BuildTools.jar https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/BuildTools.jar
java -jar BuildTools.jar
sed -i 's/eula=false/eula=true/' eula.txt
java -Xms1G -Xmx1G -jar spigot-1.15.2.jar nogui
```