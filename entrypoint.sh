#!/bin/bash

########################
#
# Script to Download job-level logs for the past 24hrs or all the logs
# Author: Pawan Bahuguna
# GitHub: https://github.com/pawanbahuguna/action-logs
# Version: v1.0
########################

C_RED="\033[0;31m" # Red
C_GRN="\033[0;32m" # Green
C_BLU="\033[0;34m" # Blue
C_RST="\033[0m"    # Reset

JOB_FILE=jobID.txt

if [ -z "$GH_TOKEN" ]; then
  echo "GH_TOKEN is not set, exiting...."
  exit 1
fi

if [ -z "$LOGS_DIR" ]; then
  LOGS_DIR="jobs-log"
fi

# Calculate the timestamp
if [ -z "$ONLY_24" ]; then
  ONLY_24="true"
fi

if [ "$ONLY_24" == "false" ]; then
  echo "Processing all the logs"
else 
  # Check for OS and use the appropriate date command
  if [ "$(uname)" = "Linux" ]; then
    if [ -f /etc/alpine-release ]; then
      # Alpine Linux
      OLD_DATE=$(date -u -D '%s' -d $(( $(date +%s) - 24*60*60 )) +'%Y-%m-%dT%H:%M:%SZ')
    else
      # Other Linux
      OLD_DATE=$(date -d '24 hours ago' +'%Y-%m-%dT%H:%M:%SZ')
    fi
  else
    # Assume BSD-style date (e.g., macOS)
    OLD_DATE=$(date -v-24H +'%Y-%m-%dT%H:%M:%SZ')
  fi
  echo "Will only process 24hrs logs before or equal to $OLD_DATE"
fi

function error_msg () {
 echo -e "${C_RED}$*${C_RST}"
}

function success_msg () {
 echo -e "${C_GRN}$*${C_RST}"
}

function info_msg () {
 echo -e "${C_BLU}$*${C_RST}"
}

clean_up () {
  info_msg "Starting cleanup"
  rm -f $JOB_FILE
  success_msg "cleanup Completed!!"
}

# Get Workflow run
get_run_id () {
  info_msg "Searching Workflow Runs"
  RUNS=$(curl -s -H "Authorization: token $GH_TOKEN" "https://api.github.com/repos/$GH_REPO/actions/runs?per_page=100")
  RUN_ID=$(echo "$RUNS" | jq -r --arg OLD_DATE "$OLD_DATE" '.workflow_runs[] | select(.created_at >= $OLD_DATE) | .id' )
  TOTAL_COUNT=$(echo "$RUNS" | jq -r '.total_count')
}

# Get jobs from the Workflow
get_job_id () {
  info_msg "Fetching Job IDs"
  for run_id in $RUN_ID; do
   curl -s -L -H "Authorization: Bearer $GH_TOKEN" "https://api.github.com/repos/$GH_REPO/actions/runs/$run_id/jobs" | jq -r '.jobs[].id' >> $JOB_FILE
  done 
}

# Get logs for the job ID
get_jobs_logs () {
  mkdir "$LOGS_DIR"
  cat $JOB_FILE | while IFS= read -r JOBID
  do
   info_msg "Writing logs for job $JOBID"
   JOB_LOGS="logs-$JOBID-$(date +'%Y-%m-%d').txt"
   curl -s -L -H "Authorization: Bearer $GH_TOKEN" "https://api.github.com/repos/$GH_REPO/actions/jobs/$JOBID/logs" -o "$LOGS_DIR/$JOB_LOGS"
  done
}

get_run_id
# Check if there are any workflow runs
if [[ "$TOTAL_COUNT" -eq 0 ]]; then
    error_msg "No workflow runs found."
    exit 1
else
    get_job_id
    if [[ -f $JOB_FILE ]]; then
     get_jobs_logs
     success_msg "Logs Downloaded and saved!"
     clean_up
     exit 0
    else 
     error_msg "Job ID file not found or no jobs to process, exiting."
     exit 1
    fi
fi
