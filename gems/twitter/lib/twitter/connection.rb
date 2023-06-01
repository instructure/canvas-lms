# frozen_string_literal: true

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
#

require "oauth"

module Twitter
  class Connection
    def self.from_request_token(request_token, request_secret, oauth_verifier)
      access_token = OAuth::RequestToken.new(
        twitter_consumer,
        request_token,
        request_secret
      ).get_access_token(oauth_verifier:)
      Twitter::Connection.new(access_token)
    end

    def self.from_service_token(service_token, service_secret)
      access_token = OAuth::AccessToken.new(
        twitter_consumer,
        service_token,
        service_secret
      )
      Twitter::Connection.new(access_token)
    end

    attr_reader :access_token

    def initialize(access_token)
      @access_token = access_token
    end

    def service_user_id
      service_user["id"]
    end

    def service_user_name
      service_user["screen_name"]
    end

    def service_user
      url = "/1.1/account/verify_credentials.json"
      @service_user ||= JSON.parse(access_token.get(url).body)
    end

    # public (to gem)
    def send_direct_message(user_name, user_id, message)
      url = "/1.1/direct_messages/new.json"
      response = access_token.post(url, {
                                     screen_name: user_name,
                                     user_id:,
                                     text: message
                                   })
      JSON.parse(response.body)
    end

    def self.request_token(success_url)
      consumer = twitter_consumer
      consumer.get_request_token(oauth_callback: success_url)
    end

    def self.twitter_consumer(key = nil, secret = nil)
      require "oauth"
      require "oauth/consumer"
      twitter_config = Twitter::Connection.config
      key ||= twitter_config["api_key"]
      secret ||= twitter_config["secret_key"]
      OAuth::Consumer.new(key, secret, {
                            site: "https://api.twitter.com",
                            request_token_path: "/oauth/request_token",
                            access_token_path: "/oauth/access_token",
                            authorize_path: "/oauth/authorize",
                            signature_method: "HMAC-SHA1"
                          })
    end
    private_class_method :twitter_consumer

    def self.config_check(settings)
      consumer = twitter_consumer(settings[:api_key], settings[:secret_key])
      token = consumer.get_request_token rescue nil
      token ? nil : "Configuration check failed, please check your settings"
    end

    def self.config=(config)
      unless config.respond_to?(:call)
        raise "Config must respond to #call"
      end

      @config = config
    end

    def self.config
      @config.call
    end
  end
end
