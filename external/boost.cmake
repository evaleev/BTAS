# -*- mode: cmake -*-

# Limit scope of the search if BOOST_ROOT or BOOST_INCLUDEDIR is provided.
if (BOOST_ROOT OR BOOST_INCLUDEDIR)
  set(Boost_NO_SYSTEM_PATHS TRUE)
endif()
  
# Check for Boost
find_package(Boost 1.33 COMPONENTS serialization)

if (Boost_FOUND)

  # Perform a compile check with Boost
  list(APPEND CMAKE_REQUIRED_INCLUDES ${Boost_INCLUDE_DIR})
  list(APPEND CMAKE_REQUIRED_LIBRARIES ${Boost_LIBRARIES})

  CHECK_CXX_SOURCE_RUNS(
      "
      #define BOOST_TEST_MAIN main_tester
      #include <boost/test/included/unit_test.hpp>
      
      #include <fstream>
      #include <cstdio>
      #include <boost/archive/text_oarchive.hpp>
      #include <boost/archive/text_iarchive.hpp>
      
      class A {
        public:
          A() : a_(0) {}
          A(int a) : a_(a) {}
          bool operator==(const A& other) const {
            return a_ == other.a_;
          }
        private:
          int a_;
          
          friend class boost::serialization::access;
          template<class Archive>
          void serialize(Archive & ar, const unsigned int version)
          {
            ar & a_;
          }
      };

      BOOST_AUTO_TEST_CASE( tester )
      {
        BOOST_CHECK( true );
        
        A i(1);
        const char* fname = \"tmp.boost\";
        std::ofstream ofs(fname);
        {
          boost::archive::text_oarchive oa(ofs);
          oa << i;
        }
        {
          std::ifstream ifs(fname);
          boost::archive::text_iarchive ia(ifs);
          A i_restored;
          ia >> i_restored;
          BOOST_CHECK(i == i_restored);
          remove(fname);
        }
      }
      "  BOOST_COMPILES_AND_RUNS)

  if (NOT BOOST_COMPILES_AND_RUNS)
    message(FATAL_ERROR "Boost found at ${BOOST_ROOT}, but could not compile and/or run test program")
  endif()
  
elseif(BTAS_EXPERT)

  message("** BOOST was not explicitly set")
  message(FATAL_ERROR "** Downloading and building Boost is explicitly disabled in EXPERT mode")

else()

  # compiling boost properly is too hard ... ask to come back
  message("** BOOST was not explicitly set")
  message(WARNING "** Downloading and building Boost automatically is not supported, will disable unit tests")
  set(BTAS_BUILD_UNITTEST OFF)
  
endif()

# Set the  build variables
include_directories(${Boost_INCLUDE_DIRS})
