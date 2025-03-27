#!/bin/bash

# Database connection details
DB_HOST="postgres-service"
DB_NAME="taskdb"
DB_USER="taskuser"
DB_PASSWORD="taskpassword"
PGPASSWORD="taskpassword"
export PGPASSWORD='taskpassword'

echo "Waiting for PostgreSQL to be ready..."

# Wait for PostgreSQL to be ready
until PGPASSWORD='taskpassword' psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -c '\q'; do
  echo "Waiting for PostgreSQL to be ready..."
  sleep 5
done

echo 'PostgreSQL is ready!'

# Create the tasks table if it doesn't exist
psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" <<-EOSQL
  CREATE TABLE IF NOT EXISTS tasks (
      id SERIAL PRIMARY KEY,
      description TEXT NOT NULL,
      status TEXT NOT NULL
  );
EOSQL

# Function to insert random tasks
insert_random_task() {
  DESCRIPTIONS=("Clean" "Cook" "Study" "Exercise" "Sleep")
  STATUSES="Todo"

  DESCRIPTION=${DESCRIPTIONS[$RANDOM % ${#DESCRIPTIONS[@]}]}

  psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" <<-EOSQL
    INSERT INTO tasks (description, status)
    VALUES ('$DESCRIPTION', '$STATUS');
EOSQL

  echo "Inserted task: $DESCRIPTION with status: $STATUS"
}

# Continuously insert tasks
while true; do
  # log uncompleted, completed tasks
  COUNT=$(psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -t <<-EOSQL
    SELECT COUNT(*) FROM tasks WHERE status != 'Completed';
EOSQL
  )
  echo "Total uncompleted tasks: $COUNT"

  # get random number between 1 and 3
  random_number=$((1 + RANDOM % 3))
  for i in $(seq 1 $random_number); do
    insert_random_task
  done
  sleep 2  # Wait for 2 seconds before inserting the next tasks
done
