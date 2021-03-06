#ifndef P3_FUNCTIONS_DROPLET_SELF_COLL_IMPL_HPP
#define P3_FUNCTIONS_DROPLET_SELF_COLL_IMPL_HPP

#include "p3_functions.hpp" // for ETI only but harmless for GPU

namespace scream {
namespace p3 {

/*
 * Implementation of p3 droplet self collection function. Clients should NOT
 * #include this file, but include p3_functions.hpp instead.
 */

template <typename S, typename D>
KOKKOS_FUNCTION
void Functions<S,D>
::droplet_self_collection(const Spack&, const Spack&,
                          const Spack& qc_incld, const Spack&,
                          const Spack&, const Spack&, Spack& ncslf)
{
  constexpr Scalar qsmall = C::QSMALL;

  const auto qc_not_small = (qc_incld >= qsmall);
  if (qc_not_small.any()) {
    // Khroutdinov and Kogan (2000)
    ncslf.set(qc_not_small, 0);
  }
}

} // namespace p3
} // namespace scream

#endif
