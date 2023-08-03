# Build-a-Number-Guessing-Game

For this project, I will use Bash scripting, PostgreSQL, and Git to create a number guessing game that runs in the terminal and saves user information.  

## Step 1: Create Docker-compose file

You will use docker compose to create a container docker for Postgres.  

Pls create a file `docker-compose.yaml` and a folder `number_guess_data`.    

File `docker-compose.yaml`    
```
services:
  pgdatabase:
    image: postgres:13
    environment:
      - POSTGRES_USER=root
      - POSTGRES_PASSWORD=root
      - POSTGRES_DB=number_guess
    volumes:
      - "./number_guess_data:/var/lib/postgresql/data:rw"
    ports:
      - "5432:5432"
```

To start a postgres instance, run this command:  
`sudo docker-compose up -d`

**Note:** If you want to stop that docker compose, pls enter this command: `sudo docker-compose down`  

Ensure that the .pgpass file is properly set up to avoid any password prompts. If the .pgpass file doesn't exist, create it in your home directory and set the appropriate permissions:

```
touch ~/.pgpass
chmod 600 ~/.pgpass
```

Open the .pgpass file in a text editor and add the following line with the appropriate values for your PostgreSQL server:

```
localhost:5432:number_guess:root:your_password_here
``` 

To log in to PostgreSQL with psql. Do that by entering this command in your terminal:

```
psql -h <hostname> -p <port> -U <username> -d <database>
```

## Step 2: Create table in DB

Create 2 tables `users` and `games` for DB like the below:

```
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    name VARCHAR(30)
);
```

```
CREATE TABLE games (
    game_id SERIAL PRIMARY KEY,
    guess_count INT NOT NULL,
    user_id INT NOT NULL REFERENCES users(user_id)
);
```

## Step 3: Create Bash file

And then, you will create the Bash script file `number_guess.sh`. Ensure the script has execution permission: 

```
chmod +x number_guess.sh
```

File `number_guess.sh`  

```
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

```

Execute that Bash file: `./number_guess.sh`.
This is the result:

```
number_guess=# CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    name VARCHAR(30)
);CREATE TABLE games (
    game_id SERIAL PRIMARY KEY,
    guess_count INT NOT NULL,
    user_id INT NOT NULL REFERENCES users(user_id)
);
CREATE TABLE
CREATE TABLE
number_guess=# select * from users;
 user_id | name 
---------+------
(0 rows)

number_guess=# select * from games;
 game_id | guess_count | user_id 
---------+-------------+---------
(0 rows)

number_guess=# 

```

```
$ ./number_guess.sh 
Enter your username:
Sang

Welcome, Sang! It looks like this is your first time here.

Guess the secret number between 1 and 1000:
235
It's higher than that, guess again:
300
It's higher than that, guess again:
700
It's lower than that, guess again:
500
It's higher than that, guess again:
600
It's higher than that, guess again:
650
It's lower than that, guess again:
640
It's lower than that, guess again:
620
It's higher than that, guess again:
630
It's lower than that, guess again:
624
It's higher than that, guess again:
627

You guessed it in 11 tries. The secret number was 627. Nice job!
$ ./number_guess.sh 
Enter your username:
Sang

Welcome back, Sang! You have played 1 games, and your best game took 11 guesses.

Guess the secret number between 1 and 1000:
400
It's higher than that, guess again:
600
It's lower than that, guess again:
500
It's lower than that, guess again:
450
It's lower than that, guess again:
423
It's lower than that, guess again:
413
It's higher than that, guess again:
418
It's lower than that, guess again:
415

You guessed it in 8 tries. The secret number was 415. Nice job!
$ ./number_guess.sh 
Enter your username:
An

Welcome, An! It looks like this is your first time here.

Guess the secret number between 1 and 1000:
200
It's higher than that, guess again:
400
It's higher than that, guess again:
600
It's lower than that, guess again:
500
It's lower than that, guess again:
450
It's lower than that, guess again:
425
It's lower than that, guess again:
415
It's higher than that, guess again:
419

You guessed it in 8 tries. The secret number was 419. Nice job!

```

```
number_guess=# select * from users;
 user_id | name 
---------+------
       1 | Sang
       2 | An
(2 rows)

number_guess=# select * from games;
 game_id | guess_count | user_id 
---------+-------------+---------
       1 |          11 |       1
       2 |           8 |       1
       3 |           8 |       2
(3 rows)

number_guess=# 

```

## Step 4: Dump DB into \<file>.sql

When completed, pls enter in the terminal to dump the database into a salon.sql file. It will save all the commands needed to rebuild it. Take a quick look at the file when you are done. The file will be located where the command was entered.  

```
pg_dump --clean --create --inserts --username=root -h localhost number_guess > number_guess.sql
```  

You can rebuild the database by entering in a terminal where the .sql file is.  

```
psql -h <hostname> -p <port> -U <username> -d <database> < <file>.sql
```  

Exp: `psql -h localhost -p 5432 -U root -d number_guess < number_guess.sql`