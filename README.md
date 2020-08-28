# app-http-logger-logstash-service

This repository contains a Logstash plugin that builds a reverse-DNS mapping of Docker IPs to Docker-Compose service names, and uses this mapping to enrich HTTP log items with the correct name for their peer.

The Dockerfile builds a Logstash image with this plugin already installed (as the installation is quite slow).

## Building the plugin separately

This plugin can only be built with JRuby and requires the Bundler gem.
First, install the dependencies:
```sh
bundle install
```
Then build the gem:
```sh
gem build logstash-service-ip-map-plugin.gemspec
```
It may be installed in logstash using the `logstash-plugin install` utility.

