#!/bin/bash
#
# This script will generate Young's modulus LAMMPS input scripts for polymerized PCFF systems.


sim_data_files=("Polymer_ANEqPlyANEq_R1_M.dat.gz")

dir_array=("1" "2" "3")
for sim in ${sim_data_files[@]}
do
# uncomment the following line if you use line 7 to find all of the systems you want to test (useful if you run many different replicates all with similar filenames)
#    sim=${sim:2}
   for dir in ${dir_array[@]}
   do
input_script=${sim: 0: 22}YM${dir}
# Begin writing Young's mod script
cat <<EOM >${input_script}.in
# This script will strain the system in the ${dir}-direction until 20% strain at 300 K and 1.0 atm.

##########################
### Simulation history ###
##########################

#################################
### Initialization & Settings ###
#################################

# Debugging
echo screen

units 		real
dimension	3
boundary	p p p

variable myid string ${input_script}
variable data string ${sim}
log \${myid}.log.lammps

timestep        1 #fs
variable strain equal 0.221402758160 # engineering strain, 20% true strain. e_true = ln(e_eng + 1)
variable strain_rate_s equal 2e8 #in 1/s # This is a standard strain rate for MD. 

variable dir equal ${dir}
# dir 1 means x
# dir 2 means y
# dir 3 means z
##############################
### Force Field Parameters ###
##############################

atom_style	full
bond_style hybrid class2 morse
angle_style class2
dihedral_style class2
improper_style class2
special_bonds lj/coul 0 0 1
pair_style lj/class2/coul/long 10.0
pair_modify mix sixthpower
kspace_style pppm 1e-6
read_data       \${data}

# Include IFF-R bond coefficients
include Polymer_IFFR_Corrected.coeff

variable        strain_rate_fs equal \${strain_rate_s}*1e-15 # in 1/fs
variable        totaltime equal \${strain}/\${strain_rate_fs} # total time in femtoseconds
variable        steps equal \$(round(v_totaltime/dt))
variable        runs equal 200
variable        run_steps equal \$(floor(v_steps/v_runs))
variable        eeng equal time*\${strain_rate_fs}
variable        etrue equal ln(1+v_eeng)

variable thermo_freq equal \$(round(v_steps/2000))
variable dump_freq equal \$(round(v_steps/30))

##############################
########### Strains ##########
##############################

variable	tmp equal lx
variable	lx0 equal \${tmp}
variable    tmp equal ly
variable    ly0 equal \${tmp}
variable    tmp equal lz
variable    lz0 equal \${tmp}

variable	eengx equal (lx-\${lx0})/\${lx0}
variable	eengy equal (ly-\${ly0})/\${ly0}
variable	eengz equal (lz-\${lz0})/\${lz0}
variable    etruex equal ln(1+v_eengx)
variable    etruey equal ln(1+v_eengy)
variable    etruez equal ln(1+v_eengz)


##############################
########## Stresses ##########
##############################

compute         p all pressure thermo_temp
variable        sxx equal -0.101325*c_p[1] #in MPa
variable        syy equal -0.101325*c_p[2] #in MPa
variable        szz equal -0.101325*c_p[3] #in MPa
fix             sxx_ave all ave/time 1 \${thermo_freq} \${thermo_freq} v_sxx
fix             syy_ave all ave/time 1 \${thermo_freq} \${thermo_freq} v_syy
fix             szz_ave all ave/time 1 \${thermo_freq} \${thermo_freq} v_szz

##############################
### Thermo & Dump Settings ###
##############################

thermo \${thermo_freq}
thermo_style custom step temp press etotal ke pe epair ebond eangle edihed eimp elong lx ly lz pxx pyy pzz v_etrue v_eengx v_eengy v_eengz v_etruex v_etruey v_etruez v_sxx v_syy v_szz f_sxx_ave f_syy_ave f_szz_ave vol density v_dir

dump 1 all custom/gz \${dump_freq} \${myid}.lammpstrj.gz x y z type id 


####################
### Run Settings ###
####################
neigh_modify    delay 0 every 1 check yes one 2500 page 100000
fix balance all balance \${run_steps} 1.05 shift xyz 20 1.05
if "\${dir} == 1" then &
  "fix          1 all npt temp 300 300 100 y 1 1 1000 z 1 1 1000" &
  "fix          2 all deform 1 x erate \${strain_rate_fs}"
if "\${dir} == 2" then &
  "fix          1 all npt temp 300 300 100 x 1 1 1000 z 1 1 1000" &
  "fix          2 all deform 1 y erate \${strain_rate_fs}"
if "\${dir} == 3" then &
  "fix          1 all npt temp 300 300 100 x 1 1 1000 y 1 1 1000" &
  "fix          2 all deform 1 z erate \${strain_rate_fs}"
# Breaking up the runs resets the pppm grid points which increases accuracy when box size changes
label deform_loop
variable deform loop \$(v_runs)
run   \${run_steps} start 0 stop \$(v_run_steps*v_runs)
next deform
jump SELF deform_loop
write_data \${myid}.dat
shell pigz \${myid}.dat
EOM
      echo "${input_script}.in created!"
      # 
      /qlammps.sh -c 192 -n 1 -w 24:00:00 -q standard -f ${input_script}.in -s
      

   done
done
