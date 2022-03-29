#!/usr/bin/env bash
# usage: submit_pr.sh <branch-prefix> <pr-title> <pr-body>

set -e
set -u
# Use privileged mode, which e.g. skips using CDPATH.
set -p

# Ensure that the user has a bash that supports -A
if [[ "${BASH_VERSINFO[0]}" -lt 4 ]]; then
  echo >&2 "error: script requires bash 4+ (you have ${BASH_VERSION})."
  exit 1
fi

readonly NVIM_SOURCE_DIR="${NVIM_SOURCE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
BASENAME="$(basename "${0}")"

readonly BRANCH_PREFIX=$1
readonly PR_TITILE=$2
readonly PR_BODY=$3

msg_ok() {
  printf '\e[32m✔\e[0m %s\n' "$@"
}

msg_err() {
  printf '\e[31m✘\e[0m %s\n' "$@" >&2
}

# Checks if a program is in the user's PATH, and is executable.
check_executable() {
  test -x "$(command -v "${1}")"
}

require_executable() {
  if ! check_executable "${1}"; then
    echo >&2 "${BASENAME}: '${1}' not found in PATH or not executable."
    exit 1
  fi
}

gh_pr() {
  local pr_title
  local pr_body
  pr_title="$1"
  pr_body="$2"
  shift 2
  gh pr create --title "${pr_title}" --body "${pr_body}" "$@"
}

git_hub_pr() {
  local pr_message
  pr_message="$(printf '%s\n\n%s\n' "$1" "$2")"
  shift 2
  git hub pull new -m "${pr_message}" "$@"
}

find_git_remote() {
  local git_remote
  if [[ "${1-}" == fork ]]; then
    git_remote=$(git remote -v | awk '$2 !~ /github.com[:\/]neovim\/neovim/ && $3 == "(fetch)" {print $1; exit}')
  else
    git_remote=$(git remote -v | awk '$2 ~ /github.com[:\/]neovim\/neovim/ && $3 == "(fetch)" {print $1; exit}')
  fi
  if [[ -z "$git_remote" ]]; then
    git_remote="origin"
  fi
  git_remote="myorigin"
  echo "$git_remote"
}

submit_pr() {
  require_executable git
  local push_first
  push_first=1
  local submit_fn
  if check_executable gh; then
    submit_fn="gh_pr"
  elif check_executable git-hub; then
    push_first=0
    submit_fn="git_hub_pr"
  else
    echo >&2 "${BASENAME}: 'gh' or 'git-hub' not found in PATH or not executable."
    echo >&2 "              Get it here: https://cli.github.com/"
    exit 1
  fi

  cd "${NVIM_SOURCE_DIR}"
  local checked_out_branch
  checked_out_branch="$(git rev-parse --abbrev-ref HEAD)"
  if [[ "${checked_out_branch}" != ${BRANCH_PREFIX}* ]]; then
    msg_err "Current branch '${checked_out_branch}' doesn't seem to be a vim-patch branch."
    exit 1
  fi

  local nvim_remote
  nvim_remote="$(find_git_remote)"
  local pr_body
  pr_body="$(git log --grep=vim-patch --reverse --format='#### %s%n%n%b%n' "${nvim_remote}"/master..HEAD)"
  local patches
  # Extract just the "vim-patch:X.Y.ZZZZ" or "vim-patch:sha" portion of each log
  patches=("$(git log --grep=vim-patch --reverse --format='%s' "${nvim_remote}"/master..HEAD | sed 's/: .*//')")
  # shellcheck disable=SC2206
  patches=(${patches[@]//vim-patch:/}) # Remove 'vim-patch:' prefix for each item in array.
  local pr_title="${patches[*]}"       # Create space-separated string from array.
  pr_title="${pr_title// /,}"          # Replace spaces with commas.
  pr_title="$(printf 'vim-patch:%s' "${pr_title#,}")"

  if [[ $push_first -ne 0 ]]; then
    local push_remote
    push_remote="$(git config --get branch."${checked_out_branch}".pushRemote || true)"
    push_remote=$(find_git_remote)
    if [[ -z "$push_remote" ]]; then
      push_remote="$(git config --get remote.pushDefault || true)"
      if [[ -z "$push_remote" ]]; then
        push_remote="$(git config --get branch."${checked_out_branch}".remote || true)"
        if [[ -z "$push_remote" ]] || [[ "$push_remote" == "$nvim_remote" ]]; then
          push_remote="$(find_git_remote fork)"
        fi
      fi
    fi
    echo "Pushing to '${push_remote}/${checked_out_branch}'."
    if output="$(git push "$push_remote" "$checked_out_branch" 2>&1)"; then
      msg_ok "$output"
    else
      msg_err "$output"
      exit 1
    fi

    echo
  fi

  echo "ttt pr_title: $pr_title" >> log
  echo "ttt pr_body: $pr_body" >> log
  
  echo "Creating pull request."
  if output="$($submit_fn "$pr_title" "$pr_body" --repo "https://github.com/abrfr/neovim.git" --head abrfr:bump_deps_example 2>&1)"; then
    msg_ok "$output"
  else
    msg_err "$output"
    exit 1
  fi
}

submit_pr "--title" "$PR_TITILE" "--body" "$PR_BODY"
