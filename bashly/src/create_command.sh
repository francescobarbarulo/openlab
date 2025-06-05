lab_name=${args[name]}
WORKSPACE="${lab_name}-${ENV}"

cd $PWD/terraform
terraform workspace select ${WORKSPACE} &> /dev/null || terraform workspace new ${WORKSPACE} &> /dev/null
terraform apply -auto-approve -var="env=${ENV}"
echo "guacamole_fqdn: $(terraform output hostname)" > $PWD/../ansible/vars.yaml
cd $PWD/..
mkdir -p $PWD/ansible/${lab_name}/${ENV}
ansible-playbook $PWD/ansible/playbook.yaml --extra-vars "lab_name=${lab_name} env=${ENV}"