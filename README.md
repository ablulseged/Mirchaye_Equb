# robot

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## GitHub Guide

### What is GitHub?

GitHub is a platform for hosting and collaborating on code repositories. It uses Git, a version control system that tracks changes to your code over time.

### Current Git Configuration

- **Username**: ablulseged
- **Email**: daniellulseged010@gmail.com

### Basic GitHub Workflow

#### 1. Check Status
See what files have been changed:
```bash
git status
```

#### 2. Stage Changes
Add files you want to commit:
```bash
git add <filename>          # Stage a specific file
git add .                   # Stage all changed files
git add *.dart              # Stage all .dart files
```

#### 3. Commit Changes
Save your changes with a message:
```bash
git commit -m "Your descriptive commit message"
```

#### 4. Push to GitHub
Upload your commits to the remote repository:
```bash
git push origin main
```

### Common Git Commands

```bash
# View changes before committing
git diff

# View commit history
git log

# Pull latest changes from GitHub
git pull origin main

# Clone a repository
git clone <repository-url>

# Create a new branch
git checkout -b <branch-name>

# Switch branches
git checkout <branch-name>

# View all branches
git branch
```

### Why Commit Button is Disabled

The commit button in your IDE (VS Code/Cursor) will be **disabled/grayed out** when:
- There are no changes to commit
- No files are staged
- No commit message is entered

**To enable it:**
1. Make changes to your files
2. Stage the changes (click "+" next to files in Source Control)
3. Enter a commit message
4. The commit button will become active

### Best Practices

- **Write clear commit messages**: Describe what changes you made and why
- **Commit often**: Make small, frequent commits rather than large ones
- **Pull before push**: Always pull latest changes before pushing
- **Review changes**: Use `git diff` to review what you're committing

### Example Workflow

```bash
# 1. Make changes to your files
# 2. Check what changed
git status

# 3. Stage all changes
git add .

# 4. Commit with message
git commit -m "Add new feature: user authentication"

# 5. Push to GitHub
git push origin main
```

### Getting Help

- [Git Documentation](https://git-scm.com/doc)
- [GitHub Guides](https://guides.github.com/)
- [Git Cheat Sheet](https://education.github.com/git-cheat-sheet-education.pdf)