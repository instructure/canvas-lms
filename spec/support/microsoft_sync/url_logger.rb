# frozen_string_literal: true

#
# Canvas is Copyright (C) 2021 Instructure, Inc.
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

module MicrosoftSync::GraphService::SpecHelper
  class UrlLogger
    attr_reader :errors

    def initialize
      @stubbed_urls = []
      @openapi_schema = {}
      # TODO: get permissions for putting in Jenkins' S3 bucket and pull from there.
      # @openapi_schema = YAML.load_file(Rails.root.join('openapi.yaml')")
      @errors = []
    end

    # Return an array of just the URLs in @stubbed_urls for
    # searching through them more easily.
    def stubbed_url_array
      @stubbed_urls.pluck(:url)
    end

    def stub_request(method, url, response, variables, request_params = {})
      if request_params.any?
        WebMock.stub_request(method, url).with(request_params).and_return(response)
      else
        WebMock.stub_request(method, url).and_return(response)
      end

      unless stubbed_url_array.include?(url)
        @stubbed_urls.push({
                             url:,
                             variables:,
                             requests: [],
                             responses: []
                           })
      end
    end

    def log(request, response)
      log_request(request)
      log_response(request.uri.normalize.to_s, response)
    end

    def log_request(request)
      index = stubbed_url_array.find_index(request.uri.normalize.to_s)
      @stubbed_urls[index][:requests] << request if index
    end

    def log_response(url, response)
      index = stubbed_url_array.find_index(url)
      @stubbed_urls[index][:responses] << response if index
    end

    def verify_responses
      @stubbed_urls.each do |request_stub|
        responses = request_stub[:responses]
        variables = request_stub[:variables]

        request_stub[:requests].each_with_index do |request, index|
          response = responses[index]
          next if @openapi_schema.empty?
          next if validates_with_schema?(request, response, variables)

          @errors << {
            body: response.body,
            url: request.uri.path,
          }
        end
      end
    end

    def validates_with_schema?(request, response, request_substitution_values = [])
      method = request.method
      path = request.uri.path.sub("/v1.0", "") << "$"
      request_substitution_values.each do |value|
        # Make a regular expression, replacing all substitution values with
        # [^/]+, meaning "any characters besides a forward slash."
        # In MSFT's openapi doc, variables are inside of curly braces, so add those.
        # Example:
        # path: "teams/myteamid"
        # request_substitution_values: ["myteamid"]
        # resulting regex: %r(/teams/{[^/]+}), matches MS openapi doc's "/teams/{team_id}"
        path = path.sub(value, "{[^/]+}")
      end

      path_regex = Regexp.new(path)
      all_schema_paths = @openapi_schema["paths"].keys
      schema_path = all_schema_paths.grep(path_regex).first
      schema = @openapi_schema.dig(*schema_dig_keys(schema_path, method, response))

      JSON::Validator.validate({ components: @openapi_schema["components"] }.merge(schema), JSON.parse(response.body))
    end

    def schema_dig_keys(schema_path, method, response)
      [
        "paths",
        schema_path,
        method.to_s,
        "responses",
        response.status.first.to_s,
        "content",
        response.headers["Content-Type"],
        "schema",
      ]
    end
  end
end
