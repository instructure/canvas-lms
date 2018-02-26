require 'datadog/statsd'

module Tracers
  class DatadogTracer
    def initialize(domain)
      @domain = domain
      @statsd = Datadog::Statsd.new('localhost', 8125)
    end

    def trace(key, metadata)
      if key == "execute_query"
        @statsd.batch do |statsd|
          query_name = metadata[:query].operation_name || "unnamed"
          tags = [
            "query_md5:#{Digest::MD5.hexdigest(metadata[:query].query_string)}",
            "domain:#@domain",
          ]
          statsd.increment("graphql.#{query_name}.count", tags: tags)
          statsd.time("graphql.#{query_name}.time", tags: tags) do
            yield
          end
        end
      else
        yield
      end
    end
  end
end
