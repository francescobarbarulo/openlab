for i in $(ls $PWD/terraform/terraform.tfstate.d)
do
  TMP=$(echo ${i} | rev | awk '{sub(/-/,":")}1' | rev)
  LAB_NAME=$(echo ${TMP} | cut -d ":" -f 1)
  ENV=$(echo ${TMP} | cut -d ":" -f 2)
  echo "${LAB_NAME} (${ENV})"
done
