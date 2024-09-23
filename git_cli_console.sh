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
    echo "12. Create Remote Repo"
    echo "13. Add Files"
    echo "14. Commit"
    echo "15. Pull from Remote Branch"
    echo "16. Push to Branch"
    echo "17. Delete Local Branch"
    echo "18. Delete ALL Local Branches"
    echo "19. Delete Remote Branch"
    echo "20. Show remote branch"
    echo "21. <--- Back to Initial menu"
    echo " "
    echo "-------------------------------------------"
    echo " "
    echo "Working on path/repo: "$PWD
    echo " "
    read -p "Select an option (1-19): " choice

    case $choice in
        1)
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
              ;;
        2)
            echo " "
            echo "Working on path/repo: "$PWD
            echo " "
            read -p "Enter GitHub repository URL: " repo_url
            git remote set-url origin $repo_url
            ;;
        3)
            echo " "
            echo "Working on path/repo: "$PWD
            echo " "
            echo "SSH testing mode accessed."
            echo " "
            read -p "Press enter to test the ssh connection to git@github.com now: " enter
            ssh -vT git@github.com
            echo " "
            read -p "Connection test finalized, press enter to get back to the main menu: " enter
            echo " "
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
            echo " "
            echo "Working on path/repo: "$PWD
            echo " "
            read -p "Enter local branch name to create: " local_branch
            echo " "
            git branch $local_branch
            echo " "
            echo "Listing branches "
            echo " "
            git branch
            echo " "
            read -p "Press enter to return to the menu: " enter
            ;;
        12)
			echo " "
			echo "Working on path/repo: $PWD"
			echo " "

			# Check if the remote already exists locally
			if git remote get-url "$new_repo" &>/dev/null; then
				echo "Fatal: Remote '$new_repo' already exists."
			else
				# Create the repository on GitHub using GitHub CLI
				echo "Creating GitHub repository '$new_repo' for user '$git_username'..."
				gh repo create
				
			fi
			echo " "

			read -p "Press enter to return to the menu: " enter
            ;;
        13)
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
        14)
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
        15)
            echo " "
            echo "Working on path/repo: "$PWD
            echo " "
            echo "Pull from remote branch menu accessed. "
            echo " "
            echo "Showing current branch: "
            echo " "
            git branch
            read -p "Press enter to pull from Remote Branch: "
            echo " "
            git pull
            read -p "Press enter to return to the menu: " enter
            ;;
        16)
            echo " "
            echo "Working on path/repo: "$PWD
            echo " "
            echo "Push to remote Branch menu accessed: "
            echo " "
            echo "Showing current branch: "
            echo " "
            git branch
            echo " "
            read -p "Press enter to push to the from Remote Branch: "
            echo " "
            git config --global url."git@github.com:".insteadOf "https://github.com/"
            echo
            ssh -T git@github.com
            echo
            git push --set-upstream origin master
            echo " "
            read -p "Press enter to return to the menu: " enter
            ;;
        17)
			echo " "
			echo "Working on path/repo: $PWD"
			echo " "
			echo "Showing current branch: "
			echo " "
			git branch
			echo " "

			# Prompt for branch name to delete
			read -p "Enter local branch name to delete: " delete_local_branch
			echo
			confirm_delete_all_branches() {
				
				# Check if the branch exists
				if git show-ref --verify --quiet refs/heads/"$delete_local_branch"; then
					read -p "Do you want to delete the branch '$delete_local_branch' in $PWD: y/n?: " confirm_delete
					echo

					if [ "$confirm_delete" == 'y' ]; then
						echo "Creating temp branch for deletion 'temp-branch-for-deletion'... "
						echo
						git checkout -b temp-branch-for-deletion
						echo
						echo "Deleting branch: $delete_local_branch, except temp-branch-for-deletion... "
						echo
						git branch -D $delete_local_branch
						echo
						echo "Deleted except 'temp-branch-for-deletion'."
					    echo
						
					elif [ "$confirm_delete" == 'n' ]; then
						echo
						echo "Aborted the deletion of $delete_local_branch in $PWD"
						echo
					else
						echo
						read -p "Invalid reply. Press enter to go back to the prompt: " enter
						echo
						confirm_delete_all_branches
					fi
				else
					echo
					echo "Branch '$delete_local_branch' does not exist in $PWD."
				fi
			}
			confirm_delete_all_branches
			echo
			read -p "Press enter to return to the menu: " enter
            ;;
            
	    18)
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
        19)
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
            ;;
        20) echo " "
            read -p "Enter remote branch name to show: " show_remote_branch
            echo " "
            gh repo view $show_remote_branch
            echo " "
            read -p "Press enter to return to the menu: " enter
            ;;
        21)
            check_and_initialize_repository
            ;;
        *)
            echo " "
            echo "ERROR!"
            echo "Invalid option. Please select an option from 1 to 16."
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
          echo "1 - Search for a git branch using a regex"
          echo "2 - Create a new branch in "$PWD
          echo "3 - Provide a valid repo/directory to work with"
          echo " "
          read -p "Select an option : " choice
          case $choice in
			  1)
			    echo " "
			    search_git_branch
			    echo " "
                read -p "Press enter to go to the main menu program: " enter
                check_and_initialize_repository
			    ;;
              2)
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
              3)
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
              *)
                echo " "
                echo "ERROR!"
                echo "Invalid option. Please select either 1 or 2."
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
