require "cassandra-cql"
require "benchmark"

module CanvasCassandra
  require "canvas_cassandra/database"

  def self.consistency_level(name)
    CassandraCQL::Thrift::ConsistencyLevel.const_get(name.to_s.upcase)
  end
end
