#!/bin/bash

# check code files for compliance with Arduino's code formatting standard

readonly excludedPathList="$1"
readonly targetPath="$2"

readonly astyleInstallationFolder="${HOME}/bin"
readonly astyleConfigurationFileFolder="${HOME}/etc/astyle"
readonly astyleConfigurationFileDownloadURL="https://raw.githubusercontent.com/arduino/Arduino/master/build/shared/examples_formatter.conf"
readonly astyleConfigurationFilePath="${astyleConfigurationFileFolder}/examples_formatter.conf"

# Fold the output in the Travis CI log
echo -e 'travis_fold:start:check_code_formatting'

if ! [[ -d "$targetPath" ]]; then
  echo "ERROR: targetPath doesn't exist"
  echo -e 'travis_fold:end:check_code_formatting'
  exit 1
fi

# Assemble the find options for the excluded paths from the list
for excludedPath in ${excludedPathList//,/ }; do
  excludeOptions="$excludeOptions -path $excludedPath -prune -or"
done

astylePath=$(command -v astyle)
if [[ ! -e "$astylePath" ]]; then
  # Install astyle
  # Save the current folder
  readonly previousFolder="$PWD"
  wget --quiet --output-document="/tmp/astyle.tar.gz" "https://iweb.dl.sourceforge.net/project/astyle/astyle/astyle%203.1/astyle_3.1_linux.tar.gz"
  if ! [[ -d "$astyleInstallationFolder" ]]; then
    mkdir --parents "$astyleInstallationFolder"
  fi
  tar --extract --file="/tmp/astyle.tar.gz" --directory="$astyleInstallationFolder"
  if ! cd "${astyleInstallationFolder}/astyle/build/gcc"; then
    echo -e 'travis_fold:end:check_code_formatting'
    exit 1
  fi
  make &>/dev/null
  astylePath="${astyleInstallationFolder}/astyle/build/gcc/bin/astyle"
  # Return to the previous folder
  if ! cd "$previousFolder"; then
    echo -e 'travis_fold:end:check_code_formatting'
    exit 1
  fi
fi

if [[ ! -e "$astyleConfigurationFilePath" ]]; then
  # download Arduino's Artistic Style configuration file
  if ! [[ -d "$astyleConfigurationFileFolder" ]]; then
    mkdir --parents "$astyleConfigurationFileFolder"
  fi
  wget --quiet --output-document="$astyleConfigurationFilePath" $astyleConfigurationFileDownloadURL
fi

# Set default exit status
exitStatus=0

while read -r filename; do
  # Check if it's a file (find matches on pruned folders)
  if [[ -f "$filename" ]]; then
    if ! diff --strip-trailing-cr "$filename" <("${astylePath}" --options="$astyleConfigurationFilePath" --dry-run <"$filename"); then
      echo "ERROR: Non-compliant code formatting in $filename"
      # Make the function fail
      exitStatus=1
    fi
  fi
done <<<"$(eval "find $targetPath -regextype posix-extended $excludeOptions \( -iregex '.*\.((ino)|(h)|(hpp)|(hh)|(hxx)|(h\+\+)|(cpp)|(cc)|(cxx)|(c\+\+)|(cp)|(c)|(ipp)|(ii)|(ixx)|(inl)|(tpp)|(txx)|(tpl))$' -and -type f \)")"

echo -e 'travis_fold:end:check_code_formatting'
exit "$exitStatus"
