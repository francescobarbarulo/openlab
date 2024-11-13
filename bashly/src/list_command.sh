for i in $(ls $PWD/terraform/terraform.tfstate.d)
do 
  LAB_NAME=$(echo ${i} | cut -d "-" -f 1)
  ENV=$(echo ${i} | cut -d "-" -f 2)
  echo "${LAB_NAME} (${ENV})"
done
