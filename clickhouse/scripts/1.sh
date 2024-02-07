HOST=`hostname -s` &&
DOMAIN=`hostname -d` &&
CLIENT_PORT=2181 &&
SERVER_PORT=2888 &&
ELECTION_PORT=3888 &&
PROMETHEUS_PORT=7000 &&
ZOO_DATA_DIR=/var/lib/zookeeper/data &&
ZOO_DATA_LOG_DIR=/var/lib/zookeeper/datalog &&
{
  echo "clientPort=${CLIENT_PORT}"
  echo 'tickTime=2000'
  echo 'initLimit=300'
  echo 'syncLimit=10'
  echo 'maxClientCnxns=2000'
  echo 'maxTimeToWaitForEpoch=2000'
  echo 'maxSessionTimeout=60000000'
  echo "dataDir=${ZOO_DATA_DIR}"
  echo "dataLogDir=${ZOO_DATA_LOG_DIR}"
  echo 'autopurge.snapRetainCount=10'
  echo 'autopurge.purgeInterval=1'
  echo 'preAllocSize=131072'
  echo 'snapCount=3000000'
  echo 'leaderServes=yes'
  echo 'standaloneEnabled=false'
  echo '4lw.commands.whitelist=*'
  echo 'metricsProvider.className=org.apache.zookeeper.metrics.prometheus.PrometheusMetricsProvider'
  echo "metricsProvider.httpPort=${PROMETHEUS_PORT}"
  echo "skipACL=true"
  echo "fastleader.maxNotificationInterval=10000"
} > /conf/zoo.cfg &&
{
  echo "zookeeper.root.logger=CONSOLE"
  echo "zookeeper.console.threshold=INFO"
  echo "log4j.rootLogger=\${zookeeper.root.logger}"
  echo "log4j.appender.CONSOLE=org.apache.log4j.ConsoleAppender"
  echo "log4j.appender.CONSOLE.Threshold=\${zookeeper.console.threshold}"
  echo "log4j.appender.CONSOLE.layout=org.apache.log4j.PatternLayout"
  echo "log4j.appender.CONSOLE.layout.ConversionPattern=%d{ISO8601} - %-5p [%t:%C{1}@%L] - %m%n"
} > /conf/log4j.properties &&
echo 'JVMFLAGS="-Xms128M -Xmx4G -XX:ActiveProcessorCount=8 -XX:+AlwaysPreTouch -Djute.maxbuffer=8388608 -XX:MaxGCPauseMillis=50"' > /conf/java.env &&
if [[ $HOST =~ (.*)-([0-9]+)$ ]]; then
    NAME=${BASH_REMATCH[1]} &&
    ORD=${BASH_REMATCH[2]};
else
    echo "Failed to parse name and ordinal of Pod" &&
    exit 1;
fi &&
mkdir -pv ${ZOO_DATA_DIR} &&
mkdir -pv ${ZOO_DATA_LOG_DIR} &&
whoami &&
chown -Rv zookeeper "$ZOO_DATA_DIR" "$ZOO_DATA_LOG_DIR" &&
export MY_ID=$((ORD+1)) &&
echo $MY_ID > $ZOO_DATA_DIR/myid &&
for (( i=1; i<=$SERVERS; i++ )); do
    echo "server.$i=$NAME-$((i-1)).$DOMAIN:$SERVER_PORT:$ELECTION_PORT" >> /conf/zoo.cfg;
done &&
if [[ $SERVERS -eq 1 ]]; then
    echo "group.1=1" >> /conf/zoo.cfg;
else
    echo "group.1=1:2:3" >> /conf/zoo.cfg;
fi &&
for (( i=1; i<=$SERVERS; i++ )); do
    WEIGHT=1
    if [[ $i == 1 ]]; then
      WEIGHT=10
    fi
    echo "weight.$i=$WEIGHT" >> /conf/zoo.cfg;
done &&
zkServer.sh start-foreground
