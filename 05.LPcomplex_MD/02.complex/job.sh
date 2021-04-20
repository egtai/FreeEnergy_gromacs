#!/bin/bash

# 设置一些环境变量 
# FREE_ENERGY=/home/justin/Free_Energy
FREE_ENERGY=/home/eric/free_energy/04.LP/02.complex
echo "Free energy home directory set to $FREE_ENERGY"

MDP=$FREE_ENERGY/MDP
echo ".mdp files are stored in $MDP"

#使用脚本替换Wnum值 0到29，共30个值
LAMBDA=Wnum

# 将为lambda的每个值和工作流程中的每个步骤创建一个新的目录，以实现最大限度的组织。

mkdir Lambda_$LAMBDA
cd Lambda_$LAMBDA

#################################
# 能量最小化
#################################
echo "Starting minimization for lambda = $LAMBDA..." 

mkdir EM 
cd EM

# Iterative calls to grompp and mdrun to run the simulations

gmx grompp -f $MDP/EM/enmin_$LAMBDA.mdp -c $FREE_ENERGY/Complex/complex.gro -p $FREE_ENERGY/Complex/complex.top -o min$LAMBDA.tpr

gmx mdrun -nt 2 -v -deffnm min$LAMBDA

sleep 10



#####################
# NVT 等容平衡 #
#####################
echo "Starting constant volume equilibration..."

cd ../
mkdir NVT
cd NVT

gmx grompp -f $MDP/NVT/nvt_$LAMBDA.mdp -c ../EM/min$LAMBDA.gro -p $FREE_ENERGY/Complex/complex.top -o nvt$LAMBDA.tpr  -maxwarn 1

gmx mdrun -nt 2 -v -deffnm nvt$LAMBDA

echo "Constant volume equilibration complete."

sleep 10

#####################
# NPT 等压平衡 #
#####################
echo "Starting constant pressure equilibration..."

cd ../
mkdir NPT
cd NPT

gmx grompp -f $MDP/NPT/npt_$LAMBDA.mdp -c ../NVT/nvt$LAMBDA.gro -p $FREE_ENERGY/Complex/complex.top -t ../NVT/nvt$LAMBDA.cpt -o npt$LAMBDA.tpr -maxwarn 1

gmx mdrun -nt 2 -v -deffnm npt$LAMBDA

echo "Constant pressure equilibration complete."

sleep 10

#################
# 成品模拟 MD #
#################
echo "Starting production MD simulation..."

cd ../
mkdir Production_MD
cd Production_MD

gmx grompp -f $MDP/PROD/prod_$LAMBDA.mdp -c ../NPT/npt$LAMBDA.gro -p $FREE_ENERGY/Complex/complex.top -t ../NPT/npt$LAMBDA.cpt -o md$LAMBDA.tpr -maxwarn 1

#-dhdl ----->dhdl.xvg
gmx mdrun -nt 2 -v -deffnm md$LAMBDA    -dhdl dhdl

echo "Production MD complete."

# End
echo "Ending. Job completed for lambda = $LAMBDA"
