# TODO: Elastic energy should be T*E^e not sigma*eps^e for finte strain? NOW IT'S T*E for Sn and sigma*eps for the rest
# TODO: Not sure if plastic energy is correctly calculated
# TODO: Check how eigenstrain is applied in finite strains: Eigenstrain are subtracted from strain increment, maybe should use F=F^eF^* as in plasticity?
# TODO: ComputeFiniteStrain does not compute Green-Lagrange strain.
[Mesh]
  type = GeneratedMesh
  dim = 3
  elem_type = HEX8
  nx = 10
  ny = 10
  nz = 1
  xmin = 0
  xmax = 400
  ymin = 0
  ymax = 400
  zmin = 0
  zmax = 10
  displacements = 'disp_x disp_y disp_z'
  uniform_refine = 2 # Initial uniform refinement of the mesh
  skip_partitioning = true
[]
[GlobalParams]
  # CahnHilliard needs the third derivatives
  derivative_order = 3
  #enable_jit = true
  displacements = 'disp_x disp_y disp_z'
[]
[Variables]
  [./disp_x]
    #scaling = 1e-1
  [../]
  [./disp_y]
    #scaling = 1e-1
  [../]
  [./disp_z]
    #scaling = 1e-1
  [../]

  [./c]
    scaling = 1e1
  [../]
  # chemical potential
  [./w]
    scaling = 1e1
    #initial_condition = -0.7405
  [../]

  [./eta0]
    scaling = 1e1
  [../]
  [./eta1]
    #initial_condition = 1
    scaling = 1e1
  [../]
  [./eta2]
    initial_condition = 0
    scaling = 1e1
  [../]

  [./c0]
    initial_condition = 0.02
    #initial_condition = 0.1617
    scaling = 1e1
  [../]
  [./c1]
    initial_condition = 0.9745
    scaling = 1e1
  [../]
  [./c2]
    initial_condition = 0.4350
    scaling = 1e1
  [../]
[]

[ICs]
  [./eta0]
    #type = FunctionIC
    type = SmoothCircleIC
    variable = eta0
    radius = 200
    int_width = 60
    invalue = 1
    outvalue = 0
    x1 = 0
    y1 = 0
    z1 = 0
    #function = 'if(y<=0,1,0)'
    #function = '1-0.5*(1+tanh(y/100))' #close to equlibrium shape
    #function = '1-0.5*(1+tanh(y/40))' #close to equlibrium shape
  [../]
  [./eta1]
    type = UnitySubVarIC
    variable = eta1
    etas = eta0
  [../]
  [./c] #Concentration of Sn
    type = VarDepIC
    variable = c
    cis = 'c0 c1 c2'
    etas = 'eta0 eta1 eta2'
  [../]
  [./w]
    #type = FunctionIC
    type = SmoothCircleIC
    variable = w
    radius = 200
    int_width = 60
    invalue = -16.4486
    outvalue = -0.74034
    x1 = 0
    y1 = 0
    z1 = 0
    #function = 'if(y<=0,1,0)'
    #function = '1-0.5*(1+tanh(y/100))' #close to equlibrium shape
    #function = '1-0.5*(1+tanh(y/40))' #close to equlibrium shape
  [../]
[]

[BCs]
  [./Periodic]
    [./z]
      auto_direction = 'z'
      variable = 'eta0 eta1 eta2 c w c0 c1 c2'
    [../]
  [../]

  [./symmy]
    type = PresetBC
    variable = disp_y
    boundary = 'bottom'
    value = 0
  [../]
  [./symmx]
    type = PresetBC
    variable = disp_x
    boundary = 'left right'
    value = 0
  [../]
  [./symmz]
    type = PresetBC
    variable = disp_z
    boundary = 'front back'
    value = 0
  [../]
[]
[UserObjects]
  [./slip_rate_gss1]
    type = CrystalPlasticitySlipRateGSSBaseName
    variable_size = 32
    slip_sys_file_name = slip_systems_bct.txt
    num_slip_sys_flowrate_props = 2
    #flowprops = '1 4 0.001 0.1 5 8 0.001 0.1 9 12 0.001 0.1' #start_ss end_ss gamma0 1/m
    flowprops = '1 32 0.001 0.05' #start_ss end_ss gamma0 1/m
    uo_state_var_name = state_var_gss1
    base_name = 'eta1'
  [../]
  [./slip_resistance_gss1]
    type = CrystalPlasticitySlipResistanceGSS
    variable_size = 32
    uo_state_var_name = state_var_gss1
  [../]
  [./state_var_gss1]
    type = CrystalPlasticityStateVariable
    variable_size = 32
    groups = '0 32'
    group_values = '0.144' # 23 MPa in eV/nm^3 initial values of slip resistance
    uo_state_var_evol_rate_comp_name = state_var_evol_rate_comp_gss1
    scale_factor = 1.0
  [../]
  [./state_var_evol_rate_comp_gss1]
    type = CrystalPlasticityStateVarRateComponentGSS
    variable_size = 32
    #hprops = '1.4 100 40 2' #qab h0 ss c see eq (9) in Zhao 2017, values from Darbandi 2013 table V
    hprops = '1.4 0.624 0.250 2' #qab h0 ss c see eq (9) in Zhao 2017, values from Darbandi 2013 table V
    uo_slip_rate_name = slip_rate_gss1
    uo_state_var_name = state_var_gss1
  [../]
[]

[Materials]
  [./time]
    type = TimeStepMaterial
    prop_time = time
    prop_dt = dt
    use_displaced_mesh = true
  [../]
  # Cu
  [./elasticity_tensor_cu]
    type = ComputeIsotropicElasticityTensor
    youngs_modulus = 936. #150 GPa in eV/nm^3
    poissons_ratio = 0.35
    base_name = eta0
  [../]
  [./strain_cu]
    type = ComputeFiniteStrain
    base_name = eta0
  [../]
  [./stress_cu]
    type = ComputeFiniteStrainElasticStress
    base_name = eta0
  [../]
  [./fel_cu]
    type = ElasticEnergyMaterial
    args = ' '
    base_name = eta0
    f_name = fe0
    outputs = exodus
    output_properties = fe0
    use_displaced_mesh = true
  [../]

  #Sn
  [./crysp]
    type = FiniteStrainUObasedCPBaseName
    block = 0
    stol = 1e-2
    uo_slip_rates = 'slip_rate_gss1'
    uo_slip_resistances = 'slip_resistance_gss1'
    uo_state_vars = 'state_var_gss1'
    uo_state_var_evol_rate_comps = 'state_var_evol_rate_comp_gss1'
    base_name = 'eta1'
    maximum_substep_iteration = 8
    tan_mod_type = exact
  [../]
  [./strain]
    type = ComputeFiniteStrain
    block = 0
    #displacements = 'disp_x disp_y disp_z'
    base_name = 'eta1'
  [../]
  [./elasticity_tensor]
    type = ComputeElasticityTensorCPBaseName #Allows for changes due to crystal re-orientation
    block = 0
    #C_ijkl = '72.3e3 59.4e3 35.8e3 72.3e3 35.8e3 88.4e3 24e3 22e3 22e3' #MPa #From Darbandi 2013 table III
    C_ijkl = '451.26 370.75 223.45 451.26 223.45 551.75 149.8022 137.31 137.31' #eV/nm^3 #From Darbandi 2013 table III
    fill_method = symmetric9
    euler_angle_1 = 60
    euler_angle_2 = 60
    euler_angle_3 = 60
    base_name = 'eta1'
  [../]
  [./fe1]
    type = ElasticEnergyMaterialGreenPK2
    args = ' '
    f_name = fe1
    base_name = eta1
    use_displaced_mesh = true #Not sure
    outputs = exodus
    output_properties = fe1
  [../]
  [./fp1]
    type = CPPlasticEnergyMaterial
    Q = 0.624 # Not sure what this should be
    variable_size = 32
    uo_state_var_name = state_var_gss1
    f_name = fp1
    use_displaced_mesh = true
    args = ' '
    s0 = 0.144
    outputs = exodus
    output_properties = fp1
  [../]

  [./elasticity_tensor_eta]
    type = ComputeIsotropicElasticityTensor
    youngs_modulus = 701. #112.3 GPa in eV/nm^3
    poissons_ratio = 0.31
    base_name = eta2
  [../]

  [./strain_eta]
    type = ComputeFiniteStrain
    base_name = eta2
    eigenstrain_names = eT_eta
  [../]
  [./stress_eta]
    type = ComputeFiniteStrainElasticStress
    base_name = eta2
  [../]
  [./eigenstrain_eta]
    type = ComputeVariableEigenstrain
    args = 'eta0 eta1 eta2'
    #args = ' '
    base_name = eta2
    eigen_base = '1 1 1 0 0 0'
    #eigen_base = '0.02 0.02 0'
    #eigen_base = '0 0 0'
    eigenstrain_name = eT_eta
    prefactor = pre
  [../]
  [./pre]
    type = DerivativeParsedMaterial
    material_property_names = 'h2(eta0,eta1,eta2)'
    function = '0.02*h2'
    f_name = pre
    outputs = exodus
  [../]
  [./fe2]
    type = ElasticEnergyMaterial
    args = 'eta0 eta1 eta2'
    #args = ' '
    f_name = fe2
    base_name = eta2
    use_displaced_mesh = true #Not sure
    outputs = exodus
    output_properties = fe2
  [../]
  #[./pre_eps]
  #  type = GenericFunctionMaterial
  #  prop_names = pre_eps
  #  prop_values = tdisp
  #  #prop_values = 0.02
  #  outputs = exodus
  #  output_properties = pre_eps
  #[../]

  [./scale]
    type = GenericConstantMaterial
    prop_names = 'length_scale energy_scale time_scale'
    prop_values = '1e9 6.24150943e18 1.' #m to nm J to eV s to h
  [../]
  [./model_constants]
    type = GenericConstantMaterial
    prop_names = 'sigma delta gamma tgrad_corr_mult'
    prop_values = '0.5 60e-9 1.5 0' #J/m^2 m - ?
  [../]
  [./kappa]
    type = ParsedMaterial
    material_property_names = 'sigma delta length_scale energy_scale'
    f_name = kappa
    function = '0.75*sigma*delta*energy_scale/length_scale' #eV/nm
  [../]
  [./mu]
    type = ParsedMaterial
    material_property_names = 'sigma delta length_scale energy_scale'
    f_name = mu
    function = '6*(sigma/delta)*energy_scale/length_scale^3' #eV/nm^3
    output_properties = mu
  [../]
  [./h0]
      type = SwitchingFunctionMultiPhaseMaterial
      h_name = h0
      all_etas = 'eta0 eta1 eta2'
      phase_etas = eta0
      use_displaced_mesh = true
      outputs = exodus
      output_properties = h0
  [../]
  [./h1]
      type = SwitchingFunctionMultiPhaseMaterial
      h_name = h1
      all_etas = 'eta0 eta1 eta2'
      phase_etas = eta1
      use_displaced_mesh = true
      outputs = exodus
      output_properties = h1
  [../]
  [./h2]
      type = SwitchingFunctionMultiPhaseMaterial
      h_name = h2
      all_etas = 'eta0 eta1 eta2'
      phase_etas = eta2
      use_displaced_mesh = true
      outputs = exodus
      output_properties = h2
  [../]
  [./g0]
    type = BarrierFunctionMaterial
    eta = eta0
    well_only = true
    function_name = g0
    g_order = SIMPLE
    use_displaced_mesh = true
  [../]
  [./g1]
    type = BarrierFunctionMaterial
    eta = eta1
    well_only = true
    function_name = g1
    g_order = SIMPLE
    use_displaced_mesh = true
  [../]
  [./g2]
    type = BarrierFunctionMaterial
    eta = eta2
    well_only = true
    function_name = g2
    g_order = SIMPLE
    use_displaced_mesh = true
  [../]
  [./ACMobility]
      type = GenericConstantMaterial
      prop_names = L
      prop_values = 2.7
  [../]
  [./noise_constants]
    type = GenericConstantMaterial
    prop_names = 'T kb lambda dim' #temperature Boltzmann gridsize dimensionality
    prop_values = '493 8.6173303e-5 10 3'
  [../]
  [./nuc]
    type =  DerivativeParsedMaterial
    f_name = nuc
    material_property_names = 'time dt T kb lambda dim L h0(eta0,eta1,eta2) h1(eta0,eta1,eta2)'
    function = 'if(time<1&h0*h1>0.09,sqrt(2*kb*T*L/(lambda^dim*dt)),0)' #expression from Shen (2007)
    outputs = exodus
    output_properties = nuc
    use_displaced_mesh = true
  [../]
  #Constants The energy parameters are for 220 C
  [./energy_A]
    type = GenericConstantMaterial
    prop_names = 'A_cu A_eps A_eta A_sn'
    #prop_values = '1.0133e5/Vm 4e5/Vm 4.2059e6/Vm' #J/m^3
    prop_values = '1.7756e10 2.4555e11 2.4555e11 2.3033e10' #J/m^3 Aeps=Aeta=2e6
    #prop_values = '1.5929e10 2.4555e12 2.4555e12 2.3020e10' #J/m^3 Aeps = 2e7 Aeta = 2e7
  [../]
  [./energy_B]
    type = GenericConstantMaterial
    prop_names = 'B_cu B_eps B_eta B_sn'
    #prop_values = '-2.1146e4/Vm -6.9892e3/Vm 7.168e3/Vm' #J/m^3
    prop_values = '-2.6351e9 -1.4014e9 2.3251e7 2.14216e8' #J/m^3
    #prop_values = '-2.5789e9 -1.3733e9 2.3175e7 2.1406e8' #J/m^3
  [../]
  [./energy_C]
    type = GenericConstantMaterial
    prop_names = 'C_cu C_eps C_eta C_sn'
    #prop_values = '-1.2842e4/Vm -1.9185e4/Vm -1.5265e4/Vm' #J/m^3
    prop_values = '-1.1441e9 -1.7294e9 -1.7646e9 -1.646e9' #J/m^3
    #prop_values = '-1.1529e9 -1.7330e9 -1.7646e9 -1.646e9' #J/m^3
  [../]
  [./energy_c_ab]
    type = GenericConstantMaterial
    prop_names = 'c_cu_eps c_cu_eta c_cu_sn c_eps_cu c_eps_eta c_eps_sn c_eta_cu c_eta_eps c_eta_sn c_sn_cu c_sn_eps c_sn_eta'
    prop_values = '0.02 0.1957 0.6088 0.2383 0.2483 0.2495 0.4299 0.4343 0.4359 0.9789 0.9839 0.9889' #-
    #prop_values = '0.0234 0.198 0.6088 0.2479 0.2489 0.000 0.4345 0.4349 0.4351 0.9789 0.000 0.9889' #- Aeps = 2e7 Aeta = 2e7
  [../]
  [./energy_chat]
    type = GenericConstantMaterial
    prop_names = 'chat_cu chat_eps chat_eta chat_sn'
    prop_values = '0.02 0.2433 0.4351 0.9889' #-
    #prop_values = '0.0234 0.2484 0.4350 0.9889' #-
  [../]
  [./diffusion_constants]
    type = GenericConstantMaterial
    prop_names = 'D_cu D_eps D_eta D_sn'
    #prop_values = '1e-20 6e-16 1.5e-14 1e-13' # m^2/s #D12 best slightly slow
    #prop_values = '1e-20 9.5e-16 3e-14 1e-13' # m^2/s #D15
    prop_values = '1e-20 1.25e-15 3.1e-14 1e-13' # m^2/s #D16 BEST
    #prop_values = '1e-16 1.25e-15 3.1e-14 1e-13' # m^2/s #D17
    #outputs = exodus
  [../]
  [./D_gb]
    type = ParsedMaterial
    material_property_names = 'D_eta'
    f_name = D_gb
    function = '200*D_eta'
  [../]

  [./fch_imc] #Chemical energy Cu6Sn5 phase grain 2
      type = DerivativeParsedMaterial
      f_name = fch2
      args = 'c2'
      material_property_names = 'A_eta B_eta C_eta chat_eta length_scale energy_scale'
      function = '(energy_scale/length_scale^3)*(0.5*A_eta*(c2-chat_eta)^2+B_eta*(c2-chat_eta)+C_eta)' #eV/nm^3
      derivative_order = 2
      use_displaced_mesh = true
      outputs = exodus
      output_properties = fch2
  [../]
  [./fch_sn] #Chemical energy Sn phase
      type = DerivativeParsedMaterial
      f_name = fch1
      args = 'c1'
      material_property_names = 'A_sn B_sn C_sn chat_sn length_scale energy_scale'
      function = '(energy_scale/length_scale^3)*(0.5*A_sn*(c1-chat_sn)^2+B_sn*(c1-chat_sn)+C_sn)' #eV/nm^3
      derivative_order = 2
      use_displaced_mesh = true
      outputs = exodus
      output_properties = fch1
  [../]
  [./fch_cu] #Chemical energy cu phase
      type = DerivativeParsedMaterial
      f_name = fch0
      args = 'c0'
      material_property_names = 'A_cu B_cu C_cu chat_cu length_scale energy_scale'
      function = '(energy_scale/length_scale^3)*(0.5*A_cu*(c0-chat_cu)^2+B_cu*(c0-chat_cu)+C_cu)' #eV/nm^3
      derivative_order = 2
      use_displaced_mesh = true
      outputs = exodus
      output_properties = fch0
  [../]
  [./CHMobility]
      type = DerivativeParsedMaterial
      f_name = M
      args = 'eta0 eta1 eta2'
      material_property_names = 'h0(eta0,eta1,eta2) h1(eta0,eta1,eta2) h2(eta0,eta1,eta2) D_cu D_eta D_sn A_cu A_eta A_sn Mgb length_scale energy_scale time_scale'
      #function = 's:=eta_cu^2+eta_imc1^2+eta_imc2^2+eta_sn^2;p:=eta_imc1^2*eta_imc2^2;(length_scale^5/(energy_scale*time_scale))*(h_cu*D_cu/A_cu+h_imc1*D_imc/A_imc+h_imc2*D_imc/A_imc+h_sn*D_sn/A_sn+p*Mgb/s)' #nm^5/eVs
      #function = '(length_scale^5/(energy_scale*time_scale))*(h_cu*D_cu/A_cu+h_imc1*D_imc/A_imc+h_imc2*D_imc/A_imc+h_sn*D_sn/A_sn)+if(h_imc1*h_imc2>1./16.,0,Mgb)' #nm^5/eVs
      function = '(length_scale^5/(energy_scale*time_scale))*(h2*D_eta/A_eta+h1*D_sn/A_sn+h0*D_cu/A_cu)' #'+h_imc1*h_imc2*Mgb' #nm^5/eVs
      #function = '(length_scale^5/(energy_scale*time_scale))*(h_cu*D_sn/A_sn+h_imc*D_sn/A_sn+h_sn*D_sn/A_sn)' #nm^5/eVs
      derivative_order = 2
      #outputs = exodus
      use_displaced_mesh = true
  [../]


  [./F_eta]
    type = DerivativeSumMaterial
    f_name = F2
    args = 'c2 eta0 eta1 eta2'
    sum_materials = 'fch2 fe2'
    #sum_materials = 'fch1'
    use_displaced_mesh = true
  [../]
  [./F_sn]
    type = DerivativeSumMaterial
    f_name = F1
    args = 'c1'
    sum_materials = 'fch1 fe1 fp1'
    #sum_materials = 'fch2'
    use_displaced_mesh = true
  [../]
  [./F_cu]
    type = DerivativeSumMaterial
    f_name = F0
    args = 'c0'
    sum_materials = 'fch0 fe0'
    #sum_materials = 'fch2'
    use_displaced_mesh = true
  [../]


  # Generate the global stress from the phase stresses
  [./global_stress] #homogeniserar bara Cauchy stress
    type = MultiPhaseStressMaterial
    phase_base = 'eta0 eta1 eta2'
    h          = 'h0 h1 h2'
    base_name = global
  [../]
  [./global_strain]
    type = ComputeFiniteStrain
    #displacements = 'disp_x disp_y disp_z'
    base_name = global
  [../]
[]

[Kernels]
  #Stress divergence
  [./TensorMechanics]
    #displacements = 'disp_x disp_y disp_z'
    use_displaced_mesh = true
    base_name = global
    strain = FINITE #this also sets incremental strain =true
  [../]

  #Nucleation of Cu6Sn5
  [./nuceta2]
    type = LangevinNoisePositive
    variable = eta2
    amplitude = 1
    seed = 123456789
    multiplier = nuc
    use_displaced_mesh = true
  [../]
  # Cahn-Hilliard Equation
  [./CHBulk] # Gives the residual for the concentration, dF/dc-mu
      type = KKSSplitCHCRes
      variable = c
      ca       = c1
      cb       = c2
      fa_name  = F1 #only fa is used
      fb_name  = F2
      w        = w
      h_name   = h1
      args_a = ' '
      use_displaced_mesh = true
  [../]

  [./dcdt] # Gives dc/dt
      type = CoupledTimeDerivative
      variable = w
      v = c
      use_displaced_mesh = true
  [../]
  [./ckernel] # Gives residual for chemical potential dc/dt+M\grad(mu)
      type = SplitCHWRes
      mob_name = M
      variable = w
      args = 'eta0 eta1 eta2'
      use_displaced_mesh = true
  [../]

  #KKS conditions
  # enforce pointwise equality of chemical potentials, n-1 kernels needed (mu_1=mu_2, mu_2=mu_3, ..., mu_n-1=mu_n
  [./chempot_cu_eta]
    type = KKSPhaseChemicalPotential
    variable = c0
    cb       = c2
    fa_name  = F0
    fb_name  = F2
    use_displaced_mesh = true
    args_a = ' '
    args_b = 'eta0 eta1 eta2'
  [../]
  [./chempot_eta_sn]
    type = KKSPhaseChemicalPotential
    variable = c2
    cb       = c1
    fa_name  = F2
    fb_name  = F1
    use_displaced_mesh = true
    args_a = 'eta0 eta1 eta2'
  [../]
  [./phaseconcentration] # enforce c = sum h_i*c_i
    type = KKSMultiPhaseConcentration
    variable = c1
    cj = 'c0 c1 c2'
    hj_names = 'h0 h1 h2'
    etas = 'eta0 eta1 eta2'
    c = c
    use_displaced_mesh = true
  [../]

  # AC Kernels
  [./KKSMultiACKernel]
    op_num = 3
    op_name_base = 'eta'
    ci_name_base = 'c'
    f_name_base = F
    #wi = 0.0624
    wi = 0.
    #wi = 4.
    #wi = 1.
    g_name_base = g
    use_displaced_mesh = true
  [../]
[]

[AuxVariables]
  [./hyd_g]
    order = CONSTANT
    family = MONOMIAL
    outputs = none
  [../]
  [./hyd_g_mpa]
    order = CONSTANT
    family = MONOMIAL
  [../]
  [./hyd_sn]
    order = CONSTANT
    family = MONOMIAL
  [../]
  [./hyd_sn_mpa]
    order = CONSTANT
    family = MONOMIAL
  [../]
  [./hyd_imc]
    order = CONSTANT
    family = MONOMIAL
  [../]
  [./hyd_imc_mpa]
    order = CONSTANT
    family = MONOMIAL
  [../]
  [./vm_g]
    order = CONSTANT
    family = MONOMIAL
    outputs = none
  [../]
  [./vm_g_mpa]
    order = CONSTANT
    family = MONOMIAL
  [../]

  #[./fe1]
  #  order = CONSTANT
  #  family = MONOMIAL
  #  outputs = none
  #[../]
  #[./fe2]
  #  order = CONSTANT
  #  family = MONOMIAL
  #  outputs = none
  #[../]
  [./hfe1]
    order = CONSTANT
    family = MONOMIAL
  [../]
  [./hfe2]
    order = CONSTANT
    family = MONOMIAL
  [../]
  [./hfch1]
    order = CONSTANT
    family = MONOMIAL
  [../]
  [./hfch2]
    order = CONSTANT
    family = MONOMIAL
  [../]
  [./f_density]
    order = CONSTANT
    family = MONOMIAL
  [../]
  [./f_int]
    order = CONSTANT
    family = MONOMIAL
  [../]
  [./hfp1]
    order = CONSTANT
    family = MONOMIAL
  [../]
[]

[AuxKernels]
  [./hfp1]
    type = ParsedAux
    variable = hfp1
    args = 'fp1 h1'
    function = 'h1*fp1'
    use_displaced_mesh = true
  [../]
  [./hfe1]
    type = ParsedAux
    variable = hfe1
    args = 'fe1 h1'
    function = 'h1*fe1'
    use_displaced_mesh = true
  [../]
  [./hfe2]
    type = ParsedAux
    variable = hfe2
    args = 'fe2 h2'
    function = 'h2*fe2'
    use_displaced_mesh = true
  [../]
  [./hfch1]
    type = ParsedAux
    variable = hfch1
    args = 'fch1 h1'
    function = 'h1*fch1'
    use_displaced_mesh = true
  [../]
  [./hfch2]
    type = ParsedAux
    variable = hfch2
    args = 'fch2 h2'
    function = 'h2*fch2'
    use_displaced_mesh = true
  [../]


  [./hyd_g]
    type = RankTwoScalarAux
    variable = hyd_g
    rank_two_tensor = global_stress
    scalar_type = Hydrostatic
    execute_on = timestep_end
  [../]
  [./hyd_g_mpa]
    type = ParsedAux
    variable = hyd_g_mpa
    args = hyd_g
    constant_names = 'to_MPa' #from eV/nm^3
    constant_expressions = '160.217662'
    function = 'hyd_g*to_MPa'
    execute_on = timestep_end
  [../]
  [./hyd_sn]
    type = RankTwoScalarAux
    variable = hyd_sn
    rank_two_tensor = eta1_stress
    scalar_type = Hydrostatic
    execute_on = timestep_end
  [../]
  [./hyd_sn_mpa]
    type = ParsedAux
    variable = hyd_sn_mpa
    args = 'h1 hyd_sn'
    constant_names = 'to_MPa' #from eV/nm^3
    constant_expressions = '160.217662'
    function = 'h1*hyd_sn*to_MPa'
    execute_on = timestep_end
  [../]
  [./hyd_imc]
    type = RankTwoScalarAux
    variable = hyd_imc
    rank_two_tensor = eta2_stress
    scalar_type = Hydrostatic
    execute_on = timestep_end
  [../]
  [./hyd_imc_mpa]
    type = ParsedAux
    variable = hyd_imc_mpa
    args = 'h2 hyd_imc'
    constant_names = 'to_MPa' #from eV/nm^3
    constant_expressions = '160.217662'
    function = 'h2*hyd_imc*to_MPa'
    execute_on = timestep_end
  [../]
  [./vm_g]
    type = RankTwoScalarAux
    variable = vm_g
    rank_two_tensor = global_stress
    scalar_type = VonMisesStress
    execute_on = timestep_end
  [../]
  [./vm_g_mpa]
    type = ParsedAux
    variable = vm_g_mpa
    args = vm_g
    constant_names = 'to_MPa' #from eV/nm^3
    constant_expressions = '160.217662'
    function = 'vm_g*to_MPa'
    execute_on = timestep_end
  [../]

  [./f_density]
    type = KKSMultiFreeEnergy
    variable = f_density
    hj_names = 'h0 h1 h2'
    Fj_names = 'F0 F1 F2'
    gj_names = 'g0 g1 g2'
    additional_free_energy = f_int
    interfacial_vars = 'eta0 eta1 eta2'
    kappa_names = 'kappa kappa kappa'
    #w = 0.0624
    #w = 4.
    #w = 1.
    w = 0.
    execute_on = 'initial timestep_end'
    use_displaced_mesh = true
  [../]
  [./f_int]
    type = ParsedAux
    variable = f_int
    args = 'eta0 eta1 eta2'
    constant_names = 'sigma delta gamma length_scale energy_scale'
    constant_expressions = '0.5 60e-9 1.5 1e9 6.24150943e18'
    function ='mu:=(6*sigma/delta)*(energy_scale/length_scale^3); mu*(0.25*eta0^4-0.5*eta0^2+0.25*eta1^4-0.5*eta1^2+0.25*eta2^4-0.5*eta2^2+gamma*(eta0^2*(eta1^2+eta2^2)+eta1^2*eta2^2)+0.25)'
    execute_on = 'initial timestep_end'
    use_displaced_mesh = true
  [../]
[]


[Postprocessors]
  [./imc_area_h]
    type = ElementIntegralMaterialProperty
    mat_prop = h2
    execute_on = 'INITIAL TIMESTEP_END'
    use_displaced_mesh = true
  [../]
  #[./e_yy1]
  #  type = PointValue
  #  variable = e_yy1
  #  point = '-250 0 50'
  #  #use_displaced_mesh = true
  #[../]
  #[./stress_yy1]
  #  type = PointValue
  #  variable = stress_yy1
  #  point = '-250 0 50'
  #  #use_displaced_mesh = true
  #[../]
  #[./e_yy2]
  #  type = PointValue
  #  variable = e_yy2
  #  point = '-250 0 50'
  #  #use_displaced_mesh = true
  #[../]
  #[./stress_yy2]
  #  type = PointValue
  #  variable = stress_yy2
  #  point = '-250 0 50'
  #  #use_displaced_mesh = true
  #[../]
  #[./e_yyg]
  #  type = PointValue
  #  variable = eyyg
  #  point = '-250 0 50'
  #  #use_displaced_mesh = true
  #[../]
  #[./stress_yyg]
  #  type = PointValue
  #  variable = syyg
  #  point = '-250 0 50'
  #  #use_displaced_mesh = true
  #[../]
  #[./stress_xyg]
  #  type = PointValue
  #  variable = stress_yy1
  #  point = '-250 0 50'
  #  #use_displaced_mesh = true
  #[../]
  #[./stress_xzg]
  #  type = PointValue
  #  variable = sxzg
  #  point = '-250 0 50'
  #  #use_displaced_mesh = true
  #[../]
  [./total_energy]
    type = ElementIntegralVariablePostprocessor
    variable = f_density
    execute_on = 'Initial TIMESTEP_END'
    use_displaced_mesh = true
  [../]
  [./step_size]
    type = TimestepSize
  [../]
[]
[Debug]
  show_var_residual_norms = true
  show_material_props = false
[]
[Preconditioning]
  [./smp]
    type = SMP
    full = true
    petsc_options_iname = '-ksp_gmres_restart -snes_atol  -snes_rtol -ksp_rtol -pc_type -sub_pc_type  -pc_factor_shift_type  -sub_pc_factor_shift_type pc_factor_mat_solver_package'
    petsc_options_value = '     121              1e-10     1e-8     1e-5          lu       ilu             nonzero             nonzero            superlu_dist'

    #petsc_options_iname = '-ksp_gmres_restart -snes_atol  -snes_rtol -ksp_rtol -pc_type -sub_pc_type  -pc_factor_shift_type  -sub_pc_factor_shift_type'
    #petsc_options_value = '     121              1e-10     1e-8     1e-5          asm       ilu             nonzero             nonzero'

    #petsc_options_iname = '-pc_type -sub_pc_type   -sub_pc_factor_shift_type'
    #petsc_options_value = 'asm       ilu            nonzero'

    #petsc_options_iname = '-pc_type -pc_hypre_type   -pc_factor_shift_type  -ksp_gmres_restart'
    #petsc_options_value = 'hypre       boomeramg            nonzero    150'
  [../]
[]

[Executioner]
  type = Transient
  solve_type = 'PJFNK'
  line_search = default
  #line_search = none
  #line_search = bt
  petsc_options = '-snes_converged_reason -ksp_converged_reason -snes_ksp_ew'
  l_max_its = 100
  nl_max_its = 20
  l_tol = 1.0e-4
  #l_abs_step_tol = 1e-8
  nl_rel_tol = 1.0e-7 #1.0e-10
  nl_abs_tol = 1.0e-10#1.0e-11

  #num_steps = 2000
  end_time = 10 #50 hours
  scheme = implicit-euler

  [./TimeStepper]
      # Turn on time stepping
      type = IterationAdaptiveDT
      dt = 1e-3

      cutback_factor = 0.5
      growth_factor = 1.5
      optimal_iterations = 10
      linear_iteration_ratio = 25
      #postprocessor_dtlim = 5
  [../]

  [./Adaptivity]
    # Block that turns on mesh adaptivity. Note that mesh will never coarsen beyond initial mesh (before uniform refinement)
  #    initial_adaptivity = 2 # Number of times mesh is adapted to initial condition
    refine_fraction = 0.6 # Fraction of high error that will be refined
    coarsen_fraction = 0.1 # Fraction of low error that will coarsened
    max_h_level = 4 # Max number of refinements used, starting from initial mesh (before uniform refinement)
  [../]

[]

[Outputs]
  file_base = 3phase-10nm-40x40x1-nuc-fp-circle-60-60-60-adaptive
  exodus = true
  csv = true
  print_mesh_changed_info = true
[]
