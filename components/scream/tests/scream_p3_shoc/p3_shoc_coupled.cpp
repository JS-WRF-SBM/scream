#include <catch2/catch.hpp>
#include "share/atmosphere_process.hpp"
#include "share/scream_pack.hpp"
#include "share/grid/user_provided_grids_manager.hpp"
#include "share/grid/se_grid.hpp"
#include "control/atmosphere_driver.hpp"

#include "physics/p3/atmosphere_microphysics.hpp"
#include "physics/p3/scream_p3_interface.hpp"
#include "physics/shoc/atmosphere_macrophysics.hpp"
#include "physics/shoc/scream_shoc_interface.hpp"
#include "physics/p3/p3_functions_f90.hpp"

namespace scream {

// === A dummy physics grids for this test === //

class DummyPhysicsGrid : public SEGrid
{
public:
  DummyPhysicsGrid (const int num_cols)
   : SEGrid("Physics",GridType::SE_NodeBased,num_cols)
  {
    // Nothing to do here
  }
  ~DummyPhysicsGrid () = default;

protected:
};

TEST_CASE("p3-shoc-coupled", "") {
  using namespace scream;
  using namespace scream::control;

  constexpr int num_iters = 10;
  constexpr int num_cols  = 32;

  // Create a parameter list for inputs
  ParameterList ad_params("Atmosphere Driver");
  auto& proc_params = ad_params.sublist("Atmosphere Processes");

  proc_params.set("Number of Entries",3);
  proc_params.set<std::string>("Schedule Type","Sequential");

  auto& p0 = proc_params.sublist("Process 0");
  p0.set<std::string>("Process Name", "SA");
  p0.set<std::string>("Grid","Physics");
  auto& p1 = proc_params.sublist("Process 1");
  p1.set<std::string>("Process Name", "P3");
  p1.set<std::string>("Grid","Physics");
  auto& p2 = proc_params.sublist("Process 2");
  p2.set<std::string>("Process Name", "SHOC");
  p2.set<std::string>("Grid","Physics");

  auto& gm_params = ad_params.sublist("Grids Manager");
  gm_params.set<std::string>("Type","User Provided");
  gm_params.set<std::string>("Reference Grid","Physics");

  // Need to register products in the factory *before* we create any AtmosphereProcessGroup,
  // which rely on factory for process creation. The initialize method of the AD does that.
  // While we're at it, check that the case insensitive key of the factory works.
  auto& proc_factory = AtmosphereProcessFactory::instance();
  proc_factory.register_product("SA",&create_atmosphere_process<P3StandAloneInit>);
  proc_factory.register_product("P3",&create_atmosphere_process<P3Microphysics>);
  proc_factory.register_product("SHOC",&create_atmosphere_process<SHOCMacrophysics>);

  // Need to register grids managers before we create the driver
  auto& gm_factory = GridsManagerFactory::instance();
  gm_factory.register_product("User Provided",create_user_provided_grids_manager);

  // Set the dummy grid in the UserProvidedGridManager
  // Recall that this class stores *static* members, so whatever
  // we set here, will be reflected in the GM built by the factory.
  UserProvidedGridsManager upgm;
  upgm.set_grid(std::make_shared<DummyPhysicsGrid>(num_cols));
  upgm.set_reference_grid("Physics");

  // Create a comm
  Comm atm_comm (MPI_COMM_WORLD);

  // Create the driver
  AtmosphereDriver ad;

  // Init and run (do not finalize, or you'll clear the field repo!)
  util::TimeStamp time (0,0,0);
  ad.initialize(atm_comm,ad_params,time);
  for (int i=0; i<num_iters; ++i) {
    ad.run(300.0);
  }

  // Finalize 
  ad.finalize();
  upgm.clean_up();
  p3::P3GlobalForFortran::deinit();

  // If we got here, we were able to run p3+shoc
  REQUIRE(true);
}
} // empty namespace
