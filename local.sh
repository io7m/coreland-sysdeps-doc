#!/bin/sh

fatal()
{
  echo "fatal: $1" 1>&2
  exit 1
}

SYSDEPS_SOURCE="$HOME/git/coreland/sysdeps"

#
# Create CPU extension description table.
#
(
IFS="
"
cat <<EOF
(table arches
  (t-row
    (item "Value")
    (item "Description"))
EOF

LINE=1
for line in `cat ${SYSDEPS_SOURCE}/GENERATION/cpu_ext.txt`
do
  ext_type="SD_SYSINFO_CPU_EXT_`echo ${line} | awk '{print $2}'`"
  desc=`echo ${line} | awk -F\| '{print $2}'`

  cat <<EOF
  (t-row
    (item (item constant "${ext_type}"))
    (item "${desc}"))
EOF
  LINE=`expr ${LINE} + 1`
done
echo ")"
) > src/dd-comp-cpufeat-table.ud ||
  fatal "could not write src/dd-comp-cpufeat-table.ud"

#
# Create architecture description table.
#
(
IFS="
"
cat <<EOF
(table arches
  (t-row
    (item "Value")
    (item "Description")
    (item "URL"))
EOF

LINE=1
for line in `cat ${SYSDEPS_SOURCE}/GENERATION/arch.txt`
do
  arch_type="SD_SYSINFO_ARCH_`echo ${line} | awk '{print $2}'`"
  desc_line=`sed -e "${LINE}q;d" < ${SYSDEPS_SOURCE}/GENERATION/arch_desc.txt`
  desc=`echo ${desc_line} | awk -F\| '{print $2}'`
  url=`echo ${desc_line}  | awk -F\| '{print $3}' | tr -d ' '`

  if [ "${url}" = "n/a" ]
  then
    item="\"n/a\""
  else
    item="(link-ext \"${url}\")"
  fi

  cat <<EOF
  (t-row
    (item (item constant "${arch_type}"))
    (item "${desc}")
    (item ${item}))
EOF
  LINE=`expr ${LINE} + 1`
done
echo ")"
) > src/dd-comp-arch-table.ud ||
  fatal "could not write src/dd-comp-arch-table.ud"

#
# Create sd-cctype output.
#
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
  url=`echo ${desc_line}  | awk -F\| '{print $3}' | tr -d ' '`

  if [ "${url}" = "n/a" ]
  then
    item="\"n/a\""
  else
    item="(link-ext \"${url}\")"
  fi

  cat <<EOF
  (t-row
    (item (item constant "${cc_type}"))
    (item "${desc}")
    (item ${item}))
EOF
  LINE=`expr ${LINE} + 1`
done
echo ")"
) > src/dd-comp-cctype-table.ud ||
  fatal "could not write src/dd-comp-cctype-table.ud"
