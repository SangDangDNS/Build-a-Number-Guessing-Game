#!/bin/bash

# Set PGPASSFILE environment variable to point to the .pgpass file
export PGPASSFILE=/home/sang/.pgpass

PSQL="psql -h localhost -p 5432 -U root -d number_guess --no-align --tuples-only -c"

echo "Enter your username:"
read NAME

SECRET_NUMBER=$(( RANDOM % 999 + 1 ))

USER_ID=$($PSQL "SELECT user_id FROM users where name = '$NAME'")

if [[ -z $USER_ID ]]
then
  echo -e "\nWelcome, $NAME! It looks like this is your first time here."
  INSERT_USER=$($PSQL "INSERT INTO users (name) values ('$NAME')")
else
  GAME_ID=$($PSQL "SELECT count(game_id) FROM games where user_id = $USER_ID")
  GUESS_COUNT=$($PSQL "SELECT min(guess_count) FROM games where user_id = $USER_ID")
  echo -e "\nWelcome back, $NAME! You have played $GAME_ID games, and your best game took $GUESS_COUNT guesses."
fi

echo -e "\nGuess the secret number between 1 and 1000:"
COUNT=0
NUMBER_INPUT=0
until [ $NUMBER_INPUT == $SECRET_NUMBER ]
do
  read -r NUMBER_INPUT  
  if [[ ! $NUMBER_INPUT =~ ^[0-9]+$ ]] 
  then
    echo "That is not an integer, guess again:"
  else
    ((COUNT++))
    if [[ $NUMBER_INPUT -lt $SECRET_NUMBER ]]
    then
      echo "It's higher than that, guess again:"
    elif [[ $NUMBER_INPUT -gt $SECRET_NUMBER ]]
    then
      echo "It's lower than that, guess again:"
    fi    
  fi
done

USER_ID=$($PSQL "SELECT user_id FROM users where name = '$NAME'")
INSERT_GAME=$($PSQL "INSERT INTO games (guess_count, user_id) values ($COUNT,$USER_ID)")
echo -e "\nYou guessed it in $COUNT tries. The secret number was $SECRET_NUMBER. Nice job!"
