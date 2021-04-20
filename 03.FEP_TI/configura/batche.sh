#!/bin/bash

#批量执行job脚本,从0开始

for num  in {0..20}

do

./job_$num.sh

done 
