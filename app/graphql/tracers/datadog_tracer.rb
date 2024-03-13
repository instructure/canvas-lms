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

require "datadog/statsd"

module Tracers
  class DatadogTracer
    def initialize(first_party, domain)
      @third_party = !first_party
      @domain = domain
    end

    def trace(key, metadata, &)
      if key == "validate"
        tags = {}

        tags[:operation_name] = @third_party ? "3rdparty" : metadata[:query].operation_name || "unnamed"

        op, fields = op_type_and_fields(metadata)
        fields.each do |field|
          InstStatsd::Statsd.increment("graphql.#{op}.count", tags: tags.merge(field:))
        end
        InstStatsd::Statsd.increment("graphql.operation.count", tags:)
        InstStatsd::Statsd.time("graphql.operation.time", tags:, &)
      else
        yield
      end
    end

    # easiest to describe what this does by example.  if the operation is:
    #    query MyQuery {
    #      course(id: "1") { name }
    #      legacyNode(type: User, id: "5") { sisId }
    #    }
    # then this will return ["query", ["course", "legacyNode"]]
    #
    # if the operation is:
    #    mutation MyMutation {
    #      createAssignment(input: {courseId: "1", name: "Do my bidding"}) {
    #        assignment {
    #          name
    #        }
    #      }
    #    }
    # then this will return ["mutation", ["createAssignment"]]
    def op_type_and_fields(metadata)
      op = metadata[:query].selected_operation
      op_type = op.operation_type || "query"
      [op_type, op.selections.map(&:name)]
    end
  end
end
