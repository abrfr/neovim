#!/bin/bash

echo "\$ ./scripts/bump-deps.sh --dep LuaJIT --HEAD"
./scripts/bump-deps.sh --dep LuaJIT --HEAD

echo "\$ ./scripts/bump-deps.sh --dep libuv --commit c40f8cb9f8ddf69d116952f8924a11ec0623b444"
./scripts/bump-deps.sh --dep libuv --commit c40f8cb9f8ddf69d116952f8924a11ec0623b444

echo "\$ ./scripts/bump-deps.sh --dep libuv --commit c40f8cb9f8ddf69d116952f8924a11ec0623b445"
./scripts/bump-deps.sh --dep libuv --commit c40f8cb9f8ddf69d116952f8924a11ec0623b445

echo "\$ ./scripts/bump-deps.sh --dep tree-sitter --version v0.20.0"
./scripts/bump-deps.sh --dep tree-sitter --version v0.20.0

echo "\$ ./scripts/bump-deps.sh --dep luv --commit 9d602ab12654d3adb53f34457390f534eb85f5d6"
./scripts/bump-deps.sh --dep luv --commit 9d602ab12654d3adb53f34457390f534eb85f5d6

echo "\$ ./scripts/bump-deps.sh --dep Luv --commit 9d602ab12654d3adb53f34457390f534eb85f5d6"
./scripts/bump-deps.sh --dep Luv --commit 9d602ab12654d3adb53f34457390f534eb85f5d6

echo "\$ ./scripts/bump-deps.sh --pr"
./scripts/bump-deps.sh --pr
