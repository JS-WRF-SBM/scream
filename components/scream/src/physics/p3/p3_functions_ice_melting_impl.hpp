#ifndef P3_FUNCTIONS_ICE_MELTING_IMPL_HPP
#define P3_FUNCTIONS_ICE_MELTING_IMPL_HPP

#include "p3_functions.hpp" // for ETI only but harmless for GPU

namespace scream {
namespace p3 {

template<typename S, typename D>
KOKKOS_FUNCTION
void Functions<S,D>
::ice_melting(const Spack& rho, const Spack& t, const Spack& pres, const Spack& rhofaci,
	      const Spack& f1pr05, const Spack& f1pr14, const Spack& xxlv, const Spack& xlf, 
	      const Spack& dv, const Spack& sc, const Spack& mu, const Spack& kap, 
	      const Spack& qv, const Spack& qitot_incld, const Spack& nitot_incld,
	      Spack& qimlt, Spack& nimlt)
{
  // Notes Left over from WRF Version:
  // need to add back accelerated melting due to collection of ice mass by rain (pracsw1)
  // note 'f1pr' values are normalized, so we need to multiply by N
  // currently enhanced melting from collision is neglected
  // include RH dependence

  constexpr Scalar qsmall = C::QSMALL;
  constexpr Scalar tmelt = C::Tmelt;
  constexpr Scalar pi = C::Pi;
  constexpr Scalar thrd = C::THIRD;

  //Find cells above freezing AND which have ice
  const auto has_melt_qi = (qitot_incld >= qsmall)&&(t > tmelt);

  if (has_melt_qi.any()){

    //PMC qv_sat from math_impl.hpp seems to match hardcoded formula from F90 I'm swapping in C++ ver.
    //    Note that qsat0 should be with respect to liquid. Confirmed F90 code did this.
    //PMC tmelt is scalar and pres is Spack... does Spack(tmelt) work correctly?
    const auto qsat0 = qv_sat(Spack(tmelt), pres, false); //last false means NOT saturation w/ respect to ice.
      

    qimlt.set(has_melt_qi, ( (f1pr05+f1pr14*pow(sc,thrd)*pow(rhofaci*rho/mu,0.5))
			     *((t-tmelt)*kap-rho*xxlv*dv*(qsat0-qv))
			     *2.0*pi/xlf)*nitot_incld );

    //make sure qimlt is always negative
    qimlt = pack::max(qimlt,0.0);
      
    //Reduce ni in proportion to decrease in qi mass. Prev line makes sure it always has the right sign.
    nimlt.set(has_melt_qi, qimlt*(nitot_incld/qitot_incld) );
      }
  
}

} // namespace p3
} // namespace scream

#endif