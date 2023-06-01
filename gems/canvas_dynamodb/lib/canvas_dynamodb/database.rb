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
  class Database
    DEFAULT_MIN_CAPACITY = 5
    DEFAULT_MAX_CAPACITY = 10_000

    attr_reader :client, :fingerprint, :logger

    # The "fingerprint" is really just for logging so you have
    # some string you can grep for if you want to pull out only
    # the ddb query logs for THIS database (often something like "db_name:environment").
    # "prefix" will become part of whatever naming structure you use,
    # and can be left blank if you do not intend to have this db
    # be one of a class of similarly purposed tables.
    #
    def initialize(fingerprint, prefix: nil, client_opts: {}, logger: nil)
      @client = client_opts[:client] || Aws::DynamoDB::Client.new(client_opts)
      @fingerprint = fingerprint
      @prefix = prefix
      @logger = logger || Logger.new($stdout)
    end

    %i[delete_item get_item put_item query scan update_item].each do |method|
      define_method(method) do |params|
        params = params.merge(
          table_name: prefixed_table_name(params[:table_name])
        )
        execute(method, params)
      end
    end

    %i[batch_get_item batch_write_item].each do |method|
      define_method(method) do |params|
        request_items = {}
        params[:request_items].each_key do |table_name|
          request_items[prefixed_table_name(table_name)] = params[:request_items][table_name]
        end
        execute(method, params.merge({ request_items: }))
      end
    end

    def prefixed_table_name(table_name)
      [@prefix, table_name].compact.join("-")
    end

    def batch_get
      BatchGetBuilder.new(self)
    end

    def batch_write
      BatchWriteBuilder.new(self)
    end

    def execute(method, params)
      result = nil
      ms = 1000 * Benchmark.realtime do
        result = client.send(method, params)
      end
      logger.debug("  #{"DDB (%.2fms)" % [ms]}  #{method}(#{params.inspect}) [#{fingerprint}]")
      result
    end
  end
end
