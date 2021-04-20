#!/bin/bash

#批量执行job脚本,从0开始到19
chmod +x job*.sh
for num  in {0..19}

do

./job_$num.sh

done 
