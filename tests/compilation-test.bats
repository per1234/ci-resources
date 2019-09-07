#!/usr/bin/env bats

source ../compilation-test.sh

# install arduino-cli 0.4.0
@test "installCLI '0.4.0'" {
  expectedExitStatus=0
  run installCLI '0.4.0'
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ $status -eq $expectedExitStatus ]
  expectedExitStatus=0
  run arduino-cli version
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ $status -eq $expectedExitStatus ]
}

# install latest version of arduino-cli
@test "installCLI" {
  expectedExitStatus=0
  run installCLI
  run arduino-cli version
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ $status -eq $expectedExitStatus ]
}

# install Arduino SAMD Boards
@test "installBoards 'arduino:samd'" {
  expectedExitStatus=0
  run installBoards 'arduino:samd'
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ $status -eq $expectedExitStatus ]
  expectedExitStatus=0
  run arduino-cli compile --fqbn arduino:samd:mkrzero ./compilation-test/all-compile/Compiles1
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ $status -eq $expectedExitStatus ]
}

# install MicroCore
@test "installBoards 'MicroCore:avr' 'https://mcudude.github.io/MicroCore/package_MCUdude_MicroCore_index.json'" {
  expectedExitStatus=0
  # MicroCore has a dependency on Arduino AVR Boards
  run installBoards 'arduino:avr'
  run installBoards 'MicroCore:avr' 'https://mcudude.github.io/MicroCore/package_MCUdude_MicroCore_index.json'
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ $status -eq $expectedExitStatus ]
  expectedExitStatus=0
  run arduino-cli compile --fqbn MicroCore:avr:attiny13 ./compilation-test/all-compile/Compiles1
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ $status -eq $expectedExitStatus ]
}

# install a library from this repository
@test "installLibrary \"\${PWD}/compilation-test/TestLibrary\"" {
  expectedExitStatus=0
  run installLibrary "${PWD}/compilation-test/TestLibrary"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ $status -eq $expectedExitStatus ]
  expectedExitStatus=0
  run arduino-cli compile --fqbn arduino:samd:mkrzero "${HOME}/Arduino/libraries/TestLibrary/examples/TestLibraryExample"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ $status -eq $expectedExitStatus ]
}

# install a library from a non-existent folder of this repository
@test "installLibrary \"${PWD}/doesnt-exist\"" {
  expectedExitStatus=1
  run installLibrary "${PWD}/doesnt-exist"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ $status -eq $expectedExitStatus ]
  outputRegex='^ERROR: /home/travis/build/per1234/ci-resources/tests/doesnt-exist does not exist$'
  [[ "${lines[0]}" =~ $outputRegex ]]
}

# build an example sketch that compiles
@test "buildExampleSketch 'Compiles1' 'arduino:samd:mkrzero' './compilation-test/all-compile'" {
  expectedExitStatus=0
  run buildExampleSketch 'Compiles1' 'arduino:samd:mkrzero' './compilation-test/all-compile'
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ $status -eq $expectedExitStatus ]
}

# build an example sketch that doesn't compile
@test "buildExampleSketch 'Fails' 'arduino:samd:mkrzero' './compilation-test/not-all-compile/subfolder'" {
  expectedExitStatus=1
  run buildExampleSketch 'Fails' 'arduino:samd:mkrzero' './compilation-test/not-all-compile/subfolder'
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ $status -eq $expectedExitStatus ]
}

# build an example sketch that doesn't exist
@test "buildExampleSketch 'DoesntExist' 'arduino:samd:mkrzero' './compilation-test/not-all-compile'" {
  expectedExitStatus=1
  run buildExampleSketch 'DoesntExist' 'arduino:samd:mkrzero' './compilation-test/not-all-compile'
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ $status -eq $expectedExitStatus ]
  outputRegex='^ERROR: \./compilation-test/not-all-compile/DoesntExist does not exist$'
  [[ "${lines[0]}" =~ $outputRegex ]]
}

# build all example sketches (all compile)
@test "buildAllExamples 'arduino:samd:mkrzero' './compilation-test/all-compile'" {
  expectedExitStatus=0
  run buildAllExamples 'arduino:samd:mkrzero' './compilation-test/all-compile'
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ $status -eq $expectedExitStatus ]
}

# build all example sketches (one doesn't compile)
@test "buildAllExamples 'arduino:samd:mkrzero' './compilation-test/not-all-compile'" {
  expectedExitStatus=1
  run buildAllExamples 'arduino:samd:mkrzero' './compilation-test/not-all-compile'
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ $status -eq $expectedExitStatus ]
}

# build all example sketches (specified folder doesn't exist)
@test "buildAllExamples 'arduino:samd:mkrzero' './compilation-test/doesnt-exist'" {
  expectedExitStatus=1
  run buildAllExamples 'arduino:samd:mkrzero' './compilation-test/doesnt-exist'
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ $status -eq $expectedExitStatus ]
  outputRegex='^ERROR: \./compilation-test/doesnt-exist does not exist$'
  [[ "${lines[0]}" =~ $outputRegex ]]
}

# build all example sketches (no sketches in folder)
@test "buildAllExamples 'arduino:samd:mkrzero' './compilation-test/no-sketches'" {
  expectedExitStatus=1
  run buildAllExamples 'arduino:samd:mkrzero' './compilation-test/no-sketches'
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ $status -eq $expectedExitStatus ]
  outputRegex='^ERROR: No sketches found in \./compilation-test/no-sketches$'
  [[ "${lines[0]}" =~ $outputRegex ]]
}
