# Titan graph databse docker image

Titan is an opensource free scalable graph database optimized for storing and querying graphs containing hundreds of billions of vertices and edges distributed across a multi-machine cluster. Titan is a transactional database that can support thousands of concurrent users executing complex graph traversals in real time

This docker image instantiaties a Titan graph database that is capable of integrating with an ElasticSearch container (Indexing) and a Cassandra container (Storage). 

The concepts used here can be extended to support any other storage or indexing backend, for that you would need to modify the run.sh file to suit your needs. The titan docker image builds the full version of titan, hence support to the storage / indexing engine is mearly configuration and modifications of configuration to suit the needs.   

The default distribution of Titan runs on a single node, with this docker image, it is possible to hook onto the mostly used storage and indexing dependencies of titan (Cassandra and ElasticSearch respectively).

Thanks to Docker. It is possible to realize a separation of concerns at the same time co-locate the backend and titan-server as suggested by the authors of the database. 

Note: the use of Docker is not endorsed by the authors of the database, but they suggested to have the storage node and titan-server communicate over localhost. In this docker scenario, I don't think there is any additional cost we have to look at!!

## Titan

Using this project, you can build titan from any specific tag / branch as per your wish. Supported directly by the configuration in the Dockerfile: 
```
# search for the following entries and modify them as necessary.
ENV TITAN_VERSION="0.9.0-SNAPSHOT"
ENV TITAN_BRANCH="titan09"
```
You may even buid a specific container using a specific commit from titan code branch. For this you would need to update the the RUN command where the git checkout is performed. 

If you want to build the titan from your fork, because you have done some changes to the open source code in your forke? no worries, just change the git repository path in the container where it is obtaining the package from and you are done. 

You can find more details about titan at its [page](http://thinkaurelius.github.io/titan/) or the [live forum](https://groups.google.com/forum/#!forum/aureliusgraphs).

Note: If you wish to build titan from a older version/ branch/ tag, please make sure that you have the correct version of the JDK in the Dockerfile. If you are modern enough to use Docker, I wouldn't expect you to build a older version of titan though. Ofcourse, it is your business and your decision :) 

## Tinkerpop and Gremlin

[TinkerPop3](http://tinkerpop.incubator.apache.org/) provides graph computing capabilities for both graph databases (OLTP) and graph analytic systems (OLAP) under the Apache2 license.

This project enables you to customize the version of Tinkerpop3 you want to depend upon. The current implementation always fetches the latest branch from the master and builds it. 

In case you need a specific tag/ branch, please feel free to modify the Dockerfile using the titan portion of the git checkouts as example. If you don't even want to deal with building Tinkerpop3 and wish to directly titan, please change the flag to value other than YES. 
```
ENV CUSTOMIZE_TINKERPOP="YES"
```

## Running

The minimum system requirements for this stack is 1 GB with 2 cores.

Run the required external dependencies, in our case : [Cassandra](https://github.com/docker-library/cassandra) and [ElasticSearch](https://github.com/docker-library/elasticsearch). Following are the snippets to run theese nodes, but I would encourage you to go to the respective github projects to get the latest and relevant instructions

```
# I am using the 2.0 version of cassandra and 1.5 version of elasticsearch. 
# At the moment these are the versions supported by titan-0.9.0-M2. 
# If the versions change, please feel free to use the correct versions
docker run --name cas1 -d cassandra:2.0
docker run -d --name elas1 elasticsearch:1.5
docker run -d -P --name mytitan --link elas1:elasticsearch --link cas1:cassandra <YOUR TITAN IMAGE>
```
If you wish to run Cassandra / Elasticsearch as clusters of their own, please refer to the documentation from the above mentioned project. For simplicity, I am omitting that topic here. 

When running in docker containers, I would encourage you to mount the data directories in your host filesystem. This you can do as follows:
```
docker run -d --name cas1 -v /mnt/Share/titandb/cassdata:/var/lib/cassandra/data cassandra:2.0
docker run -d --name elas1 -v /mnt/Share/titandb/es_index_data:/usr/share/elasticsearch/data elasticsearch:1.5
```

Following is a visual depiction of how the whole thing would look like:
![docker_topology](https://cloud.githubusercontent.com/assets/9419954/9651888/b36eb066-5233-11e5-8e59-fbf3b811d378.jpg)

One more thing to note is, when you are using the docker containers as above with mounted file system, you should be aware of the facts mentioned in the [stackoverflow thread](http://stackoverflow.com/questions/16549833/cassandra-commit-and-recovery-on-a-single-node). I've spent good 2 days hitting around the bush to figure this out. [Details](https://groups.google.com/forum/#!topic/aureliusgraphs/VhLrgs4EsKo) of the issue I've faced. 

### Run on Linux with docker-compose

    docker-compose up

wait a minute and curl the server

    bin/test

access the gremlin console

    bin/gremlin

### Ports

8182: Websocket port (incase you are using the Websocket(default) version in the run.sh file)
8182: HTTP port for REST API (incase you are using the HTTP / JSON version in the run.sh file)

8184: JMX Port (You won't need to use this, probably)

To test out the REST API (over Boot2docker):

```
curl "http://docker.local:8182?gremlin=100-1"
curl "http://docker.local:8182?gremlin=g.addV('Name','Eric')"
curl "http://docker.local:8182?gremlin=g.V()"
```
For Websocket testing, you would need to have a proper application / gremlin-console. At the time of this writing, the gremlin-console coming with titan-0.9.0-M2 has some issues for remote connection. Hence I've tested using a simple Scala application connecting through gremlin-driver.

## Dependencies

I've tested this container with the following containers:

	- docker-library/cassandra: This is the Cassandra Storage backend for Titan
	- docker-library/elasticsearch: This is the ElasticSearch Indexing backend for Titan. It provides search capabilities for Titan graph datasets.

## Hurdles faced and how did I overcome
1. When using using the docker containers with mounted file system, you should be aware of the facts mentioned in the [stackoverflow thread](http://stackoverflow.com/questions/16549833/cassandra-commit-and-recovery-on-a-single-node). I've spent good 2 days hitting around the bush to figure this out. [Details](https://groups.google.com/forum/#!topic/aureliusgraphs/VhLrgs4EsKo) of the issue I've faced. 
2. Not being able to connect to the titan-server through gremlin-driver. This has been addressed by the suggestion from stephen at the [Tinkerpop3-815](https://issues.apache.org/jira/browse/TINKERPOP3-815)

