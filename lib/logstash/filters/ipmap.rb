# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"
require "concurrent"

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
    @mapping = Concurrent::Map.new
  end

  public
  def filter(event)
    begin
      source_ip = event.get("[source][ip]")
      dest_ip = event.get("[destination][ip]")
      direction = event.get("[network][direction]")
      if direction != "inbound" && direction != "outbound"
        direction = "unknown"
      end

      if source_ip && source_ip == dest_ip
        event.set("[fields][peer_service]", event.get("[fields][compose_service]"))
      else
        # if there is no direction, then we'll default to the inbound reasoning
        if direction == "inbound"
          my_ip = dest_ip
          other_ip = source_ip
        elsif direction == "outbound"
          my_ip = source_ip
          other_ip = dest_ip
        else # direction is unknown
          my_ip = dest_ip
          other_ip = source_ip
        end

        my_ip = direction == "inbound" ? dest_ip : source_ip
        other_ip = direction == "inbound" ? source_ip : dest_ip

        compose_service = event.get("[fields][compose_service]")

        if my_ip
          current_mapping = @mapping[my_ip]
          if current_mapping.nil?
            @logger.info("Mapping for #{my_ip} set to #{compose_service}")
            unless direction == "unknown"
              @mapping[my_ip] = compose_service
            end
          elsif current_mapping != compose_service
            @logger.info("Mapping of #{my_ip} changed from #{current_mapping} to #{compose_service}")
            if ENV['LOG_EVENT_ON_REMAP'] == "true"
              @logger.info("Event details", :event => event.to_hash)
            end
            unless direction == "unknown"
              @mapping[my_ip] = compose_service
            end
          end
        end

        # If we have a @mapping for the peer
        if other_ip && @mapping[other_ip]
          event.set("[fields][peer_service]", @mapping[other_ip])
        end
      end
    rescue => e
      @logger.error("Failed to set source and target", :event => event.to_hash, :exception => e.message, :backtrace => e.backtrace)
    end

    filter_matched(event)
  end
end
