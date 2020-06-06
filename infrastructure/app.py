#!/usr/bin/env python3

from aws_cdk import core

from stacks.minecraft_server import (
    MinecraftServer,
    BackupBucket
)

app = core.App()
env = env={'region': 'eu-west-2', 'account': '098281131088'}

bucket = BackupBucket(app, "minecraft-backup", env=env)
MinecraftServer(app, "minecraft-server", env=env, backup_bucket=bucket.backup_bucket)

app.synth()
