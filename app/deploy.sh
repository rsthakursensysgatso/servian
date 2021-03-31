lcfg1="APP-LC"
lcfg2="APP-LC-2"

lc=`aws autoscaling describe-launch-configurations --region us-east-1|grep LaunchConfigurationName|awk '{print $2}'|cut -d '"' -f2`

if [[ "$lc" == "$lcfg1" ]]
then
	cd lc2
	vpc=`aws ec2 describe-vpcs --filters Name=tag:Name,Values='WP Solution VPC' --query 'Vpcs[*].VpcId' --output text`
	sg=aws ec2  describe-security-groups --filter Name=vpc-id,Values=$vpc  Name=group-name,Values=app_asg --region us-east-1 --query 'SecurityGroups[*].[GroupId]' --output text	
	sed -i "s/sgid/$sg/g" lc.tf
	terraform init
	terraform apply --auto-approve  
	aws autoscaling update-auto-scaling-group --auto-scaling-group-name APP-ASG --launch-configuration-name $lcfg2 --min-size 4 --max-size 4
	sleep 150
	aws autoscaling delete-launch-configuration --launch-configuration-name $lcfg1
	aws autoscaling update-auto-scaling-group --auto-scaling-group-name APP-ASG --launch-configuration-name $lcfg2 --min-size 2 --max-size 2

elif [[ "$lc" == "$lcfg2" ]]
then
	cd lc1
	vpc=`aws ec2 describe-vpcs --filters Name=tag:Name,Values='WP Solution VPC' --query 'Vpcs[*].VpcId' --output text`
	sg=aws ec2  describe-security-groups --filter Name=vpc-id,Values=$vpc  Name=group-name,Values=app_asg --region us-east-1 --query 'SecurityGroups[*].[GroupId]' --output text	
	sed -i "s/sgid/$sg/g" lc.tf	
	terraform init
	terraform apply --auto-approve  
	aws autoscaling update-auto-scaling-group --auto-scaling-group-name APP-ASG --launch-configuration-name $lcfg1 1 --min-size 4 --max-size 4
	sleep 150
	aws autoscaling delete-launch-configuration --launch-configuration-name $lcfg2
	aws autoscaling update-auto-scaling-group --auto-scaling-group-name APP-ASG --launch-configuration-name $lcfg1 --min-size 2 --max-size 2
	
else
	terraform init
	terraform plan
	terraform apply --auto-approve  
fi
