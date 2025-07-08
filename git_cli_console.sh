#!/bin/bash

function gh_tool() {
	# Check if the 'gh' command exists
	if command -v gh >/dev/null 2>&1; then
	    echo
		echo "'gh' tool is already installed."
	else
	    echo
		echo "'gh' tool is not installed. Installing it via Snap..."

		# Check if Snap is installed
		if command -v snap >/dev/null 2>&1; then
		    echo
			sudo snap install gh
			echo
			echo "'gh' has been installed."
		else
			echo "Snap is not installed. Please install Snap first to use this script."
			echo
		fi
	fi
}

gh_tool

function delete_remote_repo() {

	echo " "
	read -p "Enter remote branch name to delete: " delete_remote_branch
	echo
	echo "Querying remote branch: $delete_remote_branch"
	echo
	gh repo view $delete_remote_branch
	echo " "
	gh repo delete $delete_remote_branch
	echo " "
	echo "Re-Querying remote branch: $delete_remote_branch"
	echo
	gh repo view $delete_remote_branch
	echo
	read -p "Press enter to return to the menu: " enter

}

function create_remote_repo() {
    echo
    echo "🔍 Checking working directory: $PWD"
    echo

    # Prompt user for repository name
    read -p "Provide the name of the repo you want to create: " repo_name

    if [[ -d "$repo_name" ]]; then
        echo
        echo "⚠️ Repo '$repo_name' already exists."

        if [[ -d "$repo_name/.git" ]]; then
            echo
            echo "✅ Repo '$repo_name' is already initialized."
            echo
            read -p "You cannot create this repo because it already exists. Press Enter to return to the main menu: " enter
            main_program
        else
            echo "📂 Directory exists but is not a Git repo. Initializing..."
            cd "$repo_name" || exit
            git init
        fi
    else
        echo
        echo "⚠️ This directory does not exist."
        echo
        while true; do
          echo
          echo "1 - Create the directory with $PWD/$repo_name"
          echo "2 - Return to the main program menu"
          echo
          read -p "Provide an operation numner to proceed: " choice
          case $choice in
            1)
              echo "Creating directory: $PWD/$repo_name"
              mkdir $PWD/$repo_name
              cd $PWD/$repo_name
              echo
              echo "Initializing Git repo in $PWD/$repo_name"
              git init
              break
              ;;
            2)
              main_program
              ;;
            *)
              echo
              echo "❌ Invalid choice. Please enter 1 or 2."
              ;;
          esac
        done
    fi

    # Prompt for GitHub username
    echo
    read -p "Enter the GitHub account to create the repo under: " github_user

    # Validate input
    if [[ -z "$github_user" ]]; then
        echo "❌ Error: GitHub account name cannot be empty."
        return 1
    fi

    # Run the remote URLs manager before creating the repo
    remote_urls_manager

    # Detect default branch name (master or main)
    default_branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "master")

    # Check if the repository already exists on GitHub
    if gh repo view "$github_user/$repo_name" &>/dev/null; then
        echo "⚠️ Repository '$repo_name' already exists under '$github_user'."
        read -p "Press Enter to return to the menu: "
        return
    fi

    # Create and commit README.md
    current_date=$(date +"%m/%d/%Y")
    cat <<EOF > README.md
# 📅 Date Created: $current_date

---

# $repo_name

Welcome to the **$repo_name** repository! 🎉

## 📌 About This Project
This repository serves as a starting point for version-controlled projects.
Feel free to modify and expand upon it as needed.

## 🚀 Getting Started

1. Clone this repository:
   \`\`\`bash
   git clone git@github.com:$github_user/$repo_name.git
   \`\`\`
2. Navigate into the directory:
   \`\`\`bash
   cd $repo_name
   \`\`\`

##
---
💡 *Happy coding! 🚀*
EOF
    git add README.md
    git commit -m "Initial commit"

    # Display the final remote URLs before proceeding
    echo
    echo "📡 Final remote URLs set for this repository:"
    git remote -v
    echo

    # Confirm repository creation
    gh auth status
    echo
    read -p "Proceed with creating the remote repository under '$github_user'? (y/n): " confirm
    if [[ $confirm != "y" && $confirm != "Y" ]]; then
        echo "❌ Repository creation aborted."
        return
    fi

    # Create the remote repository on GitHub
    echo
    echo "🔧 Creating GitHub repository '$repo_name' under '$github_user'..."
    gh repo create "$github_user/$repo_name" --public --source=. --remote=upstream

    # Construct the correct remote repository URL
    remote_url="git@github.com:$github_user/$repo_name.git"

    # Add the correct remote URL
    git remote add origin "$remote_url"

    # Push the initial commit using the correct branch
    echo
    echo "🚀 Pushing initial commit to '$remote_url'..."
    git push -u origin "$default_branch"

    echo " "
    read -p "Press Enter to return to the menu: "
}

function git_configure_account() {

	while true; do
		echo " "
		echo "Configure Git Submenu accessed"
		echo " "
		echo "1. Set Username"
		echo "2. Set Email"
		echo "3. List Git Configuration"
		echo "4. Back to Main Menu"
		echo " "
		read -p "Select an option (1-4): " git_config_choice

		case $git_config_choice in
			1)
				read -p "Enter your Git username: " git_username
				git config --global user.name "$git_username"
				;;
			2)
				read -p "Enter your Git email: " git_email
				git config --global user.email "$git_email"
				;;
			3)
				echo " "
				echo "Listing git config: "
				echo " "
				git config --global --list
				echo " "
				read -p "Press enter to return to the menu: " enter
				;;
			4)
				break
				;;
			*)
				echo " "
				echo "ERROR!"
				echo "Invalid option. Please select an option from 1 to 4."
				;;
		esac
	done

}

function git_authentication() {

	echo " "
	echo "Working on path/repo: "$PWD
	echo " "
	read -p "Enter GitHub repository URL: " repo_url
	git remote set-url origin $repo_url

}

function test_ssh_connection() {

	echo " "
	echo "Working on path/repo: "$PWD
	echo " "
	echo "SSH testing mode accessed."
	echo " "
	read -p "Press enter to test the ssh connection to git@github.com now: " enter
	eval "$(ssh-agent -s)"
	ssh-add -D
	ssh -vT git@github.com
	echo " "
	read -p "Connection test finalized, press enter to get back to the main menu: " enter
	echo " "

}

# Function to prompt for directory and check if it exists
function get_directory() {
    read -p "Enter the directory path: " repo_dir

    if [[ ! -d "$repo_dir" ]]; then
        read -p "Directory does not exist. Do you want to create it? (y/n): " create_dir
        if [[ "$create_dir" == "y" || "$create_dir" == "Y" ]]; then
            mkdir -p "$repo_dir"
            echo "Directory $repo_dir created."
        else
            echo "Directory does not exist. Exiting."
            exit 1
        fi
    fi

    cd "$repo_dir" || { echo "Failed to access $repo_dir. Exiting."; exit 1; }
}

# Function to check if the directory is a Git repository and initialize if necessary
function check_git_repo() {
    if [[ ! -d ".git" ]]; then
        echo "This directory is not a Git repository. Initializing..."
        git init
    fi
}

# Function to check if a remote repository exists on GitHub
function check_remote_repo_exists() {
    remote_url=$(git remote get-url origin 2>/dev/null)

    if [[ -z "$remote_url" ]]; then
        echo "No remote repository configured for this directory."
        read -p "Enter the GitHub repository name (e.g., user/repo): " repo_name

        echo "Checking if the repository exists on GitHub..."
        if gh repo view "$repo_name" &>/dev/null; then
            echo "Remote repository '$repo_name' found. Setting up local repo..."
            git remote add origin "git@github.com:$repo_name.git"
        else
            read -p "Remote repository does not exist. Do you want to create it? (y/n): " create_repo
            if [[ "$create_repo" == "y" || "$create_repo" == "Y" ]]; then
                echo "Creating GitHub repository '$repo_name'..."
                gh repo create "$repo_name" --public --source=. --remote=origin
            else
                echo "No remote repository available. Exiting."
                exit 1
            fi
        fi
    fi
}

# Function to pull from the remote repository
function pull_from_remote() {
    echo " "
    echo "Pull from remote branch menu accessed."
    echo " "
    get_directory
    check_git_repo
    check_remote_repo_exists
    echo
    echo "Showing current branch:"
    echo " "
    git branch
    echo
    read -p "Press enter to pull from Remote Branch: "
    echo
    echo "Checking connection to GitHub..."
    eval "$(ssh-agent -s)"
    ssh -T git@github.com || { echo "GitHub authentication failed. Exiting."; return 1; }
    echo " "
    git pull origin "$(git branch --show-current)"

    echo " "
    read -p "Press enter to return to the menu: "
}

# Function to push to the remote repository
function push_to_remote() {
    echo " "
    echo "Push to remote branch menu accessed."
    echo " "

    get_directory
    check_git_repo
    check_remote_repo_exists
	echo
    echo "Showing current branch:"
    echo " "
    git branch
    echo " "
    read -p "Press enter to push to the Remote Branch: "
    echo
    echo "Setting up SSH authentication for GitHub..."
    echo
    git config --global url."git@github.com:".insteadOf "https://github.com/"
    echo
    eval "$(ssh-agent -s)"
    ssh -T git@github.com || { echo "GitHub authentication failed. Exiting."; return 1; }
    echo " "
    current_branch=$(git branch --show-current)
    git push --set-upstream origin "$current_branch"
    echo " "
    read -p "Press enter to return to the menu: "
}

function create_local_branch() {
    echo
    read -p "Enter the path to the local repository: " repo_dir
    repo_dir=${repo_dir:-$PWD}  # Default to current directory if empty
    repo_dir=$(eval echo "$repo_dir")  # Expand ~ (home directory)

    # Check if the directory exists
    if [[ ! -d "$repo_dir" ]]; then
        echo "Error: Directory does not exist."
        read -p "Do you want to create this directory? (y/n): " create_dir
        if [[ "$create_dir" == "y" ]]; then
            mkdir -p "$repo_dir"
            echo "Created directory: $repo_dir"
        else
            echo "Operation aborted."
            return 1
        fi
    fi

    # Navigate to the repository directory
    cd "$repo_dir" || { echo "Error: Failed to access $repo_dir. Exiting."; return 1; }

    # Check if it's a Git repository
    if [[ ! -d ".git" ]]; then
        echo "This is not a Git repository."
        read -p "Do you want to initialize a Git repository here? (y/n): " init_git
        if [[ "$init_git" == "y" ]]; then
            git init
            echo "Initialized new Git repository in $repo_dir."
        else
            echo "Operation aborted."
            return 1
        fi
    fi

    # Ensure the repository has an initial commit
    if [[ -z $(git rev-parse --verify HEAD 2>/dev/null) ]]; then
        echo "Repository has no commits. Creating an initial commit..."
        touch README.md
        git add README.md
        git commit -m "Initial commit" > /dev/null 2>&1
        echo "Initial commit created."
    fi

    echo
    echo "Working in repository: $PWD"
    echo

    # Prompt for branch name
    read -p "Enter the name of the local branch to create: " local_branch
    echo

    # Create and switch to the new branch
    git checkout -b "$local_branch"
    echo "Branch '$local_branch' created successfully."
    echo

    # List available branches
    echo "Listing all branches:"
    echo "---------------------"
    git branch
    echo

    read -p "Press enter to return to the menu: "
}

function delete_local_branch() {
    echo
    read -p "Enter the path to the local repository: " repo_dir
    repo_dir=${repo_dir:-$PWD}  # Default to current directory if empty
    repo_dir=$(eval echo "$repo_dir")  # Expand ~ (home directory)

    # Ensure the provided path exists
    if [[ ! -d "$repo_dir" ]]; then
        echo "Error: Directory '$repo_dir' does not exist. Exiting."
        echo
        read -p "Press enter to return to the menu: "
        return
    fi

    # Navigate to the repository directory
    cd "$repo_dir" || { echo "Error: Failed to access $repo_dir. Exiting."; return 1; }

    # Ensure it's a Git repository
    if [[ ! -d ".git" ]]; then
        echo "Error: This is not a Git repository. Exiting."
        echo
        read -p "Press enter to return to the menu: "
        return
    fi

    echo
    echo "Working in repository: $PWD"
    echo

    # List local branches
    local_branches=$(git branch --format="%(refname:short)")

    if [[ -z "$local_branches" ]]; then
        echo "No local branches found in this repository."
        echo
        read -p "Press enter to return to the menu: "
        return
    fi

    echo "Available branches:"
    echo "-------------------"
    echo "$local_branches"
    echo

    # Prompt user for branch to delete
    read -p "Copy and paste the branch name to delete: " delete_branch
    echo

    # Ensure the branch exists before attempting to delete
    if git rev-parse --verify "$delete_branch" >/dev/null 2>&1; then
        read -p "Are you sure you want to delete branch '$delete_branch' in $PWD? (y/n): " confirm_delete
        echo

        if [[ "$confirm_delete" == "y" ]]; then
            # Get current branch
            current_branch=$(git rev-parse --abbrev-ref HEAD)

            # If deleting the currently checked-out branch (including master)
            if [[ "$current_branch" == "$delete_branch" ]]; then
                echo "WARNING: You are trying to delete the currently checked-out branch '$delete_branch'."
                echo "To proceed, a temporary branch 'temp_branch' will be created."
                read -p "Continue? (y/n): " confirm_temp
                if [[ "$confirm_temp" != "y" ]]; then
                    echo "Branch deletion aborted."
                    read -p "Press enter to return to the menu: "
                    return
                fi

                # Create and switch to a temporary branch
                git checkout -b temp_branch
                echo "Switched to 'temp_branch'. Now deleting '$delete_branch'..."
            fi

            # Delete the target branch
            git branch -D "$delete_branch"
            echo "Branch '$delete_branch' has been deleted."

            # If `master` was deleted, ask if they want to rename temp_branch
            if [[ "$delete_branch" == "master" ]]; then
                echo
                read -p "Master branch was deleted. Do you want to rename 'temp_branch' to 'master'? (y/n): " rename_master
                if [[ "$rename_master" == "y" ]]; then
                    git branch -m master
                    echo "Branch 'temp_branch' has been renamed to 'master'."
                else
                    echo "You are now on 'temp_branch'."
                fi
            fi
        else
            echo "Branch deletion aborted."
        fi
    else
        echo "Error: Branch '$delete_branch' does not exist in this repository."
    fi

    echo
    read -p "Press enter to return to the menu: "
}

delete_remote_branch() {
    # Prompt for the repository directory
    echo
	# Prompt the user for the repository path, default to current directory if empty
	read -rp "Enter the path to the Git repository (Press Enter to use current directory): " repo_path
	repo_path=${repo_path:-$PWD}  # Use current directory if input is empty

	# Print the selected repo path
	echo "Using repository path: $repo_path"

	# Validate that the directory exists
	if [[ ! -d "$repo_path" ]]; then
		echo "❌ Error: Directory '$repo_path' does not exist."
		exit 1
	fi

	# Validate that it's a Git repository
	if [[ ! -d "$repo_path/.git" ]]; then
		echo "❌ Error: '$repo_path' is not a valid Git repository."
		exit 1
	fi

	echo "✅ '$repo_path' is a valid Git repository!"
	echo
	git branch -r

    # Move into the repository directory
    cd "$repo_path" || { echo "❌ Error: Failed to enter directory '$repo_path'"; return 1; }
	echo
    # Prompt for the branch name
    echo "Enter the remote branch name to delete."
    echo "Example syntax: 'repo_name/branch_name' (as seen in 'git branch -r', but without 'origin/')"
    echo
    read -rp "Remote branch name: " remote_branch_name

    # Extract only the branch name (remove repo prefix)
    branch_name="${remote_branch_name#*/}"
	echo
    # Fetch latest remote branches
    git fetch origin --prune

    # List available branches for validation
    echo "🔎 Checking existing branches..."
    echo
    git branch -r
    git branch

    # Check if the local branch exists
    if git show-ref --verify --quiet "refs/heads/$branch_name"; then
        echo
        echo "✅ Local branch '$branch_name' exists."
    else
        echo
        echo "⚠️ Warning: Local branch '$branch_name' does not exist. Checking remotely..."
    fi

    # Check if the remote branch exists
    if git branch -r | grep -qE "^\s*origin/$branch_name\$"; then
        # Confirmation prompt
        echo
        read -rp "Are you sure you want to delete the remote branch 'origin/$branch_name'? (y/n): " confirmation
        if [[ "$confirmation" == "y" ]]; then
            # Delete the remote branch
            git push origin --delete "$branch_name"
            echo
            echo "✅ Remote branch 'origin/$branch_name' has been deleted."
        else
            echo
            echo "❌ Operation canceled."
        fi
    else
        echo
        echo "⚠️ Error: Remote branch 'origin/$branch_name' does not exist."
        echo
        echo "Make sure you have entered the correct branch name as seen in 'git branch -r'."
    fi
}

create_remote_branch() {
    # Prompt for the repository directory
    echo

	# Prompt the user for the repository path, default to current directory if empty
	read -rp "Enter the path to the Git repository (Press Enter to use current directory): " repo_path
	repo_path=${repo_path:-$PWD}  # Use current directory if input is empty

	# Print the selected repo path
	echo "Using repository path: $repo_path"

	# Validate that the directory exists
	if [[ ! -d "$repo_path" ]]; then
		echo "❌ Error: Directory '$repo_path' does not exist."
		exit 1
	fi

	# Validate that it's a Git repository
	if [[ ! -d "$repo_path/.git" ]]; then
		echo "❌ Error: '$repo_path' is not a valid Git repository."
		exit 1
	fi

	echo "✅ '$repo_path' is a valid Git repository!"

    # Move into the repository directory
    cd "$repo_path" || { echo "❌ Error: Failed to enter directory '$repo_path'"; return 1; }

    # Ensure the repository has a remote named 'origin'
    if ! git remote get-url origin > /dev/null 2>&1; then
        echo
        echo "❌ Error: No remote repository found. Ensure 'origin' is set up."
        return 1
    fi

    # Fetch the latest remote branches
    git fetch origin --prune

    # Prompt for the new branch name
    echo
    echo "Enter the name of the new remote branch."
    read -rp "New branch name: " branch_name

    # Check if the branch already exists locally
    if git show-ref --verify --quiet "refs/heads/$branch_name"; then
        echo
        echo "⚠️ Error: Local branch '$branch_name' already exists."
        return 1
    fi

    # Check if the branch already exists remotely
    if git branch -r | grep -qE "^\s*origin/$branch_name\$"; then
        echo
        echo "⚠️ Error: Remote branch 'origin/$branch_name' already exists."
        return 1
    fi

    # Create the local branch
    git checkout -b "$branch_name"

    # Push the new branch to the remote repository
    echo
    git push -u origin "$branch_name"
    echo
    echo "✅ Remote branch 'origin/$branch_name' has been created successfully."
}

delete_untracked_branches() {
    echo
    read -rp "Enter the path to the Git repository (Press Enter to use current directory): " repo_path
    repo_path=${repo_path:-$PWD}  # Default to current directory if empty
    repo_path=$(eval echo "$repo_path")  # Expand ~ (home directory)

    # Validate that the directory exists
    if [[ ! -d "$repo_path" ]]; then
        echo
        echo "❌ Error: Directory '$repo_path' does not exist."
        return 1
    fi

    # Validate that it's a Git repository
    if [[ ! -d "$repo_path/.git" ]]; then
        echo
        echo "❌ Error: '$repo_path' is not a valid Git repository."
        return 1
    fi

    # Move into the repository directory
    cd "$repo_path" || { echo "❌ Error: Failed to enter directory '$repo_path'"; return 1; }

    # Fetch latest remote branches
    echo
    echo "🔄 Fetching the latest remote branches..."
    git fetch --prune

    # List all local branches
    echo
    echo "🔎 Local branches in this repository:"
    git branch
    echo

    # List all remote branches
    echo
    echo "🔎 Remote branches in this repository:"
    git branch -r
    echo

    # Get current branch name
    current_branch=$(git rev-parse --abbrev-ref HEAD)

    # Find local branches that no longer have a remote
    echo "🔎 Checking for local branches without a remote counterpart..."
    untracked_branches=($(git branch --format "%(refname:short)" | while read -r branch; do
        if ! git ls-remote --exit-code --heads origin "$branch" > /dev/null 2>&1; then
            echo "$branch"
        fi
    done))

    # If no untracked branches exist, exit
    if [[ ${#untracked_branches[@]} -eq 0 ]]; then
        echo
        echo "✅ No local branches found without a remote counterpart."
        return 0
    fi

    # Prompt the user for deletion
    echo
    echo "⚠️ The following local branches have no remote counterpart:"
    for branch in "${untracked_branches[@]}"; do
        echo
        read -rp "Delete local branch '$branch'? (y/n): " confirm
        if [[ "$confirm" == "y" ]]; then
            if [[ "$branch" == "$current_branch" ]]; then
                echo
                echo "⚠️ Cannot delete the currently checked-out branch '$branch'. Switching to 'master' first..."
                git checkout master || git checkout main
            fi
            git branch -D "$branch"
            echo
            echo "✅ Deleted local branch '$branch'."
        else
            echo
            echo "❌ Skipping deletion of '$branch'."
        fi
    done
    echo
    echo "🎉 Cleanup complete!"
}

function remote_urls_manager() {
  while true; do
    echo
    echo "----------------------------------------"
    echo " Git Remote URLs Manager"
    echo "----------------------------------------"
    echo ""
    echo "📂 Working on repo: $PWD"
    echo ""
    echo "🔍 Current working branch:"
    git branch
    echo ""
    echo "🌐 Listing remote URLs (fetch & push):"
    git remote -v
    echo ""

    echo "✅ Examples of correct remote URL formats:"
    echo " - SSH:   git@github.com:your-username/repository.git"
    echo " - HTTPS: https://github.com/your-username/repository.git"
    echo ""

    echo "Options:"
    echo "1) Change 'origin' URL"
    echo "2) Change 'upstream' URL"
    echo "3) Keep URLs and exit"
    echo ""
    read -p "Select an option (1/2/3): " option

    case $option in
        1)
            echo
            read -p "Enter the new 'origin' URL: " new_origin
            if [[ "$new_origin" =~ ^(git@github.com:|https://github.com/) ]]; then
                echo
                read -p "Are you sure you want to update 'origin' to $new_origin? (y/n): " confirm
                if [[ $confirm == "y" || $confirm == "Y" ]]; then
                    if git remote get-url origin &>/dev/null; then
                        git remote set-url origin "$new_origin"
                    else
                        git remote add origin "$new_origin"
                    fi
                    echo
                    echo "✅ Origin URL updated successfully!"
                else
                    echo
                    echo "⚠️ No changes made."
                fi
            else
                echo
                echo "❌ Error: Invalid repository URL. Must be SSH or HTTPS format."
            fi
            ;;
        2)
            echo
            read -p "Enter the new 'upstream' URL: " new_upstream
            if [[ "$new_upstream" =~ ^(git@github.com:|https://github.com/) ]]; then
                echo
                read -p "Are you sure you want to update 'upstream' to $new_upstream? (y/n): " confirm
                if [[ $confirm == "y" || $confirm == "Y" ]]; then
                    if git remote get-url upstream &>/dev/null; then
                        git remote set-url upstream "$new_upstream"
                    else
                        git remote add upstream "$new_upstream"
                    fi
                    echo
                    echo "✅ Upstream URL updated successfully!"
                else
                    echo
                    echo "⚠️ No changes made."
                fi
            else
                echo
                echo "❌ Error: Invalid repository URL. Must be SSH or HTTPS format."
            fi
            ;;
        3)
            echo
            echo "✅ Keeping current URLs and exiting..."
            break
            ;;
        *)
            echo
            echo "⚠️ Invalid option. Press Enter to return to the menu."
            read
            ;;
    esac
  done
}

function git_stats() {

# Define Colors
RED='\033[1;31m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
MAGENTA='\033[1;35m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Function to fetch details for a specific repository
fetch_repo_details() {
    local REPO="$1"

    echo -e "\n${BLUE}🔍 Fetching activity for repository: ${CYAN}$REPO${NC}"

    # Fetch branches
    echo -e "\n${MAGENTA}📂 Listing all branches:${NC}"
    gh api "repos/$REPO/branches" --jq '.[] | "🌿 \(.name)"' || echo -e "${RED}❌ Unable to fetch branches.${NC}"

    # Fetch latest commits
    echo -e "\n${MAGENTA}📜 Latest commits on each branch:${NC}"
    for branch in $(gh api "repos/$REPO/branches" --jq '.[].name'); do
        echo -e "\n${CYAN}📌 Branch: ${YELLOW}$branch${NC}"
        gh api "repos/$REPO/commits?sha=$branch" --jq '.[] | "🔹 \(.commit.author.date) - \(.commit.message) by \(.commit.author.name)"' | head -n 5
    done

    # Fetch deleted branches (from merged PRs)
    echo -e "\n${MAGENTA}🚀 Deleted branches (from merged PRs):${NC}"
    gh api "repos/$REPO/pulls?state=closed" --jq '.[] | select(.merged_at != null) | "❌ Deleted branch: 🌿 \(.head.ref) (Merged on: \(.merged_at))"' || echo -e "${RED}❌ No deleted branches found.${NC}"

    # Fetch pull requests
    echo -e "\n${MAGENTA}📬 Pull Requests:${NC}"
    gh pr list --repo "$REPO" --state all --limit 10 --json title,author,createdAt,state --jq '.[] | "📌 \(.state | ascii_upcase): \(.title) by \(.author.login) on \(.createdAt)"'

    # Fetch issues
    echo -e "\n${MAGENTA}🐞 Issues:${NC}"
    gh issue list --repo "$REPO" --state all --limit 10 --json title,author,createdAt,state --jq '.[] | "📌 \(.state | ascii_upcase): \(.title) by \(.author.login) on \(.createdAt)"'

    # Fetch discussions
    echo -e "\n${MAGENTA}💬 Discussions:${NC}"
    gh api "repos/$REPO/discussions" --jq '.[] | "📌 \(.title) by \(.user.login) on \(.created_at)"' 2>/dev/null || echo -e "${RED}❌ No discussions found.${NC}"

    echo -e "\n${GREEN}✅ Done!${NC}\n"
}

# Function to list all repositories for a user and fetch details for each
list_repos() {
    read -p "🔹 Enter GitHub username: " USERNAME
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    LOGFILE="${USERNAME}_all_repos_data_${TIMESTAMP}.log"

    echo -e "\n${BLUE}📂 Fetching repositories for user: ${CYAN}$USERNAME${NC}" | tee -a "$LOGFILE"

    REPO_LIST=$(gh api "users/$USERNAME/repos" --jq '.[].full_name' 2>/dev/null)

    if [[ -z "$REPO_LIST" ]]; then
        echo -e "${RED}❌ No repositories found or unable to fetch data.${NC}\n" | tee -a "$LOGFILE"
        return
    fi

    for REPO in $REPO_LIST; do
        echo -e "\n${GREEN}========================================${NC}" | tee -a "$LOGFILE"
        echo -e "${YELLOW}📂 Processing repository: ${CYAN}$REPO${NC}" | tee -a "$LOGFILE"
        echo -e "${GREEN}========================================${NC}\n" | tee -a "$LOGFILE"

        fetch_repo_details "$REPO" | tee -a "$LOGFILE"
    done

    echo -e "\n${GREEN}✅ All repositories processed! Log saved to: ${WHITE}$LOGFILE${NC}\n" | tee -a "$LOGFILE"

    read -p "Press enter to return to the main menu: " enter
}

# Function to query a specific repository
query_repo() {
    read -p "🔹 Enter GitHub username: " USERNAME
    read -p "🔹 Enter repository name: " REPO_NAME

    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    LOGFILE="${USERNAME}_${REPO_NAME}_${TIMESTAMP}.log"

    REPO="$USERNAME/$REPO_NAME"

    fetch_repo_details "$REPO" | tee -a $LOGFILE
}

# Function to list log and HTML files, and allow viewing
view_logs() {
    echo -e "\n${MAGENTA}📂 Available files in the current directory:${NC}\n"

    LOG_FILES=$(ls *.log 2>/dev/null)
    HTML_FILES=$(ls *.html 2>/dev/null)

    if [[ -n "$LOG_FILES" ]]; then
        echo -e "${GREEN}✅ Log files found:${NC}\n"
        ls -lha *.log
        echo
    else
        echo -e "${RED}❌ No log files found.${NC}\n"
    fi

    if [[ -n "$HTML_FILES" ]]; then
        echo -e "${GREEN}✅ HTML files found:${NC}\n"
        ls -lha *.html
        echo
    else
        echo -e "${RED}❌ No HTML files found.${NC}\n"
    fi

    echo -e "\n${YELLOW}🔹 Copy and paste a filename from the list above to view it:${NC}\n"
    read -p "📖 File to view: " FILE

    if [[ -f "$FILE" ]]; then
        if [[ "$FILE" == *.log ]]; then
            echo -e "\n${CYAN}📖 Displaying log file: ${WHITE}$FILE${NC}\n"
            cat "$FILE"
        elif [[ "$FILE" == *.html ]]; then
            echo -e "\n${GREEN}🌍 Opening HTML file in browser: ${WHITE}$FILE${NC}\n"
            xdg-open "$FILE" &>/dev/null || echo -e "${RED}❌ Unable to open in browser. Open manually: $FILE${NC}\n"
        else
            echo -e "${RED}❌ Invalid file type. Please select a .log or .html file.${NC}\n"
        fi
    else
        echo -e "${RED}❌ File not found. Please try again.${NC}\n"
    fi

    echo
    read -p "Press enter to return to main menu: " enter
}

# Function to search for a pattern in a log file
search_logs() {
    view_logs
    read -p "🔍 Enter the search pattern: " PATTERN
    grep --color=always -i "$PATTERN" "$LOGFILE" || echo -e "${RED}❌ No matches found.${NC}\n"
    echo
    read -p "Press enter to return to main menu: " enter
}

# Function to delete a specific log file
delete_log() {

    echo
    if ls *.log &>/dev/null; then
      echo "✅ Log files found."
      echo
      ls -lha *.log
      echo
    else
        echo -e "${RED}❌ No log files found to delete${NC}\n"
        read -p "Press enter to return to main menu: " enter
    fi
    read -p "🗑️ Log file to delete: " LOGFILE

    if [[ -f "$LOGFILE" ]]; then
        echo
        echo
        read -p "🔹 ⚠️ WARNING: Are you sure you want to delete $LOGFILE? (y/n): " CONFIRM

        if [[ "$CONFIRM" == "y" ]]; then
            rm -rf "$LOGFILE"
            echo
            echo
            echo -e "${GREEN}✅ $LOGFILE deleted.${NC}\n"
        else
            echo
            echo -e "${RED}❌ Operation cancelled.${NC}\n"
        fi
    else
        echo
        echo -e "${RED}❌ File not found. Please try again.${NC}\n"
    fi
    echo
    read -p "Press enter to return to main menu: " enter
}

# Function to delete all logs
delete_all_logs() {
    echo -e "\n${RED}⚠️ WARNING: This will delete ALL log files in this path:  $PWD.${NC}"
    echo
    if ls *.log &>/dev/null; then
      echo -e "${GREEN}✅ Log files found.${NC}"
      echo
      ls -lha *.log
      echo
      read -p "🔹 ⚠️ WARNING: Are you sure you want to proceed deleting ALL .log files in: $PWD? (y/n): " CONFIRM

      if [[ "$CONFIRM" == "y" ]]; then
          rm -f *.log 2>/dev/null
          echo
          echo -e "${GREEN}✅ All logs deleted.${NC}\n"
      else
          echo
          echo -e "${RED}❌ Operation cancelled.${NC}\n"
      fi
    else
        echo -e "${RED}❌ No log files found to delete${NC}\n"
    fi
    echo
    read -p "Press enter to return to main menu: " enter
}

# Function to generate a futuristic HTML report from a log file
generate_html_report() {
    echo -e "\n${MAGENTA}📂 Available log files:${NC}\n"
    ls -lha *.log 2>/dev/null || { echo -e "${RED}❌ No log files found.${NC}\n"; return; }

    echo -e "\n${YELLOW}🔹 Copy and paste a filename from the list above to generate an HTML report:${NC}\n"
    read -p "📖 Log file to convert: " LOGFILE

    if [[ ! -f "$LOGFILE" ]]; then
        echo -e "${RED}❌ File not found. Please try again.${NC}\n"
        return
    fi

    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    HTMLFILE="${LOGFILE%.log}_report_${TIMESTAMP}.html"

    # Remove ANSI color escape sequences from log file
    CLEANED_LOG=$(sed -E 's/\x1B\[[0-9;]*[mK]//g' "$LOGFILE")

    # Start the HTML structure
    cat <<EOF > "$HTMLFILE"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>GitHub Report - $LOGFILE</title>
    <style>
        body {
            font-family: 'Courier New', monospace;
            background-color: #121212;
            color: #00ffaa;
            padding: 20px;
            text-align: center;
        }
        h1 {
            color: #00ffaa;
            text-shadow: 0px 0px 15px #00ffaa;
            font-size: 28px;
            margin-bottom: 5px;
        }
        h2 {
            color: #ddd;
            font-size: 18px;
            margin-top: 0;
            opacity: 0.8;
        }
        .repo-container {
            width: 80%;
            margin: 20px auto;
            background-color: #1e1e1e;
            padding: 15px;
            border-radius: 10px;
            box-shadow: 0px 0px 20px #00ffaa;
            text-align: left;
        }
        .section-title {
            background: linear-gradient(90deg, #00ffaa, #0088cc);
            color: #121212;
            padding: 10px;
            font-weight: bold;
            text-align: center;
            border-radius: 5px;
            font-size: 18px;
            margin-bottom: 10px;
        }
        .content {
            background-color: #000;
            padding: 12px;
            border-radius: 5px;
            margin-top: 10px;
            font-size: 14px;
        }
        .commit { color: #00ffaa; }
        .branch { color: #ffcc00; font-weight: bold; }
        .deleted-branch { color: #ff6666; font-style: italic; }
        .pr { color: #66ff66; }
        .issue { color: #ff9966; }
        .footer {
            margin-top: 20px;
            font-size: 14px;
            opacity: 0.7;
        }
    </style>
</head>
<body>
    <h1>🚀 GitHub Activity Report</h1>
    <h2>File: $LOGFILE</h2>
EOF

    # Variables to track sections
    INSIDE_REPO=false

    # Process log file content and format sections
    while IFS= read -r line; do
        if [[ "$line" == "📂 Processing repository:"* ]]; then
            # Close previous repo container if open
            if [[ "$INSIDE_REPO" == true ]]; then
                echo "</div>" >> "$HTMLFILE"
            fi
            # Start new repo block
            echo '<div class="repo-container">' >> "$HTMLFILE"
            echo "<div class='section-title'>$line</div>" >> "$HTMLFILE"
            INSIDE_REPO=true
        elif [[ "$line" == "📜 Latest commits on each branch:"* ]]; then
            echo '<div class="section-title">📜 Latest Commits</div>' >> "$HTMLFILE"
        elif [[ "$line" == "📌 Branch:"* ]]; then
            echo "<div class='branch'>$line</div>" >> "$HTMLFILE"
        elif [[ "$line" == "🔹 "* ]]; then
            echo "<div class='commit'>$line</div>" >> "$HTMLFILE"
        elif [[ "$line" == "🚀 Deleted branches (from merged PRs):"* ]]; then
            echo '<div class="section-title">🚀 Deleted Branches</div>' >> "$HTMLFILE"
        elif [[ "$line" == "❌ Deleted branch:"* ]]; then
            echo "<div class='deleted-branch'>$line</div>" >> "$HTMLFILE"
        elif [[ "$line" == "📬 Pull Requests:"* ]]; then
            echo '<div class="section-title">📬 Pull Requests</div>' >> "$HTMLFILE"
        elif [[ "$line" == "📌 MERGED:"* ]]; then
            echo "<div class='pr'>$line</div>" >> "$HTMLFILE"
        elif [[ "$line" == "🐞 Issues:"* ]]; then
            echo '<div class="section-title">🐞 Issues</div>' >> "$HTMLFILE"
        elif [[ "$line" == "💬 Discussions:"* ]]; then
            echo '<div class="section-title">💬 Discussions</div>' >> "$HTMLFILE"
        elif [[ "$line" == "✅ Done!"* ]]; then
            echo '<div class="section-title">✅ Report Complete</div>' >> "$HTMLFILE"
        else
            echo "<div class='content'>$line</div>" >> "$HTMLFILE"
        fi
    done <<< "$CLEANED_LOG"

    # Close last repo container if open
    if [[ "$INSIDE_REPO" == true ]]; then
        echo "</div>" >> "$HTMLFILE"
    fi

    # Finish HTML structure
    echo "<div class='footer'>Generated on $(date +"%Y-%m-%d %H:%M:%S")</div></body></html>" >> "$HTMLFILE"

    echo -e "\n${GREEN}✅ HTML report generated: ${WHITE}$HTMLFILE${NC}\n"

    # Ask if user wants to open the file
    read -p "🔹 Open the HTML report in your browser? (y/n): " OPEN_FILE
    if [[ "$OPEN_FILE" == "y" ]]; then
        xdg-open "$HTMLFILE" &>/dev/null || echo -e "${RED}❌ Unable to open in browser. Open manually: $HTMLFILE${NC}\n"
    fi

    read -p "Press enter to return to the main menu: " enter
}

# Menu function
menu() {
    while true; do
        echo -e "\n${CYAN}======================================"
        echo -e "🌟 GitHub Activity Tracker 🌟"
        echo -e "======================================${NC}\n"

        echo -e "${YELLOW}1 - Query all repositories for a user${NC}"
        echo -e "${YELLOW}2 - Query a specific repository${NC}"
        echo -e "${YELLOW}3 - View log files${NC}"
        echo -e "${YELLOW}4 - Search for a pattern in a log file${NC}"
        echo -e "${YELLOW}5 - Delete a specific log file${NC}"
        echo -e "${YELLOW}6 - Delete all log files${NC}"
        echo -e "${YELLOW}7 - Generate a futuristic HTML report from a log file${NC}\n"
        echo -e "${YELLOW}8 - Back to initialize menu${NC}\n"

        read -p "🔹 Select an option (1-7): " CHOICE
        echo ""

        case $CHOICE in
            1) list_repos ;;
            2) query_repo ;;
            3) view_logs ;;
            4) search_logs ;;
            5) delete_log ;;
            6) delete_all_logs ;;
            7) generate_html_report ;;
            8) check_and_initialize_repository ;;
            *) echo -e "${RED}❌ Invalid option. Try again.${NC}\n" ;;
        esac
    done
}

# Run the menu
menu

}
main_program() {
  while true; do
    echo " "
    echo "###########################################"
    echo "   ***        GitHub CLI Tool         ***  "
    echo " "
    echo "-------------------------------------------"
    echo " "
    echo " -------->    Main operations menu         "
    echo " "
    echo "1. View/Configure Git account"
    echo "2. Authentication for a Branch/Project"
    echo "3. Test SSH Connection"
    echo "4. List Branches"
    echo "5. Change Branch"
    echo "6. Show remote urls"
    echo "7. Delete remote url"
    echo "8. Git status"
    echo "9. Git show"
    echo "10. Merge branches"
    echo "11. Create Local Branch"
    echo "12. Create Remote Branch"
    echo "13. Create Remote Repo"
    echo "14. Add Files"
    echo "15. Commit"
    echo "16. Pull from Remote Repo"
    echo "17. Push to Remote repo"
    echo "18. Delete Local Branch"
    echo "19. Delete ALL Local Branches"
    echo "20. Delete Remote branch"
    echo "21. Delete Remote Repo"
    echo "22. Show remote branch"
    echo "23. Delete untracked branches - Deletes LOCAL branches, which do not have remotes"
    echo "24. <--- Back to Initial menu"
    echo " "
    echo "-------------------------------------------"
    echo " "
    echo "Working on path/repo: "$PWD
    echo " "
    read -p "Select an option (1-19): " choice

    case $choice in
        1)
			git_configure_account
            ;;
        2)
			git_authentication
            ;;
        3)
			test_ssh_connection
            ;;
        4)
            echo " "
            echo "Working on path/repo: "$PWD
            echo " "
            echo "Listing branches: "
            echo " "
            git branch
            echo " "
            read -p "Press enter to return to the menu: " enter
            ;;
        5)
            echo " "
            echo "Working on path/repo: "$PWD
            echo " "
            echo "Current working branch: "
            git branch
            echo " "
            read -p "Enter branch name to switch to: " switch_branch
            git switch $switch_branch
            echo " "
            git branch
            echo " "
            read -p "Press enter to return to the menu: " enter
            ;;
        6)
            remote_urls_manager
            ;;
        7)
            echo " "
            echo "Working on path/repo: "$PWD
            echo " "
            echo "Current working branch: "
            git branch
            echo " "
            git remote -v
            echo " "
            read -p "Enter the remote url name to remove: " remove_remote_url
            git remote remove $remove_remote_url
            echo " "
            git remote -v
            read -p "Press enter to return to the menu: " enter
            ;;
        8)
            echo " "
            echo "Working on path/repo: "$PWD
            echo " "
            echo "Current working branch: "
            git branch
            echo " "
            git status
            echo " "
            read -p "Press enter to return to the menu: " enter
            ;;
        9)
            echo " "
            echo "Working on path/repo: "$PWD
            echo " "
            echo "Current working branch: "
            git branch
            echo " "
            git show
            echo " "
            read -p "Press enter to return to the menu: " enter
            ;;
        10)
            echo " "
            echo "Working on path/repo: "$PWD
            echo " "
            echo "Current working branch: "
            echo " "
            read -p "Enter the branch you want to merge with current: " branch_merge
            git merge $branch_merge
            echo " "
            read -p "Press enter to return to the menu: " enter
            ;;
        11)
            create_local_branch
            ;;

        12)
            create_remote_branch
            echo " "
            read -p "Press enter to return to the menu: " enter
            ;;

        13)
			      create_remote_repo
            ;;
        14)
            echo " "
            echo "Working on path/repo: "$PWD
            echo " "
            echo "Listing files "
            echo " "
            ls -lha
            echo " "
            read -p "Add all files in the local branch? (Y/N): " answer
            if [ "$answer" == "Y" ] || [ "$answer" == "y" ]; then
                echo
                read -p "Provide the branch to add the files into: " branchname
                git checkout $branchname
                echo
                git add .
                echo " "
                read -p "Press enter to return to the menu: " enter
            else
                echo " "
                echo "Working on path/repo: "$PWD
                echo " "
                echo "Listing files "
                echo " "
                ls -lha
                echo " "
                read -p "Enter the file name to add: " file_name
                git add $file_name
                echo " "
                read -p "Press enter to return to the menu: " enter
            fi
            ;;
        15)
            echo " "
            echo "Working on path/repo: "$PWD
            echo " "
            git branch
            echo " "
            read -p "Enter commit message: " commit_message
            git commit -m "$commit_message"
            echo " "
            read -p "Press enter to return to the menu: " enter
            ;;
        16)
            pull_from_remote
            ;;
        17)
            push_to_remote
            ;;
        18)
			delete_local_branch
            ;;

	    19)
	        echo " "
            echo "Working on path/repo: "$PWD
            echo " "
            echo "Showing current branch: "
            echo " "
            git branch
            echo " "
            function confirm_delete_all_branches() {

				read -p "Do you want to delete all the branches in $PWD: y/n?: " confirm_delete
				if [ $confirm_delete == 'y' ]; then
				    echo "Creating temp branch for deletion 'temp-branch-for-deletion'... "
					echo
					git checkout -b temp-branch-for-deletion
					echo
					echo "Deleting all branches except temp-branch-for-deletion... "
					echo
					for branch in $(git branch | grep -v "temp-branch-for-deletion"); do
						git branch -D "$branch"
					done
				elif [ $confirm_delete == 'n' ]; then
					echo
					echo "Aborted the deletion of ALL branches in $PWD"
				else
				    echo
				    read -p "Invalid reply. Press enter to go back to the prompt: " enter
				    echo
				    confirm_delete_all_branches
				fi
			}
            confirm_delete_all_branches
            echo " "
            git branch
            echo " "
            read -p "Press enter to return to the menu: " enter
            ;;

        20)
            delete_remote_branch
            echo " "
            read -p "Press enter to return to the menu: " enter
            ;;
        21)
			delete_remote_repo
            ;;
        22) echo " "
            read -p "Enter remote branch name to show: " show_remote_branch
            echo " "
            gh repo view $show_remote_branch
            echo " "
            read -p "Press enter to return to the menu: " enter
            ;;

        23)
			delete_untracked_branches
            echo " "
            read -p "Press enter to return to the menu: " enter
            ;;
        24)
            check_and_initialize_repository
            ;;
        *)
            echo " "
            echo "ERROR!"
            echo "Invalid option. Please select a valid option from the menu."
            ;;
    esac
done
}

# Function to search for git branches using a regex
search_git_branch() {
  echo "Branch search mode accessed. "
  echo
  read -p "Enter a regex pattern to search for a branch: " pattern
  echo
  echo "Searching for branches matching the pattern '$pattern'..."
  echo
  find . -type d -name .git | grep $pattern
  echo
  read -p "Press enter to go to the start menu: " enter
  echo
  check_and_initialize_repository
}


gh_authentication_menu() {

	# Colors for styling
	green="\e[32m"
	blue="\e[34m"
	yellow="\e[33m"
	red="\e[31m"
	reset="\e[0m"

	# Function to authenticate with GitHub using gh
	#authenticate_account() {
	#	echo -e "${blue}\nAuthenticating GitHub account with gh...${reset}\n"
	#	gh auth login --hostname github.com --git-protocol ssh
	#	echo -e "${green}Authentication successful!${reset}\n"
	#}

	authenticate_account() {
		echo -e "${blue}\nAuthenticating GitHub account with gh...${reset}\n"

		gh auth login --hostname github.com --git-protocol ssh

		# Correct GitHub CLI config path
		GH_CONFIG_FILE="$HOME/snap/gh/502/.config/gh/hosts.yml"

		if [[ ! -f "$GH_CONFIG_FILE" ]]; then
			echo -e "${red}Error: GitHub CLI config file not found at $GH_CONFIG_FILE.${reset}"
			return 1
		fi

		# Retrieve the logged-in GitHub username
		logged_git_user=$(grep 'user:' "$GH_CONFIG_FILE" | awk '{print $2}' | tr -d ' ')

		# Retrieve the OAuth token
		logged_git_oauth_token=$(grep 'oauth_token:' "$GH_CONFIG_FILE" | awk '{print $2}')

		# Correct SSH key path
		key_path="$HOME/.ssh/id_ed25519_${logged_git_user}"

		# Check if the key file exists
		if [[ ! -f "$key_path" ]]; then
			echo -e "${red}Error: No valid SSH key found for $logged_git_user at $key_path.${reset}"
			echo -e "${yellow}Ensure you have an SSH key added and registered with GitHub.${reset}"
			return 1
		fi

		echo -e "${green}Authentication successful! Using SSH key: $key_path.${reset}\n"

		# Remove existing symlink if it exists
		if [[ -L "$HOME/.ssh/current_github_key" ]]; then
			rm "$HOME/.ssh/current_github_key"
		fi

		# Create a new symlink to the SSH key
		ln -sf "$key_path" "$HOME/.ssh/current_github_key"

		# Ensure the SSH agent is running
		if ! pgrep -u "$USER" ssh-agent > /dev/null; then
			echo -e "${blue}Starting SSH agent...${reset}"
			eval "$(ssh-agent -s)"
		fi

		# Remove all existing SSH keys and add the correct one
		ssh-add -D > 2&>1 /dev/null
		ssh-add "$HOME/.ssh/current_github_key" > 2&>1 /dev/null

		# Debugging
		echo -e "\n${yellow}Verifying SSH key content:${reset}"
		ls -lha "$HOME/.ssh/current_github_key"

		# Test SSH connection with GitHub
		ssh -T git@github.com
		echo
		echo "Configured commiter username is: "
		echo
		git config --global user.email
		echo
		echo "Configured commiter email is: "
		echo
		git config --global user.name
		echo
		echo "Remember you can change the comitter data in option 2, from the github account manager menu"
		echo
		read -p "Press enter to return to the main menu: " enter
	}

	# Function to switch GitHub identity using gh
	switch_account() {
		echo -e "${blue}\nSwitching GitHub account...${reset}\n"
		read -p "Enter GitHub username to switch to: " username
		read -p "Enter GitHub email for $username: " email

		echo -e "${yellow}\nLogging in with gh...${reset}\n"
		gh auth login --hostname github.com --git-protocol ssh

		git config --global user.name "$username"
		git config --global user.email "$email"

		echo -e "${yellow}Testing SSH connection...${reset}\n"
		eval "$(ssh-agent -s)"
		ssh -T git@github.com

		echo -e "${green}Switched to $username!${reset}\n"
	}

	# Function to display current GitHub identity
	show_identity() {
		echo -e "${blue}\nCurrent GitHub Identity:${reset}\n"
		gh auth status
		echo
		echo "Configured commiter username is: "
		echo
		git config --global user.email
		echo
		echo "Configured commiter email is: "
		echo
		git config --global user.name
		echo
		echo "Remember you can change the comitter data in option 2, from the github account manager menu"
		echo
		read -p "Press enter to return to the main menu: " enter

	}

	# Function to clone a repository using gh
	clone_repo() {
		echo -e "${blue}\nCloning a repository...${reset}\n"
		read -p "Enter GitHub repository URL (https or SSH): " repo_url
		gh repo clone "$repo_url"
		echo -e "${green}Repository cloned successfully!${reset}\n"
	}

	# Menu loop
	while true; do
		echo
		echo -e "${green}\n========= GitHub Account Manager (gh) =========${reset}"
		echo
		echo -e "${yellow}1) gh tool - Authenticate to remote GitHub Account${reset}"
		echo -e "${yellow}2) Switch GitHub Account locally ${reset}"
		echo -e "${yellow}3) Show Current GitHub Identity${reset}"
		echo -e "${yellow}4) Clone Repository${reset}"
		echo -e "${yellow}5) Exit${reset}\n"
		read -p "Choose an option: " choice

		case $choice in
			1) authenticate_account ;;
			2) switch_account ;;
			3) show_identity ;;
			4) clone_repo ;;
			5) echo -e "${green}Goodbye!${reset}"; break;;
			*) echo -e "${red}Invalid option. Try again.${reset}\n" ;;
		esac

	done


}

CYAN='\e[36m'
GREEN='\e[32m'
RED='\e[31m'
BOLD='\e[1m'
RESET='\e[0m'

function git_workflow_main() {

	echo "──────────────────────────────────────────────"
	echo "  🌌 Welcome to the Futuristic Git Assistant  "
	echo "──────────────────────────────────────────────"
	echo "🚀 Automating Your Workflow Like a Pro! 🛠️"
	echo

	# Start option with timestamp
	echo "🔹 Start Time: $(date '+%Y-%m-%d %H:%M:%S')"
	echo "🔹 Repository Path: $PWD"
	echo

	read -p "🔧 Ready to begin? Press Enter to start..."

	# Step 1: Validate user authentication
	echo
	echo -e "${CYAN}🔒 Validating user authentication...${RESET}"
	echo
	rm -f ssh_auth_check.log
	ssh -v -T git@github.com 2>&1 | tee ssh_auth_check.log

	if grep -q "You've successfully authenticated" ssh_auth_check.log; then
		AUTH_USER=$(grep -oP "Hi \K\w+" ssh_auth_check.log)  # Extract username from SSH output
		echo
		echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
		echo -e "${GREEN}${BOLD}! ✅ Authentication successful for user: $AUTH_USER ${RESET}"
		echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
	elif grep -q "Permission denied" ssh_auth_check.log || grep -q "publickey" ssh_auth_check.log; then
		echo
		echo -e "${RED}${BOLD}❌ Authentication failed!${RESET}"
		echo -e "${RED}🚨 Possible issues detected:${RESET}"
		echo -e "${RED}🔹 Public key authentication failed.${RESET}"
		echo -e "${RED}🔹 Permission denied.${RESET}"
		echo -e "${RED}🔹 SSH key might not be added to GitHub.${RESET}"
		echo
		read -p "🔄 Press Enter to retry authentication or CTRL+C to exit... " retry
		exec "$0" # Restart the script
	else
		echo
		echo -e "${RED}${BOLD}⚠️ Something went wrong with authentication.${RESET}"
		echo -e "${RED}🔎 Check ssh_auth_check.log for details.${RESET}"
		echo
		read -p "🔄 Press Enter to retry authentication or CTRL+C to exit... " retry
		exec "$0"
	fi

	# Step 2: Prompt for branch name
	while true; do
	  echo
	  echo
	  echo "You are working in path: $PWD"
	  echo
	  read -p "Change path to another repo? (y/n): " change_path
	  if [[ "$change_path" == "y" ]]; then
		echo
		git_dirs=$(find ~ -type d -name .git)
		echo "$git_dirs"
		echo
		read -p "Enter the path to the repo without the .git and last forward slash (eg: /path/to/repo ): " repo_path
		if [[ ! -d "$repo_path" ]]; then
		  echo
		  echo "❌ Directory '$repo_path' does not exist."
		  continue
		fi

		cd "$repo_path"

	  else
		break
	  fi
	  echo
	  read -p "📌 Enter the new branch name: " branch_name

	  if [[ -d "$branch_name" ]]; then
		  if [[ -d ".git" && -n "$branch_name" ]]; then
			read -p "💡 Use existing branch '$branch_name'? (y/n): " use_branch
			if [[ "$use_branch" == "y" ]]; then
			  echo "🔄 Switching to '$branch_name'..."
			  cd "$branch_name" || exit
			  git checkout "$branch_name"
			else
			  read -p "❌ Not using '$branch_name'. Press enter to proceed." enter
			fi
		  fi
		  echo "⚠️ Directory '$branch_name' already exists."
	  else
		  # Create and switch to the new branch
		  echo
		  echo "Creating  and switching to '$branch_name'..."
		  git branch "$branch_name"
		  echo
		  git checkout "$branch_name"
		  break
	  fi
	done

	echo
	# Open terminal in current directory
	echo "🖥️ Opening terminal at $PWD..."
	gnome-terminal "$PWD"
	echo
	read -p "⏳ Start working on your changes. Press Enter when done: " enter

	# Step 3: Stage changes
	echo
	read -p "📂 Stage all files? (y/n): " stage_all
	if [[ "$stage_all" == "y" ]]; then
		git add .
	else
		echo
		ls -lha
		echo
		read -p "📝 Enter files to stage: " files_to_stage
		git add $files_to_stage
	fi

	# Step 4: Commit changes
	echo
	read -p "💬 Commit message: " commit_msg
	git commit -m "$commit_msg"

	# Step 5: Push changes
	git push --set-upstream origin "$branch_name"

	# Step 6: Provide repo user
	echo
	read -p "👤 Enter repo owner username: " account_owner

	# Step 7: Extract repository name
	#repo_name=$(basename -s .git $(git config --get remote.origin.url))
	repo_name=$(git config --get remote.origin.url | sed -E 's/.*\/([^/]+)\.git/\1/')

	# Step 8: Construct PR URL
	pr_url="https://github.com/$account_owner/$repo_name/pull/new/$branch_name"

	# Open PR in Chrome profile
	while true; do
	  echo
	  echo "🔹 1 - Profile Gus"
	  echo "🔹 2 - Profile kuroiyamahar15"
	  echo "🔹 3 - Profile kurogane.tecnology"
	  echo
	  read -p "🌐 Select Chrome profile to open PR: " profile
	  case $profile in
		1)
		  gnome-terminal -- google-chrome --profile-directory=Default "$pr_url"
		  break
		  ;;
		2)
		  gnome-terminal -- google-chrome --profile-directory="Profile 2" "$pr_url"
		  break
		  ;;

		3)
		  gnome-terminal -- google-chrome --profile-directory="Profile 3" "$pr_url"
		  break
		  ;;

		*) echo "❌ Invalid option. Try again." ;;
	  esac
	done

	echo
	read -p "⏳ Wait for approval or merge PR. Press Enter when done: " enter
	echo
	# Step 9: Delete remote branch
	git push origin --delete "$branch_name"

	# Delete untracked branches
	echo
	repo_path=${repo_path:-$PWD}  # Default to current directory if empty
	repo_path=$(eval echo "$repo_path")  # Expand ~ (home directory)

	# Validate that the directory exists
	if [[ ! -d "$repo_path" ]]; then
		echo "❌ Error: Directory '$repo_path' does not exist."
		return 1
	fi

	# Validate that it's a Git repository
	if [[ ! -d "$repo_path/.git" ]]; then
		echo "❌ Error: '$repo_path' is not a valid Git repository."
		return 1
	fi

	# Move into the repository directory
	cd "$repo_path" || { echo "❌ Error: Failed to enter directory '$repo_path'"; return 1; }

	# Fetch latest remote branches
	echo "🔄 Fetching the latest remote branches..."
	git fetch --prune

	# List local branches
	echo "🔎 Local branches:"
	git branch
	echo

	# Find local branches that no longer have a remote
	echo "🔎 Checking for local branches without a remote counterpart..."
	echo
	untracked_branches=($(git branch --format "%(refname:short)" | while read -r branch; do
		if ! git ls-remote --exit-code --heads origin "$branch" > /dev/null 2>&1; then
			echo "$branch"
		fi
	done))

	# If no untracked branches exist, exit
	if [[ ${#untracked_branches[@]} -eq 0 ]]; then
		echo "✅ No untracked local branches found."
		return 0
	fi

	# Prompt the user for deletion
	echo "⚠️ Untracked branches detected:"
	echo
	for branch in "${untracked_branches[@]}"; do
		read -rp "🔥 Delete local branch '$branch'? (y/n): " confirm
		if [[ "$confirm" == "y" ]]; then
			if [[ "$branch" == "$(git rev-parse --abbrev-ref HEAD)" ]]; then
				echo "⚠️ Switching to 'master' before deletion..."
				echo
				git checkout master || git checkout main
			fi
			echo "🗑️ Deleting '$branch'..."
			echo
			git branch -D "$branch"
			echo "✅ Deleted '$branch'."
		else
			echo "❌ Skipped '$branch'."
		fi
	done
	echo
	echo "🎉 Cleanup complete!"

	git pull

	echo
	# Step 11: Provide report
	echo
	echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	echo "✨ Summary of Actions Taken: "
	echo "✔️ Created and switched to branch: $branch_name"
	echo "✔️ Staged files and committed changes"
	echo "✔️ Pushed branch to remote"
	echo "✔️ Opened PR in Chrome: $pr_url"
	echo "✔️ Deleted remote branch and cleaned untracked branches"
	echo "✔️ Pulled latest changes"
	echo "🚀 All steps completed successfully!"
	echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	echo
	read -p "Press enter to return to the check initialize main menu: " enter
	check_and_initialize_repository
}


check_and_initialize_repository() {
    cd ..
    git_dirs=$(find . -type d -name .git)
    if [ -n "$git_dirs" ]; then
      echo "###########################################"
      echo "   ***       GitHub repo setup        ***  "
      echo " "
      echo "Git Ok - already initialized - There is no need to initialize git"
      echo " "
      cd ~
      echo "Current path is: "$PWD
      echo " "
      read -p "Press enter to view found paths/repos/direcotries conatining .git: " enter
      echo " "
      echo "Found .git directories in the following subdirectories:"
      check_existing_repo() {
        echo " "
        echo "$git_dirs"
        while true; do
          echo " "
          echo "-----------------------------------------------------------------------------------------------------------"
          echo
          echo "1 - gh remote and local account authentication menu"
          echo "2 - View/Configure Git account locally"
          echo "3 - Test SSH Connection"
          echo "4 - Search for a git branch using a regex"
          echo "5 - Create a new local branch in "$PWD
          echo "6 - Create a remote Repo"
          echo "7 - Delete a remote Repo"
          echo "8 - Provide a valid LOCAL repo/directory to work with"
          echo "--------------------------------------------------------------------"
          echo "9 - GIT WORKFLOW MENU"
          echo "--------------------------------------------------------------------"
          echo "10 - GIT STATISTICS MODULE"
          echo "11 - Main program operations"
          echo " "
          read -p "Select an option : " choice
          case $choice in

              1)
                gh_authentication_menu
                ;;

              2)
                git_configure_account
                ;;
              3)
                test_ssh_connection
                ;;
              4)
                echo " "
                search_git_branch
                echo " "
                      read -p "Press enter to go to the main menu program: " enter
                      check_and_initialize_repository
                ;;
              5)
                echo " "
                read -p "Enter initial branch name: " branch_name
                git init $branch_name
                echo " "
                echo "Accessing git branch "$branch_name" ..."
                cd $branch_name
                echo " "
                read -p "Enter a name to create a test file: " test_file
                touch $test_file
                git add $test_file
                git commit -m "Initial commit done"
                echo " "
                read -p "Press enter to list the branches: " enter
                echo " "
                echo "Listing branches: "
                git branch
                echo " "
                read -p "Press enter to go to the main menu program: " enter
                main_program
                ;;
              6)
                create_remote_repo
                ;;
              7)
                delete_remote_repo
                ;;
              8)
                echo " "
                echo "Copy and paste the name of the repo/branch you want to work with, without the ./ "
                echo "Example: ./Doe/.git. - Doe"
                echo " "
                read -p "Provide a valid repo listed above like in the example and press enter: " repo_name
                repo_name=${repo_name:-$PWD}  # Default to current directory if empty

                if [[ -d "$repo_name" ]]; then
                  cd $repo_name
                  echo " "
                  read -p "You will be working with repo: $repo_name. Press enter to display the main menu to get started: "
                  main_program
                else
                  echo " "
                  read -p  "Error: Invalid repo provided. Provide a repo which containes a .git directory from the list. Press enter to continue: " enter
                  check_and_initialize_repository
                fi
                ;;
                
              9)
                 git_workflow_main
                 ;;

              10)
                git_stats
                ;;
              11)
                main_program
                ;;
              *)
                echo " "
                echo "ERROR!"
                echo "Invalid option. Please select a valid option from the menu."
                ;;
          esac
        done
      }
      check_existing_repo
    else
      echo "################################################"
      echo "  ***  GitHub initialization setup wizard  ***  "
      echo " "
      echo "No .git directories found in subdirectories."
      echo "A .git directory needs to be in found in a subdirectory"
      echo " "
      echo "You MUST create an initial repository to operate this console."
      echo " "
      echo "Once you provide your branch name, we will create a repo directory"
      echo "with it's name, access it, and create a master branch for you"
      echo " "
      cd ~
      read -p "Press enter to get started now: " enter
      echo " "
      read -p "Enter initial branch name: " branch_name
      git init $branch_name
      echo " "
      echo "Accessing git branch "$branch_name" ..."
      cd $branch_name
      echo " "
      read -p "Enter a name to create a test file: " test_file
      touch $test_file
      git add $test_file
      git commit -m "Initial commit done"
      echo " "
      read -p "Press enter to list the branches: " enter
      echo " "
      echo "Listing branches: "
      git branch
      echo " "
      read -p "Press enter to return to the menu: " enter
      cd $branch_name
      check_and_initialize_repository
    fi
}

check_and_initialize_repository

list_git_directories() {
    # Find all .git directories in subdirectories and list them
    git_dirs=$(find . -type d -name .git)

    if [ -n "$git_dirs" ]; then
        echo " "
        echo "Found .git directories in the following subdirectories:"
        echo " "
        echo "$git_dirs"
    else
        echo "No .git directories found in subdirectories."
    fi
}

# Call the function
#list_git_directories
