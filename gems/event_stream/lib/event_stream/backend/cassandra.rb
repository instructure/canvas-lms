#
# Copyright (C) 2020 - present Instructure, Inc.
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
module EventStream::Backend
  class Cassandra
    include Strategy
    attr_accessor :stream, :database

    def initialize(stream_obj)
      @stream = stream_obj
      @database = stream_obj.database
    end

    class Unavailable < RuntimeError; end

    def available?
      !!database && database.available?
    end

    def execute(operation, record)
      unless stream.available?
        stream.run_callbacks(:error, operation, record, Unavailable.new)
        return
      end

      ttl_seconds = stream.ttl_seconds(record.created_at)
      return if ttl_seconds < 0

      database.batch do
        stream.database.send(:"#{operation}_record", stream.table, {stream.id_column => record.id}, stream.operation_payload(operation, record), ttl_seconds)
        stream.run_callbacks(operation, record)
      end
    rescue StandardError => exception
      stream.run_callbacks(:error, operation, record, exception)
      raise if stream.raise_on_error
    end
  end
end