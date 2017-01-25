#
# Copyright (C) 2014 Instructure, Inc.
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

  attr_config :database, :default => nil
  attr_config :table, :type => String
  attr_config :id_column, :type => String, :default => 'id'
  attr_config :record_type, :default => EventStream::Record
  attr_config :time_to_live, :type => Integer, :default => 1.year
  attr_config :read_consistency_level, :default => nil

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

  def insert(record)
    execute(:insert, record)
    record
  end

  def on_update(&callback)
    add_callback(:update, callback)
  end

  def update(record)
    execute(:update, record)
    record
  end

  def on_error(&callback)
    add_callback(:error, callback)
  end

  def fetch(ids)
    rows = []
    if available? && ids.present?
      database.execute(fetch_cql, ids, consistency: read_consistency_level).fetch do |row|
        rows << record_type.from_attributes(row.to_hash)
      end
    end
    rows
  end

  def add_index(name, &blk)
    index = EventStream::Index.new(self, &blk)

    on_insert do |record|
      if entry = index.entry_proc.call(record)
        key = index.key_proc ? index.key_proc.call(*entry) : entry
        index.insert(record, key)
      end
    end

    singleton_class.send(:define_method, "for_#{name}") do |*args|
      options = args.extract_options!
      key = index.key_proc ? index.key_proc.call(*args) : args
      index.for_key(key, options)
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

  def fetch_cql
    "SELECT * FROM #{table} %CONSISTENCY% WHERE #{id_column} IN (?)"
  end

  private

  def callbacks_for(operation)
    @callbacks ||= {}
    @callbacks[operation] ||= []
  end

  class Unavailable < Exception; end

  def execute(operation, record)
    unless available?
      run_callbacks(:error, operation, record, Unavailable.new)
      return
    end

    ttl_seconds = self.ttl_seconds(record.created_at)
    return if ttl_seconds < 0

    database.batch do
      database.send(:"#{operation}_record", table, {id_column => record.id}, operation_payload(operation, record), ttl_seconds)
      run_callbacks(operation, record)
    end
  rescue Exception => exception
    run_callbacks(:error, operation, record, exception)
    raise if raise_on_error
  end

  def add_callback(operation, callback)
    callbacks_for(operation) << callback
  end

  def run_callbacks(operation, *args)
    callbacks_for(operation).each do |callback|
      instance_exec(*args, &callback)
    end
  end
end
