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
  class FetchBatchResultService < PageViews::ServiceBase
    def call(query_id)
      uri = @configuration.uri.merge("/api/v5/pageviews/batch-query/#{query_id}/results")
      CanvasHttp.get(
        uri.to_s,
        request_headers
      ) do |response|
        handle_generic_errors(response) unless response.code.to_i == 200
        response.decode_content = false # Prevent automatic decompression
        format = determine_result_format(response)
        filename = determine_filename(response)
        return Common::DownloadableResult.new(format:, filename:, content: response.body)
      end
    end

    private

    def determine_result_format(response)
      raise InvalidResultError, "Missing Content-Type header in response." unless response.header["Content-Type"]

      # strip any parameters (encoding for example) from the Content-Type
      content_type = response.header["Content-Type"].split(";").first.strip
      raise Common::InvalidResultError, "Result format is invalid: #{content_type}" unless Common::CONTENT_TYPE_MAPPINGS[content_type]

      Common::CONTENT_TYPE_MAPPINGS[content_type]
    end

    def determine_filename(response)
      content_disposition = response.header["Content-Disposition"]
      if content_disposition && content_disposition =~ /filename="?([^";]+)"?/
        Regexp.last_match(1)
      else
        raise Common::InvalidResultError, "Unable to determine filename from Content-Disposition header"
      end
    end
  end
end
