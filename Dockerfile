# Stage 0: build the gem
FROM jruby:9.2 AS build-gem

WORKDIR /build

COPY Gemfile ./
COPY logstash-service-ip-map-plugin.gemspec ./

RUN bundle install

COPY lib /build/lib

RUN gem build logstash-service-ip-map-plugin.gemspec -o ipmap.gem

# Stage 1: build logstash
FROM docker.elastic.co/logstash/logstash-oss:7.9.0

COPY --from=build-gem /build/ipmap.gem /ipmap.gem

RUN /usr/share/logstash/bin/logstash-plugin install /ipmap.gem
