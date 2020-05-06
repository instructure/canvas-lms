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
require 'event_stream/index_strategy/active_record'
require 'event_stream/index_strategy/cassandra'

class EventStream::Index
  include EventStream::AttrConfig

  attr_reader :event_stream

  attr_config :table, :type => String
  attr_config :id_column, :type => String, :default => 'id'
  attr_config :key_column, :type => String, :default => 'key'
  attr_config :bucket_size, :type => Integer, :default => 1.week
  attr_config :scrollback_limit, :type => Integer, :default => 52.weeks
  attr_config :entry_proc, :type => Proc
  attr_config :key_proc, :type => Proc, :default => nil
  attr_config :ar_conditions_proc, type: Proc, default: nil

  def initialize(event_stream, &blk)
    @event_stream = event_stream
    instance_exec(&blk) if blk
    attr_config_validate
  end

  def find_with(args, options)
    strategy = self.strategy_for(options[:strategy])
    strategy.find_with(args, options)
  end

  def find_ids_with(args, options)
    strategy = self.strategy_for(options[:strategy])
    strategy.find_ids_with(args, options)
  end

  def strategy_for(strategy_name)
    if strategy_name == :active_record
      @_ar_decorator ||= EventStream::IndexStrategy::ActiveRecord.new(self)
    elsif strategy_name == :cassandra
      @_cass_decorator ||= EventStream::IndexStrategy::Cassandra.new(self)
    else
      raise "Unknown Indexing Strategy: #{strategy_name}"
    end
  end

  # these methods are included to keep the interface with plugins
  # until they can be updated or removed to no longer
  # depend no a cassandra-specific implementation.
  # --- start ---
  def database
    event_stream.database
  end

  def for_key(key, options={})
    self.strategy_for(:cassandra).for_key(key, options)
  end

  def select_cql
    self.strategy_for(:cassandra).select_cql
  end

  def insert_cql
    self.strategy_for(:cassandra).insert_cql
  end

  def insert(record, key)
    self.strategy_for(:cassandra).insert(record, key)
  end

  def bucket_for_time(time)
    self.strategy_for(:cassandra).bucket_for_time(time)
  end
  # --- end ---

end
