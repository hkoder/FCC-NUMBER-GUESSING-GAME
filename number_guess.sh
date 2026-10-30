#!/bin/bash

#adding psql variable to query the database
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

#generate secret number
SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))

#Prompt the user for the username
echo "Enter your username:"
read USERNAME

#check if the user exists
USER_DATA=$($PSQL "SELECT user_id, games_played, best_game FROM users WHERE username='$USERNAME'")

if [[ -z $USER_DATA ]]
  then
  #greet new user
  echo -e "\nWelcome, $USERNAME! It looks like this is your first time here."
  #insert user into the database
  INSERT_USER=$($PSQL "INSERT INTO users(username) VALUES('$USERNAME')")
  #fetch new user's id
  USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME'")
  else
  # If user is returning, read variables in one shot using '|' as the separator
  IFS='|' read -r USER_ID GAMES_PLAYED BEST_GAME <<< "$USER_DATA"
  #greet returning user
  echo -e "\nWelcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

#core game loop
echo -e "\nGuess the secret number between 1 and 1000:"
NUMBER_OF_GUESSES=0

while true
do
  read GUESS
  ((NUMBER_OF_GUESSES++))

  # Input Validation: Is guess an integer?
  if [[ ! $GUESS =~ ^[0-9]+$ ]]
  then
    echo "That is not an integer, guess again:"
    continue
  fi
  # Check guess matching
  if [[ $GUESS -eq $SECRET_NUMBER ]]
  then
    break
  elif [[ $GUESS -gt $SECRET_NUMBER ]]
  then
    echo "It's lower than that, guess again:"
  else
    echo "It's higher than that, guess again:"
  fi
done

# Game Over & Database Synchronization
echo -e "\nYou guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"

# Log the match statistics in games table
INSERT_GAME_RESULT=$($PSQL "INSERT INTO games(user_id, number_of_guesses) VALUES($USER_ID, $NUMBER_OF_GUESSES)")

# Increment games_played count
UPDATE_GAMES_COUNT=$($PSQL "UPDATE users SET games_played = games_played + 1 WHERE user_id=$USER_ID")

# Update personal high score record if applicable
if [[ -z $BEST_GAME || $NUMBER_OF_GUESSES -lt $BEST_GAME ]]
then
  UPDATE_BEST_GAME=$($PSQL "UPDATE users SET best_game = $NUMBER_OF_GUESSES WHERE user_id=$USER_ID")
fi
