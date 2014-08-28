require 'active_support'
require 'active_record'
require 'bookmarked_collection'
require 'canvas_cassandra'
require 'canvas_statsd'
require 'canvas_uuid'

module EventStream
  require 'event_stream/attr_config'
  require 'event_stream/record'
  require 'event_stream/failure'
  require 'event_stream/stream'
  require 'event_stream/index'

  def self.current_shard
    @current_shard_lookup and @current_shard_lookup.call
  end

  def self.current_shard_lookup=(callable)
    @current_shard_lookup = callable
  end

  def self.get_index_ids(index, rows)
    @get_index_ids_lookup ||= lambda { |index, rows| rows.map{ |row| row[index.id_column] } }
    @get_index_ids_lookup.call(index, rows)
  end

  def self.get_index_ids_lookup=(callable)
    @get_index_ids_lookup = callable
  end
end
