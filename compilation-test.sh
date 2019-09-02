#!/bin/bash

# functions for common tasks involved in compilation testing of Arduino sketches in Travis CI builds

WORKING_DIR="$TRAVIS_BUILD_DIR"
if [[ "$WORKING_DIR" == "" ]]; then
  WORKING_DIR="$PWD"
fi

# install arduino-cli
function installCLI() {
  local -r CLIVersion="$1"

  local -r CLIInstallationFolder="${HOME}/bin"
  mkdir -p "$CLIInstallationFolder"

  if [[ "$CLIVersion" == "latest" || "$CLIVersion" == "" ]]; then
    curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | BINDIR="$CLIInstallationFolder" sh
  else
    local -r previousFolder="$PWD"
    cd "$CLIInstallationFolder" || return 1
    wget "https://github.com/arduino/arduino-cli/releases/download/${CLIVersion}/arduino-cli_${CLIVersion}_Linux_64bit.tar.gz"
    tar --extract --file="arduino-cli_${CLIVersion}_Linux_64bit.tar.gz"
    cd "${previousFolder}" || return 1
  fi

  export PATH="$PATH:${CLIInstallationFolder}"
}

# install a hardware core from the Boards Manager index
function installBoards() {
  local -r core="$1"
  local -r additionalBoardsManagerURLs="$2"

  if [[ "$additionalBoardsManagerURLs" == "" ]]; then
    # no additional URLs were specified
    arduino-cli core update-index
    arduino-cli core install "$core"
  else
    arduino-cli core update-index --additional-urls "$additionalBoardsManagerURLs"
    arduino-cli core install "$core" --additional-urls "$additionalBoardsManagerURLs"
  fi
}

# do a manual library installation to the sketchbook folder (usually used to install the library from the repository)
function installLibrary() {
  # the current location of the library
  local libraryPath="$1"
  local sketchbookPath="$2"

  if [[ "$libraryPath" == "" ]]; then
    # use default library location
    libraryPath="${WORKING_DIR}"
  fi

  if [[ "$sketchbookPath" == "" ]]; then
    # use default sketchbook folder
    sketchbookPath="${HOME}/Arduino"
  fi

  if [[ ! -d "$libraryPath" ]]; then
    echo ERROR: "$libraryPath" does not exist
    return 1
  fi

  mkdir --parents "${sketchbookPath}/libraries"
  ln --symbolic "$libraryPath" "${sketchbookPath}/libraries/."
}

# compile an example sketch
function buildExampleSketch() {
  local -r sketch="$1"
  local -r board="$2"
  local sketchPath="$3"

  if [[ "$sketchPath" == "" ]]; then
    # use default examples folder
    sketchPath="${WORKING_DIR}/examples"
  fi

  if [[ ! -d "${sketchPath}/${sketch}" ]]; then
    echo ERROR: "${sketchPath}/${sketch}" does not exist
    return 1
  fi

  arduino-cli compile --verbose --warnings all --fqbn "$board" "${sketchPath}/${sketch}"
}

# compile all example sketches
function buildAllExamples() {
  local -r board="$1"
  local examplesPath="$2"

  if [[ "$examplesPath" == "" ]]; then
    # use default examples folder
    examplesPath="${WORKING_DIR}/examples"
  fi

  if [[ ! -d "$examplesPath" ]]; then
    echo ERROR: "$examplesPath" does not exist
    return 1
  fi

  # set the default return value
  local exitStatus=0

  local sketchFound=false

  # find all folders that contain a sketch file
  while read -r examplePath; do
    # the while loop always runs once, even when no sketches were found in $examplesPath
    if [[ "$examplePath" == "" ]]; then
      continue
    fi

    if ! buildExampleSketch "${examplePath##*/}" "$board" "$examplesPath"; then
      # the sketch build failed
      exitStatus=1
    fi

    # at least one sketch was found
    sketchFound=true
  done <<<"$(find "$examplesPath" -type f \( -iname '*.ino' -or -iname '*.pde' \) -printf '%h\n' | sort --unique)"

  if [[ $sketchFound == false ]]; then
    echo ERROR: No sketches found in "$examplesPath"
    return 1
  fi

  return $exitStatus
}
