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

# do a manual library installation
function installLibrary() {
  local -r libraryIdentifier="$1"

  local -r URLregex="://"
  if [[ "$libraryIdentifier" =~ $URLregex ]]; then
    # install the library from a clone of a remote repository
    # note: this assumes the library is in the root of the repository

    # this can be branch, tag, or commit hash
    local -r branchName="$2"
    # used to customize sketchbook location or library folder name
    local installPath="$3"

    if [[ "$installPath" == "" ]]; then
      # use default sketchbook folder and library folder name
      # get the last part of the URL
      local libraryFolder="${libraryIdentifier##*/}"
      # strip the .git from the end of the extracted string, if present
      libraryFolder="${libraryFolder%.*}"
      installPath="${HOME}/Arduino/libraries/${libraryFolder}"
    fi

    if [[ "$branchName" == "" || "$branchName" == "latest" ]]; then
      git clone --quiet "$libraryIdentifier" "$installPath"
      if [[ "$branchName" == "latest" ]]; then
        # checkout the latest tag of the repository
        local -r previousFolder="$PWD"
        cd "$installPath" || return 1
        # get new tags from the remote
        git fetch --tags
        # checkout the latest tag
        git checkout "$(git describe --tags "$(git rev-list --tags --max-count=1)")"
        cd "$previousFolder" || return 1
      fi
    else
      git clone --quiet --branch "$branchName" "$libraryIdentifier" "$installPath"
    fi

  else
    # install the library from this repository
    # the current location of the library
    local libraryPath="$1"
    local installPath="$2"

    if [[ "$libraryPath" == "" ]]; then
      # use default library location
      libraryPath="${WORKING_DIR}"
    elif [[ ! -d "$libraryPath" ]]; then
      echo ERROR: "$libraryPath" does not exist
      return 1
    fi

    if [[ "$installPath" == "" ]]; then
      # use default sketchbook and library folder
      local -r librariesPath="${HOME}/Arduino/libraries"
      installPath="${librariesPath}/."
    else
      # use custom sketchbook and library folder
      local -r librariesPath="${installPath%%/libraries/*}/libraries"
    fi

    mkdir --parents "$librariesPath"
    ln --symbolic "$libraryPath" "$installPath"
  fi
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

# Extract common file formats
# https://github.com/xvoland/Extract
function extract() {
  if [ -z "$1" ]; then
    # display usage if no parameters given
    echo "Usage: extract <path/file_name>.<zip|rar|bz2|gz|tar|tbz2|tgz|Z|7z|xz|ex|tar.bz2|tar.gz|tar.xz>"
    echo "       extract <path/file_name_1.ext> [path/file_name_2.ext] [path/file_name_3.ext]"
  else
    for n in "$@"; do
      if [ -f "$n" ]; then
        case "${n%,}" in
        *.cbt | *.tar.bz2 | *.tar.gz | *.tar.xz | *.tbz2 | *.tgz | *.txz | *.tar)
          tar xvf "$n"
          ;;
        *.lzma) unlzma ./"$n" ;;
        *.bz2) bunzip2 ./"$n" ;;
        *.cbr | *.rar) unrar x -ad ./"$n" ;;
        *.gz) gunzip ./"$n" ;;
        *.cbz | *.epub | *.zip) unzip ./"$n" ;;
        *.z) uncompress ./"$n" ;;
        *.7z | *.apk | *.arj | *.cab | *.cb7 | *.chm | *.deb | *.dmg | *.iso | *.lzh | *.msi | *.pkg | *.rpm | *.udf | *.wim | *.xar)
          7z x ./"$n"
          ;;
        *.xz) unxz ./"$n" ;;
        *.exe) cabextract ./"$n" ;;
        *.cpio) cpio -id <./"$n" ;;
        *.cba | *.ace) unace x ./"$n" ;;
        *.zpaq) zpaq x ./"$n" ;;
        *.arc) arc e ./"$n" ;;
        *.cso) ciso 0 ./"$n" ./"$n.iso" &&
          extract "$n.iso" && \rm -f "$n" ;;
        *)
          echo "extract: '$n' - unknown archive method"
          return 1
          ;;
        esac
      else
        echo "'$n' - file does not exist"
        return 1
      fi
    done
  fi
}
