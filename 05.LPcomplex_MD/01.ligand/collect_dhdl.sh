#!/bin/bash

#批量执行job脚本,这里0时已经被测式执行来。从1开始
mkdir analysis_FEP
cd analysis_FEP
for num  in {0..19}

do

cp ../Lambda_$num/Production_MD/dhdl.xvg ./dhdl$num.xvg  ./

done 
