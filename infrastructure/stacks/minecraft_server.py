from aws_cdk import (
    aws_ec2 as ec2,
    aws_s3 as s3,
    aws_iam as iam,
    core
)
from aws_cdk.aws_ec2 import UserData

class BackupBucket(core.Stack):
    def __init__(self, scope: core.Construct, id: str, **kwargs) -> None:
        super().__init__(scope, id, **kwargs)
        self.backup_bucket = s3.Bucket(self, "mc-backup")


class MinecraftServer(core.Stack):
    def __init__(self, scope: core.Construct, id: str, backup_bucket, **kwargs) -> None:
        super().__init__(scope, id, **kwargs)

        ubuntu_lts = ec2.MachineImage.generic_linux({
            'eu-west-2': 'ami-0917237b4e71c5759'})
        vpc = ec2.Vpc.from_lookup(self, "VPC", vpc_id="vpc-60d9ad08")

        security_group = ec2.SecurityGroup(self, "MinecraftServer",
            vpc=vpc,
            description="minecraft server security group",
            allow_all_outbound=True)
        security_group.add_ingress_rule(ec2.Peer.any_ipv4(),
            ec2.Port.tcp(22), "Allow ssh access")
        security_group.add_ingress_rule(ec2.Peer.any_ipv4(),
            ec2.Port.tcp(25565), "Spigot port")

        role = iam.Role(self, "MinecraftServerRole",
            assumed_by=iam.ServicePrincipal("ec2.amazonaws.com"))
        role.add_to_policy(iam.PolicyStatement(
            resources=[
                backup_bucket.bucket_arn,
                backup_bucket.bucket_arn + "/*"
            ],
            actions=[
                "s3:GetObject",
                "s3:ListBucket",
                "s3:PutObject",
                "s3:DeleteObject"
            ]
        ))

        instance = ec2.Instance(self, "MinecraftEC2",
            instance_type=ec2.InstanceType("t3.medium"),
            machine_image=ubuntu_lts,
            vpc=vpc,
            security_group=security_group,
            key_name="carwyn",
            role=role)
        setup_file = open("./configure_minecraft.sh", "rb").read()
        instance.user_data.add_commands(str(setup_file, 'utf-8'))

        ec2.CfnEIPAssociation(self, "MinecraftIp",
            allocation_id="eipalloc-002456c0178e856c1",
            instance_id=instance.instance_id)
