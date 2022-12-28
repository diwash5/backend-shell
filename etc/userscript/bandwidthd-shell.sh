#! /bin/sh

#Tested and most of it works. anything with uci doesn't work .
WEBSITEAPI="https://backend-nodejs.diwash5.repl.co/input/"
WEBSITETOKEN="R4A"

# Check if the symbolic link exists
if [ ! -L "/log.1.0.cdf" ]; then
    # Create the symbolic link , delete if there are existing file there
    for i in 1 2 3 4
    do
        ln -sf /tmp/log.${i}.0.cdf /log.${i}.0.cdf
    done
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
        SENDME=$(echo "$line" | awk '{print "{ \"ip\" : \""$1"\" , \"deviceName\" : \""$2"\" , \"macaddress\" : \""$3"\" , \"date\" : \""$4"\" , \"upload\" : \""$5"\" , \"download\" : \""$6"\" ,\"token\" : \"""'$WEBSITETOKEN'""\" \}"}')
        RESPONSE=$( curl -s --insecure --location --request POST "$WEBSITEAPI" \
            --header 'Content-Type: application/json' \
        --data-raw "$SENDME" )
        sleep 1s
    done < /tmp/cleanlog
    logger "Data is sent to the server and local file is deleted"
    
done