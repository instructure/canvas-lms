#
# Copyright (C) 2013 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

class EventStream::Stream
  include EventStream::AttrConfig

  attr_config :database, :default => nil # only needed if backend_strategy evaluates to :cassandra
  attr_config :table, :type => String
  attr_config :id_column, :type => String, :default => 'id'
  attr_config :record_type, :default => EventStream::Record
  attr_config :time_to_live, :type => Integer, :default => 1.year # only honored for cassandra strategy
  attr_config :read_consistency_level, :default => nil # only honored for cassandra strategy
  attr_config :backend_strategy, default: ->{ :cassandra } # one of [:cassandra, :active_record]
  attr_config :active_record_type, default: nil # only needed if backend_strategy evaluates to :active_record

  attr_accessor :raise_on_error

  def initialize(&blk)
    instance_exec(&blk) if blk
    attr_config_validate
  end

  def available?
    !!database && database.available?
  end

  def database_name
    database && database.keyspace
  end

  def on_insert(&callback)
    add_callback(:insert, callback)
  end

  def insert(record, options={})
    backend = backend_for(options.fetch(:backend_strategy, backend_strategy))
    backend.execute(:insert, record)
    record
  end

  def on_update(&callback)
    add_callback(:update, callback)
  end

  def update(record, options={})
    backend = backend_for(options.fetch(:backend_strategy, backend_strategy))
    backend.execute(:update, record)
    record
  end

  def on_error(&callback)
    add_callback(:error, callback)
  end

  def fetch(ids, strategy: :batch)
    current_backend.fetch(ids, strategy: strategy)
  end

  def current_backend
    backend_for(backend_strategy)
  end

  def add_index(name, &blk)
    index = EventStream::Index.new(self, &blk)

    on_insert do |record|
      current_backend.index_on_insert(index, record)
    end

    singleton_class.send(:define_method, "for_#{name}") do |*args|
      current_backend.find_with_index(index, args)
    end

    singleton_class.send(:define_method, "ids_for_#{name}") do |*args|
      current_backend.find_ids_with_index(index, args)
    end

    singleton_class.send(:define_method, "#{name}_index") do
      index
    end

    index
  end

  def operation_payload(operation, record)
    if operation == :update
      record.changes
    else
      record.attributes
    end
  end

  def identifier
    "#{database_name}.#{table}"
  end

  def ttl_seconds(timestamp)
    timestamp.to_i - time_to_live.seconds.ago.to_i
  end

  def run_callbacks(operation, *args)
    callbacks_for(operation).each do |callback|
      instance_exec(*args, &callback)
    end
  end

  # primarily for use in testing
  # to regenerate state of
  # backend strategy
  def reset_backend!
    @backends = {}
  end

  # these methods are included to keep the interface with plugins
  # until they can be updated or removed to no longer
  # depend no a cassandra-specific implementation.
  # --- start ---
  def fetch_cql
    backend_for(:cassandra).fetch_cql
  end
  # --- end ---

  private

  def backend_for(strategy)
    @backends ||= {}
    @backends[strategy] ||= EventStream::Backend.for_strategy(self, strategy)
  end

  def callbacks_for(operation)
    @callbacks ||= {}
    @callbacks[operation] ||= []
  end

  def add_callback(operation, callback)
    callbacks_for(operation) << callback
  end

end
