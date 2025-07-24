lab_name=${args[name]}
WORKSPACE="${lab_name}-${ENV}"

echo "Creating lab ${lab_name} in ${ENV} environment..."

cd $PWD/terraform
terraform workspace select ${WORKSPACE} &> /dev/null || terraform workspace new ${WORKSPACE} &> /dev/null
terraform apply -auto-approve -var="env=${ENV}"
LAB_URL=$(terraform output -json lab_url)
USERS=$(terraform output -json users)
INSTANCES=$(terraform output -json instances)
cd $PWD/..
ansible-playbook $PWD/ansible/playbook.yaml \
  --extra-vars "lab_name=${lab_name}" \
  --extra-vars "env=${ENV}" \
  --extra-vars "guacamole_url=${LAB_URL}" \
  --extra-vars "users=${USERS}" \
  --extra-vars "instances=${INSTANCES}"
