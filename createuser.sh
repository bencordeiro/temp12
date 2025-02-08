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
  echo "  -a              Assign admin/sudo"
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
shell=""
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
    d)
      if [[ -z "$OPTARG" || "$OPTARG" =~ ^- ]]; then
        echo "Error: -d requires a home directory argument."
        usage
      fi
      homedir="$OPTARG"
      ;;
    s)
      if [[ -z "$OPTARG" || "$OPTARG" =~ ^- ]]; then
        echo "Error: -s requires a shell argument."
        usage
      fi
      shell="$OPTARG"
      ;;
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
    \?)
      echo "Error: Invalid option -$OPTARG"
      usage
      ;;
  esac
done


# Validation Checks

# Require username parameter
if [ -z "$username" ]; then
  echo "Error: The -u (username) is required."
  usage
fi

# Validate inactive days
if [ -n "$inactive_days" ] && [ "$inactive_days" -le 0 ]; then
  echo "Error: -i (inactive days) must be greater than 0."
  exit 2
fi

# Validate max days
if [ -n "$max_days" ] && [ "$max_days" -lt 20 ]; then
  echo "Error: -M (max days) must be at least 20."
  exit 3
fi

# Validate warn days
if [ -n "$warn_days" ] && [ "$warn_days" -le 0 ]; then
  echo "Error: -W (warn days) must be greater than 0."
  exit 4
fi

# Build useradd command
cmd="useradd"

[ -n "$fullname" ] && cmd+=" -c \"$fullname\""
[ -n "$homedir" ] && cmd+=" -d $homedir"
[ -n "$shell" ] && cmd+=" -s $shell" || cmd+=" -s /bin/bash"

cmd+=" $username"

# Create user
if eval "$cmd"; then

  # Assign to sudo group if -a is set
  [ "$admin" = true ] && usermod -aG sudo "$username"

  # Set password if -p or -P is specified
  if [ -n "$password" ]; then
    echo "$username:$password" | chpasswd
  elif [ "$gen_password" = true ]; then
    rand_password=$(apg -n 1 -m 10 -x 10)
    echo "$username:$rand_password" | chpasswd
    echo "Password for $username: $rand_password"
  else
    passwd -l "$username"  # Lock account if neither is provided
  fi

  # Apply password policies
  [ -n "$inactive_days" ] && chage -I "$inactive_days" "$username"
  [ -n "$max_days" ] && chage -M "$max_days" "$username"
  [ -n "$warn_days" ] && chage -W "$warn_days" "$username"

else
  echo "Failed to create user $username."
  exit 1
fi

exit 0
