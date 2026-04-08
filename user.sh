#!/bin/bash
#
USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
SCRIPT_DIR=$PWD
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log" # /var/log/shell-script/16-logs.log

mkdir -p $LOGS_FOLDER
echo "Script started executed at: $(date)" | tee -a $LOG_FILE
START_TIME=$(date +%s)
if [ $USERID -ne 0 ]; then
    echo "ERROR:: Please run this script with root privelege"
    exit 1 # failure is other than 0
fi

VALIDATE(){ # functions receive inputs through args just like shell script args
    if [ $1 -ne 0 ]; then
        echo -e "$2 ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    else
        echo -e " $2 ... $G SUCCESS $N" | tee -a $LOG_FILE
    fi
}

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "disabling nodeJS"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "enabling nodeJS"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Installing NodeJS"


id roboshop &>>$LOG_FILE

if [ $? -ne 0 ]; then

    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "creating system user"
else
    echo -e "user already exist ...$Y skipping $N"
fi

mkdir -p /app
VALIDATE $? "creating app directory"

curl -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip  &>>$LOG_FILE
VALIDATE $? "download user application"
cd /app 
VALIDATE $? "changing to  app directory"
rm -rf /app/*
VALIDATE $? "removing existing code"
unzip /tmp/user.zip &>>$LOG_FILE
VALIDATE $? "unzip user"

npm install &>>$LOG_FILE
VALIDATE $? "install dependencies"

cp $SCRIPT_DIR/user.service /etc/systemd/system/user.service
VALIDATE $? "copy systemctl service"

systemctl daemon-reload

systemctl enable user &>>$LOG_FILE
VALIDATE $? "Enable user"



systemctl restart user &>>$LOG_FILE
VALIDATE $? "Restarted user"

systemctl start user &>>$LOG_FILE
VALIDATE $? "STARTING USER"











END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME))
echo -e "Script executed in: $Y $TOTAL_TIME Seconds $N"

