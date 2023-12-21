CfhighlanderTemplate do
  Name 'redshift'
  Description "redshift - #{component_version}"

  DependsOn 'lib-ec2'
  DependsOn 'lib-iam'

  Parameters do
    ComponentParam 'EnvironmentName', 'dev', isGlobal: true
    ComponentParam 'EnvironmentType', 'development', allowedValues: ['development','production'], isGlobal: true

    ComponentParam 'VpcId', type: 'AWS::EC2::VPC::Id'
    ComponentParam 'SubnetIds', type: 'CommaDelimitedList'
    ComponentParam 'NumberOfNodes', '1'
    ComponentParam 'NodeType'
    ComponentParam 'MasterUsername', 'master', allowedPattern: "'([a-z]|[0-9])+'"
    ComponentParam 'EnableLogging', 'true', allowedValues: ['true', 'false']
    ComponentParam 'AutomatedSnapshotRetentionPeriod', '7'
    ComponentParam 'MaintenanceWindow', 'sat:05:00-sat:05:30'
    ComponentParam 'Encrypt', 'true', allowedValues: ['true', 'false']
    ComponentParam 'KmsKeyId', ''
    ComponentParam 'Snapshot', ''
    ComponentParam 'SnapshotAccountOwner', ''
    ComponentParam 'DatabaseName', ''
    ComponentParam 'ParameterGroupName', ''
  end

end
