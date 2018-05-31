# Find out about the current directory
OFVM_BASE="$( cd "$(dirname "$BASH_SOURCE")" ; pwd -P )"
OF_SRC="$OFVM_BASE/of-src"
OF_BUILTIN_VERSIONS="$OF_SRC/builtin-versions.conf"
OF_EXTRA_VERSIONS="$OF_SRC/extra-versions.conf"
OF_DEFAULT_VERSION_PATH="$OF_SRC/default-version"

####################
# Helper functions #
####################

__ofvm_function_exists() {
  declare -f -F $1 > /dev/null
  return $?
}

__ofvm_get_git_url_from_file() {
  proj=$1
  file=$2
  # Split on = and trim whitespace
  url=$(grep -e "^${proj}[[:blank:]]\+=" $file | cut -f 2 -d '=' | awk '{$1=$1};1')
  echo $url
}

__ofvm_get_git_url() {
  url=$(__ofvm_get_git_url_from_file $1 $OF_BUILTIN_VERSIONS)
  if [ -f $OF_EXTRA_VERSIONS ]; then
    url=$(__ofvm_get_git_url_from_file $1 $OF_EXTRA_VERSIONS)
  fi

  echo $url
}

__ofvm_error_not_installed() {
  echo "ERROR: $of_name is not installed to $src_path" >&2
}

__ofvm_log() {
  echo "[ofvm] $1"
}

# Command line

ofvm() {
  command=$1
  if [ -z "$command" ]; then
    ofvm_help
    return 0
  fi

  f=ofvm_$1
  shift
  if ! __ofvm_function_exists $f; then
    echo "ERROR: ofvm $f is not a valid command" >&2
    return 1
  fi

  $f "$@"
}

ofvm_help() {
  command=$1
  if [ -z "$command" ]; then
    echo "usage: ofvm COMMAND [options]"
    echo ""
    echo "possible commands:"
    echo "  list            lists the installed versions of OF"
    echo "  listavailable   lists the available versions of OF"
    echo "  install         install a version of OF"
    echo "  update          update a version of OF"
    echo "  remove          remove a version of OF"
    echo "  use             switch to a different version of OF for this shell"
    echo "  default         set a default version of OF"
    echo "  tar             creates a tar from the current installation to stdout"
  fi
}

ofvm_reload() {
  source $OFVM_BASE/ofvm.bash
}

ofvm_install() (
  set -e
  of_name=$1
  tp_name=${of_name/OpenFOAM/ThirdParty}

  of_git_url=$(__ofvm_get_git_url ${of_name})
  tp_git_url=$(__ofvm_get_git_url ${tp_name})

  if [ -z "$of_git_url" ] || [ -z "$tp_git_url" ]; then
    echo "ERROR: Cannot find version ${version}" >&2
    echo "ERROR: of_git_url=${of_git_url}"
    echo "ERROR: tp_git_url=${tp_git_url}"
    return 1
  fi

  set -x

  pushd $OF_SRC >/dev/null
    git clone $of_git_url $of_name
    git clone $tp_git_url $tp_name

    set +e
    source $of_name/etc/bashrc
    set -e

    pushd $of_name >/dev/null
      time ./Allwmake -j
    popd >/dev/null
  popd >/dev/null

  __ofvm_log "Successfully installed ${of_name} from ${of_git_url}."

  if [ ! -f $OF_DEFAULT_VERSION_PATH ]; then
    ofvm_default $of_name
  fi
)

ofvm_update() (
  set -e
  of_name=$1
  tp_name=${of_name/OpenFOAM/ThirdParty}

  if [ -z "$of_name" ]; then
    echo "ERROR: must specify a version" >&2
    return 1
  fi

  if [ ! -d $OF_SRC/$of_name ]; then
    __ofvm_error_not_installed
    return 1
  fi

  set -x
  cd $OF_SRC

  pushd $tp_name >/dev/null
    git fetch origin
    git checkout origin/master
  popd >/dev/null

  pushd $of_name >/dev/null
    git fetch origin
    git checkout origin/master
    time ./Allwmake -j
  popd >/dev/null
)

ofvm_remove() (
  set -e
  of_name=$1
  tp_name=${of_name/OpenFOAM/ThirdParty}

  cd $OF_SRC
  rm -rf $of_name
  rm -rf $tp_name
)

ofvm_use() {
  of_name=$1
  src_path=$OF_SRC/$of_name
  if [ ! -d $src_path ]; then
    return 1
  fi

  . $src_path/etc/bashrc
  __ofvm_log "switched to using $of_name"
}

ofvm_default() {
  of_name=$1
  if [ -z "$of_name" ]; then
    rm $OF_DEFAULT_VERSION_PATH
    __ofvm_log "removed default OF"
    return 0
  fi

  src_path=$OF_SRC/$of_name
  if [ ! -d $src_path ]; then
    __ofvm_error_not_installed
    return 1
  fi

  echo $of_name > $OF_DEFAULT_VERSION_PATH
  __ofvm_log "using $of_name as default OF"
  ofvm_use $of_name
}

ofvm_list() {
  versions=$(ls -1 $OF_SRC | grep OpenFOAM-)
  echo $versions
}

ofvm_listavailable() {
  grep --color=never "^OpenFOAM-" $OF_BUILTIN_VERSIONS
  if [ -f $OF_EXTRA_VERSIONS ]; then
    grep --color=never "^OpenFOAM-" $OF_EXTRA_VERSIONS
  fi

  echo
  __ofvm_log "Installation is done via ofvm install OpenFOAM-VERSION"
  __ofvm_log "Extra targets can be defined in:"
  __ofvm_log "  - $OF_EXTRA_VERSIONS"
}

ofvm_tar() {
  tar czf - -C $(dirname $OFVM_BASE) $(basename $OFVM_BASE)
}

if [ -f $OF_DEFAULT_VERSION_PATH ]; then
  default_version=$(cat $OF_DEFAULT_VERSION_PATH)
  ofvm_use $default_version
fi
