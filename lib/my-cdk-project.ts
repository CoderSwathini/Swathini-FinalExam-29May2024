import * as cdk from '@aws-cdk/core';
import * as ec2 from '@aws-cdk/aws-ec2';
import * as sqs from '@aws-cdk/aws-sqs';
import * as sns from '@aws-cdk/aws-sns';
import * as secretsmanager from '@aws-cdk/aws-secretsmanager';

export class MyCdkProjectStack extends cdk.Stack {
  constructor(scope: cdk.Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);
    
    
    const vpc = new ec2.Vpc(this, 'MyVpc', {
      cidr: '10.30.0.0/16',
      maxAzs: 2,
      subnetConfiguration: [
        {
          cidrMask: 24,
          name: 'PublicSubnet',
          subnetType: ec2.SubnetType.PUBLIC,
        }
      ]
    });

    
    const instance = new ec2.Instance(this, 'MyInstance', {
      vpc,
      instanceType: new ec2.InstanceType('t2.micro'), // Adjust size as necessary
      machineImage: new ec2.AmazonLinuxImage(), // Default Amazon Linux Image
      vpcSubnets: {
        subnetType: ec2.SubnetType.PUBLIC,
      },
    });

   
    const queue = new sqs.Queue(this, 'MyQueue', {
      queueName: 'MyQueue'
    });

    
    const topic = new sns.Topic(this, 'MyTopic', {
      topicName: 'MyTopic'
    });

    
    const secret = new secretsmanager.Secret(this, 'MySecret', {
      secretName: 'metrodb-secrets',
      generateSecretString: {
        secretStringTemplate: JSON.stringify({ username: 'user', password: 'pass' }),
        generateStringKey: 'password'
      }
    });
  }
}
