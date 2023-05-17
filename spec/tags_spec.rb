require 'yaml'

describe 'compiled component redshift' do
  
  context 'cftest' do
    it 'compiles test' do
      expect(system("cfhighlander cftest #{@validate} --tests tests/tags.test.yaml")).to be_truthy
    end      
  end
  
  let(:template) { YAML.load_file("#{File.dirname(__FILE__)}/../out/tests/tags/redshift.compiled.yaml") }
  
  context "Resource" do

    
    context "RedshiftLoggingS3Bucket" do
      let(:resource) { template["Resources"]["RedshiftLoggingS3Bucket"] }

      it "is of type AWS::S3::Bucket" do
          expect(resource["Type"]).to eq("AWS::S3::Bucket")
      end
      
      it "to have property BucketName" do
          expect(resource["Properties"]["BucketName"]).to eq({"Fn::Join"=>["-", ["redshift", "logs", {"Ref"=>"EnvironmentName"}, {"Ref"=>"AWS::Region"}, {"Fn::Select"=>[4, {"Fn::Split"=>["-", {"Fn::Select"=>[2, {"Fn::Split"=>["/", {"Ref"=>"AWS::StackId"}]}]}]}]}]]})
      end
      
      it "to have property BucketEncryption" do
          expect(resource["Properties"]["BucketEncryption"]).to eq({"ServerSideEncryptionConfiguration"=>[{"ServerSideEncryptionByDefault"=>{"SSEAlgorithm"=>"AES256"}}]})
      end
      
      it "to have property PublicAccessBlockConfiguration" do
          expect(resource["Properties"]["PublicAccessBlockConfiguration"]).to eq({"BlockPublicAcls"=>true, "BlockPublicPolicy"=>true, "IgnorePublicAcls"=>true, "RestrictPublicBuckets"=>true})
      end
      
      it "to have property Tags" do
          expect(resource["Properties"]["Tags"]).to eq([{"Key"=>"Environment", "Value"=>{"Ref"=>"EnvironmentName"}}, {"Key"=>"Locale", "Value"=>"AU"}])
      end
      
    end
    
    context "RedshiftLoggingS3BucketPolicy" do
      let(:resource) { template["Resources"]["RedshiftLoggingS3BucketPolicy"] }

      it "is of type AWS::S3::BucketPolicy" do
          expect(resource["Type"]).to eq("AWS::S3::BucketPolicy")
      end
      
      it "to have property Bucket" do
          expect(resource["Properties"]["Bucket"]).to eq({"Ref"=>"RedshiftLoggingS3Bucket"})
      end
      
      it "to have property PolicyDocument" do
          expect(resource["Properties"]["PolicyDocument"]).to eq({"Statement"=>[{"Principal"=>{"Service"=>"redshift.amazonaws.com"}, "Action"=>["s3:PutObject", "s3:GetBucketAcl"], "Effect"=>"Allow", "Resource"=>[{"Fn::Sub"=>"arn:aws:s3:::${RedshiftLoggingS3Bucket}"}, {"Fn::Sub"=>"arn:aws:s3:::${RedshiftLoggingS3Bucket}/*"}]}]})
      end
      
    end
    
    context "RedshiftIAMRole" do
      let(:resource) { template["Resources"]["RedshiftIAMRole"] }

      it "is of type AWS::IAM::Role" do
          expect(resource["Type"]).to eq("AWS::IAM::Role")
      end
      
      it "to have property AssumeRolePolicyDocument" do
          expect(resource["Properties"]["AssumeRolePolicyDocument"]).to eq({"Version"=>"2012-10-17", "Statement"=>[{"Effect"=>"Allow", "Principal"=>{"Service"=>"redshift.amazonaws.com"}, "Action"=>"sts:AssumeRole"}, {"Effect"=>"Allow", "Principal"=>{"Service"=>"glue.amazonaws.com"}, "Action"=>"sts:AssumeRole"}]})
      end
      
      it "to have property Policies" do
          expect(resource["Properties"]["Policies"]).to eq([{"PolicyName"=>"s3-logging", "PolicyDocument"=>{"Statement"=>[{"Sid"=>"s3logging", "Action"=>["s3:GetBucketLocation", "s3:GetObject", "s3:ListMultipartUploadParts", "s3:ListBucket", "s3:ListBucketMultipartUploads"], "Resource"=>[{"Fn::Sub"=>"arn:aws:s3:::${RedshiftLoggingS3Bucket}"}, {"Fn::Sub"=>"arn:aws:s3:::${RedshiftLoggingS3Bucket}/*"}], "Effect"=>"Allow"}]}}, {"PolicyName"=>"glue", "PolicyDocument"=>{"Statement"=>[{"Sid"=>"glue", "Action"=>["glue:CreateDatabase", "glue:DeleteDatabase", "glue:GetDatabase", "glue:GetDatabases", "glue:UpdateDatabase", "glue:CreateTable", "glue:DeleteTable", "glue:BatchDeleteTable", "glue:UpdateTable", "glue:GetTable", "glue:GetTables", "glue:BatchCreatePartition", "glue:CreatePartition", "glue:DeletePartition", "glue:BatchDeletePartition", "glue:UpdatePartition", "glue:GetPartition", "glue:GetPartitions", "glue:BatchGetPartition"], "Resource"=>["*"], "Effect"=>"Allow"}]}}, {"PolicyName"=>"logs", "PolicyDocument"=>{"Statement"=>[{"Sid"=>"logs", "Action"=>["logs:*"], "Resource"=>["*"], "Effect"=>"Allow"}]}}])
      end
      
    end
    
    context "RedshiftSecurityGroup" do
      let(:resource) { template["Resources"]["RedshiftSecurityGroup"] }

      it "is of type AWS::EC2::SecurityGroup" do
          expect(resource["Type"]).to eq("AWS::EC2::SecurityGroup")
      end
      
      it "to have property GroupDescription" do
          expect(resource["Properties"]["GroupDescription"]).to eq({"Fn::Sub"=>"${EnvironmentName} - Redshift cluster security group"})
      end
      
      it "to have property VpcId" do
          expect(resource["Properties"]["VpcId"]).to eq({"Ref"=>"VpcId"})
      end
      
      it "to have property Tags" do
          expect(resource["Properties"]["Tags"]).to eq([{"Key"=>"Environment", "Value"=>{"Ref"=>"EnvironmentName"}}, {"Key"=>"Locale", "Value"=>"AU"}])
      end
      
    end
    
    context "SecretRedshiftMasterUser" do
      let(:resource) { template["Resources"]["SecretRedshiftMasterUser"] }

      it "is of type AWS::SecretsManager::Secret" do
          expect(resource["Type"]).to eq("AWS::SecretsManager::Secret")
      end
      
      it "to have property Description" do
          expect(resource["Properties"]["Description"]).to eq({"Fn::Sub"=>"${EnvironmentName} Secrets Manager to store Redshift user credentials"})
      end
      
      it "to have property GenerateSecretString" do
          expect(resource["Properties"]["GenerateSecretString"]).to eq({"SecretStringTemplate"=>{"Fn::Sub"=>"{\"username\": \"${MasterUsername}\"}"}, "GenerateStringKey"=>"password", "PasswordLength"=>32, "ExcludePunctuation"=>true})
      end
      
    end
    
    context "SecretTargetAttachment" do
      let(:resource) { template["Resources"]["SecretTargetAttachment"] }

      it "is of type AWS::SecretsManager::SecretTargetAttachment" do
          expect(resource["Type"]).to eq("AWS::SecretsManager::SecretTargetAttachment")
      end
      
      it "to have property SecretId" do
          expect(resource["Properties"]["SecretId"]).to eq({"Ref"=>"SecretRedshiftMasterUser"})
      end
      
      it "to have property TargetId" do
          expect(resource["Properties"]["TargetId"]).to eq({"Ref"=>"RedshiftCluster"})
      end
      
      it "to have property TargetType" do
          expect(resource["Properties"]["TargetType"]).to eq("AWS::Redshift::Cluster")
      end
      
    end
    
    context "RedshiftClusterSubnetGroup" do
      let(:resource) { template["Resources"]["RedshiftClusterSubnetGroup"] }

      it "is of type AWS::Redshift::ClusterSubnetGroup" do
          expect(resource["Type"]).to eq("AWS::Redshift::ClusterSubnetGroup")
      end
      
      it "to have property Description" do
          expect(resource["Properties"]["Description"]).to eq({"Fn::Sub"=>"${EnvironmentName} - Redshift cluster subnet group"})
      end
      
      it "to have property SubnetIds" do
          expect(resource["Properties"]["SubnetIds"]).to eq({"Ref"=>"SubnetIds"})
      end
      
      it "to have property Tags" do
          expect(resource["Properties"]["Tags"]).to eq([{"Key"=>"Environment", "Value"=>{"Ref"=>"EnvironmentName"}}, {"Key"=>"Locale", "Value"=>"AU"}])
      end
      
    end
    
    context "RedshiftClusterParameterGroup" do
      let(:resource) { template["Resources"]["RedshiftClusterParameterGroup"] }

      it "is of type AWS::Redshift::ClusterParameterGroup" do
          expect(resource["Type"]).to eq("AWS::Redshift::ClusterParameterGroup")
      end
      
      it "to have property Description" do
          expect(resource["Properties"]["Description"]).to eq({"Fn::Sub"=>"${EnvironmentName} - Redshift cluster parameter group"})
      end
      
      it "to have property ParameterGroupFamily" do
          expect(resource["Properties"]["ParameterGroupFamily"]).to eq("redshift-1.0")
      end
      
      it "to have property Parameters" do
          expect(resource["Properties"]["Parameters"]).to eq([{"ParameterName"=>"enable_user_activity_logging", "ParameterValue"=>"true"}])
      end
      
      it "to have property Tags" do
          expect(resource["Properties"]["Tags"]).to eq([{"Key"=>"Environment", "Value"=>{"Ref"=>"EnvironmentName"}}, {"Key"=>"Locale", "Value"=>"AU"}])
      end
      
    end
    
    context "RedshiftCluster" do
      let(:resource) { template["Resources"]["RedshiftCluster"] }

      it "is of type AWS::Redshift::Cluster" do
          expect(resource["Type"]).to eq("AWS::Redshift::Cluster")
      end
      
      it "to have property ClusterType" do
          expect(resource["Properties"]["ClusterType"]).to eq({"Fn::If"=>["RedshiftSingleNodeClusterCondition", "single-node", "multi-node"]})
      end
      
      it "to have property NumberOfNodes" do
          expect(resource["Properties"]["NumberOfNodes"]).to eq({"Fn::If"=>["RedshiftSingleNodeClusterCondition", {"Ref"=>"AWS::NoValue"}, {"Ref"=>"NumberOfNodes"}]})
      end
      
      it "to have property Encrypted" do
          expect(resource["Properties"]["Encrypted"]).to eq({"Ref"=>"Encrypt"})
      end
      
      it "to have property KmsKeyId" do
          expect(resource["Properties"]["KmsKeyId"]).to eq({"Fn::If"=>["EncryptWithKMS", {"Ref"=>"KmsKeyId"}, {"Ref"=>"AWS::NoValue"}]})
      end
      
      it "to have property NodeType" do
          expect(resource["Properties"]["NodeType"]).to eq({"Ref"=>"NodeType"})
      end
      
      it "to have property DBName" do
          expect(resource["Properties"]["DBName"]).to eq({"Fn::If"=>["DatabaseNameSet", {"Ref"=>"DatabaseName"}, {"Ref"=>"AWS::NoValue"}]})
      end
      
      it "to have property MasterUsername" do
          expect(resource["Properties"]["MasterUsername"]).to eq({"Fn::Sub"=>"{{resolve:secretsmanager:${SecretRedshiftMasterUser}:SecretString:username}}"})
      end
      
      it "to have property MasterUserPassword" do
          expect(resource["Properties"]["MasterUserPassword"]).to eq({"Fn::Sub"=>"{{resolve:secretsmanager:${SecretRedshiftMasterUser}:SecretString:password}}"})
      end
      
      it "to have property ClusterParameterGroupName" do
          expect(resource["Properties"]["ClusterParameterGroupName"]).to eq({"Ref"=>"RedshiftClusterParameterGroup"})
      end
      
      it "to have property ClusterSubnetGroupName" do
          expect(resource["Properties"]["ClusterSubnetGroupName"]).to eq({"Ref"=>"RedshiftClusterSubnetGroup"})
      end
      
      it "to have property VpcSecurityGroupIds" do
          expect(resource["Properties"]["VpcSecurityGroupIds"]).to eq([{"Ref"=>"RedshiftSecurityGroup"}])
      end
      
      it "to have property AutomatedSnapshotRetentionPeriod" do
          expect(resource["Properties"]["AutomatedSnapshotRetentionPeriod"]).to eq({"Ref"=>"AutomatedSnapshotRetentionPeriod"})
      end
      
      it "to have property PreferredMaintenanceWindow" do
          expect(resource["Properties"]["PreferredMaintenanceWindow"]).to eq({"Ref"=>"MaintenanceWindow"})
      end
      
      it "to have property LoggingProperties" do
          expect(resource["Properties"]["LoggingProperties"]).to eq({"Fn::If"=>["EnableLoggingCondition", {"BucketName"=>{"Ref"=>"RedshiftLoggingS3Bucket"}, "S3KeyPrefix"=>"AWSLogs"}, {"Ref"=>"AWS::NoValue"}]})
      end
      
      it "to have property IamRoles" do
          expect(resource["Properties"]["IamRoles"]).to eq([{"Fn::GetAtt"=>["RedshiftIAMRole", "Arn"]}])
      end
      
      it "to have property SnapshotIdentifier" do
          expect(resource["Properties"]["SnapshotIdentifier"]).to eq({"Fn::If"=>["SnapshotSet", {"Ref"=>"Snapshot"}, {"Ref"=>"AWS::NoValue"}]})
      end

      it "to have property OwnerAccount" do
        expect(resource["Properties"]["OwnerAccount"]).to eq({"Fn::If"=>["OwnerAccountSet", {"Ref"=>"SnapshotOwnerAccount"}, {"Ref"=>"AWS::NoValue"}]})
      end
      
      it "to have property Tags" do
          expect(resource["Properties"]["Tags"]).to eq([{"Key"=>"Environment", "Value"=>{"Ref"=>"EnvironmentName"}}, {"Key"=>"Locale", "Value"=>"AU"}])
      end
      
    end
    
  end

end