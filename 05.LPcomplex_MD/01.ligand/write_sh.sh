#!/bin/bash

#对于模拟, 我们将使用shell脚本替换.job文件中的Wnum关键字

# 打开一个通用的job.sh文件，并替换Wnum的值

#20个窗口, 即Wnum有20个值，从0到19
for ((i=0;i<20;i++))
do
sed 's/Wnum/'$i'/g' $1.sh  >$1_$i.sh
done
