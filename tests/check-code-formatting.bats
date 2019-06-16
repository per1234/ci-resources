#!/usr/bin/env bats

# nonexistent targetPath
@test "../check-code-formatting.sh \"\" \"./nonexistent-path\"" {
  expectedExitStatus=1
  run ../check-code-formatting.sh "" "./nonexistent-path"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ $status -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 3 ]
  outputRegex="^ERROR: targetPath doesn't exist$"
  [[ "${lines[1]}" =~ $outputRegex ]]
}

# non-compliant code formatting
@test "../check-code-formatting.sh \"\" \"./check-code-formatting/non-compliant\"" {
  expectedExitStatus=1
  run ../check-code-formatting.sh "" "./check-code-formatting/non-compliant"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ $status -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 12 ]
  outputRegex="^> void foo\(\) \{}$"
  [[ "${lines[4]}" =~ $outputRegex ]]
  outputRegex="^ERROR: Non-compliant code formatting in \./check-code-formatting/non-compliant/non-compliant\.cpp$"
  [[ "${lines[5]}" =~ $outputRegex ]]
  outputRegex="^ERROR: Non-compliant code formatting in \./check-code-formatting/non-compliant/subfolder/non-compliant\.h$"
  [[ "${lines[10]}" =~ $outputRegex ]]
}

# non-compliant code formatting in subfolder of targetPath
@test "../check-code-formatting.sh \"\" \"./check-code-formatting/compliant\"" {
  expectedExitStatus=1
  run ../check-code-formatting.sh "" "./check-code-formatting/compliant"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ $status -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 7 ]
  outputRegex="^ERROR: Non-compliant code formatting in \./check-code-formatting/compliant/excluded-non-compliant/non-compliant\.h$"
  [[ "${lines[5]}" =~ $outputRegex ]]
}

# exclude subfolder with non-compliant code
@test "../check-code-formatting.sh \"./check-code-formatting/compliant/excluded-non-compliant\" \"./check-code-formatting/compliant\"" {
  expectedExitStatus=0
  run ../check-code-formatting.sh "./check-code-formatting/compliant/excluded-non-compliant" "./check-code-formatting/compliant"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ $status -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 2 ]
}
