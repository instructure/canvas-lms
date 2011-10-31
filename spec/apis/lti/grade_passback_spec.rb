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

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')

describe LtiApiController, :type => :integration do
  before do
    course_with_student(:active_all => true)
    @student = @user
    assignment_model
    @course.enroll_teacher(user_with_pseudonym(:active_all => true))
    @tool = @course.context_external_tools.create!(:shared_secret => 'test_secret', :consumer_key => 'test_key', :name => 'my grade passback test tool')
  end

  def make_call(opts = {})
    opts['path'] ||= "/api/lti/tools/#{@tool.id}/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}"
    opts['key'] ||= @tool.consumer_key
    opts['secret'] ||= @tool.shared_secret
    opts['content-type'] ||= 'application/xml'
    consumer = OAuth::Consumer.new(opts['key'], opts['secret'], :site => "https://www.example.com", :signature_method => "HMAC-SHA1")
    req = consumer.create_signed_request(:post, opts['path'], nil, :scheme => 'header', :timestamp => opts['timestamp'], :nonce => opts['nonce'])
    req.body = opts['body'] if opts['body']
    post "https://www.example.com#{req.path}",
      req.body,
      { "content-type" => opts['content-type'], "Authorization" => req['Authorization'] }
  end

  it "should respond 'unsupported' for any unknown xml body" do
    body = %{<imsx_POXEnvelopeRequest xmlns = "http://www.imsglobal.org/lis/oms1p0/pox"></imsx_POXEnvelopeRequest>}
    make_call('body' => body)
    response.should be_success
    response.content_type.should == 'application/xml'
    Nokogiri::XML.parse(response.body).at_css('imsx_POXEnvelopeResponse > imsx_POXHeader > imsx_POXResponseHeaderInfo > imsx_statusInfo > imsx_codeMajor').content.should == 'unsupported'
  end

  it "should require a content-type of application/xml" do
    make_call('content-type' => 'application/other')
    response.status.should == "415 Unsupported Media Type"
  end

  it "should require the correct shared secret" do
    make_call('secret' => 'bad secret is bad')
    response.status.should == "401 Unauthorized"
  end

  it "should not allow the same nonce to be used more than once" do
    make_call('nonce' => 'not_so_random', 'content-type' => 'none')
    response.status.should == "415 Unsupported Media Type"
    make_call('nonce' => 'not_so_random', 'content-type' => 'none')
    pending("start tracking nonces") do
      response.status.should == "401 Unauthorized"
      response.body.should match(/nonce/i)
    end
  end

  it "should block timestamps more than 90 minutes old" do
    # the 90 minutes value is suggested by the LTI spec
    make_call('timestamp' => 2.hours.ago.to_i, 'content-type' => 'none')
    pending("start verifying timestamps") do
      response.status.should == "401 Unauthorized"
      response.body.should match(/expired/i)
    end
  end
end
