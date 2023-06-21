# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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
module CanvasDynamoDB
  class BatchWriteBuilder < BatchBuilderBase
    def operation
      :batch_write_item
    end

    def batch_size
      25
    end

    def unprocessed_attr
      :unprocessed_items
    end

    def put(table_name, *items)
      vals = items.map { |item| { put_request: { item: } } }
      add(table_name, *vals)
    end

    def delete(table_name, *keys)
      vals = keys.map { |key| { delete_request: { key: } } }
      add(table_name, *vals)
    end

    def execute
      @result ||= begin
        execute_raw
        true
      end
    end
  end
end
