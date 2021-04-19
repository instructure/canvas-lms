# frozen_string_literal: true

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
  # it's expected that this proc will return an AR Scope from the
  # associated AR type.  If it doesn't, there could be problems...
  attr_config :ar_scope_proc, type: Proc, default: nil

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

end
