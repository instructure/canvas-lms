# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

module GraphQLPostgresTimeout
  class << self
    attr_accessor :do_not_wrap
  end

  TIMEOUT = 60_000

  def self.wrap(query)
    if do_not_wrap
      yield
    else
      ActiveRecord::Base.transaction do
        ActiveRecord::Base.connection.execute "SET statement_timeout = #{TIMEOUT}"
        yield
      rescue ActiveRecord::StatementInvalid => e
        if e.cause.is_a?(PG::QueryCanceled)
          Rails.logger.warn do
            "GraphQL Operation failed due to postgres statement_timeout:\n#{query.query_string}"
          end
          raise GraphQLPostgresTimeout::Error, "operation timed out"
        end
        raise GraphQL::ExecutionError, "Invalid SQL: #{e.message}"
      end
    end
  end

  Error = Class.new(StandardError)
end
