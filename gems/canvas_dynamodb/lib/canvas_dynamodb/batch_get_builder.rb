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

  class BatchGetBuilder < BatchBuilderBase

    def operation
      :batch_get_item
    end

    def batch_size
      100
    end

    def unprocessed_attr
      :unprocessed_keys
    end

    def request_items(tables)
      Hash[tables.map { |k,v| [k, { keys: v }] }]
    end

    def execute
      @result ||= begin
        result = {}
        execute_raw.each { |resp|
          merge_result(resp.responses, result)
        }
        result
      end
    end

    private

    def merge_result(src, dest)
      src.each_key do |table_name|
        dest[table_name] ||= []
        dest[table_name].concat(src[table_name])
      end
    end

  end

end
