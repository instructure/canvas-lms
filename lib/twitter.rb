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

module Twitter

  def twitter_retrieve_access_token(token=nil, secret=nil)
    consumer = twitter_consumer
    if token && secret
      access_token = OAuth::AccessToken.new(consumer, token, secret)
    elsif @current_user
      service = @current_user.user_services.find_by_service("twitter")
      @twitter_service = service
      access_token = OAuth::AccessToken.new(consumer, service.token, service.secret)
    elsif @twitter_service
      access_token = OAuth::AccessToken.new(consumer, @twitter_service.token, @twitter_service.secret)
    else
      access_token = OAuth::AccessToken.new(consumer, session[:oauth_twitter_access_token_token], session[:oauth_twitter_access_token_secret])
    end
    access_token
  end
  
  def twitter_generate_token(token, secret)
    OAuth::AccessToken.new(twitter_consumer, token, secret)
  end

  def twitter_get_service_user(access_token)
    credentials = JSON.parse(access_token.get('/1/account/verify_credentials.json').body)
    service_user_id = credentials["id"]
    service_user_name = credentials["screen_name"]
    return service_user_id, service_user_name
  end
  
  def twitter_get_access_token(oauth_request, oauth_verifier)
    consumer = twitter_consumer
    request_token = OAuth::RequestToken.new(consumer,
                                            session.delete(:oauth_twitter_request_token_token),
                                            session.delete(:oauth_twitter_request_token_secret))
    access_token = request_token.get_access_token(:oauth_verifier => oauth_verifier)
    service_user_id, service_user_name = twitter_get_service_user(access_token)
    session[:oauth_twitter_access_token_token] = access_token.token
    session[:oauth_twitter_access_token_secret] = access_token.secret
    if oauth_request.user
      @twitter_service = UserService.register(
        :service => "twitter", 
        :access_token => access_token, 
        :user => oauth_request.user,
        :service_domain => "twitter.com",
        :service_user_id => service_user_id,
        :service_user_name => service_user_name
      )
      session.delete(:oauth_twitter_access_token_token)
      session.delete(:oauth_twitter_access_token_secret)
    end
    access_token
  end
  
  def twitter_request_token_url(return_to)
    consumer = twitter_consumer
    request_token = consumer.get_request_token(:oauth_callback => oauth_success_url(:service => 'twitter'))
    session[:oauth_twitter_request_token_token] = request_token.token
    session[:oauth_twitter_request_token_secret] = request_token.secret
    OauthRequest.create(
      :service => 'twitter',
      :token => request_token.token,
      :secret => request_token.secret,
      :return_url => return_to,
      :user => @current_user,
      :original_host_with_port => request.host_with_port
    )
    request_token.authorize_url
  end
  
  def twitter_send(message, access_token=nil)
    access_token ||= twitter_retrieve_access_token
    response = access_token.post("/1/statuses/update.json", {:status => message})
    res = JSON.parse(response.body)
    res
  end
  
  def twitter_self_dm(service, message)
    @twitter_service = service
    access_token = twitter_retrieve_access_token
    response = access_token.post("/1/direct_messages/new.json", {:screen_name => service.service_user_name, :user_id => service.service_user_id, :text => message})
    res = JSON.parse(response.body)
    res
  end
  
  def twitter_list(access_token=nil, since_id=nil)
    access_token ||= twitter_retrieve_access_token
    url = "/1/statuses/user_timeline.json"
    url += "?since_id=#{since_id}" if since_id
    response = access_token.get(url)
    case response
    when Net::HTTPSuccess
      return JSON.parse(response.body) rescue []
    else
      data = JSON.parse(response.body) rescue nil
      if data && data['error'] && data['error'].match(/requires authentication/)
        @service.destroy if @service
        @twitter_service.destroy if @twitter_service
      end
      ErrorReport.log_error(:processing, {
        :backtrace => "Retrieving twitter list for #{@twitter_service.inspect}",
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
  
  def twitter_consumer(key=nil, secret=nil)
    require 'oauth'
    require 'oauth/consumer'
    twitter_config = Twitter.config
    key ||= twitter_config['api_key']
    secret ||= twitter_config['secret_key']
    consumer = OAuth::Consumer.new(key, secret, {
      :site => "http://api.twitter.com",
      :request_token_path => "/oauth/request_token",
      :access_token_path => "/oauth/access_token",
      :authorize_path=> "/oauth/authorize",
      :signature_method => "HMAC-SHA1"
    })
  end
  
  def self.config_check(settings)
    o = Object.new
    o.extend(Twitter)
    consumer = o.twitter_consumer(settings[:api_key], settings[:secret_key])
    token = consumer.get_request_token rescue nil
    token ? nil : "Configuration check failed, please check your settings"
  end
  
  def self.config
    Canvas::Plugin.find(:twitter).try(:settings) || Setting.from_config('twitter')
  end
  
end
