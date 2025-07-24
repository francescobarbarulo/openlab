LAB_NAME=${args[name]}
WORKSPACE="${LAB_NAME}-${ENV}"
TABLE="ENV,NAME,URL,STATUS"

cd $PWD/terraform
terraform workspace select ${WORKSPACE} &> /dev/null || (echo "Lab \"${LAB_NAME}\" does not exist in ${ENV} environment" && exit 1)
URL=$(terraform output -raw lab_url)
STATUS=$(terraform output -raw state)
cd $PWD/..
TABLE="${TABLE}\n${ENV},${LAB_NAME},${URL},${STATUS}"
printf $TABLE | column -t -s ','
