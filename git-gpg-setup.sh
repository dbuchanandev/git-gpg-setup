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

# Generate a GPG key
echo "Generating GPG key..."
gpg --full-generate-key

# List GPG keys to find the ID of the key you just created
echo "Finding GPG key ID..."
key_id=$(gpg --list-secret-keys | grep 'sec' | awk '{print $2}' | cut -d '/' -f 2)

# Configure Git to use your GPG key
echo "Configuring Git to use GPG key..."
git config --global user.signingkey "$key_id"

# Prompt the user to update their global Git configuration with the email matching the GPG key

echo "Would you like to update your global Git configuration to use the email matching the GPG key that was created?"
read -p "Enter y for yes or n for no (default: y): " update_git_config

# If the user didn't enter any input or entered y, look up the email for the key and set the git configuration to use that email

if [ -z "$update_git_config" ] || [ "$update_git_config" = "y" ]; then
email=$(gpg --list-secret-keys --with-colons | grep '^uid' | cut -d ':' -f 10)
git config --global user.email "$email"
echo "Your global Git configuration has been updated to use the email $email."
else
echo "Your global Git configuration was not updated."
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
if [ -f ~/.bash_profile ] && [ -f ~/.zshrc ]; then
# Modify ~/.zshrc if both ~/.bash_profile and ~/.zshrc exist
echo "Modifying ~/.zshrc to set GPG_TTY and start gpg-agent..."
echo "if [ -f ~/.gnupg/gpg-agent.conf ]; then" >> ~/.zshrc
echo " source ~/.gnupg/gpg-agent.env" >> ~/.zshrc
echo " if ! pgrep -u "$(id -u)" gpg-agent > /dev/null; then" >> ~/.zshrc
echo " gpg-agent --daemon --write-env-file ~/.gnupg/gpg-agent.env" >> ~/.zshrc
echo " fi" >> ~/.zshrc
echo "fi" >> ~/.zshrc
elif [ -f ~/.bash_profile ]; then

# Modify ~/.bash_profile if only ~/.bash_profile exists

echo "Modifying ~/.bash_profile to set GPG_TTY and start gpg-agent..."
echo "if [ -f ~/.gnupg/gpg-agent.conf ]; then" >> ~/.bash_profile
echo " source ~/.gnupg/gpg-agent.env" >> ~/.bash_profile
echo " if ! pgrep -u "$(id -u)" gpg-agent > /dev/null; then" >> ~/.bash_profile
echo " gpg-agent --daemon --write-env-file ~/.gnupg/gpg-agent.env" >> ~/.bash_profile
echo " fi" >> ~/.bash_profile
echo "fi" >> ~/.bash_profile
else

# Create ~/.bash_profile if neither file exists

echo "Creating ~/.bash_profile to set GPG_TTY and start gpg-agent..."
echo "if [ -f ~/.gnupg/gpg-agent.conf ]; then" >> ~/.bash_profile
echo " source ~/.gnupg/gpg-agent.env" >> ~/.bash_profile
echo " if ! pgrep -u "$(id -u)" gpg-agent > /dev/null; then" >> ~/.bash_profile
echo " gpg-agent --daemon --write-env-file ~/.gnupg/gpg-agent.env" >> ~/.bash_profile
echo " fi" >> ~/.bash_profile
echo "fi" >> ~/.bash_profile
fi

# Stop gpg-agent
echo "Stopping gpg-agent..."
if ! gpg-connect-agent killagent /bye; then
  echo "Error: Failed to stop gpg-agent"
  exit 1
fi

# Start gpg-agent
echo "Starting gpg-agent..."
if ! gpg-agent --daemon --write-env-file ~/.gnupg/gpg-agent.env; then
  echo "Error: Failed to start gpg-agent"
  exit 1
fi

# Configure Git to use gpg as the GPG program

echo "Configuring Git to use gpg as the GPG program..."
git config --global gpg.program gpg

# Configure Git to automatically sign commits with your GPG key

echo "Configuring Git to automatically sign commits with your GPG key..."
git config --global commit.gpgsign true

echo "Done! Git is now configured to use your GPG key stored in the macOS keychain with 
pinentry-mac."
echo "You will only be prompted to enter the password for the GPG key once per year or when the gpg-agent is process is terminated."

echo "Verifying the configuration..."

# Create a test directory named "git-gpg-setup-verification-test"
mkdir git-gpg-setup-verification-test

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

# Discard the test commit
git reset --hard HEAD~1

# Remove any untracked files and directories
git clean -f -d

# Navigate back to the parent directory
cd ..

# Remove the test directory
rm -r git-gpg-setup-verification-test

echo "Verification test completed."
echo "If the signature and GPG key are displayed correctly, then your configuration is working as expected."

echo -e "Visit the following URL to add your GPG key to your GitHub 
account:\n\033]8;;https://docs.github.com/en/authentication/managing-commit-signature-verification/adding-a-gpg-key-to-your-github-account\033\\"
