#
# Copyright (C) 2014 Instructure, Inc.
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

module Facebook
  class Connection
    API_URL = 'https://api.facebook.com'
    GRAPH_URL = 'https://graph.facebook.com'

    def self.parse_signed_request(signed_request)
      sig, str = signed_request.split('.')
      generated_sig = Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('sha256'), config['secret'], str)).strip.tr('+/', '-_').sub(/=+$/, '')
      str += '=' * (4 - str.length.modulo(4))
      data = JSON.parse(str.tr('-_', '+/').unpack('m')[0]) rescue nil
      [data, sig == generated_sig ? sig : nil]
    end

    def self.dashboard_increment_count(user_id, token, msg)
      send_graph_request("#{user_id}/apprequests", :post, token, message: msg)
    end

    def self.get_service_user_info(token)
      send_graph_request('me', :get, token)
    end

    def self.authorize_url(state)
      callback_url = "#{protocol}://#{config['canvas_domain']}/facebook_success.html"
      "https://www.facebook.com/dialog/oauth?client_id=#{config['app_id']}&redirect_uri=#{CGI.escape(callback_url)}&response_type=token&scope=offline_access&state=#{CGI.escape(state)}"
    end

    def self.app_url
      "http://apps.facebook.com/#{ URI.escape(self.config['canvas_name']) }"
    end

    def self.config_check(settings)
      url = "https://graph.facebook.com/oauth/access_token?client_id=#{settings['app_id']}&redirect_uri=http#{settings['disable_ssl'] ? '' : 's'}://#{settings['canvas_domain']}&client_secret=#{settings['secret']}&code=wrong&format=json"
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      tmp_url = uri.path+"?"+uri.query
      request = Net::HTTP::Get.new(tmp_url)
      response = http.request(request)
      res = JSON.parse(response.body)
      if res['error']
        if res['error']['message'] == "Error validating client secret."
          "Invalid app id or app secret"
        elsif res['error']['message'] == "Invalid redirect_uri: Given URL is not allowed by the Application configuration."
          "Invalid app id or redirect uri"
        elsif res['error']['message'] == "Invalid verification code format."
          # This means everything else checked out
          nil
        else
          "Unexpected error"
        end
      else
        # We expect to get an error in this API call, so no error means
        # something bad happened
        "Unexpected response from settings check"
      end
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

    def self.logger=(logger)
      @logger = logger
    end

    def self.send_graph_request(path, method, token, params = {})
      params[:access_token] = token
      query_string = build_query_string(params)
      uri = URI("#{GRAPH_URL}/#{path}#{query_string}")
      client = Net::HTTP.new(uri.host, uri.port)
      client.use_ssl = true

      response = if method == :get
                   client.get(uri.request_uri)
                 else
                   client.post(uri.request_uri, '')
                 end
      body = JSON.parse(response.body)

      if body['error']
        logger.error(body['error']['message'])
        nil
      else
        body
      end
    end
    private_class_method :send_graph_request

    def self.build_query_string(hash)
      elements = []

      hash.each do |key, value|
        if value
          elements << "#{CGI.escape(key.to_s)}=#{CGI.escape(value.to_s)}"
        end
      end

      elements.empty? ? '' : "?#{elements.sort * '&'}"
    end
    private_class_method :build_query_string

    def self.logger
      @logger ||= Logger.new(STDOUT)
    end
    private_class_method :logger

  
    def self.protocol
      "http#{config['disable_ssl'] ? '' : 's'}"
    end
    private_class_method :protocol
  end
end
