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

###
# Warning: Facebook has deprecated the Dashboard API. See https://developers.facebook.com/blog/post/615/
##

module Facebook
  def self.parse_signed_request(signed_request)
    sig, str = signed_request.split('.')
    generated_sig = Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('sha256'), config['secret'], str)).strip.tr('+/', '-_').sub(/=+$/, '')
    str += '=' * (4 - str.length.modulo(4))
    data = JSON.parse(str.tr('-_','+/').unpack('m')[0]) rescue nil
    [data, sig == generated_sig ? sig : nil]
  end
  
  def self.dashboard_increment_count(service)
    send_request("dashboard.incrementCount", service, :uid => service.service_user_id)
  end
  
  def self.dashboard_clear_count(service)
    send_request("dashboard.setCount", service, :uid => service.service_user_id, :count => 0)
  end
  
  def self.protocol
    "http#{config['disable_ssl'] ? '' : 's'}"
  end
  
  def self.authorize_url(oauth_request)
    callback_url = "#{protocol}://#{config['canvas_domain']}/facebook_success.html"
    state = Canvas::Security.encrypt_password(oauth_request.global_id.to_s, 'facebook_oauth_request').join('.')
    "https://www.facebook.com/dialog/oauth?client_id=#{config['app_id']}&redirect_uri=#{CGI.escape(callback_url)}&response_type=token&scope=offline_access&state=#{CGI.escape(state)}"
  end
  
  def self.oauth_request_id(state)
    key,salt = state.split('.', 2)
    request_id = Canvas::Security.decrypt_password(key, salt, 'facebook_oauth_request')
  end
  
  def self.authorize_success(user, token)
    @service = UserService.find_by_user_id_and_service(user.id, 'facebook')
    @service ||= UserService.new(:user => user, :service => 'facebook')
    @service.token = token
    data = send_graph_request('/me', :get, @service)
    return nil unless data
    @service.service_user_id = data['id']
    @service.service_user_name = data['name']
    @service.service_user_url = data['link']
    @service.save
    @service
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
  
  def self.send_graph_request(path, method, service, params={})
    params[:format] = 'json'
    params[:access_token] = service.token if service
    url = "https://graph.facebook.com/#{path}" + ActionController::Routing::Route.new.build_query_string(params)
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    tmp_url = uri.path+"?"+uri.query
    request = Net::HTTP::Get.new(tmp_url)
    response = http.request(request)
    res = JSON.parse(response.body)
    if res['error']
      Rails.logger.error(res['error']['message'])
      nil
    else
      res
    end
  end
  
  def self.send_request(method, service, params)
    params[:format] = 'json'
    params[:access_token] = service.token if service
    url = "https://api.facebook.com/method/#{method}" + ActionController::Routing::Route.new.build_query_string(params)
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    tmp_url = uri.path+"?"+uri.query
    request = Net::HTTP::Get.new(tmp_url)
    response = http.request(request)
    response.body
  end
  
  def self.config
    res = Canvas::Plugin.find(:facebook).try(:settings)
    res && res['app_id'] ? res : nil
  end
end
