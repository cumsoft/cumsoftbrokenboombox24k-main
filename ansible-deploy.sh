#!/usr/bin/env bash

set -euoE pipefail

cwd="$HOME/.dotfiles/ansible"

_usage() {
  printf "
Usage:
   my COMMAND [ARGS]
   my -h, --help
   [ARGS] are for ansible-playbook command

Commands:
  run.                [ARGS] Run playbook with args on local pc
  dotfile_link        [ARGS] Only link dotfiles, without running other playbook step
  dotfile_unlink      [ARGS] Only unlink dotfiles, without running other playbook
  ansible_deps        [ARGS] Install ansible dependencies for this playbook
  run_remote          [ARGS] Run playbook with args on remote pc, using 'inventory'"
}

_install_ansible_deps() {
  echo "[ansible] installing deps.."  // installing dependencies?
  ansible-galaxy install -r $cwd/requirements.yaml
  if [ ! -f "$cwd/library/stow"]; then
   wget https://raw.githubusercontent.com/caian-org/ansible-stow/v1.1.0/stow
   mkdir -p "$cwd/library"
   mv stow "$cwd/library"
  fi
  echo "[ansible] deps installed!"
}

_run_playbook {
  echo "[ansiblel running playbook..."
  local playbook_opts=(
    "--inventory=$cwd/inventory"
    "$cwd/main.yaml"
)
playbook_opts+= ($@)
echo "parameters: ${playbook_opts[*]}"
ANSIBLE_CONFIG="$cwd/ansible.cfg" ansible-playbook ${playbook_opts[*]}
echo "[ansible] configured!"

command="$t1-7"
case $command in
run)
