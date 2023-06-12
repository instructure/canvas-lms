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

require "active_support/core_ext/module/delegation"

class EventStream::Stream
  include EventStream::AttrConfig

  attr_config :database, default: nil # only needed if backend_strategy evaluates to :cassandra
  attr_config :table, type: String, default: nil # only needed if backend_strategy evaluates to :cassandra
  attr_config :id_column, type: String, default: "id"
  attr_config :record_type, default: EventStream::Record
  attr_config :time_to_live, type: Integer, default: 1.year # only honored for cassandra strategy
  attr_config :read_consistency_level, default: nil # only honored for cassandra strategy
  attr_config :backend_strategy, default: -> { :active_record } # one of [:cassandra, :active_record]
  attr_config :active_record_type, default: nil # only needed if backend_strategy evaluates to :active_record

  attr_accessor :raise_on_error, :backend_override

  def initialize(&blk)
    @backend_override = nil
    instance_exec(&blk) if blk
    attr_config_validate
  end

  delegate :available?, :database_name, :database_fingerprint, to: :current_backend

  def on_insert(&callback)
    add_callback(:insert, callback)
  end

  def insert(record, options = {})
    backend_for(options.fetch(:backend_strategy, backend_strategy)) do |backend|
      backend.execute(:insert, record)
    end
    record
  end

  def on_update(&callback)
    add_callback(:update, callback)
  end

  def update(record, options = {})
    backend_for(options.fetch(:backend_strategy, backend_strategy)) do |backend|
      backend.execute(:update, record)
    end
    record
  end

  def on_error(&callback)
    add_callback(:error, callback)
  end

  def fetch(ids, strategy: :batch)
    current_backend.fetch(ids, strategy:)
  end

  def current_backend
    @backend_override || backend_for(backend_strategy)
  end

  def add_index(name, &)
    index = EventStream::Index.new(self, &)

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

  private

  def backend_for(strategy)
    @backends ||= {}
    @backends[strategy] ||= EventStream::Backend.for_strategy(self, strategy)
    to_return = @backends[strategy]
    if block_given?
      begin
        # this is useful because callbacks like indexers
        # use the "current_backend".  If we explicitly pass in a backend
        # for an invocation, then we want that same backend to be
        # used in the callbacks
        restore_state, @backend_override = @backend_override, to_return
        yield @backend_override
      ensure
        # restore_state will usually be nil,
        # but if we have some insert triggered from a callback
        # it will pop off the previous backend
        @backend_override = restore_state
      end
    end
    to_return
  end

  def callbacks_for(operation)
    @callbacks ||= {}
    @callbacks[operation] ||= []
  end

  def add_callback(operation, callback)
    callbacks_for(operation) << callback
  end
end
