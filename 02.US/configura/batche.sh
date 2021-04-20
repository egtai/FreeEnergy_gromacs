#!/bin/bash

#批量执行job脚本,这里0时已经被测式执行来。从1开始
#给新生成的26个Job脚本赋予可执行的权限
chmod +x job*.sh

for num  in {0..26}

do

./job$num.sh

done 
