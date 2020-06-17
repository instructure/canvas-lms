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
  class ActiveRecord
    include Strategy
    attr_accessor :stream

    def initialize(stream_obj)
      @stream = stream_obj
    end

    delegate :active_record_type, to: :stream

    class Unavailable < RuntimeError; end

    def available?
      active_record_type.connection.active?
    end

    def fetch(ids, strategy: :batch)
      active_record_type.where(uuid: ids)
    end

    def execute(operation, record)
      unless available?
        stream.run_callbacks(:error, operation, record, Unavailable.new)
        return
      end

      send(operation, record)
      stream.run_callbacks(operation, record)
    rescue StandardError => exception
      stream.run_callbacks(:error, operation, record, exception)
      raise if stream.raise_on_error
    end

    def index_on_insert(index, record)
      entry = index.entry_proc.call(record)
      key = index.key_proc ? index.key_proc.call(*entry) : entry
      index.strategy_for(:active_record).insert(record, key)
    end

    def find_with_index(index, args)
      options = args.extract_options!
      options[:strategy] = :active_record
      index.find_with(args, options)
    end

    def find_ids_with_index(index, args)
      options = args.extract_options!
      options[:strategy] = :active_record
      index.find_ids_with(args, options)
    end

    private
    def insert(record)
      active_record_type.create_from_event_stream!(record)
    end

    def update(record)
      active_record_type.update_from_event_stream!(record)
    end
  end
end