#
# Copyright (C) 2011-2013 Instructure, Inc.
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

class Facebook
  API_URL   = 'https://api.facebook.com'
  GRAPH_URL = 'https://graph.facebook.com'

  def self.parse_signed_request(signed_request)
    sig, str = signed_request.split('.')
    generated_sig = Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('sha256'), config['secret'], str)).strip.tr('+/', '-_').sub(/=+$/, '')
    str += '=' * (4 - str.length.modulo(4))
    data = JSON.parse(str.tr('-_','+/').unpack('m')[0]) rescue nil
    [data, sig == generated_sig ? sig : nil]
  end
  
  def self.dashboard_increment_count(user_id, token, msg)
    path = "#{user_id}/apprequests"
    send_graph_request(path, :post, token, message: msg)
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
  
  def self.send_graph_request(path, method, token, params = {})
    params[:access_token] = token
    query_string          = ActionController::Routing::Route.new.build_query_string(params)
    uri                   = URI("#{GRAPH_URL}/#{path}#{query_string}")
    client                = Net::HTTP.new(uri.host, uri.port)
    client.use_ssl        = true

    response = if method == :get
                 client.get(uri.request_uri)
               else
                 client.post(uri.request_uri, '')
               end
    body = JSON.parse(response.body)

    if body['error']
      Rails.logger.error(body['error']['message'])
      nil
    else
      body
    end
  end

  def self.config
    res = Canvas::Plugin.find(:facebook).try(:settings)
    res && res['app_id'] ? res : nil
  end

  def self.protocol
    "http#{config['disable_ssl'] ? '' : 's'}"
  end
end
