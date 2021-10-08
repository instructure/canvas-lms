# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

module Canvas
  # this module mostly exists to be invoked by an
  # initializer, but it's also useful if you want
  # to monkey with how the message bus config works
  # for a test or something and then "re-initialize"
  # it to it's standard state (plugged into canvas settings and such)
  module MessageBusConfig
    def self.apply
      MessageBus.logger = Rails.logger
      MessageBus.max_mem_queue_size = -> { Setting.get('pulsar_max_mem_queue_size', 200).to_i }
      MessageBus.worker_process_interval = -> { Setting.get('pulsar_process_interval_seconds', 1.0).to_f }
      # sometimes this async worker thread grabs a connection on a Setting read or similar.
      # We need it to be released or the main thread can have a real problem.
      MessageBus.on_work_unit_end = -> { ActiveRecord::Base.clear_active_connections! }
    end
  end
end
