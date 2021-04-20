
configura文件：模拟使用的gromacs5.1.4版本 

configura文件：模拟使用的gromacs5.1.4版本 
├── methane.pdb        :甲烷结构文件
├── box.gro            :步骤1生成的文件
├── conf.gro           :步骤2生成的文件
├── min1.mdp           :第一次能量最小化
├── min2.mdp           :第二次能量最小化
├── eql.mdp            :NVT 预平衡 
├── eql2.mdp           :NPT 预平衡
├── prd.mdp            :成品模拟，这里注意你可以改一下时长，我自己仅跑了5ns用于展示，建议跑100ns,rdf更平滑
├── topol.top          :拓扑文件，包含10个甲烷和1000个水分子
└── run_pmf.bsh        :自动化执行分子模拟流程的脚本