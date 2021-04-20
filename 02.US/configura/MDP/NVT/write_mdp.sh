#!/bin/bash

#对于模拟, 我们将使用shell脚本替换.mdp文件中的WINDOW关键字

# 打开一个通用的.mdp文件，并替换以下值

#26个窗口, 距离从0.05 nm到大约1.3 nm.既WINDOW有26个值，增量为0.05
for ((i=0;i<27;i++))

do

# 小数点前补0
x=$(echo "0.05*$(($i+1))" | bc |awk '{printf "%.2f",$0}');


sed 's/WINDOW/'$x'/g' $1.mdp  >$1$i.mdp


done
