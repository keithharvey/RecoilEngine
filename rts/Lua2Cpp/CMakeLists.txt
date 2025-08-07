cmake_minimum_required(VERSION 3.15)
project(Lua2Cpp LANGUAGES CXX)

# Find LLVM and Clang
find_package(LLVM REQUIRED CONFIG)
find_package(Clang REQUIRED CONFIG)

message(STATUS "Found LLVM ${LLVM_PACKAGE_VERSION}")
message(STATUS "Using LLVMConfig.cmake in: ${LLVM_DIR}")

# Set C++ standard
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# LLVM/Clang include directories and definitions
include_directories(${LLVM_INCLUDE_DIRS})
include_directories(${CLANG_INCLUDE_DIRS})
add_definitions(${LLVM_DEFINITIONS})

# Source files
set(LUA2CPP_SOURCES
    Lua2CppCompiler.h
    LuaAST.h
    CppCodeGenerator.h
)

# Create the Lua2Cpp library (header-only for now)
add_library(lua2cpp INTERFACE)
target_include_directories(lua2cpp INTERFACE ${CMAKE_CURRENT_SOURCE_DIR})
target_link_libraries(lua2cpp INTERFACE
    LLVM
    clangAST
    clangBasic
    clangFrontend
    clangParse
    clangSema
    clangCodeGen
)

# Example: build a test executable if desired
add_executable(lua2cpp_example
    ../../examples/lua2cpp_example.lua
    ../../examples/lua2cpp_output.cpp
)
target_link_libraries(lua2cpp_example PRIVATE lua2cpp)

# Optionally, link against more LLVM/Clang components as needed
# target_link_libraries(lua2cpp_example PRIVATE LLVM clangTooling clangRewrite clangSerialization)

# Installation (optional)
# install(TARGETS lua2cpp_example DESTINATION bin) 