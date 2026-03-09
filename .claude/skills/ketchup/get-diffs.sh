#!/bin/bash
set -euo pipefail

# Get arguments - check if we should analyze commits
ANALYZE_COMMITS=false
if [[ "${1:-}" =~ commit ]]; then
  ANALYZE_COMMITS=true
fi

# Find Canvas LMS root directory
CANVAS_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
if [[ -z "$CANVAS_ROOT" ]]; then
  echo "Error: Not in a git repository"
  exit 1
fi

# If we're in a plugin, navigate to Canvas root
if [[ "$CANVAS_ROOT" =~ gems/plugins/ ]]; then
  CANVAS_ROOT=$(cd "$CANVAS_ROOT/../../../.." && pwd)
fi

echo "=== CANVAS ROOT ==="
echo "$CANVAS_ROOT"
echo ""

# Function to analyze a repository
analyze_repo() {
  local repo_path="$1"
  local repo_name="$2"

  echo "=== REPOSITORY: $repo_name ==="
  echo "Path: $repo_path"
  echo ""

  # Get current branch
  echo "--- BRANCH ---"
  git -C "$repo_path" branch --show-current 2>/dev/null || echo "detached HEAD"
  echo ""

  # Check for uncommitted changes
  echo "--- STATUS ---"
  local status_output=$(git -C "$repo_path" status --short 2>/dev/null || echo "")
  if [[ -z "$status_output" ]]; then
    echo "No uncommitted changes"
  else
    echo "$status_output"
  fi
  echo ""

  # Get uncommitted diff if there are changes
  if [[ -n "$status_output" ]]; then
    # Show staged changes separately
    echo "--- STAGED CHANGES ---"
    local staged_diff=$(git -C "$repo_path" diff --cached 2>/dev/null || echo "")
    if [[ -n "$staged_diff" ]]; then
      echo "$staged_diff"
    else
      echo "No staged changes"
    fi
    echo ""

    # Show unstaged changes separately
    echo "--- UNSTAGED CHANGES ---"
    local unstaged_diff=$(git -C "$repo_path" diff 2>/dev/null || echo "")
    if [[ -n "$unstaged_diff" ]]; then
      echo "$unstaged_diff"
    else
      echo "No unstaged changes"
    fi
    echo ""

    # Show content of untracked files (limit to reasonable size)
    echo "--- UNTRACKED FILES CONTENT ---"
    local has_untracked=false
    while IFS= read -r line; do
      if [[ "$line" =~ ^\?\?[[:space:]](.+)$ ]]; then
        local path="${BASH_REMATCH[1]}"
        local full_path="$repo_path/$path"

        # If it's a file, show its content
        if [[ -f "$full_path" ]]; then
          has_untracked=true
          echo "=== NEW FILE: $path ==="
          # Only show first 500 lines of new files to avoid huge output
          head -n 500 "$full_path" 2>/dev/null || echo "Unable to read file"
          echo ""
        # If it's a directory, find all files within it
        elif [[ -d "$full_path" ]]; then
          while IFS= read -r file; do
            has_untracked=true
            local rel_path="${file#$repo_path/}"
            echo "=== NEW FILE: $rel_path ==="
            # Only show first 500 lines of new files to avoid huge output
            head -n 500 "$file" 2>/dev/null || echo "Unable to read file"
            echo ""
          done < <(find "$full_path" -type f 2>/dev/null)
        fi
      fi
    done <<< "$status_output"

    if [[ "$has_untracked" == "false" ]]; then
      echo "No untracked files to display"
    fi
    echo ""
  fi

  # Get commit info if requested
  if [[ "$ANALYZE_COMMITS" == "true" ]]; then
    echo "--- RECENT COMMITS ---"
    git -C "$repo_path" log --oneline -5 2>/dev/null || echo "No commits available"
    echo ""

    echo "--- BRANCH DIFF FROM MASTER ---"
    # Try master, then origin/master, then main, then origin/main
    local base_branch=""
    for branch in master origin/master main origin/main; do
      if git -C "$repo_path" rev-parse --verify "$branch" >/dev/null 2>&1; then
        base_branch="$branch"
        break
      fi
    done

    if [[ -n "$base_branch" ]]; then
      git -C "$repo_path" diff "$base_branch"..HEAD 2>/dev/null || echo "No diff available"
    else
      echo "No base branch (master/main) found"
    fi
    echo ""
  fi

  echo "=== END REPOSITORY: $repo_name ==="
  echo ""
}

# Analyze main Canvas repository
analyze_repo "$CANVAS_ROOT" "Canvas LMS (main)"

# Find and analyze all plugin repositories
echo "=== DISCOVERING PLUGINS ==="
if [[ -d "$CANVAS_ROOT/gems/plugins" ]]; then
  # Use a more portable approach than mapfile (which requires bash 4+)
  plugin_repos=()
  while IFS= read -r line; do
    [[ -n "$line" ]] && plugin_repos+=("$line")
  done < <(find "$CANVAS_ROOT/gems/plugins" -maxdepth 2 -name .git -type d 2>/dev/null | sed 's|/.git$||' | sort)

  if [[ ${#plugin_repos[@]} -gt 0 ]]; then
    echo "Found ${#plugin_repos[@]} plugin repositories"
    echo ""

    for plugin_path in "${plugin_repos[@]}"; do
      plugin_name=$(basename "$plugin_path")
      analyze_repo "$plugin_path" "Plugin: $plugin_name"
    done
  else
    echo "No plugin repositories found"
    echo ""
  fi
else
  echo "No plugins directory found"
  echo ""
fi
