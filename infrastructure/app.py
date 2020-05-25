#!/usr/bin/env python3

from aws_cdk import core

from stacks.minecraft_server import MinecraftServer

app = core.App()
MinecraftServer(app, "minecraft-server", env={
    'region': 'eu-west-2',
    'account': '098281131088'})

app.synth()
