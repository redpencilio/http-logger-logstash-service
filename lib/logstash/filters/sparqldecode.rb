# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"
require 'cgi'

class LogStash::Filters::SparqlDecode < LogStash::Filters::Base

  config_name "sparqldecode"

  public
  def register
  end

  public
  def filter(event)
    if event.get("[http][response][headers][content-type]") == "application/sparql-results+json"
      # A SPARQL query was sent, let's enrich it'
      if event.get("[http][request][headers][content-type]") == "application/sparql-query"
        # POST with content-type sparql-update, get body
        event.set("[http][request][sparql]", event.get("[http][request][body]"))
      elsif event.get("[url][query]")
        query_map = CGI::parse(event.get("[url][query]"))
        query_map.default = nil
        query = query_map["query"] || query_map["update"]
        event.set("[http][request][sparql]", query) if query
      end
    end

    filter_matched(event)
  end
end
