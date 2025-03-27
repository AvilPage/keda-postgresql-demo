#!/bin/bash

# Database connection details
DB_HOST="postgres-service"
DB_NAME="taskdb"
DB_USER="taskuser"
DB_PASSWORD="taskpassword"
PGPASSWORD="taskpassword"
export PGPASSWORD='taskpassword'

# Wait for PostgreSQL to be ready
until psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -c '\q'; do
  echo "Waiting for PostgreSQL to be ready..."
  sleep 5
done

# Function to fetch and process tasks
process_tasks() {
  # log count of total uncompleted tasks
  COUNT=$(psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -t <<-EOSQL
    SELECT COUNT(*) FROM tasks WHERE status != 'Completed';
EOSQL
  )

  echo "Total uncompleted tasks: $COUNT"

  TASK=$(psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -t <<-EOSQL
    SELECT id, description, status FROM tasks
    WHERE status != 'Completed'
    ORDER BY id
    LIMIT 1;
EOSQL
  )

  if [ -n "$TASK" ]; then
    TASK_ID=$(echo "$TASK" | awk '{print $1}')
    DESCRIPTION=$(echo "$TASK" | awk '{print $2}')
    STATUS=$(echo "$TASK" | awk '{print $3}')

    echo "Processing task: $DESCRIPTION (ID: $TASK_ID)"

    # Mark the task as completed
    psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" <<-EOSQL
      UPDATE tasks
      SET status = 'Completed'
      WHERE id = $TASK_ID;
EOSQL

    echo "Task $TASK_ID marked as completed."

    echo "consumer sleeping for 1 seconds"
    sleep 1

  else
    echo "No pending tasks found."
  fi
}

# Continuously process tasks
while true; do
  process_tasks
  sleep 2
done
