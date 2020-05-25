from aws_cdk import (
    aws_ec2 as ec2,
    core
)

class MinecraftServer(core.Stack):
    def __init__(self, scope: core.Construct, id: str, **kwargs) -> None:
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

        ec2.Instance(self, "MinecraftEC2",
            instance_type=ec2.InstanceType("t3.small"),
            machine_image=ubuntu_lts,
            vpc=vpc,
            security_group=security_group,
            key_name="carwyn")
        
