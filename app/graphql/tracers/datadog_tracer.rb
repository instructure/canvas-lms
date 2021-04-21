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
    def initialize(domain, first_party)
      @domain = domain
      @third_party = !first_party
    end

    def trace(key, metadata)
      if key == "execute_query"
        query_name = @third_party ? "3rdparty" : metadata[:query].operation_name || "unnamed"
        tags = {
          domain: @domain
        }

        tags[:query_md5] = Digest::MD5.hexdigest(metadata[:query].query_string).to_s unless @third_party
        InstStatsd::Statsd.increment("graphql.#{query_name}.count", tags: tags)
        InstStatsd::Statsd.time("graphql.#{query_name}.time", tags: tags) do
          yield
        end
      else
        yield
      end
    end
  end
end
