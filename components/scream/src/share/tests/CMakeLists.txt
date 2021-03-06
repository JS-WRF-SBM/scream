INCLUDE (ScreamUtils)

# Test utilities (f90)
CreateUnitTest(array_io "array_io_tests.cpp;unit_test.f90" scream_share)

# Test utilities (c++)
CreateUnitTest(util_cxx "util_tests.cpp" scream_share)

# Test packs
CreateUnitTest(packs "pack_tests.cpp;pack_kokkos_tests.cpp" scream_share)

# Test kokkos utils
CreateUnitTest(kokkos_utils "kokkos_utils_tests.cpp" scream_share THREADS 1 ${SCREAM_TEST_MAX_THREADS} ${SCREAM_TEST_THREAD_INC})

# Test fields
CreateUnitTest(field "field_tests.cpp" scream_share)

# Test workspace manager
CreateUnitTest(wsm "workspace_tests.cpp" scream_share THREADS 1 ${SCREAM_TEST_MAX_THREADS} ${SCREAM_TEST_THREAD_INC})

# Test atmosphere processes
CreateUnitTest(atm_proc "atm_process_tests.cpp" scream_share)

# Test lin interp processes
CreateUnitTest(lin_interp "lin_interp_test.cpp;lin_interp_ref.f90" scream_share THREADS 1 ${SCREAM_TEST_MAX_THREADS} ${SCREAM_TEST_THREAD_INC})

# Test upper_bound
CreateUnitTest(upper_bound "upper_bound_test.cpp" scream_share)

# Test tridiag solvers
CreateUnitTest(tridiag "tridiag_tests.cpp;tridiag_tests_correctness.cpp;tridiag_tests_performance.cpp" scream_share THREADS ${SCREAM_TEST_MAX_THREADS} OPTIONAL EXCLUDE_MAIN_CPP)

# Test units framework
CreateUnitTest(units "units.cpp" scream_share)

# YAML parser
CONFIGURE_FILE (${CMAKE_CURRENT_SOURCE_DIR}/input.yaml
                ${CMAKE_CURRENT_BINARY_DIR}/input.yaml
                COPYONLY)
CreateUnitTest(yaml_parser "yaml_parser.cpp" scream_share)
