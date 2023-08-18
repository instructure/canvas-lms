# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

class RedisClient
  MaxNumberOfClientsReachedError = Class.new(ConnectionError)

  module MaxClients
    def connect(*)
      protect_from_max_clients { super }
    end

    def call(*)
      protect_from_max_clients { super }
    end

    def call_pipelined(*)
      protect_from_max_clients { super }
    end

    def protect_from_max_clients
      yield
    rescue CommandError => e
      raise MaxNumberOfClientsReachedError, e.message if e.message.include?("max number of clients reached")

      raise
    end
  end
end
