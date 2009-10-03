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
  (ref "mr_${module}")
  (title "${module}")

  (subsection
    (title "Synopsis")
    (para "${synopsis}"))

  (subsection
    (title "Description")
EOF
cat ${dir}/description.ud || fatal "could not read ${dir}/description.ud"
cat <<EOF
  )

EOF

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

cp "${dir}/sysdeps_bnf" "src/mr-${module}-sysdeps-bnf.txt" ||
  fatal "could not copy ${dir}/sysdeps_bnf to src/mr-${module}-sysdeps-bnf.txt"

cat <<EOF
  (subsection
    (title "Output")
    (para "The module writes lines with the following forms to "
      (item file_name "sysdeps.out") ":")
    (para-verbatim example (render "mr-${module}-sysdeps-bnf.txt")))
EOF

#
# Read author information.
#

author_email=`head -n 1 ${dir}/author_email` || fatal "could not read ${dir}/author_email"
author_url=`head -n 1 ${dir}/author_url`     || fatal "could not read ${dir}/author_url"

cat <<EOF
  (subsection
    (title "Author Information")
    (para
      (table author_info
        (t-row
          (item "Author Email") (item email_address "${author_email}"))
        (t-row
          (item "Author URL")    (item (link-ext "${author_url}"))))))
EOF

cat <<EOF
)
EOF
