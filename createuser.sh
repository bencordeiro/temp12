#!/bin/bash

# Ben Cordeiro | bcordeiro | ID: 1119774

usage() {
  echo "Usage: $0 -u username [-c fullname] [-d homedir] [-s shell] [-a] [-p password] [-P]"
  echo "       [-i inactive_days] [-M max_days] [-W warn_days]"
  echo "Options:"
  echo "  -u USERNAME     (Required) Username for account."
  echo "  -c FULLNAME     Full name."
  echo "  -d HOMEDIR      Home directory."
  echo "  -s SHELL        Login shell."
  echo "  -a              Assign admin/sudo."
  echo "  -p PASSWORD     Set password."
  echo "  -P              Generate a random password."
  echo "  -i DAYS         Set inactive days before expiration."
  echo "  -M DAYS         Set max password age (minimum 20 days)."
  echo "  -W DAYS         Set warning days before password expires."
  exit 1
}

if [ "$USER" != "root" ]; then
  echo "Permission Denied"
  echo "Can only be run by root"
  exit 1
fi

# Init vars
username=""
fullname=""
homedir=""
shell="/bin/bash"  # default shell
admin=false
password=""
gen_password=false
inactive_days=""
max_days=""
warn_days=""

# Getopts for named parameters
while getopts ":u:c:d:s:ap:Pi:M:W:" opt; do
  case ${opt} in
    u) username="$OPTARG" ;;
    c) fullname="$OPTARG" ;;
    d) homedir="$OPTARG" ;;
    s) shell="$OPTARG" ;;
    a) admin=true ;;
    p) 
      if [[ -z "$OPTARG" || "$OPTARG" =~ ^- ]]; then
        echo "Error: -p requires a password argument."
        usage
      fi
      if [ "$gen_password" = true ]; then
        echo "Error: Cannot use both -p (password) and -P (generate password) together."
        usage
        exit 3
      fi
      password="$OPTARG"
      ;;
    P) 
      if [ -n "$password" ]; then
        echo "Error: Cannot use both -p (password) and -P (generate password) together."
        usage
        exit 3
      fi
      gen_password=true
      ;;
    i) inactive_days="$OPTARG" ;;
    M) max_days="$OPTARG" ;;
    W) warn_days="$OPTARG" ;;
    \?) # Invalid Option
      echo "Error: Invalid option -$OPTARG"
      usage
      ;;
  esac
done

# Test variable assignments
echo "Username: $username"
echo "Fullname: $fullname"
echo "Home Directory: $homedir"
echo "Shell: $shell"
echo "Admin: $admin"
echo "Password: ${password:+Set}" # Hide actual password
echo "Generate Password: $gen_password"
echo "Inactive Days: $inactive_days"
echo "Max Days: $max_days"
echo "Warn Days: $warn_days"

exit 0
