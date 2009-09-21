#!/bin/sh

fatal()
{
  echo "fatal: $1" 1>&2
  exit 1
}

SYSDEPS_SOURCE="$HOME/git/coreland/sysdeps"

# Create sd-arch output.
(
echo 'SD_SYSINFO_ARCH_UNKNOWN'
awk '{printf "SD_SYSINFO_ARCH_%s\n",$2}' < ${SYSDEPS_SOURCE}/GENERATION/arch.txt
) > src/dd-comp-arch.txt || fatal "could not write src/dd-comp-arch.txt"

# Create sd-cctype output.
(
echo 'SD_SYSINFO_CCTYPE_UNKNOWN'
awk '{printf "SD_SYSINFO_CCTYPE_%s\n",$2}' < ${SYSDEPS_SOURCE}/GENERATION/cctype.txt
) > src/dd-comp-cctype.txt || fatal "could not write src/dd-comp-cctype.txt"

