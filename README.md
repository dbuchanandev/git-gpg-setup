# Git GPG Setup Script for macOS

This script installs and configures GPG (GNU Privacy Guard) on a macOS machine and configures Git to use GPG to sign commits.

## Prerequisites

- Homebrew must be installed on your machine. If it is not, you can install it by running the following command:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
```

## How to use the script

1. Copy the script from [this link](https://raw.githubusercontent.com/<user>/<repo>/<branch>/git-gpg-setup.sh) and save it as `git-gpg-setup.sh`.
2. Make the script executable by running the following command: `chmod +x git-gpg-setup.sh`
3. Run the script by entering the following command: `./git-gpg-setup.sh`

The script will do the following:

- Check if `gpg` is installed and install it if necessary.
- Generate a GPG key.
- Find the ID of the key you just created.
- Configure Git to use your GPG key.
- Check if `pinentry-mac` is installed and install it if necessary.
- Create a `gpg-agent` configuration file.
- Set the default input value to one month (30 days or 2592000 seconds).
- Ask the user how long they would like the `gpg-agent` to cache the password.
- Set the `default-cache-ttl` and `max-cache-ttl` options in the `gpg-agent.conf` file.
- Restart `gpg-agent` to apply the configuration.
- Configure Git to use `gpg` as the GPG program.
- Configure Git to automatically sign commits with your GPG key.

The script will also verify the configuration by creating a local test git repository, making a commit, and verifying the signature of the commit. The test repository and commit will be discarded and any untracked files and directories will be removed at the end of the verification test.

If the signature and GPG key are displayed correctly, then your configuration is working as expected. 

Visit [this link](https://docs.github.com/en/authentication/managing-commit-signature-verification/adding-a-gpg-key-to-your-github-account) for documentation on how to add the GPG key to your GitHub account.

