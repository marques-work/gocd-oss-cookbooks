#!/bin/bash

set -e

#####################################################################
# These are functions shared by both CentOS and Ubuntu provisioners #
#####################################################################

function validate_sourced() {
  if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    die "${BASH_SOURCE[0]} is intended to be sourced as a library";
  fi
}

# user setup

function add_gocd_user() {
  try useradd --create-home --home-dir /go --shell /bin/bash go
  try cp /usr/local/src/provision/gocd-sudoers /etc/sudoers.d/go
  try chmod 0440 /etc/sudoers.d/go
}

function setup_nexus_configs() {
  setup_gradle_config
  setup_maven_config
  setup_rubygems_config
  setup_npm_config
}

function setup_gradle_config() {
  copy_to_home_dir init.gradle .gradle/init.gradle
}

function setup_maven_config() {
  copy_to_home_dir settings.xml .m2/settings.xml
}

function setup_rubygems_config() {
  copy_to_home_dir bundle-config .bundle/config
}

function setup_npm_config() {
  copy_to_home_dir npmrc .npmrc
}

function setup_git_config() {
  copy_to_home_dir gitconfig .gitconfig
}

# devtools

function install_rbenv() {
  # in case this exists, remove it; the installer will try to symlink this into ~go/.rbenv/versions
  try rm -rf /opt/rubies

  cat <<-EOF > /etc/profile.d/rbenv.sh
export PATH="\$HOME/.rbenv/bin:\$PATH"
if command -v rbenv &> /dev/null; then
  eval "\$(rbenv init -)"
fi
EOF
  try su - "${PRIMARY_USER:-go}" -c "bash /usr/local/src/provision/rbenv-installer"
  try su - "${PRIMARY_USER:-go}" -c "git -C \"\$(rbenv root)/plugins\" clone https://github.com/tpope/rbenv-aliases"

  echo "Validating rbenv installation"
  try su - "${PRIMARY_USER:-go}" -c "curl -fsSL https://raw.githubusercontent.com/rbenv/rbenv-installer/master/bin/rbenv-doctor | bash"
}

function install_nodenv() {
  # in case this exists, remove it; the installer will try to symlink this into ~go/.nodenv/versions; and yes,
  # even though this is nodenv and not rbenv...
  try rm -rf /opt/rubies

  cat <<-EOF > /etc/profile.d/nodenv.sh
export PATH="\$HOME/.nodenv/bin:\$PATH"
if command -v nodenv &> /dev/null; then
  eval "\$(nodenv init -)"
fi
EOF
  try su - "${PRIMARY_USER:-go}" -c "bash /usr/local/src/provision/nodenv-installer"
  try su - "${PRIMARY_USER:-go}" -c "git -C \"\$(nodenv root)/plugins\" clone https://github.com/nodenv/node-build-update-defs"
  try su - "${PRIMARY_USER:-go}" -c "git -C \"\$(nodenv root)/plugins\" clone https://github.com/nodenv/nodenv-aliases"

  echo "Validating nodenv installation"
  try su - "${PRIMARY_USER:-go}" -c "curl -fsSL https://raw.githubusercontent.com/nodenv/nodenv-installer/master/bin/nodenv-doctor | bash"
}

function install_jabba() {
  try su - ${PRIMARY_USER:-go} -c 'curl -sL https://github.com/shyiko/jabba/raw/master/install.sh | bash'
}

function major_minor() {
  local version="$1"
  printf "$(printf $version | cut -d. -f1).$(printf $version | cut -d. -f2)"
}

function install_global_ruby() {
  local version="$1"
  try su - "${PRIMARY_USER:-go}" -c "rbenv install $version && rbenv global $(major_minor $version) && echo \"Default ruby version: \$(ruby --version)\""
  try su - "${PRIMARY_USER:-go}" -c "gem install rake bundler && rbenv rehash && rake --version && bundle --version"
}

function install_global_node() {
  local version="$1"
  try su - "${PRIMARY_USER:-go}" -c "nodenv install $version && nodenv global $(major_minor $version) && echo \"Default node version: \$(node --version)\""
}

function install_yarn() {
  try su - "${PRIMARY_USER:-go}" -c "npm install -g yarn && nodenv rehash && yarn --version"
}

function install_gauge() {
  local version="$1"
  try curl -sL -O https://github.com/getgauge/gauge/releases/download/v$version/gauge-$version-linux.x86_64.zip
  try unzip -d /usr/bin gauge-$version-linux.x86_64.zip
  try gauge -v
}

function install_jdks() {
  if [ $# -eq 0 ]; then
    die "install_jdks() must be given at least 1 version argument"
  fi

  for version in $@; do
    try su - ${PRIMARY_USER:-go} -c "jabba install openjdk@1.${version}"
  done
}

function install_maven() {
  local version="$1"
  try mkdir -p /opt/local/
  try curl --silent --fail --location http://archive.apache.org/dist/maven/maven-3/${version}/binaries/apache-maven-${version}-bin.zip --output /usr/local/src/apache-maven-${version}-bin.zip
  try unzip -q /usr/local/src/apache-maven-${version}-bin.zip -d /opt/local
  try ln -sf /opt/local/apache-maven-${version}/bin/mvn /usr/local/bin/mvn
}

function install_ant() {
  local version="$1"
  try mkdir -p /opt/local/
  try curl --silent --fail --location http://archive.apache.org/dist/ant/binaries/apache-ant-${version}-bin.zip --output /usr/local/src/apache-ant-${version}-bin.zip
  try unzip -q /usr/local/src/apache-ant-${version}-bin.zip -d /opt/local
  try ln -sf /opt/local/apache-ant-${version}/bin/ant /usr/local/bin/ant
}

function install_geckodriver() {
  local URL="$(curl --silent --fail --location https://github-api-proxy.gocd.org/repos/mozilla/geckodriver/releases/latest | jq -r '.assets[] | select(.name | contains("linux64.tar.gz")) | .browser_download_url')"
  try curl --silent --fail --location "${URL}" --output /usr/local/src/geckodriver-latest.tar.gz
  try tar -zxf /usr/local/src/geckodriver-latest.tar.gz -C /usr/local/bin
}

# startup services

function install_tini() {
  local URL="$(curl --silent --fail --location https://github-api-proxy.gocd.org/repos/krallin/tini/releases/latest | jq -r '.assets[] | select(.name | match("-static-amd64$")) | .browser_download_url' | grep -v muslc)"
  try curl -fsSL --output /usr/bin/tini "$URL"
  try chmod a+rx /usr/bin/tini
  try tini --version
}

function add_golang_gocd_bootstrapper() {
  local URL="$(curl -fsSL https://github-api-proxy.gocd.org/repos/ketan/gocd-golang-bootstrapper/releases/latest | jq -r '.assets[] | select(.name | contains("linux.amd64")) | .browser_download_url')"
  try curl -fsSL --output /go/go-agent "${URL}"
  try chown go:go /go/go-agent
  try chmod a+rx /go/go-agent
}

function setup_entrypoint() {
  try cp /usr/local/src/provision/with-java /usr/local/bin/with-java
  try cp /usr/local/src/provision/bootstrap.sh /bootstrap.sh
  try chmod a+rx /usr/local/bin/with-java
  try chmod a+rx /bootstrap.sh
}

# helpers

function print_versions_summary() {
  green "$(try su - "${PRIMARY_USER:-go}" <<-EOF
printf "\n"
printf "//////////////////////////////\n"
printf "// Package versions summary //\n"
printf "//////////////////////////////\n"
printf "\n"

printf "git version:\n"
git --version | pr -to 2
printf "\n"

printf "ruby version:\n"
ruby --version | pr -to 2
printf "\n"

printf "node version:\n"
node --version | pr -to 2
printf "\n"

printf "yarn version:\n"
yarn --version | pr -to 2
printf "\n"

printf "Installed JDKs:\n"
jabba ls | pr -to 2
printf "\n"

if type gauge &> /dev/null; then
  printf "gauge version:\n"
  gauge -v | pr -to 2
  printf "\n"
fi

EOF
)"
}

function copy_to_home_dir() {
  local src="$1"
  local dst="$2"
  local destdir="$(dirname "$dst")"
  local provisiondir="$(dirname $0)"
  local homedir="$(eval printf "%s" "~go")" # expand ~go to abs path

  if [ "$destdir" != "." ]; then
    try mkdir -p "$homedir/$destdir"
  fi

  try cp "$provisiondir/$src" "$homedir/$dst"
  try chown go:go -R "$homedir"
}

function how_much_memory_in_gb() {
  free -t -g | grep -F Total: | awk '{print $2}'
}

# output and control

function yell() { redalert "$0: $*" >&2; }
function die() { yell "$*"; exit 111; }
function try() { magenta "\$ $@" >&2; "$@" || die "Failed to execute: \`$*\`"; }
function step() {
  printf "\n\n" >&2
  cyan "////////////////////////////////////////////////////////////////////////////////" >&2
  cyan "  => Step: $*" >&2
  cyan "////////////////////////////////////////////////////////////////////////////////" >&2
  printf "\n\n" >&2
  "$@"
}

# colors

function redalert() { printf "\e[1;41m$*\e[0m\n"; }
function yellowalert() { printf "\e[1;43;37m$*\e[0m\n"; }
function cyan() { printf "\e[36;1m$*\e[0m\n"; }
function magenta() { printf "\e[35;1m$*\e[0m\n"; }
function green() { printf "\e[32;1m$*\e[0m\n"; }

validate_sourced
