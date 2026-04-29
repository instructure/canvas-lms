# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

module PageViews
  class PollBatchQueryService < PageViews::ServiceBase
    def call(query_id)
      uri = @configuration.uri.merge("/api/v5/pageviews/batch-query/#{query_id}")
      CanvasHttp.get(
        uri.to_s,
        request_headers
      ) do |response|
        handle_generic_errors(response) unless [200, 202].include?(response.code.to_i)
        body = JSON.parse(response.body)
        status = body["status"].to_s.downcase.to_sym
        format = body["format"].to_s.downcase.to_sym
        error_code = body["errorCode"]
        warnings = body["warnings"]
        return Common::PollingResponse.new(query_id:, status:, format:, error_code:, warnings:)
      end
    end
  end
end
