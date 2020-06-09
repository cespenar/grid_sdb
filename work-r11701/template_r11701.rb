#!/usr/bin/env ruby

require 'mesa_script'
require 'fileutils'

###############################################################################

m = [[MASS]]
m_he_core = [[M_HE_CORE]]
z = [[Z]]
y = [[Y]]
model_name = "[[MODEL_NAME]]"
m_env = [[M_ENV]]
f_he = [[F_HE]]
mixing = "[[MIXING]]"

###############################################################################

rot = 0.0
f_shell = 0.0
mlt = 1.80 # alpha_mlt
sc = 0.1 # alpha_sc

eta_reimers = 0.0
eta_blocker = 0.0
dutch_eta = 0.0

levitation = false

m_sdb = m_he_core + m_env

if (m_env < 0.0005) then
	diff_min_dq = 1e-5
else
	diff_min_dq = 1e-9
end

if (mixing.eql? "cpm") then
	mesh_resolution = 0.2
	max_dt = 2.0e4
else
	mesh_resolution = 0.5
	max_dt = 5.0e5
end

###############################################################################


out_dir = "../logs"
Dir.mkdir(out_dir) unless File.exist?(out_dir)

history_dir = "../history"
Dir.mkdir(history_dir) unless File.exist?(history_dir)

###############################################################################

f = [0.0]
f.each do |f_h|

Inlist.make_inlist("inlist_temp") do
  #!-----------------------------STAR_JOB-------------------------------
  # &star_job
		
		load_saved_model true
		saved_model_name model_name

		set_initial_model_number true
		initial_model_number 0
		  
  		history_columns_file 'history_custom.list'
		profile_columns_file 'profile_custom.list'
		
		change_net true
		new_net_name 'pp_cno_extras_o18_ne22_fe56_ni58.net'

		eos_file_prefix 'mesa'
		kappa_file_prefix 'a09' # OP_a09_nans_removed_by_hand
		kappa_lowt_prefix 'lowT_fa05_a09p'
		kappa_co_prefix 'a09_co' # Type 2 opacities. OPAL only.
	
		set_rates_preference true
		new_rates_preference 2 # jina
		
		relax_mass true
		new_mass m_sdb
				
		set_tau_factor false
		set_to_this_tau_factor 1.0e-4

        if (rot > 0.0) then
		  new_rotation_flag true
		  change_rotation_flag true
		  set_surface_rotation_v true
        else
		  new_rotation_flag false
		  change_rotation_flag false
		  set_surface_rotation_v false
        end
		new_surface_rotation_v rot
	
		pgstar_flag false
		disable_pgstar_for_relax true

  # / !end of star_job

  #!-----------------------CONTROLS--------------------------------
  # &controls
 
	 # mixing parameters   
		mixing_length_alpha mlt
				
		use_Ledoux_criterion true
		alpha_semiconvection sc
			
		# core overshooting
        overshoot_f_above_burn_h_core f_h
        overshoot_f_above_burn_he_core f_he
        overshoot_f0_above_burn_h_core 0.002
        overshoot_f0_above_burn_he_core 0.002
  		
		recalc_mix_info_after_evolve true
		
		# CPM and Predictive Mixing
		if (mixing.eql? "cpm") then
			do_conv_premix true
			conv_premix_avoid_increase false
		end

		if (mixing.eql? "predictive") then
			predictive_mix[1] = true
			predictive_zone_type[1] = 'burn_He'
			predictive_zone_loc[1] = 'core'
			predictive_bdy_loc[1] = 'any'
			predictive_superad_thresh[1] = 0.05
			predictive_avoid_reversal[1] = 'he4'
			# predictive_limit_ingestion[1] = 'he4'
			# predictive_ingestion_factor[1] = 5.0
		end

	# rotation controls

		if (rot > 0.0) then
		  am_d_mix_factor 0.0228 # Brott et al. (2011), (0.033e0 - CZ92)
		else
		  am_d_mix_factor 0.0
		end
		am_nu_factor 1
		am_gradmu_factor 0.05e0
	
		d_dsi_factor 1.0
		d_sh_factor 1.0
		d_ssi_factor 1.0
		d_es_factor 1.0
		d_gsf_factor 1.0
		d_st_factor 0
		  
		smooth_d_dsi 3
		smooth_d_sh 3
		smooth_d_ssi 3
		smooth_d_es 3
		smooth_d_gsf 3
		smooth_d_st 3
		smooth_nu_st 3

	 # controls for output
		max_num_profile_models 10000
 
	 # starting specifications
		initial_mass m
		 
	 # output to files and terminal
		write_profiles_flag false
		profile_header_include_sys_details false
		photo_interval 500
		profile_interval 10
		history_interval 1
		terminal_interval 5
		write_header_frequency 10

		write_pulse_data_with_profile true
		pulse_data_format 'GYRE'
		add_atmosphere_to_pulse_data true
		add_center_point_to_pulse_data true
		keep_surface_point_for_pulse_data false
		
		# save osc with profile
		x_logical_ctrl[1] = false

	# mass gain or loss
		hot_wind_scheme 'Dutch'
		cool_wind_RGB_scheme 'Dutch'
		cool_wind_AGB_scheme 'Dutch'
		RGB_to_AGB_wind_switch 1.0e-4
		Dutch_scaling_factor dutch_eta
		Dutch_wind_lowT_scheme 'de Jager'
		max_wind 1e-3
 
	 # temporal resolution	
		varcontrol_target 1.0e-4
          		 
		# limit on magnitude of relative change at any grid point
        delta_lgteff_limit 0.01
        delta_lgteff_hard_limit 0.01
        
		max_years_for_timestep max_dt

  	  # spatial resolution
		max_allowed_nz 50000
        mesh_delta_coeff mesh_resolution
        
        mesh_logx_species[1] = 'h1'
        mesh_logx_min_for_extra[1] = -6
        mesh_dlogx_dlogp_extra[1] = 1.0 # 0.25
        
        mesh_logx_species[2] = 'he4'
        mesh_logx_min_for_extra[2] = -6
        mesh_dlogx_dlogp_extra[2] = 1.0 # 0.25
  	  
        mesh_logx_species[3] = 'c12'
        mesh_logx_min_for_extra[3] = -6
        mesh_dlogx_dlogp_extra[3] = 1.0 # 0.25
	
	 # solver controls
		use_gold_tolerances false
		warn_when_large_rel_run_E_err 1.0e99
		warn_when_stop_checking_residuals false

		use_eosDT2 true
		use_eosELM false
 
	 # atmosphere boundary conditions
		which_atm_option 'grey_and_kap'
	
	 # element diffusion
		do_element_diffusion false # controlled in run_star_extras
		diffusion_use_cgs_solver true
		diffusion_min_dq_at_surface diff_min_dq
		
		diffusion_use_full_net false

		diffusion_num_classes 11
		diffusion_class_representative[1] = 'h1'
		diffusion_class_representative[2] = 'he3'
		diffusion_class_representative[3] = 'he4'
		diffusion_class_representative[4] = 'c12'
		diffusion_class_representative[5] = 'n14'
		diffusion_class_representative[6] = 'o16'
		diffusion_class_representative[7] = 'ne20'
		diffusion_class_representative[8] = 'ne22'
		diffusion_class_representative[9] = 'mg24'
		diffusion_class_representative[10] = 'fe56'
		diffusion_class_representative[11] = 'ni58'
		diffusion_class_A_max[1]  = 2
		diffusion_class_A_max[2]  = 3
		diffusion_class_A_max[3]  = 4
		diffusion_class_A_max[4]  = 12
		diffusion_class_A_max[5]  = 14
		diffusion_class_A_max[6]  = 16
		diffusion_class_A_max[7]  = 20
		diffusion_class_A_max[8]  = 22
		diffusion_class_A_max[9]  = 24
		diffusion_class_A_max[10] = 56
		diffusion_class_A_max[11] = 58

        # radiation_turbulence_coeff 1.0
	
		if levitation then
			x_logical_ctrl[2] = true

			dH_div_H_limit_min_H 1e99 # disable this
			dHe_div_He_limit_min_He 1e99 # disable this
			
			# high_logT_op_mono_full_off 6.3e0 # set in run_star_extras
			# high_logT_op_mono_full_on 5.8e0 # set in run_star_extras

			diffusion_dt_limit 1

			diffusion_use_iben_macdonald false

			diffusion_min_dq_at_surface 1e-5
			diffusion_min_T_at_surface 1e4
			diffusion_min_dq_ratio_at_surface 4
			
			diffusion_AD_dm_full_on 1e-13 # Msun units
         	diffusion_AD_dm_full_off 2e-11 # Msun units
			diffusion_AD_boost_factor 20

			diffusion_Vlimit_dm_full_on 1e-13 # Msun units
			diffusion_Vlimit_dm_full_off 8e-12 # Msun units
			diffusion_Vlimit 1.5 # in units of local cell crossing velocity
			
			diffusion_v_max 1e-2

			diffusion_dt_div_timescale 1.0 # dt is at most this times the timescale

			diffusion_max_iters_per_substep 20
			diffusion_max_retries_per_substep 20

			diffusion_steps_limit 200
			diffusion_steps_hard_limit 400
			diffusion_iters_limit 500
			diffusion_iters_hard_limit 1000

			diffusion_tol_correction_max 3e-1
			diffusion_tol_correction_norm 3e-3
			diffusion_min_X_hard_limit -5e-3

			diffusion_upwind_abs_v_limit 1e-6

			diffusion_T_full_on 1e3
			diffusion_T_full_off 1e3

			diffusion_calculates_ionization true
			diffusion_nsmooth_typical_charge 10

			diffusion_max_T_for_radaccel 1e7
			diffusion_screening_for_radaccel true

			op_mono_min_X_to_include 1e-10 # skip iso if mass fraction < this
			use_op_mono_alt_get_kap false

			diffusion_use_isolve true
			diffusion_rtol_for_isolve 1e-4
			diffusion_atol_for_isolve 1e-5
			diffusion_maxsteps_for_isolve 1000
			diffusion_isolve_solver 'ros2_solver'
		else
			x_logical_ctrl[2] = false
		end

	 # opacity controls   
		use_type2_opacities true
        zbase z
        
  # / ! end of controls namelist

  #!-------------------------PGSTAR-------------------------------------
  # &pgstar

  # / ! end of pgstar namelist
end

system './mk'
system './rn'

print "m_sdB = ", m_sdb, "\n"

###############################################################################

name_string = "mi" + m.to_s + "_mhec" + m_he_core.to_s +
	"_menv" + m_env.to_s +
	"_z" + z.to_s + "_y" + "#{y.round(5)}" +
	"_fhe" + f_he.to_s + "_" + mixing

# # system 'module load python/3.6.2-gcc6.2.0' # GYRE
# # system 'source $MESASDK_ROOT/bin/mesasdk_init.sh' # GYRE

# # gyre_dir = "../gyre" # GYRE
# # FileUtils.cp Dir.glob(gyre_dir + "/*"), "LOGS/" # GYRE
# Dir.chdir("LOGS")
# # system 'python3 run_gyre.py -w . -i gyre.in -p "custom_He*.GYRE"' # GYRE

# zip_name = "logs_" + name_string + ".zip"
# zip_command = "zip -rX " + zip_name + " *"
# system zip_command

# Dir.chdir("../")

# FileUtils.cp "LOGS/" + zip_name, out_dir + "/"

logs = out_dir + "/" + "logs_" + name_string
Dir.mkdir(logs) unless File.exist?(logs)
FileUtils.mv Dir.glob('LOGS/*'), logs + "/"
FileUtils.cp "gyre.in", logs + "/"
FileUtils.cp "run_gyre.py", logs + "/"
FileUtils.cp "run_gyre.sh", logs + "/g_" + name_string + ".sh"

system './tidy'

end
