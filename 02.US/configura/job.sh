#!/bin/bash

# 设置一些环境变量，即你所有模拟配置文件所在的根目录（里面包括MDP，Methane,.sh脚本，在命令行使用pwd即可获得）
#/home/gaoyiyi/free_energy/04.US/configura1 即为我所有模拟配置文件所在根目录
FREE_ENERGY=/home/eric/free_energy/04.US/configura1
echo "Free energy home directory set to $FREE_ENERGY"

MDP=$FREE_ENERGY/MDP
echo ".mdp files are stored in $MDP"

#Wnum 为窗口数，将会被write_sh.sh进行批量替换成26个不同的值
WINDOW=Wnum

# 将为WINDOW的每个值和工作流程中的每个步骤创建一个新的目录，以实现最大限度的组织。

mkdir Window_$WINDOW
cd Window_$WINDOW

#################################
# 能量最小化第1步:STEEP  #
#################################
echo "Starting minimization for Window = $WINDOW..." 

mkdir EM_1 
cd EM_1

# Iterative calls to grompp and mdrun to run the simulations

gmx grompp -f $MDP/EM/1em$WINDOW.mdp -c $FREE_ENERGY/Methane/conf.gro -p $FREE_ENERGY/Methane/topol.top -n $FREE_ENERGY/Methane/index.ndx -o min$WINDOW.tpr -maxwarn 1 

gmx mdrun -nt 2 -v -deffnm min$WINDOW -pf pullf-min$WINDOW -px pullx-min$WINDOW

sleep 10

#################################
# 能量最小化第 2步: STEEP #
#################################

cd ../
mkdir EM_2
cd EM_2 

#我们在这里使用了 -maxwarn 1，因为 grompp 错误地抱怨使用了一个普通的截止值。
# 这是一个小问题，将在未来的Gromacs版本中得到修正。
gmx grompp -f $MDP/EM/2em$WINDOW.mdp -c ../EM_1/min$WINDOW.gro -p $FREE_ENERGY/Methane/topol.top -n $FREE_ENERGY/Methane/index.ndx -o min$WINDOW.tpr -maxwarn 1

gmx mdrun -nt 2 -v -deffnm min$WINDOW -pf pullf-min$WINDOW -px pullx-min$WINDOW

echo "Minimization complete."

sleep 10

#####################
# NVT 等容平衡 #
#####################
echo "Starting constant volume equilibration..."

cd ../
mkdir NVT
cd NVT

gmx grompp -f $MDP/NVT/nvt$WINDOW.mdp -c ../EM_2/min$WINDOW.gro -p $FREE_ENERGY/Methane/topol.top -n $FREE_ENERGY/Methane/index.ndx -o nvt$WINDOW.tpr  -maxwarn 1


gmx mdrun -nt 2 -v -deffnm nvt$WINDOW -pf pullf-nvt$WINDOW -px pullx-nvt$WINDOW


echo "Constant volume equilibration complete."

sleep 10

#####################
# NPT 等压平衡 #
#####################
echo "Starting constant pressure equilibration..."

cd ../
mkdir NPT
cd NPT

gmx grompp -f $MDP/NPT/npt$WINDOW.mdp -c ../NVT/nvt$WINDOW.gro -p $FREE_ENERGY/Methane/topol.top -n $FREE_ENERGY/Methane/index.ndx  -t ../NVT/nvt$WINDOW.cpt -o npt$WINDOW.tpr -maxwarn 1

gmx mdrun -nt 2 -v -deffnm npt$WINDOW -pf pullf-npt$WINDOW -px pullx-npt$WINDOW


echo "Constant pressure equilibration complete."

sleep 10

#################
# 成品模拟 MD #
#################
echo "Starting production MD simulation..."

cd ../
mkdir Production_MD
cd Production_MD

gmx grompp -f $MDP/PRD/prd$WINDOW.mdp -c ../NPT/npt$WINDOW.gro -p $FREE_ENERGY/Methane/topol.top -n $FREE_ENERGY/Methane/index.ndx  -t ../NPT/npt$WINDOW.cpt -o prd$WINDOW.tpr -maxwarn 1

gmx mdrun -nt 2 -v -deffnm prd$WINDOW -pf pullf-prd$WINDOW -px pullx-prd$WINDOW

echo "Production MD complete."

# End
echo "Ending. Job completed for Window= $WINDOW"
