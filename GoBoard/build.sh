#!/bin/sh
# Build a GoBoard executable target with LLVM coverage instrumentation off.
#
# Xcode's Swift.xcspec emits -profile-coverage-mapping/-profile-generate (and
# Clang.xcspec -fprofile-instr-generate/-fcoverage-mapping) whenever
# CLANG_COVERAGE_MAPPING evaluates YES. That instruments every basic block,
# including all of MLX's hot C++ paths, and makes each run dump a ~4 MB
# default.profraw into the package root on exit.
#
# -enableCodeCoverage NO cannot be used here: xcodebuild only accepts it for
# the test action, not for `build`. Overriding the settings on the command
# line works because that level outranks every other.
set -eu

scheme=${1:?usage: ./build.sh <scheme>   (TrainGoBots, SelfPlay, PlayGoBots, ...)}

exec xcodebuild build \
    -scheme "$scheme" \
    -destination 'platform=macOS' \
    -derivedDataPath .xcodebuild \
    ENABLE_CODE_COVERAGE=NO \
    CLANG_COVERAGE_MAPPING=NO
