Gem::Specification.new do |s|
  s.name = 'logstash-filter-ipmap'
  s.version = '0.2.0'
  s.summary = "Proof-of-concept Logstash plugin that creates a reverse-DNS mapping to assign proper remote domains to log items."
  s.description = "This gem is a Logstash plugin that will read the fields.compose_service, source.ip and destination.ip fields in Packetbeat output to create a mapping of IPs to service names. It will then use this to inject the correct peer domain in subsequent log items."
  s.authors = ["Gilles Coremans"]
  s.email = 'redpencil@redpencil.io'
  s.homepage = "https://github.com/redpencilio/http-logger-logstash-service"
  s.require_paths = ["lib"]

  s.files = Dir['lib/**/*','vendor/**/*','*.gemspec','*.md','Gemfile','LICENSE']

  # Logstash plugin metadata
  s.metadata = { "logstash_plugin" => "true", "logstash_group" => "filter" }

  # Dependencies
  s.add_runtime_dependency "logstash-core-plugin-api", "~> 2.0"
  s.add_development_dependency 'logstash-devutils'
end
