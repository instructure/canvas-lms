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

module FacebookOauth

  def facebook_retrieve_access_token
    consumer = facebook_consumer
    if @current_user
      @service = @current_user.user_services.find_by_service("facebook")
      access_token = OAuth::AccessToken.new(consumer, service.token, service.secret)
    elsif @facebook_service
      access_token = OAuth::AccessToken.new(consumer, @facebook_service.token, @facebook_service.secret)
    else
      access_token = OAuth::AccessToken.new(consumer, session[:oauth_facebook_access_token_token], session[:oauth_facebook_access_token_secret])
    end
    access_token
    # access_token = OAuth::AccessToken.new(consumer, "1/JcD2SzOVrqr_1IBevdbvRg", "ThNebSN+2hV2fqOakzhTwb5c")
  end
  
  def facebook_generate_token(token, secret)
    OAuth::AccessToken.new(facebook_consumer, token, secret)
  end
  
  def facebook_get_access_token(oauth_request)
    consumer = facebook_consumer
    request_token = OAuth::RequestToken.new(consumer, oauth_request.token, oauth_request.secret)
    access_token = request_token.get_access_token([], :oauth_verifier => params[:oauth_verifier])
    body = access_token.get('/v1/people/~:(id,first-name,last-name,public-profile-url)').body
    data = LibXML::XML::Parser.string(body).parse
    session[:oauth_facebook_access_token_token] = access_token.token
    session[:oauth_facebook_access_token_secret] = access_token.secret
    if oauth_request.user && data
      service_user_id = data.find("id")[0].content
      service_user_name = data.find("first-name")[0].content + " " + data.find("last-name")[0].content
      service_url = data.find("public-profile-url")[0].content
      UserService.register(
        :service => "facebook", 
        :access_token => access_token, 
        :user => oauth_request.user,
        :service_domain => "facebook.com",
        :service_user_id => service_user_id,
        :service_user_name => service_user_name,
        :service_user_url => service_url
      )
      session[:oauth_facebook_access_token_token] = nil
      session[:oauth_facebook_access_token_secret] = nil
    end
    access_token
  end
  
  def facebook_request_token_url(return_to)
    consumer = facebook_consumer
    request_token = consumer.get_request_token({}, :oauth_callback => oauth_success_url(:service => 'facebook', :user => session[:oauth_facebook_user_secret]))
    session[:oauth_facebook_token] = request_token.token
    session[:oauth_facebook_secret] = request_token.secret
    OauthRequest.create(
      :service => 'facebook',
      :token => request_token.token,
      :secret => request_token.secret,
      :return_url => return_to,
      :user => @current_user,
      :original_host_with_port => request.host_with_port
    )
    request_token.authorize_url
  end
  
  def facebook_send(message, access_token=nil)
    access_token ||= facebook_retrieve_access_token
    response = access_token.post("/statuses/update.json", {:status => message})
    res = ActiveSupport::JSON.decode(response.body)
    res
  end
  
  def facebook_list(access_token=nil, since_id=nil)
    access_token ||= facebook_retrieve_access_token
    url = "/statuses/user_timeline.json"
    url += "?since_id=#{since_id}" if since_id
    response = access_token.get(url)
    case response
    when Net::HTTPSuccess
      return ActiveSupport::JSON.decode(response.body) rescue []
    else
      data = ActiveSupport::JSON.decode(response.body) rescue nil
      if data && data['errors'] && data['errors'].match(/requires authentication/)
        @service.destroy if @service
        @facebook_service.destroy if @facebook_service
      end
      ErrorLogging.log_error(:processing, {
        :backtrace => "Retrieving facebook list for #{@facebook_service.inspect}",
        :response => response.inspect,
        :body => response.body,
        :message => response['X-RateLimit-Reset'],
        :url => url
      })
      retry_after = (response['X-RateLimit-Reset'].to_i - Time.now.utc.to_i) rescue 0 #response['Retry-After'].to_i rescue 0
      raise "Retry After #{retry_after}"
    end
    res
  end
  
  def facebook_consumer
    require 'oauth'
    require 'oauth/consumer'
    key = "LgR3JqsPBoxJ66YpD8Uf40ERj8O7tKDUI3rmF3Gqr5NbxftcUpilYaquFU_nDwX5"
    secret = "glzBPo4q0fbxDQS1a5hdyKIdb_Bp9MwcC53LiUo5fWo50pN3XcVoOoXix6SsTTg7"
    req = request || nil rescue nil
    consumer = OAuth::Consumer.new(key, secret, {
      :site => "https://api.linkedin.com",
      :request_token_path => "/uas/oauth/requestToken",
      :access_token_path => "/uas/oauth/accessToken",
      :authorize_path=> "/uas/oauth/authorize",
      :signature_method => "HMAC-SHA1"
    })
  end
  
end