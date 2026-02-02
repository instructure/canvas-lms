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
  class EnqueueBatchQueryService < PageViews::ServiceBase
    def initialize(configuration, requestor_user: nil)
      super
    end

    def call(start_date, end_date, users, format)
      validate_users!(users)

      uri = @configuration.uri.merge("/api/v5/pageviews/batch-query")
      start_date = parse_date_only(start_date) unless start_date.is_a?(Date)
      end_date = parse_date_only(end_date) unless end_date.is_a?(Date)

      user_ids = users.map(&:global_id)
      root_account_uuids = collect_root_account_uuids(users)

      request = Common::AsyncBatchQueryRequest.new(
        start_date:,
        end_date:,
        user_ids:,
        root_account_uuids:,
        format:
      )
      request.validate!

      CanvasHttp.post(
        uri.to_s,
        request_headers,
        content_type: "application/json",
        body: request.to_json
      ) do |response|
        handle_generic_errors(response) unless response.code.to_i == 201
        return response.header["Location"].split("/").last
      end
    end

    private

    def validate_users!(users)
      raise ArgumentError, "users must be an array" unless users.is_a?(Array)
      raise ArgumentError, "users cannot be empty" if users.empty?
      # rubocop:disable Performance/RedundantEqualityComparisonBlock
      raise ArgumentError, "all elements must be User objects" unless users.all? { |u| u.is_a?(User) }
      # rubocop:enable Performance/RedundantEqualityComparisonBlock
    end

    def parse_date_only(date_string)
      raise ArgumentError, "Date must be in YYYY-MM-DD format" unless date_string.match?(/\A\d{4}-\d{2}-\d{2}\z/)

      Date.parse(date_string)
    end

    def collect_root_account_uuids(users)
      users.flat_map do |user|
        user.shard.activate do
          user.root_account_ids.map do |id|
            Account.find_cached(id).uuid
          end
        end
      end.uniq
    end
  end
end
