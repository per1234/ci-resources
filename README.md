# ci-resources

Shared resources for continuous integration.

**DEPRECATED**

These scripts have now been replaced by [GitHub Actions](https://github.com/features/actions) actions:

- Code formatting check: [`per1234/artistic-style-action`](https://github.com/per1234/artistic-style-action)
- Sketch compilation check: [`arduino/compile-sketches`](https://github.com/arduino/compile-sketches)

## check-code-formatting.sh
This script checks whether code formatting is compliant with the official Arduino code style.

### Installation
```yaml
- wget --quiet --directory-prefix="$TRAVIS_BUILD_DIR" https://raw.githubusercontent.com/per1234/ci-resources/master/check-code-formatting.sh
- chmod +x "$TRAVIS_BUILD_DIR/check-code-formatting.sh"
```

### Usage
##### `check-code-formatting.sh excludedPathList targetPath`
- **excludedPathList** - Comma separated list of paths to exclude from the check.
- **targetPath** - Path from which to recursively run code formatting checks on all source files.

## compilation-test.sh
This script contains functions for common tasks used for configuring compilation tests of Arduino projects.

### Installation
```
source <(curl -SLs https://raw.githubusercontent.com/per1234/ci-resources/master/compilation-test.sh)
```

### Usage
##### `installCLI [CLIVersion]`
Install arduino-cli.
- **CLIVersion** - The version of arduino-cli to install. If the version is not specified, the latest version will be installed.

##### `installBoards core [additionalBoardsManagerURLs]`
Install a hardware core from the Boards Manager index
- **core** - The ID of the hardware core to install (e.g., `arduino:samd`).
- **additionalBoardsManagerURLs** - The Boards Manager URL of a 3rd party hardware core.

##### `installLibrary [libraryPath [installPath]]`
Do a manual library installation from the local repository
- **libraryPath** - The path of the library to install. If not specified, the library will be installed from the root of the repository.
- **installPath** - The location at which to install the library. If not specified, the library will be installed to the default sketchbook folder (`${HOME}/Arduino/libraries`).

##### `installLibrary libraryIdentifier [branchName [installPath]]`
Do a manual library installation by cloning from a remote repository
- **libraryIdentifier** - The URL of the remote repository.
- **branchName** - The branch, tag, or commit to checkout. If not specified, the latest tag will be checked out.
- **installPath** - The location at which to install the library. If not specified, the library will be installed to the default sketchbook folder (`${HOME}/Arduino/libraries`).

##### `buildExampleSketch sketch board [sketchPath]`
Compile a sketch.
- **sketch** - Sketch name (e.g., Blink).
- **board** - FQBN of the board to compile for (e.g., `arduino:avr:uno`).
- **sketchPath** - Path to the sketch. If not specified, the path is assumed to be `$TRAVIS_BUILD_DIR/examples`.

##### `buildAllExamples board [examplesPath]`
Compile all example sketches.
- **board** - FQBN of the board to compile for (e.g., `arduino:avr:uno`).
- **examplesPath** - Path to the sketches. This path will be searched recursively for sketches. If not specified, the path is assumed to be `$TRAVIS_BUILD_DIR/examples`.
