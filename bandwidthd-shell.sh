#! /bin/sh

#Tested and most of it works. anything with uci doesn't work . Didnot test modifyprogramconfig though

WEBSITEAPI="http://192.168.39.155:3600/input/"

# this module configures the bandwidthd , only meant to be used for the first time
modifyprogramconfig () {
    # setting subset i.e your ip range, obtaining it from uci ; Mine is 192.168.39.1
    MYSUBSET = $( uci get network.lan.ipaddr )
    uci set bandwidthd.@bandwidthd[0].subnets="$MYSUBSET"
    # setting the output file of bandwidthd
    uci set bandwidthd.@bandwidthd[0].output_cdf=true

}


## Getting the program refresh retrival
## and setting the script runnung interval to 1 minute after that so that the program is done outputing . This is not implemented yet
PROGRAMINTERVAl=$( uci get bandwidthd.@bandwidthd[0].meta_refresh )
SCRIPTINTERVAL=$((PROGRAMINTERVAl + 60))
# Main Program begins

#--------------- cleaning the data as required-------------------------------

# cleaning the data as recieved from bandwidthd
# keeping the NA in awk so that i can replace things later on without messing up the column

cat /log.1.*.cdf | grep -v  0.0.0.0 | awk -F "," '{print $1, "NA", "NA" ,$2,$3,$10}' > /tmp/cleanlog

# Making a Good & Combined Dhcp file
( awk '{print $3,$4,$2}' /tmp/dhcp.leases && tail +2 /tmp/hosts/dhcp.cfg* | awk '{print $1,$2,"NA"}' ) > /tmp/cleandhcp

#--------------------------Deleting The File----------------------------------- 
# Now that i have my data , i can delete the log files from the drive to save storage and have accurate data for the next time
# I'm deleting as i dont wanna compare if i have sent it before

#rm /log.*


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
echo $RESPONSE
sleep 1s
done < /tmp/cleanlog


## These are the symlink that needs to be created before doing anything
## ln -s /tmp/log.1.0.cdf /log.1.0.cdf
## ln -s /tmp/log.2.0.cdf /log.2.0.cdf
## ln -s /tmp/log.3.0.cdf /log.3.0.cdf
## ln -s /tmp/log.4.0.cdf /log.4.0.cdf