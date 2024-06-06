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
require "event_stream/index_strategy/active_record"

class EventStream::Index
  include EventStream::AttrConfig

  attr_reader :event_stream, :strategy

  # it's expected that this proc will return an AR Scope from the
  # associated AR type.  If it doesn't, there could be problems...
  attr_config :ar_scope_proc, type: Proc, default: nil

  def initialize(event_stream, &blk)
    @event_stream = event_stream
    @strategy = EventStream::IndexStrategy::ActiveRecord.new(self)
    instance_exec(&blk) if blk
    attr_config_validate
  end

  def find_with(args, options)
    @strategy.find_with(args, options)
  end

  def find_ids_with(args, options)
    @strategy.find_ids_with(args, options)
  end
end
