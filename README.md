# redshift CfHighlander Component

![cftest](https://github.com/theonestack/hl-component-redshift/actions/workflows/rspec.yaml/badge.svg)

<!--- add component description --->

```bash
kurgan add redshift
```

## Requirements

## Parameters

| Name | Use | Default | Global | Type | Allowed Values |
| ---- | --- | ------- | ------ | ---- | -------------- |
| EnvironmentName | Tagging | dev | true | String | 
| EnvironmentType | Tagging | development | true | String | ['development','production']
| VpcId | | | false | AWS::EC2::VPC::Id |
| SubnetIds | | | false | CommaDelimitedList |
| NumberOfNodes | number of redshift nodes to add to the cluster | 1 | false | Int |
| NodeType | The node type to be provisioned for the cluster | | false | String |
| MasterUsername | master username for the redshift cluster | master | | |
| EnableLogging | Enable logging information, such as queries and connection attempts | true | false | Boolean | ['true', 'false']
| AutomatedSnapshotRetentionPeriod | The number of days that automated snapshots are retained. If the value is 0, automated snapshots are disabled | 7 | false | Int | 0 to 35
| MaintenanceWindow | | sat:05:00-sat:05:30 | false | String |
| Encrypt | If true, the data in the cluster is encrypted at rest | | false | String | ['true', 'false']
| KmsKeyId | The AWS Key Management Service (KMS) key ID of the encryption key that you want to use to encrypt data in the cluster. | | | |
| Snapshot | The name of the snapshot from which to create the new cluster | | false | String |
| DatabaseName | The name of the first database to be created when the cluster is created. | | false | String |

## Configuration

**tags**

```yaml
tags:
  Locale: AU
```

## Outputs/Exports

| Name | Value | Exported |
| ---- | ----- | -------- |
| RedshiftClusterEndpoint | Endpoint.Address | true

## Development

```bash
gem install cfhighlander
```

or via docker

```bash
docker pull theonestack/cfhighlander
```

### Testing

Generate cftest

```bash
kurgan test example
```

Run cftest

```bash
cfhighlander cftest -t tests/example.test.yaml
```

or run all tests

```bash
cfhighlander cftest
```

Generate spec tests

```bash
kurgan test example --type spec
```

run spec tests

```bash
gem install rspec
```

```bash
rspec
```