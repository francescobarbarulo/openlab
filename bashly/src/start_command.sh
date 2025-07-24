lab_name=${args[name]}
WORKSPACE="${lab_name}-${ENV}"

echo "Starting lab ${lab_name} in ${ENV} environment..."

cd $PWD/terraform
terraform workspace select ${WORKSPACE} &> /dev/null || (echo "Lab \"${lab_name}\" does not exist in ${ENV} environment" && exit 1)
terraform apply -auto-approve -var="env=${ENV}"
cd $PWD/..
