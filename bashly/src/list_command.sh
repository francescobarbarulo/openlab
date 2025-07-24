TABLE="ENV,NAME"
for i in $(ls $PWD/terraform/terraform.tfstate.d)
do
  TMP=$(echo ${i} | rev | awk '{sub(/-/,":")}1' | rev)
  LAB_NAME=$(echo ${TMP} | cut -d ":" -f 1)
  ENV=$(echo ${TMP} | cut -d ":" -f 2)
  TABLE="${TABLE}\n${ENV},${LAB_NAME}"
done
(printf $TABLE | head -n 1 && printf $TABLE | tail -n +2 | sort) | column -t -s ','
