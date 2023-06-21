# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

module Services
  class ScreencapService
    def initialize(config)
      @config = config.with_indifferent_access
    end

    def snapshot_url_to_file(url, tmpfile)
      url_params = { url: }.to_query
      full_url = "#{@config[:url]}?#{url_params}"
      CanvasHttp.get(full_url, { "X-API-Key" => @config[:key] }) do |http_response|
        if http_response.code.to_i == 200
          http_response.read_body do |chunk|
            tmpfile.write chunk
          end
          tmpfile.close
        else
          Rails.logger.error("Snapshot failed with error code #{http_response.code}")
          return false
        end
      end
      true
    end
  end
end
