lab_name=${args[name]}
WORKSPACE="${lab_name}-${ENV}"

cd $PWD/terraform
terraform workspace select ${WORKSPACE} &> /dev/null || (echo "Lab \"${lab_name}\" does not exist" && exit 1)
echo "$(terraform output -raw lab_url) ($(terraform output -raw state))"
cd $PWD/..
