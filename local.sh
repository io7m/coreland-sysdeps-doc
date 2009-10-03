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
) > src/dd-comp-cpufeat-table.ud || fatal "could not write src/dd-comp-cpufeat-table.ud"

#
# Create OS description table.
#
(
IFS="
"
cat <<EOF
(table oses
  (t-row
    (item "Value")
    (item "Description")
    (item "URL"))
EOF

LINE=1
for line in `cat ${SYSDEPS_SOURCE}/GENERATION/os.txt`
do
  os_type="SD_SYSINFO_ARCH_`echo ${line} | awk '{print $2}'`"
  desc_line=`sed -e "${LINE}q;d" < ${SYSDEPS_SOURCE}/GENERATION/os_desc.txt`
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
    (item (item constant "${os_type}"))
    (item "${desc}")
    (item ${item}))
EOF
  LINE=`expr ${LINE} + 1`
done
echo ")"
) > src/dd-comp-os-table.ud || fatal "could not write src/dd-comp-os-table.ud"

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
) > src/dd-comp-arch-table.ud || fatal "could not write src/dd-comp-arch-table.ud"

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
) > src/dd-comp-cctype-table.ud || fatal "could not write src/dd-comp-cctype-table.ud"

#
# Copy images.
#

cp src/*.png release || fatal "could not copy images"

#
# Write variable lists.
#

variables_exported()
{
  SOURCE="$1"
  OUTPUT="$2"

  VARIABLES=`grep 'export' ${SYSDEPS_SOURCE}/${SOURCE} | sort | uniq | sed 's/export //g'` ||
    fatal "could not read ${SYSDEPS_SOURCE}/${SOURCE}"

  (
    exec 1>"${OUTPUT}.tmp"
    echo "(list" || exit 1
    for VAR in ${VARIABLES}
    do
      echo "(item (link \"dd_env_${VAR}\" \"${VAR}\"))" || exit 1
    done
    echo ")"
  ) || fatal "could not write ${OUTPUT}.tmp"

  mv "${OUTPUT}.tmp" "${OUTPUT}" || fatal "could not write ${OUTPUT}"
}

variables_used()
{
  SOURCE="$1"
  EXPORTED="$2"
  OUTPUT="$3"

  VARIABLES=`egrep -o '\\${SYSDEP_[A-Z_]+}' ${SYSDEPS_SOURCE}/${SOURCE} |
    tr -d '${}' | sort | uniq | sort` ||
      fatal "could not read ${SYSDEPS_SOURCE}/${SOURCE}"

  echo "(list" >> "${OUTPUT}.tmp" || fatal "could not write ${OUTPUT}.tmp"
  for VAR in ${VARIABLES}
  do
    grep "${VAR}" "${EXPORTED}" 1>/dev/null
    case $? in
      0) ;;
      1) echo "(item (link \"dd_env_${VAR}\" \"${VAR}\"))" >> "${OUTPUT}.tmp" ||
        fatal "could not write ${OUTPUT}.tmp" ;;
      *) fatal "error searching for variable" ;;
    esac
  done
  echo ")" >> "${OUTPUT}.tmp" || fatal "could not write ${OUTPUT}.tmp"

  mv "${OUTPUT}.tmp" "${OUTPUT}" || fatal "could not write ${OUTPUT}"
}

variables_exported SYSDEPS/sysdep-boot src/dd-core-boot-postcon.txt
variables_used     SYSDEPS/sysdep-boot src/dd-core-boot-postcon.txt src/dd-core-boot-precon.txt

variables_exported SYSDEPS/sysdep-subs src/dd-core-subs-postcon.txt
variables_used     SYSDEPS/sysdep-subs src/dd-core-subs-postcon.txt src/dd-core-subs-precon.txt

variables_exported SYSDEPS/sysdep-compilers src/dd-core-compilers-postcon.txt
variables_used     SYSDEPS/sysdep-compilers src/dd-core-compilers-postcon.txt src/dd-core-compilers-precon.txt

variables_exported SYSDEPS/sysdep-system src/dd-core-system-postcon.txt
variables_used     SYSDEPS/sysdep-system src/dd-core-system-postcon.txt src/dd-core-system-precon.txt

#
# Write documentation for environment variables.
#

(
IFS="
"
for line in `cat ${SYSDEPS_SOURCE}/GENERATION/environ.txt`
do
  var=`echo ${line} | awk -F\| '{print $1}' | tr -d ' '`
  type=`echo ${line} | awk -F\| '{print $2}' | tr -d ' '`
  val=`echo ${line} | awk -F\| '{print $3}'`
  desc=`echo ${line} | awk -F\| '{print $NF}'`

  case ${type} in
    version) type="(link \"dd_type_version\" \"${type}\")" ;;
    os-type) type="(link \"dd_type_os\"      \"${type}\")" ;;
    cc-type) type="(link \"dd_type_cc\"      \"${type}\")" ;;
    arch)    type="(link \"dd_type_arch\"    \"${type}\")" ;;
    *)       type="\"${type}\""                            ;;
  esac

  cat <<EOF
  (subsection
    (ref "dd_env_${var}")
    (title "${var}")
    (para example (item variable "${var}") " : " ${type})
    (para "${desc}.")
    (para "Example value:")
    (para-verbatim example "${val}"))
EOF
done
) > src/dd-env-sections.ud || fatal "could not write src/dd-env-sections.ud"

#
# Create source for all modules.
#

rm -f src/mr.ud.tmp || fatal "could not remove src/mr.ud.tmp"

cat >> src/mr.ud.tmp << EOF
(section
  (title "Module Reference")
  (contents)

EOF

for module_path in `ls ${SYSDEPS_SOURCE}/SYSDEPS/modules`
do
  module=`basename ${module_path}` || fatal "could not retrieve module name"

  ./local-mk-module.sh "${module_path}" > "src/mr-${module}.ud.tmp" ||
    fatal "could not write src/mr-${module}.ud.tmp"
  mv "src/mr-${module}.ud.tmp" "src/mr-${module}.ud" ||
    fatal "could not write src/mr-${module}.ud"

  echo "  (include \"mr-${module}.ud\")" >> src/mr.ud.tmp ||
    fatal "could not write src/mr.ud.tmp"
done

echo ")" >> src/mr.ud.tmp || 
  fatal "could not write src/mr.ud.tmp"
mv src/mr.ud.tmp src/mr.ud ||
  fatal "could not write src/mr.ud"
