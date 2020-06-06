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
