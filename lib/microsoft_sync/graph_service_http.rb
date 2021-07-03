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
  class GraphServiceHttp
    attr_reader :tenant

    BASE_URL = 'https://graph.microsoft.com/v1.0/'
    STATSD_PREFIX = 'microsoft_sync.graph_service'

    PAGINATED_NEXT_LINK_KEY = '@odata.nextLink'
    PAGINATED_VALUE_KEY = 'value'

    class ApplicationNotAuthorizedForTenant < StandardError
      include Errors::GracefulCancelErrorMixin
    end

    class BatchRequestFailed < StandardError; end
    class BatchRequestThrottled < StandardError
      include Errors::Throttled

      def initialize(msg, responses)
        super(msg)

        @retry_after_seconds = responses.map do |resp|
          headers = resp['headers']&.transform_keys(&:downcase) || {}
          headers['retry-after'].presence&.to_f
        end.compact.max
      end
    end

    def initialize(tenant, extra_statsd_tags)
      @tenant = tenant
      @extra_statsd_tags = extra_statsd_tags
    end

    attr_reader :extra_statsd_tags

    # Example options: body (hash for JSON), query (hash of query string), headers (hash),
    # quota (array of integers [read_quota_points, write_quota_points]; will be adjusted
    # if $selected query param is used.)
    # Options except for quota are passed thru to HTTParty.
    def request(method, path, quota: nil, **options)
      statsd_tags = statsd_tags_for_request(method, path)
      increment_statsd_quota_points(quota, options, statsd_tags)

      Rails.logger.info("MicrosoftSync::GraphClient: #{method} #{path}")

      response = Canvas.timeout_protection("microsoft_sync_graph", raise_on_timeout: true) do
        InstStatsd::Statsd.time("#{STATSD_PREFIX}.time", tags: statsd_tags) do
          request_without_metrics(method, path, options)
        end
      end

      raise_error_if_bad_response(response)

      result = response.parsed_response
      InstStatsd::Statsd.increment(statsd_name, tags: statsd_tags)
      result
    rescue => error
      statsd_tags[:status_code] = response&.code&.to_s || 'unknown'
      InstStatsd::Statsd.increment(statsd_name(error), tags: statsd_tags)
      raise
    end

    # Builds a query string (hash) from options used by get or list endpoints
    def expand_options(filter: {}, select: [], top: nil)
      {}.tap do |query|
        query['$filter'] = filter_clause(filter) unless filter.empty?
        query['$select'] = select.join(',') unless select.empty?
        query['$top'] = top if top
      end
    end

    # Iterate through all pages in a GET endpoint that may return
    # multiple pages of results.
    # @param [Hash] options_to_be_expanded: sent to expand_options
    # @param [Array] quota array of [read_quota_used, write_quota_used] for each page/request
    def get_paginated_list(endpoint, quota:, **options_to_be_expanded)
      request_options = expand_options(**options_to_be_expanded)
      response = request(:get, endpoint, query: request_options, quota: quota)
      return response[PAGINATED_VALUE_KEY] unless block_given?

      loop do
        value = response[PAGINATED_VALUE_KEY]
        next_link = response[PAGINATED_NEXT_LINK_KEY]
        yield value, next_link

        break if next_link.nil?

        response = request(:get, next_link, quota: quota)
      end
    end

    # Uses Microsoft API's JSON batching to run requests in parallel with one
    # HTTP request. Expected failures can be ignored by passing in a block which checks
    # the response. Other non-2xx responses cause a BatchRequestFailed error.
    # Returns a list of ids of the requests that were ignored.
    def run_batch(endpoint_name, requests, quota:, &response_should_be_ignored)
      Rails.logger.info("MicrosoftSync::GraphClient: batch of #{requests.count} #{endpoint_name}")
      tags = extra_statsd_tags.merge(msft_endpoint: "batch_#{endpoint_name}")
      increment_statsd_quota_points(quota, {}, tags)

      response =
        begin
          request(:post, '$batch', body: { requests: requests })
        rescue Errors::HTTPFailedDependency => e
          # The main request may return a 424 if any subrequests fail (esp. if throttled).
          # Regardless, we handle subrequests failures below.
          e.response.parsed_response
        rescue
          increment_batch_statsd_counters_unknown_error(endpoint_name, requests.count)
          raise
        end

      grouped = group_batch_subresponses_by_type(response['responses'], &response_should_be_ignored)

      increment_batch_statsd_counters(endpoint_name, grouped)

      failed = (grouped[:error] || []) + (grouped[:throttled] || [])
      if failed.present?
        codes = failed.map{|resp| resp['status']}
        bodies = failed.map{|resp| resp['body'].to_s.truncate(500)}
        msg = "Batch of #{failed.count}: codes #{codes}, bodies #{bodies.inspect}"

        raise BatchRequestThrottled.new(msg, grouped[:throttled]) if grouped[:throttled]

        raise BatchRequestFailed, msg
      end

      grouped[:ignored]&.map{|r| r['id']} || []
    end

    # Used mostly internally but can be useful for endpoint specifics
    def quote_value(str)
      "'#{str.gsub("'", "''")}'"
    end

    private

    # -- Helpers for request():

    def request_without_metrics(method, path, options)
      options[:headers] ||= {}
      options[:headers]['Authorization'] = 'Bearer ' + LoginService.token(tenant)
      if options[:body]
        options[:headers]['Content-type'] = 'application/json'
        options[:body] = options[:body].to_json
      end

      url = path.start_with?('https:') ? path : BASE_URL + path

      HTTParty.send(method, url, options)
    end

    def raise_error_if_bad_response(response)
      if application_not_authorized_response?(response)
        raise ApplicationNotAuthorizedForTenant
      elsif !(200..299).cover?(response.code)
        raise MicrosoftSync::Errors::HTTPInvalidStatus.for(
          service: 'graph', tenant: tenant, response: response
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
        query = request_options['query'] || request_options[:query]
        read -= 1 if read > 1 && query&.dig('$select')
        InstStatsd::Statsd.count("#{STATSD_PREFIX}.quota_read", read, tags: tags)
      end
      if write && write > 0
        InstStatsd::Statsd.count("#{STATSD_PREFIX}.quota_write", write, tags: tags)
      end
    end

    def statsd_tags_for_request(method, path_or_url)
      # Strip https, hostname, "v1.0"
      path = path_or_url.gsub(%r{^https?://[^/]*/[^/]*/}, '')

      extra_statsd_tags.merge(
        msft_endpoint: InstStatsd::Statsd.escape("#{method.to_s.downcase}_#{path.split('/').first}")
      )
    end

    def application_not_authorized_response?(response)
      (
        response.code == 401 &&
        response.body.include?('The identity of the calling application could not be established.')
      ) || (
        response.code == 403 &&
        response.body.include?('Required roles claim values are not provided')
      )
    end

    def statsd_name(error=nil)
      name = case error
             when nil then 'success'
             when MicrosoftSync::Errors::HTTPNotFound then 'notfound'
             when MicrosoftSync::Errors::HTTPTooManyRequests then 'throttled'
             else 'error'
             end
      "#{STATSD_PREFIX}.#{name}"
    end

    # -- Helpers for expand_options():

    def filter_clause(filter)
      filter.map do |filter_key, filter_value|
        if filter_value.is_a?(Array)
          quoted_values = filter_value.map{|v| quote_value(v)}
          "#{filter_key} in (#{quoted_values.join(', ')})"
        else
          "#{filter_key} eq #{quote_value(filter_value)}"
        end
      end.join(' and ')
    end

    # -- Helpers for run_batch()

    # Returns a hash with possible keys (:ignored, :throttled, :success:, :error) and values
    # being arrays of responses. e.g. {ignored: [subresp1, subresp2], success: [subresp3]}
    def group_batch_subresponses_by_type(responses, &response_should_be_ignored)
      responses.group_by do |subresponse|
        if response_should_be_ignored[subresponse]
          :ignored
        elsif subresponse['status'] == 429
          :throttled
        elsif (200..299).cover?(subresponse['status'])
          :success
        else
          :error
        end
      end
    end

    def increment_batch_statsd_counters(endpoint_name, responses_grouped_by_type)
      responses_grouped_by_type.each do |type, responses|
        responses.group_by{|c| c['status']}.transform_values(&:count).each do |code, count|
          tags = extra_statsd_tags.merge(msft_endpoint: endpoint_name, status: code)
          InstStatsd::Statsd.count("#{STATSD_PREFIX}.batch.#{type}", count, tags: tags)
        end
      end
    end

    def increment_batch_statsd_counters_unknown_error(endpoint_name, count)
      tags = extra_statsd_tags.merge(msft_endpoint: endpoint_name, status: 'unknown')
      InstStatsd::Statsd.count("#{STATSD_PREFIX}.batch.error", count, tags: tags)
    end
  end
end

