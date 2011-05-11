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

  def twitter_retrieve_access_token
    consumer = twitter_consumer
    if @current_user
      @service = @current_user.user_services.find_by_service("twitter")
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
  
  def twitter_get_access_token(oauth_request)
    consumer = twitter_consumer
    request_token = OAuth::RequestToken.new(consumer, oauth_request.token, oauth_request.secret)
    access_token = request_token.get_access_token
    credentials = ActiveSupport::JSON.decode(access_token.get('/account/verify_credentials.json').body)
    session[:oauth_twitter_access_token_token] = access_token.token
    session[:oauth_twitter_access_token_secret] = access_token.secret
    if oauth_request.user
      service_user_id = credentials["id"]
      service_user_name = credentials["screen_name"]
      UserService.register(
        :service => "twitter", 
        :access_token => access_token, 
        :user => oauth_request.user,
        :service_domain => "twitter.com",
        :service_user_id => service_user_id,
        :service_user_name => service_user_name
      )
      session[:oauth_twitter_access_token_token] = nil
      session[:oauth_twitter_access_token_secret] = nil
    end
    access_token
  end
  
  def twitter_request_token_url(return_to)
    consumer = twitter_consumer
    request_token = consumer.get_request_token
    session[:oauth_twitter_token] = request_token.token
    session[:oauth_twitter_secret] = request_token.secret
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
    response = access_token.post("/statuses/update.json", {:status => message})
    res = ActiveSupport::JSON.decode(response.body)
    res
  end
  
  def twitter_list(access_token=nil, since_id=nil)
    access_token ||= twitter_retrieve_access_token
    url = "/statuses/user_timeline.json"
    url += "?since_id=#{since_id}" if since_id
    response = access_token.get(url)
    case response
    when Net::HTTPSuccess
      return ActiveSupport::JSON.decode(response.body) rescue []
    else
      data = ActiveSupport::JSON.decode(response.body) rescue nil
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
  
  def twitter_consumer
    require 'oauth'
    require 'oauth/consumer'
    twitter_config = Twitter.config
    key = twitter_config['api_key']
    secret = twitter_config['secret_key']
    req = request || nil rescue nil
    consumer = OAuth::Consumer.new(key, secret, {
      :site => "http://twitter.com",
      :request_token_path => "/oauth/request_token",
      :access_token_path => "/oauth/access_token",
      :authorize_path=> "/oauth/authorize",
      :signature_method => "HMAC-SHA1"
    })
  end
  
  def self.config
    # Return existing value, even if nil, as long as it's defined
    return @twitter_config if defined?(@twitter_config)
    @twitter_config ||= YAML.load_file(RAILS_ROOT + "/config/twitter.yml")[RAILS_ENV] rescue nil
  end
  
end
