#include "catch2/catch.hpp"

#include "share/scream_types.hpp"
#include "share/util/scream_utils.hpp"
#include "share/scream_kokkos.hpp"
#include "share/scream_pack.hpp"
#include "physics/p3/p3_functions.hpp"
#include "physics/p3/p3_functions_f90.hpp"
#include "share/util/scream_kokkos_utils.hpp"

#include "p3_unit_tests_common.hpp"

#include <thread>
#include <array>
#include <algorithm>
#include <random>

namespace scream {
namespace p3 {
namespace unit_test {

template <typename D>
struct UnitWrap::UnitTest<D>::TestCloudRainAccretion {

static void run_phys()
{
  // TODO
}

static void run_bfb()
{
  static constexpr Int max_pack_size = 16;
  REQUIRE(Spack::n <= max_pack_size);

  // This is the threshold for whether the qc and qr cloud mixing ratios are
  // large enough to affect the warm-phase process rates qcacc and ncacc.
  constexpr Scalar qsmall = C::QSMALL;

  constexpr Scalar rho1 = 4.056E-03, rho2 = 6.852E-02,
                   rho3 = 8.852E-02, rho4 = 1.902E-01;
  constexpr Scalar inv_rho1 = 1.0/rho1, inv_rho2 = 1.0/rho2,
                   inv_rho3 = 1.0/rho3, inv_rho4 = 1.0/rho4;
  constexpr Scalar qc_incld_small = 0.9 * qsmall;
  constexpr Scalar qr_incld_small = 0.9 * qsmall;
  constexpr Scalar qc_incld_not_small = 2.0 * qsmall;
  constexpr Scalar qr_incld_not_small = 2.0 * qsmall;
  constexpr Scalar nc_incld1 = 9.952E+05, nc_incld2 = 9.952E+06,
                   nc_incld3 = 1.734E+07, nc_incld4 = 9.952E+08;

  CloudRainAccretionData cloud_rain_acc_data[max_pack_size] = {
    // rho, inv_rho, qc_incld, nc_incld, qr_incld, qcacc, ncacc
    {rho1, inv_rho1, qc_incld_small, nc_incld1, qr_incld_small},
    {rho2, inv_rho2, qc_incld_small, nc_incld2, qr_incld_small},
    {rho3, inv_rho3, qc_incld_small, nc_incld3, qr_incld_small},
    {rho4, inv_rho4, qc_incld_small, nc_incld4, qr_incld_small},

    {rho1, inv_rho1, qc_incld_small, nc_incld1, qr_incld_not_small},
    {rho2, inv_rho2, qc_incld_small, nc_incld2, qr_incld_not_small},
    {rho3, inv_rho3, qc_incld_small, nc_incld3, qr_incld_not_small},
    {rho4, inv_rho4, qc_incld_small, nc_incld4, qr_incld_not_small},

    {rho1, inv_rho1, qc_incld_not_small, nc_incld1, qr_incld_small},
    {rho2, inv_rho2, qc_incld_not_small, nc_incld2, qr_incld_small},
    {rho3, inv_rho3, qc_incld_not_small, nc_incld3, qr_incld_small},
    {rho4, inv_rho4, qc_incld_not_small, nc_incld4, qr_incld_small},

    {rho1, inv_rho1, qc_incld_not_small, nc_incld1, qr_incld_not_small},
    {rho2, inv_rho2, qc_incld_not_small, nc_incld2, qr_incld_not_small},
    {rho3, inv_rho3, qc_incld_not_small, nc_incld3, qr_incld_not_small},
    {rho4, inv_rho4, qc_incld_not_small, nc_incld4, qr_incld_not_small}
  };

  // Sync to device
  view_1d<CloudRainAccretionData> device_data("cloud_rain_acc", Spack::n);
  const auto host_data = Kokkos::create_mirror_view(device_data);
  std::copy(&cloud_rain_acc_data[0], &cloud_rain_acc_data[0] + Spack::n,
            host_data.data());
  Kokkos::deep_copy(device_data, host_data);

  // Run the Fortran subroutine.
  for (Int i = 0; i < Spack::n; ++i) {
    cloud_rain_accretion(cloud_rain_acc_data[i]);
  }

  // Run the lookup from a kernel and copy results back to host
  Kokkos::parallel_for(1, KOKKOS_LAMBDA(const Int&) {
    // Init pack inputs
    Spack rho, inv_rho, qc_incld, nc_incld, qr_incld;
    for (Int s = 0; s < Spack::n; ++s) {
      rho[s]            = device_data(s).rho;
      inv_rho[s]        = device_data(s).inv_rho;
      qc_incld[s]       = device_data(s).qc_incld;
      nc_incld[s]       = device_data(s).nc_incld;
      qr_incld[s]       = device_data(s).qr_incld;
    }

    Spack qcacc{0.0};
    Spack ncacc{0.0};

    Functions::cloud_rain_accretion(rho, inv_rho, qc_incld, nc_incld, qr_incld,
                                    qcacc, ncacc);

    // Copy results back into views
    for (Int s = 0; s < Spack::n; ++s) {
      device_data(s).qcacc  = qcacc[s];
      device_data(s).ncacc  = ncacc[s];
    }
  });

  // Sync back to host.
  Kokkos::deep_copy(host_data, device_data);

  // Validate results.
  for (Int s = 0; s < Spack::n; ++s) {
    REQUIRE(cloud_rain_acc_data[s].qcacc == host_data[s].qcacc);
    REQUIRE(cloud_rain_acc_data[s].ncacc == host_data[s].ncacc);
  }

}

};

}
}
}

namespace {

TEST_CASE("p3_cloud_rain_accretion", "[p3_functions]")
{
  using TCRA = scream::p3::unit_test::UnitWrap::UnitTest<scream::DefaultDevice>::TestCloudRainAccretion;

  TCRA::run_phys();
  TCRA::run_bfb();

  scream::p3::P3GlobalForFortran::deinit();
}

} // namespace
