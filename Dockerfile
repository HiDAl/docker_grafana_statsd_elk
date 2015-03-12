#
# Based on:
#   https://github.com/scullxbones/docker_grafana_statsd_elk
# Who is Based on
#	https://github.com/cazcade/docker-grafana-graphite
#
#
FROM debian:wheezy
MAINTAINER Pablo Alcantar <palcantar@lemontech.cl>

RUN echo 'deb http://http.debian.net/debian wheezy-backports main' >> /etc/apt/sources.list.d/wheezy-backports.list

RUN apt-get -y update
RUN apt-get -y install ca-certificates wget
# RUN wget -qO - https://packages.elasticsearch.org/GPG-KEY-elasticsearch | apt-key add -

# Logstash
# RUN echo 'deb http://packages.elasticsearch.org/logstash/1.4/debian stable main' >> /etc/apt/sources.list.d/logstash.list
RUN apt-get -y update &&\
    apt-get -y upgrade

# Prerequisites
RUN apt-get -y --no-install-recommends install python python-colorama python-django-tagging python-simplejson python-memcache python-ldap python-cairo python-pysqlite2 python-support python-pip gunicorn python-dev libpq-dev build-essential
RUN apt-get -y --no-install-recommends install supervisor nginx-light git wget curl
# Node
RUN apt-get -y --no-install-recommends install software-properties-common
RUN apt-get -y --no-install-recommends -t wheezy-backports install nodejs
# Elasticsearch
# RUN apt-get -y --no-install-recommends install openjdk-7-jre adduser

# Install Elasticsearch
# RUN groupadd -f -g 101 elasticsearch && useradd -u 1001 -g elasticsearch elasticsearch &&\
#     mkdir -p /home/elasticsearch && chown -R elasticsearch:elasticsearch /home/elasticsearch &&\
#     cd ~ && wget https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.4.0.deb &&\
#     dpkg -i elasticsearch-1.4.0.deb && rm elasticsearch-1.4.0.deb

# Install Redis, Logstash
# RUN (wget -O - http://packages.elasticsearch.org/GPG-KEY-elasticsearch | apt-key add -) && apt-get -y update
# RUN apt-get -y install --no-install-recommends redis-server logstash

# Install StatsD
RUN mkdir /src && git clone https://github.com/etsy/statsd.git /src/statsd

# Install Whisper, Carbon and Graphite-Web
RUN pip install Twisted==11.1.0
RUN pip install Django==1.5
RUN pip install whisper
RUN pip install --install-option="--prefix=/var/lib/graphite" --install-option="--install-lib=/var/lib/graphite/lib" carbon
RUN pip install --install-option="--prefix=/var/lib/graphite" --install-option="--install-lib=/var/lib/graphite/webapp" graphite-web

# Install Grafana
RUN mkdir /src/grafana && cd /src/grafana &&\
 wget http://grafanarel.s3.amazonaws.com/grafana-1.9.1.tar.gz &&\
 tar xzvf grafana-1.9.1.tar.gz --strip-components=1 && rm grafana-1.9.1.tar.gz

# Install Kibana
# RUN mkdir /src/kibana && cd /src/kibana &&\
#  wget https://download.elasticsearch.org/kibana/kibana/kibana-4.0.1-linux-x64.tar.gz &&\
#  tar xzvf kibana-4.0.1-linux-x64.tar.gz --strip-components=1 && rm kibana-4.0.1-linux-x64.tar.gz

# Configure Elasticsearch
# ADD ./elasticsearch/run /usr/local/bin/run_elasticsearch
# RUN chmod +x /usr/local/bin/run_elasticsearch &&\
#     mkdir -p /logs/elasticsearch && chown elasticsearch:elasticsearch /logs/elasticsearch &&\
#     mkdir -p /data/elasticsearch && chown elasticsearch:elasticsearch /data/elasticsearch &&\
#     mkdir -p /tmp/elasticsearch && chown elasticsearch:elasticsearch /tmp/elasticsearch

# Configure Logstash
# ADD ./logstash/001-redis-input.conf /etc/logstash/conf.d/001-redis-input.conf
# ADD ./logstash/002-tcp-json-input.conf /etc/logstash/conf.d/002-tcp-json-input.conf
# ADD ./logstash/999-elasticsearch-output.conf /etc/logstash/conf.d/999-elasticsearch-output.conf

# Confiure StatsD
ADD ./statsd/config.js /src/statsd/config.js

# Configure Whisper, Carbon and Graphite-Web
ADD ./graphite/initial_data.json /var/lib/graphite/webapp/graphite/initial_data.json
ADD ./graphite/local_settings.py /var/lib/graphite/webapp/graphite/local_settings.py
ADD ./graphite/carbon.conf /var/lib/graphite/conf/carbon.conf
ADD ./graphite/storage-schemas.conf /var/lib/graphite/conf/storage-schemas.conf
ADD ./graphite/storage-aggregation.conf /var/lib/graphite/conf/storage-aggregation.conf
RUN mkdir -p /var/lib/graphite && chown -R www-data:www-data /var/lib/graphite &&\
    mkdir -p /data/graphite && chown www-data:www-data /data/graphite &&\
    rm -rf /var/lib/graphite/storage/whisper && ln -s /data/graphite /var/lib/graphite/storage/whisper

RUN cd /var/lib/graphite/webapp/graphite && python manage.py syncdb --noinput && chown -R www-data:www-data /var/lib/graphite

# Configure Grafana
ADD ./grafana/config.js /src/grafana/config.js

# Configure Kibana
ADD ./kibana/config.js /src/kibana/config.js

# Configure nginx and supervisord
ADD ./nginx/nginx.conf /etc/nginx/nginx.conf
ADD ./supervisord.conf /etc/supervisor/conf.d/supervisord.conf
RUN mkdir -p /logs/supervisor && touch /logs/supervisor/supervisord.log &&\
    mkdir -p /logs/nginx && chown www-data:www-data /logs/nginx

# Grafana
EXPOSE 80

# Kibana
# EXPOSE 81

# Logstash TCP
# EXPOSE 4560

# Graphite (Carbon)
EXPOSE 2003

# Graphite web-ui
EXPOSE 8000

# Redis
# EXPOSE 6379

# Elasticserach
# EXPOSE 9200

# StatsD
EXPOSE 8125/udp
EXPOSE 8126

# VOLUME ["/data/graphite","/data/elasticsearch",]
VOLUME [ "/data/graphite" ]
VOLUME ["/logs/elasticsearch","/logs/supervisor","/logs/nginx"]

CMD ["/usr/bin/supervisord","-c","/etc/supervisor/supervisord.conf"]
