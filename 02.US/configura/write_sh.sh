#!/bin/bash

#对于模拟, 我们将使用shell脚本替换.job文件中的Wnum关键字

# 打开一个通用的job.sh文件，并替换Wnum的值

#26个窗口, 即Wnum有26个值，从0到26
for ((i=0;i<27;i++))
do
sed 's/Wnum/'$i'/g' $1.sh  >$1$i.sh
done
