#! /bin/sh

#Tested and most of it works. anything with uci doesn't work . Didnot test modifyprogramconfig though
WEBSITEAPI="https://backend-nodejs.diwash5.repl.co/input/"

## These are the symlink that needs to be created before doing anything
## The main reason for this is to reduce storage needs and prevent flash from wearing down
## So placing them in RAM
## Only checking for log.1.0 as it is created most frequently

SYMLINKFILES="/log.1.0.cdf"
if [ -e "$SYMLINKFILES" ]; then
    if [ ! -L "$SYMLINKFILES" ]
    then
        logger "File existed but is not a symlink. File deleted and Creating Symlink"
        rm /log.*
        ln -s /tmp/log.1.0.cdf /log.1.0.cdf
        ln -s /tmp/log.2.0.cdf /log.2.0.cdf
        ln -s /tmp/log.3.0.cdf /log.3.0.cdf
        ln -s /tmp/log.4.0.cdf /log.4.0.cdf
    else
        logger "Symlink is Already in Place"
    fi
else
    logger "File did not exists and the symlinks are created"
    ln -s /tmp/log.1.0.cdf /log.1.0.cdf
    ln -s /tmp/log.2.0.cdf /log.2.0.cdf
    ln -s /tmp/log.3.0.cdf /log.3.0.cdf
    ln -s /tmp/log.4.0.cdf /log.4.0.cdf
fi

#### Making a loop that the main program resides in and
while :
do
    sleep 3660s
    
    # Main Program begins
    #--------------- cleaning the data as required-------------------------------
    # cleaning the data as recieved from bandwidthd
    # keeping the NA in awk so that i can replace things later on without messing up the column
    grep -v  0.0.0.0 /tmp/log.3.*.cdf | awk -F "," '{print $1, "NA", "NA" ,$2,$3,$10}' > /tmp/cleanlog
    # Making a Good & Combined Dhcp file
    ( awk '{print $3,$4,$2}' /tmp/dhcp.leases && tail +2 /tmp/hosts/dhcp.cfg* | awk '{print $1,$2,"NA"}' ) > /tmp/cleandhcp
    #--------------------------Deleting The File-----------------------------------
    # Now that i have my data , i can delete the log files from the drive to save storage and have accurate data for the next time
    # I'm deleting as i dont wanna compare if i have sent it before
    # I already have a backup of the file in cleanlog file
    rm /tmp/log.*
    
    #Replacing the IP with IP,Name & MAC
    while read line
    do
        USERIP=$( echo "$line" | awk '{print $1}' )
        sed -i 's/'"$USERIP"' NA NA/'"$line"'/g' /tmp/cleanlog
    done < /tmp/cleandhcp
    # Making a Json Now by reading each line of cleanlog file and sending the json to the url
    while read line
    do
        SENDME=$(echo "$line" | awk '{printf "{ \"ip\" : \""$1"\" , \"deviceName\" : \""$2"\" , \"macaddress\" : \""$3"\" , \"date\" : \""$4"\" , \"upload\" : \""$5"\" , \"download\" : \""$6"\"  }"}')
        RESPONSE=$( curl -s --insecure --location --request POST "$WEBSITEAPI" \
            --header 'Content-Type: application/json' \
        --data-raw "$SENDME" )
        sleep 1s
    done < /tmp/cleanlog
    logger "Data is sent to the server and local file is deleted"
    
done