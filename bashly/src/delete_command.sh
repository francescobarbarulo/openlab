lab_name=${args[name]}
WORKSPACE="${lab_name}-${ENV}"

echo "Deleting lab ${lab_name} in ${ENV} environment..."

cd $PWD/terraform
terraform workspace select ${WORKSPACE} &> /dev/null || (echo "Lab \"${lab_name}\" does not exist ${ENV} environment" && exit 1)
terraform destroy -auto-approve -var="env=${ENV}"
terraform workspace select default &> /dev/null && terraform workspace delete ${WORKSPACE} &> /dev/null
cd $PWD/..