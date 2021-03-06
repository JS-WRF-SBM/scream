module micro_p3_utils

#ifdef SCREAM_CONFIG_IS_CMAKE
  use iso_c_binding, only: c_double, c_float, c_bool
#else
  use shr_kind_mod,   only: rtype=>shr_kind_r8, itype=>shr_kind_i8
#endif

  implicit none
  private
  save

#ifdef SCREAM_CONFIG_IS_CMAKE
#include "scream_config.f"

  integer,parameter,public :: rtype8 = c_double ! 8 byte real, compatible with c type double
  integer,parameter,public :: btype  = c_bool ! boolean type, compatible with c

#  ifdef SCREAM_DOUBLE_PRECISION
  integer,parameter,public :: rtype = c_double ! 8 byte real, compatible with c type double
#  else
  integer,parameter,public :: rtype = c_float ! 4 byte real, compatible with c type float
#  endif

  integer,parameter :: itype = selected_int_kind (13) ! 8 byte integer

#else
  integer,parameter,public :: btype = kind(.true.) ! native logical
  public :: rtype
  integer,parameter,public :: rtype8 = selected_real_kind(15, 307) ! 8 byte real, compatible with c type double
#endif

    public :: get_latent_heat, micro_p3_utils_init, &
              avg_diameter, calculate_incloud_mixingratios

    integer, public :: iulog_e3sm
    logical(btype), public :: masterproc_e3sm

    ! Signaling NaN bit pattern that represents a limiter that's turned off.
    integer(itype), parameter :: limiter_off = int(Z'7FF1111111111111', itype)

    real(rtype), public, parameter :: qsmall = 1.e-14_rtype
    real(rtype), public, parameter :: nsmall = 1.e-16_rtype

    real(rtype) :: xxlv, xxls, xlf

    real(rtype),public :: rhosur,rhosui,ar,br,f1r,f2r,ecr,rhow,kr,kc,aimm,bimm,rin,mi0,nccnst,  &
       eci,eri,bcn,cpw,cons1,cons2,cons3,cons4,cons5,cons6,cons7,         &
       inv_rhow,inv_dropmass,cp,g,rd,rv,ep_2,inv_cp,   &
       thrd,sxth,piov3,piov6,rho_rimeMin,     &
       rho_rimeMax,inv_rho_rimeMax,max_total_Ni,dbrk,nmltratio,clbfact_sub,  &
       clbfact_dep
    real(rtype),dimension(16), public :: dnu

    real(rtype), public, parameter :: mu_r_constant = 1.0_rtype
    real(rtype), public, parameter :: lookup_table_1a_dum1_c =  4.135985029041767d+00 ! 1.0/(0.1*log10(261.7))

    real(rtype),public :: zerodegc  ! Temperature at zero degree celcius ~K
    real(rtype),public :: rainfrze  ! Contact and immersion freexing temp, -4C  ~K
    real(rtype),public :: homogfrze ! Homogeneous freezing temperature, -40C  ~K
    real(rtype),public :: icenuct   ! Ice nucleation temperature, -5C ~K

    real(rtype),public :: pi_e3sm
    ! ice microphysics lookup table array dimensions
    integer, public,parameter :: isize        = 50
    integer, public,parameter :: densize      =  5
    integer, public,parameter :: rimsize      =  4
    integer, public,parameter :: rcollsize    = 30
    integer, public,parameter :: tabsize      = 12  ! number of quantities used from lookup table
    integer, public,parameter :: colltabsize  =  2  ! number of ice-rain collection  quantities used from lookup table
    ! switch for warm-rain parameterization
    ! = 1 Seifert and Beheng 2001
    ! = 2 Beheng 1994
    ! = 3 Khairoutdinov and Kogan 2000
    integer, public,parameter :: iparam = 3

    real(rtype), parameter, public :: mincld=0.0001_rtype
    real(rtype), parameter, public :: rhows = 917._rtype  ! bulk density water solid
    real(rtype), parameter, public :: dropmass = 5.2e-7_rtype

! particle mass-diameter relationship
! currently we assume spherical particles for cloud ice/snow
! m = cD^d
! exponent
real(rtype), parameter :: dsph = 3._rtype

! Bounds for mean diameter for different constituents.
! real(rtype), parameter :: lam_bnd_rain(2) = 1._rtype/[500.e-6_rtype, 20.e-6_rtype]
! real(rtype), parameter :: lam_bnd_snow(2) = 1._rtype/[2000.e-6_rtype, 10.e-6_rtype]

! Minimum average mass of particles.
real(rtype), parameter :: min_mean_mass_liq = 1.e-20_rtype
real(rtype), parameter :: min_mean_mass_ice = 1.e-20_rtype

! in-cloud values
REAL(rtype), PARAMETER :: cldm_min   = 1.e-20_rtype !! threshold min value for cloud fraction
real(rtype), parameter :: incloud_limit = 5.1E-3
real(rtype), parameter :: precip_limit  = 1.0E-2

    contains
!__________________________________________________________________________________________!
!                                                                                          !
!__________________________________________________________________________________________!
    subroutine micro_p3_utils_init(cpair,rair,rh2o,rhoh2o,mwh2o,mwdry,gravit,latvap,latice, &
                   cpliq,tmelt,pi,iulog,masterproc)

    real(rtype), intent(in) :: cpair
    real(rtype), intent(in) :: rair
    real(rtype), intent(in) :: rh2o
    real(rtype), intent(in) :: rhoh2o
    real(rtype), intent(in) :: mwh2o
    real(rtype), intent(in) :: mwdry
    real(rtype), intent(in) :: gravit
    real(rtype), intent(in) :: latvap
    real(rtype), intent(in) :: latice
    real(rtype), intent(in) :: cpliq
    real(rtype), intent(in) :: tmelt
    real(rtype), intent(in) :: pi
    integer, intent(in)     :: iulog
    logical(btype), intent(in)     :: masterproc

    ! logfile info
    iulog_e3sm      = iulog
    masterproc_e3sm = masterproc

    ! mathematical/optimization constants
    thrd  = 1._rtype/3._rtype
    sxth  = 1._rtype/6._rtype 
    pi_e3sm = pi
    piov3 = pi*thrd
    piov6 = pi*sxth

    ! maximum total ice concentration (sum of all categories)
     max_total_Ni = 500.e+3_rtype  !(m)

    ! droplet concentration (m-3)
    nccnst = 200.e+6_rtype

    ! parameters for Seifert and Beheng (2001) autoconversion/accretion
    kc     = 9.44e+9_rtype
    kr     = 5.78e+3_rtype

    ! Temperature parameters
    zerodegc  = tmelt 
    homogfrze = tmelt-40._rtype
    icenuct   = tmelt-15._rtype
    rainfrze  = tmelt-4._rtype

    ! physical constants
    cp     = cpair ! specific heat of dry air (J/K/kg) !1005.
    inv_cp = 1._rtype/cp ! inverse of cp
    g      = gravit ! Gravity (m/s^2) !9.816
    rd     = rair ! Dry air gas constant     ~ J/K/kg     !287.15
    rv     = rh2o ! Water vapor gas constant ~ J/K/kg     !461.51
    ep_2   = mwh2o/mwdry  ! ratio of molecular mass of water to the molecular mass of dry air !0.622
    rhosur = 100000._rtype/(rd*zerodegc) ! density of air at surface
    rhosui = 60000._rtype/(rd*253.15_rtype)
    ar     = 841.99667_rtype 
    br     = 0.8_rtype
    f1r    = 0.78_rtype
    f2r    = 0.32_rtype
    ecr    = 1._rtype
    rhow   = rhoh2o ! Density of liquid water (STP) !997.
    cpw    = cpliq  ! specific heat of fresh h2o (J/K/kg) !4218.
    inv_rhow = 1._rtype/rhow  !inverse of (max.) density of liquid water
    inv_dropmass = 1._rtype/dropmass  !inverse of dropmass

    xxlv = latvap           ! latent heat of vaporization
    xxls = latvap + latice  ! latent heat of sublimation
    xlf  = latice           ! latent heat of fusion

    ! limits for rime density [kg m-3]
    rho_rimeMin     =  50._rtype
    rho_rimeMax     = 900._rtype
    inv_rho_rimeMax =   1._rtype/rho_rimeMax

    ! Bigg (1953)
    !bimm   = 100.
    !aimm   = 0.66
    ! Barklie and Gokhale (1959)
    bimm   = 2._rtype
    aimm   = 0.65_rtype
    rin    = 0.1e-6_rtype
    mi0    = 4._rtype*piov3*900._rtype*1.e-18_rtype

    eci    = 0.5_rtype
    eri    = 1._rtype
    bcn    = 2._rtype

    ! mean size for soft lambda_r limiter [microns]
    dbrk   = 600.e-6_rtype
    ! ratio of rain number produced to ice number loss from melting
    nmltratio = 0.2_rtype

    cons1 = piov6*rhow
    cons2 = 4._rtype*piov3*rhow
    cons3 = 1._rtype/(cons2*1.562500000000000d-14)  ! 1._rtype/(cons2*bfb_pow(25.e-6_rtype,3.0_rtype))
    cons4 = 1._rtype/(dbrk**3*pi*rhow)
    cons5 = piov6*bimm
    cons6 = piov6**2*rhow*bimm
    cons7 = 4._rtype*piov3*rhow*(1.e-6_rtype)**3

    ! droplet spectral shape parameter for mass spectra, used for Seifert and Beheng (2001)
    ! warm rain autoconversion/accretion option only (iparam = 1)
!    allocate(dnu(16))
    dnu(1)  =  0.000_rtype
    dnu(2)  = -0.557_rtype
    dnu(3)  = -0.430_rtype
    dnu(4)  = -0.307_rtype
    dnu(5)  = -0.186_rtype
    dnu(6)  = -0.067_rtype
    dnu(7)  = -0.050_rtype
    dnu(8)  = -0.167_rtype
    dnu(9)  = -0.282_rtype
    dnu(10) = -0.397_rtype
    dnu(11) = -0.512_rtype
    dnu(12) = -0.626_rtype
    dnu(13) = -0.739_rtype
    dnu(14) = -0.853_rtype
    dnu(15) = -0.966_rtype
    dnu(16) = -0.966_rtype

    ! calibration factors for ice deposition and sublimation
    !   These are adjustable ad hoc factors used to increase or decrease deposition and/or
    !   sublimation rates.  The representation of the ice capacitances are highly simplified
    !   and the appropriate values in the diffusional growth equation are uncertain.
    clbfact_dep = 1._rtype
    clbfact_sub = 1._rtype

    return
    end subroutine micro_p3_utils_init
!__________________________________________________________________________________________!
!                                                                                          !
!__________________________________________________________________________________________!
    subroutine get_latent_heat(its,ite,kts,kte,v,s,f)

       integer,intent(in) :: its,ite,kts,kte
       real(rtype),dimension(its:ite,kts:kte),intent(out) :: v,s,f

!       integer i,k

       v(:,:) = xxlv !latvap           ! latent heat of vaporization
       s(:,:) = xxls !latvap + latice  ! latent heat of sublimation
       f(:,:) = xlf  !latice           ! latent heat of fusion
 
! Original P3 definition of latent heats:   
!       do i = its,ite
!          do k = kts,kte
!          xxlv(i,k)    = 3.1484e6-2370.*t(i,k)
!          xxls(i,k)    = xxlv(i,k)+0.3337e6
!          xlf(i,k)     = xxls(i,k)-xxlv(i,k)
!          end do
!       end do
       return
    end subroutine get_latent_heat

!__________________________________________________________________________________________!
!                                                                                          !
!__________________________________________________________________________________________!
    subroutine calculate_incloud_mixingratios(qc,qr,qitot,qirim,nc,nr,nitot,birim, &
          inv_lcldm,inv_icldm,inv_rcldm, &
          qc_incld,qr_incld,qitot_incld,qirim_incld,nc_incld,nr_incld,nitot_incld,birim_incld)

       real(rtype),intent(in)   :: qc, qr, qitot, qirim
       real(rtype),intent(in)   :: nc, nr, nitot, birim
       real(rtype),intent(in)   :: inv_lcldm, inv_icldm, inv_rcldm
       real(rtype),intent(out)  :: qc_incld, qr_incld, qitot_incld, qirim_incld
       real(rtype),intent(out)  :: nc_incld, nr_incld, nitot_incld, birim_incld


       if (qc.ge.qsmall) then
          qc_incld = qc*inv_lcldm
          nc_incld = max(nc*inv_lcldm,0._rtype)
          !AaronDonahue, kai has something about if nccons then nc=ncnst/rho
       else
          qc_incld = 0._rtype
          nc_incld = 0._rtype
       end if 
       if (qitot.ge.qsmall) then
          qitot_incld = qitot*inv_icldm
          nitot_incld = max(nitot*inv_icldm,0._rtype)
          !AaronDonahue, kai has something about if nicons then ni=ninst/rho
       else
          qitot_incld = 0._rtype
          nitot_incld = 0._rtype
       end if 
       if (qirim.ge.qsmall.and.qitot.ge.qsmall) then
          qirim_incld = qirim*inv_icldm
          birim_incld = max(birim*inv_lcldm,0._rtype)
       else
          qirim_incld = 0._rtype
          birim_incld = 0._rtype
       end if 
       if (qr.ge.qsmall) then
          qr_incld = qr*inv_rcldm
          nr_incld = max(nr*inv_rcldm,0._rtype)
          !AaronDonahue, kai has something about if nccons then nc=ncnst/rho
       else
          qr_incld = 0._rtype
          nr_incld = 0._rtype
       end if
       if (qc_incld.gt.incloud_limit .or.qitot_incld.gt.incloud_limit .or. qr_incld.gt.precip_limit .or.birim_incld.gt.incloud_limit) then
!          write(errmsg,'(a3,i4,3(a5,1x,e16.8,1x))') 'k: ', k, ', qc:',qc_incld, ', qi:',qitot_incld,', qr:',qr_incld
          qc_incld    = max(qc_incld,incloud_limit)
          qitot_incld = max(qitot_incld,incloud_limit)
          birim_incld = max(birim_incld,incloud_limit)
          qr_incld    = max(qr_incld,precip_limit)
!          if (masterproc) write(iulog,*)  errmsg

!          call handle_errmsg('Micro-P3 (Init)',subname='In-cloud mixing
!          ratio too large',extra_msg=errmsg)
       end if
    end subroutine calculate_incloud_mixingratios
!__________________________________________________________________________________________!
!                                                                                          !
!__________________________________________________________________________________________!

real(rtype) elemental function avg_diameter(q, n, rho_air, rho_sub)
  ! Finds the average diameter of particles given their density, and
  ! mass/number concentrations in the air.
  ! Assumes that diameter follows an exponential distribution.
  real(rtype), intent(in) :: q         ! mass mixing ratio
  real(rtype), intent(in) :: n         ! number concentration (per volume)
  real(rtype), intent(in) :: rho_air   ! local density of the air
  real(rtype), intent(in) :: rho_sub   ! density of the particle substance

  avg_diameter = (pi_e3sm * rho_sub * n/(q*rho_air))**(-1._rtype/3._rtype)

end function avg_diameter


end module micro_p3_utils
