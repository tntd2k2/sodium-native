cmake_minimum_required(VERSION 3.12)
cmake_policy(SET CMP0042 NEW)
set(CMAKE_SUPPRESS_REGENERATION true)

project (sodium-native)

set(src_dir ${PROJECT_SOURCE_DIR}/src)
set(libsodium_dir ${PROJECT_SOURCE_DIR}/zig-out)

include_directories(
	${CMAKE_JS_INC}
	${libsodium_dir}/include
)
file(GLOB napi_sources "${src_dir}/binding.c")
file(GLOB libsodium "${libsodium_dir}/lib/*")
add_library(${PROJECT_NAME} SHARED ${napi_sources} ${CMAKE_JS_SRC})
target_link_libraries(${PROJECT_NAME}
	${CMAKE_JS_LIB}
	${libsodium}
)
set_target_properties(${PROJECT_NAME} PROPERTIES PREFIX "" SUFFIX ".node")
# add_definitions(-DNAPI_VERSION=3)
# #endregion napi