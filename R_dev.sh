#!/bin/bash

# Define the session name
SESSION_NAME="R_dev"

# Check if the session already exists
tmux has-session -t "$SESSION_NAME" 2>/dev/null

# $? is the exit status of the last command
if [ $? != 0 ]; then
  # Session doesn't exist, create it

  # Start a new detached session, window named 'Code', pane 0 runs nvim
  tmux new-session -d -s "$SESSION_NAME" -n 'Code' 'nvim'

  # Split the window vertically (creates pane 1 to the right)
  tmux split-window -v -p 25 -t "$SESSION_NAME":0.0

  # Send the 'R' command to the new pane (pane 1) and press Enter
  tmux send-keys -t "$SESSION_NAME":0.1 'R' C-m

  # Select the nvim pane (pane 0) so it's active when attaching
  tmux select-pane -t "$SESSION_NAME":0.0

  echo "Created tmux session '$SESSION_NAME'"
else
  echo "Session '$SESSION_NAME' already exists."
fi

# Attach to the session
tmux attach-session -t "$SESSION_NAME"
