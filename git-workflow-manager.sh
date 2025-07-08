#!/bin/bash

# Git Workflow Manager - Interactive CLI
# Robust Git workflow management tool with colors and menus

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Extended color definitions for enhanced UI
LIGHT_RED='\033[1;31m'
LIGHT_GREEN='\033[1;32m'
LIGHT_BLUE='\033[1;34m'
LIGHT_CYAN='\033[1;36m'
LIGHT_MAGENTA='\033[1;35m'
ORANGE='\033[0;33m'
GRAY='\033[0;37m'

# Logging configuration
LOG_DIR="$HOME/.git_workflow_logs"
LOG_FILE="$LOG_DIR/git_workflow_$(date +%Y%m%d).log"
SESSION_LOG="$LOG_DIR/session_$(date +%Y%m%d_%H%M%S).log"

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Initialize logging
init_logging() {
    echo "=== Git Workflow Manager Session Started ===" >> "$SESSION_LOG"
    echo "Date: $(date '+%Y-%m-%d %H:%M:%S')" >> "$SESSION_LOG"
    echo "User: $(whoami)" >> "$SESSION_LOG"
    echo "Working Directory: $(pwd)" >> "$SESSION_LOG"
    echo "=========================================" >> "$SESSION_LOG"
    echo "" >> "$SESSION_LOG"
}

# Enhanced logging function
log_operation() {
    local level="$1"
    local message="$2"
    local operation="${3:-GENERAL}"
    local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    
    # Log to both daily log and session log
    echo "[$timestamp] [$level] [$operation] $message" >> "$LOG_FILE"
    echo "[$timestamp] [$level] [$operation] $message" >> "$SESSION_LOG"
    
    # Also display with colors if it's an important operation
    case "$level" in
        "SUCCESS")
            print_success "$message"
            ;;
        "ERROR")
            print_error "$message"
            ;;
        "WARNING")
            print_warning "$message"
            ;;
        "INFO")
            if [[ "$4" == "display" ]]; then
                print_info "$message"
            fi
            ;;
    esac
}

# Git command logging wrapper
log_git_command() {
    local command="$1"
    local operation="${2:-GIT_OPERATION}"
    local start_time=$(date +%s)
    
    log_operation "INFO" "Executing: $command" "$operation"
    
    # Execute the command and capture output
    if eval "$command" 2>&1 | tee -a "$SESSION_LOG"; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        log_operation "SUCCESS" "Command completed in ${duration}s: $command" "$operation"
        return 0
    else
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        log_operation "ERROR" "Command failed after ${duration}s: $command" "$operation"
        return 1
    fi
}

# GitHub CLI Tool Installation and Management
gh_tool_check() {
    if command -v gh >/dev/null 2>&1; then
        log_operation "INFO" "GitHub CLI (gh) is already installed" "GH_CHECK"
        return 0
    else
        log_operation "WARNING" "GitHub CLI (gh) is not installed" "GH_CHECK"
        print_warning "GitHub CLI (gh) tool is not installed"
        echo -e "${CYAN}Would you like to install it now? (y/n):${NC}"
        read -p "> " install_choice
        
        if [[ "$install_choice" == "y" || "$install_choice" == "Y" ]]; then
            if command -v snap >/dev/null 2>&1; then
                log_operation "INFO" "Installing GitHub CLI via Snap" "GH_INSTALL"
                if sudo snap install gh; then
                    log_operation "SUCCESS" "GitHub CLI installed successfully" "GH_INSTALL"
                    print_success "GitHub CLI has been installed"
                    return 0
                else
                    log_operation "ERROR" "Failed to install GitHub CLI" "GH_INSTALL"
                    print_error "Failed to install GitHub CLI"
                    return 1
                fi
            else
                log_operation "ERROR" "Snap is not available for GitHub CLI installation" "GH_INSTALL"
                print_error "Snap is not installed. Please install GitHub CLI manually"
                print_info "Visit: https://github.com/cli/cli#installation"
                return 1
            fi
        else
            log_operation "INFO" "User declined GitHub CLI installation" "GH_CHECK"
            return 1
        fi
    fi
}

# Remote Repository Detection (GitHub vs GitLab)
detect_remote_provider() {
    local remote_url=""
    
    # Try to get remote origin URL
    if git remote get-url origin >/dev/null 2>&1; then
        remote_url=$(git remote get-url origin)
    elif git remote get-url upstream >/dev/null 2>&1; then
        remote_url=$(git remote get-url upstream)
    else
        log_operation "WARNING" "No remote repository found" "REMOTE_DETECT"
        return 1
    fi
    
    log_operation "INFO" "Detected remote URL: $remote_url" "REMOTE_DETECT"
    
    if [[ "$remote_url" == *"github.com"* ]]; then
        echo "github"
        log_operation "INFO" "Remote provider detected: GitHub" "REMOTE_DETECT"
        return 0
    elif [[ "$remote_url" == *"gitlab.com"* ]] || [[ "$remote_url" == *"gitlab"* ]]; then
        echo "gitlab"
        log_operation "INFO" "Remote provider detected: GitLab" "REMOTE_DETECT"
        return 0
    else
        echo "unknown"
        log_operation "WARNING" "Unknown remote provider: $remote_url" "REMOTE_DETECT"
        return 1
    fi
}

# GitHub Authentication Menu
gh_authentication_menu() {
    while true; do
        print_header "GITHUB CLI AUTHENTICATION"
        
        # Check GitHub CLI status
        if ! gh_tool_check; then
            print_error "GitHub CLI is required for authentication features"
            pause
            return 1
        fi
        
        # Show current authentication status
        print_info "Current GitHub authentication status:"
        gh auth status 2>&1 || echo -e "${RED}Not authenticated${NC}"
        echo ""
        
        echo -e "${CYAN}Choose an operation:${NC}"
        echo ""
        echo -e "1. ${GREEN}Authenticate with GitHub${NC} ${YELLOW}(Web browser login)${NC}"
        echo -e "2. ${GREEN}Authenticate with token${NC} ${YELLOW}(Personal access token)${NC}"
        echo -e "3. ${GREEN}Switch GitHub account${NC} ${YELLOW}(Multi-account support)${NC}"
        echo -e "4. ${GREEN}Show authentication status${NC}"
        echo -e "5. ${GREEN}Logout from GitHub${NC}"
        echo -e "6. ${GREEN}Clone repository${NC} ${YELLOW}(GitHub repository)${NC}"
        echo -e "7. ${GREEN}SSH key management${NC} ${YELLOW}(Setup SSH for Git)${NC}"
        echo -e "8. ${GREEN}Back to main menu${NC}"
        echo ""
        
        read -p "Enter your choice (1-8): " choice
        echo ""
        
        case $choice in
            1) gh_authenticate_web ;;
            2) gh_authenticate_token ;;
            3) gh_switch_account ;;
            4) gh_show_status ;;
            5) gh_logout ;;
            6) gh_clone_repo ;;
            7) ssh_key_management ;;
            8) return 0 ;;
            *) 
                print_error "Invalid choice! Please enter 1-8."
                log_operation "WARNING" "Invalid menu choice: $choice" "GH_MENU"
                ;;
        esac
        
        pause
    done
}

# Authenticate with GitHub (Web)
gh_authenticate_web() {
    print_header "GITHUB WEB AUTHENTICATION"
    
    log_operation "INFO" "Starting GitHub web authentication" "GH_AUTH"
    print_info "This will open your web browser for GitHub authentication"
    echo -e "${CYAN}Proceed with web authentication? (y/n):${NC}"
    read -p "> " confirm
    
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        show_command "gh auth login" "Authenticate via web browser"
        if gh auth login; then
            log_operation "SUCCESS" "GitHub web authentication completed" "GH_AUTH"
            print_success "Successfully authenticated with GitHub"
            
            # Test the authentication
            if gh auth status; then
                print_success "Authentication verified"
            fi
        else
            log_operation "ERROR" "GitHub web authentication failed" "GH_AUTH"
            print_error "Authentication failed"
        fi
    else
        log_operation "INFO" "User cancelled GitHub web authentication" "GH_AUTH"
        print_info "Authentication cancelled"
    fi
}

# Authenticate with token
gh_authenticate_token() {
    print_header "GITHUB TOKEN AUTHENTICATION"
    
    print_info "You'll need a Personal Access Token from GitHub"
    print_info "Create one at: https://github.com/settings/tokens"
    echo ""
    
    echo -e "${CYAN}Enter your GitHub Personal Access Token:${NC}"
    read -s -p "> " token
    echo ""
    
    if [[ -n "$token" ]]; then
        log_operation "INFO" "Attempting GitHub token authentication" "GH_AUTH"
        if echo "$token" | gh auth login --with-token; then
            log_operation "SUCCESS" "GitHub token authentication completed" "GH_AUTH"
            print_success "Successfully authenticated with token"
        else
            log_operation "ERROR" "GitHub token authentication failed" "GH_AUTH"
            print_error "Token authentication failed"
        fi
    else
        log_operation "WARNING" "Empty token provided for GitHub authentication" "GH_AUTH"
        print_error "Token cannot be empty"
    fi
}

# Switch GitHub account
gh_switch_account() {
    print_header "SWITCH GITHUB ACCOUNT"
    
    print_info "This will logout and allow you to login with a different account"
    echo -e "${YELLOW}Continue? (y/n):${NC}"
    read -p "> " confirm
    
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        log_operation "INFO" "Switching GitHub account" "GH_SWITCH"
        
        # Logout first
        if gh auth logout; then
            log_operation "INFO" "Logged out from GitHub" "GH_SWITCH"
            print_success "Logged out successfully"
            
            # Prompt for new authentication
            echo -e "${CYAN}How would you like to authenticate?${NC}"
            echo ""
            echo -e "1. ${GREEN}Web browser${NC}"
            echo -e "2. ${GREEN}Personal access token${NC}"
            echo ""
            read -p "Enter your choice (1-2): " auth_choice
            
            case $auth_choice in
                1) gh_authenticate_web ;;
                2) gh_authenticate_token ;;
                *) print_error "Invalid choice" ;;
            esac
        else
            log_operation "ERROR" "Failed to logout from GitHub" "GH_SWITCH"
            print_error "Failed to logout"
        fi
    else
        log_operation "INFO" "User cancelled GitHub account switch" "GH_SWITCH"
        print_info "Account switch cancelled"
    fi
}

# Show authentication status
gh_show_status() {
    print_header "GITHUB AUTHENTICATION STATUS"
    
    log_operation "INFO" "Checking GitHub authentication status" "GH_STATUS"
    
    if gh auth status 2>/dev/null; then
        print_success "GitHub authentication is active"
        
        echo ""
        print_info "Authenticated user details:"
        gh api user --jq '{login: .login, name: .name, email: .email, company: .company}' 2>/dev/null || echo "Unable to fetch user details"
    else
        print_warning "Not authenticated with GitHub"
    fi
}

# Logout from GitHub
gh_logout() {
    print_header "GITHUB LOGOUT"
    
    print_warning "This will logout from GitHub CLI"
    echo -e "${YELLOW}Continue? (y/n):${NC}"
    read -p "> " confirm
    
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        log_operation "INFO" "Logging out from GitHub" "GH_LOGOUT"
        if gh auth logout; then
            log_operation "SUCCESS" "Logged out from GitHub successfully" "GH_LOGOUT"
            print_success "Logged out successfully"
        else
            log_operation "ERROR" "Failed to logout from GitHub" "GH_LOGOUT"
            print_error "Logout failed"
        fi
    else
        log_operation "INFO" "User cancelled GitHub logout" "GH_LOGOUT"
        print_info "Logout cancelled"
    fi
}

# Clone GitHub repository
gh_clone_repo() {
    print_header "CLONE GITHUB REPOSITORY"
    
    if ! gh auth status >/dev/null 2>&1; then
        print_error "Please authenticate with GitHub first"
        return 1
    fi
    
    echo -e "${CYAN}Enter repository to clone (format: owner/repo or full URL):${NC}"
    read -p "> " repo_input
    
    if [[ -n "$repo_input" ]]; then
        log_operation "INFO" "Cloning repository: $repo_input" "GH_CLONE"
        
        show_command "gh repo clone $repo_input" "Clone GitHub repository"
        if gh repo clone "$repo_input"; then
            log_operation "SUCCESS" "Repository cloned successfully: $repo_input" "GH_CLONE"
            print_success "Repository cloned successfully"
            
            # Extract repo name for directory change
            repo_name=$(basename "$repo_input" .git)
            if [[ -d "$repo_name" ]]; then
                echo -e "${CYAN}Change to cloned directory? (y/n):${NC}"
                read -p "> " change_dir
                if [[ "$change_dir" == "y" || "$change_dir" == "Y" ]]; then
                    cd "$repo_name" || return 1
                    print_success "Changed to directory: $(pwd)"
                fi
            fi
        else
            log_operation "ERROR" "Failed to clone repository: $repo_input" "GH_CLONE"
            print_error "Failed to clone repository"
        fi
    else
        log_operation "WARNING" "Empty repository input for cloning" "GH_CLONE"
        print_error "Repository cannot be empty"
    fi
}

# SSH Key Management
ssh_key_management() {
    print_header "SSH KEY MANAGEMENT"
    
    echo -e "${CYAN}Choose an operation:${NC}"
    echo ""
    echo -e "1. ${GREEN}Generate new SSH key${NC}"
    echo -e "2. ${GREEN}List SSH keys${NC}"
    echo -e "3. ${GREEN}Test SSH connection to GitHub${NC}"
    echo -e "4. ${GREEN}Add SSH key to GitHub${NC}"
    echo -e "5. ${GREEN}Back to authentication menu${NC}"
    echo ""
    
    read -p "Enter your choice (1-5): " ssh_choice
    echo ""
    
    case $ssh_choice in
        1) generate_ssh_key ;;
        2) list_ssh_keys ;;
        3) test_ssh_github ;;
        4) add_ssh_key_github ;;
        5) return 0 ;;
        *) print_error "Invalid choice!" ;;
    esac
}

# Generate SSH key
generate_ssh_key() {
    print_header "GENERATE SSH KEY"
    
    echo -e "${CYAN}Enter your email for the SSH key:${NC}"
    read -p "> " email
    
    if [[ -n "$email" ]]; then
        echo -e "${CYAN}Enter a filename for the key (or press Enter for default):${NC}"
        read -p "> " keyname
        
        if [[ -z "$keyname" ]]; then
            keyname="id_rsa"
        fi
        
        key_path="$HOME/.ssh/$keyname"
        
        log_operation "INFO" "Generating SSH key: $key_path" "SSH_GEN"
        
        if ssh-keygen -t rsa -b 4096 -C "$email" -f "$key_path"; then
            log_operation "SUCCESS" "SSH key generated: $key_path" "SSH_GEN"
            print_success "SSH key generated successfully"
            print_info "Public key location: ${key_path}.pub"
            
            # Start SSH agent and add key
            eval "$(ssh-agent -s)"
            ssh-add "$key_path"
            
            print_info "SSH key added to agent"
        else
            log_operation "ERROR" "Failed to generate SSH key" "SSH_GEN"
            print_error "Failed to generate SSH key"
        fi
    else
        print_error "Email cannot be empty"
    fi
}

# List SSH keys
list_ssh_keys() {
    print_header "SSH KEYS"
    
    if [[ -d "$HOME/.ssh" ]]; then
        print_info "SSH keys in $HOME/.ssh:"
        echo ""
        ls -la "$HOME/.ssh"/*.pub 2>/dev/null || print_warning "No public keys found"
    else
        print_warning "SSH directory does not exist"
    fi
}

# Test SSH connection to GitHub
test_ssh_github() {
    print_header "TEST SSH CONNECTION"
    
    log_operation "INFO" "Testing SSH connection to GitHub" "SSH_TEST"
    
    print_info "Testing SSH connection to GitHub..."
    if ssh -T git@github.com; then
        log_operation "SUCCESS" "SSH connection to GitHub successful" "SSH_TEST"
        print_success "SSH connection successful"
    else
        log_operation "WARNING" "SSH connection to GitHub failed or not configured" "SSH_TEST"
        print_warning "SSH connection failed or not configured"
        print_info "You may need to add your SSH key to GitHub"
    fi
}

# Add SSH key to GitHub
add_ssh_key_github() {
    print_header "ADD SSH KEY TO GITHUB"
    
    if ! gh auth status >/dev/null 2>&1; then
        print_error "Please authenticate with GitHub first"
        return 1
    fi
    
    # List available public keys
    print_info "Available SSH public keys:"
    echo ""
    
    if ls "$HOME/.ssh"/*.pub 2>/dev/null; then
        echo ""
        echo -e "${CYAN}Enter the full path to the public key file:${NC}"
        read -p "> " key_file
        
        if [[ -f "$key_file" ]]; then
            echo -e "${CYAN}Enter a title for this key:${NC}"
            read -p "> " key_title
            
            if [[ -n "$key_title" ]]; then
                log_operation "INFO" "Adding SSH key to GitHub: $key_file" "SSH_ADD"
                
                if gh ssh-key add "$key_file" --title "$key_title"; then
                    log_operation "SUCCESS" "SSH key added to GitHub successfully" "SSH_ADD"
                    print_success "SSH key added to GitHub"
                else
                    log_operation "ERROR" "Failed to add SSH key to GitHub" "SSH_ADD"
                    print_error "Failed to add SSH key"
                fi
            else
                print_error "Key title cannot be empty"
            fi
        else
            print_error "Key file not found: $key_file"
        fi
    else
        print_warning "No SSH public keys found"
        print_info "Generate an SSH key first"
    fi
}

# GitLab Authentication and Management
gitlab_authentication_menu() {
    while true; do
        print_header "GITLAB AUTHENTICATION"
        
        # Show PAT status
        if check_gitlab_pat; then
            local stored_pat=$(get_gitlab_pat)
            print_info "📱 GitLab PAT Status: ${GREEN}STORED${NC} (Token: ${stored_pat:0:8}...)"
        else
            print_info "📱 GitLab PAT Status: ${RED}NOT STORED${NC}"
        fi
        echo ""
        
        echo -e "${CYAN}Choose an operation:${NC}"
        echo ""
        echo -e "1. ${GREEN}Start SSH agent and add identity key${NC}"
        if check_gitlab_pat; then
            echo -e "2. ${GREEN}Validate GitLab credentials with stored PAT${NC} ${YELLOW}(use stored PAT)${NC}"
        else
            echo -e "2. ${GREEN}Validate GitLab credentials with stored PAT${NC} ${RED}(no PAT stored)${NC}"
        fi
        if check_gitlab_pat; then
            echo -e "3. ${GREEN}Save new GitLab PAT${NC} ${YELLOW}(replace current PAT)${NC}"
        else
            echo -e "3. ${GREEN}Save new GitLab PAT${NC} ${YELLOW}(enter and store PAT for future use)${NC}"
        fi
        echo -e "4. ${GREEN}Validate GitLab credentials with user-provided PAT${NC} ${YELLOW}(one-time validation)${NC}"
        echo -e "5. ${GREEN}Generate new GitLab PAT${NC} ${YELLOW}(opens GitLab in browser)${NC}"
        if check_gitlab_pat; then
            echo -e "6. ${GREEN}Remove stored GitLab PAT${NC} ${YELLOW}(delete current PAT)${NC}"
        else
            echo -e "6. ${GREEN}Remove stored GitLab PAT${NC} ${RED}(no PAT to remove)${NC}"
        fi
        echo -e "7. ${GREEN}Show GitLab local committer credentials${NC}"
        echo -e "8. ${GREEN}Set GitLab local committer credentials${NC}"
        echo -e "9. ${GREEN}Back to main menu${NC}"
        echo ""
        
        read -p "Enter your choice (1-9): " choice
        echo ""
        
        case $choice in
            1) gitlab_ssh_agent_key_session ;;
            2) gitlab_validate_stored_pat ;;
            3) gitlab_save_new_pat ;;
            4) gitlab_validate_user_pat_once ;;
            5) gitlab_generate_pat ;;
            6) remove_gitlab_pat ;;
            7) gitlab_local_commiter ;;
            8) gitlab_set_commiter_credentials ;;
            9) return 0 ;;
            *) 
                print_error "Invalid choice! Please enter 1-9."
                log_operation "WARNING" "Invalid menu choice: $choice" "GITLAB_MENU"
                ;;
        esac
        
        pause
    done
}

# GitLab SSH agent and key session management
gitlab_ssh_agent_key_session() {
    print_header "GITLAB SSH AGENT SESSION"
    
    log_operation "INFO" "Starting GitLab SSH agent session" "GITLAB_SSH"
    
    echo -e "${CYAN}$(date) - Starting ssh agent...${NC}"
    echo ""

    # Check if an SSH agent is already running
    if [[ -f ~/.ssh-agent-info ]]; then
        source ~/.ssh-agent-info > /dev/null
        if ssh-add -l > /dev/null 2>&1; then
            print_info "SSH agent is already running."
        else
            eval "$(ssh-agent -s)" > ~/.ssh-agent-info
            echo "export SSH_AUTH_SOCK=$SSH_AUTH_SOCK" > ~/.ssh-agent-info
            echo "export SSH_AGENT_PID=$SSH_AGENT_PID" >> ~/.ssh-agent-info
            chmod 600 ~/.ssh-agent-info
            print_success "New SSH agent started."
        fi
    else
        eval "$(ssh-agent -s)" > ~/.ssh-agent-info
        echo "export SSH_AUTH_SOCK=$SSH_AUTH_SOCK" > ~/.ssh-agent-info
        echo "export SSH_AGENT_PID=$SSH_AGENT_PID" >> ~/.ssh-agent-info
        chmod 600 ~/.ssh-agent-info
        print_success "SSH agent started."
    fi

    echo ""
    echo -e "${CYAN}$(date) - Adding SSH identity key...${NC}"
    echo ""
    
    # Check for common GitLab SSH key names
    local key_file=""
    local possible_keys=("~/.ssh/id_ed25519_eclypsium_key" "~/.ssh/id_ed25519" "~/.ssh/id_rsa")
    
    for key in "${possible_keys[@]}"; do
        if [[ -f $(eval echo "$key") ]]; then
            key_file=$(eval echo "$key")
            break
        fi
    done
    
    if [[ -n "$key_file" ]]; then
        if ssh-add "$key_file"; then
            log_operation "SUCCESS" "SSH key added: $key_file" "GITLAB_SSH"
            print_success "SSH key added successfully: $(basename "$key_file")"
        else
            log_operation "ERROR" "Failed to add SSH key: $key_file" "GITLAB_SSH"
            print_error "Failed to add SSH key"
        fi
    else
        print_warning "No GitLab SSH key found in ~/.ssh/"
        print_info "Expected files: id_ed25519_eclypsium_key, id_ed25519, or id_rsa"
        
        echo -e "${CYAN}Enter path to your GitLab SSH private key:${NC}"
        read -p "> " user_key
        
        if [[ -f "$user_key" ]]; then
            if ssh-add "$user_key"; then
                log_operation "SUCCESS" "SSH key added: $user_key" "GITLAB_SSH"
                print_success "SSH key added successfully"
            else
                log_operation "ERROR" "Failed to add SSH key: $user_key" "GITLAB_SSH"
                print_error "Failed to add SSH key"
            fi
        else
            print_error "SSH key file not found: $user_key"
        fi
    fi

    echo ""
    echo -e "${CYAN}$(date) - Validating identity to git@gitlab.com...${NC}"
    echo ""

    print_info "🔄 Validating SSH connection to GitLab..."
    echo ""
    
    local ssh_output=$(ssh -T git@gitlab.com 2>&1)
    local ssh_exit_code=$?

    echo -e "${YELLOW}🔍 GitLab SSH Response:${NC}"
    echo "$ssh_output"
    echo ""

    if [[ "$ssh_output" == *"Welcome to GitLab"* ]]; then
        log_operation "SUCCESS" "GitLab SSH authentication successful" "GITLAB_SSH"
        print_success "✅ Successfully authenticated with GitLab."
    elif [[ $ssh_exit_code -eq 1 && "$ssh_output" =~ "Welcome to GitLab" ]]; then
        log_operation "INFO" "GitLab SSH connection valid but may require action" "GITLAB_SSH"
        print_info "✅ SSH connection is valid. GitLab recognized the user but may require further action."
    else
        log_operation "ERROR" "GitLab SSH authentication failed" "GITLAB_SSH"
        print_error "❌ Error: Authentication failed or no valid user found."
    fi

    echo ""
    echo "------------------------------------------------------------------------------------------------------------"
    echo ""
    echo -e "${CYAN}$(date) - SSH session setup complete${NC}"
}

# GitLab PAT validation function
gitlab_validate_pat() {
    local token="$1"
    local gitlab_api_url="https://gitlab.com/api/v4/user"
    
    print_info "🔒 Validating GitLab Authentication..."
    echo ""
    
    log_operation "INFO" "Validating GitLab PAT" "GITLAB_PAT"
    
    local auth_response
    auth_response=$(curl -s --header "PRIVATE-TOKEN: $token" "$gitlab_api_url")

    if echo "$auth_response" | jq -e '.id' > /dev/null 2>&1; then
        local auth_user
        auth_user=$(echo "$auth_response" | jq -r '.username')
        
        log_operation "SUCCESS" "GitLab PAT validation successful for user: $auth_user" "GITLAB_PAT"
        print_success "✅ Authentication successful for GitLab user: $auth_user"
        return 0
    else
        log_operation "ERROR" "GitLab PAT validation failed" "GITLAB_PAT"
        print_error "❌ Authentication failed! Invalid PAT or API access issue."
        return 1
    fi
}

# Function to get GitLab PAT from local file
get_gitlab_pat() {
    local pat_file="$HOME/.gitlab_pat"
    
    if [[ -f "$pat_file" ]]; then
        cat "$pat_file"
    else
        echo ""
    fi
}

# Function to save GitLab PAT to local file
save_gitlab_pat() {
    local pat="$1"
    local pat_file="$HOME/.gitlab_pat"
    
    if [[ -n "$pat" ]]; then
        echo "$pat" > "$pat_file"
        chmod 600 "$pat_file"  # Secure file permissions
        print_success "GitLab PAT saved to $pat_file"
    else
        print_error "Invalid PAT provided"
        return 1
    fi
}

# Function to remove GitLab PAT file
remove_gitlab_pat() {
    local pat_file="$HOME/.gitlab_pat"
    
    if [[ -f "$pat_file" ]]; then
        echo -e "${YELLOW}Are you sure you want to remove the stored GitLab PAT? (y/n):${NC}"
        read -p "> " confirm
        if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
            rm "$pat_file"
            print_success "GitLab PAT file removed"
        else
            print_info "PAT removal cancelled"
        fi
    else
        print_info "No GitLab PAT file found"
    fi
}

# Function to check if GitLab PAT exists
check_gitlab_pat() {
    local pat_file="$HOME/.gitlab_pat"
    
    if [[ -f "$pat_file" ]]; then
        return 0
    else
        return 1
    fi
}

# Function to make authenticated GitLab API calls
gitlab_api_call() {
    local endpoint="$1"
    local method="${2:-GET}"
    local stored_pat=$(get_gitlab_pat)
    
    if [[ -z "$stored_pat" ]]; then
        print_error "No GitLab PAT found. Please set up your PAT first using the GitLab Authentication menu."
        return 1
    fi
    
    local response
    case "$method" in
        "GET")
            response=$(curl -s --header "PRIVATE-TOKEN: $stored_pat" "$endpoint")
            ;;
        "POST")
            response=$(curl -s -X POST --header "PRIVATE-TOKEN: $stored_pat" "$endpoint")
            ;;
        "PUT")
            response=$(curl -s -X PUT --header "PRIVATE-TOKEN: $stored_pat" "$endpoint")
            ;;
        "DELETE")
            response=$(curl -s -X DELETE --header "PRIVATE-TOKEN: $stored_pat" "$endpoint")
            ;;
        *)
            print_error "Unsupported HTTP method: $method"
            return 1
            ;;
    esac
    
    # Check for API errors
    if echo "$response" | jq -e '.message' >/dev/null 2>&1; then
        local error_message=$(echo "$response" | jq -r '.message')
        if [[ "$error_message" == "401 Unauthorized" ]]; then
            print_error "GitLab API authentication failed. Please check your PAT."
            return 1
        fi
    fi
    
    echo "$response"
}

# Validate with stored PAT
gitlab_validate_stored_pat() {
    print_header "VALIDATE GITLAB CREDENTIALS (STORED PAT)"
    
    local stored_pat=$(get_gitlab_pat)
    
    if [[ -z "$stored_pat" ]]; then
        print_error "No GitLab PAT found in local storage"
        print_info "To set up your GitLab PAT, you can:"
        print_info "• Option 3: Save new GitLab PAT (enter and store PAT for future use)"
        print_info "• Option 5: Generate new GitLab PAT (opens GitLab in browser)"
        return 1
    fi
    
    print_info "Using stored GitLab PAT for validation"
    print_info "Token: ${stored_pat:0:8}... (stored in ~/.gitlab_pat)"
    echo ""
    
    gitlab_validate_pat "$stored_pat"
}

# Save new GitLab PAT
gitlab_save_new_pat() {
    print_header "SAVE NEW GITLAB PAT"
    
    # Check if PAT already exists
    if check_gitlab_pat; then
        print_warning "A GitLab PAT is already stored in ~/.gitlab_pat"
        echo -e "${YELLOW}Would you like to replace it with a new one? (y/n):${NC}"
        read -p "> " replace_choice
        if [[ "$replace_choice" != "y" && "$replace_choice" != "Y" ]]; then
            print_info "Operation cancelled"
            return 0
        fi
    fi
    
    print_info "You'll need a Personal Access Token from GitLab"
    print_info "Create one at: https://gitlab.com/-/user_settings/personal_access_tokens"
    print_info "Required scopes: api, read_user, read_repository"
    echo ""
    
    echo -e "${CYAN}Enter your GitLab Personal Access Token:${NC}"
    read -s -p "> " user_pat
    echo ""
    echo ""
    
    if [[ -n "$user_pat" ]]; then
        print_info "Validating PAT..."
        if gitlab_validate_pat "$user_pat"; then
            echo ""
            save_gitlab_pat "$user_pat"
            print_success "PAT saved successfully and validated!"
        else
            print_error "PAT validation failed. Not saving invalid PAT."
        fi
    else
        print_error "Token cannot be empty"
    fi
}

# Validate with user-provided PAT (one-time, no saving)
gitlab_validate_user_pat_once() {
    print_header "VALIDATE GITLAB CREDENTIALS (ONE-TIME)"
    
    print_info "This will validate your PAT without storing it"
    print_info "Use option 3 if you want to save the PAT for future use"
    echo ""
    
    echo -e "${CYAN}Enter your GitLab Personal Access Token:${NC}"
    read -s -p "> " user_pat
    echo ""
    echo ""
    
    if [[ -n "$user_pat" ]]; then
        gitlab_validate_pat "$user_pat"
    else
        print_error "Token cannot be empty"
    fi
}

# Validate with user-provided PAT (legacy function for backward compatibility)
gitlab_validate_user_pat() {
    # Redirect to the new one-time validation function
    gitlab_validate_user_pat_once
}

# Generate new GitLab PAT
gitlab_generate_pat() {
    print_header "GENERATE GITLAB PERSONAL ACCESS TOKEN"
    
    log_operation "INFO" "Redirecting to GitLab PAT generation" "GITLAB_PAT_GEN"
    
    print_info "You will be redirected to the GitLab PAT (Personal Access Token) portal"
    print_info "Required scopes: api, read_user, read_repository"
    echo ""
    
    read -p "Press enter to be redirected to the GitLab PAT portal: " enter
    echo ""
    
    local gitlab_generate_pat_url="https://gitlab.com/-/user_settings/personal_access_tokens"
    
    if command -v xdg-open >/dev/null 2>&1; then
        xdg-open "$gitlab_generate_pat_url"
        print_success "Browser opened with GitLab PAT generation page"
    elif command -v gnome-terminal >/dev/null 2>&1 && command -v google-chrome >/dev/null 2>&1; then
        gnome-terminal -- google-chrome --profile-directory="Profile 5" "$gitlab_generate_pat_url"
        print_success "Chrome opened with GitLab PAT generation page"
    else
        print_info "Please open this URL manually:"
        print_info "$gitlab_generate_pat_url"
    fi
    
    echo ""
    print_info "After creating your PAT, you can validate it using option 3 from the menu"
}

# Show GitLab local committer credentials
gitlab_local_commiter() {
    print_header "GITLAB LOCAL COMMITTER CREDENTIALS"
    
    log_operation "INFO" "Displaying Git configuration" "GITLAB_CONFIG"
    
    print_info "Current Git configuration:"
    echo ""
    
    git config --list --show-origin
}

# Set GitLab committer credentials
gitlab_set_commiter_credentials() {
    print_header "SET GITLAB COMMITTER CREDENTIALS"
    
    log_operation "INFO" "Setting GitLab committer credentials" "GITLAB_CONFIG"
    
    echo -e "${CYAN}Provide your GitLab username:${NC}"
    read -p "> " username
    echo ""
    
    echo -e "${CYAN}Provide your GitLab email:${NC}"
    read -p "> " email
    echo ""

    if [[ -n "$username" && -n "$email" ]]; then
        # Set GitLab credentials
        git config --global credential.helper store
        git config --global user.name "$username"
        git config --global user.email "$email"
        
        log_operation "SUCCESS" "GitLab credentials set for user: $username" "GITLAB_CONFIG"
        print_success "GitLab credentials configured successfully"
        print_info "Username: $username"
        print_info "Email: $email"
        print_info "Credential helper: store"
    else
        log_operation "ERROR" "Empty username or email provided" "GITLAB_CONFIG"
        print_error "Username and email cannot be empty"
    fi
}

# Repository Initialization and Management
repository_management() {
    while true; do
        print_header "REPOSITORY MANAGEMENT"
        
        echo -e "${CYAN}Choose an operation:${NC}"
        echo ""
        echo -e "1. ${GREEN}Initialize new repository${NC} ${YELLOW}(Setup Git repository with remote)${NC}"
        echo -e "2. ${GREEN}Create remote repository${NC} ${YELLOW}(GitHub repository creation)${NC}"
        echo -e "3. ${GREEN}Delete remote repository${NC} ${YELLOW}(GitHub repository deletion)${NC}"
        echo -e "4. ${GREEN}Configure Git account${NC} ${YELLOW}(Set user name and email)${NC}"
        echo -e "5. ${GREEN}Remote URL management${NC} ${YELLOW}(Setup origin/upstream)${NC}"
        echo -e "6. ${GREEN}Repository health check${NC} ${YELLOW}(Validate repository setup)${NC}"
        echo -e "7. ${GREEN}Back to main menu${NC}"
        echo ""
        
        read -p "Enter your choice (1-7): " choice
        echo ""
        
        case $choice in
            1) repository_init_wizard ;;
            2) create_remote_repository ;;
            3) delete_remote_repository ;;
            4) configure_git_account ;;
            5) remote_urls_manager ;;
            6) repository_health_check ;;
            7) return 0 ;;
            *) 
                print_error "Invalid choice! Please enter 1-7."
                log_operation "WARNING" "Invalid menu choice: $choice" "REPO_MENU"
                ;;
        esac
        
        pause
    done
}

# Repository initialization wizard
repository_init_wizard() {
    print_header "REPOSITORY INITIALIZATION WIZARD"
    
    log_operation "INFO" "Starting repository initialization wizard" "REPO_INIT"
    
    local current_dir=$(pwd)
    local repo_name=$(basename "$current_dir")
    
    print_info "Current directory: $current_dir"
    print_info "Suggested repository name: $repo_name"
    echo ""
    
    # Step 1: Check if already a git repository
    if [[ -d ".git" ]]; then
        print_warning "This directory is already a Git repository"
        
        echo -e "${CYAN}What would you like to do?${NC}"
        echo ""
        echo -e "1. ${GREEN}Reinitialize (will preserve existing history)${NC}"
        echo -e "2. ${GREEN}Setup remote only${NC}"
        echo -e "3. ${GREEN}Cancel${NC}"
        echo ""
        read -p "Enter your choice (1-3): " git_choice
        
        case $git_choice in
            1) 
                log_operation "INFO" "Reinitializing existing repository" "REPO_INIT"
                ;;
            2) 
                configure_repository_remote "$repo_name"
                return 0
                ;;
            3) 
                log_operation "INFO" "Repository initialization cancelled" "REPO_INIT"
                return 0
                ;;
            *) 
                print_error "Invalid choice"
                return 1
                ;;
        esac
    fi
    
    # Step 2: Initialize Git repository
    if [[ ! -d ".git" ]]; then
        print_info "Initializing Git repository..."
        log_operation "INFO" "Initializing Git repository in $current_dir" "REPO_INIT"
        
        if git init; then
            log_operation "SUCCESS" "Git repository initialized" "REPO_INIT"
            print_success "Git repository initialized"
        else
            log_operation "ERROR" "Failed to initialize Git repository" "REPO_INIT"
            print_error "Failed to initialize Git repository"
            return 1
        fi
    fi
    
    # Step 3: Configure Git user (if not set)
    configure_git_user_if_needed
    
    # Step 4: Create initial commit
    create_initial_commit "$repo_name"
    
    # Step 5: Setup remote repository
    echo -e "${CYAN}Would you like to create a remote repository? (y/n):${NC}"
    read -p "> " create_remote
    
    if [[ "$create_remote" == "y" || "$create_remote" == "Y" ]]; then
        configure_repository_remote "$repo_name"
    fi
    
    # Step 6: Final status
    print_success "Repository initialization completed!"
    print_info "Repository status:"
    git status
    
    log_operation "SUCCESS" "Repository initialization wizard completed" "REPO_INIT"
}

# Configure Git user if needed
configure_git_user_if_needed() {
    local git_user=$(git config user.name 2>/dev/null)
    local git_email=$(git config user.email 2>/dev/null)
    
    if [[ -z "$git_user" ]] || [[ -z "$git_email" ]]; then
        print_warning "Git user configuration is missing"
        configure_git_account
    else
        print_info "Git user: $git_user <$git_email>"
    fi
}

# Create initial commit
create_initial_commit() {
    local repo_name="$1"
    
    # Check if there are any files to commit
    if [[ ! -f "README.md" ]]; then
        print_info "Creating README.md..."
        
        cat <<EOF > README.md
# $repo_name

📅 **Created:** $(date +"%Y-%m-%d %H:%M:%S")

---

## About This Project

Welcome to the **$repo_name** repository! 🎉

This repository was created using the Git Workflow Manager tool.

## Getting Started

1. Clone this repository:
   \`\`\`bash
   git clone <repository-url>
   \`\`\`

2. Navigate into the directory:
   \`\`\`bash
   cd $repo_name
   \`\`\`

## Project Structure

- \`README.md\` - This file
- Add your project files here

---

💡 *Happy coding! 🚀*
EOF
        
        log_operation "SUCCESS" "README.md created" "REPO_INIT"
        print_success "README.md created"
    fi
    
    # Add and commit files
    print_info "Creating initial commit..."
    
    git add .
    if git commit -m "Initial commit - Repository setup

- Added README.md
- Repository initialized with Git Workflow Manager
- Date: $(date '+%Y-%m-%d %H:%M:%S')"; then
        log_operation "SUCCESS" "Initial commit created" "REPO_INIT"
        print_success "Initial commit created"
    else
        log_operation "WARNING" "No changes to commit or commit failed" "REPO_INIT"
        print_warning "No changes to commit or commit failed"
    fi
}

# Configure repository remote
configure_repository_remote() {
    local repo_name="$1"
    
    if ! gh_tool_check; then
        print_error "GitHub CLI is required for remote repository creation"
        return 1
    fi
    
    if ! gh auth status >/dev/null 2>&1; then
        print_error "Please authenticate with GitHub first"
        print_info "Use the GitHub Authentication menu to login"
        return 1
    fi
    
    # Get GitHub username
    local github_user
    github_user=$(gh api user --jq '.login' 2>/dev/null)
    
    if [[ -z "$github_user" ]]; then
        print_error "Could not determine GitHub username"
        return 1
    fi
    
    print_info "GitHub user: $github_user"
    echo -e "${CYAN}Repository name [$repo_name]:${NC}"
    read -p "> " custom_repo_name
    
    if [[ -n "$custom_repo_name" ]]; then
        repo_name="$custom_repo_name"
    fi
    
    # Check if repository already exists
    if gh repo view "$github_user/$repo_name" &>/dev/null; then
        print_warning "Repository '$repo_name' already exists under '$github_user'"
        echo -e "${CYAN}Add as remote anyway? (y/n):${NC}"
        read -p "> " add_existing
        
        if [[ "$add_existing" != "y" && "$add_existing" != "Y" ]]; then
            return 0
        fi
    else
        # Create new repository
        echo -e "${CYAN}Repository visibility:${NC}"
        echo -e "1. ${GREEN}Public${NC}"
        echo -e "2. ${GREEN}Private${NC}"
        echo ""
        read -p "Enter your choice (1-2): " visibility_choice
        
        local visibility="--public"
        if [[ "$visibility_choice" == "2" ]]; then
            visibility="--private"
        fi
        
        print_info "Creating GitHub repository '$repo_name'..."
        log_operation "INFO" "Creating GitHub repository: $github_user/$repo_name" "REPO_CREATE"
        
        if gh repo create "$github_user/$repo_name" $visibility --source=. --remote=origin; then
            log_operation "SUCCESS" "GitHub repository created: $github_user/$repo_name" "REPO_CREATE"
            print_success "GitHub repository created successfully"
        else
            log_operation "ERROR" "Failed to create GitHub repository" "REPO_CREATE"
            print_error "Failed to create GitHub repository"
            return 1
        fi
    fi
    
    # Setup remote URLs
    remote_urls_manager
    
    # Push initial commit
    local default_branch
    default_branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "main")
    
    echo -e "${CYAN}Push initial commit to remote? (y/n):${NC}"
    read -p "> " push_initial
    
    if [[ "$push_initial" == "y" || "$push_initial" == "Y" ]]; then
        print_info "Pushing to remote repository..."
        log_operation "INFO" "Pushing initial commit to remote" "REPO_PUSH"
        
        if git push -u origin "$default_branch"; then
            log_operation "SUCCESS" "Initial commit pushed to remote" "REPO_PUSH"
            print_success "Repository pushed to GitHub successfully"
        else
            log_operation "ERROR" "Failed to push to remote repository" "REPO_PUSH"
            print_error "Failed to push to remote repository"
        fi
    fi
}

# Create remote repository (standalone)
create_remote_repository() {
    print_header "CREATE REMOTE REPOSITORY"
    
    if ! gh_tool_check; then
        print_error "GitHub CLI is required for repository creation"
        return 1
    fi
    
    if ! gh auth status >/dev/null 2>&1; then
        print_error "Please authenticate with GitHub first"
        return 1
    fi
    
    echo -e "${CYAN}Enter repository name:${NC}"
    read -p "> " repo_name
    
    if [[ -z "$repo_name" ]]; then
        print_error "Repository name cannot be empty"
        return 1
    fi
    
    echo -e "${CYAN}Repository visibility:${NC}"
    echo -e "1. ${GREEN}Public${NC}"
    echo -e "2. ${GREEN}Private${NC}"
    echo ""
    read -p "Enter your choice (1-2): " visibility_choice
    
    local visibility="--public"
    if [[ "$visibility_choice" == "2" ]]; then
        visibility="--private"
    fi
    
    echo -e "${CYAN}Add description (optional):${NC}"
    read -p "> " description
    
    local desc_flag=""
    if [[ -n "$description" ]]; then
        desc_flag="--description \"$description\""
    fi
    
    print_info "Creating repository '$repo_name'..."
    log_operation "INFO" "Creating repository: $repo_name" "REPO_CREATE"
    
    if eval "gh repo create \"$repo_name\" $visibility $desc_flag"; then
        log_operation "SUCCESS" "Repository created: $repo_name" "REPO_CREATE"
        print_success "Repository created successfully"
        
        echo -e "${CYAN}Clone the repository locally? (y/n):${NC}"
        read -p "> " clone_choice
        
        if [[ "$clone_choice" == "y" || "$clone_choice" == "Y" ]]; then
            gh_clone_repo
        fi
    else
        log_operation "ERROR" "Failed to create repository: $repo_name" "REPO_CREATE"
        print_error "Failed to create repository"
    fi
}

# Delete remote repository
delete_remote_repository() {
    print_header "DELETE REMOTE REPOSITORY"
    
    if ! gh_tool_check; then
        print_error "GitHub CLI is required for repository deletion"
        return 1
    fi
    
    if ! gh auth status >/dev/null 2>&1; then
        print_error "Please authenticate with GitHub first"
        return 1
    fi
    
    print_warning "This action will permanently delete the remote repository!"
    echo ""
    
    echo -e "${CYAN}Enter repository to delete (format: owner/repo):${NC}"
    read -p "> " repo_to_delete
    
    if [[ -z "$repo_to_delete" ]]; then
        print_error "Repository name cannot be empty"
        return 1
    fi
    
    # Show repository information
    print_info "Repository information:"
    if gh repo view "$repo_to_delete"; then
        echo ""
        print_warning "This will permanently delete the repository and all its data!"
        echo -e "${RED}Type 'DELETE' to confirm:${NC}"
        read -p "> " confirmation
        
        if [[ "$confirmation" == "DELETE" ]]; then
            log_operation "INFO" "Deleting repository: $repo_to_delete" "REPO_DELETE"
            
            if gh repo delete "$repo_to_delete" --yes; then
                log_operation "SUCCESS" "Repository deleted: $repo_to_delete" "REPO_DELETE"
                print_success "Repository deleted successfully"
            else
                log_operation "ERROR" "Failed to delete repository: $repo_to_delete" "REPO_DELETE"
                print_error "Failed to delete repository"
            fi
        else
            log_operation "INFO" "Repository deletion cancelled" "REPO_DELETE"
            print_info "Repository deletion cancelled"
        fi
    else
        print_error "Repository not found or access denied"
    fi
}

# Configure Git account
configure_git_account() {
    print_header "CONFIGURE GIT ACCOUNT"
    
    local current_name=$(git config user.name 2>/dev/null)
    local current_email=$(git config user.email 2>/dev/null)
    
    if [[ -n "$current_name" ]]; then
        print_info "Current Git name: $current_name"
    fi
    
    if [[ -n "$current_email" ]]; then
        print_info "Current Git email: $current_email"
    fi
    
    echo ""
    echo -e "${CYAN}Configure Git user settings:${NC}"
    echo ""
    echo -e "1. ${GREEN}Set name only${NC}"
    echo -e "2. ${GREEN}Set email only${NC}"
    echo -e "3. ${GREEN}Set both name and email${NC}"
    echo -e "4. ${GREEN}View current configuration${NC}"
    echo -e "5. ${GREEN}Cancel${NC}"
    echo ""
    
    read -p "Enter your choice (1-5): " config_choice
    echo ""
    
    case $config_choice in
        1)
            echo -e "${CYAN}Enter Git user name:${NC}"
            read -p "> " git_name
            if [[ -n "$git_name" ]]; then
                git config user.name "$git_name"
                log_operation "SUCCESS" "Git user name set to: $git_name" "GIT_CONFIG"
                print_success "Git user name set to: $git_name"
            fi
            ;;
        2)
            echo -e "${CYAN}Enter Git user email:${NC}"
            read -p "> " git_email
            if [[ -n "$git_email" ]]; then
                git config user.email "$git_email"
                log_operation "SUCCESS" "Git user email set to: $git_email" "GIT_CONFIG"
                print_success "Git user email set to: $git_email"
            fi
            ;;
        3)
            echo -e "${CYAN}Enter Git user name:${NC}"
            read -p "> " git_name
            echo -e "${CYAN}Enter Git user email:${NC}"
            read -p "> " git_email
            
            if [[ -n "$git_name" ]]; then
                git config user.name "$git_name"
                log_operation "SUCCESS" "Git user name set to: $git_name" "GIT_CONFIG"
                print_success "Git user name set to: $git_name"
            fi
            
            if [[ -n "$git_email" ]]; then
                git config user.email "$git_email"
                log_operation "SUCCESS" "Git user email set to: $git_email" "GIT_CONFIG"
                print_success "Git user email set to: $git_email"
            fi
            ;;
        4)
            print_info "Current Git configuration:"
            echo ""
            git config --list | grep -E "user\.(name|email)" || print_warning "No user configuration found"
            ;;
        5)
            print_info "Configuration cancelled"
            ;;
        *)
            print_error "Invalid choice!"
            ;;
    esac
}

# Remote URLs manager
remote_urls_manager() {
    print_header "REMOTE URL MANAGEMENT"
    
    print_info "Current remote configuration:"
    git remote -v 2>/dev/null || print_warning "No remotes configured"
    echo ""
    
    echo -e "${CYAN}Choose an operation:${NC}"
    echo ""
    echo -e "1. ${GREEN}Add origin remote${NC}"
    echo -e "2. ${GREEN}Add upstream remote${NC}"
    echo -e "3. ${GREEN}Update origin URL${NC}"
    echo -e "4. ${GREEN}Update upstream URL${NC}"
    echo -e "5. ${GREEN}Remove remote${NC}"
    echo -e "6. ${GREEN}View all remotes${NC}"
    echo -e "7. ${GREEN}Back${NC}"
    echo ""
    
    read -p "Enter your choice (1-7): " remote_choice
    echo ""
    
    case $remote_choice in
        1) add_remote "origin" ;;
        2) add_remote "upstream" ;;
        3) update_remote "origin" ;;
        4) update_remote "upstream" ;;
        5) remove_remote ;;
        6) view_remotes ;;
        7) return 0 ;;
        *) print_error "Invalid choice!" ;;
    esac
}

# Add remote
add_remote() {
    local remote_name="$1"
    
    if git remote get-url "$remote_name" >/dev/null 2>&1; then
        print_warning "Remote '$remote_name' already exists"
        local current_url=$(git remote get-url "$remote_name")
        print_info "Current URL: $current_url"
        
        echo -e "${CYAN}Update existing remote? (y/n):${NC}"
        read -p "> " update_choice
        
        if [[ "$update_choice" == "y" || "$update_choice" == "Y" ]]; then
            update_remote "$remote_name"
        fi
        return 0
    fi
    
    echo -e "${CYAN}Enter URL for '$remote_name' remote:${NC}"
    read -p "> " remote_url
    
    if [[ -n "$remote_url" ]]; then
        if git remote add "$remote_name" "$remote_url"; then
            log_operation "SUCCESS" "Added $remote_name remote: $remote_url" "REMOTE_CONFIG"
            print_success "Remote '$remote_name' added successfully"
        else
            log_operation "ERROR" "Failed to add $remote_name remote" "REMOTE_CONFIG"
            print_error "Failed to add remote"
        fi
    else
        print_error "URL cannot be empty"
    fi
}

# Update remote
update_remote() {
    local remote_name="$1"
    
    if ! git remote get-url "$remote_name" >/dev/null 2>&1; then
        print_error "Remote '$remote_name' does not exist"
        return 1
    fi
    
    local current_url=$(git remote get-url "$remote_name")
    print_info "Current URL: $current_url"
    
    echo -e "${CYAN}Enter new URL for '$remote_name' remote:${NC}"
    read -p "> " new_url
    
    if [[ -n "$new_url" ]]; then
        if git remote set-url "$remote_name" "$new_url"; then
            log_operation "SUCCESS" "Updated $remote_name remote to: $new_url" "REMOTE_CONFIG"
            print_success "Remote '$remote_name' updated successfully"
        else
            log_operation "ERROR" "Failed to update $remote_name remote" "REMOTE_CONFIG"
            print_error "Failed to update remote"
        fi
    else
        print_error "URL cannot be empty"
    fi
}

# Remove remote
remove_remote() {
    local remotes=$(git remote 2>/dev/null)
    
    if [[ -z "$remotes" ]]; then
        print_warning "No remotes configured"
        return 0
    fi
    
    print_info "Current remotes:"
    git remote -v
    echo ""
    
    echo -e "${CYAN}Enter remote name to remove:${NC}"
    read -p "> " remote_to_remove
    
    if [[ -n "$remote_to_remove" ]]; then
        if git remote remove "$remote_to_remove"; then
            log_operation "SUCCESS" "Removed remote: $remote_to_remove" "REMOTE_CONFIG"
            print_success "Remote '$remote_to_remove' removed successfully"
        else
            log_operation "ERROR" "Failed to remove remote: $remote_to_remove" "REMOTE_CONFIG"
            print_error "Failed to remove remote"
        fi
    else
        print_error "Remote name cannot be empty"
    fi
}

# View remotes
view_remotes() {
    print_info "Remote configuration:"
    echo ""
    
    if git remote -v 2>/dev/null; then
        echo ""
        print_info "Detailed remote information:"
        for remote in $(git remote 2>/dev/null); do
            echo -e "${CYAN}$remote:${NC}"
            echo -e "  Fetch: $(git remote get-url "$remote" 2>/dev/null || echo 'Not set')"
            echo -e "  Push:  $(git remote get-url --push "$remote" 2>/dev/null || echo 'Not set')"
        done
    else
        print_warning "No remotes configured"
    fi
}

# Repository health check
repository_health_check() {
    print_header "REPOSITORY HEALTH CHECK"
    
    log_operation "INFO" "Running repository health check" "REPO_HEALTH"
    
    local issues=0
    
    # Check if in Git repository
    if [[ ! -d ".git" ]]; then
        print_error "Not in a Git repository"
        ((issues++))
    else
        print_success "Git repository detected"
    fi
    
    # Check Git configuration
    local git_name=$(git config user.name 2>/dev/null)
    local git_email=$(git config user.email 2>/dev/null)
    
    if [[ -z "$git_name" ]]; then
        print_warning "Git user name not configured"
        ((issues++))
    else
        print_success "Git user name: $git_name"
    fi
    
    if [[ -z "$git_email" ]]; then
        print_warning "Git user email not configured"
        ((issues++))
    else
        print_success "Git user email: $git_email"
    fi
    
    # Check remotes
    local remotes=$(git remote 2>/dev/null)
    if [[ -z "$remotes" ]]; then
        print_warning "No remote repositories configured"
        ((issues++))
    else
        print_success "Remote repositories configured: $remotes"
        
        # Test remote connections
        for remote in $remotes; do
            local remote_url=$(git remote get-url "$remote" 2>/dev/null)
            print_info "Testing connection to $remote ($remote_url)..."
            
            if git ls-remote "$remote" >/dev/null 2>&1; then
                print_success "Connection to $remote: OK"
            else
                print_warning "Connection to $remote: Failed"
                ((issues++))
            fi
        done
    fi
    
    # Check working directory status
    if git diff --quiet && git diff --cached --quiet 2>/dev/null; then
        print_success "Working directory clean"
    else
        print_warning "Working directory has uncommitted changes"
        git status --short
    fi
    
    # Check for untracked files
    local untracked=$(git ls-files --others --exclude-standard 2>/dev/null)
    if [[ -n "$untracked" ]]; then
        print_warning "Untracked files detected:"
        echo "$untracked"
    else
        print_success "No untracked files"
    fi
    
    # Summary
    echo ""
    if [[ $issues -eq 0 ]]; then
        print_success "Repository health check passed! ✅"
        log_operation "SUCCESS" "Repository health check completed - no issues" "REPO_HEALTH"
    else
        print_warning "Repository health check found $issues issue(s) ⚠️"
        log_operation "WARNING" "Repository health check completed - $issues issues found" "REPO_HEALTH"
    fi
}

# Git Statistics and Reporting Module
git_statistics_menu() {
    while true; do
        print_header "GIT STATISTICS & REPORTING"
        
        echo -e "${CYAN}Choose an operation:${NC}"
        echo ""
        echo -e "1. ${GREEN}Repository Analysis${NC} ${YELLOW}(Single repository detailed analysis)${NC}"
        echo -e "2. ${GREEN}Multi-Repository Analysis${NC} ${YELLOW}(All repositories for a user)${NC}"
        echo -e "3. ${GREEN}Generate HTML Report${NC} ${YELLOW}(Professional visual report)${NC}"
        echo -e "4. ${GREEN}View Log Files${NC} ${YELLOW}(Browse and view generated logs)${NC}"
        echo -e "5. ${GREEN}Search Logs${NC} ${YELLOW}(Search patterns in log files)${NC}"
        echo -e "6. ${GREEN}Log Management${NC} ${YELLOW}(Delete and manage log files)${NC}"
        echo -e "7. ${GREEN}Quick Repository Stats${NC} ${YELLOW}(Current repository overview)${NC}"
        echo -e "8. ${GREEN}Back to main menu${NC}"
        echo ""
        
        read -p "Enter your choice (1-8): " choice
        echo ""
        
        case $choice in
            1) analyze_single_repository ;;
            2) analyze_multiple_repositories ;;
            3) generate_html_report ;;
            4) view_log_files ;;
            5) search_log_files ;;
            6) log_management ;;
            7) quick_repository_stats ;;
            8) return 0 ;;
            *) 
                print_error "Invalid choice! Please enter 1-8."
                log_operation "WARNING" "Invalid menu choice: $choice" "STATS_MENU"
                ;;
        esac
        
        pause
    done
}

# Analyze single repository
analyze_single_repository() {
    print_header "SINGLE REPOSITORY ANALYSIS"
    
    echo -e "${CYAN}Select repository provider:${NC}"
    echo ""
    echo -e "1. ${GREEN}GitHub${NC} ${YELLOW}(github.com repositories)${NC}"
    echo -e "2. ${GREEN}GitLab${NC} ${YELLOW}(gitlab.com repositories)${NC}"
    echo -e "3. ${GREEN}Auto-detect from URL${NC} ${YELLOW}(Enter full repository URL)${NC}"
    echo ""
    read -p "Enter your choice (1-3): " provider_choice
    
    local provider=""
    local repo_input=""
    
    case $provider_choice in
        1)
            provider="github"
            if ! gh_tool_check; then
                print_error "GitHub CLI is required for GitHub repository analysis"
                return 1
            fi
            
            if ! gh auth status >/dev/null 2>&1; then
                print_error "Please authenticate with GitHub first"
                return 1
            fi
            
            echo -e "${CYAN}Enter GitHub repository (format: owner/repo):${NC}"
            read -p "> " repo_input
            ;;
        2)
            provider="gitlab"
            
            # Validate GitLab authentication before proceeding
            print_info "Validating GitLab authentication..."
            
            # Check if user has configured GitLab credentials
            local gitlab_user=$(git config user.name 2>/dev/null)
            local gitlab_email=$(git config user.email 2>/dev/null)
            
            if [[ -z "$gitlab_user" || -z "$gitlab_email" ]]; then
                print_warning "GitLab credentials not configured"
                print_info "Please configure GitLab credentials first using the GitLab Authentication menu (option 7)"
                return 1
            fi
            
            # Test GitLab connectivity with stored PAT for validation
            local stored_pat=$(get_gitlab_pat)
            if [[ -z "$stored_pat" ]] || ! gitlab_validate_pat "$stored_pat" >/dev/null 2>&1; then
                print_warning "GitLab authentication validation failed"
                print_info "Please validate your GitLab authentication using the GitLab Authentication menu (option 7)"
                echo -e "${YELLOW}Would you like to proceed anyway? (y/n):${NC}"
                read -p "> " proceed_anyway
                if [[ "$proceed_anyway" != "y" && "$proceed_anyway" != "Y" ]]; then
                    return 1
                fi
            else
                print_success "GitLab authentication validated successfully"
            fi
            
            echo -e "${CYAN}Enter GitLab repository (format: owner/repo or full URL):${NC}"
            read -p "> " repo_input
            
            # Parse GitLab URL if full URL provided
            if [[ "$repo_input" == *"gitlab.com"* ]]; then
                # Extract owner/repo from GitLab URL
                if [[ "$repo_input" =~ gitlab\.com[:/]([^/]+)/([^/\.]+) ]]; then
                    repo_input="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
                    print_info "Extracted repository: $repo_input"
                fi
            fi
            ;;
        3)
            echo -e "${CYAN}Enter full repository URL:${NC}"
            read -p "> " repo_input
            
            if [[ -z "$repo_input" ]]; then
                print_error "Repository URL cannot be empty"
                return 1
            fi
            
            # Auto-detect provider from URL
            if [[ "$repo_input" == *"github.com"* ]]; then
                provider="github"
                # Extract owner/repo from GitHub URL
                if [[ "$repo_input" =~ github\.com[:/]([^/]+)/([^/\.]+) ]]; then
                    repo_input="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
                fi
            elif [[ "$repo_input" == *"gitlab.com"* ]] || [[ "$repo_input" == *"gitlab"* ]]; then
                provider="gitlab"
                # Extract owner/repo from GitLab URL
                if [[ "$repo_input" =~ gitlab\.com[:/]([^/]+)/([^/\.]+) ]]; then
                    repo_input="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
                fi
                
                # Validate GitLab authentication
                print_info "GitLab repository detected - validating authentication..."
                
                local gitlab_user=$(git config user.name 2>/dev/null)
                local gitlab_email=$(git config user.email 2>/dev/null)
                
                if [[ -z "$gitlab_user" || -z "$gitlab_email" ]]; then
                    print_warning "GitLab credentials not configured"
                    print_info "Please configure GitLab credentials first using the GitLab Authentication menu (option 7)"
                    return 1
                fi
                
                # Test GitLab connectivity with stored PAT for validation
                local stored_pat=$(get_gitlab_pat)
                if [[ -z "$stored_pat" ]] || ! gitlab_validate_pat "$stored_pat" >/dev/null 2>&1; then
                    print_warning "GitLab authentication validation failed or no stored PAT found"
                    print_info "Please set up your GitLab PAT using the GitLab Authentication menu (option 7)"
                    echo -e "${YELLOW}Would you like to proceed anyway? (y/n):${NC}"
                    read -p "> " proceed_anyway
                    if [[ "$proceed_anyway" != "y" && "$proceed_anyway" != "Y" ]]; then
                        return 1
                    fi
                else
                    print_success "GitLab authentication validated successfully"
                fi
            else
                print_error "Unable to detect provider from URL. Please select GitHub or GitLab manually."
                return 1
            fi
            ;;
        *)
            print_error "Invalid choice! Please enter 1-3."
            return 1
            ;;
    esac
    
    if [[ -z "$repo_input" ]]; then
        print_error "Repository cannot be empty"
        return 1
    fi
    
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local safe_repo_name="${repo_input//\//_}"
    local logfile="${provider}_${safe_repo_name}_analysis_${timestamp}.log"
    
    log_operation "INFO" "Starting $provider repository analysis: $repo_input" "REPO_ANALYSIS"
    
    print_info "Analyzing $provider repository: $repo_input"
    print_info "Log file: $logfile"
    echo ""
    
    # Start analysis
    {
        echo "==============================================="
        echo "Repository Analysis Report"
        echo "Provider: $(echo "$provider" | tr '[:lower:]' '[:upper:]')"
        echo "Repository: $repo_input"
        echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "==============================================="
        echo ""
        
        if [[ "$provider" == "github" ]]; then
            fetch_repository_details "$repo_input"
        else
            fetch_gitlab_repository_details "$repo_input"
        fi
        
    } | tee "$logfile"
    
    log_operation "SUCCESS" "Repository analysis completed: $logfile" "REPO_ANALYSIS"
    print_success "Analysis completed! Report saved to: $logfile"
    
    echo -e "${CYAN}Generate HTML report from this data? (y/n):${NC}"
    read -p "> " generate_html
    
    if [[ "$generate_html" == "y" || "$generate_html" == "Y" ]]; then
        generate_html_from_log "$logfile" "$repo_input" "$provider"
    fi
}

# Fetch repository details (main analysis function)
fetch_repository_details() {
    local repo="$1"
    
    log_operation "INFO" "Fetching details for repository: $repo" "FETCH_DETAILS"
    
    echo -e "${BLUE}🔍 Fetching activity for repository: ${CYAN}$repo${NC}"
    
    # Repository basic info
    echo -e "\n${MAGENTA}📊 Repository Information:${NC}"
    gh repo view "$repo" --json name,description,createdAt,pushedAt,isPrivate,stargazerCount,forkCount,watchers \
        --jq '"📁 Name: \(.name)", "📝 Description: \(.description // "No description")", "📅 Created: \(.createdAt)", "🔄 Last Push: \(.pushedAt)", "🔒 Private: \(.isPrivate)", "⭐ Stars: \(.stargazerCount)", "🍴 Forks: \(.forkCount)", "👀 Watchers: \(.watchers)"' 2>/dev/null || echo "❌ Unable to fetch repository info"
    
    # Fetch branches
    echo -e "\n${MAGENTA}📂 Branches Analysis:${NC}"
    local branches_data=$(gh api "repos/$repo/branches" --jq '.[] | "🌿 \(.name) - Protected: \(.protected) - Last commit: \(.commit.sha[0:7])"' 2>/dev/null)
    if [[ -n "$branches_data" ]]; then
        echo "$branches_data"
        local branch_count=$(echo "$branches_data" | wc -l)
        echo "📊 Total branches: $branch_count"
    else
        echo "❌ Unable to fetch branches"
    fi
    
    # Latest commits per branch
    echo -e "\n${MAGENTA}📜 Recent Commits by Branch:${NC}"
    for branch in $(gh api "repos/$repo/branches" --jq '.[].name' 2>/dev/null | head -5); do
        echo -e "\n${CYAN}📌 Branch: ${YELLOW}$branch${NC}"
        gh api "repos/$repo/commits?sha=$branch" --jq '.[] | "🔹 \(.commit.author.date) - \(.commit.message | split("\n")[0]) by \(.commit.author.name)"' 2>/dev/null | head -3
    done
    
    # Pull requests analysis
    echo -e "\n${MAGENTA}📬 Pull Requests Analysis:${NC}"
    local pr_open=$(gh pr list --repo "$repo" --state open --json number --jq '. | length' 2>/dev/null || echo "0")
    local pr_closed=$(gh pr list --repo "$repo" --state closed --json number --jq '. | length' 2>/dev/null || echo "0")
    local pr_merged=$(gh pr list --repo "$repo" --state merged --json number --jq '. | length' 2>/dev/null || echo "0")
    
    echo "📊 Open PRs: $pr_open"
    echo "📊 Closed PRs: $pr_closed"
    echo "📊 Merged PRs: $pr_merged"
    
    echo -e "\n${CYAN}Recent Pull Requests:${NC}"
    gh pr list --repo "$repo" --state all --limit 5 --json title,author,createdAt,state,number \
        --jq '.[] | "📌 #\(.number) [\(.state | ascii_upcase)]: \(.title) by \(.author.login) (\(.createdAt | split("T")[0]))"' 2>/dev/null || echo "❌ No pull requests found"
    
    # Issues analysis
    echo -e "\n${MAGENTA}🐞 Issues Analysis:${NC}"
    local issues_open=$(gh issue list --repo "$repo" --state open --json number --jq '. | length' 2>/dev/null || echo "0")
    local issues_closed=$(gh issue list --repo "$repo" --state closed --json number --jq '. | length' 2>/dev/null || echo "0")
    
    echo "📊 Open Issues: $issues_open"
    echo "📊 Closed Issues: $issues_closed"
    
    echo -e "\n${CYAN}Recent Issues:${NC}"
    gh issue list --repo "$repo" --state all --limit 5 --json title,author,createdAt,state,number \
        --jq '.[] | "📌 #\(.number) [\(.state | ascii_upcase)]: \(.title) by \(.author.login) (\(.createdAt | split("T")[0]))"' 2>/dev/null || echo "❌ No issues found"
    
    # Contributors analysis
    echo -e "\n${MAGENTA}👥 Contributors Analysis:${NC}"
    gh api "repos/$repo/contributors" --jq '.[] | "👤 \(.login) - Contributions: \(.contributions)"' 2>/dev/null | head -10 || echo "❌ Unable to fetch contributors"
    
    # Languages analysis
    echo -e "\n${MAGENTA}💻 Languages Used:${NC}"
    gh api "repos/$repo/languages" --jq 'to_entries | .[] | "📝 \(.key): \(.value) bytes"' 2>/dev/null || echo "❌ Unable to fetch languages"
    
    # Releases
    echo -e "\n${MAGENTA}🚀 Releases:${NC}"
    gh release list --repo "$repo" --limit 5 --json tagName,name,publishedAt \
        --jq '.[] | "🏷️  \(.tagName) - \(.name) (\(.publishedAt | split("T")[0]))"' 2>/dev/null || echo "❌ No releases found"
    
    # Repository activity metrics
    echo -e "\n${MAGENTA}📈 Activity Metrics:${NC}"
    local commit_count=$(gh api "repos/$repo/commits" --jq '. | length' 2>/dev/null || echo "0")
    echo "📊 Recent commits visible: $commit_count"
    
    echo -e "\n${GREEN}✅ Analysis Complete!${NC}"
}

# Fetch GitLab repository details
fetch_gitlab_repository_details() {
    local repo="$1"
    
    log_operation "INFO" "Fetching details for GitLab repository: $repo" "FETCH_GITLAB_DETAILS"
    
    echo -e "${BLUE}🔍 Fetching activity for GitLab repository: ${CYAN}$repo${NC}"
    
    # GitLab API base URL
    local gitlab_api="https://gitlab.com/api/v4"
    local repo_encoded="${repo//\//%2F}"
    
    # Check if repository exists and is accessible
    echo -e "\n${MAGENTA}🔍 Repository Validation:${NC}"
    if gitlab_api_call "${gitlab_api}/projects/${repo_encoded}" >/dev/null; then
        echo "✅ Repository exists and is accessible"
    else
        echo "❌ Repository not found or not accessible"
        echo "   Please check:"
        echo "   • Repository exists: https://gitlab.com/$repo"
        echo "   • Repository is public or you have access"
        echo "   • Repository format is correct (owner/repo)"
        echo "   • GitLab PAT is configured and valid"
        return 1
    fi
    
    # Repository basic info
    echo -e "\n${MAGENTA}📊 Repository Information:${NC}"
    local repo_info=$(gitlab_api_call "${gitlab_api}/projects/${repo_encoded}" 2>/dev/null)
    if [[ -n "$repo_info" ]]; then
        echo "$repo_info" | jq -r '
            "📁 Name: " + .name,
            "📝 Description: " + (.description // "No description"),
            "📅 Created: " + .created_at,
            "🔄 Last Activity: " + .last_activity_at,
            "🔒 Visibility: " + .visibility,
            "⭐ Stars: " + (.star_count | tostring),
            "🍴 Forks: " + (.forks_count | tostring),
            "👀 Issues: " + (.open_issues_count | tostring)' 2>/dev/null || echo "❌ Unable to parse repository info"
    else
        echo "❌ Unable to fetch repository info"
    fi
    
    # Fetch branches
    echo -e "\n${MAGENTA}📂 Branches Analysis:${NC}"
    local branches_data=$(gitlab_api_call "${gitlab_api}/projects/${repo_encoded}/repository/branches" 2>/dev/null)
    if [[ -n "$branches_data" ]] && [[ "$branches_data" != "null" ]]; then
        echo "$branches_data" | jq -r '.[] | "🌿 " + .name + " - Protected: " + (.protected | tostring) + " - Last commit: " + .commit.short_id' 2>/dev/null || echo "❌ Unable to parse branches"
        local branch_count=$(echo "$branches_data" | jq '. | length' 2>/dev/null || echo "0")
        echo "📊 Total branches: $branch_count"
    else
        echo "❌ Unable to fetch branches"
    fi
    
    # Latest commits per branch (limited to first 5 branches)
    echo -e "\n${MAGENTA}📜 Recent Commits by Branch:${NC}"
    local branch_names=$(gitlab_api_call "${gitlab_api}/projects/${repo_encoded}/repository/branches" 2>/dev/null | jq -r '.[0:5][].name' 2>/dev/null)
    if [[ -n "$branch_names" ]]; then
        while IFS= read -r branch; do
            if [[ -n "$branch" ]]; then
                echo -e "\n${CYAN}📌 Branch: ${YELLOW}$branch${NC}"
                local commits=$(gitlab_api_call "${gitlab_api}/projects/${repo_encoded}/repository/commits?ref_name=${branch}&per_page=3" 2>/dev/null)
                if [[ -n "$commits" ]] && [[ "$commits" != "null" ]]; then
                    echo "$commits" | jq -r '.[] | "🔹 " + .created_at + " - " + (.message | split("\n")[0]) + " by " + .author_name' 2>/dev/null || echo "❌ Unable to fetch commits for $branch"
                fi
            fi
        done <<< "$branch_names"
    else
        echo "❌ Unable to fetch branch information for commits"
    fi
    
    # Merge requests analysis
    echo -e "\n${MAGENTA}📬 Merge Requests Analysis:${NC}"
    local mr_opened=$(gitlab_api_call "${gitlab_api}/projects/${repo_encoded}/merge_requests?state=opened&per_page=1" 2>/dev/null | jq '. | length' 2>/dev/null || echo "0")
    local mr_closed=$(gitlab_api_call "${gitlab_api}/projects/${repo_encoded}/merge_requests?state=closed&per_page=1" 2>/dev/null | jq '. | length' 2>/dev/null || echo "0")
    local mr_merged=$(gitlab_api_call "${gitlab_api}/projects/${repo_encoded}/merge_requests?state=merged&per_page=1" 2>/dev/null | jq '. | length' 2>/dev/null || echo "0")
    
    echo "📊 Open MRs: $mr_opened"
    echo "📊 Closed MRs: $mr_closed"
    echo "📊 Merged MRs: $mr_merged"
    
    echo -e "\n${CYAN}Recent Merge Requests:${NC}"
    local recent_mrs=$(gitlab_api_call "${gitlab_api}/projects/${repo_encoded}/merge_requests?per_page=5" 2>/dev/null)
    if [[ -n "$recent_mrs" ]] && [[ "$recent_mrs" != "null" ]]; then
        echo "$recent_mrs" | jq -r '.[] | "📌 #" + (.iid | tostring) + " [" + (.state | ascii_upcase) + "]: " + .title + " by " + .author.username + " (" + (.created_at | split("T")[0]) + ")"' 2>/dev/null || echo "❌ No merge requests found"
    else
        echo "❌ No merge requests found"
    fi
    
    # Issues analysis
    echo -e "\n${MAGENTA}🐞 Issues Analysis:${NC}"
    local issues_opened=$(gitlab_api_call "${gitlab_api}/projects/${repo_encoded}/issues?state=opened&per_page=1" 2>/dev/null | jq '. | length' 2>/dev/null || echo "0")
    local issues_closed=$(gitlab_api_call "${gitlab_api}/projects/${repo_encoded}/issues?state=closed&per_page=1" 2>/dev/null | jq '. | length' 2>/dev/null || echo "0")
    
    echo "📊 Open Issues: $issues_opened"
    echo "📊 Closed Issues: $issues_closed"
    
    echo -e "\n${CYAN}Recent Issues:${NC}"
    local recent_issues=$(gitlab_api_call "${gitlab_api}/projects/${repo_encoded}/issues?per_page=5" 2>/dev/null)
    if [[ -n "$recent_issues" ]] && [[ "$recent_issues" != "null" ]]; then
        echo "$recent_issues" | jq -r '.[] | "📌 #" + (.iid | tostring) + " [" + (.state | ascii_upcase) + "]: " + .title + " by " + .author.username + " (" + (.created_at | split("T")[0]) + ")"' 2>/dev/null || echo "❌ No issues found"
    else
        echo "❌ No issues found"
    fi
    
    # Contributors analysis
    echo -e "\n${MAGENTA}👥 Contributors Analysis:${NC}"
    local contributors=$(gitlab_api_call "${gitlab_api}/projects/${repo_encoded}/repository/contributors?per_page=10" 2>/dev/null)
    if [[ -n "$contributors" ]] && [[ "$contributors" != "null" ]]; then
        echo "$contributors" | jq -r '.[] | "👤 " + .name + " (" + .email + ") - Commits: " + (.commits | tostring)' 2>/dev/null || echo "❌ Unable to fetch contributors"
    else
        echo "❌ Unable to fetch contributors"
    fi
    
    # Languages analysis
    echo -e "\n${MAGENTA}💻 Languages Used:${NC}"
    local languages=$(gitlab_api_call "${gitlab_api}/projects/${repo_encoded}/languages" 2>/dev/null)
    if [[ -n "$languages" ]] && [[ "$languages" != "null" ]] && [[ "$languages" != "{}" ]]; then
        echo "$languages" | jq -r 'to_entries | .[] | "📝 " + .key + ": " + (.value | tostring) + "%"' 2>/dev/null || echo "❌ Unable to fetch languages"
    else
        echo "❌ No language data available"
    fi
    
    # Releases/Tags
    echo -e "\n${MAGENTA}🚀 Tags/Releases:${NC}"
    local tags=$(gitlab_api_call "${gitlab_api}/projects/${repo_encoded}/repository/tags?per_page=5" 2>/dev/null)
    if [[ -n "$tags" ]] && [[ "$tags" != "null" ]] && [[ "$tags" != "[]" ]]; then
        echo "$tags" | jq -r '.[] | "🏷️  " + .name + " - " + (.message // "No message") + " (" + (.commit.created_at | split("T")[0]) + ")"' 2>/dev/null || echo "❌ No tags found"
    else
        echo "❌ No tags/releases found"
    fi
    
    # Repository activity metrics
    echo -e "\n${MAGENTA}📈 Activity Metrics:${NC}"
    local commits=$(gitlab_api_call "${gitlab_api}/projects/${repo_encoded}/repository/commits?per_page=1" 2>/dev/null)
    if [[ -n "$commits" ]] && [[ "$commits" != "null" ]]; then
        local commit_count=$(echo "$commits" | jq '. | length' 2>/dev/null || echo "0")
        echo "📊 Recent commits visible: $commit_count"
    else
        echo "📊 Recent commits visible: 0"
    fi
    
    echo -e "\n${GREEN}✅ GitLab Analysis Complete!${NC}"
}

# Analyze multiple repositories
analyze_multiple_repositories() {
    print_header "MULTI-REPOSITORY ANALYSIS"
    
    echo -e "${CYAN}Select provider for multi-repository analysis:${NC}"
    echo ""
    echo -e "1. ${GREEN}GitHub${NC} ${YELLOW}(Analyze all GitHub repositories for a user)${NC}"
    echo -e "2. ${GREEN}GitLab${NC} ${YELLOW}(Analyze all GitLab repositories for a user)${NC}"
    echo ""
    read -p "Enter your choice (1-2): " provider_choice
    
    local provider=""
    case $provider_choice in
        1)
            provider="github"
            if ! gh_tool_check; then
                print_error "GitHub CLI is required for GitHub repository analysis"
                return 1
            fi
            
            if ! gh auth status >/dev/null 2>&1; then
                print_error "Please authenticate with GitHub first"
                return 1
            fi
            
            echo -e "${CYAN}Enter GitHub username:${NC}"
            read -p "> " username
            ;;
        2)
            provider="gitlab"
            
            # Validate GitLab authentication before proceeding
            print_info "Validating GitLab authentication for multi-repository analysis..."
            
            # Check if user has configured GitLab credentials
            local gitlab_user=$(git config user.name 2>/dev/null)
            local gitlab_email=$(git config user.email 2>/dev/null)
            
            if [[ -z "$gitlab_user" || -z "$gitlab_email" ]]; then
                print_warning "GitLab credentials not configured"
                print_info "Please configure GitLab credentials first using the GitLab Authentication menu (option 7)"
                return 1
            fi
            
            # Test GitLab connectivity with stored PAT for validation
            local stored_pat=$(get_gitlab_pat)
            if [[ -z "$stored_pat" ]] || ! gitlab_validate_pat "$stored_pat" >/dev/null 2>&1; then
                print_warning "GitLab authentication validation failed"
                print_info "Please validate your GitLab authentication using the GitLab Authentication menu (option 7)"
                echo -e "${YELLOW}Would you like to proceed anyway? (y/n):${NC}"
                read -p "> " proceed_anyway
                if [[ "$proceed_anyway" != "y" && "$proceed_anyway" != "Y" ]]; then
                    return 1
                fi
            else
                print_success "GitLab authentication validated successfully"
            fi
            
            echo -e "${CYAN}Enter GitLab username:${NC}"
            read -p "> " username
            ;;
        *)
            print_error "Invalid choice! Please enter 1-2."
            return 1
            ;;
    esac
    
    if [[ -z "$username" ]]; then
        print_error "Username cannot be empty"
        return 1
    fi
    
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local logfile="${provider}_${username}_all_repos_analysis_${timestamp}.log"
    
    log_operation "INFO" "Starting $provider multi-repository analysis for user: $username" "MULTI_REPO_ANALYSIS"
    
    print_info "Analyzing all $provider repositories for user: $username"
    print_info "Log file: $logfile"
    echo ""
    
    # Get repository list based on provider
    local repo_list
    if [[ "$provider" == "github" ]]; then
        repo_list=$(gh api "users/$username/repos" --jq '.[].full_name' 2>/dev/null)
    else
        # GitLab - get all projects for user
        local gitlab_api="https://gitlab.com/api/v4"
        repo_list=$(gitlab_api_call "${gitlab_api}/users/${username}/projects?per_page=100" 2>/dev/null | jq -r '.[].path_with_namespace' 2>/dev/null)
    fi
    
    if [[ -z "$repo_list" ]]; then
        print_error "No repositories found or unable to fetch data for $provider user: $username"
        log_operation "ERROR" "No repositories found for $provider user: $username" "MULTI_REPO_ANALYSIS"
        return 1
    fi
    
    local repo_count=$(echo "$repo_list" | wc -l)
    print_info "Found $repo_count repositories on $provider"
    
    # Start analysis
    {
        echo "==============================================="
        echo "Multi-Repository Analysis Report"
        echo "Provider: $(echo "$provider" | tr '[:lower:]' '[:upper:]')"
        echo "User: $username"
        echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Total Repositories: $repo_count"
        echo "==============================================="
        echo ""
        
        local count=1
        for repo in $repo_list; do
            echo ""
            echo "========================================"
            echo "Repository $count/$repo_count: $repo"
            echo "========================================"
            echo ""
            
            if [[ "$provider" == "github" ]]; then
                fetch_repository_details "$repo"
            else
                fetch_gitlab_repository_details "$repo"
            fi
            
            ((count++))
        done
        
        echo ""
        echo "==============================================="
        echo "Multi-Repository Analysis Complete"
        echo "Provider: $(echo "$provider" | tr '[:lower:]' '[:upper:]')"
        echo "Total Repositories Analyzed: $repo_count"
        echo "==============================================="
        
    } | tee "$logfile"
    
    log_operation "SUCCESS" "$provider multi-repository analysis completed: $logfile" "MULTI_REPO_ANALYSIS"
    print_success "Analysis completed! Report saved to: $logfile"
    
    echo -e "${CYAN}Generate HTML report from this data? (y/n):${NC}"
    read -p "> " generate_html
    
    if [[ "$generate_html" == "y" || "$generate_html" == "Y" ]]; then
        generate_html_from_log "$logfile" "$username" "$provider"
    fi
}

# Generate HTML report
generate_html_report() {
    print_header "GENERATE HTML REPORT"
    
    print_info "Available log files for HTML generation:"
    echo ""
    
    local log_files
    log_files=$(ls *.log 2>/dev/null)
    
    if [[ -z "$log_files" ]]; then
        print_warning "No log files found in current directory"
        print_info "Run a repository analysis first to generate data"
        return 1
    fi
    
    echo "$log_files" | nl -w2 -s'. '
    echo ""
    
    echo -e "${CYAN}Enter log file name to convert to HTML:${NC}"
    read -p "> " log_file
    
    if [[ ! -f "$log_file" ]]; then
        print_error "Log file not found: $log_file"
        return 1
    fi
    
    local repo_name=$(basename "$log_file" .log)
    generate_html_from_log "$log_file" "$repo_name"
}

# Generate HTML from log file
generate_html_from_log() {
    local log_file="$1"
    local title="$2"
    local provider="${3:-github}"  # Default to github if not specified
    local html_file="${log_file%.log}.html"
    
    log_operation "INFO" "Generating HTML report from: $log_file (Provider: $provider)" "HTML_GENERATION"
    
    print_info "Generating HTML report: $html_file"
    
    # Set provider-specific colors and title
    local provider_color="#0366d6"  # GitHub blue
    local provider_name="GitHub"
    local provider_icon="🐙"
    
    if [[ "$provider" == "gitlab" ]]; then
        provider_color="#FC6D26"  # GitLab orange
        provider_name="GitLab"
        provider_icon="🦊"
    fi
    
    # Create HTML report
    cat > "$html_file" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$provider_name Repository Analysis Report</title>
    <style>
        :root {
            --primary-color: #0f1419;
            --secondary-color: #1a202c;
            --accent-color: #00d4aa;
            --success-color: #00d4aa;
            --warning-color: #ffa500;
            --error-color: #ff6b6b;
            --info-color: #4fc3f7;
            --background: linear-gradient(135deg, #0f1419 0%, #1a202c 100%);
            --card-background: #1e2936;
            --text-primary: #e2e8f0;
            --text-secondary: #a0aec0;
            --border-color: #2d3748;
            --shadow: 0 8px 25px rgba(0, 0, 0, 0.3);
            --glow-cyan: #00d4aa;
            --glow-blue: #4fc3f7;
            --glow-purple: #9f7aea;
        }
        
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: var(--background);
            color: var(--text-primary);
            line-height: 1.6;
            min-height: 100vh;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 2rem;
        }
        
        .header {
            background: linear-gradient(135deg, var(--secondary-color) 0%, var(--primary-color) 100%);
            border-radius: 16px;
            padding: 2rem;
            margin-bottom: 2rem;
            box-shadow: var(--shadow);
            text-align: center;
            color: var(--text-primary);
            border: 1px solid var(--border-color);
            position: relative;
            overflow: hidden;
        }
        
        .header::before {
            content: '';
            position: absolute;
            top: -2px;
            left: -2px;
            right: -2px;
            bottom: -2px;
            background: linear-gradient(45deg, var(--glow-cyan), var(--glow-blue), var(--glow-purple), var(--glow-cyan));
            border-radius: 18px;
            z-index: -1;
            animation: glow 3s ease-in-out infinite alternate;
        }
        
        @keyframes glow {
            0% { filter: blur(5px) brightness(1); }
            100% { filter: blur(8px) brightness(1.3); }
        }
        
        .header h1 {
            font-size: 2.5rem;
            font-weight: 800;
            margin-bottom: 0.5rem;
            text-shadow: 0 2px 4px rgba(0,0,0,0.3);
        }
        
        .header .subtitle {
            font-size: 1.1rem;
            opacity: 0.9;
        }
        
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 1.5rem;
            margin-bottom: 2rem;
        }
        
        .stat-card {
            background: var(--card-background);
            border-radius: 12px;
            padding: 1.5rem;
            box-shadow: var(--shadow);
            border: 1px solid var(--border-color);
            transition: transform 0.2s ease, box-shadow 0.2s ease;
        }
        
        .stat-card:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 25px rgba(0,0,0,0.15);
        }
        
        .stat-card h3 {
            color: var(--accent-color);
            font-size: 0.9rem;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            margin-bottom: 0.5rem;
            font-weight: 600;
        }
        
        .stat-value {
            font-size: 2rem;
            font-weight: 700;
            color: var(--primary-color);
        }
        
        .content-section {
            background: var(--card-background);
            border-radius: 12px;
            padding: 2rem;
            margin-bottom: 2rem;
            box-shadow: var(--shadow);
            border: 1px solid var(--border-color);
        }
        
        .section-title {
            font-size: 1.5rem;
            color: var(--primary-color);
            margin-bottom: 1rem;
            font-weight: 700;
            border-bottom: 2px solid var(--accent-color);
            padding-bottom: 0.5rem;
        }
        
        .log-content {
            background: var(--primary-color);
            color: var(--text-primary);
            padding: 1.5rem;
            border-radius: 8px;
            font-family: 'Fira Code', 'Monaco', 'Cascadia Code', 'Ubuntu Mono', monospace;
            font-size: 0.9rem;
            line-height: 1.5;
            overflow-x: auto;
            white-space: pre-wrap;
            border: 1px solid var(--border-color);
            box-shadow: inset 0 2px 10px rgba(0, 0, 0, 0.3);
        }
        
        .badge {
            display: inline-block;
            padding: 0.25rem 0.75rem;
            border-radius: 9999px;
            font-size: 0.8rem;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        
        .badge-success { background: var(--success-color); color: white; }
        .badge-warning { background: var(--warning-color); color: white; }
        .badge-error { background: var(--error-color); color: white; }
        .badge-info { background: var(--info-color); color: white; }
        
        .timestamp {
            color: var(--text-secondary);
            font-size: 0.9rem;
            margin-top: 1rem;
            text-align: center;
            font-style: italic;
        }
        
        .highlight {
            background: linear-gradient(120deg, var(--glow-cyan) 0%, var(--glow-blue) 100%);
            color: var(--primary-color);
            padding: 0.2rem 0.4rem;
            border-radius: 4px;
            font-weight: 600;
            box-shadow: 0 0 10px rgba(0, 212, 170, 0.3);
        }
        
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 1.5rem;
            margin-bottom: 2rem;
        }
        
        .stat-card {
            background: var(--card-background);
            border-radius: 12px;
            padding: 1.5rem;
            box-shadow: var(--shadow);
            border: 1px solid var(--border-color);
            transition: all 0.3s ease;
            position: relative;
            overflow: hidden;
        }
        
        .stat-card::before {
            content: '';
            position: absolute;
            top: 0;
            left: -100%;
            width: 100%;
            height: 100%;
            background: linear-gradient(90deg, transparent, rgba(0, 212, 170, 0.1), transparent);
            transition: left 0.5s;
        }
        
        .stat-card:hover::before {
            left: 100%;
        }
        
        .stat-card:hover {
            transform: translateY(-3px);
            box-shadow: 0 12px 30px rgba(0, 212, 170, 0.2);
            border-color: var(--accent-color);
        }
        
        @media (max-width: 768px) {
            .container { padding: 1rem; }
            .header h1 { font-size: 2rem; }
            .stats-grid { grid-template-columns: 1fr; }
        }
        
        .fade-in {
            animation: fadeIn 0.8s ease-in;
        }
        
        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(20px); }
            to { opacity: 1; transform: translateY(0); }
        }
    </style>
</head>
<body>
    <div class="container">
        <header class="header fade-in">
            <h1>PROVIDER_ICON_PLACEHOLDER $provider_name Repository Analysis</h1>
            <p class="subtitle">REPORT_TITLE_PLACEHOLDER</p>
        </header>
        
        <div class="stats-grid fade-in">
            <div class="stat-card">
                <h3>📊 Provider</h3>
                <div class="stat-value" style="color: $provider_color;">$provider_name</div>
            </div>
            <div class="stat-card">
                <h3>📅 Generated</h3>
                <div class="stat-value">TIMESTAMP_PLACEHOLDER</div>
            </div>
            <div class="stat-card">
                <h3>🛠️ Tool</h3>
                <div class="stat-value">Git Workflow Manager</div>
            </div>
        </div>
        
        <section class="content-section fade-in">
            <h2 class="section-title">📋 Analysis Report</h2>
            <div class="log-content">CONTENT_PLACEHOLDER</div>
        </section>
        
        <div class="timestamp fade-in">
            Generated by Git Workflow Manager on FULL_TIMESTAMP_PLACEHOLDER
        </div>
    </div>
</body>
</html>
EOF
    
    # Process the log file content and insert into HTML
    local escaped_content
    escaped_content=$(sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g' "$log_file")
    
    # Replace placeholders using safer approach with proper escaping
    local current_date=$(date '+%Y-%m-%d')
    local full_timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Use awk for safe replacement instead of sed to avoid special character issues
    local temp_file=$(mktemp)
    awk -v title="$title" -v icon="$provider_icon" -v date="$current_date" -v timestamp="$full_timestamp" '
        { gsub(/REPORT_TITLE_PLACEHOLDER/, title); 
          gsub(/PROVIDER_ICON_PLACEHOLDER/, icon); 
          gsub(/TIMESTAMP_PLACEHOLDER/, date); 
          gsub(/FULL_TIMESTAMP_PLACEHOLDER/, timestamp); 
          print }
    ' "$html_file" > "$temp_file" && mv "$temp_file" "$html_file"
    
    # Insert the log content
    temp_file=$(mktemp)
    awk -v content="$escaped_content" '
        /CONTENT_PLACEHOLDER/ { print content; next }
        { print }
    ' "$html_file" > "$temp_file" && mv "$temp_file" "$html_file"
    
    log_operation "SUCCESS" "HTML report generated: $html_file" "HTML_GENERATION"
    print_success "HTML report generated: $html_file"
    
    echo -e "${CYAN}Open the HTML report in your browser? (y/n):${NC}"
    read -p "> " open_browser
    
    if [[ "$open_browser" == "y" || "$open_browser" == "Y" ]]; then
        if command -v xdg-open >/dev/null 2>&1; then
            xdg-open "$html_file" &>/dev/null
            print_success "Opening report in browser..."
        elif command -v open >/dev/null 2>&1; then
            open "$html_file" &>/dev/null
            print_success "Opening report in browser..."
        else
            print_warning "Could not open browser automatically"
            print_info "Please open the file manually: $html_file"
        fi
    fi
}

# View log files
view_log_files() {
    print_header "VIEW LOG FILES"
    
    echo -e "${MAGENTA}📂 Available files in the current directory:${NC}"
    echo ""
    
    local log_files
    log_files=$(ls *.log 2>/dev/null)
    local html_files
    html_files=$(ls *.html 2>/dev/null)
    
    if [[ -n "$log_files" ]]; then
        echo -e "${GREEN}✅ Log files found:${NC}"
        echo ""
        ls -lha *.log
        echo ""
    else
        echo -e "${RED}❌ No log files found.${NC}"
        echo ""
    fi
    
    if [[ -n "$html_files" ]]; then
        echo -e "${GREEN}✅ HTML files found:${NC}"
        echo ""
        ls -lha *.html
        echo ""
    else
        echo -e "${RED}❌ No HTML files found.${NC}"
        echo ""
    fi
    
    if [[ -z "$log_files" && -z "$html_files" ]]; then
        print_warning "No report files found"
        print_info "Run a repository analysis first to generate files"
        return 0
    fi
    
    echo -e "${YELLOW}🔹 Enter filename to view:${NC}"
    read -p "> " file_to_view
    
    if [[ -f "$file_to_view" ]]; then
        if [[ "$file_to_view" == *.log ]]; then
            print_info "Displaying log file: $file_to_view"
            echo ""
            cat "$file_to_view"
        elif [[ "$file_to_view" == *.html ]]; then
            print_info "Opening HTML file in browser: $file_to_view"
            if command -v xdg-open >/dev/null 2>&1; then
                xdg-open "$file_to_view" &>/dev/null
            elif command -v open >/dev/null 2>&1; then
                open "$file_to_view" &>/dev/null
            else
                print_warning "Could not open browser automatically"
                print_info "Please open the file manually: $file_to_view"
            fi
        else
            print_warning "Unsupported file type"
            print_info "File content:"
            cat "$file_to_view"
        fi
    else
        print_error "File not found: $file_to_view"
    fi
}

# Search log files
search_log_files() {
    print_header "SEARCH LOG FILES"
    
    local log_files
    log_files=$(ls *.log 2>/dev/null)
    
    if [[ -z "$log_files" ]]; then
        print_warning "No log files found"
        print_info "Run a repository analysis first to generate log files"
        return 0
    fi
    
    print_info "Available log files:"
    echo ""
    ls -1 *.log
    echo ""
    
    echo -e "${CYAN}Enter log file to search:${NC}"
    read -p "> " log_file
    
    if [[ ! -f "$log_file" ]]; then
        print_error "Log file not found: $log_file"
        return 1
    fi
    
    echo -e "${CYAN}Enter search pattern:${NC}"
    read -p "> " search_pattern
    
    if [[ -z "$search_pattern" ]]; then
        print_error "Search pattern cannot be empty"
        return 1
    fi
    
    print_info "Searching for '$search_pattern' in $log_file"
    echo ""
    
    if grep --color=always -i -n "$search_pattern" "$log_file"; then
        echo ""
        print_success "Search completed"
    else
        print_warning "No matches found for '$search_pattern'"
    fi
}

# Log management
log_management() {
    while true; do
        print_header "LOG MANAGEMENT"
        
        echo -e "${CYAN}Choose an operation:${NC}"
        echo ""
        echo -e "1. ${GREEN}List all log files${NC}"
        echo -e "2. ${GREEN}Delete specific log file${NC}"
        echo -e "3. ${GREEN}Delete all log files${NC}"
        echo -e "4. ${GREEN}Archive old logs${NC}"
        echo -e "5. ${GREEN}View log statistics${NC}"
        echo -e "6. ${GREEN}Back to statistics menu${NC}"
        echo ""
        
        read -p "Enter your choice (1-6): " choice
        echo ""
        
        case $choice in
            1) list_log_files ;;
            2) delete_specific_log ;;
            3) delete_all_logs ;;
            4) archive_old_logs ;;
            5) view_log_statistics ;;
            6) return 0 ;;
            *) print_error "Invalid choice!" ;;
        esac
        
        pause
    done
}

# List log files
list_log_files() {
    print_header "LOG FILES LIST"
    
    print_info "Current directory log files:"
    echo ""
    
    if ls *.log &>/dev/null; then
        ls -lha *.log
        echo ""
        local count=$(ls *.log 2>/dev/null | wc -l)
        print_info "Total log files: $count"
    else
        print_warning "No log files found in current directory"
    fi
    
    echo ""
    print_info "Workflow manager log files:"
    if [[ -d "$LOG_DIR" ]]; then
        ls -lha "$LOG_DIR"/*.log 2>/dev/null || print_warning "No workflow logs found"
    else
        print_warning "Log directory not found: $LOG_DIR"
    fi
}

# Delete specific log file
delete_specific_log() {
    print_header "DELETE SPECIFIC LOG FILE"
    
    local log_files
    log_files=$(ls *.log 2>/dev/null)
    
    if [[ -z "$log_files" ]]; then
        print_warning "No log files found"
        return 0
    fi
    
    print_info "Available log files:"
    echo ""
    echo "$log_files" | nl -w2 -s'. '
    echo ""
    
    echo -e "${CYAN}Enter log file name to delete:${NC}"
    read -p "> " log_file
    
    if [[ ! -f "$log_file" ]]; then
        print_error "Log file not found: $log_file"
        return 1
    fi
    
    print_warning "This will permanently delete: $log_file"
    echo -e "${YELLOW}Are you sure? (y/n):${NC}"
    read -p "> " confirm
    
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        if rm "$log_file"; then
            log_operation "SUCCESS" "Deleted log file: $log_file" "LOG_MANAGEMENT"
            print_success "Log file deleted: $log_file"
        else
            log_operation "ERROR" "Failed to delete log file: $log_file" "LOG_MANAGEMENT"
            print_error "Failed to delete log file"
        fi
    else
        print_info "Deletion cancelled"
    fi
}

# Delete all logs
delete_all_logs() {
    print_header "DELETE ALL LOG FILES"
    
    local log_files
    log_files=$(ls *.log 2>/dev/null)
    
    if [[ -z "$log_files" ]]; then
        print_warning "No log files found"
        return 0
    fi
    
    local count=$(echo "$log_files" | wc -l)
    print_warning "This will permanently delete $count log files:"
    echo ""
    ls -1 *.log
    echo ""
    
    echo -e "${RED}Type 'DELETE ALL' to confirm:${NC}"
    read -p "> " confirmation
    
    if [[ "$confirmation" == "DELETE ALL" ]]; then
        if rm *.log 2>/dev/null; then
            log_operation "SUCCESS" "Deleted all log files ($count files)" "LOG_MANAGEMENT"
            print_success "All log files deleted ($count files)"
        else
            log_operation "ERROR" "Failed to delete some log files" "LOG_MANAGEMENT"
            print_error "Failed to delete some log files"
        fi
    else
        print_info "Deletion cancelled"
    fi
}

# Archive old logs
archive_old_logs() {
    print_header "ARCHIVE OLD LOGS"
    
    local archive_name="logs_archive_$(date +%Y%m%d_%H%M%S).tar.gz"
    local log_files
    log_files=$(ls *.log 2>/dev/null)
    
    if [[ -z "$log_files" ]]; then
        print_warning "No log files found to archive"
        return 0
    fi
    
    local count=$(echo "$log_files" | wc -l)
    print_info "Creating archive of $count log files..."
    
    if tar -czf "$archive_name" *.log 2>/dev/null; then
        log_operation "SUCCESS" "Created log archive: $archive_name" "LOG_MANAGEMENT"
        print_success "Archive created: $archive_name"
        
        echo -e "${CYAN}Delete original log files after archiving? (y/n):${NC}"
        read -p "> " delete_originals
        
        if [[ "$delete_originals" == "y" || "$delete_originals" == "Y" ]]; then
            rm *.log 2>/dev/null
            print_success "Original log files deleted"
        fi
    else
        log_operation "ERROR" "Failed to create archive" "LOG_MANAGEMENT"
        print_error "Failed to create archive"
    fi
}

# View log statistics
view_log_statistics() {
    print_header "LOG STATISTICS"
    
    local log_files
    log_files=$(ls *.log 2>/dev/null)
    
    if [[ -z "$log_files" ]]; then
        print_warning "No log files found"
        return 0
    fi
    
    local total_files=$(echo "$log_files" | wc -l)
    local total_size=$(du -ch *.log 2>/dev/null | tail -1 | cut -f1)
    
    print_info "Log file statistics:"
    echo ""
    echo -e "${CYAN}📊 Total log files:${NC} $total_files"
    echo -e "${CYAN}📦 Total size:${NC} $total_size"
    echo ""
    
    print_info "File breakdown:"
    echo ""
    for log_file in $log_files; do
        local lines=$(wc -l < "$log_file" 2>/dev/null || echo "0")
        local size=$(du -h "$log_file" 2>/dev/null | cut -f1)
        local date=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$log_file" 2>/dev/null || stat -c "%y" "$log_file" 2>/dev/null | cut -d' ' -f1,2 | cut -d'.' -f1)
        
        echo -e "${GREEN}📄 $log_file${NC}"
        echo -e "   Size: $size | Lines: $lines | Modified: $date"
    done
    echo ""
    
    # Show oldest and newest
    local oldest=$(ls -tr *.log 2>/dev/null | head -1)
    local newest=$(ls -t *.log 2>/dev/null | head -1)
    
    if [[ -n "$oldest" ]]; then
        echo -e "${CYAN}📅 Oldest log:${NC} $oldest"
    fi
    
    if [[ -n "$newest" ]]; then
        echo -e "${CYAN}📅 Newest log:${NC} $newest"
    fi
}

# Quick repository stats
quick_repository_stats() {
    print_header "QUICK REPOSITORY STATS"
    
    # Check if in git repository
    if [[ ! -d ".git" ]]; then
        print_error "Not in a Git repository"
        print_info "Navigate to a Git repository first"
        return 1
    fi
    
    log_operation "INFO" "Generating quick repository stats" "QUICK_STATS"
    
    local repo_name=$(basename "$(pwd)")
    print_info "Repository: $repo_name"
    print_info "Location: $(pwd)"
    echo ""
    
    # Basic repository info
    echo -e "${MAGENTA}📊 Repository Overview:${NC}"
    
    # Current branch
    local current_branch=$(git branch --show-current 2>/dev/null || echo "detached")
    echo -e "${GREEN}🌿 Current branch:${NC} $current_branch"
    
    # Total branches
    local branch_count=$(git branch -a 2>/dev/null | wc -l)
    echo -e "${GREEN}📂 Total branches:${NC} $branch_count"
    
    # Commits count
    local commit_count=$(git rev-list --count HEAD 2>/dev/null || echo "0")
    echo -e "${GREEN}📜 Total commits:${NC} $commit_count"
    
    # Contributors
    local contributor_count=$(git log --format='%ae' | sort -u | wc -l 2>/dev/null || echo "0")
    echo -e "${GREEN}👥 Contributors:${NC} $contributor_count"
    
    # Repository size
    if [[ -d ".git" ]]; then
        local repo_size=$(du -sh .git 2>/dev/null | cut -f1 || echo "Unknown")
        echo -e "${GREEN}💾 Repository size:${NC} $repo_size"
    fi
    
    echo ""
    
    # Recent activity
    echo -e "${MAGENTA}📈 Recent Activity:${NC}"
    
    # Last commit
    echo -e "${CYAN}📝 Last commit:${NC}"
    git log -1 --pretty=format:"   %h - %s (%cr) <%an>" 2>/dev/null || echo "   No commits found"
    
    echo ""
    echo ""
    
    # Top contributors
    echo -e "${CYAN}👤 Top contributors:${NC}"
    git log --format='%an' | sort | uniq -c | sort -rn | head -5 | while read count name; do
        echo "   $name: $count commits"
    done 2>/dev/null || echo "   No commit data available"
    
    echo ""
    
    # Working directory status
    echo -e "${MAGENTA}📋 Working Directory Status:${NC}"
    
    if git diff --quiet && git diff --cached --quiet 2>/dev/null; then
        echo -e "${GREEN}✅ Working directory clean${NC}"
    else
        echo -e "${YELLOW}⚠️  Working directory has changes:${NC}"
        git status --short 2>/dev/null
    fi
    
    # Untracked files
    local untracked=$(git ls-files --others --exclude-standard 2>/dev/null)
    if [[ -n "$untracked" ]]; then
        local untracked_count=$(echo "$untracked" | wc -l)
        echo -e "${YELLOW}📁 Untracked files:${NC} $untracked_count"
    else
        echo -e "${GREEN}📁 No untracked files${NC}"
    fi
    
    echo ""
    
    # Remote information
    echo -e "${MAGENTA}🌐 Remote Information:${NC}"
    
    local remotes=$(git remote 2>/dev/null)
    if [[ -n "$remotes" ]]; then
        for remote in $remotes; do
            local remote_url=$(git remote get-url "$remote" 2>/dev/null)
            echo -e "${GREEN}📡 $remote:${NC} $remote_url"
        done
        
        # Check if ahead/behind
        if [[ "$current_branch" != "detached" ]] && git rev-parse @{u} >/dev/null 2>&1; then
            local ahead=$(git rev-list --count @{u}..HEAD 2>/dev/null || echo "0")
            local behind=$(git rev-list --count HEAD..@{u} 2>/dev/null || echo "0")
            
            if [[ "$ahead" -gt 0 ]] && [[ "$behind" -gt 0 ]]; then
                echo -e "${YELLOW}🔄 Branch status: $ahead ahead, $behind behind${NC}"
            elif [[ "$ahead" -gt 0 ]]; then
                echo -e "${GREEN}⬆️  Branch status: $ahead ahead${NC}"
            elif [[ "$behind" -gt 0 ]]; then
                echo -e "${YELLOW}⬇️  Branch status: $behind behind${NC}"
            else
                echo -e "${GREEN}✅ Branch status: up to date${NC}"
            fi
        fi
    else
        echo -e "${YELLOW}⚠️  No remotes configured${NC}"
    fi
    
    log_operation "SUCCESS" "Quick repository stats generated" "QUICK_STATS"
}

# Function to print colored headers
print_header() {
    echo -e "\n${CYAN}================================================${NC}"
    echo -e "${WHITE}$1${NC}"
    echo -e "${CYAN}================================================${NC}\n"
}

# Function to print colored messages
print_success() {
    echo -e "${GREEN}✓ $1${NC}\n"
}

print_error() {
    echo -e "${RED}✗ $1${NC}\n"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}\n"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}\n"
}

# Function to check if we're in a git repository
check_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_error "Not in a Git repository! Please navigate to a Git repository first."
        exit 1
    fi
}

# Function to list branches with colors
list_branches() {
    local current_branch=$(git branch --show-current)
    echo -e "${PURPLE}Available branches:${NC}"
    echo -e "${CYAN}==================${NC}"

    local count=1
    local branches_array=()

    # Get all branches and store in array
    while IFS= read -r branch; do
        # Remove leading spaces, asterisk, and remote prefix
        branch_name=$(echo "$branch" | sed 's/^[* ]*//g' | sed 's/remotes\/origin\///g')

        # Skip if already in array (avoid duplicates)
        if [[ ! " ${branches_array[@]} " =~ " ${branch_name} " ]]; then
            branches_array+=("$branch_name")
        fi
    done < <(git branch -a | grep -v HEAD)

    # Display numbered branches
    for branch_name in "${branches_array[@]}"; do
        if [[ "$branch_name" == "$current_branch" ]]; then
            echo -e "${GREEN}$count. $branch_name ${WHITE}(current)${NC}"
        else
            echo -e "$count. $branch_name"
        fi
        ((count++))
    done
    echo ""
}

# Function to select a branch
select_branch() {
    local action="$1"
    echo -e "${YELLOW}Select branch for $action:${NC}"

    # Get all branches and store in array
    local branches_array=()
    local current_branch=$(git branch --show-current)

    while IFS= read -r branch; do
        # Remove leading spaces, asterisk, and remote prefix
        branch_name=$(echo "$branch" | sed 's/^[* ]*//g' | sed 's/remotes\/origin\///g')

        # Skip if already in array (avoid duplicates)
        if [[ ! " ${branches_array[@]} " =~ " ${branch_name} " ]]; then
            branches_array+=("$branch_name")
        fi
    done < <(git branch -a | grep -v HEAD)

    # Check if we have any branches
    if [[ ${#branches_array[@]} -eq 0 ]]; then
        print_error "No branches found!"
        return 1
    fi

    # Display numbered branches
    echo -e "${PURPLE}Available branches:${NC}"
    echo -e "${CYAN}==================${NC}"
    local count=1
    for branch_name in "${branches_array[@]}"; do
        if [[ "$branch_name" == "$current_branch" ]]; then
            echo -e "${GREEN}$count. $branch_name ${WHITE}(current)${NC}"
        else
            echo -e "$count. $branch_name"
        fi
        ((count++))
    done
    echo ""

    echo -e "${CYAN}Enter branch number, branch name, or 'q' to quit:${NC}"
    read -p "> " branch_choice

    if [[ "$branch_choice" == "q" ]]; then
        return 1
    fi

    # Check if it's a number
    if [[ "$branch_choice" =~ ^[0-9]+$ ]]; then
        # Convert to array index (subtract 1)
        local index=$((branch_choice - 1))
        if [[ $index -ge 0 && $index -lt ${#branches_array[@]} ]]; then
            SELECTED_BRANCH="${branches_array[$index]}"
            return 0
        else
            print_error "Invalid branch number! Please select a number between 1 and ${#branches_array[@]}"
            return 1
        fi
    else
        # Check if branch exists by name
        if [[ " ${branches_array[@]} " =~ " ${branch_choice} " ]]; then
            SELECTED_BRANCH="$branch_choice"
            return 0
        else
            print_error "Branch '$branch_choice' does not exist!"
            return 1
        fi
    fi
}

# Function to show git status with colors
show_git_status() {
    print_info "Current Git Status:"
    git status --short --branch
    echo ""
}

# Function to show command before execution
show_command() {
    local cmd="$1"
    local comment="$2"
    echo -e "${PURPLE}| ${WHITE}$cmd${NC} ${YELLOW}| $comment${NC}"
}

# Function to pause and wait for user input
pause() {
    echo -e "${CYAN}Press Enter to continue...${NC}"
    read
}

# Function to pause and return to submenu
pause_and_return() {
    echo -e "${CYAN}Press Enter to return to menu...${NC}"
    read
}

# Function to return to main menu
return_to_main_menu() {
    echo -e "${CYAN}Press Enter to return to main menu...${NC}"
    read
}

# Function to check for uncommitted changes
check_uncommitted_changes() {
    if ! git diff --quiet || ! git diff --cached --quiet; then
        local current_branch=$(git branch --show-current)
        print_warning "You have uncommitted changes on branch: $current_branch"
        echo ""
        
        # Show summary status
        git status --short
        echo ""
        
        print_error "Cannot proceed with rebase operation due to uncommitted changes."
        print_error "Cannot switch to branch with uncommitted changes"
        print_info "Please handle your changes first:"
        echo -e "${CYAN}• To commit: ${WHITE}git add . && git commit -m \"your message\"${NC}"
        echo -e "${CYAN}• To stash: ${WHITE}git stash push -m \"your message\"${NC}"
        echo -e "${CYAN}• To discard: ${WHITE}git restore .${NC}"
        echo ""
        
        return 1
    fi
    return 0
}

# Start of Day Operations (Point 1)
start_of_day() {
    print_header "START OF DAY - SETUP & CLEANUP"

    print_info "Initial status before start of day operations:"
    show_git_status

    print_info "Switching to master branch..."
    if ! check_uncommitted_changes; then
        return 1
    fi

    show_command "git checkout master" "Switch to master/main branch"
    if git checkout master 2>/dev/null || git checkout main 2>/dev/null; then
        print_success "Switched to main branch"
    else
        print_error "Failed to switch to master/main branch"
        return 1
    fi

    print_info "Updating master branch..."
    show_command "git pull origin master" "Pull latest changes from remote master branch"
    if git pull origin master 2>/dev/null || git pull origin main 2>/dev/null; then
        print_success "Updated master branch"
    else
        print_error "Failed to update master branch"
        return 1
    fi

    print_info "Cleaning up merged branches..."
    show_command "git branch --merged" "List branches that have been merged"
    merged_branches=$(git branch --merged | grep -v "\*\|master\|main" | xargs)

    if [[ -n "$merged_branches" ]]; then
        echo -e "${YELLOW}Merged branches to delete:${NC}"
        echo "$merged_branches"
        echo -e "${CYAN}Delete these branches? (y/n):${NC}"
        read -p "> " confirm

        if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
            show_command "git branch -d <branch>" "Delete merged branches safely"
            echo "$merged_branches" | xargs -n 1 git branch -d
            print_success "Cleaned up merged branches"
        else
            print_info "Skipped branch cleanup"
        fi
    else
        print_info "No merged branches to clean up"
    fi

    print_success "Start of day setup complete!"

    print_info "Final status after start of day operations:"
    show_git_status
}

# Daily Work Operations (Point 3)
daily_work() {
    while true; do
        print_header "DAILY WORK OPERATIONS"

        echo -e "${CYAN}Choose an operation:${NC}"
        echo ""
        echo -e "1. ${GREEN}Work on existing branch${NC} ${YELLOW}(switch to and update existing branch)${NC}"
        echo -e "2. ${GREEN}Create new branch${NC} ${YELLOW}(create new branch from master)${NC}"
        echo -e "3. ${GREEN}Commit and push current work${NC}"
        echo -e "4. ${GREEN}Update current branch with master${NC}"
        echo -e "5. ${GREEN}Uncommit recent changes${NC} ${YELLOW}(undo last commit)${NC}"
        echo -e "6. ${GREEN}Back to main menu${NC}"
        echo ""

        read -p "Enter your choice (1-6): " choice
        echo ""

        case $choice in
            1) switch_and_update_branch ;;
            2) create_new_branch ;;
            3) commit_and_push ;;
            4) update_with_master ;;
            5) uncommit_changes ;;
            6) return 0 ;;
            *) print_error "Invalid choice! Please enter 1-6." ;;
        esac

        pause
    done
}

# Switch to existing branch and update
switch_and_update_branch() {
    print_header "SWITCH & UPDATE BRANCH"

    print_info "Current status before switching:"
    show_git_status

    select_branch "switch to"
    if [[ $? -eq 0 && -n "$SELECTED_BRANCH" ]]; then
        local branch="$SELECTED_BRANCH"
        print_info "Switching to branch: $branch"

        if ! check_uncommitted_changes; then
            return 1
        fi

        show_command "git checkout $branch" "Switch to selected branch"
        if git checkout "$branch"; then
            print_success "Switched to branch: $branch"

            print_info "Updating branch with latest master..."
            show_command "git fetch origin" "Fetch latest changes from remote"
            git fetch origin

            # Check for unpushed commits
            local unpushed_count
            if git rev-parse @{u} >/dev/null 2>&1; then
                # Branch has upstream tracking
                unpushed_count=$(git rev-list --count @{u}..HEAD)
            else
                # Check against remote branch directly
                if git rev-parse "origin/$branch" >/dev/null 2>&1; then
                    unpushed_count=$(git rev-list --count "origin/$branch..HEAD")
                else
                    unpushed_count=0
                fi
            fi
            if [[ "$unpushed_count" -gt 0 ]]; then
                print_warning "You have $unpushed_count unpushed commit(s)!"
                print_warning "Updating with master may cause conflicts or lost work."
                echo ""
                echo -e "${YELLOW}Choose an option:${NC}"
                echo -e "1. ${GREEN}Push commits first${NC} ${YELLOW}(recommended)${NC}"
                echo -e "2. ${GREEN}Uncommit changes${NC} ${YELLOW}(undo recent commits)${NC}"
                echo -e "3. ${RED}Cancel operation${NC}"
                echo ""
                read -p "Enter your choice (1-3): " choice

                case $choice in
                    1)
                        print_info "Pushing commits to remote..."
                        show_command "git push origin $branch" "Push unpushed commits"
                        if git push origin "$branch"; then
                            print_success "Commits pushed successfully"
                            print_info "Git status after push:"
                            show_git_status
                        else
                            print_error "Failed to push commits. Cannot continue with update."
                            return 1
                        fi
                        ;;
                    2)
                        print_info "Redirecting to uncommit menu..."
                        uncommit_changes
                        print_info "Git status after uncommit:"
                        show_git_status
                        print_info "Please try updating with master again if needed."
                        return 0
                        ;;
                    3)
                        print_info "Update operation cancelled"
                        return 0
                        ;;
                    *)
                        print_error "Invalid choice. Operation cancelled."
                        return 1
                        ;;
                esac
            fi

            # Check for uncommitted changes before rebase
            if ! check_uncommitted_changes; then
                return 1
            fi

            show_command "git rebase origin/master" "Rebase current branch on master"
            if git rebase origin/master 2>/dev/null || git rebase origin/main 2>/dev/null; then
                print_success "Updated branch with master"
            else
                # Check if rebase is actually in progress
                if git rebase --show-current-patch &>/dev/null; then
                    print_warning "Rebase encountered conflicts. Please resolve manually."
                    print_info "After resolving conflicts, run: git rebase --continue"
                else
                    print_success "Rebase completed successfully (no conflicts to resolve)"
                fi
            fi
        else
            print_error "Failed to switch to branch: $branch"
        fi
    fi

    print_info "Final status after switching and updating:"
    show_git_status
}

# Create new branch from master
create_new_branch() {
    print_header "CREATE NEW BRANCH"

    print_info "Current status before creating new branch:"
    show_git_status

    print_info "First, updating master..."
    if ! check_uncommitted_changes; then
        return 1
    fi

    show_command "git checkout master" "Switch to master branch"
    git checkout master 2>/dev/null || git checkout main 2>/dev/null
    show_command "git pull origin master" "Pull latest changes from remote"
    git pull origin master 2>/dev/null || git pull origin main 2>/dev/null

    echo -e "${CYAN}Enter new branch name (e.g., feature/your-feature):${NC}"
    read -p "> " new_branch

    if [[ -n "$new_branch" ]]; then
        print_info "Creating and switching to new branch: $new_branch"

        show_command "git checkout -b $new_branch" "Create and switch to new branch"
        if git checkout -b "$new_branch"; then
            print_success "Created branch: $new_branch"

            print_info "Pushing branch to remote..."
            show_command "git push -u origin $new_branch" "Push new branch and set upstream"
            if git push -u origin "$new_branch"; then
                print_success "Branch pushed to remote with upstream set"
            else
                print_error "Failed to push branch to remote"
            fi
        else
            print_error "Failed to create branch: $new_branch"
        fi
    else
        print_error "Branch name cannot be empty!"
    fi

    print_info "Final status after creating new branch:"
    show_git_status
}

# Commit and push current work
commit_and_push() {
    print_header "COMMIT & PUSH WORK"

    local current_branch=$(git branch --show-current)
    print_info "Current branch: $current_branch"

    print_info "Current status before committing:"
    show_git_status

    # Check if there are changes
    if ! git diff --quiet || ! git diff --cached --quiet; then
        print_info "Changes detected. Showing status..."
        git status --short
        echo ""

        echo -e "${CYAN}Add all changes? (y/n):${NC}"
        read -p "> " add_all

        if [[ "$add_all" == "y" || "$add_all" == "Y" ]]; then
            show_command "git add ." "Stage all changes for commit"
            git add .
            print_success "Added all changes"
        fi

        echo -e "${CYAN}Enter commit message:${NC}"
        read -p "> " commit_msg

        if [[ -n "$commit_msg" ]]; then
            show_command "git commit -m \"$commit_msg\"" "Commit staged changes with message"
            if git commit -m "$commit_msg"; then
                print_success "Committed changes"

                print_info "Pushing to remote..."
                show_command "git push origin $current_branch" "Push commits to remote branch"
                if git push origin "$current_branch"; then
                    print_success "Pushed to remote"
                else
                    print_error "Failed to push to remote"
                fi
            else
                print_error "Failed to commit changes"
            fi
        else
            print_error "Commit message cannot be empty!"
        fi
    else
        print_info "No changes to commit"
    fi

    print_info "Final status after commit and push:"
    show_git_status
}

# Update current branch with master
update_with_master() {
    print_header "UPDATE WITH MASTER"

    local current_branch=$(git branch --show-current)
    print_info "Current branch: $current_branch"

    print_info "Current status before updating with master:"
    show_git_status

    if [[ "$current_branch" == "master" || "$current_branch" == "main" ]]; then
        print_info "Already on master/main branch. Pulling latest changes..."
        show_command "git pull origin $current_branch" "Pull latest changes from remote"
        git pull origin "$current_branch"
    else
        print_info "Fetching latest changes..."
        show_command "git fetch origin" "Fetch latest changes from remote"
        git fetch origin

        # Check for unpushed commits
        local current_branch=$(git branch --show-current)
        local unpushed_count
        if git rev-parse @{u} >/dev/null 2>&1; then
            # Branch has upstream tracking
            unpushed_count=$(git rev-list --count @{u}..HEAD)
        else
            # Check against remote branch directly
            if git rev-parse "origin/$current_branch" >/dev/null 2>&1; then
                unpushed_count=$(git rev-list --count "origin/$current_branch..HEAD")
            else
                unpushed_count=0
            fi
        fi
        if [[ "$unpushed_count" -gt 0 ]]; then
            print_warning "You have $unpushed_count unpushed commit(s)!"
            print_warning "Updating with master may cause conflicts or lost work."
            echo ""
            echo -e "${YELLOW}Choose an option:${NC}"
            echo -e "1. ${GREEN}Push commits first${NC} ${YELLOW}(recommended)${NC}"
            echo -e "2. ${GREEN}Uncommit changes${NC} ${YELLOW}(undo recent commits)${NC}"
            echo -e "3. ${RED}Cancel operation${NC}"
            echo ""
            read -p "Enter your choice (1-3): " choice

            case $choice in
                1)
                    print_info "Pushing commits to remote..."
                    show_command "git push origin $current_branch" "Push unpushed commits"
                    if git push origin "$current_branch"; then
                        print_success "Commits pushed successfully"
                        print_info "Git status after push:"
                        show_git_status
                    else
                        print_error "Failed to push commits. Cannot continue with update."
                        return 1
                    fi
                    ;;
                2)
                    print_info "Redirecting to uncommit menu..."
                    uncommit_changes
                    print_info "Git status after uncommit:"
                    show_git_status
                    print_info "Please try updating with master again if needed."
                    return 0
                    ;;
                3)
                    print_info "Update operation cancelled"
                    return 0
                    ;;
                *)
                    print_error "Invalid choice. Operation cancelled."
                    return 1
                    ;;
            esac
        fi

        # Check for uncommitted changes before rebase
        if ! check_uncommitted_changes; then
            return 1
        fi

        print_info "Rebasing with master..."
        show_command "git rebase origin/master" "Rebase current branch on master"
        if git rebase origin/master 2>/dev/null || git rebase origin/main 2>/dev/null; then
            print_success "Successfully rebased with master"
        else
            # Check if rebase is actually in progress
            if git rebase --show-current-patch &>/dev/null; then
                print_warning "Rebase encountered conflicts. Please resolve manually."
                print_info "After resolving conflicts, run: git rebase --continue"
            else
                print_success "Rebase completed successfully (no conflicts to resolve)"
            fi
        fi
    fi

    print_info "Final status after updating with master:"
    show_git_status
}

# Uncommit recent changes
uncommit_changes() {
    print_header "UNCOMMIT RECENT CHANGES"

    local current_branch=$(git branch --show-current)
    print_info "Current branch: $current_branch"

    print_info "Current status before uncommitting:"
    show_git_status

    print_info "Recent commits:"
    show_command "git log --oneline -5" "Show last 5 commits"
    git log --oneline -5
    echo ""

    echo -e "${CYAN}Choose uncommit method:${NC}"
    echo ""
    echo -e "1. ${GREEN}Soft reset${NC} ${YELLOW}(keep changes staged)${NC}"
    echo -e "2. ${GREEN}Mixed reset${NC} ${YELLOW}(keep changes unstaged)${NC}"
    echo -e "3. ${GREEN}Hard reset${NC} ${YELLOW}(discard changes completely)${NC}"
    echo -e "4. ${GREEN}Revert commit${NC} ${YELLOW}(create new commit that undoes changes)${NC}"
    echo -e "5. ${GREEN}Cancel${NC}"
    echo ""

    read -p "Enter your choice (1-5): " choice
    echo ""

    case $choice in
        1) uncommit_soft ;;
        2) uncommit_mixed ;;
        3) uncommit_hard ;;
        4) revert_commit ;;
        5) print_info "Uncommit cancelled" ;;
        *) print_error "Invalid choice! Please enter 1-5." ;;
    esac

    print_info "Final status after uncommit operation:"
    show_git_status
}

# Soft reset - keep changes staged
uncommit_soft() {
    print_info "Performing soft reset (keeping changes staged)..."
    show_command "git reset --soft HEAD~1" "Undo last commit but keep changes staged"

    echo -e "${YELLOW}Are you sure you want to undo the last commit? (y/n):${NC}"
    read -p "> " confirm

    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        if git reset --soft HEAD~1; then
            print_success "Successfully undid last commit (changes remain staged)"
        else
            print_error "Failed to undo commit"
        fi
    else
        print_info "Soft reset cancelled"
    fi
}

# Mixed reset - keep changes unstaged
uncommit_mixed() {
    print_info "Performing mixed reset (keeping changes unstaged)..."
    show_command "git reset HEAD~1" "Undo last commit and unstage changes"

    echo -e "${YELLOW}Are you sure you want to undo the last commit? (y/n):${NC}"
    read -p "> " confirm

    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        if git reset HEAD~1; then
            print_success "Successfully undid last commit (changes remain in working directory)"
        else
            print_error "Failed to undo commit"
        fi
    else
        print_info "Mixed reset cancelled"
    fi
}

# Hard reset - discard changes completely
uncommit_hard() {
    print_info "Performing hard reset (discarding changes completely)..."
    show_command "git reset --hard HEAD~1" "Undo last commit and discard all changes"

    echo -e "${RED}WARNING: This will permanently delete all changes from the last commit!${NC}"
    echo -e "${YELLOW}Are you absolutely sure? (y/n):${NC}"
    read -p "> " confirm

    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        if git reset --hard HEAD~1; then
            print_success "Successfully undid last commit (all changes discarded)"
        else
            print_error "Failed to undo commit"
        fi
    else
        print_info "Hard reset cancelled"
    fi
}

# Revert commit - create new commit that undoes changes
revert_commit() {
    print_info "Reverting commit (creating new commit that undoes changes)..."
    show_command "git revert HEAD" "Create new commit that undoes the last commit"

    echo -e "${YELLOW}Are you sure you want to revert the last commit? (y/n):${NC}"
    read -p "> " confirm

    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        if git revert HEAD --no-edit; then
            print_success "Successfully reverted last commit"
        else
            print_error "Failed to revert commit (may have conflicts)"
            print_info "If there are conflicts, resolve them and run: git revert --continue"
        fi
    else
        print_info "Revert cancelled"
    fi
}

# Branch management menu
branch_management() {
    while true; do
        print_header "BRANCH MANAGEMENT"

        echo -e "${CYAN}Choose an operation:${NC}"
        echo ""
        echo -e "1. ${GREEN}List all branches${NC}"
        echo -e "2. ${GREEN}Delete local branch${NC}"
        echo -e "3. ${GREEN}Delete remote branch${NC}"
        echo -e "4. ${GREEN}Rename current branch${NC}"
        echo -e "5. ${GREEN}Back to main menu${NC}"
        echo ""

        read -p "Enter your choice (1-5): " choice
        echo ""

        case $choice in
            1) list_all_branches ;;
            2) delete_local_branch ;;
            3) delete_remote_branch ;;
            4) rename_current_branch ;;
            5) return 0 ;;
            *) print_error "Invalid choice! Please enter 1-5." ;;
        esac

        pause
    done
}

# List all branches
list_all_branches() {
    print_header "ALL BRANCHES"

    print_info "Local branches:"
    git branch
    echo ""

    print_info "Remote branches:"
    git branch -r
    echo ""
}

# Delete local branch
delete_local_branch() {
    print_header "DELETE LOCAL BRANCH"

    print_info "Current status before deleting branch:"
    show_git_status

    select_branch "delete"
    if [[ $? -eq 0 && -n "$SELECTED_BRANCH" ]]; then
        local branch="$SELECTED_BRANCH"
        local current_branch=$(git branch --show-current)

        if [[ "$branch" == "$current_branch" ]]; then
            print_error "Cannot delete current branch! Switch to another branch first."
        else
            echo -e "${YELLOW}Are you sure you want to delete branch '$branch'? (y/n):${NC}"
            read -p "> " confirm

            if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                show_command "git branch -d $branch" "Delete branch safely (or force with -D)"
                if git branch -d "$branch" 2>/dev/null || git branch -D "$branch"; then
                    print_success "Deleted branch: $branch"
                else
                    print_error "Failed to delete branch: $branch"
                fi
            else
                print_info "Branch deletion cancelled"
            fi
        fi
    fi

    print_info "Final status after branch deletion:"
    show_git_status
}

# Delete remote branch
delete_remote_branch() {
    print_header "DELETE REMOTE BRANCH"

    print_info "Current status before deleting remote branch:"
    show_git_status

    echo -e "${YELLOW}Remote branches:${NC}"
    echo -e "${CYAN}==================${NC}"

    # Get remote branches and store in array
    local remote_branches_array=()
    local count=1

    while IFS= read -r branch; do
        # Remove remotes/origin/ prefix
        branch_name=$(echo "$branch" | sed 's/^[[:space:]]*origin\///g')
        remote_branches_array+=("$branch_name")
        echo -e "$count. $branch_name"
        ((count++))
    done < <(git branch -r | grep -v HEAD | grep -v "\->" | sed 's/^[[:space:]]*//')
    echo ""

    echo -e "${CYAN}Enter branch number, branch name, or 'q' to quit:${NC}"
    read -p "> " remote_branch_choice

    if [[ "$remote_branch_choice" == "q" ]]; then
        print_info "Remote branch deletion cancelled"
        return 0
    fi

    local remote_branch=""
    # Check if it's a number
    if [[ "$remote_branch_choice" =~ ^[0-9]+$ ]]; then
        # Convert to array index (subtract 1)
        local index=$((remote_branch_choice - 1))
        if [[ $index -ge 0 && $index -lt ${#remote_branches_array[@]} ]]; then
            remote_branch="${remote_branches_array[$index]}"
        else
            print_error "Invalid branch number! Please select a number between 1 and ${#remote_branches_array[@]}"
            return 1
        fi
    else
        # Check if branch exists by name
        if [[ " ${remote_branches_array[@]} " =~ " ${remote_branch_choice} " ]]; then
            remote_branch="$remote_branch_choice"
        else
            print_error "Branch '$remote_branch_choice' does not exist!"
            return 1
        fi
    fi

    if [[ -n "$remote_branch" ]]; then
        echo -e "${YELLOW}Are you sure you want to delete remote branch 'origin/$remote_branch'? (y/n):${NC}"
        read -p "> " confirm

        if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
            show_command "git push origin --delete $remote_branch" "Delete remote branch"
            if git push origin --delete "$remote_branch"; then
                print_success "Deleted remote branch: origin/$remote_branch"
            else
                print_error "Failed to delete remote branch: origin/$remote_branch"
            fi
        else
            print_info "Remote branch deletion cancelled"
        fi
    else
        print_error "Branch name cannot be empty!"
    fi

    print_info "Final status after remote branch deletion:"
    show_git_status
}

# Rename current branch
rename_current_branch() {
    print_header "RENAME CURRENT BRANCH"

    local current_branch=$(git branch --show-current)
    print_info "Current branch: $current_branch"

    print_info "Current status before renaming:"
    show_git_status

    echo -e "${CYAN}Enter new branch name:${NC}"
    read -p "> " new_name

    if [[ -n "$new_name" ]]; then
        show_command "git branch -m $new_name" "Rename current branch"
        if git branch -m "$new_name"; then
            print_success "Renamed branch to: $new_name"

            print_info "Updating remote..."
            show_command "git push origin -u $new_name" "Push renamed branch and set upstream"
            git push origin -u "$new_name"
            show_command "git push origin --delete $current_branch" "Delete old remote branch"
            git push origin --delete "$current_branch"
            print_success "Updated remote branch"
        else
            print_error "Failed to rename branch"
        fi
    else
        print_error "Branch name cannot be empty!"
    fi

    print_info "Final status after renaming:"
    show_git_status
}

# Main menu
main_menu() {
    print_header "GIT WORKFLOW MANAGER"
    
    # Show current working directory
    print_info "Current working directory: $(pwd)"
    
    # Show current Git user if configured
    local git_user=$(git config user.name 2>/dev/null)
    local git_email=$(git config user.email 2>/dev/null)
    if [[ -n "$git_user" && -n "$git_email" ]]; then
        print_info "Git user: $git_user <$git_email>"
    fi
    
    # Show remote provider if detectable
    local provider=$(detect_remote_provider 2>/dev/null)
    if [[ -n "$provider" && "$provider" != "unknown" ]]; then
        print_info "Remote provider: $(echo "$provider" | tr '[:lower:]' '[:upper:]')"
    fi
    echo ""

    echo -e "${CYAN}Choose an operation:${NC}"
    echo ""
    echo -e "1. ${GREEN}Start of Day Setup${NC} ${YELLOW}(Fetch, update master, cleanup)${NC}"
    echo -e "2. ${GREEN}Daily Work Operations${NC} ${YELLOW}(Branch work, commit, push)${NC}"
    echo -e "3. ${GREEN}Branch Management${NC} ${YELLOW}(List, delete, rename branches)${NC}"
    echo -e "4. ${GREEN}Commits Management${NC} ${YELLOW}(View, search, analyze commits)${NC}"
    echo -e "5. ${GREEN}Git Status & Info${NC} ${YELLOW}(Current status, log, diff)${NC}"
    echo -e "6. ${GREEN}GitHub Authentication${NC} ${YELLOW}(Setup GitHub CLI access)${NC}"
    echo -e "7. ${GREEN}GitLab Authentication${NC} ${YELLOW}(Setup GitLab SSH/PAT access)${NC}"
    echo -e "8. ${GREEN}Repository Management${NC} ${YELLOW}(Initialize, create, configure repos)${NC}"
    echo -e "9. ${GREEN}Git Statistics & Reports${NC} ${YELLOW}(Analysis, reports, logs)${NC}"
    echo -e "10. ${GREEN}Help${NC} ${YELLOW}(Show commands and explanations)${NC}"
    echo -e "11. ${GREEN}Change Working Path${NC} ${YELLOW}(Select different Git repository)${NC}"
    echo -e "12. ${RED}Exit${NC}"
    echo ""

    read -p "Enter your choice (1-12): " choice
    echo ""

    case $choice in
        1) start_of_day ;;
        2) daily_work ;;
        3) branch_management ;;
        4) commits_management ;;
        5) git_status_info ;;
        6) gh_authentication_menu ;;
        7) gitlab_authentication_menu ;;
        8) repository_management ;;
        9) git_statistics_menu ;;
        10) help_menu ;;
        11) change_working_path ;;
        12)
            print_info "Goodbye!"
            log_operation "INFO" "User exited Git Workflow Manager" "EXIT"
            exit 0
            ;;
        *)
            print_error "Invalid choice! Please enter 1-12."
            log_operation "WARNING" "Invalid menu choice: $choice" "MAIN_MENU"
            pause
            ;;
    esac
}

# Commits management menu
commits_management() {
    while true; do
        print_header "COMMITS MANAGEMENT"

        echo -e "${CYAN}Choose an operation:${NC}"
        echo ""
        echo -e "1. ${GREEN}View commits by branch${NC} ${YELLOW}(detailed commit history per branch)${NC}"
        echo -e "2. ${GREEN}Search commits${NC} ${YELLOW}(search by message, author, or file)${NC}"
        echo -e "3. ${GREEN}View commit details${NC} ${YELLOW}(detailed info for specific commit ID)${NC}"
        echo -e "4. ${GREEN}Compare commits${NC} ${YELLOW}(diff between two commits)${NC}"
        echo -e "5. ${GREEN}Cherry-pick commit${NC} ${YELLOW}(apply commit to current branch)${NC}"
        echo -e "6. ${GREEN}Revert commit${NC} ${YELLOW}(create commit that undoes changes)${NC}"
        echo -e "7. ${GREEN}Interactive rebase${NC} ${YELLOW}(edit commit history)${NC}"
        echo -e "8. ${GREEN}Commit statistics${NC} ${YELLOW}(author stats, file changes)${NC}"
        echo -e "9. ${GREEN}Blame analysis${NC} ${YELLOW}(who changed what in files)${NC}"
        echo -e "10. ${GREEN}Back to main menu${NC}"
        echo ""

        read -p "Enter your choice (1-10): " choice
        echo ""

        case $choice in
            1) view_commits_by_branch ;;
            2) search_commits ;;
            3) view_commit_details ;;
            4) compare_commits ;;
            5) cherry_pick_commit ;;
            6) revert_specific_commit ;;
            7) interactive_rebase ;;
            8) commit_statistics ;;
            9) blame_analysis ;;
            10) return 0 ;;
            *) print_error "Invalid choice! Please enter 1-10." ;;
        esac

        pause
    done
}

# View commits by branch
view_commits_by_branch() {
    print_header "VIEW COMMITS BY BRANCH"

    # Call select_branch and get result through global variable
    select_branch "view commits for"
    local select_result=$?

    if [[ $select_result -eq 0 && -n "$SELECTED_BRANCH" ]]; then
        local branch="$SELECTED_BRANCH"
        print_info "Commits for branch: $branch"

        echo -e "${CYAN}Choose display format:${NC}"
        echo ""
        echo -e "1. ${GREEN}Detailed view${NC} ${YELLOW}(full commit info)${NC}"
        echo -e "2. ${GREEN}One-line view${NC} ${YELLOW}(compact format)${NC}"
        echo -e "3. ${GREEN}Graph view${NC} ${YELLOW}(with branch visualization)${NC}"
        echo -e "4. ${GREEN}Statistics view${NC} ${YELLOW}(with file changes)${NC}"
        echo -e "5. ${GREEN}Cancel${NC}"
        echo ""

        read -p "Enter your choice (1-5): " format_choice
        echo ""

        case $format_choice in
            1)
                show_command "git log $branch --pretty=format:'%h - %an, %ar : %s' -10" "Show detailed commit history"
                git log "$branch" --pretty=format:'%C(yellow)%h%C(reset) - %C(green)%an%C(reset), %C(blue)%ar%C(reset) : %s' -10
                ;;
            2)
                show_command "git log $branch --oneline -20" "Show compact commit history"
                git log "$branch" --oneline -20
                ;;
            3)
                show_command "git log $branch --graph --oneline -15" "Show commit history with graph"
                git log "$branch" --graph --oneline -15
                ;;
            4)
                show_command "git log $branch --stat -5" "Show commit history with file statistics"
                git log "$branch" --stat -5
                ;;
            5)
                print_info "View cancelled"
                return 0
                ;;
            *)
                print_error "Invalid choice!"
                ;;
        esac
    else
        print_info "Branch selection cancelled or failed"
    fi
}

# Search commits
search_commits() {
    print_header "SEARCH COMMITS"

    echo -e "${CYAN}Choose search type:${NC}"
    echo ""
    echo -e "1. ${GREEN}Search by commit message${NC}"
    echo -e "2. ${GREEN}Search by author${NC}"
    echo -e "3. ${GREEN}Search by file name${NC}"
    echo -e "4. ${GREEN}Search by date range${NC}"
    echo -e "5. ${GREEN}Search by content${NC}"
    echo -e "6. ${GREEN}Cancel${NC}"
    echo ""

    read -p "Enter your choice (1-6): " search_choice
    echo ""

    case $search_choice in
        1) search_by_message ;;
        2) search_by_author ;;
        3) search_by_file ;;
        4) search_by_date ;;
        5) search_by_content ;;
        6) print_info "Search cancelled" ;;
        *) print_error "Invalid choice!" ;;
    esac
}

# Search by commit message
search_by_message() {
    echo -e "${CYAN}Enter search term for commit message:${NC}"
    read -p "> " search_term

    if [[ -n "$search_term" ]]; then
        print_info "Searching commits with message containing: $search_term"
        show_command "git log --grep='$search_term' --oneline" "Search commits by message"
        git log --grep="$search_term" --oneline
    else
        print_error "Search term cannot be empty!"
    fi
}

# Search by author
search_by_author() {
    echo -e "${CYAN}Enter author name or email:${NC}"
    read -p "> " author

    if [[ -n "$author" ]]; then
        print_info "Searching commits by author: $author"
        show_command "git log --author='$author' --oneline" "Search commits by author"
        git log --author="$author" --oneline
    else
        print_error "Author cannot be empty!"
    fi
}

# Search by file name
search_by_file() {
    echo -e "${CYAN}Enter file name or path:${NC}"
    read -p "> " filename

    if [[ -n "$filename" ]]; then
        print_info "Searching commits that modified file: $filename"
        show_command "git log --oneline -- '$filename'" "Search commits by file"
        git log --oneline -- "$filename"
    else
        print_error "Filename cannot be empty!"
    fi
}

# Search by date range
search_by_date() {
    echo -e "${CYAN}Enter start date (YYYY-MM-DD):${NC}"
    read -p "> " start_date
    echo -e "${CYAN}Enter end date (YYYY-MM-DD):${NC}"
    read -p "> " end_date

    if [[ -n "$start_date" && -n "$end_date" ]]; then
        print_info "Searching commits between $start_date and $end_date"
        show_command "git log --since='$start_date' --until='$end_date' --oneline" "Search commits by date range"
        git log --since="$start_date" --until="$end_date" --oneline
    else
        print_error "Both dates must be provided!"
    fi
}

# Search by content
search_by_content() {
    echo -e "${CYAN}Enter content to search for:${NC}"
    read -p "> " content

    if [[ -n "$content" ]]; then
        print_info "Searching commits that added or removed: $content"
        show_command "git log -S'$content' --oneline" "Search commits by content changes"
        git log -S"$content" --oneline
    else
        print_error "Content cannot be empty!"
    fi
}

# View commit details
view_commit_details() {
    print_header "VIEW COMMIT DETAILS"

    print_info "Recent commits for reference:"
    show_command "git log --oneline -10" "Show recent commits"
    git log --oneline -10
    echo ""

    echo -e "${CYAN}Enter commit ID (hash):${NC}"
    read -p "> " commit_id

    if [[ -n "$commit_id" ]]; then
        print_info "Detailed information for commit: $commit_id"

        echo -e "${CYAN}Choose detail level:${NC}"
        echo ""
        echo -e "1. ${GREEN}Full details${NC} ${YELLOW}(complete commit info)${NC}"
        echo -e "2. ${GREEN}Files changed${NC} ${YELLOW}(with statistics)${NC}"
        echo -e "3. ${GREEN}Diff view${NC} ${YELLOW}(actual changes)${NC}"
        echo -e "4. ${GREEN}All info${NC} ${YELLOW}(everything)${NC}"
        echo -e "5. ${GREEN}Cancel${NC}"
        echo ""

        read -p "Enter your choice (1-5): " detail_choice
        echo ""

        case $detail_choice in
            1)
                show_command "git show --stat $commit_id" "Show commit details with file stats"
                git show --stat "$commit_id"
                ;;
            2)
                show_command "git show --name-status $commit_id" "Show files changed in commit"
                git show --name-status "$commit_id"
                ;;
            3)
                show_command "git show $commit_id" "Show commit with full diff"
                git show "$commit_id"
                ;;
            4)
                show_command "git show --pretty=fuller --stat $commit_id" "Show all commit information"
                git show --pretty=fuller --stat "$commit_id"
                ;;
            5)
                print_info "View cancelled"
                return 0
                ;;
            *)
                print_error "Invalid choice!"
                ;;
        esac
    else
        print_error "Commit ID cannot be empty!"
    fi

}

# Compare commits
compare_commits() {
    print_header "COMPARE COMMITS"

    print_info "Recent commits for reference:"
    show_command "git log --oneline -10" "Show recent commits"
    git log --oneline -10
    echo ""

    echo -e "${CYAN}Enter first commit ID:${NC}"
    read -p "> " commit1
    echo -e "${CYAN}Enter second commit ID:${NC}"
    read -p "> " commit2

    if [[ -n "$commit1" && -n "$commit2" ]]; then
        print_info "Comparing commits: $commit1 vs $commit2"

        echo -e "${CYAN}Choose comparison type:${NC}"
        echo ""
        echo -e "1. ${GREEN}Files changed${NC} ${YELLOW}(what files differ)${NC}"
        echo -e "2. ${GREEN}Statistics${NC} ${YELLOW}(lines added/removed)${NC}"
        echo -e "3. ${GREEN}Full diff${NC} ${YELLOW}(actual differences)${NC}"
        echo -e "4. ${GREEN}Cancel${NC}"
        echo ""

        read -p "Enter your choice (1-4): " comp_choice
        echo ""

        case $comp_choice in
            1)
                show_command "git diff --name-status $commit1 $commit2" "Show files that differ"
                git diff --name-status "$commit1" "$commit2"
                ;;
            2)
                show_command "git diff --stat $commit1 $commit2" "Show diff statistics"
                git diff --stat "$commit1" "$commit2"
                ;;
            3)
                show_command "git diff $commit1 $commit2" "Show full diff"
                git diff "$commit1" "$commit2"
                ;;
            4)
                print_info "Comparison cancelled"
                return 0
                ;;
            *)
                print_error "Invalid choice!"
                ;;
        esac
    else
        print_error "Both commit IDs must be provided!"
    fi

}

# Cherry-pick commit
cherry_pick_commit() {
    print_header "CHERRY-PICK COMMIT"

    local current_branch=$(git branch --show-current)
    print_info "Current branch: $current_branch"

    print_info "Available branches:"
    echo -e "${CYAN}==================${NC}"

    # Get all branches and store in array
    local branches_array=()
    local count=1

    while IFS= read -r branch; do
        # Remove leading spaces, asterisk, and remote prefix
        branch_name=$(echo "$branch" | sed 's/^[* ]*//g' | sed 's/remotes\/origin\///g')

        # Skip if already in array (avoid duplicates)
        if [[ ! " ${branches_array[@]} " =~ " ${branch_name} " ]]; then
            branches_array+=("$branch_name")
            if [[ "$branch_name" == "$current_branch" ]]; then
                echo -e "${GREEN}$count. $branch_name ${WHITE}(current)${NC}"
            else
                echo -e "$count. $branch_name"
            fi
            ((count++))
        fi
    done < <(git branch -a | grep -v HEAD)
    echo ""

    echo -e "${CYAN}Enter source branch number, name, or 'q' to quit:${NC}"
    read -p "> " source_branch_choice

    if [[ "$source_branch_choice" == "q" ]]; then
        print_info "Cherry-pick cancelled"
        return 0
    fi

    local source_branch=""
    # Check if it's a number
    if [[ "$source_branch_choice" =~ ^[0-9]+$ ]]; then
        # Convert to array index (subtract 1)
        local index=$((source_branch_choice - 1))
        if [[ $index -ge 0 && $index -lt ${#branches_array[@]} ]]; then
            source_branch="${branches_array[$index]}"
        else
            print_error "Invalid branch number! Please select a number between 1 and ${#branches_array[@]}"
            return 1
        fi
    else
        # Check if branch exists by name
        if [[ " ${branches_array[@]} " =~ " ${source_branch_choice} " ]]; then
            source_branch="$source_branch_choice"
        else
            print_error "Branch '$source_branch_choice' does not exist!"
            return 1
        fi
    fi

    if [[ -n "$source_branch" ]]; then
        print_info "Recent commits from $source_branch:"
        show_command "git log $source_branch --oneline -10" "Show commits from source branch"
        git log "$source_branch" --oneline -10
        echo ""

        echo -e "${CYAN}Enter commit ID to cherry-pick:${NC}"
        read -p "> " commit_id

        if [[ -n "$commit_id" ]]; then
            print_info "Cherry-picking commit $commit_id to $current_branch"
            show_command "git cherry-pick $commit_id" "Apply commit to current branch"

            echo -e "${YELLOW}Are you sure you want to cherry-pick this commit? (y/n):${NC}"
            read -p "> " confirm

            if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                if git cherry-pick "$commit_id"; then
                    print_success "Successfully cherry-picked commit"
                else
                    print_error "Cherry-pick failed (may have conflicts)"
                    print_info "Resolve conflicts and run: git cherry-pick --continue"
                fi
            else
                print_info "Cherry-pick cancelled"
            fi
        else
            print_error "Commit ID cannot be empty!"
        fi
    else
        print_error "Source branch cannot be empty!"
    fi

}

# Revert specific commit
revert_specific_commit() {
    print_header "REVERT SPECIFIC COMMIT"

    print_info "Recent commits for reference:"
    show_command "git log --oneline -10" "Show recent commits"
    git log --oneline -10
    echo ""

    echo -e "${CYAN}Enter commit ID to revert:${NC}"
    read -p "> " commit_id

    if [[ -n "$commit_id" ]]; then
        print_info "Reverting commit: $commit_id"
        show_command "git revert $commit_id" "Create commit that undoes the specified commit"

        echo -e "${YELLOW}Are you sure you want to revert this commit? (y/n):${NC}"
        read -p "> " confirm

        if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
            if git revert "$commit_id" --no-edit; then
                print_success "Successfully reverted commit"
            else
                print_error "Revert failed (may have conflicts)"
                print_info "Resolve conflicts and run: git revert --continue"
            fi
        else
            print_info "Revert cancelled"
        fi
    else
        print_error "Commit ID cannot be empty!"
    fi

}

# Interactive rebase
interactive_rebase() {
    print_header "INTERACTIVE REBASE"

    print_warning "Interactive rebase allows you to edit commit history"
    print_warning "This is a powerful but potentially dangerous operation"
    echo ""

    print_info "Recent commits for reference:"
    show_command "git log --oneline -10" "Show recent commits"
    git log --oneline -10
    echo ""

    echo -e "${CYAN}Enter number of commits to rebase (from HEAD):${NC}"
    read -p "> " num_commits

    if [[ -n "$num_commits" && "$num_commits" =~ ^[0-9]+$ ]]; then
        # Check for uncommitted changes before interactive rebase
        if ! check_uncommitted_changes; then
            return 1
        fi

        print_info "Starting interactive rebase for last $num_commits commits"
        show_command "git rebase -i HEAD~$num_commits" "Start interactive rebase"

        echo -e "${YELLOW}This will open an editor to modify commit history. Continue? (y/n):${NC}"
        read -p "> " confirm

        if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
            print_info "Opening interactive rebase editor..."
            print_info "Use 'pick', 'reword', 'edit', 'squash', 'fixup', or 'drop' for each commit"
            git rebase -i HEAD~"$num_commits"
        else
            print_info "Interactive rebase cancelled"
        fi
    else
        print_error "Please enter a valid number!"
    fi

}

# Commit statistics
commit_statistics() {
    print_header "COMMIT STATISTICS"

    echo -e "${CYAN}Choose statistics type:${NC}"
    echo ""
    echo -e "1. ${GREEN}Author statistics${NC} ${YELLOW}(commits per author)${NC}"
    echo -e "2. ${GREEN}File change statistics${NC} ${YELLOW}(most modified files)${NC}"
    echo -e "3. ${GREEN}Commit frequency${NC} ${YELLOW}(commits over time)${NC}"
    echo -e "4. ${GREEN}Code contribution${NC} ${YELLOW}(lines added/removed by author)${NC}"
    echo -e "5. ${GREEN}Branch statistics${NC} ${YELLOW}(commits per branch)${NC}"
    echo -e "6. ${GREEN}Cancel${NC}"
    echo ""

    read -p "Enter your choice (1-6): " stats_choice
    echo ""

    case $stats_choice in
        1)
            print_info "Author commit statistics:"
            show_command "git shortlog -sn" "Show commit count by author"
            git shortlog -sn
            ;;
        2)
            print_info "Most modified files:"
            show_command "git log --pretty=format: --name-only | sort | uniq -c | sort -rg | head -10" "Show most modified files"
            git log --pretty=format: --name-only | sort | uniq -c | sort -rg | head -10
            ;;
        3)
            print_info "Commit frequency (last 30 days):"
            show_command "git log --since='30 days ago' --pretty=format:'%ad' --date=short | sort | uniq -c" "Show commits per day"
            git log --since='30 days ago' --pretty=format:'%ad' --date=short | sort | uniq -c
            ;;
        4)
            print_info "Code contribution by author:"
            show_command "git log --pretty=format:'%an' --numstat | awk '{if(NF==3) {adds[author]+=$1; dels[author]+=$2}} NF==1 {author=$0} END {for(a in adds) print a, adds[a], dels[a]}'" "Show lines added/removed by author"
            git log --pretty=format:'%an' --numstat | awk '{if(NF==3) {adds[author]+=$1; dels[author]+=$2}} NF==1 {author=$0} END {for(a in adds) print a, "+" adds[a], "-" dels[a]}'
            ;;
        5)
            print_info "Commits per branch:"
            show_command "git for-each-ref --format='%(refname:short) %(committerdate)' refs/heads | sort -k2" "Show branch statistics"
            git for-each-ref --format='%(refname:short) %(committerdate)' refs/heads | sort -k2
            ;;
        6)
            print_info "Statistics cancelled"
            ;;
        *)
            print_error "Invalid choice!"
            ;;
    esac

}

# Blame analysis
blame_analysis() {
    print_header "BLAME ANALYSIS"

    echo -e "${CYAN}Enter file path to analyze:${NC}"
    read -p "> " file_path

    if [[ -n "$file_path" ]]; then
        if [[ -f "$file_path" ]]; then
            print_info "Blame analysis for file: $file_path"

            echo -e "${CYAN}Choose analysis type:${NC}"
            echo ""
            echo -e "1. ${GREEN}Full blame${NC} ${YELLOW}(who wrote each line)${NC}"
            echo -e "2. ${GREEN}Line range${NC} ${YELLOW}(specific lines only)${NC}"
            echo -e "3. ${GREEN}Summary${NC} ${YELLOW}(contribution summary)${NC}"
            echo -e "4. ${GREEN}Cancel${NC}"
            echo ""

            read -p "Enter your choice (1-4): " blame_choice
            echo ""

            case $blame_choice in
                1)
                    show_command "git blame $file_path" "Show who wrote each line"
                    git blame "$file_path"
                    ;;
                2)
                    echo -e "${CYAN}Enter start line:${NC}"
                    read -p "> " start_line
                    echo -e "${CYAN}Enter end line:${NC}"
                    read -p "> " end_line

                    if [[ -n "$start_line" && -n "$end_line" ]]; then
                        show_command "git blame -L$start_line,$end_line $file_path" "Show blame for specific lines"
                        git blame -L"$start_line","$end_line" "$file_path"
                    else
                        print_error "Both line numbers must be provided!"
                    fi
                    ;;
                3)
                    show_command "git blame $file_path | cut -d'(' -f2 | cut -d' ' -f1 | sort | uniq -c | sort -rn" "Show contribution summary"
                    git blame "$file_path" | cut -d'(' -f2 | cut -d' ' -f1 | sort | uniq -c | sort -rn
                    ;;
                4)
                    print_info "Blame analysis cancelled"
                    ;;
                *)
                    print_error "Invalid choice!"
                    ;;
            esac
        else
            print_error "File not found: $file_path"
        fi
    else
        print_error "File path cannot be empty!"
    fi

}

# Help menu with command explanations
help_menu() {
    while true; do
        print_header "HELP - COMMAND EXPLANATIONS"

        echo -e "${CYAN}Choose a section to learn about:${NC}"
        echo ""
        echo -e "1. ${GREEN}Start of Day Setup Commands${NC}"
        echo -e "2. ${GREEN}Daily Work Operations Commands${NC}"
        echo -e "3. ${GREEN}Branch Management Commands${NC}"
        echo -e "4. ${GREEN}Git Workflow Strategy${NC}"
        echo -e "5. ${GREEN}Back to main menu${NC}"
        echo ""

        read -p "Enter your choice (1-5): " choice
        echo ""

        case $choice in
            1) help_start_of_day ;;
            2) help_daily_work ;;
            3) help_branch_management ;;
            4) help_workflow_strategy ;;
            5) return 0 ;;
            *) print_error "Invalid choice! Please enter 1-5." ;;
        esac

        pause
    done
}

# Help for start of day commands
help_start_of_day() {
    print_header "START OF DAY COMMANDS EXPLANATION"

    echo -e "${YELLOW}This section runs the following commands in order:${NC}"
    echo ""

    echo -e "${CYAN}1. git status --short --branch${NC}"
    echo -e "   ${WHITE}Purpose:${NC} Shows current branch and file status before starting"
    echo -e "   ${WHITE}Why:${NC} Gives you visibility into current state"
    echo ""

    echo -e "${CYAN}2. git checkout master/main${NC}"
    echo -e "   ${WHITE}Purpose:${NC} Switches to the main branch"
    echo -e "   ${WHITE}Why:${NC} Ensures you're on the primary branch for updates"
    echo ""

    echo -e "${CYAN}4. git pull origin master/main${NC}"
    echo -e "   ${WHITE}Purpose:${NC} Updates main branch with latest remote changes"
    echo -e "   ${WHITE}Why:${NC} Ensures your main branch is up to date"
    echo ""

    echo -e "${CYAN}5. git branch --merged${NC}"
    echo -e "   ${WHITE}Purpose:${NC} Lists branches that have been merged into current branch"
    echo -e "   ${WHITE}Why:${NC} Identifies branches safe to delete"
    echo ""

    echo -e "${CYAN}3. git pull origin master${NC}"
    echo -e "   ${WHITE}Purpose:${NC} Updates master branch with latest changes"
    echo -e "   ${WHITE}Why:${NC} Ensures you have the most recent code"
    echo ""

    echo -e "${CYAN}4. git branch -d <branch>${NC}"
    echo -e "   ${WHITE}Purpose:${NC} Safely deletes merged branches"
    echo -e "   ${WHITE}Why:${NC} Cleans up old feature branches to reduce clutter"
    echo -e "   ${WHITE}-d flag:${NC} Only deletes if branch is fully merged (safe)"
    echo ""

    echo -e "${CYAN}5. git status --short --branch${NC}"
    echo -e "   ${WHITE}Purpose:${NC} Shows final state after cleanup"
    echo -e "   ${WHITE}Why:${NC} Confirms all operations completed successfully"
    echo ""

}

# Help for daily work commands
help_daily_work() {
    print_header "DAILY WORK COMMANDS EXPLANATION"

    echo -e "${YELLOW}Work on existing branch (Option 1):${NC}"
    echo -e "${CYAN}git status --short --branch${NC} - Show current status"
    echo -e "${CYAN}git checkout <branch>${NC} - Switch to specified branch"
    echo -e "${CYAN}git fetch origin${NC} - Get latest remote changes"
    echo -e "${CYAN}git rebase origin/master${NC} - Update branch with master changes"
    echo -e "${WHITE}Why rebase:${NC} Keeps linear history, avoids merge commits"
    echo -e "${WHITE}When to use:${NC} When continuing work on existing feature branch"
    echo ""

    echo -e "${YELLOW}Create new branch (Option 2):${NC}"
    echo -e "${CYAN}git status --short --branch${NC} - Show current status"
    echo -e "${CYAN}git checkout master${NC} - Switch to master first"
    echo -e "${CYAN}git pull origin master${NC} - Update master"
    echo -e "${CYAN}git checkout -b <new-branch>${NC} - Create and switch to new branch"
    echo -e "${CYAN}git push -u origin <new-branch>${NC} - Push and set upstream"
    echo -e "${WHITE}-u flag:${NC} Sets upstream tracking for easy future pushes"
    echo -e "${WHITE}When to use:${NC} When starting a new feature or task"
    echo ""

    echo -e "${YELLOW}Commit and push current work (Option 3):${NC}"
    echo -e "${CYAN}git status --short${NC} - Show current changes"
    echo -e "${CYAN}git add .${NC} - Stage all changes"
    echo -e "${CYAN}git commit -m \"message\"${NC} - Commit with message"
    echo -e "${CYAN}git push origin <branch>${NC} - Push to remote"
    echo -e "${WHITE}When to use:${NC} When ready to save and share your work"
    echo ""

    echo -e "${YELLOW}Update current branch with master (Option 4):${NC}"
    echo -e "${CYAN}git fetch origin${NC} - Get latest changes"
    echo -e "${CYAN}git rebase origin/master${NC} - Rebase on master"
    echo -e "${WHITE}Why:${NC} Keeps your branch updated with team changes"
    echo -e "${WHITE}When to use:${NC} Before committing or when master has new changes"
    echo ""

}

# Help for branch management commands
help_branch_management() {
    print_header "BRANCH MANAGEMENT COMMANDS EXPLANATION"

    echo -e "${YELLOW}List branches:${NC}"
    echo -e "${CYAN}git branch${NC} - List local branches"
    echo -e "${CYAN}git branch -r${NC} - List remote branches"
    echo -e "${CYAN}git branch -a${NC} - List all branches (local + remote)"
    echo ""

    echo -e "${YELLOW}Delete local branch:${NC}"
    echo -e "${CYAN}git branch -d <branch>${NC} - Safe delete (only if merged)"
    echo -e "${CYAN}git branch -D <branch>${NC} - Force delete (even if not merged)"
    echo -e "${WHITE}Tool uses -d first, then -D if needed${NC}"
    echo ""

    echo -e "${YELLOW}Delete remote branch:${NC}"
    echo -e "${CYAN}git push origin --delete <branch>${NC} - Delete branch on remote"
    echo -e "${WHITE}Warning:${NC} This is permanent and affects all team members"
    echo ""

    echo -e "${YELLOW}Rename branch:${NC}"
    echo -e "${CYAN}git branch -m <new-name>${NC} - Rename current branch"
    echo -e "${CYAN}git push origin -u <new-name>${NC} - Push renamed branch"
    echo -e "${CYAN}git push origin --delete <old-name>${NC} - Delete old remote branch"
    echo ""

}

# Help for workflow strategy
help_workflow_strategy() {
    print_header "GIT WORKFLOW STRATEGY EXPLANATION"

    echo -e "${YELLOW}Why this workflow prevents Git issues:${NC}"
    echo ""

    echo -e "${CYAN}1. Always fetch before work${NC}"
    echo -e "   ${WHITE}Prevents:${NC} Working with stale information"
    echo -e "   ${WHITE}Ensures:${NC} You see latest remote changes"
    echo ""

    echo -e "${CYAN}2. Use rebase instead of merge${NC}"
    echo -e "   ${WHITE}Prevents:${NC} Messy commit history with merge commits"
    echo -e "   ${WHITE}Ensures:${NC} Clean, linear history"
    echo ""

    echo -e "${CYAN}3. Always branch from updated master${NC}"
    echo -e "   ${WHITE}Prevents:${NC} Branching from outdated code"
    echo -e "   ${WHITE}Ensures:${NC} New features start from latest base"
    echo ""

    echo -e "${CYAN}4. Regular status checks${NC}"
    echo -e "   ${WHITE}Prevents:${NC} Surprises about uncommitted changes"
    echo -e "   ${WHITE}Ensures:${NC} Visibility into current state"
    echo ""

    echo -e "${CYAN}5. Clean up merged branches${NC}"
    echo -e "   ${WHITE}Prevents:${NC} Branch clutter and confusion"
    echo -e "   ${WHITE}Ensures:${NC} Only active branches remain"
    echo ""

    echo -e "${CYAN}6. Use --force-with-lease instead of --force${NC}"
    echo -e "   ${WHITE}Prevents:${NC} Overwriting others' work"
    echo -e "   ${WHITE}Ensures:${NC} Safety when force-pushing"
    echo ""

    echo -e "${YELLOW}This workflow eliminates:${NC}"
    echo -e "• Merge conflicts from outdated branches"
    echo -e "• 'Your branch has diverged' errors"
    echo -e "• Accidentally overwriting others' work"
    echo -e "• Messy commit history"
    echo -e "• Branch management confusion"
    echo ""

}

# Git status and info
git_status_info() {
    while true; do
        print_header "GIT STATUS & INFO"

        echo -e "${CYAN}Choose an operation:${NC}"
        echo ""
        echo -e "1. ${GREEN}Show current status${NC}"
        echo -e "2. ${GREEN}Show recent commits${NC}"
        echo -e "3. ${GREEN}Show current diff${NC}"
        echo -e "4. ${GREEN}Show remote info${NC}"
        echo -e "5. ${GREEN}Back to main menu${NC}"
        echo ""

        read -p "Enter your choice (1-5): " choice
        echo ""

        case $choice in
            1)
                print_info "Current Git status:"
                show_command "git status" "Show working tree status"
                git status
                ;;
            2)
                print_info "Recent commits:"
                show_command "git log --oneline -10" "Show recent commits in one line format"
                git log --oneline -10
                ;;
            3)
                print_info "Current diff:"
                show_command "git diff" "Show unstaged changes"
                git diff
                ;;
            4)
                print_info "Remote information:"
                show_command "git remote -v" "Show remote repositories"
                git remote -v
                ;;
            5) return 0 ;;
            *) print_error "Invalid choice! Please enter 1-5." ;;
        esac

        pause
    done
}

# Saved paths file
SAVED_PATHS_FILE="$HOME/.git_workflow_saved_paths"

# Function to validate if path exists and contains git repository
validate_git_path() {
    local path="$1"
    
    # Check if path exists
    if [[ ! -d "$path" ]]; then
        print_error "Path does not exist: $path"
        return 1
    fi
    
    print_success "Path exists: $path"
    
    # Check if path contains .git directory
    if [[ ! -d "$path/.git" ]]; then
        print_error "No .git repository found in: $path"
        print_info "This directory is not a Git repository"
        return 1
    fi
    
    print_success "Git repository found in: $path"
    return 0
}

# Function to select working path
select_working_path() {
    print_header "SELECT WORKING PATH"
    
    echo -e "${CYAN}Choose an option:${NC}"
    echo ""
    echo -e "1. ${GREEN}Enter custom path${NC}"
    echo -e "2. ${GREEN}Use current directory${NC} ${YELLOW}($(pwd))${NC}"
    echo -e "3. ${GREEN}Select from saved paths${NC}"
    echo -e "4. ${GREEN}Manage saved paths${NC}"
    echo ""
    
    read -p "Enter your choice (1-4): " path_choice
    echo ""
    
    case $path_choice in
        1)
            echo -e "${CYAN}Enter the full path to your Git repository:${NC}"
            read -p "> " custom_path
            
            if [[ -n "$custom_path" ]]; then
                # Expand tilde to home directory
                custom_path="${custom_path/#\~/$HOME}"
                
                if validate_git_path "$custom_path"; then
                    cd "$custom_path" || return 1
                    print_success "Changed to working directory: $(pwd)"
                    
                    # Ask if user wants to save this path
                    echo -e "${CYAN}Save this path for future use? (y/n):${NC}"
                    read -p "> " save_choice
                    if [[ "$save_choice" == "y" || "$save_choice" == "Y" ]]; then
                        save_path "$custom_path"
                    fi
                    return 0
                else
                    return 1
                fi
            else
                print_error "Path cannot be empty!"
                return 1
            fi
            ;;
        2)
            if validate_git_path "$(pwd)"; then
                print_success "Using current directory: $(pwd)"
                return 0
            else
                return 1
            fi
            ;;
        3)
            select_from_saved_paths
            return $?
            ;;
        4)
            manage_saved_paths
            # After managing paths, return to path selection
            select_working_path
            return $?
            ;;
        *)
            print_error "Invalid choice! Please enter 1-4."
            return 1
            ;;
    esac
}

# Function to save a path
save_path() {
    local path="$1"
    local description=""
    
    echo -e "${CYAN}Enter a description for this path (optional):${NC}"
    read -p "> " description
    
    # Create saved paths file if it doesn't exist
    touch "$SAVED_PATHS_FILE"
    
    # Check if path already exists
    if grep -q "^$path|" "$SAVED_PATHS_FILE" 2>/dev/null; then
        print_warning "Path already saved: $path"
        return 0
    fi
    
    # Save path with description and timestamp
    echo "$path|${description:-No description}|$(date '+%Y-%m-%d %H:%M:%S')" >> "$SAVED_PATHS_FILE"
    print_success "Path saved: $path"
}

# Function to select from saved paths
select_from_saved_paths() {
    if [[ ! -f "$SAVED_PATHS_FILE" ]] || [[ ! -s "$SAVED_PATHS_FILE" ]]; then
        print_warning "No saved paths found"
        return 1
    fi
    
    print_header "SAVED PATHS"
    
    local paths_array=()
    local count=1
    
    echo -e "${PURPLE}Available saved paths:${NC}"
    echo -e "${CYAN}=====================${NC}"
    
    while IFS='|' read -r path description timestamp; do
        paths_array+=("$path")
        echo -e "${GREEN}$count.${NC} $path"
        echo -e "   ${YELLOW}Description:${NC} $description"
        echo -e "   ${BLUE}Saved:${NC} $timestamp"
        echo ""
        ((count++))
    done < "$SAVED_PATHS_FILE"
    
    if [[ ${#paths_array[@]} -eq 0 ]]; then
        print_warning "No saved paths found"
        return 1
    fi
    
    echo -e "${CYAN}Enter path number or 'q' to quit:${NC}"
    read -p "> " choice
    
    if [[ "$choice" == "q" ]]; then
        return 1
    fi
    
    if [[ "$choice" =~ ^[0-9]+$ ]]; then
        local index=$((choice - 1))
        if [[ $index -ge 0 && $index -lt ${#paths_array[@]} ]]; then
            local selected_path="${paths_array[$index]}"
            if validate_git_path "$selected_path"; then
                cd "$selected_path" || return 1
                print_success "Changed to working directory: $(pwd)"
                return 0
            else
                return 1
            fi
        else
            print_error "Invalid selection! Please enter a number between 1 and ${#paths_array[@]}"
            return 1
        fi
    else
        print_error "Invalid input! Please enter a number or 'q'"
        return 1
    fi
}

# Function to manage saved paths
manage_saved_paths() {
    while true; do
        print_header "MANAGE SAVED PATHS"
        
        echo -e "${CYAN}Choose an operation:${NC}"
        echo ""
        echo -e "1. ${GREEN}List saved paths${NC}"
        echo -e "2. ${GREEN}List paths with details (ls -lha)${NC}"
        echo -e "3. ${GREEN}Edit saved paths${NC}"
        echo -e "4. ${GREEN}Delete a saved path${NC}"
        echo -e "5. ${GREEN}Back to path selection${NC}"
        echo ""
        
        read -p "Enter your choice (1-5): " choice
        echo ""
        
        case $choice in
            1) list_saved_paths ;;
            2) list_paths_details ;;
            3) edit_saved_paths ;;
            4) delete_saved_path ;;
            5) return 0 ;;
            *) print_error "Invalid choice! Please enter 1-5." ;;
        esac
        
        pause
    done
}

# Function to list saved paths
list_saved_paths() {
    print_header "SAVED PATHS LIST"
    
    if [[ ! -f "$SAVED_PATHS_FILE" ]] || [[ ! -s "$SAVED_PATHS_FILE" ]]; then
        print_warning "No saved paths found"
        return 0
    fi
    
    local count=1
    while IFS='|' read -r path description timestamp; do
        echo -e "${GREEN}$count.${NC} $path"
        echo -e "   ${YELLOW}Description:${NC} $description"
        echo -e "   ${BLUE}Saved:${NC} $timestamp"
        echo ""
        ((count++))
    done < "$SAVED_PATHS_FILE"
}

# Function to list paths with ls details
list_paths_details() {
    print_header "SAVED PATHS DETAILS"
    
    if [[ ! -f "$SAVED_PATHS_FILE" ]] || [[ ! -s "$SAVED_PATHS_FILE" ]]; then
        print_warning "No saved paths found"
        return 0
    fi
    
    while IFS='|' read -r path description timestamp; do
        echo -e "${CYAN}Path:${NC} $path"
        echo -e "${YELLOW}Description:${NC} $description"
        echo -e "${BLUE}Saved:${NC} $timestamp"
        
        if [[ -d "$path" ]]; then
            echo -e "${GREEN}Directory details:${NC}"
            ls -lha "$path" 2>/dev/null || echo -e "${RED}Cannot access directory${NC}"
        else
            echo -e "${RED}Directory does not exist${NC}"
        fi
        echo -e "${CYAN}--------------------------------------------------${NC}"
    done < "$SAVED_PATHS_FILE"
}

# Function to edit saved paths
edit_saved_paths() {
    print_header "EDIT SAVED PATHS"
    
    if [[ ! -f "$SAVED_PATHS_FILE" ]] || [[ ! -s "$SAVED_PATHS_FILE" ]]; then
        print_warning "No saved paths found"
        return 0
    fi
    
    print_info "Opening saved paths file in default editor..."
    print_warning "Format: path|description|timestamp"
    print_warning "Please maintain this format when editing"
    echo ""
    
    # Use default editor or nano as fallback
    ${EDITOR:-nano} "$SAVED_PATHS_FILE"
    
    print_success "Saved paths file edited"
}

# Function to delete a saved path
delete_saved_path() {
    print_header "DELETE SAVED PATH"
    
    if [[ ! -f "$SAVED_PATHS_FILE" ]] || [[ ! -s "$SAVED_PATHS_FILE" ]]; then
        print_warning "No saved paths found"
        return 0
    fi
    
    local paths_array=()
    local count=1
    
    echo -e "${PURPLE}Select path to delete:${NC}"
    echo -e "${CYAN}=====================${NC}"
    
    while IFS='|' read -r path description timestamp; do
        paths_array+=("$path")
        echo -e "${GREEN}$count.${NC} $path"
        echo -e "   ${YELLOW}Description:${NC} $description"
        echo ""
        ((count++))
    done < "$SAVED_PATHS_FILE"
    
    echo -e "${CYAN}Enter path number to delete or 'q' to quit:${NC}"
    read -p "> " choice
    
    if [[ "$choice" == "q" ]]; then
        return 0
    fi
    
    if [[ "$choice" =~ ^[0-9]+$ ]]; then
        local index=$((choice - 1))
        if [[ $index -ge 0 && $index -lt ${#paths_array[@]} ]]; then
            local path_to_delete="${paths_array[$index]}"
            
            echo -e "${YELLOW}Are you sure you want to delete this path? (y/n):${NC}"
            echo -e "${RED}$path_to_delete${NC}"
            read -p "> " confirm
            
            if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                # Create temporary file without the selected path
                grep -v "^${path_to_delete}|" "$SAVED_PATHS_FILE" > "${SAVED_PATHS_FILE}.tmp" && mv "${SAVED_PATHS_FILE}.tmp" "$SAVED_PATHS_FILE"
                print_success "Deleted path: $path_to_delete"
            else
                print_info "Deletion cancelled"
            fi
        else
            print_error "Invalid selection! Please enter a number between 1 and ${#paths_array[@]}"
        fi
    else
        print_error "Invalid input! Please enter a number or 'q'"
    fi
}

# Function to change working path from main menu
change_working_path() {
    print_header "CHANGE WORKING PATH"
    print_info "Current working directory: $(pwd)"
    echo ""
    
    # Path selection loop
    while true; do
        if select_working_path; then
            print_success "Working path changed successfully!"
            break
        else
            echo -e "${YELLOW}Would you like to try again? (y/n):${NC}"
            read -p "> " retry
            if [[ "$retry" != "y" && "$retry" != "Y" ]]; then
                print_info "Keeping current working directory: $(pwd)"
                break
            fi
        fi
    done
}

# Main execution
main() {
    # Initialize logging
    init_logging
    log_operation "INFO" "Git Workflow Manager started" "STARTUP"
    
    print_header "GIT DAILY OPERATIONS"
    
    # Path selection as first step
    while true; do
        if select_working_path; then
            log_operation "SUCCESS" "Working path selected: $(pwd)" "PATH_SELECTION"
            break
        else
            echo -e "${YELLOW}Would you like to try again? (y/n):${NC}"
            read -p "> " retry
            if [[ "$retry" != "y" && "$retry" != "Y" ]]; then
                log_operation "INFO" "User cancelled path selection" "PATH_SELECTION"
                print_info "Goodbye!"
                exit 0
            fi
        fi
    done
    
    # Now check if we're in a git repository (should pass since we validated)
    check_git_repo
    log_operation "SUCCESS" "Git repository validation passed" "REPO_CHECK"

    # Main loop
    while true; do
        main_menu
    done
}

# Run the main function
main "$@"
