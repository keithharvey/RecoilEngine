#!/bin/zsh

# Create output dir
mkdir -p prompts/artifacts

# Get branch names
SPRING_BRANCH=$(git -C . rev-parse --abbrev-ref HEAD)
BAR_PATH="../Beyond-All-Reason"
BAR_BRANCH=$(git -C "$BAR_PATH" rev-parse --abbrev-ref HEAD)

# Spring engine diffs
git -C . diff origin/master > prompts/artifacts/spring_diff_${SPRING_BRANCH}_vs_master.md
git -C . diff --cached > prompts/artifacts/spring_diff_${SPRING_BRANCH}_staged.md

# BAR game diffs
git -C "$BAR_PATH" diff origin/master > prompts/artifacts/bar_diff_${BAR_BRANCH}_vs_master.md
git -C "$BAR_PATH" diff --cached > prompts/artifacts/bar_diff_${BAR_BRANCH}_staged.md
