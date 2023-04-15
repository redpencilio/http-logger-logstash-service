# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"
require 'cgi'

class LogStash::Filters::IpMap < LogStash::Filters::Base

  config_name "ipmap"

# These values are hardcoded for now because of the need to switch source and dest ip fields based on direction
#  # The fields where the IP and domain name of a service can be found. Used to fill the IP -> domain name map
#  config :source_domain_field, :validate => :string, :required => true
#  config :source_ip_field, :validate => :string, :required => true
#
#  # The field containing the IP to be resolved using the map we built
#  config :dest_ip_field, :validate => :string, :required => true
#  # The field where the domain name associated with the destination IP will be inserted
#  config :dest_domain_field, :validate => :string, :required => true

  # Mapping of IPs to Docker service names/domain names
  attr_accessor :mapping

  public
  def register
    @mapping = Hash.new
  end

  public
  def filter(event)
    begin
      response_content_types = event.get("[http][response][headers][content-type]")
      request_content_types = event.get("[http][request][headers][content-type]")
      if response_content_types == "application/sparql-results+json"
        # A SPARQL query was sent, let's enrich it'
        if request_content_types && request_content_types == "application/sparql-query"
          # POST with content-type sparql-update, get body
          event.set("[http][request][sparql]", event.get("[http][request][body]"))
        elsif event.get("[url][query]") && event.get("[url][query]")
          query_map = CGI::parse(event.get("[url][query]"))
          query = query_map["query"] || query_map["update"]
          event.set("[http][request][sparql]", query) if query.first && query.first
        else
        end
      end
    rescue
      puts "Failed to process SPARQL query for #{event}"
    end

    begin
      my_ip = ""
      other_ip = ""

      case event.get("[network][direction]")
      when "internal" # Don't do anything with 'internal' (= container to itself) requests
        filter_matched(event)
        return

      when "outbound" # Outbound means we are the source
        my_ip = event.get("[source][ip]")
        other_ip = event.get("[destination][ip]")

      when "inbound" # Inbound means we are the destination
        my_ip = event.get("[destination][ip]")
        other_ip = event.get("[source][ip]")

      end

      if !@mapping[my_ip]
        @logger.info("Mapping for #{my_ip} set to #{event.get("[fields][compose_service]")}")
        @mapping[my_ip] = event.get("[fields][compose_service]")
      elsif @mapping[my_ip] && mapping[my_ip] != event.get("[fields][compose_service]")
        @logger.info("Mapping of #{my_ip} changed from #{@mapping[my_ip]} to #{event.get("[fields][compose_service]")}")
        @mapping[my_ip] = event.get("[fields][compose_service]")
      end

      # If we have a @mapping for the peer
      if @mapping[other_ip]
        event.set("[fields][peer_service]", @mapping[other_ip])
      end
    rescue
      puts "Failed to set source and target for #{event}"
    end

    filter_matched(event)
  end
end
