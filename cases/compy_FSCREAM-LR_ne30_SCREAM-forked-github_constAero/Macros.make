SUPPORTS_CXX := FALSE
ifeq ($(COMPILER),intel)
  MPIFC :=  mpif90 
  FFLAGS_NOOPT :=  -O0 
  CXXFLAGS :=  -std=c++11 -fp-model source 
  MPICC :=  mpicc  
  SCC :=  icc 
  MPICXX :=  mpicxx 
  HAS_F2008_CONTIGUOUS := TRUE
  CXX_LDFLAGS :=  -cxxlib 
  SUPPORTS_CXX := TRUE
  FFLAGS :=   -convert big_endian -assume byterecl -ftz -traceback -assume realloc_lhs -fp-model source 
  FIXEDFLAGS :=  -fixed -132 
  CXX_LINKER := FORTRAN
  FC_AUTO_R8 :=  -r8 
  CFLAGS :=  -O2 -fp-model precise -std=gnu99 
  FREEFLAGS :=  -free 
  SFC :=  ifort 
  SCXX :=  icpc 
endif
ifeq ($(COMPILER),pgi)
  MPIFC :=  mpif90 
  FFLAGS_NOOPT :=  -O0 
  MPICC :=  mpicc 
  SCC :=  pgcc 
  LDFLAGS :=  -time -Wl,--allow-multiple-definition 
  MPICXX :=  mpicxx 
  HAS_F2008_CONTIGUOUS := FALSE
  FFLAGS :=   -i4 -time -Mstack_arrays  -Mextend -byteswapio -Mflushz -Kieee -Mallocatable=03 
  FIXEDFLAGS :=  -Mfixed 
  FC_AUTO_R8 :=  -r8 
  CFLAGS :=  -time 
  FREEFLAGS :=  -Mfree 
  SFC :=  pgf95 
  SCXX :=  pgc++ 
endif
ifeq ($(COMPILER),intel)
  PIO_FILESYSTEM_HINTS := lustre
  PNETCDF_PATH := $(PNETCDF_HOME)
  NETCDF_PATH := $(NETCDF_HOME)
  CONFIG_ARGS :=  --host=Linux 
  ifeq ($(MPILIB),impi)
    MPIFC := mpiifort
    MPICC := mpiicc
    MPICXX := mpiicpc
  endif
endif
ifeq ($(COMPILER),pgi)
  PIO_FILESYSTEM_HINTS := lustre
  PNETCDF_PATH := $(PNETCDF_HOME)
  CXX_LIBS := -lstdc++
  NETCDF_PATH :=  $(NETCDF_HOME)
  SUPPORTS_CXX := TRUE
  CONFIG_ARGS :=  --host=Linux 
  CXX_LINKER := FORTRAN
  ifeq ($(MPILIB),impi)
    MPIFC := mpipgf90
    MPICC := mpipgcc
    MPICXX := mpipgcxx
  endif
endif
ifeq ($(COMPILER),intel)
  CPPDEFS := $(CPPDEFS)  -DFORTRANUNDERSCORE -DNO_R16 -DCPRINTEL
  CPPDEFS := $(CPPDEFS)  -DLINUX 
  ifeq ($(compile_threaded),TRUE)
    CFLAGS := $(CFLAGS)  -qopenmp 
  endif
  ifeq ($(DEBUG),FALSE)
    CFLAGS := $(CFLAGS)  -O2 -debug minimal 
    CFLAGS := $(CFLAGS)  -O2 
  endif
  ifeq ($(DEBUG),TRUE)
    CFLAGS := $(CFLAGS)  -O0 -g 
  endif
  ifeq ($(COMP_NAME),gptl)
    CFLAGS := $(CFLAGS)  -DHAVE_SLASHPROC 
  endif
  ifeq ($(compile_threaded),TRUE)
    CXXFLAGS := $(CXXFLAGS)  -qopenmp 
    FFLAGS := $(FFLAGS)  -qopenmp 
  endif
  ifeq ($(DEBUG),TRUE)
    CXXFLAGS := $(CXXFLAGS)  -O0 -g 
    FFLAGS := $(FFLAGS)  -O0 -g -check uninit -check bounds -check pointers -fpe0 -check noarg_temp_created 
    FFLAGS := $(FFLAGS)  -g -traceback  -O0 -fpe0 -check  all -check noarg_temp_created -ftrapuv -init=snan
  endif
  ifeq ($(DEBUG),FALSE)
    CXXFLAGS := $(CXXFLAGS)  -O2 
    FFLAGS := $(FFLAGS)  -O2 -debug minimal 
    FFLAGS := $(FFLAGS)  -O2 
  endif
  ifeq ($(compile_threaded),TRUE)
    LDFLAGS := $(LDFLAGS)  -qopenmp 
  endif
endif
ifeq ($(COMPILER),pgi)
  CPPDEFS := $(CPPDEFS)  -DFORTRANUNDERSCORE -DNO_SHR_VMATH -DNO_R16 -DCPRPGI 
  CPPDEFS := $(CPPDEFS)  -DLINUX 
  ifeq ($(compile_threaded),TRUE)
    FFLAGS := $(FFLAGS)  -mp 
    CFLAGS := $(CFLAGS)  -mp 
  endif
  ifeq ($(DEBUG),TRUE)
    FFLAGS := $(FFLAGS)  -O0 -g -Ktrap=fp -Mbounds -Kieee 
    FFLAGS := $(FFLAGS) -C -Mbounds -traceback -Mchkfpstk -Mchkstk -Mdalign  -Mdepchk  -Mextend -Miomutex -Mrecursive  -Ktrap=fp -O0 -g -byteswapio -Meh_frame
  endif
  ifeq ($(DEBUG),FALSE)
    FFLAGS := $(FFLAGS)  -O2 
    CFLAGS := $(CFLAGS)  -O2 
  endif
  ifeq ($(COMP_NAME),dwav)
    FFLAGS := $(FFLAGS)  -Mnovect 
  endif
  ifeq ($(COMP_NAME),dice)
    FFLAGS := $(FFLAGS)  -Mnovect 
  endif
  ifeq ($(COMP_NAME),dlnd)
    FFLAGS := $(FFLAGS)  -Mnovect 
  endif
  ifeq ($(COMP_NAME),datm)
    FFLAGS := $(FFLAGS)  -Mnovect 
  endif
  ifeq ($(COMP_NAME),docn)
    FFLAGS := $(FFLAGS)  -Mnovect 
  endif
  ifeq ($(COMP_NAME),cam)
    FFLAGS := $(FFLAGS) -Mnovect
  endif
  ifeq ($(COMP_NAME),gptl)
    CFLAGS := $(CFLAGS)  -DHAVE_SLASHPROC 
  endif
  ifeq ($(COMP_NAME),drof)
    FFLAGS := $(FFLAGS)  -Mnovect 
  endif
  ifeq ($(compile_threaded),TRUE)
    LDFLAGS := $(LDFLAGS)  -mp 
  endif
endif
ifeq ($(COMPILER),intel)
  SLIBS :=  -lpmi -L$(NETCDF_PATH)/lib -lnetcdf -lnetcdff -L$(MKL_PATH)/lib/intel64/ -lmkl_rt $(PNETCDF_LIBRARIES)
endif
ifeq ($(COMPILER),pgi)
  SLIBS := $(SLIBS)  -lpmi -L$(NETCDF_PATH)/lib -lnetcdf -lnetcdff -L$(MKL_PATH)/lib/intel64/ -lmkl_rt $(PNETCDF_LIBRARIES) 
endif
