IFS=;
MNTR=$(exec 3<>/dev/tcp/127.0.0.1/2181 ; printf "mntr" >&3 ; tee <&3; exec 3<&- ;);
while [[ "$MNTR" == "This ZooKeeper instance is not currently serving requests" ]];
do
  echo "wait mntr works";
  sleep 1;
  MNTR=$(exec 3<>/dev/tcp/127.0.0.1/2181 ; printf "mntr" >&3 ; tee <&3; exec 3<&- ;);
done;
STATE=$(echo -e $MNTR | grep zk_server_state | cut -d " " -f 2);
if [[ "$STATE" =~ "leader" ]]; then
  echo "check leader state";
  SYNCED_FOLLOWERS=$(echo -e $MNTR | grep zk_synced_followers | awk -F"[[:space:]]+" "{print \$2}" | cut -d "." -f 1);
  if [[ "$SYNCED_FOLLOWERS" != "0" ]]; then
    ./bin/zkCli.sh ls /;
    exit $?;
  else
    exit 0;
  fi;
elif [[ "$STATE" =~ "follower" ]]; then
  echo "check follower state";
  PEER_STATE=$(echo -e $MNTR | grep zk_peer_state);
  if [[ "$PEER_STATE" =~ "following - broadcast" ]]; then
    ./bin/zkCli.sh ls /;
    exit $?;
  else
    exit 1;
  fi;
else
  exit 1;
fi
