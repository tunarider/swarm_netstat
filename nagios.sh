#/bin/bashsh
NETSTATS=$(/usr/local/bin/docker_netstat -n $1| grep "Total" | awk -F ":" '{print $2}' |tr -d ' ')

WARNING=200
CRITICAL=230

if [ $NETSTATS -gt $WARNING ]; then
  echo "WARNING - $1 exceeded $WARNING"
  exit 1

elif [ $NETSTATS -gt $CRITICAL ]; then
  echo "CRITICAL - $1 exceeded $CRITICAL"
  exit 2
else
  echo "OK : $1 is $NETSTATS"
  exit 0
fi
