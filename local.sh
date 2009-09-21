#!/bin/sh

fatal()
{
  echo "fatal: $1" 1>&2
  exit 1
}

SYSDEPS_SOURCE="$HOME/git/coreland/sysdeps"

# Create sd-arch output.
(
echo 'UNKNOWN'
awk '{print $2}' < ${SYSDEPS_SOURCE}/GENERATION/arch.txt
) > src/dd-comp-arch.txt || fatal "could not write src/dd-comp-arch.txt"
