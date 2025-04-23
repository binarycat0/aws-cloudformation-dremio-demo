PROFILE ?=us-west-2
STACK_NAME ?= dremio
ECS_CLUSTER_NAME ?= $(STACK_NAME)-ec2-asg

create-iam:
	aws --profile $(PROFILE) cloudformation deploy --template-file iam.yaml --stack-name $(STACK_NAME)-iam --capabilities CAPABILITY_NAMED_IAM

create-vpc:
	aws --profile $(PROFILE) cloudformation deploy --template-file vpc.yaml --stack-name $(STACK_NAME)-vpc --capabilities CAPABILITY_NAMED_IAM

create-efs:
	aws --profile $(PROFILE) cloudformation deploy --template-file efs.yaml --stack-name $(STACK_NAME)-efs

create-rds:
	aws --profile $(PROFILE) cloudformation deploy --template-file rds.yaml --stack-name $(STACK_NAME)-rds

create-ec2:
	aws --profile $(PROFILE) cloudformation deploy --template-file ec2_asg.yaml --stack-name $(STACK_NAME)-ec2 --capabilities CAPABILITY_NAMED_IAM \
	  --parameter-overrides ECSClusterName=$(ECS_CLUSTER_NAME)

create-ecs:
	aws --profile $(PROFILE) cloudformation deploy --template-file ecs.yaml --stack-name $(STACK_NAME)-ecs --capabilities CAPABILITY_NAMED_IAM \
	  --parameter-overrides ECSClusterName=$(ECS_CLUSTER_NAME)

destroy-iam:
	aws --profile $(PROFILE) cloudformation delete-stack --stack-name $(STACK_NAME)-iam

destroy-ecs:
	aws --profile $(PROFILE) cloudformation delete-stack --stack-name $(STACK_NAME)-ecs

destroy-ec2:
	aws --profile $(PROFILE) cloudformation delete-stack --stack-name $(STACK_NAME)-ec2

destroy-efs:
	aws --profile $(PROFILE) cloudformation delete-stack --stack-name $(STACK_NAME)-efs

destroy-rds:
	aws --profile $(PROFILE) cloudformation delete-stack --stack-name $(STACK_NAME)-rds

destroy-vpc:
	aws --profile $(PROFILE) cloudformation delete-stack --stack-name $(STACK_NAME)-vpc

destroy: destroy-ecs destroy-iam destroy-ec2 destroy-efs destroy-rds destroy-vpc

status-ec2_asg:
	@aws --profile $(PROFILE) cloudformation describe-stacks --stack-name $(STACK_NAME)-ec2 --query "Stacks[0].Outputs[?OutputKey=='$(ECS_CLUSTER_NAME)'].OutputValue" --output text

status:
	@for stack in vpc efs rds iam ecs; do \
	  echo "Status of $(STACK_NAME)-$$stack:"; \
	  aws --profile $(PROFILE) cloudformation describe-stacks --stack-name $(STACK_NAME)-$$stack --query "Stacks[0].StackStatus" --output text || echo "Not found"; \
	done

outputs:
	@for stack in vpc efs rds iam ecs; do \
	  echo "Outputs from $(STACK_NAME)-$$stack:"; \
	  aws --profile $(PROFILE) cloudformation describe-stacks --stack-name $(STACK_NAME)-$$stack --query "Stacks[0].Outputs" --output table || echo "No outputs"; \
	done

all: create-vpc create-efs create-rds create-iam create-ec2 create-ecs