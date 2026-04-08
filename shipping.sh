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
MYSQL_HOST=mysql.raviteja.store
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

dnf install maven -y


id roboshop &>>$LOG_FILE

if [ $? -ne 0 ]; then

    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "creating system user"
else
    echo -e "user already exist ...$Y skipping $N"
fi

mkdir -p /app
VALIDATE $? "creating app directory"

curl -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip  &>>$LOG_FILE
VALIDATE $? "download shipping application"
cd /app 
VALIDATE $? "changing to  app directory"
rm -rf /app/*
VALIDATE $? "removing existing code"

unzip /tmp/shipping.zip &>>$LOG_FILE
VALIDATE $? "unzip shipping"

mvn clean package 
mv target/shipping-1.0.jar shipping.jar



cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service
VALIDATE $? "copy systemctl service"

systemctl daemon-reload

systemctl enable shipping &>>$LOG_FILE
VALIDATE $? "Enable shipping"


dnf install mysql -y

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 -e "use cities" &>>$LOG_FILE

if [ $? -ne 0 ]; then
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql &>>$LOG_FILE
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql &>>$LOG_FILE 
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql &>>$LOG_FILE
else
    echo -e "Shipping data is already loaded ... $Y SKIPPING $N"
fi

systemctl start shipping &>>$LOG_FILE
VALIDATE $? "STARTING shipping"






systemctl restart shipping &>>$LOG_FILE
VALIDATE $? "Restarted shipping"











END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME))
echo -e "Script executed in: $Y $TOTAL_TIME Seconds $N"

