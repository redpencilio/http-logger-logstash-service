# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"
require 'cgi'

class LogStash::Filters::SparqlDecode < LogStash::Filters::Base

  config_name "sparqldecode"

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
  end

  public
  def filter(event)
    if (event.get("[http][response][headers][content-type]") || "").start_with?( "application/sparql-results+json" )
      # A SPARQL query was sent, let's enrich it'
      if event.get("[http][request][headers][content-type]") == "application/sparql-query"
        # POST with content-type sparql-update, get body
        event.set("[http][request][sparql]", event.get("[http][request][body]"))
      elsif event.get("[url][query]")
        query_map = CGI::parse(event.get("[url][query]"))
        query = query_map["query"] || query_map["update"]
        event.set("[http][request][sparql]", query) if query
      end
    end

    filter_matched(event)
  end
end
