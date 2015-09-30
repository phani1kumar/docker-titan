#!/bin/bash

BIN=./bin
SLEEP_INTERVAL_S=2

# wait_for_startup friendly_name host port timeout_s
wait_for_startup() {
    local friendly_name="$1"
    local host="$2"
    local port="$3"
    local timeout_s="$4"

    local now_s=`date '+%s'`
    local stop_s=$(( $now_s + $timeout_s ))
    local status=

    echo -n "Connecting to $friendly_name ($host:$port)"
    while [ $now_s -le $stop_s ]; do
        echo -n .
        $BIN/checksocket.sh $host $port >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo " OK (connected to $host:$port)."
            return 0
        fi
        sleep $SLEEP_INTERVAL_S
        now_s=`date '+%s'`
    done

    echo " timeout exceeded ($timeout_s seconds): could not connect to $host:$port" >&2
    return 1
}

ELASTICSEARCH_STARTUP_TIMEOUT_S=60
CASSANDRA_STARTUP_TIMEOUT_S=60

wait_for_startup Elasticsearch \
	$ELASTICSEARCH_PORT_9200_TCP_ADDR \
	$ELASTICSEARCH_PORT_9200_TCP_PORT \
	$ELASTICSEARCH_STARTUP_TIMEOUT_S || {
   return 1
}

wait_for_startup Cassandra \
	$CASSANDRA_PORT_9160_TCP_ADDR \
	$CASSANDRA_PORT_9160_TCP_PORT \
	$CASSANDRA_STARTUP_TIMEOUT_S || {
	return 1
}

# use cassandra backed db instead of berkeleyje
sed -i "s/host: localhost/host: 0.0.0.0/g" conf/gremlin-server/gremlin-server.yaml
sed -i "s/titan-berkeleyje-server.properties/titan-cassandra-es-server.properties/g" conf/gremlin-server/gremlin-server.yaml

# Want to have JSON / Http access to your titan-server? then enable the following two lines
#sed -i "s/channelizer: org.apache.tinkerpop.gremlin.server.channel.WebSocketChannelizer/channelizer: org.apache.tinkerpop.gremlin.server.channel.HttpChannelizer/g" conf/gremlin-server/gremlin-server.yaml
#sed -i "s/serializers:/serializers:\n  - { className: org.apache.tinkerpop.gremlin.driver.ser.JsonMessageSerializerGremlinV1d0 }\n  - { className: org.apache.tinkerpop.gremlin.driver.ser.JsonMessageSerializerV1d0, config: { useMapperFromGraph: graph } }/g" conf/gremlin-server/gremlin-server.yaml

# Following two lines will enable the Websocket access to your titan-server! Meaning, you can connect using your gremlin-driver from your client applications
# IMPORTANT - Please comment out the following two lines in case you are enabling JSON/ HTTP access from the above section.
# they both can't co-exist
sed -i "s/GraphSONMessageSerializerGremlinV1d0.*/GraphSONMessageSerializerGremlinV1d0 \}/g" conf/gremlin-server/gremlin-server.yaml
sed -i "s/GraphSONMessageSerializerV1d0.*/GraphSONMessageSerializerV1d0 \}/g" conf/gremlin-server/gremlin-server.yaml


# create the backing file
cp conf/titan-cassandra-es.properties conf/gremlin-server/titan-cassandra-es-server.properties
sed -i "s/storage.backend=cassandrathrift/storage.backend=cassandra/g" conf/gremlin-server/titan-cassandra-es-server.properties
sed -i "s/storage.hostname=127.0.0.1/storage.hostname=$CASSANDRA_PORT_9160_TCP_ADDR/g" conf/gremlin-server/titan-cassandra-es-server.properties
sed -i "s/client-only=true/client-only=false/g" conf/gremlin-server/titan-cassandra-es-server.properties
sed -i "s/index.search.hostname=127.0.0.1/index.search.hostname=$ELASTICSEARCH_PORT_9200_TCP_ADDR/g" conf/gremlin-server/titan-cassandra-es-server.properties
cat <<EOF >> conf/gremlin-server/titan-cassandra-es-server.properties
# Instead of individually adjusting the field mapping for every key added 
# to a mixed index, one can instruct Titan to always set the field name in 
# the external index to be identical to the property key name. 
# This is accomplished by enabling the configuration option map-name which 
# is configured per indexing backend. If this option is enabled for a particular 
# indexing backend, then all mixed indexes defined against said backend will use 
# field names identical to the property key names.

# However, this approach has two limitations: 
# 1) The user has to ensure that the property key names are valid field names 
# for the indexing backend and 
# 2) renaming the property key will NOT rename the field name in the index which 
# can lead to naming collisions that the user has to be aware of and avoid.
index.search.map-name=true
gremlin.graph=com.thinkaurelius.titan.core.TitanFactory
EOF

$BIN/gremlin-server.sh conf/gremlin-server/gremlin-server.yaml
