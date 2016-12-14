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
    def self.from_request_token(request_token, request_secret, oauth_verifier)
      access_token = OAuth::RequestToken.new(
        consumer,
        request_token,
        request_secret
      ).get_access_token(:oauth_verifier => oauth_verifier)
      new(access_token)
    end

    attr_reader :access_token

    def initialize(access_token)
      @access_token = access_token
    end

    def service_user_id
      service_user.css("id")[0].content
    end

    def service_user_name
      fn = service_user.css("first-name")[0].content
      ln = service_user.css("last-name")[0].content
      "#{fn} #{ln}"
    end

    def service_user_url
      service_user.css("public-profile-url")[0].content
    end

    def service_user
      url = '/v1/people/~:(id,first-name,last-name,public-profile-url,picture-url)'
      @data ||= Nokogiri::XML(access_token.get(url).body)
    end

    def self.request_token(oauth_callback)
      consumer.get_request_token(:oauth_callback => oauth_callback)
    end

    def self.consumer(key=nil, secret=nil)
      config = self.config
      key ||= config['api_key']
      secret ||= config['secret_key']
      OAuth::Consumer.new(key, secret, {
        :site => "https://api.linkedin.com",
        :request_token_path => "/uas/oauth/requestToken",
        :access_token_path => "/uas/oauth/accessToken",
        :authorize_path => "/uas/oauth/authorize",
        :signature_method => "HMAC-SHA1"
      })
    end
    private_class_method :consumer

    def self.config_check(settings)
      c = consumer(settings[:api_key], settings[:secret_key])
      token = c.get_request_token rescue nil
      token ? nil : "Configuration check failed, please check your settings"
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
