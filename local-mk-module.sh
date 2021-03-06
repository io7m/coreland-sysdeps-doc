#!/bin/sh

fatal()
{
  echo "fatal: $1" 1>&2
  exit 1
}

if [ $# -ne 1 ]
then
  echo "usage: module" 1>&2
  exit 1
fi

dir=$1

shift

module=`basename ${dir}`       || fatal "could not retrieve module name"
synopsis=`cat ${dir}/synopsis` || fatal "could not read ${dir}/synopsis"

cat <<EOF
(section
  (ref "r_mr_${module}")
  (title "${module}")

  (subsection
    (title "Synopsis")
    (para "${synopsis}"))

  (subsection
    (title "Description")
EOF
cat ${dir}/description.ud || fatal "could not read ${dir}/description.ud"

if [ -f "${dir}/config_bin" ]
then
  config_bin=`head -n 1 ${dir}/config_bin`           || fatal "could not read ${dir}/config_bin"
  config_bin_args=`head -n 1 ${dir}/config_bin_args` || fatal "could not read ${dir}/config_bin_args"

  cat <<EOF
    (para "The module will attempt to execute the following command in order
      to retrieve the desired information from the environment:")
    (para-verbatim example "${config_bin} ${config_bin_args}")
EOF
fi

if [ -f "${dir}/pkg" ]
then
  pkg=`head -n 1 ${dir}/pkg`                         || fatal "could not read ${dir}/pkg"
  pkg_config_args=`head -n 1 ${dir}/pkg_config_args` || fatal "could not read ${dir}/pkg_config_args"

  cat <<EOF
    (para "The module will attempt to execute the following "
      (item command "pkg-config") " command in order
      to retrieve the desired information from the environment:")
    (para-verbatim example "pkg-config ${pkg_config_args} ${pkg}")
EOF
fi

if [ -f "${dir}/header" ]
then
  header=`head -n 1 ${dir}/header` || fatal "could not read ${dir}/header"

  cat <<EOF
    (para "The module will attempt to manually search for the following
      C header file:")
    (para (item file_name "${header}"))
EOF
fi

if [ -f "${dir}/dynamic_lib" ]
then
  dynamic_lib=`head -n 1 ${dir}/dynamic_lib` || fatal "could not read ${dir}/dynamic_lib"

  cat <<EOF
    (para "The module will attempt to manually search for a dynamic library
      with a base name matching \"" (item file_name "${dynamic_lib}") "\".")
    (para "Platform-specific variations such as file suffixes and prefixes
      are automatically accounted for.")
EOF
fi

if [ -f "${dir}/static_lib" ]
then
  static_lib=`head -n 1 ${dir}/static_lib` || fatal "could not read ${dir}/static_lib"

  cat <<EOF
    (para "The module will attempt to manually search for a static library
      with a base name matching \"" (item file_name "${static_lib}") "\".")
    (para "Platform-specific variations such as file suffixes and prefixes
      are automatically accounted for.")
EOF
fi

cat <<EOF
  )

EOF

if [ -d "${dir}/os_ext" ]
then
  cat <<EOF
  (subsection
    (title "System Specifics")
EOF

  for SYSDEP_OS in `ls "${dir}/os_ext"`
  do
    cat <<EOF
      (subsection
        (title "${SYSDEP_OS}")
EOF

    if [ -f "${dir}/os_ext/${SYSDEP_OS}/override" ]
    then
      override=`head -n 1 ${dir}/os_ext/${SYSDEP_OS}/override` ||
        fatal "could not read ${dir}/os_ext/${SYSDEP_OS}/override"

      cat <<EOF
        (para "On systems returning " (item constant "${SYSDEP_OS}") " for "
          (link "dd_env_SYSDEP_OS" "SYSDEP_OS") ", the module will do nothing
          other than simply print:")
        (para-verbatim example "${override}")
EOF
    fi


    if [ -f "${dir}/os_ext/${SYSDEP_OS}/header" ]
    then
      header=`head -n 1 ${dir}/os_ext/${SYSDEP_OS}/header` ||
        fatal "could not read ${dir}/os_ext/${SYSDEP_OS}/header"

      cat <<EOF
        (para "On systems returning " (item constant "${SYSDEP_OS}") " for "
          (link "dd_env_SYSDEP_OS" "SYSDEP_OS") ", the module will attempt to
          locate " (item file_name "${header}") " instead of the normal header
          file.")
EOF
    fi

    if [ -f "${dir}/os_ext/${SYSDEP_OS}/static_lib" ]
    then
      static_lib=`head -n 1 ${dir}/os_ext/${SYSDEP_OS}/static_lib` ||
        fatal "could not read ${dir}/os_ext/${SYSDEP_OS}/static_lib"

      cat <<EOF
        (para "On systems returning " (item constant "${SYSDEP_OS}") " for "
          (link "dd_env_SYSDEP_OS" "SYSDEP_OS") ", the module will attempt to
          locate a static library with a base name matching "
          (item file_name "${static_lib}") " instead of the normal static
          library file.")
EOF
    fi
 
    if [ -f "${dir}/os_ext/${SYSDEP_OS}/dynamic_lib" ]
    then
      dynamic_lib=`head -n 1 ${dir}/os_ext/${SYSDEP_OS}/dynamic_lib` ||
        fatal "could not read ${dir}/os_ext/${SYSDEP_OS}/dynamic_lib"

      cat <<EOF
        (para "On systems returning " (item constant "${SYSDEP_OS}") " for "
          (link "dd_env_SYSDEP_OS" "SYSDEP_OS") ", the module will attempt to
          locate a dynamic library with a base name matching "
          (item file_name "${dynamic_lib}") " instead of the normal dynamic
          library file.")
EOF
    fi
    cat <<EOF
    )
EOF
  done

  cat <<EOF
  )
EOF
fi


#
# Read list of created files.
#

cat <<EOF
  (subsection
    (title "Creates")
    (para "The module creates the following files:")
    (list
EOF

CREATES=`cat ${dir}/creates` || fatal "could not read ${dir}/creates"

for file in ${CREATES}
do
  cat <<EOF
      (item file_name "${file}")
EOF
done
cat <<EOF
    ))

EOF

#
# Read list of config files.
#

if [ -f "${dir}/config" ]
then
  cat <<EOF
  (subsection
    (title "Configuration")
    (para "The module is influenced by the following configuration files:")
    (list
EOF

  CONFIGS=`cat ${dir}/config` || fatal "could not read ${dir}/config"

  for file in ${CONFIGS}
  do
    cat <<EOF
      (item file_name "${file}")
EOF
  done
  cat <<EOF
    ))

EOF
fi

#
# Read list of preprocessor defines.
#

if [ -f "${dir}/defines" ]
then
  cat <<EOF
  (subsection
    (title "Defines")
    (para "The module defines the following preprocessor constants:")
    (table definitions
      (t-row
        (item "Constant")
        (item "Type")
        (item "Attributes"))
EOF

  OLD_IFS="${IFS}"
  IFS="
"

  for line in `cat ${dir}/defines`
  do
    name=`echo ${line} | awk -F: '{print $1}'`
    type=`echo ${line} | awk -F: '{print $2}'`
    attr=`echo ${line} | awk -F: '{print $3}'`
  cat <<EOF
      (t-row
        (item constant "${name}")
        (item "${type}")
        (item constant "${attr}"))
EOF
  done
  cat <<EOF
    ))

EOF
fi

IFS="${OLD_IFS}"

#
# Read lines written to sysdeps.out.
#

cp "${dir}/sysdeps_bnf" "src/r-mr-${module}-sysdeps-bnf.txt" ||
  fatal "could not copy ${dir}/sysdeps_bnf to src/r-mr-${module}-sysdeps-bnf.txt"

cat <<EOF
  (subsection
    (title "Output")
    (para "The module writes lines with the following forms to "
      (item file_name "sysdeps.out") ":")
    (para-verbatim example (render "r-mr-${module}-sysdeps-bnf.txt")))
EOF

#
# Read module metadata.
#

author_email=`head -n 1 ${dir}/author_email` || fatal "could not read ${dir}/author_email"
author_url=`head -n 1 ${dir}/author_url`     || fatal "could not read ${dir}/author_url"

cat <<EOF
  (subsection
    (title "Module Metadata")
    (para
      (table module_metadata
EOF

if [ -f "${dir}/package_url" ]
then
  package_url=`head -n 1 ${dir}/package_url` || fatal "could not read ${dir}/package_url"
cat <<EOF
        (t-row
          (item "Package URL")  (item (link-ext "${package_url}")))
EOF
fi

cat <<EOF
        (t-row
          (item "Author Email") (item email_address "${author_email}"))
        (t-row
          (item "Author URL")    (item (link-ext "${author_url}"))))))
EOF

cat <<EOF
)
EOF
