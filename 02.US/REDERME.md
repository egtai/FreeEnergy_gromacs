**configura 文件下的目录结构**
├── batche.sh                   :批量执行job0.sh -->job26.sh 的脚本
├── write_mdp.sh                :批量生成mdp文件的脚本，主要修改mdp 中的pull-coord1-init=WINDOWS 的值，表现为替换WINDOWS关键字,值为0，1，2...26 
├── write_sh.sh                 :批量生成job文件的脚本,主要修改job文件中 WINDOW=Wnum的值，表现为替换Wnum关键字,值为0，1，2...26
├── job.sh                      :为每一窗口独立运行整个模拟过程（EM->NVT->NPT->PRD），即WINDOW0，WINDOW1，...WINDOW26
├── MDP                         :总运行参数mdp文件夹
│   ├── EM                      :能量最小化参数mdp文件夹
│   │   ├── 1em.mdp             :第1次能量最小化参数mdp文件
│   │   ├── 2em.mdp             :第2次能量最小化参数mdp文件
│   │   └── write_mdp.sh        : 用法：./write_mdp.sh  1em     即可后接mdp文件前缀    ./write_mdp.sh  2em
│   ├── NVT                     :等温等容预平衡参数mdp文件夹
│   │   ├── nvt.mdp             :等温等容预平衡参数mdp文件
│   │   ├── write_mdp.sh        : 用法：./write_mdp.sh  nvt     即可后接mdp文件前缀
│   ├── NPT                     :等温等压预平衡参数mdp文件夹
│   │   ├── npt.mdp             :等温等压预平衡参数mdp文件
│   │   └── write_mdp.sh        : 用法：./write_mdp.sh  npt     即可后接mdp文件前缀
│   └── PRD                     :成品模拟参数mdp文件夹
│       ├── prd.mdp             :成品模拟参数mdp文件
│       └── write_mdp.sh        : 用法：./write_mdp.sh  mdp     即可后接mdp文件前缀
├── Methane                     :结构文件和拓扑文件夹
│   ├── box.gro                 :10个甲烷盒子结构文件
│   ├── conf.gro                :模拟体系结构文件10个甲烷+水
│   ├── index.ndx               :甲烷中所有原子的索引文件
│   ├── methane.pdb             :甲烷结构文件
│   └── topol.top               :体系top文件
└── REDERME.md
---------------------------------------------------------
**生成以下文件后即可开始模拟**
.
├── batche.sh
├── write_mdp.sh
├── write_sh.sh  
├── job0.sh
├── job10.sh
├── job11.sh
├── job12.sh
├── job13.sh
├── job14.sh
├── job15.sh
├── job16.sh
├── job17.sh
├── job18.sh
├── job19.sh
├── job1.sh
├── job20.sh
├── job21.sh
├── job22.sh
├── job23.sh
├── job24.sh
├── job25.sh
├── job26.sh
├── job2.sh
├── job3.sh
├── job4.sh
├── job5.sh
├── job6.sh
├── job7.sh
├── job8.sh
├── job9.sh
├── job.sh
├── MDP
│   ├── EM
│   │   ├── 1em0.mdp
│   │   ├── 1em10.mdp
│   │   ├── 1em11.mdp
│   │   ├── 1em12.mdp
│   │   ├── 1em13.mdp
│   │   ├── 1em14.mdp
│   │   ├── 1em15.mdp
│   │   ├── 1em16.mdp
│   │   ├── 1em17.mdp
│   │   ├── 1em18.mdp
│   │   ├── 1em19.mdp
│   │   ├── 1em1.mdp
│   │   ├── 1em20.mdp
│   │   ├── 1em21.mdp
│   │   ├── 1em22.mdp
│   │   ├── 1em23.mdp
│   │   ├── 1em24.mdp
│   │   ├── 1em25.mdp
│   │   ├── 1em26.mdp
│   │   ├── 1em2.mdp
│   │   ├── 1em3.mdp
│   │   ├── 1em4.mdp
│   │   ├── 1em5.mdp
│   │   ├── 1em6.mdp
│   │   ├── 1em7.mdp
│   │   ├── 1em8.mdp
│   │   ├── 1em9.mdp
│   │   ├── 1em.mdp
│   │   ├── 2em0.mdp
│   │   ├── 2em10.mdp
│   │   ├── 2em11.mdp
│   │   ├── 2em12.mdp
│   │   ├── 2em13.mdp
│   │   ├── 2em14.mdp
│   │   ├── 2em15.mdp
│   │   ├── 2em16.mdp
│   │   ├── 2em17.mdp
│   │   ├── 2em18.mdp
│   │   ├── 2em19.mdp
│   │   ├── 2em1.mdp
│   │   ├── 2em20.mdp
│   │   ├── 2em21.mdp
│   │   ├── 2em22.mdp
│   │   ├── 2em23.mdp
│   │   ├── 2em24.mdp
│   │   ├── 2em25.mdp
│   │   ├── 2em26.mdp
│   │   ├── 2em2.mdp
│   │   ├── 2em3.mdp
│   │   ├── 2em4.mdp
│   │   ├── 2em5.mdp
│   │   ├── 2em6.mdp
│   │   ├── 2em7.mdp
│   │   ├── 2em8.mdp
│   │   ├── 2em9.mdp
│   │   ├── 2em.mdp
│   │   └── write_mdp.sh
│   ├── NPT
│   │   ├── npt0.mdp
│   │   ├── npt10.mdp
│   │   ├── npt11.mdp
│   │   ├── npt12.mdp
│   │   ├── npt13.mdp
│   │   ├── npt14.mdp
│   │   ├── npt15.mdp
│   │   ├── npt16.mdp
│   │   ├── npt17.mdp
│   │   ├── npt18.mdp
│   │   ├── npt19.mdp
│   │   ├── npt1.mdp
│   │   ├── npt20.mdp
│   │   ├── npt21.mdp
│   │   ├── npt22.mdp
│   │   ├── npt23.mdp
│   │   ├── npt24.mdp
│   │   ├── npt25.mdp
│   │   ├── npt26.mdp
│   │   ├── npt2.mdp
│   │   ├── npt3.mdp
│   │   ├── npt4.mdp
│   │   ├── npt5.mdp
│   │   ├── npt6.mdp
│   │   ├── npt7.mdp
│   │   ├── npt8.mdp
│   │   ├── npt9.mdp
│   │   ├── npt.mdp
│   │   └── write_mdp.sh
│   ├── NVT
│   │   ├── nvt0.mdp
│   │   ├── nvt10.mdp
│   │   ├── nvt11.mdp
│   │   ├── nvt12.mdp
│   │   ├── nvt13.mdp
│   │   ├── nvt14.mdp
│   │   ├── nvt15.mdp
│   │   ├── nvt16.mdp
│   │   ├── nvt17.mdp
│   │   ├── nvt18.mdp
│   │   ├── nvt19.mdp
│   │   ├── nvt1.mdp
│   │   ├── nvt20.mdp
│   │   ├── nvt21.mdp
│   │   ├── nvt22.mdp
│   │   ├── nvt23.mdp
│   │   ├── nvt24.mdp
│   │   ├── nvt25.mdp
│   │   ├── nvt26.mdp
│   │   ├── nvt2.mdp
│   │   ├── nvt3.mdp
│   │   ├── nvt4.mdp
│   │   ├── nvt5.mdp
│   │   ├── nvt6.mdp
│   │   ├── nvt7.mdp
│   │   ├── nvt8.mdp
│   │   ├── nvt9.mdp
│   │   ├── nvt.mdp
│   │   └── write_mdp.sh
│   └── PRD
│       ├── prd0.mdp
│       ├── prd10.mdp
│       ├── prd11.mdp
│       ├── prd12.mdp
│       ├── prd13.mdp
│       ├── prd14.mdp
│       ├── prd15.mdp
│       ├── prd16.mdp
│       ├── prd17.mdp
│       ├── prd18.mdp
│       ├── prd19.mdp
│       ├── prd1.mdp
│       ├── prd20.mdp
│       ├── prd21.mdp
│       ├── prd22.mdp
│       ├── prd23.mdp
│       ├── prd24.mdp
│       ├── prd25.mdp
│       ├── prd26.mdp
│       ├── prd2.mdp
│       ├── prd3.mdp
│       ├── prd4.mdp
│       ├── prd5.mdp
│       ├── prd6.mdp
│       ├── prd7.mdp
│       ├── prd8.mdp
│       ├── prd9.mdp
│       ├── prd.mdp
│       └── write_mdp.sh
├── Methane
│   ├── box.gro
│   ├── conf.gro
│   ├── index.ndx
│   ├── methane.pdb
│   └── topol.top
└── REDERME.md

