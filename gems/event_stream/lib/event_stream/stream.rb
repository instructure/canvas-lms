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

  attr_config :record_type

  attr_accessor :raise_on_error

  def initialize(&blk)
    instance_exec(&blk) if blk
    attr_config_validate
  end

  delegate :available?, :database_name, :database_fingerprint, :fetch, to: :current_backend

  def on_insert(&callback)
    add_callback(:insert, callback)
  end

  def insert(record)
    current_backend.execute(:insert, record)
    record
  end

  def on_update(&callback)
    add_callback(:update, callback)
  end

  def update(record)
    current_backend.execute(:update, record)
    record
  end

  def on_error(&callback)
    add_callback(:error, callback)
  end

  def current_backend
    @current_backend ||= EventStream::Backend::ActiveRecord.new(self)
  end

  def add_index(name, &)
    index = EventStream::Index.new(self, &)

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
    "#{database_name}.#{record_type.table_name}"
  end

  def ttl_seconds(timestamp)
    timestamp.to_i - time_to_live.seconds.ago.to_i
  end

  def run_callbacks(operation, *args)
    callbacks_for(operation).each do |callback|
      instance_exec(*args, &callback)
    end
  end

  private

  def callbacks_for(operation)
    @callbacks ||= {}
    @callbacks[operation] ||= []
  end

  def add_callback(operation, callback)
    callbacks_for(operation) << callback
  end
end
