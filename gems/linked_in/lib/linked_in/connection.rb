#
# Copyright (C) 2011 Instructure, Inc.
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

require 'nokogiri'
require 'oauth'

module LinkedIn
  class Connection

    def get_request(path, access_token)
      config = self.class.config

      http = Net::HTTP.new("api.linkedin.com", 443)
      http.use_ssl = true
      #http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      http

      request = Net::HTTP::Get.new(path)
      request['Authorization'] = "Bearer #{access_token}"
      response = http.request(request)

      response
    end

    def get_service_user_info(access_token)
      body = get_request('/v2/me', access_token).body
      data = JSON.parse(body)
      Rails.logger.debug("### Registering LinkedIn service.  Data returned from LinkedIn API: ID #{data["id"]} and url name #{data["vanityName"]}")
      service_user_id = data["id"]
      service_user_name = "#{data["localizedFirstName"]} #{data["localizedLastName"]}"
      service_user_url = "http://www.linkedin.com/in/#{data["vanityName"]}"
      return service_user_id, service_user_name, service_user_url
    end

    def authorize_url(return_to, nonce)
      config = self.class.config
      "https://www.linkedin.com/oauth/v2/authorization?response_type=code&scope=r_emailaddress%20r_fullprofile&client_id=#{config['api_key']}&state=#{nonce}&redirect_uri=#{CGI.escape(return_to)}"
    end

    def exchange_code_for_token(code, redirect_uri)
      config = self.class.config

      http = Net::HTTP.new("www.linkedin.com", 443)
      http.use_ssl = true
      #http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      http

      request = Net::HTTP::Post.new("/oauth/v2/accessToken")
      request.set_form_data(
        'grant_type' => 'authorization_code',
        'code' => code,
        'redirect_uri' => redirect_uri,
        'client_id' => config['api_key'],
        'client_secret' => config['secret_key']
      )
      response = http.request(request)

      info = JSON.parse response.body

      info['access_token']
    end

    def self.config_check(settings)
      nil # we don't confirm it here with oauth 2, instead go in as a user and try to auth manually
    end

    def self.config=(config)
      unless config.respond_to?(:call)
        raise "Config must respond to #call"
      end
      @config = config
    end

    def self.config
      @config.call()
    end
  end
end
