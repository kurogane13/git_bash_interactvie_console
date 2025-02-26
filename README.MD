# GitHub CLI Tool

## Author: Gustavo Wydler Azuaga
## Release date: 09/23/2024

- A command-line interface (CLI) tool for managing Git and GitHub operations efficiently. 
- This tool simplifies the process of working with Git repositories, handling everything from authentication and branch management to commits, pushes, and merges.

## Upgraded Version release: 02/26/2025

## Included in this new version:

* **Some of the new important features**:
  - gh authentication with ssh
  - gh switcher to switch between github accounts or identities
  - Enahnced validation for creation and deletion of repos an branches in functions
  - Improved ssh validation in functions
  
* **To use this new version with the gh auth login**:

  - When adding multiple accounts or github identities, follow the following structure of the ssh config file:
  
  ```bash
  # Default GitHub Account (Switches Dynamically)
  Host github.com
	HostName github.com
	User git
	IdentityFile ~/.ssh/current_github_key
	IdentitiesOnly yes

  # majinga79 GitHub Account
  Host github.com-user1
	HostName github.com
	User git
	IdentityFile ~/.ssh/id_ed25519_user1
	IdentitiesOnly yes

  # kurogane13 GitHub Account
  Host github.com-user2
	HostName github.com
	User git
	IdentityFile ~/.ssh/id_ed25519_user2
	IdentitiesOnly yes

  ```
  - How this works:
  
    - The identity files or key files in the config file shown above, should start with the following syntax: ~/.ssh/id_ed25519_username_here
    - Everytime you wish to switch to a different account or user:
    
      - The gh auth login instance will start
      - It will ask to revalidate login (reply yes)
      - A new ssh key will be asked to create (reply no)
      - Select the Paste an authentication token option
      - The program will look for the identity of the gh authenticated user in: $HOME/snap/gh/502/.config/gh/hosts.yml
      - It will extract the user id from it
      - It will identify the user and match it with the user found in the .ssh/config file, following the pattern github.com-$userx
      - Once it matches the user, the Identity file will be sent to a symlink (~/.ssh/current_github_key), which will be generated
      - The ssh query (ssh -T git@github.com) runs to attempt validating the correct user.

## Table of Contents

* Requirements

**Install the gh utility with snap**:
   ```bash
   sudo snap install gh
   ```
## Requirements

* **Operating System**: Linux (AlmaLinux, CentOS, Ubuntu, etc.)
* **Dependencies**:
  - `git`
  - `gh`
  - `ssh`
  - `bash`

## Installation

**Clone the Repository**:
   ```bash
   git clone https://github.com/kurogane13/git_bash_interactvie_console.git

   cd git_bash_interactvie_console
   bash git_cli_console.sh
  ```

