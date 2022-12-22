#!/usr/bin/env bash

# Exit immediately if any command returns a non-zero exit status
set -e

# Exit immediately if any uninitialized variables are used
set -u

# Exit immediately if any command in a pipeline returns a non-zero exit status
set -o pipefail

# Check if gpg is installed and install it if necessary
if ! command -v gpg > /dev/null; then
  echo "gpg is not installed. Checking Homebrew installation and installing gpg..."
  brew doctor
  brew install gpg
fi

# Check if pinentry-mac is installed and install it if necessary
if ! command -v pinentry-mac > /dev/null; then
  echo "pinentry-mac is not installed. Checking Homebrew installation and installing
pinentry-mac..."
  brew doctor
  brew install pinentry-mac
fi

# Create gpg-agent configuration file
echo "Creating gpg-agent configuration file..."
echo "pinentry-program /usr/local/bin/pinentry-mac" > ~/.gnupg/gpg-agent.conf
chmod 700 ~/.gnupg

# Generate a GPG key
echo "Generating GPG key..."
gpg --full-generate-key

# List GPG keys to find the ID of the key you just created
echo "Finding GPG key ID..."
key_id=$(gpg --list-secret-keys | awk '/sec/{getline; print}' | sort -k 3 -t '/' | tail -n 1 | cut -d '/' -f 2 | sed -e 's/^[ \t]*//')

# Configure Git to use your GPG key
echo "Configuring Git to use GPG key..."
git config --global user.signingkey "$key_id"

# Check if the user wants to update their git configuration to use the email matching the GPG key
read -p "Do you want to update your global git configuration to use the email matching the GPG key that was created? (y/n) [y]: " update_email
update_email=${update_email:-y}

if [ "$update_email" = "y" ]; then
  # Look up the email for the key
  email=$(gpg --list-keys $key_id | awk '/uid/ {print $NF}' | sed 's/[<>]//g')

  # Set the git configuration to use the email
  git config --global user.email "$email"
  echo "Git configuration updated to use email: $email"
fi

# Set the default input value to one month (30 days or 2592000 seconds)
default_cache_ttl=2592000

# Ask the user how long they would like the gpg-agent to cache the password
read -p "Enter the number of seconds you would like the gpg-agent to cache the password (default: $default_cache_ttl): " cache_ttl

# If the user didn't enter any input, use the default value
if [ -z "$cache_ttl" ]; then
  cache_ttl=$default_cache_ttl
fi

# Set the default-cache-ttl and max-cache-ttl options in the gpg-agent.conf file
echo "default-cache-ttl $cache_ttl" >> ~/.gnupg/gpg-agent.conf
echo "max-cache-ttl $cache_ttl" >> ~/.gnupg/gpg-agent.conf

# Convert the number of seconds into a format that includes years, months, days, hours, and seconds
years=$((cache_ttl / 31536000))
cache_ttl=$((cache_ttl % 31536000))
months=$((cache_ttl / 2592000))
cache_ttl=$((cache_ttl % 2592000))
days=$((cache_ttl / 86400))
cache_ttl=$((cache_ttl % 86400))
hours=$((cache_ttl / 3600))
cache_ttl=$((cache_ttl % 3600))
seconds=$cache_ttl

# Output a confirmation of the amount of time the user input
echo "The gpg-agent will cache the password for"

if [ $years -ne 0 ]; then
  echo "$years year(s)"
fi

if [ $months -ne 0 ]; then
  echo "$months month(s)"
fi

if [ $days -ne 0 ]; then
  echo "$days day(s)"
fi

if [ $hours -ne 0 ]; then
  echo "$hours hour(s)"
fi

if [ $seconds -ne 0 ]; then
  echo "$seconds second(s)"
fi

# Add a period to the end of the output confirmation
echo "."

# Set GPG_TTY and start gpg-agent in Bash or Zsh
if [ -f ~/.zshrc ]; then
  # Modify ~/.zshrc if it exists
  echo "Modifying ~/.zshrc to set GPG_TTY and start gpg-agent..."
  echo "export GPG_TTY=\$TTY" >> ~/.zshrc
  echo "if [ -f ~/.gnupg/gpg-agent.conf ]; then" >> ~/.zshrc
  echo "  if ! pgrep -u "$(id -u)" gpg-agent > /dev/null; then" >> ~/.zshrc
  echo "    gpg-connect-agent updatestartuptty /bye" >> ~/.zshrc
  echo "  fi" >> ~/.zshrc
  echo "fi" >> ~/.zshrc
elif [ -f ~/.bash_profile ]; then
  # Modify ~/.bash_profile if only ~/.bash_profile exists
  echo "Modifying ~/.bash_profile to set GPG_TTY and start gpg-agent..."
  echo "export GPG_TTY=\$TTY" >> ~/.bash_profile
  echo "if [ -f ~/.gnupg/gpg-agent.conf ]; then" >> ~/.bash_profile
  echo "  if ! pgrep -u "$(id -u)" gpg-agent > /dev/null; then" >> ~/.bash_profile
  echo "    gpg-connect-agent updatestartuptty /bye" >> ~/.bash_profile
  echo "  fi" >> ~/.bash_profile
  echo "fi" >> ~/.bash_profile
else
  # Create ~/.bash_profile if neither file exists
  echo "Creating ~/.bash_profile to set GPG_TTY and start gpg-agent..."
  echo "export GPG_TTY=\$TTY" >> ~/.bash_profile
  echo "if [ -f ~/.gnupg/gpg-agent.conf ]; then" >> ~/.bash_profile
  echo "  if ! pgrep -u "$(id -u)" gpg-agent > /dev/null; then" >> ~/.bash_profile
  echo "    gpg-connect-agent updatestartuptty /bye" >> ~/.bash_profile
  echo "  fi" >> ~/.bash_profile
  echo "fi" >> ~/.bash_profile
fi

# Stop gpg-agent
echo "Stopping gpg-agent..."
killall gpg-agent

# Start gpg-agent
gpg-connect-agent updatestartuptty /bye

# Configure Git to use gpg as the GPG program

echo "Configuring Git to use gpg as the GPG program..."
git config --global gpg.program gpg

# Configure Git to automatically sign commits with your GPG key

echo "Configuring Git to automatically sign commits with your GPG key..."
git config --global commit.gpgsign true
echo "        use-agent" >> ~/.gitconfig

echo "Done! Git is now configured to use your GPG key stored in the macOS keychain with 
pinentry-mac."
echo "You will only be prompted to enter the password for the GPG key once per year or when the gpg-agent is process is terminated."

echo "Verifying the configuration..."

# Create a test directory named "git-gpg-setup-verification-test"
if [ -d "git-gpg-setup-verification-test" ]; then
  # If the directory already exists, delete it
  rm -rf "git-gpg-setup-verification-test"
fi

# Create the directory
mkdir "git-gpg-setup-verification-test"

# Change into the test directory
cd git-gpg-setup-verification-test

# Initialize a git repository in the test directory
git init

# Add a file to the staging area
echo "test" > test.txt
git add test.txt

# Make a test commit
git commit --allow-empty -m "Test commit"

# Verify the signature of the test commit
git log --show-signature -1

# Navigate back to the parent directory
cd ..

# Remove the test directory
rm -rf "git-gpg-setup-verification-test"

echo "Verification test completed."
echo "If the signature and GPG key are displayed correctly, then your configuration is working as expected."

# Ask the user if they want to show the public key
echo "Do you want to print out the public key? (y/N)"
read -p "N" print_key

if [ "$print_key" = "y" ]; then
  gpg --armor --export "$key_id"
fi

echo -e "Visit the following URL to add your GPG key to your GitHub account:\n\033[34mhttps://docs.github.com/en/authentication/managing-commit-signature-verification/adding-a-gpg-key-to-your-github-account\033[0m"

