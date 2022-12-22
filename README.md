# Git GPG Setup Script for macOS

This script installs and configures GPG (GNU Privacy Guard) on a macOS machine and configures Git to use GPG to sign commits.

## Prerequisites

- Homebrew must be installed on your machine. If it is not, you can install it by running the following command:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
```

## How to use the script

1. Download the script from [this link](git-gpg-setup.sh) and save it as `git-gpg-setup.sh`.
2. Make the script executable by running the following command: `chmod +x git-gpg-setup.sh`
3. Run the script by entering the following command: `./git-gpg-setup.sh`

The script will do the following:

- Check if `gpg` is installed and install it if necessary.
- Check if `pinentry-mac` is installed and install it if necessary.
- Generate a GPG key.
- Configure Git to use your GPG key.
- Create a `gpg-agent` configuration file.
- Ask the user how long they would like the `gpg-agent` to cache the password.
- Configure Git to automatically sign commits with your GPG key.

The script will also verify the configuration by creating a local test git repository, making a commit, and verifying the signature of the commit. The test repository will be removed at the end of the verification test.

If the signature and GPG key are displayed correctly, then your configuration is working as expected. 

Visit [this link](https://docs.github.com/en/authentication/managing-commit-signature-verification/adding-a-gpg-key-to-your-github-account) for documentation on how to add the GPG key to your GitHub account.

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.
