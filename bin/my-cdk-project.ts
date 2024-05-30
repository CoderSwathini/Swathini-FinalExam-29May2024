#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from '@aws-cdk/core';
import { MyCdkProjectStack } from '../lib/my-cdk-project-stack';

const app = new cdk.App();
new MyCdkProjectStack(app, 'MyCdkProjectStack');
