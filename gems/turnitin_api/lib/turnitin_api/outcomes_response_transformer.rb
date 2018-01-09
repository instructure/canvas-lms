#
# Copyright (C) 2011 - present Instructure, Inc.
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

require 'simple_oauth'

module TurnitinApi
  class OutcomesResponseTransformer

    # key
    # secret
    # turnitin_api response

    attr_accessor :outcomes_response_json, :key, :lti_params
    def initialize(key, secret, lti_params, outcomes_response_json)
      @key = key
      @secret = secret
      @lti_params = lti_params || {}
      @outcomes_response_json = outcomes_response_json
    end

    def response
      @response ||= make_call(outcomes_response_json['outcomes_tool_placement_url'])
    end

    # download original
    def original_submission
      yield make_call(response.body["outcome_originalfile"]["launch_url"])
    end

    # store link to report
    def originality_report_url
      response.body["outcome_originalityreport"]["launch_url"]
    end

    def originality_data
      response.body['outcome_originalityreport'].select {|k, _| %w(breakdown numeric).include?(k)}
    end

    def uploaded_at
      response.body['meta']['date_uploaded']
    end

    def scored?
      originality_data["numeric"]["score"].present?
    end

    private

    def connection
      @connection ||= Faraday.new do |conn|
        conn.request :multipart
        conn.request :url_encoded
        conn.response :json, :content_type => /\bjson$/
        conn.use FaradayMiddleware::FollowRedirects
        conn.adapter :net_http
      end
    end

    def make_call(url)
      default_params = {
          'roles' => 'Learner',
          'lti_message_type' => 'basic-lti-launch-request',
          'lti_version' => 'LTI-1p0',
          'resource_link_id' => SecureRandom.hex(32),
      }
      params = default_params.merge(lti_params)
      header = SimpleOAuth::Header.new(:post, url, params, consumer_key: @key, consumer_secret: @secret,
                                       callback: 'about:blank')
      connection.post url, params.merge(header.signed_attributes)
    end

  end
end
