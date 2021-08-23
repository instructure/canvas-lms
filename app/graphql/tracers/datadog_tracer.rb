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

require 'datadog/statsd'

module Tracers
  class DatadogTracer
    def initialize(first_party, base_tags = {})
      @third_party = !first_party
      @tags = base_tags
    end

    def trace(key, metadata)
      if key == "validate"
        operation_name = metadata[:query].operation_name
        query_name = @third_party ? "3rdparty" : operation_name || "unnamed"

        @tags[:query_md5] = Digest::MD5.hexdigest(metadata[:query].query_string).to_s unless @third_party || operation_name.nil?

        operation_and_fields(metadata).each do |op_and_field|
          InstStatsd::Statsd.increment("graphql.#{op_and_field}.count", tags: @tags)
        end
        InstStatsd::Statsd.increment("graphql.#{query_name}.count", tags: @tags)
        InstStatsd::Statsd.time("graphql.#{query_name}.time", tags: @tags) do
          yield
        end
      else
        yield
      end
    end

    # easiest to describe what this does by example.  if the operation is:
    #    query MyQuery {
    #      course(id: "1") { name }
    #      legacyNode(type: User, id: "5") { sisId }
    #    }
    # then this will return ["query.course", "query.legacyNode"]
    #
    # if the operation is:
    #    mutation MyMutation {
    #      createAssignment(input: {courseId: "1", name: "Do my bidding"}) {
    #        assignment {
    #          name
    #        }
    #      }
    #    }
    # then this will return ["mutation.createAssignment"]
    def operation_and_fields(metadata)
      op = metadata[:query].selected_operation
      op_type = op.operation_type || "query"
      op.selections.map { |field| "#{op_type}.#{field.name}" }
    end
  end
end
