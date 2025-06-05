# IaC for labs on AWS

## Lab infrastructure

## Prerequisites

## Generate cli

```sh
alias bashly='docker run --rm -it --user $(id -u):$(id -g) --volume "$PWD:/app" dannyben/bashly'
cd bashly && bashly generate && cd ..
sudo ln lab /usr/local/bin/lab
```
