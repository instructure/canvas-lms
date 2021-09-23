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

  class BatchBuilderBase

    MAX_BACKOFF_EXP = 10

    def initialize(database, backoff_exp = 0)
      if backoff_exp > MAX_BACKOFF_EXP
        raise "Exceeded maximum number of backoff attempts for batch" 
      end
      @database = database
      @backoff_exp = backoff_exp
      @pairs = []
    end

    def add(table_name, *vals)
      raise "Cannot add to an executed batch" if @result
      vals.each { |val| @pairs << [table_name, val] }
      self
    end

    def add_unprocessed(unprocessed)
      unprocessed.each_key do |table_name|
        add(table_name, *unprocessed[table_name])
      end
      self
    end

    def request_items(tables)
      tables
    end

    def execute_raw
      responses = []
      @pairs.each_slice(batch_size) do |batch|
        tables = {}
        batch.each do |pair|
          tables[pair[0]] ||= []
          tables[pair[0]] << pair[1]
        end
        sleep 2 ** @backoff_exp / 1000 if @backoff_exp > 0
        resp = @database.send(operation, { request_items: request_items(tables) })
        responses << resp
        until resp.send(unprocessed_attr).empty?
          unprocessed_batch = self.class.new(@database, @backoff_exp + 1)
          unprocessed_batch.add_unprocessed(resp.send(unprocessed_attr))
          resp = unprocessed_batch.execute_raw(batch_size, unprocessed_attr)
          responses << resp
        end
      end
      responses
    end

  end

end
