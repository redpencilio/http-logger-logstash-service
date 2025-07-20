# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"
require "cgi"

class LogStash::Filters::SparqlDecode < LogStash::Filters::Base

  config_name "sparqldecode"

  public
  def register
  end

  public
  def filter(event)
    begin
      response_content_types = event.get("[http][response][headers][content-type]")
      request_content_types = event.get("[http][request][headers][content-type]")
      if response_content_types == "application/sparql-results+json"
        # A SPARQL query was sent, let's enrich it
        if request_content_types == "application/sparql-query"
          # POST with content-type sparql-update, get body
          event.set("[http][request][sparql]", event.get("[http][request][body]"))
        elsif request_content_types == "application/sparql-update"
          # POST with content-type sparql-update, get body
          event.set("[http][request][sparql]", event.get("[http][request][body]"))
        elsif event.get("[url][query]")
          query_map = CGI::parse(event.get("[url][query]"))
          query_map.default = nil
          query = query_map["query"] || query_map["update"]
          event.set("[http][request][sparql]", query) if query.first && query.first
        end
      end
    rescue
      @logger.warn("Failed to process SPARQL query for #{event}")
    end

    filter_matched(event)
  end
end
