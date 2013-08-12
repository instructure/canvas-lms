#
# Copyright (C) 2013 Instructure, Inc.
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

class EventStream
  include AttrConfig

  attr_config :database_name, :type => String
  attr_config :table, :type => String
  attr_config :id_column, :type => String, :default => 'id'
  attr_config :record_type, :default => EventStream::Record
  attr_config :time_to_live, :type => Fixnum, :default => 1.year

  def initialize(&blk)
    instance_exec(&blk) if blk
    attr_config_validate
  end

  def database
    Canvas::Cassandra::Database.from_config(database_name)
  end

  def available?
    Canvas::Cassandra::Database.configured?(database_name)
  end

  def on_insert(&callback)
    add_callback(:insert, callback)
  end

  def insert(record)
    if available?
      execute(:insert, record)
      record
    else
      nil
    end
  end

  def on_update(&callback)
    add_callback(:update, callback)
  end

  def update(record)
    if available?
      execute(:update, record)
      record
    else
      nil
    end
  end

  def fetch(ids)
    rows = []
    if available? && ids.present?
      database.execute(fetch_cql, ids).fetch do |row|
        rows << record_type.from_attributes(row.to_hash)
      end
    end
    rows
  end

  def add_index(name, &blk)
    index = EventStream::Index.new(self, &blk)

    on_insert do |record|
      if entry = index.entry_proc.call(record)
        key = index.key_proc ? index.key_proc.call(entry) : entry
        index.insert(record, key)
      end
    end

    singleton_class.send(:define_method, "for_#{name}") do |entry, options={}|
      key = index.key_proc ? index.key_proc.call(entry) : entry
      index.for_key(key, options)
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

  def ttl_seconds(record)
    ((record.created_at + time_to_live) - Time.now).to_i
  end

  private

  def fetch_cql
    "SELECT * FROM #{table} WHERE #{id_column} IN (?)"
  end

  def callbacks_for(operation)
    @callbacks ||= {}
    @callbacks[operation] ||= []
  end

  def execute(operation, record)
    ttl_seconds = self.ttl_seconds(record)
    return if ttl_seconds < 0

    database.batch do
      database.send(:"#{operation}_record", table, { id_column => record.id }, operation_payload(operation, record), ttl_seconds)
      run_callbacks(operation, record)
    end
  rescue Exception => exception
    EventStream::Failure.log!(operation, self, record, exception)
  end

  def add_callback(operation, callback)
    callbacks_for(operation) << callback
  end

  def run_callbacks(operation, record)
    callbacks_for(operation).each do |callback|
      instance_exec(record, &callback)
    end
  end
end
