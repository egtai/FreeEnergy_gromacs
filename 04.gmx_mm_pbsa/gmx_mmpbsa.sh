echo -e "\
>>>>>>>>>>>>>>>>   gmx_mmpbsa   <<<<<<<<<<<<<<<<
>>>>>>>>>>>>>>>>    Jicun Li    <<<<<<<<<<<<<<<<
>>>>>>>>>>     2020-11-15 10:11:59     <<<<<<<<<\n
>>   Usage: gmx_mmpbsa -f   *.xtc     -s   *.tpr      -n   *.ndx
                       -com COMPLEX   -pro PROTEIN   {-lig <LIGAND|none>}\n
>> Default: gmx_mmpbsa -f  traj.xtc   -s topol.tpr    -n index.ndx
                       -com Complex   -pro Protein    -lig Ligand
>> Option:
     f: trajectory file
     s: topology file
     n: index file
   com: index group name of complex
   pro: index group name of protein
   lig: index group name of ligand, can be ignored using none
   change other settings in the script directly
>> Log:
   TODO:       Opt before MM-PBSA
   TODO:       CAS
   TODO:       parallel APBS, focus
   2020-11-15: fix bug for resID >=1000, for awk 3.x gsub /\s/
   2020-06-02: fix bug of withLig
   2020-06-01: fix bug of -skip
   2020-05-27: fix bug for sdie
   2020-05-26: fix bug for RES name
   2020-04-03: use C6, C12 directly
   2020-01-08: support protein only
   2019-12-24: fix bug for small time step
   2019-12-10: fix bug for OPLS force field
   2019-11-17: fix bug for c6, c12 of old version tpr
   2019-11-06: apbs FILE.apbs &> FILE.out
               on ubuntu 18.04 may not work, then delete &
   2019-11-03: fix bug for time stamp
   2019-09-19: push to gmxtool
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n"

################################################################################
# �������л���, �������
# setting up environmets and parameters
################################################################################

trj=traj.xtc		# �켣�ļ� trajectory file
tpr=topol.tpr		# tpr�ļ�  tpr file
ndx=index.ndx		# �����ļ� index file

com=Complex			# ������������ index group name of complex
pro=Protein			# ����������   index group name of protein
lig=Ligand			# ����������   index group name of ligand

step=1	# �ӵڼ�����ʼ���� step number to run
		# 1. Ԥ����켣: ������������, �Ŵػ�, ���е���, Ȼ������pdb�ļ�
		#    pre-processe trajectory, whole, cluster, center, fit, then generate pdb file
		# 2. ��ȡÿ��ԭ�ӵĵ��, �뾶, LJ����, Ȼ������qrv�ļ�
		#    abstract atomic parameters, charge, radius, C6/C12, then generate qrv file
		# 3. MM-PBSA����: pdb->pqr, ���apbs, ����MM, APBS
		#    run MM-PBSA, pdb->pqr, apbs, then calculate MM, PB, SA

gmx='gmx'								# /path/to/GMX/bin/gmx_mpi
dump="$gmx dump"						# gmx dump
trjconv="$gmx trjconv -dt 1000"			# gmx trjconv, use -b -e -dt, NOT -skip

#apbs='/path/APBS/bin/apbs'				# APBS(Linux)
apbs='c:/apbs1.5/bin/apbs.exe'			# APBS(Windows), USE "/", NOT "\"
export MCSH_HOME=/dev/null				# APBS io.mc

pid=pid				# ����ļ�($$�����ظ�) prefix of the output files($$)
scr=_$pid.scr		# ��Ļ����ļ� file to save the message from the screen
qrv=_$pid.qrv		# ���/�뾶/VDW�����ļ� to save charge/radius/vdw parmeters

radType=1			# ԭ�Ӱ뾶���� radius of atoms (0:ff; 1:mBondi; 2:Bondi)
radLJ0=1.2			# ����LJ����ԭ�ӵ�Ĭ�ϰ뾶(A, ��ҪΪH) radius when LJ=0 (H)

meshType=0			# �����С mesh (0:global  1:local)
gridType=1			# ����С grid (0:GMXPBSA 1:psize)

cfac=3				# ���ӳߴ絽���Ը��ķŴ�ϵ��
					# Factor to expand mol-dim to get coarse grid dim
fadd=10				# ���ӳߴ絽ϸ�ܸ�������ֵ(A)
					# Amount added to mol-dim to get fine grid dim (A)
df=.5				# ϸ�ܸ����(A) The desired fine mesh spacing (A)

# ���Լ�������(Polar)
PBEset='
  temp  298.15      # �¶�
  pdie  2           # ���ʽ�糣��
  sdie  78.54       # �ܼ���糣��, ���1, ˮ78.54

  lpbe              # PB������ⷽ��, lpbe(����), npbe(������), smbpe(��С����)
  bcfl  mdh         # ���Ը��PB���̵ı߽�����, zero, sdh/mdh(single/multiple Debye-Huckel), focus, map
  srfm  smol        # �������ʺ����ӱ߽��ģ��, mol(���ӱ���), smol(ƽ�����ӱ���), spl2/4(��������/7�׶���ʽ)
  chgm  spl4        # ���ӳ�䵽���ķ���, spl0/2/4, �����Բ�ֵ, ����/�Ĵ�B������ɢ
  swin  0.3         # ���������Ĵ���ֵ, ������ srfm=spl2/4

  srad  1.4         # �ܼ�̽��뾶
  sdens 10          # �����ܶ�, ÿA^2�ĸ����, (srad=0)��(srfm=spl2/4)ʱ��ʹ��

  ion  1 0.15 0.95  # �����ӵĵ��, Ũ��, �뾶
  ion -1 0.15 1.81  # ������

  calcforce  no
  calcenergy comps'

# �Ǽ��Լ�������(Apolar/Non-polar)
PBAset='
  temp  298.15 # �¶�
  srfm  sacc   # �����ܼ���ر���������ģ��
  swin  0.3    # ������������(A), ���ڶ�����������

  # SASA
  srad  1.4    # ̽��뾶(A)
  gamma 1      # ��������(kJ/mol-A^2)

  #gamma const 0.027     0        # ��������, ����
  #gamma const 0.0226778 3.84928  # ��������, ����

  press  0     # ѹ��(kJ/mol-A^3)
  bconc  0     # �ܼ������ܶ�(A^3)
  sdens 10
  dpos  0.2
  grid  0.1 0.1 0.1

  # SAV
  #srad  1.29      # SAV̽��뾶(A)
  #press 0.234304  # ѹ��(kJ/mol-A^3)

  # WCA
  #srad   1.25           # ̽��뾶(A)
  #sdens  200            # ����ĸ���ܶ�(1/A)
  #dpos   0.05           # ����������ļ��㲽��
  #bconc  0.033428       # �ܼ������ܶ�(A^3)
  #grid   0.45 0.45 0.45 # �������ʱ�ĸ����(A)

  calcforce no
  calcenergy total'

################################################################################
# ��� gmx, apbs �Ƿ��������
# check gmx, apbs
################################################################################

str=$($gmx --version | grep -i "GROMACS version")
[[ -z "$str" ]] && { echo -e "!!! WARNING !!! GROMACS NOT available !\n"; }

str=$($apbs --version | grep -i "Poisson-Boltzmann")
[[ -z "$str" ]] && { echo -e "!!! WARNING !!!  APBS   NOT available !\n"; }

################################################################################
# ���������в���
# parse command line options
################################################################################

opt=($*); N=${#opt[@]}
for((i=0; i<N; i++)); do
	arg=${opt[$i]}; j=$((i+1)); val=${opt[$j]}
	[[ $arg =~ -f   ]] && { trj=$val; }
	[[ $arg =~ -s   ]] && { tpr=$val; }
	[[ $arg =~ -n   ]] && { ndx=$val; }
	[[ $arg =~ -com ]] && { com=$val; }
	[[ $arg =~ -pro ]] && { pro=$val; }
	[[ $arg =~ -lig ]] && { lig=$val; }
done

withLig=1; [[ $lig =~ none ]] && { withLig=0; com=$pro; lig=$pro; }

################################################################################
# ����ļ�
# check files
################################################################################

[[ ! -f "$trj" ]] && { echo -e "!!! ERROR !!! trajectory File NOT Exist !\n"; exit; }
[[ ! -f "$tpr" ]] && { echo -e "!!! ERROR !!! topology   File NOT Exist !\n"; exit; }
[[ ! -f "$ndx" ]] && { echo -e "!!! ERROR !!! index      File NOT Exist !\n"; exit; }
str=$(grep $com "$ndx"); [[ -z "$str" ]] && { echo -e "!!! ERROR !!! $com NOT in $ndx !\n"; exit; }
str=$(grep $pro "$ndx"); [[ -z "$str" ]] && { echo -e "!!! ERROR !!! $pro NOT in $ndx !\n"; exit; }
str=$(grep $lig "$ndx"); [[ -z "$str" && $withLig -eq 1 ]] && { echo -e "!!! ERROR !!! $lig NOT in $ndx !\n"; exit; }

if [[ $step -le 1 ]]; then
################################################################################
# 1. Ԥ����켣: ������������, �Ŵػ�, ���е���, Ȼ������pdb�ļ�
#    ����pdb�ļ�ȷ������PBC������ȷ
# 1. pre-processe trajectory, whole, cluster, center, fit, then generate pdb file
################################################################################
trjwho=$pid~who; trjcnt=$pid~cnt; trjcls=$pid~cls
echo $com            | $trjconv  -s $tpr -n $ndx -f $trj    -o $trjwho.xtc &> $scr -pbc whole
echo -e "$lig\n$com" | $trjconv  -s $tpr -n $ndx -f $trjwho -o _$pid.pdb   &>>$scr -pbc mol -center

# usful for single protein and ligand
#echo $com            | $trjconv  -s $tpr -n $ndx -f $trj    -o $trjwho.xtc &> $scr -pbc whole
#echo -e "$lig\n$com" | $trjconv  -s $tpr -n $ndx -f $trjwho -o $trjcnt.xtc &>>$scr -pbc mol -center
#echo -e "$com\n$com" | $trjconv  -s $tpr -n $ndx -f $trjcnt -o $trjcls.xtc &>>$scr -pbc cluster
#echo -e "$lig\n$com" | $trjconv  -s $tpr -n $ndx -f $trjcls -o _$pid.pdb   &>>$scr -fit rot+trans

fi; if [[ $step -le 2 ]]; then
################################################################################
# 2. ��ȡÿ��ԭ�ӵĵ��, �뾶, LJ����, Ȼ������qrv�ļ�
# 2. abstract atomic parameters, charge, radius, C6/C12, then generate qrv file
#    feel free to change radius with radType
#    radType=0: radius from C6/C12, or radLJ0 if either C6 or C12 is zero
#    radType=1: mBondi
#    radType=2: Bondi
################################################################################
$dump -quiet -s $tpr 2>>$scr \
| awk >$qrv -v ndx=$ndx -v pro=$pro -v lig=$lig -v withLig=$withLig \
			-v radType=$radType -v radLJ0=$radLJ0 '
	BEGIN { RS="["
		print pro, lig
		while(getline < ndx) {
			gsub(" ","", $1); gsub("\t","", $1)
			if($1==pro)    for(i=3; i<=NF; i++) ndxPro[$i+0]++
			if($1==pro"]") for(i=2; i<=NF; i++) ndxPro[$i+0]++
			if(withLig) {
				if($1==lig)    for(i=3; i<=NF; i++) ndxLig[$i+0]++
				if($1==lig"]") for(i=2; i<=NF; i++) ndxLig[$i+0]++
			}
		}
		RS="\r?\n"
		nres=0
	}

	/#molblock/  { Ntyp=$3 }
	/moltype.+=/ { Imol=$3; getline; Nmol[Imol]=$3 }
	/ffparams:/ {
		getline Atyp; sub(/.+=/, "", Atyp); Atyp += 0
		print Atyp
		getline
		for(i=0; i<Atyp; i++) {
			printf "%6d", i
			for(j=0; j<Atyp; j++) {
				getline
				C6 =$0; sub(".*c6 *= *",  "", C6);  sub(",.*", "", C6);
				C12=$0; sub(".*c12 *= *", "", C12); sub(",.*", "", C12);
				printf " %s %s", C6, C12
				if(j==i) {
					sigma[i]=0; epsilon[i]=0
					Rad[i]=radLJ0
					if(C6*C12!=0) {
						sigma[i]=10*(C12/C6)^(1./6) # ת����λΪA
						epsilon[i]=C6^2/(4*C12)
						Rad[i]=.5*sigma[i]          # sigmaΪֱ��
					}
				}
			}
			print ""
		}
	}

	/moltype.+\(/ { Imol=$0; gsub(/[^0-9]/,"",Imol)
		getline txt; sub(/.*=/,"",txt); gsub(" ","_",txt)
		Name[Imol]=txt
		getline; getline txt;       gsub(/[^0-9]/,"",txt); Natm[Imol]=txt+0
		for(i=0; i<Natm[Imol]; i++) {
			getline; txt=$0; idx=$3; resID[Imol, i]=$(NF-2)+1+nres
			sub(",", "", idx);    idx += 0;
			Catm[Imol, i]=idx
			Ratm[Imol, i]=Rad[idx]
			Satm[Imol, i]=sigma[idx]
			Eatm[Imol, i]=epsilon[idx]
			sub(/.+q=/, "", txt); sub(/,.+/,  "", txt); Qatm[Imol, i]=txt
		}
		getline
		for(i=0; i<Natm[Imol]; i++) {
			getline txt
			sub(/.+=./, "", txt); sub(/..$/, "", txt)
			Tatm[Imol, i]=txt
		}
	}

	/residue\[/ { nres++
		sub(/.*="/,"",$0); sub(/".*/,"",$0);
		resName[nres]=sprintf("%d%s", nres, $0)
	}

	END {
		Ntot=0; Nidx=0
		for(i=0; i<Ntyp; i++) {
			for(n=0; n<Nmol[i]; n++) {
				for(j=0; j<Natm[i]; j++) {
					Ntot++
					if(Ntot in ndxPro || Ntot in ndxLig) {
						Nidx++
						if(radType==0) radi=Ratm[i, j]
						if(radType >0) radi=getRadi(Tatm[i, j], radType)
						printf "%6d %9.5f %9.6f %6d %9.6f %9.6f %6d %s %s %-6s  ",  \
						Nidx, Qatm[i,j], radi, Catm[i,j], Satm[i,j], Eatm[i,j], \
						Ntot, Name[i]"-"n+1"."j+1, \
						resName[resID[i,j]], Tatm[i, j]
						if(Ntot in ndxPro) print "Pro"
						if(Ntot in ndxLig) print "Lig"
					}
				}
			}
		}
	}

	function getRadi(tag, radType) {
		radBondi["O" ]= 1.50; if(radType==2) radBondi["O" ]= 1.52
		radBondi["S" ]= 1.80; if(radType==2) radBondi["S" ]= 1.83
		radBondi["P" ]= 1.85; if(radType==2) radBondi["P" ]= 1.80
		radBondi["I" ]= 1.98; if(radType==2) radBondi["I" ]= 2.06
		radBondi["BR"]= 1.85; if(radType==2) radBondi["BR"]= 1.92
		radBondi["N" ]= 1.55
		radBondi["F" ]= 1.47
		radBondi["CL"]= 1.77

		radBondi["C" ]= 1.70; radBondi["H" ]= 1.20
		radBondi["C*"]= 1.77; radBondi["H4"]= 1.00
		radBondi["CA"]= 1.77; radBondi["H5"]= 1.00
		radBondi["CB"]= 1.77; radBondi["HA"]= 1.00
		radBondi["CC"]= 1.77; radBondi["HC"]= 1.30
		radBondi["CD"]= 1.77; radBondi["HN"]= 1.30
		radBondi["CN"]= 1.77; radBondi["HP"]= 1.30
		radBondi["CR"]= 1.77; radBondi["HO"]= 0.80
		radBondi["CV"]= 1.77; radBondi["HS"]= 0.80
		radBondi["CW"]= 1.77;

		tag=toupper(tag)
		if(length(tag)>=2) {
			if(!radBondi[substr(tag,1,2)]) return radBondi[substr(tag,1,1)]
			else return radBondi[substr(tag,1,2)]
		}
		return radBondi[tag]
	}
'

fi; if [[ $step -le 3 ]]; then
################################################################################
# 3. MM-PBSA����: pdb->pqr, ���apbs, ����MM, APBS
# 3. run MM-PBSA, pdb->pqr, apbs, then calculate MM, PB, SA
################################################################################
dt=$(awk '/t=/{n++;sub(/.*t=/,"");sub(/step=.*/,"");t[n]=$0;if(n==2){print t[n]-t[1];exit}}' _$pid.pdb)
awk -v pid=_$pid  -v qrv=$qrv -v apbs="$apbs" \
	-v ff=$ff     -v PBEset="$PBEset" -v PBAset="$PBAset" \
	-v meshType=$meshType -v gridType=$gridType -v gmem=$gmem  \
	-v fadd=$fadd -v cfac=$cfac -v df=$df -v dt="$dt"          \
	-v withLig=$withLig -v RS="\r?\n" '
	BEGIN {
		getline < qrv
		getline Atyp < qrv
		for(i=0; i<Atyp; i++) {
			getline < qrv
			for(j=0; j<Atyp; j++) { C6[i, j]=$(2+2*j); C12[i,j]=$(3+2*j) }
		}
		while(getline < qrv) {
			Qatm[$1]=$2; Ratm[$1]=$3; Catm[$1]=$4
			Satm[$1]=$5; Eatm[$1]=$6
			if($NF=="Pro") { Npro++; if(Npro==1) Ipro=$1
				ndxPro[$1]++; resPro[Npro]="P~"$(NF-2)
			}
			if($NF=="Lig") { Nlig++; if(Nlig==1) Ilig=$1
				ndxLig[$1]++; resLig[Nlig]="L~"$(NF-2)
			}
		}
		close(qrv)
		Ncom=Npro+Nlig

		PBEset0=PBEset; sub(/sdie +[0-9]*\.*[0-9]*/, "sdie  1", PBEset0)

		txt=PBEset; sub(/.*pdie +/, "", txt);
		sub(/\n.*/, "", txt); split(txt, arr)
		pdie=arr[1]

		txt=PBAset; sub(/.*#gamma +con[a-zA-Z]+/, "", txt);
		sub(/\n.*/, "", txt); split(txt, arr)
		gamma=arr[1]; const=arr[2]

		MAXPOS=1E9
		minX= MAXPOS; maxX=-MAXPOS;
		minY= MAXPOS; maxY=-MAXPOS;
		minZ= MAXPOS; maxZ=-MAXPOS

		fmt=sprintf("%.9f",dt/1E3)
		sub(/0*$/,"",fmt);sub(/.*\./,"",fmt)
		fmt="~%."length(fmt)"fns"
	}

	/REMARK/ {next}
	/TITLE/ {Fout=FILENAME
		txt=$0; sub(/.*t= */,"",txt); sub(/ .*/,"",txt)
		txt=sprintf(fmt, txt/1E3);
		sub(".pdb", txt, Fout)
		Nfrm++; n=0
		Fname[Nfrm]=Fout

		minXpro[Nfrm]= MAXPOS; minXlig[Nfrm]= MAXPOS;
		minYpro[Nfrm]= MAXPOS; minYlig[Nfrm]= MAXPOS;
		minZpro[Nfrm]= MAXPOS; minZlig[Nfrm]= MAXPOS

		maxXpro[Nfrm]=-MAXPOS; maxXlig[Nfrm]=-MAXPOS
		maxYpro[Nfrm]=-MAXPOS; maxYlig[Nfrm]=-MAXPOS
		maxZpro[Nfrm]=-MAXPOS; maxZlig[Nfrm]=-MAXPOS
	}
	/^ATOM/ {
		ATOM=substr($0,1,6)
		INDX=substr($0,7,5)+0
		NAME=substr($0,13,4)
		RES =substr($0,18,3)
		CHN =substr($0,22,1); if(CHN=" ") CHN="A"
		NUM =substr($0,23,4)
		X   =substr($0,31,8); X += 0
		Y   =substr($0,39,8); Y += 0
		Z   =substr($0,47,8); Z += 0
		r=Ratm[INDX]

		txt=sprintf("%-6s%5d %-4s %3s %s%4d    %8.3f %8.3f %8.3f %12.6f %12.6f", \
			ATOM, INDX, NAME, RES, CHN, NUM, X, Y, Z, Qatm[INDX], r)

		if(INDX in ndxPro) {
			print txt > Fout"_pro.pqr"
			minXpro[Nfrm]=min(minXpro[Nfrm], X-r); maxXpro[Nfrm]=max(maxXpro[Nfrm], X+r)
			minYpro[Nfrm]=min(minYpro[Nfrm], Y-r); maxYpro[Nfrm]=max(maxYpro[Nfrm], Y+r)
			minZpro[Nfrm]=min(minZpro[Nfrm], Z-r); maxZpro[Nfrm]=max(maxZpro[Nfrm], Z+r)
		}

		if(withLig) {
			print txt > Fout"_com.pqr"
			if(INDX in ndxLig) {
				print txt > Fout"_lig.pqr"
				minXlig[Nfrm]=min(minXlig[Nfrm], X-r); maxXlig[Nfrm]=max(maxXlig[Nfrm], X+r)
				minYlig[Nfrm]=min(minYlig[Nfrm], Y-r); maxYlig[Nfrm]=max(maxYlig[Nfrm], Y+r)
				minZlig[Nfrm]=min(minZlig[Nfrm], Z-r); maxZlig[Nfrm]=max(maxZlig[Nfrm], Z+r)
			}
		}

		minXcom[Nfrm]=min(minXpro[Nfrm], minXlig[Nfrm]); maxXcom[Nfrm]=max(maxXpro[Nfrm], maxXlig[Nfrm])
		minYcom[Nfrm]=min(minYpro[Nfrm], minYlig[Nfrm]); maxYcom[Nfrm]=max(maxYpro[Nfrm], maxYlig[Nfrm])
		minZcom[Nfrm]=min(minZpro[Nfrm], minZlig[Nfrm]); maxZcom[Nfrm]=max(maxZpro[Nfrm], maxZlig[Nfrm])

		minX=min(minX, minXcom[Nfrm]); maxX=max(maxX, maxXcom[Nfrm])
		minY=min(minY, minYcom[Nfrm]); maxY=max(maxY, maxYcom[Nfrm])
		minZ=min(minZ, minZcom[Nfrm]); maxZ=max(maxZ, maxZcom[Nfrm])

		next
	}

	END{
		kJcou=1389.35457520287
		Rcut=1E10              # large enough

		for(i=1; i<=Npro; i++) dE[resPro[i]]=0
		for(i=1; i<=Nlig; i++) dE[resLig[i]]=0
		Nres=asorti(dE, Tres)

		txt="   #Frame   "
		for(i=1; i<=Nres; i++) {
			ii=Tres[i]; sub(/~0+/, "~", ii)
			txt = txt""sprintf("%12s", ii)
		}
		if(withLig) {
			print txt > pid"~resMM.dat"
			print txt > pid"~resMM_COU.dat"
			print txt > pid"~resMM_VDW.dat"
			print txt > pid"~res_MMPBSA.dat"
		}
		print txt > pid"~resPBSA.dat"
		print txt > pid"~resPBSA_PB.dat"
		print txt > pid"~resPBSA_SA.dat"

		print "   #Frame      Binding    MM        PB        SA     "\
			 "|   COU       VDW     |       PBcom        PBpro        PBlig  "\
			 "|    SAcom     SApro     SAlig" >> pid"~MMPBSA.dat"

		for(fr=1; fr<=Nfrm; fr++) {
			Fout=Fname[fr]
			print "running for Frame "fr": "Fout

			txt=Fout"_pro.pqr"; if(withLig) txt=Fout"_com.pqr";
			close(txt)
			n=0;
			while(getline < txt) { n++;
				type[n]=$3; res[n]=$4;
				x[n]=$(NF-4);    y[n]=$(NF-3);   z[n]=$(NF-2)
				resID[n]=$(NF-5); gsub(/[A-Z]+/, "", resID[n])
			}
			close(txt)

			# MM
			if(withLig) {
				for(i=1; i<=Npro; i++) { dEcou[resPro[i]]=0; dEvdw[resPro[i]]=0 }
				for(i=1; i<=Nlig; i++) { dEcou[resLig[i]]=0; dEvdw[resLig[i]]=0 }
				for(i=1; i<=Npro; i++) {
					ii=i+Ipro-1
					qi=Qatm[ii]; ci=Catm[ii]; si=Satm[ii]; ei=Eatm[ii]
					xi=x[ii]; yi=y[ii]; zi=z[ii]
					for(j=1; j<=Nlig; j++) {
						jj=j+Ilig-1; cj=Catm[jj]
						r=sqrt( (xi-x[jj])^2+(yi-y[jj])^2+(zi-z[jj])^2 )
						if(r<Rcut) {
							t=1/(.1*r)^6
							Ecou = qi*Qatm[jj]/r
							Evdw = (C12[ci,cj]*t-C6[ci,cj])*t
							dEcou[resPro[i]] += Ecou; dEcou[resLig[j]] += Ecou
							dEvdw[resPro[i]] += Evdw; dEvdw[resLig[j]] += Evdw
						}
					}
				}

				Ecou=0; Evdw=0
				for(i in dEcou) {
					dEcou[i] *= kJcou/(2*pdie); Ecou += dEcou[i];
					dEvdw[i] /= 2;              Evdw += dEvdw[i]
				}
			}

			# PBSA
			if(withLig) print "read\n" \
				"  mol pqr "Fout"_com.pqr\n" \
				"  mol pqr "Fout"_pro.pqr\n" \
				"  mol pqr "Fout"_lig.pqr\n" \
				"end\n\n" > Fout".apbs"
			else        print "read\n" \
				"  mol pqr "Fout"_pro.pqr\n" \
				"end\n\n" > Fout".apbs"

			if(meshType==0) { # GMXPBSA
				if(withLig) print \
					dimAPBS(Fout"_com", 1, minX, maxX, minY, maxY, minZ, maxZ), \
					dimAPBS(Fout"_pro", 2, minX, maxX, minY, maxY, minZ, maxZ), \
					dimAPBS(Fout"_lig", 3, minX, maxX, minY, maxY, minZ, maxZ)  > Fout".apbs"
				else        print \
					dimAPBS(Fout"_pro", 1, minX, maxX, minY, maxY, minZ, maxZ)  > Fout".apbs"
			} else if(meshType==1) { # g_mmpbsa
				if(withLig) print \
					dimAPBS(Fout"_com", 1, minXcom[fr], maxXcom[fr], minYcom[fr], maxYcom[fr], minZcom[fr], maxZcom[fr]), \
					dimAPBS(Fout"_pro", 2, minXpro[fr], maxXpro[fr], minYpro[fr], maxYpro[fr], minZpro[fr], maxZpro[fr]), \
					dimAPBS(Fout"_lig", 3, minXlig[fr], maxXlig[fr], minYlig[fr], maxYlig[fr], minZlig[fr], maxZlig[fr])  > Fout".apbs"
				else       print \
					dimAPBS(Fout"_pro", 1, minXpro[fr], maxXpro[fr], minYpro[fr], maxYpro[fr], minZpro[fr], maxZpro[fr])  > Fout".apbs"
			}

			cmd=apbs" "Fout".apbs > "Fout".out 2>&1";
			system(cmd); close(cmd)

			txt=Fout".out";
			while(getline < txt ) {
				if(index($0, "CALCULATION #")) {
					if(index($0, "("Fout"_com")) { t=1; n=Ncom }
					if(index($0, "("Fout"_pro")) { t=2; n=Npro }
					if(index($0, "("Fout"_lig")) { t=3; n=Nlig }
					if(index($0, "~VAC)")) t += 10
					if(index($0, "~SAS)")) t += 20
					while(getline < txt) {
						if(t<20 && index($0, "Per-atom energies:") \
						|| t>20 && index($0, "Solvent Accessible Surface Area")) break
					}

					for(i=1; i<=n; i++) {
						getline <txt;
						if(t<20) r=$3; else r=$NF
						if(t<10)       Esol[t%10, i]=r
						else if(t<20)  Evac[t%10, i]=r
						else if(t<30)  Esas[t%10, i]=gamma*r+const/n
					}
				}
			}
			close(txt)

			PBcom=0; SAcom=0;
			PBpro=0; SApro=0;
			PBlig=0; SAlig=0;
			for(i=1; i<=Ncom; i++) { Esol[1,i] -= Evac[1,i]; PBcom += Esol[1,i]; SAcom += Esas[1,i] }
			for(i=1; i<=Npro; i++) { Esol[2,i] -= Evac[2,i]; PBpro += Esol[2,i]; SApro += Esas[2,i] }
			for(i=1; i<=Nlig; i++) { Esol[3,i] -= Evac[3,i]; PBlig += Esol[3,i]; SAlig += Esas[3,i] }

			for(i=1; i<=Npro; i++) { PBres[resPro[i]]=0; SAres[resPro[i]]=0 }
			for(i=1; i<=Nlig; i++) { PBres[resLig[i]]=0; SAres[resLig[i]]=0 }
			for(i=1; i<=Npro; i++) {
				PBres[resPro[i]] += Esol[1, Ipro+i-1]-Esol[2, i]
				SAres[resPro[i]] += Esas[1, Ipro+i-1]-Esas[2, i]
			}
			for(i=1; i<=Nlig; i++) {
				PBres[resLig[i]] += Esol[1, Ilig+i-1]-Esol[3, i]
				SAres[resLig[i]] += Esas[1, Ilig+i-1]-Esas[3, i]
			}

			preK=-1; if(withLig) preK=1
			printf "%-12s %9.3f %9.3f %9.3f %9.3f | %9.3f %9.3f | %12.3f %12.3f %12.3f | %9.3f %9.3f %9.3f\n", \
				Fout,       preK*(Ecou+Evdw+PBcom-PBpro-PBlig+SAcom-SApro-SAlig), \
				Ecou+Evdw,  preK*(PBcom-PBpro-PBlig), preK*(SAcom-SApro-SAlig), \
				Ecou, Evdw, PBcom, PBpro, PBlig, SAcom, SApro, SAlig >> pid"~MMPBSA.dat"

			fmt="%s%12.3f%s"
			for(i=1; i<=Nres; i++) {
				ii="";  if(i==1) ii=sprintf("%-12s", Fout)
				txt=""; if(i==Nres) txt="\n"
				if(withLig) {
					printf fmt, ii, dEcou[Tres[i]], txt                > pid"~resMM_COU.dat"
					printf fmt, ii, dEvdw[Tres[i]], txt                > pid"~resMM_VDW.dat"
					printf fmt, ii, dEcou[Tres[i]]+dEvdw[Tres[i]], txt > pid"~resMM.dat"
					printf fmt, ii, dEcou[Tres[i]]+dEvdw[Tres[i]] \
								   +PBres[Tres[i]]+SAres[Tres[i]], txt > pid"~res_MMPBSA.dat"
				}
				printf fmt, ii, preK*(PBres[Tres[i]]), txt                > pid"~resPBSA_PB.dat"
				printf fmt, ii, preK*(SAres[Tres[i]]), txt                > pid"~resPBSA_SA.dat"
				printf fmt, ii, preK*(PBres[Tres[i]]+SAres[Tres[i]]), txt > pid"~resPBSA.dat"
			}

			fmt="%s%6.1f%6.1f\n"
			for(i=1; i<=Npro; i++) {
				ii=Ipro+i-1
				txt=sprintf("%-6s%5d %-4s %3s A%4d    %8.3f%8.3f%8.3f", \
					"ATOM", ii, type[ii], res[ii], resID[ii], x[ii], y[ii], z[ii])
				if(withLig) {
					printf fmt, txt, dEcou[resPro[i]], dEvdw[resPro[i]] > Fout"~COU+VDW.pdb"
					printf fmt, txt, dEcou[resPro[i]]+dEvdw[resPro[i]], \
								 PBres[resPro[i]]+SAres[resPro[i]]  > Fout"~res_MM+PBSA.pdb"
				}
				printf fmt, txt, preK*PBres[resPro[i]], preK*SAres[resPro[i]] > Fout"~PB+SA.pdb"
				printf fmt, txt, 0, dEcou[resPro[i]]+dEvdw[resPro[i]]  \
								+preK*(PBres[resPro[i]]+SAres[resPro[i]])  > Fout"~res_MMPBSA.pdb"
			}
			for(i=1; i<=Nlig; i++) {
				ii=Ilig+i-1
				txt=sprintf("%-6s%5d %-4s %3s A%4d    %8.3f%8.3f%8.3f", \
					 "ATOM", ii, type[ii], res[ii], resID[ii], x[ii], y[ii], z[ii])
				printf fmt, txt, dEcou[resLig[i]], dEvdw[resLig[i]] > Fout"~COU+VDW.pdb"
				printf fmt, txt, PBres[resLig[i]], SAres[resLig[i]] > Fout"~PB+SA.pdb"
				printf fmt, txt, dEcou[resLig[i]]+dEvdw[resLig[i]], \
								 PBres[resLig[i]]+SAres[resLig[i]]  > Fout"~res_MM+PBSA.pdb"
				printf fmt, txt, 0, dEcou[resLig[i]]+dEvdw[resLig[i]]  \
								+PBres[resLig[i]]+SAres[resLig[i]]  > Fout"~res_MMPBSA.pdb"
			}
		}
	}

	function dimAPBS(file, Imol, minX, maxX, minY, maxY, minZ, maxZ) {

		lenX=max(maxX-minX, 0.1); cntX=(maxX+minX)/2
		lenY=max(maxY-minY, 0.1); cntY=(maxY+minY)/2
		lenZ=max(maxZ-minZ, 0.1); cntZ=(maxZ+minZ)/2
		cX  =lenX*cfac;           fX  =min(cX, lenX+fadd)
		cY  =lenY*cfac;           fY  =min(cY, lenY+fadd)
		cZ  =lenZ*cfac;           fZ  =min(cZ, lenZ+fadd)

		levN=4    # ���ּ���
		t=2^(levN+1)
		nX=round(fX/df)-1; nX=max(t*round(nX/t)+1, 33)
		nY=round(fY/df)-1; nY=max(t*round(nY/t)+1, 33)
		nZ=round(fZ/df)-1; nZ=max(t*round(nZ/t)+1, 33)

		if(gridType==0) { # GMXPBSA method
			fpre=1; cfac=1.7
			fX=lenX+2*fadd; cX=fX*cfac; nX=t*(int(fX/(t*df))+1+fpre)+1
			fY=lenY+2*fadd; cY=fY*cfac; nY=t*(int(fY/(t*df))+1+fpre)+1
			fZ=lenZ+2*fadd; cZ=fZ*cfac; nZ=t*(int(fZ/(t*df))+1+fpre)+1
		}

		MGset="mg-auto"
		mem = 200*nX*nY*nZ/1024./1024. # MB

#		npX=nX; npY=nY; npZ=nZ
#		gmem=4000
#		ofrac=0.1
#		if(mem>=gmem) {
#			while(mem>gmem) {
#				maxN=max(npX, max(npY, npZ))
#					 if(maxN==npX) npX = t*((npX-1)/t-1)+1
#				else if(maxN==npY) npY = t*((npY-1)/t-1)+1
#				else if(maxN==npZ) npZ = t*((npZ-1)/t-1)+1
#				mem = 200*npX*npY*npZ/1024./1024
#			}

#			t=nX/npX; if(t>1) npX = int(t*(1+2*ofrac) + 1.0);
#			t=nY/npY; if(t>1) npY = int(t*(1+2*ofrac) + 1.0);
#			t=nZ/npZ; if(t>1) npZ = int(t*(1+2*ofrac) + 1.0);
#			MGset="mg-para\n  ofrac "ofrac"\n  pdime "npX" "npY" "npZ
#		}

		XYZset="  "MGset \
			"\n  mol "Imol \
			"\n  dime   "nX"  "nY"  "nZ"        # �����Ŀ, �����ڴ�: "mem" MB"  \
			"\n  cglen  "cX"  "cY"  "cZ"        # ���Ը�㳤��" \
			"\n  fglen  "fX"  "fY"  "fZ"        # ϸ�ܸ�㳤��" \
			"\n  fgcent "cntX"  "cntY"  "cntZ"  # ϸ�ܸ������" \
			"\n  cgcent "cntX"  "cntY"  "cntZ"  # ���Ը������"

		return \
			"ELEC name "file"\n" \
			XYZset "\n" \
			PBEset "\n" \
			"end\n\n" \
			"ELEC name "file"~VAC\n" \
			XYZset  "\n" \
			PBEset0 "\n" \
			"end\n\n" \
			"APOLAR name "file"~SAS\n" \
			"  mol "Imol"\n" \
			PBAset"\n" \
			"end\n\n" \
			"print elecEnergy "file" - "file"~VAC end\n" \
			"print apolEnergy "file"~SAS end\n\n"
	}
	function min(x, y) { return x<y ? x : y }
	function max(x, y) { return x>y ? x : y }
	function round(x)  { return int(x+0.5)  }
' _$pid.pdb
fi

################################################################################
# 4. ɾ����ʱ�ļ�
# 4. remove intermediate files
################################################################################
#rm -f $trjwho.xtc $trjcnt.xtc $trjcls.xtc
#rm -f io.mc _$pid.pdb $scr $qrv \#_$pid*\#