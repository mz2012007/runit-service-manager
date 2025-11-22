#!/usr/bin/env bash
#
# Advanced Runit Service Manager
# Copyright (C) 2024 mz2012007
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
VERSION="1.0.0"

check_root_privileges() {
  if [[ $EUID -eq 0 ]]; then
    echo "❌ don't use it as root"
    exit 1
  fi

  if ! sudo -n true 2>/dev/null; then
    sudo -v
  fi

  if ! sudo -n true 2>/dev/null; then
    echo "❌ pasword isn't true"
    exit 1
  fi
}
clear

check_dependencies() {
  local deps=("sudo" "sv" "fzf" "eza" "sha256sum")
  local missing=()

  for dep in "${deps[@]}"; do
    if ! command -v "$dep" &>/dev/null; then
      missing+=("$dep")
    fi
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    echo "❌ missing dependencies: ${missing[*]}" >&2
    echo "📦 install dependencies first"
    exit 1
  fi
}

cleanup() {
  if [[ -n "$SUDO_REFRESH_PID" ]]; then
    kill "$SUDO_REFRESH_PID" 2>/dev/null
  fi

  echo "✅ you have exited successfully"
  exit 0
}

check_root_privileges
check_dependencies

trap cleanup EXIT INT TERM

source ~/scripts/services/hash.sh
source ~/scripts/services/new_services.sh

mkdir-serv
while true; do
  nowserv
  cashe
  print-sum
done
