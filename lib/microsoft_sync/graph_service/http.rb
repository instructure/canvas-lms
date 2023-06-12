# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

# Functions used by GraphService common to all/multiple Microsoft endpoints,
# such as making requests, expanding parameters ('filter', 'select', etc.),
# stats/metrics, logging, throttling, pagination, and making batch requests.
# To be used only through GraphService, which provides individual endpoints.
#
# Stats metrics supplied here:
# * timings for all requests
# * counters one per request (split up by method and first part of path)
# * quota points used (split up the same way). (See `quota` argument to request
#   and `increment_statsd_quota_points`)
module MicrosoftSync
  class GraphService
    class Http
      attr_reader :tenant

      BASE_URL = "https://graph.microsoft.com/v1.0/"
      STATSD_PREFIX = "microsoft_sync.graph_service"

      PAGINATED_NEXT_LINK_KEY = "@odata.nextLink"
      PAGINATED_VALUE_KEY = "value"

      DEFAULT_N_INTERMITTENT_RETRIES = 1

      class ApplicationNotAuthorizedForTenant < MicrosoftSync::Errors::GracefulCancelError
        def self.public_message
          I18n.t "Application not authorized for tenant. " \
                 "Please make sure your admin has granted access for us to access your Microsoft tenant."
        end
      end

      class BatchRequestFailed < MicrosoftSync::Errors::PublicError
        def self.public_message
          I18n.t "Got error from Microsoft API while making a batch request."
        end
      end

      class BatchRequestThrottled < MicrosoftSync::Errors::PublicError
        include Errors::Throttled

        def initialize(msg, responses)
          super(msg)

          @retry_after_seconds = responses.filter_map do |resp|
            headers = resp["headers"]&.transform_keys(&:downcase) || {}
            headers["retry-after"].presence&.to_f
          end.max
        end

        def self.public_message
          I18n.t "Received throttled response from Microsoft API while making a batch request."
        end
      end

      class ExpectedErrorWrapper < StandardError
        attr_reader :wrapped_exception

        def initialize(wrapped_exception)
          super()
          @wrapped_exception = wrapped_exception
        end
      end
      private_constant :ExpectedErrorWrapper

      def initialize(tenant, extra_statsd_tags)
        @tenant = tenant
        @extra_statsd_tags = extra_statsd_tags
      end

      attr_reader :extra_statsd_tags

      # Example options: body (hash for JSON), query (hash of query string), headers (hash),
      # quota (array of integers [read_quota_points, write_quota_points]; will be adjusted
      # if $selected query param is used.)
      # Options except for quota are passed thru to HTTParty.
      #
      # If special_cases is given, it should be an array of SpecialCase objects.
      # If any match, the "expected" statsd metrics is incremented and that value
      # is returned. If the SpecialCase result is an error class, instead of
      # returning, a new error of that class is raised (and counted as
      # "expected", not "error"). This is useful if there are non-200s expected
      # and you don't want to raise an HTTP error / count those these as errors
      # in the stats.
      def request(method,
                  path,
                  quota: nil,
                  retries: DEFAULT_N_INTERMITTENT_RETRIES,
                  special_cases: [],
                  **options)
        statsd_tags = statsd_tags_for_request(method, path)
        increment_statsd_quota_points(quota, options, statsd_tags)

        response = Canvas.timeout_protection("microsoft_sync_graph", raise_on_timeout: true) do
          InstStatsd::Statsd.time("#{STATSD_PREFIX}.time", tags: statsd_tags) do
            request_without_metrics(method, path, options)
          end
        end

        special_case_value = SpecialCase.match(
          special_cases,
          status_code: response.code,
          body: response.body
        )
        if special_case_value
          log_and_increment(method, path, statsd_tags, :expected, response.code)
          if special_case_value.is_a?(StandardError)
            raise ExpectedErrorWrapper, special_case_value
          else
            return special_case_value
          end
        end

        raise_error_if_bad_response(response)

        result = response.parsed_response
        log_and_increment(method, path, statsd_tags, :success, response.code)
        result
      rescue ExpectedErrorWrapper => e
        raise e.wrapped_exception
      rescue => e
        response_code = response&.code&.to_s || e.class.name.tr(":", "_")

        if intermittent_non_throttled?(e) && retries > 0
          retries -= 1
          log_and_increment(method, path, statsd_tags, :retried, response_code)
          retry
        end

        log_and_increment(method, path, statsd_tags, statsd_name_for_error(e), response_code)
        raise
      end

      # Builds a query string (hash) from options used by get or list endpoints
      def expand_options(filter: {}, select: [], top: nil)
        {}.tap do |query|
          query["$filter"] = filter_clause(filter) unless filter.empty?
          query["$select"] = select.join(",") unless select.empty?
          query["$top"] = top if top
        end
      end

      # Iterate through all pages in a GET endpoint that may return
      # multiple pages of results.
      # @param [Hash] options_to_be_expanded: sent to expand_options
      # @param [Array] quota array of [read_quota_used, write_quota_used] for each page/request
      # @param [Array] special_cases passed on to request()
      def get_paginated_list(endpoint, quota:, special_cases: [], **options_to_be_expanded)
        request_options = expand_options(**options_to_be_expanded)
        response = request(:get, endpoint, query: request_options, quota:, special_cases:)
        return response[PAGINATED_VALUE_KEY] unless block_given?

        loop do
          value = response[PAGINATED_VALUE_KEY]
          next_link = response[PAGINATED_NEXT_LINK_KEY]
          yield value, next_link

          break if next_link.nil?

          response = request(:get, next_link, quota:, special_cases:)
        end
      end

      # Uses Microsoft API's JSON batching to run requests in parallel with one
      # HTTP request. Any throttled responses will cause a BatchRequestThrottled to be raised.
      # Othe non-2xx responses which are not caught by any special_cases will
      # cause a BatchRequestFailed error. special_cases is a array of SpecialCase objects that can
      # be used to handle semi-expected (often non-2xx) responses, very similar to special_cases
      # in request().
      #
      # The subresponses from Microsoft are checked in this order:
      # * If there any "throttled" subresponses, BatchRequestThrottled is raised.
      # * If there are any non-2xx status codes that are _not_ covered by any special_cases, a
      #   BatchRequestFailed error is raised.
      # * If any responses are covered by special cases with a StandardError "result", that error
      #   will be raised (the first errored response as returned by Microsoft)
      # * Otherwise, this returns a hash from (request_id) -> (SpecialCase result) for each
      #   subrequest that matched a special case.
      #
      # Regardless of the above, individual counters (ignored [any special case], throttled, success,
      # error) will be incremented for each subresponse.
      def run_batch(endpoint_name, requests, quota:, special_cases: [])
        Rails.logger.info("MicrosoftSync::GraphService: batch of #{requests.count} #{endpoint_name}")
        tags = extra_statsd_tags.merge(msft_endpoint: "batch_#{endpoint_name}")
        increment_statsd_quota_points(quota, {}, tags)

        response =
          begin
            request(:post, "$batch", body: { requests: })
          rescue Errors::HTTPFailedDependency => e
            # The main request may return a 424 if any subrequests fail (esp. if throttled).
            # Regardless, we handle subrequests failures below.
            e.response.parsed_response
          rescue
            increment_batch_statsd_counters_unknown_error(endpoint_name, requests.count)
            raise
          end

        grouped, special_vals = group_batch_subresponses_by_type(response["responses"], special_cases)

        increment_batch_statsd_counters(endpoint_name, grouped)

        failed = (grouped[:error] || []) + (grouped[:throttled] || [])
        if failed.present?
          codes = failed.pluck("status")
          bodies = failed.map { |resp| resp["body"].to_s.truncate(500) }
          msg = "Batch of #{failed.count}: codes #{codes}, bodies #{bodies.inspect}"

          raise BatchRequestThrottled.new(msg, grouped[:throttled]) if grouped[:throttled]

          raise BatchRequestFailed, msg
        end

        special_case_error = special_vals.values.find { |v| v.is_a?(StandardError) }
        raise special_case_error if special_case_error

        special_vals
      end

      # Used mostly internally but can be useful for endpoint specifics
      def quote_value(str)
        "'#{str.gsub("'", "''")}'"
      end

      private

      # -- Helpers for request():

      def request_without_metrics(method, path, options)
        options = options.dup
        options[:headers] = options[:headers]&.dup || {}

        options[:headers]["Authorization"] = "Bearer " + LoginService.token(tenant)
        if options[:body]
          options[:headers]["Content-type"] = "application/json"
          options[:body] = options[:body].to_json
        end

        url = path.start_with?("https:") ? path : BASE_URL + path

        HTTParty.send(method, url, options)
      end

      def intermittent_non_throttled?(error)
        Errors::INTERMITTENT.any? { |klass| error.is_a?(klass) } && !error.is_a?(Errors::Throttled)
      end

      def raise_error_if_bad_response(response)
        if application_not_authorized_response?(response)
          raise ApplicationNotAuthorizedForTenant
        elsif !(200..299).cover?(response.code)
          raise MicrosoftSync::Errors::HTTPInvalidStatus.for(
            service: "graph", tenant:, response:
          )
        end
      end

      # Keep track of quota points we use. See https://docs.microsoft.com/en-us/graph/throttling
      # Endpoints should supply a base quota points ("Base Resource Unit Cost")
      # of [read_cost, right_cost], typically passed into request(). From the
      # Microsoft docs:
      # > Using $select decreases [read] cost by 1
      # > Using $top with a value of less than 20 decreases [read] cost by 1
      #   [not implemented here because we never use $top < 20]
      # > A request [read] cost can never be lower than 1.
      def increment_statsd_quota_points(quota, request_options, tags)
        read, write = quota
        if read && read > 0
          query = request_options["query"] || request_options[:query]
          read -= 1 if read > 1 && query&.dig("$select")
          InstStatsd::Statsd.count("#{STATSD_PREFIX}.quota_read", read, tags:)
        end
        if write && write > 0
          InstStatsd::Statsd.count("#{STATSD_PREFIX}.quota_write", write, tags:)
        end
      end

      def statsd_tags_for_request(method, path_or_url)
        # Strip https, hostname, "v1.0"
        path = path_or_url.gsub(%r{^https?://[^/]*/[^/]*/}, "")

        extra_statsd_tags.merge(
          msft_endpoint: InstStatsd::Statsd.escape("#{method.to_s.downcase}_#{path.split("/").first}")
        )
      end

      def application_not_authorized_response?(response)
        (
          response.code == 401 &&
          response.body.include?("The identity of the calling application could not be established.")
        ) || (
          response.code == 403 &&
          response.body.include?("Required roles claim values are not provided")
        )
      end

      def statsd_name_for_error(error)
        case error
        when MicrosoftSync::Errors::HTTPNotFound then "notfound"
        when MicrosoftSync::Errors::HTTPTooManyRequests then "throttled"
        when *MicrosoftSync::Errors::INTERMITTENT then "intermittent"
        else "error"
        end
      end

      def log_and_increment(request_method, request_path, statsd_tags, outcome, status_code)
        Rails.logger.info(
          "MicrosoftSync::GraphService::Http: #{request_method} #{request_path} -- #{status_code}, #{outcome}"
        )
        InstStatsd::Statsd.increment(
          "#{STATSD_PREFIX}.#{outcome}", tags: statsd_tags.merge(status_code: status_code.to_s)
        )
      end

      # -- Helpers for expand_options():

      def filter_clause(filter)
        filter.map do |filter_key, filter_value|
          if filter_value.is_a?(Array)
            quoted_values = filter_value.map { |v| quote_value(v) }
            "#{filter_key} in (#{quoted_values.join(", ")})"
          else
            "#{filter_key} eq #{quote_value(filter_value)}"
          end
        end.join(" and ")
      end

      # -- Helpers for run_batch()

      # Returns two things:
      # * a hash with possible keys (:ignored, :throttled, :success:, :error) and values
      #   being arrays of responses. e.g. {ignored: [subresp1, subresp2], success: [subresp3]}
      # * a hash of special case results returned by matching special cases (keys are request ids)
      def group_batch_subresponses_by_type(responses, special_cases)
        special_cases_values = {}
        grouped = responses.group_by do |subresponse|
          special_case_value = SpecialCase.match(
            special_cases,
            status_code: subresponse["status"],
            body: subresponse["body"].to_json,
            batch_request_id: subresponse["id"]
          )

          if special_case_value
            special_cases_values[subresponse["id"]] = special_case_value
            :ignored
          elsif subresponse["status"] == 429
            :throttled
          elsif (200..299).cover?(subresponse["status"])
            :success
          else
            :error
          end
        end

        [grouped, special_cases_values]
      end

      def increment_batch_statsd_counters(endpoint_name, responses_grouped_by_type)
        responses_grouped_by_type.each do |type, responses|
          responses.group_by { |c| c["status"] }.transform_values(&:count).each do |code, count|
            tags = extra_statsd_tags.merge(msft_endpoint: endpoint_name, status: code)
            InstStatsd::Statsd.count("#{STATSD_PREFIX}.batch.#{type}", count, tags:)
          end
        end
      end

      def increment_batch_statsd_counters_unknown_error(endpoint_name, count)
        tags = extra_statsd_tags.merge(msft_endpoint: endpoint_name, status: "unknown")
        InstStatsd::Statsd.count("#{STATSD_PREFIX}.batch.error", count, tags:)
      end
    end
  end
end
