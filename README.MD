# GitHub CLI Tool

## Author: Gustavo Wydler Azuaga
## Release date: 09/23/2024

- A command-line interface (CLI) tool for managing Git and GitHub operations efficiently. 
- This tool simplifies the process of working with Git repositories, handling everything from authentication and branch management to commits, pushes, and merges.

## Upgraded Version release: 02/26/2025

---------------------------------------------------------------------------------------------------------------------------------------------------------------------

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

* Requirements needed to run the program

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

---

## Version 2.0 - Enhanced Git Workflow Manager (git-workflow-manager.sh)

### Major Enhancements and New Features

The original `git_cli_console.sh` has been completely redesigned and enhanced into `git-workflow-manager.sh` - a more robust, user-friendly, and feature-rich version 2.0 of the tool.

---

### 🎯 **Key Improvements in Version 2.0:**

#### **1. Enhanced User Interface & Experience**
- **Colored Output**: Professional color-coded interface with consistent styling
- **Clear Navigation**: Intuitive menu system with numbered options and descriptions
- **Progress Indicators**: Visual feedback for all operations
- **Interactive Prompts**: Smart validation and confirmation prompts
- **Help System**: Comprehensive built-in help with command explanations

#### **2. Advanced Git Workflow Management**
- **Start of Day Operations**: Automated setup routine including fetch, master update, and cleanup
- **Daily Work Operations**: Streamlined branch switching, creation, and updates
- **Intelligent Branch Management**: Enhanced validation and conflict resolution
- **Commit Management**: Advanced commit operations with detailed history tracking
- **Status Monitoring**: Real-time Git status with comprehensive information display

#### **3. Comprehensive Branch Operations**
- **Smart Branch Selection**: Numbered branch selection with current branch highlighting
- **Enhanced Validation**: Robust branch name validation and existence checking
- **Conflict Resolution**: Automated handling of merge conflicts and rebase issues
- **Branch Cleanup**: Automated cleanup of merged and stale branches
- **Remote Synchronization**: Intelligent remote branch management

#### **4. Advanced Commit Management System**
- **Commit History Analysis**: Detailed commit viewing with multiple display formats
- **Search Functionality**: Search commits by message, author, file, date, or content
- **Commit Comparison**: Side-by-side commit comparison with detailed diff analysis
- **Cherry-pick Operations**: Safe cherry-picking with conflict resolution
- **Interactive Rebase**: Guided interactive rebase with safety checks
- **Commit Statistics**: Comprehensive analytics and contributor insights

#### **5. Enhanced Security & Validation**
- **SSH Validation**: Improved SSH connection testing and validation
- **Enhanced Authentication**: Better GitHub authentication with multiple account support
- **Input Validation**: Comprehensive validation for all user inputs
- **Error Handling**: Robust error handling with informative messages
- **Uncommitted Changes Detection**: Smart detection and handling of uncommitted changes

#### **6. Professional Error Handling**
- **Graceful Degradation**: Intelligent fallback mechanisms
- **Informative Messages**: Clear error messages with suggested solutions
- **Recovery Options**: Automatic recovery suggestions for common issues
- **State Verification**: Continuous validation of Git repository state

---

### 🚀 **New Features Not in Original Version:**

#### **Advanced Workflow Operations**
- **Automated Start-of-Day Setup**: Complete morning routine automation
- **Intelligent Update System**: Smart branch updates with conflict resolution
- **Uncommit Operations**: Multiple uncommit strategies (soft, mixed, hard, revert)
- **Interactive Workflows**: Guided step-by-step operations

#### **Comprehensive Analytics**
- **Author Statistics**: Detailed contributor analysis
- **File Change Tracking**: Most modified files identification
- **Commit Frequency Analysis**: Timeline-based commit analytics
- **Code Contribution Metrics**: Lines added/removed by author
- **Blame Analysis**: Detailed line-by-line code ownership

#### **Enhanced Repository Management**
- **Repository Validation**: Enhanced validation for repo operations
- **Branch Protection**: Safeguards against destructive operations
- **Cleanup Automation**: Automated cleanup of merged branches
- **Remote Management**: Advanced remote repository handling

#### **Professional Documentation**
- **Built-in Help System**: Comprehensive command explanations
- **Workflow Strategy Guide**: Best practices and strategy explanations
- **Command Reference**: Detailed command documentation
- **Troubleshooting Guide**: Common issues and solutions

---

### 📊 **Feature Comparison Matrix:**

| Feature | Original (git_cli_console.sh) | Enhanced (git-workflow-manager.sh) |
|---------|-------------------------------|-------------------------------------|
| **User Interface** | Basic text menus | Professional colored interface |
| **Branch Management** | Basic operations | Advanced with validation & cleanup |
| **Commit Operations** | Simple commit/push | Advanced commit analysis & management |
| **Error Handling** | Basic error messages | Comprehensive error handling & recovery |
| **Help System** | None | Built-in comprehensive help |
| **Workflow Automation** | Manual operations | Automated daily workflows |
| **Analytics** | Basic stats | Comprehensive analytics & insights |
| **Security** | Basic SSH testing | Enhanced validation & authentication |
| **Documentation** | Minimal | Extensive with explanations |

---

### 🔧 **Technical Improvements:**

#### **Code Quality**
- **Modular Design**: Well-structured functions with clear responsibilities
- **Consistent Styling**: Professional coding standards throughout
- **Error Resilience**: Robust error handling and recovery mechanisms
- **Performance Optimization**: Efficient operations with minimal overhead

#### **User Experience**
- **Intuitive Navigation**: Logical menu structure with clear options
- **Visual Feedback**: Color-coded status indicators and progress updates
- **Context Awareness**: Smart defaults based on current repository state
- **Safety Features**: Confirmation prompts for destructive operations

#### **Advanced Functionality**
- **State Management**: Intelligent tracking of repository state
- **Conflict Resolution**: Automated handling of common Git conflicts
- **Batch Operations**: Efficient handling of multiple operations
- **Integration Support**: Better integration with GitHub CLI and SSH

---

### 🎯 **Migration Guide:**

Users of the original `git_cli_console.sh` can seamlessly transition to `git-workflow-manager.sh` with these benefits:

1. **Familiar Operations**: All original functionality preserved and enhanced
2. **New Capabilities**: Access to advanced features without learning curve
3. **Improved Reliability**: Enhanced error handling and recovery
4. **Better Performance**: Optimized operations with faster execution
5. **Professional Experience**: Modern interface with comprehensive feedback

---

### 📋 **Usage Instructions:**

```bash
# Clone the repository
git clone https://github.com/kurogane13/git_bash_interactvie_console.git

# Navigate to the directory
cd git_bash_interactvie_console

# Run the original version (Version 1.0)
bash git_cli_console.sh

# Run the enhanced version 2.0
bash git-workflow-manager.sh
```

The enhanced version maintains backward compatibility while providing a significantly improved user experience and powerful new features for modern Git workflow management.

