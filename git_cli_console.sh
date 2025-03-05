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
    echo " "
    echo "Working on path/repo: $PWD"
    echo
    eval "$(ssh-agent -s)"
	ssh-add -D
    read -p "Provide the name of the repo you want to create: " repo_name

    if [[ -d "$repo_name" ]]; then 
        echo
        echo "Repo '$repo_name' already exists."

        if [[ -d "$repo_name/.git" ]]; then
            echo
            echo "Repo '$repo_name' is already initialized."
            echo
            read -p "You cannot create this repo, because it already exists. Press enter to return to the main menu: " enter
            main_program
        else
            echo "Directory exists but is not a Git repo. Initializing..."
            cd "$repo_name" || exit
            git init
        fi
    else
        echo
        echo "Creating local directory '$repo_name'..."
        mkdir -p "$repo_name"
        cd "$repo_name" || exit
        echo
        echo "Initializing new Git repository in '$repo_name'..."
        git init
    fi

    # Detect default branch name (master or main)
    default_branch=$(git symbolic-ref --short HEAD 2>/dev/null)
    if [[ -z "$default_branch" ]]; then
        default_branch="master"  # Fallback to master
    fi

	# Extract GitHub username dynamically
    github_user=$(ssh -T git@github.com 2>&1 | grep -oP "(?<=Hi ).*?(?=! You've successfully)")

    if [[ -z "$github_user" ]]; then
        echo "Failed to determine GitHub username. Ensure you have SSH access configured."
        echo
        read -p "Press enter to return to the menu: "
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
   git clone https://github.com/$github_user/$repo_name.git
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

    # Create the remote repository on GitHub
    echo
    echo "Creating GitHub repository '$repo_name'..."
    gh repo create "$repo_name" --public --source=. --remote=upstream

    # Construct the correct remote repository URL
    remote_url="git@github.com:$github_user/$repo_name.git"

    # Add the correct remote URL
    git remote add origin "$remote_url"

    # Push the initial commit using the correct branch
    echo
    echo "Pushing initial commit to '$remote_url'..."
    git push -u origin "$default_branch"

    echo " "
    read -p "Press enter to return to the menu: "
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
            echo " "
            echo "Working on path/repo: "$PWD
            echo " "
            echo "Current working branch: "
            git branch
            echo " "
            echo "Listing remote urls - fetch push"
            echo " "
            git remote -v
            echo " "
            read -p "Press enter to return to the menu: " enter
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
          echo "9 - Main program operations"
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
