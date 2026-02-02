# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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
  module Common
    FORMATS = ["csv", "jsonl"].freeze

    STATUS = %w[queued running finished failed].freeze

    CONTENT_TYPE_MAPPINGS = {
      "application/jsonl" => :jsonl,
      "text/csv" => :csv,
    }.freeze

    AsyncQueryRequest = Struct.new(:start_date, :end_date, :user_id, :root_account_uuids, :format) do
      def validate!(*)
        raise ArgumentError, "Start date must be a valid date" unless start_date.is_a?(Date)
        raise ArgumentError, "End date must be a valid date" unless end_date.is_a?(Date)
        raise ArgumentError, "Start date must be before or equal to end date" if start_date > end_date
        raise ArgumentError, "Only full-month intervals are supported" unless start_date.day == 1 && end_date.day == 1
        raise ArgumentError, "User ID must be positive number" unless user_id.positive?
        raise ArgumentError, "Root account UUIDs must be an array" unless root_account_uuids.is_a?(Array)
        raise ArgumentError, "Root account UUIDs cannot be empty" if root_account_uuids.empty?
        raise ArgumentError, "Format must be one of #{FORMATS.join(", ")}" unless FORMATS.include?(format.to_s)
      end
    end

    AsyncBatchQueryRequest = Struct.new(:start_date, :end_date, :user_ids, :root_account_uuids, :format) do
      def validate!(*)
        raise ArgumentError, "Format must be one of #{FORMATS.join(", ")}" unless FORMATS.include?(format.to_s)
        raise ArgumentError, "Start date must be a valid date" unless start_date.is_a?(Date)
        raise ArgumentError, "End date must be a valid date" unless end_date.is_a?(Date)
        raise ArgumentError, "Start date must be before or equal to end date" if start_date > end_date
        raise ArgumentError, "Only full-month intervals are supported" unless start_date.day == 1 && end_date.day == 1
        raise ArgumentError, "User IDs must be an array" unless user_ids.is_a?(Array)
        raise ArgumentError, "User IDs cannot be empty" if user_ids.empty?
        raise ArgumentError, "All user IDs must be positive numbers" unless user_ids.all? { |id| id.is_a?(Integer) && id.positive? }
        raise ArgumentError, "Root account UUIDs must be an array" unless root_account_uuids.is_a?(Array)
        raise ArgumentError, "Root account UUIDs cannot be empty" if root_account_uuids.empty?
      end
    end

    DownloadableResult = Struct.new(:format, :filename, :content, :compressed?)

    PollingResponse = Struct.new(:query_id, :status, :format, :error_code, :warnings)

    class ConfigurationError < StandardError; end
    class InvalidRequestError < StandardError; end
    class NotFoundError < StandardError; end
    class InternalServerError < StandardError; end
    class AccessDeniedError < StandardError; end
    class InvalidResultError < StandardError; end
    class TooManyRequestsError < StandardError; end
    class NoContentError < StandardError; end
  end
end
