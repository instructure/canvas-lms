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
  def linked_in_get_service_user(access_token)
    body = access_token.get('/v1/people/~:(id,first-name,last-name,public-profile-url,picture-url)').body
    data = Nokogiri::XML(body)
    service_user_id = data.css("id")[0].content
    service_user_name = data.css("first-name")[0].content + " " + data.css("last-name")[0].content
    service_user_url = data.css("public-profile-url")[0].content
    return service_user_id, service_user_name, service_user_url
  end
  
  def linked_in_get_access_token(oauth_request, oauth_verifier)
    consumer = linked_in_consumer
    request_token = OAuth::RequestToken.new(consumer,
                                            session.delete(:oauth_linked_in_request_token_token),
                                            session.delete(:oauth_linked_in_request_token_secret))
    access_token = request_token.get_access_token(:oauth_verifier => oauth_verifier)
    service_user_id, service_user_name, service_user_url = linked_in_get_service_user(access_token)
    session[:oauth_linked_in_access_token_token] = access_token.token
    session[:oauth_linked_in_access_token_secret] = access_token.secret
    if oauth_request.user
      UserService.register(
        :service => "linked_in", 
        :access_token => access_token, 
        :user => oauth_request.user,
        :service_domain => "linked_in.com",
        :service_user_id => service_user_id,
        :service_user_name => service_user_name,
        :service_user_url => service_user_url
      )
      session.delete(:oauth_linked_in_access_token_token)
      session.delete(:oauth_linked_in_access_token_secret)
    end
    access_token
  end
  
  def linked_in_request_token_url(return_to)
    consumer = linked_in_consumer
    request_token = consumer.get_request_token(:oauth_callback => oauth_success_url(:service => 'linked_in'))
    session[:oauth_linked_in_request_token_token] = request_token.token
    session[:oauth_linked_in_request_token_secret] = request_token.secret
    OauthRequest.create(
      :service => 'linked_in',
      :token => request_token.token,
      :secret => request_token.secret,
      :return_url => return_to,
      :user => @current_user,
      :original_host_with_port => request.host_with_port
    )
    request_token.authorize_url
  end
  
  def linked_in_consumer(key=nil, secret=nil)
    require 'oauth'
    require 'oauth/consumer'
    config = LinkedIn.config
    key ||= config['api_key']
    secret ||= config['secret_key']
    OAuth::Consumer.new(key, secret, {
      :site => "https://api.linkedin.com",
      :request_token_path => "/uas/oauth/requestToken",
      :access_token_path => "/uas/oauth/accessToken",
      :authorize_path=> "/uas/oauth/authorize",
      :signature_method => "HMAC-SHA1"
    })
  end
  
  def self.config_check(settings)
    o = Object.new
    o.extend(LinkedIn)
    consumer = o.linked_in_consumer(settings[:api_key], settings[:secret_key])
    token = consumer.get_request_token rescue nil
    token ? nil : "Configuration check failed, please check your settings"
  end
  
  def self.config
    Canvas::Plugin.find(:linked_in).try(:settings) || Setting.from_config('linked_in')
  end
  
end
