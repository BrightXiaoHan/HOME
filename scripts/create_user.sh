#!/bin/bash
while true; do
  case "$1" in
  --user | -u)
    USERNAME=$2
    shift 2
    ;;
  --folder | -f)
    HOME_FOLDER=$2
    shift 2
    ;;
  --help | -h)
    Usage
    ;;
  -*)
    echo "Unknown option: $1"
    Usage
    ;;
  *)
    break
    ;;
  esac
done

# Check if running with root privileges
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script with root privileges"
  exit 1
fi

# Set variables
USERNAME=${USERNAME:-"hanbing"} # Username
HOME_FOLDER=${HOME_FOLDER:-"/home"} # Home folder
USER_HOME="$HOME_FOLDER/$USERNAME" # User home directory
USER_SHELL="/bin/bash"          # User shell

# Create user and set home directory and shell
useradd -m -d "$USER_HOME" -s "$USER_SHELL" "$USERNAME"

# Set password for the new user
echo "Please set a password for $USERNAME:"
passwd "$USERNAME"

# Add user to sudo group
usermod -aG sudo "$USERNAME"

# Configure sudo without password
echo "$USERNAME ALL=(ALL) NOPASSWD: ALL" | tee /etc/sudoers.d/"$USERNAME"

# Set correct permissions
chmod 440 /etc/sudoers.d/"$USERNAME"

# Confirm successful creation
echo "User creation complete! Here is the user information:"
echo "Username: $USERNAME"
echo "Home directory: $USER_HOME"
echo "Shell: $USER_SHELL"
echo "Sudo privileges: Enabled (no password required)"

# Verify sudo group membership
groups "$USERNAME"

# add user to docker group
usermod -aG docker "$USERNAME"
