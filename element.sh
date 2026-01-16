#!/bin/bash

if [[ $# -eq 0 ]]; then
    echo "Please provide an element as an argument."
    exit 0
fi

ARGUMENT="$1"

# Build the WHERE clause based on whether ARGUMENT is a number
if [[ "$ARGUMENT" =~ ^[0-9]+$ ]]; then
    WHERE_CLAUSE="e.atomic_number = $ARGUMENT"
else
    WHERE_CLAUSE="UPPER(e.symbol) = UPPER('$ARGUMENT') OR UPPER(e.name) = UPPER('$ARGUMENT')"
fi

# Try to find the element by atomic number, symbol, or name
QUERY="SELECT e.atomic_number::text || '|' || e.name || '|' || e.symbol || '|' || p.atomic_mass::text || '|' || p.melting_point_celsius::text || '|' || p.boiling_point_celsius::text || '|' || t.type
FROM elements e
LEFT JOIN properties p ON e.atomic_number = p.atomic_number
LEFT JOIN types t ON p.type_id = t.type_id
WHERE $WHERE_CLAUSE
LIMIT 1;"

# Execute the query
OUTPUT=$(psql --username=freecodecamp --dbname=periodic_table -t -A -c "$QUERY" 2>/dev/null | tr -d '\n')

if [[ -z "$OUTPUT" ]]; then
    echo "I could not find that element in the database."
    exit 0
fi

# Parse the result using IFS
IFS='|' read -r ATOMIC_NUMBER NAME SYMBOL ATOMIC_MASS MELTING_POINT BOILING_POINT ELEMENT_TYPE <<< "$OUTPUT"

# Clean up any whitespace issues
ELEMENT_TYPE=$(echo "$ELEMENT_TYPE" | tr -d '\n' | xargs)

echo "The element with atomic number $ATOMIC_NUMBER is $NAME ($SYMBOL). It's a $ELEMENT_TYPE, with a mass of $ATOMIC_MASS amu. $NAME has a melting point of $MELTING_POINT celsius and a boiling point of $BOILING_POINT celsius."
