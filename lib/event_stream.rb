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

  def initialize(&blk)
    instance_exec(&blk) if blk
    attr_config_validate
  end

  def database
    @database ||= Canvas::Cassandra::Database.from_config(database_name)
  end

  def on_insert(&callback)
    add_callback(:insert, callback)
  end

  def insert(record)
    database.batch do
      database.insert_record(table, { id_column => record.id }, record.attributes)
      run_callbacks(:insert, record)
    end
  end

  def on_update(&callback)
    add_callback(:update, callback)
  end

  def update(record)
    database.batch do
      database.update_record(table, { id_column => record.id }, record.changes)
      run_callbacks(:update, record)
    end
  end

  def fetch(ids)
    rows = []
    if ids.present?
      database.execute(fetch_cql, ids).fetch do |row|
        rows << record_type.from_attributes(row)
      end
    end
    rows
  end

  def add_index(name, &blk)
    index = EventStream::Index.new(self, &blk)

    on_insert do |record|
      if entry = index.entry_proc.call(record)
        key = index.key_proc ? index.key_proc.call(entry) : entry
        index.insert(record.id, key, record.created_at)
      end
    end

    singleton_class.send(:define_method, "for_#{name}") do |entry|
      key = index.key_proc ? index.key_proc.call(entry) : entry
      index.for_key(key)
    end

    index
  end

  private

  def fetch_cql
    "SELECT * FROM #{table} WHERE #{id_column} IN (?)"
  end

  def callbacks_for(type)
    @callbacks ||= {}
    @callbacks[type] ||= []
  end

  def add_callback(type, callback)
    callbacks_for(type) << callback
  end

  def run_callbacks(type, record)
    callbacks_for(type).each do |callback|
      instance_exec(record, &callback)
    end
  end
end
