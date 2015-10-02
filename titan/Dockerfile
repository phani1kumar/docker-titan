FROM ubuntu:14.04

MAINTAINER Venkata Phani Kumar Mangipudi <phani1kumar@gmail.com>

RUN echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections
RUN apt-get purge -y openjdk*
RUN apt-get update && apt-get install -y software-properties-common python-software-properties \
	&& add-apt-repository ppa:webupd8team/java
RUN apt-get update && apt-get install -y \
	curl \
	git \
	maven \
	oracle-java8-installer \
	openssh-server \
	wget

RUN sed -i 's/required[ ]*pam_loginuid/optional\tpam_loginuid/g' /etc/pam.d/sshd \
	&& mkdir -p /var/run/sshd \
	&& echo "UserKnownHostsFile /dev/null\nStrictHostKeyChecking no\nLogLevel quiet" >> /etc/ssh/ssh_config \
	&& ssh-keygen -t dsa -P '' -f /root/.ssh/id_dsa \
	&& cat /root/.ssh/id_dsa.pub >> /root/.ssh/authorized_keys \
	&& chmod 600 /root/.ssh/id_dsa /root/.ssh/authorized_keys \
	&& chmod 644 /root/.ssh/id_dsa.pub
ENV CUSTOMIZE_TINKERPOP="NO"
RUN if [ $CUSTOMIZE_TINKERPOP -eq "YES" ]; \
then \
	git clone https://github.com/apache/incubator-tinkerpop.git; \
	cd incubator-tinkerpop/; \
fi
RUN if [ $CUSTOMIZE_TINKERPOP -eq "YES" ]; \
then \
	cd incubator-tinkerpop; \
	git checkout tags/3.0.0-incubating; \
	TINKERPOP_VERSION=$( cat pom.xml | grep "^    <version>.*</version>$" | awk -F'[><]' '{print $3}'); \
	echo "TINKERPOP_VERSION IS: $TINKERPOP_VERSION"; \
fi
#If you want to perform any quick corrections to the checked out tinkerpop repository, you could do here and mark your own version name
#RUN if [ $CUSTOMIZE_TINKERPOP -eq "YES" ]; \
#then \
#	cd incubator-tinkerpop; \
#	sed -i "s/onStartup:/onStartup: \{\/\//g" gremlin-server/scripts/generate-modern-readonly.groovy; \
#	sed -i "s/ctx.logger.info/\/\/ctx.logger.info/g" gremlin-server/scripts/generate-modern-readonly.groovy; \
#	sed -i "s/TinkerFactory.generateClassic/\/\/TinkerFactory.generateClassic/g" gremlin-server/scripts/generate-modern-readonly.groovy; \
#	sed -i "s/onStartup:/onStartup: \{\/\//g" gremlin-server/scripts/generate-modern.groovy; \
#	sed -i "s/ctx.logger.info/\/\/ctx.logger.info/g" gremlin-server/scripts/generate-modern.groovy; \
#	sed -i "s/TinkerFactory.generateClassic/\/\/TinkerFactory.generateClassic/g" gremlin-server/scripts/generate-modern.groovy; \
#	pwd; \
#fi

#Ideally you wouldn't need to specify any changes to the TINKERPOP version, if you have done any changes like in above commented
# code, you may wish to change the version, to be sure that your changes are picked up by titan build that follows
ENV TINKERPOP_VERSION="3.0.0-MY-SNAPSHOT"
RUN if [ $CUSTOMIZE_TINKERPOP -eq "YES" ]; \
then \
	cd incubator-tinkerpop; \
	sed -i "s/^    <version>.*<\/version>/    <version>$TINKERPOP_VERSION<\/version>/g" pom.xml; \
	sed -i "s/^        <version>.*<\/version>/        <version>$TINKERPOP_VERSION<\/version>/g" $(find . -maxdepth 2 -mindepth 2 -type f -name 'pom.xml'); \
	cat $(find . -maxdepth 2 -mindepth 2 -type f -name 'pom.xml') | grep "^        <version>.*<\/version>"; \
	T_VERSION=$( cat pom.xml | grep "^    <version>.*</version>$" | awk -F'[><]' '{print $3}'); \
	echo "TINKERPOP_VERSION IS: $T_VERSION"; \
fi
RUN if [ $CUSTOMIZE_TINKERPOP -eq "YES" ]; \
then \
	cd incubator-tinkerpop; \
	mvn clean install -DskipTests -Denforcer.skip=true; \
fi

ENV TITAN_VERSION="1.0.1-SNAPSHOT"
ENV TITAN_BRANCH="titan10"

RUN if [ ! -z $TITAN_BRANCH ]; \
then \
	echo "cloning the branch TITAN_BRANCH=$TITAN_BRANCH"; \
	git clone https://github.com/thinkaurelius/titan.git --branch $TITAN_BRANCH --single-branch && cd titan/; \
else \
	echo "cloning the master TITAN_BRANCH=$TITAN_BRANCH"; \
	git clone https://github.com/thinkaurelius/titan.git; \
	cd titan/; \
	git checkout tags/$TITAN_VERSION; \
fi 
RUN if [ $CUSTOMIZE_TINKERPOP -eq "YES" ]; \ 
then \
	cd titan; \
	sed -i "s/tinkerpop.version.*/tinkerpop.version>$TINKERPOP_VERSION<\/tinkerpop.version>/g" pom.xml; \
	cat pom.xml | grep tinkerpop.version; \
fi
RUN cd titan && mvn clean install -DskipTests=true -Paurelius-release -Dgpg.skip=true
RUN cd titan && rm -f conf/core-site.xml conf/mapred-site.xml \
	&& cd ../ \
	&& mv titan /usr/local/titan-$TITAN_VERSION \
	&& ln -sf /usr/local/titan-$TITAN_VERSION /usr/local/titan
ENV TITAN_DEPLOYMENT="titan-$TITAN_VERSION-hadoop1"
WORKDIR /opt/$TITAN_DEPLOYMENT
RUN find / -name $TITAN_DEPLOYMENT.zip
RUN unzip /usr/local/titan-$TITAN_VERSION/titan-dist/titan-dist-hadoop-1/target/$TITAN_DEPLOYMENT.zip -d /opt/ \
    && rm /usr/local/titan-$TITAN_VERSION/titan-dist/titan-dist-hadoop-1/target/$TITAN_DEPLOYMENT.zip

ADD run.sh /opt/$TITAN_DEPLOYMENT/

EXPOSE 8182
EXPOSE 8184

CMD /bin/sh  -e "/opt/$TITAN_DEPLOYMENT/run.sh"
