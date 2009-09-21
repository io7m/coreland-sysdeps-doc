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
IFS="
"
cat <<EOF
(table cctypes
  (t-row
    (item "Value")
    (item "Description")
    (item "URL"))
EOF

LINE=1
for line in `cat ${SYSDEPS_SOURCE}/GENERATION/cctype.txt`
do
  cc_type="SD_SYSINFO_CCTYPE_`echo ${line} | awk '{print $2}'`"
  desc_line=`sed -e "${LINE}q;d" < ${SYSDEPS_SOURCE}/GENERATION/cctype_desc.txt`
  desc=`echo ${desc_line} | awk -F\| '{print $2}'`
  url=`echo ${desc_line}  | awk -F\| '{print $3}'`

  cat <<EOF
  (t-row
    (item (item constant "${cc_type}"))
    (item "${desc}")
    (item (link-ext "${url}")))
EOF
  LINE=`expr ${LINE} + 1`
done
echo ")"
) > src/dd-comp-cctype-table.ud ||
  fatal "could not write src/dd-comp-cctype-table.ud"
