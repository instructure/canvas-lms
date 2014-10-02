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

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')

describe LtiApiController, type: :integration do
  before :once do
    user_with_pseudonym(:username => 'parajsa', :password => 'password1')
    course_with_student(:active_all => true, :user => @user)
    @tool = @course.context_external_tools.create(:shared_secret => 'test_secret', :consumer_key => 'test_key', :name => 'logout service test tool', :domain => 'example.com')
    @tool.url = 'https://example.edu/tool-launch-url'
    @tool.course_navigation = {
        :enabled => "true"
    }
    @tool.custom_fields = {
        "sub_logout_service_url" => "$Canvas.logoutService.url"
    }
    @tool.save!
  end

  def api_path(token = nil, callback = nil)
    token ||= Lti::LogoutService.create_token(@tool, @pseudonym)
    callback ||= 'http://logout.notify.example.com'
    "/api/lti/v1/logout_service/#{token}?#{{callback: callback}.to_query}"
  end

  def make_call(opts = {})
    opts['path'] ||= api_path
    opts['key'] ||= @tool.consumer_key
    opts['secret'] ||= @tool.shared_secret
    consumer = OAuth::Consumer.new(opts['key'], opts['secret'], :site => "http://www.example.com", :signature_method => "HMAC-SHA1")
    req = consumer.create_signed_request(:post, opts['path'], nil, :scheme => 'header', :timestamp => opts['timestamp'], :nonce => opts['nonce'])
    req.body = opts['body'] if opts['body']
    post "http://www.example.com#{req.path}",
         req.body,
         { "CONTENT_TYPE" => opts['content-type'], "HTTP_AUTHORIZATION" => req['Authorization'] }
  end

  it "should generate a logout service URL with token" do
    user_session(@student)
    get "/courses/#{@course.id}/external_tools/#{@tool.id}"
    response.should be_success
    doc = Nokogiri::HTML(response.body)
    logout_service_url = doc.css('#custom_sub_logout_service_url').attr('value').value
    match = %r{\Ahttp://www.example.com/api/lti/v1/logout_service/([a-z0-9-]+)\z}.match(logout_service_url)
    match.should_not be_nil
    token = Lti::LogoutService::Token.parse_and_validate(match[1])
    token.tool.should eql(@tool)
    token.pseudonym.should eql(@pseudonym)
  end

  it "should reject an invalid secret" do
    make_call('secret' => 'not secret')
    response.status.should eql 401
    response.body.should =~ /Invalid authorization header/
  end

  it "should reject an invalid token" do
    token_parts = Lti::LogoutService.create_token(@tool, @pseudonym).split('-')
    # falsify the pseudonym to try and get notified when somebody else logs out
    token_parts[1] = (token_parts[1].to_i + 1).to_s
    make_call('path' => api_path(token_parts.join('-')))
    response.status.should eql 401
    response.body.should =~ /Invalid logout service token/
  end

  it "should reject an expired token" do
    token = Timecop.freeze(15.minutes.ago) do
      Lti::LogoutService.create_token(@tool, @pseudonym)
    end
    make_call('path' => api_path(token))
    response.status.should eql 401
    response.body.should =~ /Logout service token has expired/
  end

  it "should register callbacks" do
    enable_cache do
      token1 = Lti::LogoutService.create_token(@tool, @pseudonym)
      make_call('path' => api_path(token1, 'http://logout.notify.example.com/123'))
      token2 = Lti::LogoutService.create_token(@tool, @pseudonym)
      make_call('path' => api_path(token2, 'http://logout.notify.example.com/456'))
      Lti::LogoutService.get_logout_callbacks(@pseudonym).values.should =~ [
          'http://logout.notify.example.com/123',
          'http://logout.notify.example.com/456'
      ]
    end
  end

  it "should reject reused tokens" do
    enable_cache do
      token = Lti::LogoutService.create_token(@tool, @pseudonym)
      make_call('path' => api_path(token, 'http://logout.notify.example.com/123'))
      response.should be_success
      make_call('path' => api_path(token, 'http://logout.notify.example.com/456'))
      response.status.should eql 401
      response.body.should =~ /Logout service token has already been used/
    end
  end

  it "should call registered callbacks when the user logs out" do
    enable_cache do
      login_as 'parajsa', 'password1'
      token = Lti::LogoutService::Token.create(@tool, @pseudonym)
      Lti::LogoutService.register_logout_callback(token, 'http://logout.notify.example.com/789')
      Net::HTTP.expects(:get).with(URI('http://logout.notify.example.com/789'))
      delete '/logout'
      run_jobs
    end
  end
end
