CloudFormation do

  redshift_tags = []
  redshift_tags << {Key: 'Environment', Value: Ref(:EnvironmentName)}

  tags = external_parameters.fetch(:tags, {})
  redshift_tags += tags.map {|key,value| {Key: key, Value: value}}

  Condition(:RedshiftSingleNodeClusterCondition, FnEquals(Ref(:NumberOfNodes), '1'))
  Condition(:EnableLoggingCondition, FnEquals(Ref(:EnableLogging), 'true'))
  Condition(:SnapshotSet, FnNot(FnEquals(Ref(:Snapshot), '')))
  Condition(:DatabaseNameSet, FnNot(FnEquals(Ref(:DatabaseName), '')))
  Condition(:EncryptWithKMS, FnAnd([
    FnNot(FnEquals(Ref(:KmsKeyId), '')),
    FnEquals(Ref(:Encrypt), 'true')
  ]))

  S3_Bucket(:RedshiftLoggingS3Bucket) {
    Condition(:EnableLoggingCondition)
    DeletionPolicy 'Retain'
    BucketName FnJoin("-", ["redshift", "logs", Ref(:EnvironmentName), Ref('AWS::Region'), FnSelect(4, FnSplit('-', FnSelect(2, FnSplit('/', Ref('AWS::StackId')))))])
    BucketEncryption({
      ServerSideEncryptionConfiguration: [
        {
          ServerSideEncryptionByDefault: {
            SSEAlgorithm: 'AES256'
          }
        }
      ]
    })
    PublicAccessBlockConfiguration({
      BlockPublicAcls: true,
      BlockPublicPolicy: true,
      IgnorePublicAcls: true,
      RestrictPublicBuckets: true
    })
    Tags redshift_tags
  }

  S3_BucketPolicy(:RedshiftLoggingS3BucketPolicy) {
    Condition(:EnableLoggingCondition)
    Bucket Ref(:RedshiftLoggingS3Bucket)
    PolicyDocument({
      Statement: [
        {
          Principal: {
            Service: "redshift.amazonaws.com" 
          },
          Action: [
            "s3:PutObject",
            "s3:GetBucketAcl"
          ],
          Effect: "Allow",
          Resource: [
            FnSub("arn:aws:s3:::${RedshiftLoggingS3Bucket}"),
            FnSub("arn:aws:s3:::${RedshiftLoggingS3Bucket}/*"),
          ]
        }
      ]
    })
  }

  iam_policies = external_parameters[:iam_policies]

  IAM_Role(:RedshiftIAMRole) {
    AssumeRolePolicyDocument service_assume_role_policy(['redshift','glue'])
    Policies iam_role_policies(iam_policies['redshift'])
  }

  security_group_rules = external_parameters.fetch(:security_group_rules, [])
  ip_blocks = external_parameters.fetch(:ip_blocks, {})

  EC2_SecurityGroup(:RedshiftSecurityGroup) {
    GroupDescription FnSub("${EnvironmentName} - Redshift cluster security group")
    VpcId Ref(:VpcId)
    SecurityGroupIngress generate_security_group_rules(security_group_rules, ip_blocks, true) unless (security_group_rules.empty? || ip_blocks.empty?)
    Tags redshift_tags
  }

  SecretsManager_Secret(:SecretRedshiftMasterUser) {
    Description FnSub("${EnvironmentName} Secrets Manager to store Redshift user credentials")
    GenerateSecretString({
      SecretStringTemplate: FnSub('{"username": "${MasterUsername}"}'),
      GenerateStringKey: "password",
      PasswordLength: 32,
      ExcludePunctuation: true
    })
  }

  Output(:RedshiftSecretId) {
    Value Ref(:SecretRedshiftMasterUser)
    Export FnSub("${EnvironmentName}-#{external_parameters[:component_name]}-redshift-secret")
  }

  SecretsManager_SecretTargetAttachment(:SecretTargetAttachment) {
    SecretId Ref(:SecretRedshiftMasterUser)
    TargetId Ref(:RedshiftCluster)
    TargetType 'AWS::Redshift::Cluster'
  }

  Redshift_ClusterSubnetGroup(:RedshiftClusterSubnetGroup) {
    Description FnSub("${EnvironmentName} - Redshift cluster subnet group")
    SubnetIds Ref(:SubnetIds)
    Tags redshift_tags
  }
  
  parameters = []
  parameters << { ParameterName: 'enable_user_activity_logging', ParameterValue: 'true' }
  parameters << { ParameterName: 'wlm_json_configuration', ParameterValue: FnSub(external_parameters[:wlm_config]) } if external_parameters[:wlm_config]

  cluster_parameters = external_parameters.fetch(:cluster_parameters, {})
  cluster_parameters.each do |key,value|
    parameters << { ParameterName: key, ParameterValue: value }
  end

  Redshift_ClusterParameterGroup(:RedshiftClusterParameterGroup) do
    Description FnSub("${EnvironmentName} - Redshift cluster parameter group")
    ParameterGroupFamily 'redshift-1.0'
    Parameters parameters
    Tags redshift_tags
  end

  Redshift_Cluster(:RedshiftCluster) {
    DeletionPolicy 'Snapshot'
    UpdateReplacePolicy 'Snapshot'
    ClusterType FnIf(:RedshiftSingleNodeClusterCondition, 'single-node', 'multi-node')
    NumberOfNodes FnIf(:RedshiftSingleNodeClusterCondition, Ref('AWS::NoValue'), Ref(:NumberOfNodes))
    Encrypted Ref(:Encrypt)
    KmsKeyId FnIf(:EncryptWithKMS, Ref(:KmsKeyId), Ref('AWS::NoValue'))
    NodeType Ref(:NodeType)
    DBName FnIf(:DatabaseNameSet, Ref(:DatabaseName), Ref('AWS::NoValue'))
    MasterUsername FnSub("{{resolve:secretsmanager:${SecretRedshiftMasterUser}:SecretString:username}}")
    MasterUserPassword FnSub("{{resolve:secretsmanager:${SecretRedshiftMasterUser}:SecretString:password}}")
    ClusterParameterGroupName Ref(:RedshiftClusterParameterGroup)
    ClusterSubnetGroupName Ref(:RedshiftClusterSubnetGroup)
    VpcSecurityGroupIds([Ref(:RedshiftSecurityGroup)])
    AutomatedSnapshotRetentionPeriod Ref(:AutomatedSnapshotRetentionPeriod)
    PreferredMaintenanceWindow Ref(:MaintenanceWindow)
    LoggingProperties FnIf(:EnableLoggingCondition,
      {
        BucketName: Ref(:RedshiftLoggingS3Bucket),
        S3KeyPrefix: 'AWSLogs'
      },
      Ref('AWS::NoValue')
    )
    IamRoles [FnGetAtt(:RedshiftIAMRole, :Arn)]
    SnapshotIdentifier FnIf(:SnapshotSet, Ref(:Snapshot), Ref('AWS::NoValue'))
    Tags redshift_tags
  }

  Output(:RedshiftClusterEndpoint) {
    Value FnGetAtt(:RedshiftCluster , 'Endpoint.Address')
    Export FnSub("${EnvironmentName}-#{external_parameters[:component_name]}-redshift-endpoint")
  }

  Output(:RedshiftClusterPort) {
    Value FnGetAtt(:RedshiftCluster , 'Endpoint.Port')
    Export FnSub("${EnvironmentName}-#{external_parameters[:component_name]}-redshift-port")
  }
  
end
