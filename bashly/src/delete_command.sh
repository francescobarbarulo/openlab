lab_name=${args[name]}
WORKSPACE="${lab_name}-${ENV}"

cd $PWD/terraform
terraform workspace select ${WORKSPACE} &> /dev/null || (echo "Lab \"${lab_name}\" does not exist" && exit 1)
terraform destroy -auto-approve -var="env=${ENV}"
terraform workspace select default &> /dev/null && terraform workspace delete ${WORKSPACE} &> /dev/null
cd $PWD/..
rm -rf $PWD/ansible/${lab_name}/${ENV}
if [ -z "$(ls -A $PWD/ansible/${lab_name})" ]; then rmdir $PWD/ansible/${lab_name}; fi