lab_name=${args[name]}
WORKSPACE="${lab_name}-${ENV}"

echo "Stopping lab ${lab_name} in ${ENV} environment..."

cd $PWD/terraform
terraform workspace select ${WORKSPACE} &> /dev/null || (echo "Lab \"${lab_name}\" does not exist ${ENV} environment" && exit 1)
terraform apply -auto-approve -var="instance_state=stopped" -var="env=${ENV}"
cd $PWD/..
