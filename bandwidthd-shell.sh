#! /bin/sh


#This Code is not tested .. Please do not use s









# this module configures the bandwidthd , only meant to be used for the first time
modifyprogramconfig () {
    # setting subset i.e your ip range, obtaining it from uci ; Mine is 192.168.39.1
    MYSUBSET = $( uci get network.lan.ipaddr )
    uci set bandwidthd.@bandwidthd[0].subnets="$MYSUBSET"
    # setting the output file of bandwidthd 
    uci set bandwidthd.@bandwidthd[0].output_cdf=true

}


## Getting the program refresh retrival 
## and setting the script runnung interval to 1 minute after that so that the program is done outputing
PROGRAMINTERVAl =$( uci get bandwidthd.@bandwidthd[0].meta_refresh )
SCRIPTINTERVAL = $PROGRAMINTERVAl + 60

# Main Program begins

# cleaning the data as required

# cleaning the data as recieved from bandwidthd
# keeping the NA in awk so that i can replace things later on without messing up the column
cat /log.1.*.cdf | grep -v  0.0.0.0 | awk -F "," '{print $1, "NA", "NA" ,$2,$3,$10}' > /tmp/Dprogram/cleanlog

# Making a Good & Combined Dhcp file
( awk '{print $3,$4,$2}' /tmp/dhcp.leases && tail +2 /tmp/hosts/dhcp.cfg* | awk '{print $1,$2,"NA"}' ) > /tmp/Dprogram/cleandhcp


# Now that i have my data , i can delete the log files from the drive to save storage and have accurate data for the next time
# I'm deleting as i dont wanna compare if i have sent it before


#Replacing the IP with IP,Name & MAC  
while read line
do
USERIP=$( echo "$line" | awk '{print $1}' )
sed -i 's/'"$USERIP"' NA NA/'"$line"'/g' /tmp/Dprogram/cleanlog
done < /tmp/Dprogram/cleandhcp


# Making a Json Now and outputing it to terminal
while read line
do
echo "$line" | awk '{printf "{ \"ip\" : \""$1"\" , \"name\" : \""$2"\" , \"macaddress\" : \""$3"\" , \"date\" : \""$4"\" , \"sent\" : \""$5"\" , \"recieved\" : \""$6"\"  }"}'
sleep 1s
done < /tmp/Dprogram/cleanlog







