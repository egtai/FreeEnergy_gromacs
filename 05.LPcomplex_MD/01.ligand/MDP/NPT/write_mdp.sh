#!/bin/bash

#对于模拟, 我们将使用shell脚本替换.mdp文件中的nlambda关键字

# 打开一个通用的.mdp文件，并替换nlambda的值

#
for ((i=0;i<20;i++))
do
sed 's/nlambda/'$i'/g' $1.mdp  >$1_$i.mdp

done
