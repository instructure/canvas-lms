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

module LinkedIn
  class Connection
    def get_service_user_info(access_token)
      body = access_token.get('/v1/people/~:(id,first-name,last-name,public-profile-url,picture-url)').body
      data = Nokogiri::XML(body)
      service_user_id = data.css("id")[0].content
      service_user_name = data.css("first-name")[0].content + " " + data.css("last-name")[0].content
      service_user_url = data.css("public-profile-url")[0].content
      return service_user_id, service_user_name, service_user_url
    end

    def get_access_token(token, secret, oauth_verifier)
      consumer = self.class.consumer
      request_token = OAuth::RequestToken.new(consumer, token, secret)
      request_token.get_access_token(:oauth_verifier => oauth_verifier)
    end

    def request_token(oauth_callback)
      consumer = self.class.consumer
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

    def self.config_check(settings)
      consumer = self.consumer(settings[:api_key], settings[:secret_key])
      token = consumer.get_request_token rescue nil
      token ? nil : "Configuration check failed, please check your settings"
    end

    def self.config=(config)
      if !config.is_a?(Proc)
        raise "Config must be a Proc"
      end
      @config = config
    end

    def self.config
      @config.call()
    end
  end
end
