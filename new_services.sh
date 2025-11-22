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

# colors

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
MAGENTA="\e[35m"
CYAN="\e[36m"
RESET="\e[0m"

#---------------------------------------------------------------------------------------------------

# work dirs for services
mkdir-serv() {
  mkdir -p $HOME/scripts/services/work/
  mkdir -p $HOME/scripts/services/work/disabled_dir
  mkdir -p $HOME/scripts/services/work/up_dir
  mkdir -p $HOME/scripts/services/work/down_dir
}
disabled_dir="$HOME/scripts/services/work/disabled_dir"
up_dir="$HOME/scripts/services/work/up_dir"
down_dir="$HOME/scripts/services/work/down_dir"
real_all="/etc/sv"
real_enabled="/var/service"

#---------------------------------------------------------------------------------------------------

nowserv() {
  # shutdown services
  for s in /var/service/*; do
    service=$(basename "$s")
    status=$(sudo sv status "$service")
    if [[ $status == down* || $status == fail* ]]; then
      down_services+=("$service")
    fi
  done

  # up services
  up_services=$(comm -23 <(ls -1 $real_enabled | sort) <(ls -1 $down_services | sort))

  # disabled services
  disabled_services=$(comm -23 <(ls -1 $real_all | sort) <(ls -1 $real_enabled | sort))

}

mkserv() {
  # shutdown services
  for s in /var/service/*; do
    service=$(basename "$s")
    status=$(sudo sv status "$service")
    if [[ $status == down* || $status == fail* ]]; then
      mkdir -p "$down_dir/$service"
    fi
  done

  # up services
  up_services=$(comm -23 <(ls -1 $real_enabled | sort) <(ls -1 $down_dir | sort))

  for service in $up_services; do
    mkdir -p "$up_dir/$service"
  done

  # disabled services
  disabled_services=$(comm -23 <(ls -1 $real_all | sort) <(ls -1 $real_enabled | sort))

  for service in $disabled_services; do
    mkdir -p "$disabled_dir/$service"
  done
}

#---------------------------------------------------------------------------------------------------

print_header() {
  clear
  echo -e "${MAGENTA}"
  echo "╔══════════════════════════════════════════════════════════════════════════════╗"
  echo "║                   🚀 Advanced Runit Service Manager                          ║"
  echo "╚══════════════════════════════════════════════════════════════════════════════╝"
  echo -e "${RESET}"
}

print_header
print-sum() {
  print-head() {
    local color="$1"
    local icon="$2"

    echo -e "${color}╔══════════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${color}║ ${icon} $services_kind $(printf '%*s' $((65 - ${#services_kind} - 4)) '')            ║${RESET}"
    echo -e "${color}╚══════════════════════════════════════════════════════════════════════════════╝${RESET}"

    if [ -z "$(ls -A "$services_dir" 2>/dev/null)" ]; then
      echo -e "  ${YELLOW}⏸️  not found $services_kind${RESET}"
      echo ""
    else
      eza --color-scale-mode=gradient --icons --group-directories-first \
        --sort=name "$services_dir/"
      echo ""
    fi
  }

  #  print-head() {
  #   echo -e "${MAGENTA}──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────${RESET}"
  #   echo " "
  #   echo -e "${GREEN} $services_kind ${RESET}"
  #   echo " "
  #   if [ -z "$(ls -A $services_dir 2>/dev/null)" ]; then
  #     echo -e "${RED}There is no $services_kind ${RESET}"
  #   else
  #     eza --color-scale-mode=gradient --icons $services_dir/
  #   fi
  # }

  #---------------------------------------------------------------------------------------------------

  # all services
  services_kind="all services"
  services_dir="$real_all"
  print-head "$BLUE" "📦"

  # enabled services
  services_kind="enabled services"
  services_dir="$real_enabled"
  print-head "$GREEN" "✅"

  # disabled services
  services_kind="disabled services"
  services_dir="$disabled_dir"
  print-head "$RED" "⏸️ "

  # up services
  services_kind="up services"
  services_dir="$up_dir"
  print-head "$GREEN" "🟢"

  # shutdown services
  services_kind="shutdown services"
  services_dir="$down_dir"
  print-head "$YELLOW" "🔴" #---------------------------------------------------------------------------------------------------

  # number of services

  count_all=$(ls -1 $real_all | wc -l)
  count_enabled=$(ls -1 $real_enabled | wc -l)
  count_disabled=$(ls -1 $disabled_dir | wc -l)
  count_up=$(ls -1 $up_dir | wc -l)
  count_shutdown=$(ls -1 $down_dir | wc -l)

  echo -e "${BLUE}┌──────────────────────┬─────────┐${RESET}"
  echo -e "${BLUE}│      category        │ number  │${RESET}"
  echo -e "${BLUE}├──────────────────────┼─────────┤${RESET}"
  echo -e "${BLUE}│ ${RESET}All services         ${BLUE}│ ${RESET}$count_all ${BLUE}     │${RESET}"
  echo -e "${BLUE}│ ${GREEN}Enabled services${RESET}     ${BLUE}│ ${GREEN}$count_enabled ${BLUE}     │${RESET}"
  echo -e "${BLUE}│ ${RED}Disabled services${RESET}    ${BLUE}│ ${RED}$count_disabled ${BLUE}     │${RESET}"
  echo -e "${BLUE}│ ${GREEN}Up services${RESET}          ${BLUE}│ ${GREEN}$count_up ${BLUE}     │${RESET}"
  echo -e "${BLUE}│ ${YELLOW}Down services${RESET}        ${BLUE}│ ${YELLOW}$count_shutdown ${BLUE}      │${RESET}"
  echo -e "${BLUE}└──────────────────────┴─────────┘${RESET}"
  echo ""

  # echo -e "${MAGENTA}──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────${RESET}"
  # echo ""
  # echo -e "${BLUE}Total services: $count_all${RESET}"
  # echo -e "${GREEN}Enabled: $count_enabled${RESET}"
  # echo -e "${RED}Disabled: $count_disabled${RESET}"
  # echo -e "${GREEN}UP: $count_up${RESET}"
  # echo -e "${RED}shutdown: $count_shutdown${RESET}"

  #---------------------------------------------------------------------------------------------------

  #  echo -e "${MAGENTA}──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────${RESET}"
  #  echo ""
  #  echo -e "${BLUE}Options: ${RESET}"
  #  echo ""
  #  echo "  e = enable service"
  #  echo "  d = disable service"
  #  echo "  s = shutdown service"
  #  echo "  u = start service"
  #  echo "  r = restart service"
  #  echo "  q = quit"
  #  echo ""
  #  echo -e "${MAGENTA}──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────${RESET}"

  echo -e "${MAGENTA}┌──────┬───────────────────────────┐${RESET}"
  echo -e "${MAGENTA}│ ${GREEN}e${RESET}    ${MAGENTA}│${RESET} ${GREEN}enable${RESET} (Enable)           ${MAGENTA}│${RESET}${RESET}"
  echo -e "${MAGENTA}│ ${RED}d${RESET}    ${MAGENTA}│${RESET} ${RED}disable${RESET} (Disable)         ${MAGENTA}│${RESET}${RESET}"
  echo -e "${MAGENTA}│ ${YELLOW}s${RESET}    ${MAGENTA}│${RESET} ${YELLOW}shutdown${RESET} (Shutdown)       ${MAGENTA}│${RESET}${RESET}"
  echo -e "${MAGENTA}│ ${BLUE}u${RESET}    ${MAGENTA}│${RESET} ${BLUE}up${RESET} (Start)                ${MAGENTA}│${RESET}${RESET}"
  echo -e "${MAGENTA}│ ${CYAN}r${RESET}    ${MAGENTA}│${RESET} ${CYAN}restart${RESET} (Restart)         ${MAGENTA}│${RESET}${RESET}"
  echo -e "${MAGENTA}│ ${GREEN}Enter${RESET}${MAGENTA}│${RESET} ${GREEN}refresh${RESET} (Refresh)         ${MAGENTA}│${RESET}${RESET}"
  echo -e "${MAGENTA}│ ${RED}q${RESET}  ${MAGENTA}  │${RESET} ${RED}quit${RESET} (Quit)          ${MAGENTA}     │${RESET}${RESET}"
  echo -e "${MAGENTA}└──────┴───────────────────────────┘${RESET}"
  echo ""

  read -n 1 -p " : " option

  if [[ "$option" == "e" || "$option" == "d" || "$option" == "s" || "$option" == "u" || "$option" == "r" ]]; then

    echo ""
    echo -e "${CYAN}Select a service to manage:${RESET}"

    if [[ "$option" == "d" ]]; then
      dir="$real_enabled"
    elif [[ "$option" == "s" || "$option" == "r" ]]; then
      dir="$up_dir"
    elif [[ "$option" == "u" ]]; then
      dir="$down_dir"
    else
      dir="$disabled_dir"
    fi

    if [ -z "$(ls -A "$dir" 2>/dev/null)" ]; then
      echo -e "${YELLOW}No services available for this action.${RESET}"
      sleep 2
      continue
    else
      service=$(ls -1 "$dir" | fzf --prompt="Select a service: " --height=20%)
    fi

    if [[ -z "$service" ]]; then
      echo -e "${YELLOW}No service selected, skipping...${RESET}"
      #      print-sum
      return 1
    fi

    case $option in
    e) sudo ln -s "$real_all/$service" "$real_enabled/" && echo "$service has been enabled" ;;
    d) if [ -L "$real_enabled/$service" ]; then
      sudo unlink -- "$real_enabled/$service" && echo "$service has been disabled"
    else
      echo "$service is not a symlink in /var/service/, skipping..."
    fi ;;
    s) sudo sv shutdown $service && echo "$service has been shutdown" ;;
    u) sudo sv up $service && echo "$service has been started" ;;
    r) sudo sv restart $service && echo "$service has been restarted" ;;
    esac
    sleep 1
    sudo sv status $service

  elif [[ "$option" == "q" ]]; then
    clear
    exit 0
  elif [[ "$option" == "" ]]; then
    echo ""
  else
    echo ""
    echo " Wrong choice"
    echo ""
    echo -e "${YELLOW}click (Enter) to continue${RESET}"
    echo ""
    echo -e "${RED}write (q) to exit${RESET}"
    echo ""
    read -n 1 mz
    if [[ "$mz" == "q" ]]; then
      clear
      exit 0
    fi
  fi

  clear

}
