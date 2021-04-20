#!/bin/bash
#创建保存分析需要用的prd0.tpr 到prd26.tpr 和 pullf-prd0.xvg 到pullf-prd26.xvg文件的文件夹 analysis_us  
mkdir analysis_us
cd analysis_us

for num  in {0..26}

do

cp ../Window_$num/Production_MD/prd$num.tpr ./
cp ../Window_$num/Production_MD/pullf-prd$num.xvg ./

done 
