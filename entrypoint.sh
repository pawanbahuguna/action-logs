#!/bin/sh

########################
#
# Script to Download job-level logs for the past 24hrs or all the logs
# Author: Pawan Bahuguna
# GitHub: https://github.com/pawanbahuguna/action-logs
# Version: v2.0
########################

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

if [ "$ONLY_24" = "false" ]; then
  echo "Processing all the logs"
else 
  # Check for OS and use the appropriate date command
  if [ "$(uname)" = "Linux" ]; then
    if [ -f /etc/alpine-release ]; then
      # Alpine Linux
      OLD_DATE=$(date -u -R | awk '{ print strftime("%Y-%m-%dT%H:%M:%SZ", systime() - 24*60*60) }')
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


clean_up () {
  echo "Starting cleanup"
  rm -f $JOB_FILE
  echo "cleanup Completed!!"
}

# Get Workflow run
get_run_id () {
  echo "Searching Workflow Runs"
  RUNS=$(curl -s -H "Authorization: token $GH_TOKEN" "https://api.github.com/repos/$GH_REPO/actions/runs?per_page=100")
  RUN_ID=$(echo "$RUNS" | jq -r --arg OLD_DATE "$OLD_DATE" '.workflow_runs[] | select(.created_at >= $OLD_DATE) | .id' )
  TOTAL_COUNT=$(echo "$RUNS" | jq -r '.total_count')
}

# Get jobs from the Workflow
get_job_id () {
  echo "Fetching Job IDs"
  for run_id in $RUN_ID; do
   curl -s -L -H "Authorization: Bearer $GH_TOKEN" "https://api.github.com/repos/$GH_REPO/actions/runs/$run_id/jobs" | jq -r '.jobs[].id' >> $JOB_FILE
  done 
}

# Get logs for the job ID
get_jobs_logs () {
  mkdir "$LOGS_DIR"
  cat $JOB_FILE | while IFS= read -r JOBID
  do
   echo "Writing logs for job $JOBID"
   JOB_LOGS="logs-$JOBID-$(date +'%Y-%m-%d').txt"
   curl -s -L -H "Authorization: Bearer $GH_TOKEN" "https://api.github.com/repos/$GH_REPO/actions/jobs/$JOBID/logs" -o "$LOGS_DIR/$JOB_LOGS"
  done
}

get_run_id
# Check if there are any workflow runs
if [ "$TOTAL_COUNT" -eq 0 ]; then
    echo "No workflow runs found."
    exit 1
else
    get_job_id
    if [ -f $JOB_FILE ]; then
     get_jobs_logs
     echo "Logs Downloaded and saved!"
     clean_up
     exit 0
    else 
     echo "Job ID file not found or no jobs to process, exiting."
     exit 1
    fi
fi
