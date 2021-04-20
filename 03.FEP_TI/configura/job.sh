#!/bin/bash

# 设置一些环境变量 
# FREE_ENERGY=/home/justin/Free_Energy,以下部分需要根据你文件所在位置进行修改
FREE_ENERGY=/home/eric/free_energy/02.mbar
echo "Free energy home directory set to $FREE_ENERGY"

MDP=$FREE_ENERGY/MDP
echo ".mdp files are stored in $MDP"

#使用脚本替换Wnum值 0到20，共21个值
LAMBDA=Wnum

# 将为lambda的每个值和工作流程中的每个步骤创建一个新的目录，以实现最大限度的组织。

mkdir Lambda_$LAMBDA
cd Lambda_$LAMBDA

#################################
# 能量最小化第1步:STEEP  #
#################################
echo "Starting minimization for lambda = $LAMBDA..." 

mkdir EM_1 
cd EM_1

# Iterative calls to grompp and mdrun to run the simulations

gmx grompp -f $MDP/EM/em_steep_$LAMBDA.mdp -c $FREE_ENERGY/Methane/methane_water.gro -p $FREE_ENERGY/Methane/topol.top -o min$LAMBDA.tpr

gmx mdrun -nt 2 -v -deffnm min$LAMBDA

sleep 10

#################################
# 能量最小化第 2步: L-BFGS #
#################################

cd ../
mkdir EM_2
cd EM_2 

#我们在这里使用了 -maxwarn 1，因为 grompp 错误地抱怨使用了一个普通的截止值。
# 这是一个小问题，将在未来的Gromacs版本中得到修正。
gmx grompp -f $MDP/EM/em_l-bfgs_$LAMBDA.mdp -c ../EM_1/min$LAMBDA.gro -p $FREE_ENERGY/Methane/topol.top -o min$LAMBDA.tpr -maxwarn 1

# Run L-BFGS in serial (cannot be run in parallel)

gmx mdrun -nt 1 -v -deffnm min$LAMBDA

echo "Minimization complete."

sleep 10

#####################
# NVT 等容平衡 #
#####################
echo "Starting constant volume equilibration..."

cd ../
mkdir NVT
cd NVT

gmx grompp -f $MDP/NVT/nvt_$LAMBDA.mdp -c ../EM_2/min$LAMBDA.gro -p $FREE_ENERGY/Methane/topol.top -o nvt$LAMBDA.tpr  -maxwarn 1

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

gmx grompp -f $MDP/NPT/npt_$LAMBDA.mdp -c ../NVT/nvt$LAMBDA.gro -p $FREE_ENERGY/Methane/topol.top -t ../NVT/nvt$LAMBDA.cpt -o npt$LAMBDA.tpr -maxwarn 1

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

gmx grompp -f $MDP/Production_MD/md_$LAMBDA.mdp -c ../NPT/npt$LAMBDA.gro -p $FREE_ENERGY/Methane/topol.top -t ../NPT/npt$LAMBDA.cpt -o md$LAMBDA.tpr -maxwarn 1

#-dhdl ----->dhdl.xvg
gmx mdrun -nt 2 -v -deffnm md$LAMBDA    -dhdl dhdl

echo "Production MD complete."

# End
echo "Ending. Job completed for lambda = $LAMBDA"
