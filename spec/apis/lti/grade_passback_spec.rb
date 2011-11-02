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
    @course.enroll_teacher(user_with_pseudonym(:active_all => true))
    @tool = @course.context_external_tools.create!(:shared_secret => 'test_secret', :consumer_key => 'test_key', :name => 'my grade passback test tool')
    assignment_model(:course => @course, :context_external_tool => @tool, :name => 'tool assignment', :submission_types => 'external_tool', :points_possible => 20, :grading_type => 'points')
  end

  def make_call(opts = {})
    opts['path'] ||= "/api/lti/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}"
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
    check_unsupported
  end

  it "should require a content-type of application/xml" do
    make_call('content-type' => 'application/other')
    response.status.should == "415 Unsupported Media Type"
  end

  it "should require the correct shared secret" do
    make_call('secret' => 'bad secret is bad')
    response.status.should == "401 Unauthorized"
  end

  def replace_result(score, sourceid = nil)
    sourceid ||= BasicLTI::BasicOutcomes.result_source_id(@tool, @course, @assignment, @student)
    body = %{
<?xml version = "1.0" encoding = "UTF-8"?>
<imsx_POXEnvelopeRequest xmlns = "http://www.imsglobal.org/lis/oms1p0/pox">
  <imsx_POXHeader>
    <imsx_POXRequestHeaderInfo>
      <imsx_version>V1.0</imsx_version>
      <imsx_messageIdentifier>999999123</imsx_messageIdentifier>
    </imsx_POXRequestHeaderInfo>
  </imsx_POXHeader>
  <imsx_POXBody>
    <replaceResultRequest>
      <resultRecord>
        <sourcedGUID>
          <sourcedId>#{sourceid}</sourcedId>
        </sourcedGUID>
        <result>
          <resultScore>
            <language>en</language>
            <textString>#{score}</textString>
          </resultScore>
        </result>
      </resultRecord>
    </replaceResultRequest>
  </imsx_POXBody>
</imsx_POXEnvelopeRequest>
    }
  end

  def check_unsupported
    response.should be_success
    Nokogiri::XML.parse(response.body).at_css('imsx_POXEnvelopeResponse > imsx_POXHeader > imsx_POXResponseHeaderInfo > imsx_statusInfo > imsx_codeMajor').content.should == 'unsupported'
    @assignment.submissions.find_by_user_id(@student.id).should be_nil
  end

  it "should allow updating the submission score" do
    @assignment.submissions.find_by_user_id(@student.id).should be_nil
    make_call('body' => replace_result('0.6'))
    response.should be_success
    response.content_type.should == 'application/xml'

    xml = Nokogiri::XML.parse(response.body)
    xml.at_css('imsx_codeMajor').content.should == 'success'
    xml.at_css('imsx_messageRefIdentifier').content.should == '999999123'
    xml.at_css('imsx_operationRefIdentifier').content.should == 'replaceResult'
    submission = @assignment.submissions.find_by_user_id(@student.id)
    submission.should be_present
    submission.score.should == 12
  end

  it "should reject scores < 0.0, but allow 0.0" do
    @assignment.submissions.find_by_user_id(@student.id).should be_nil
    make_call('body' => replace_result('-1'))
    check_unsupported

    make_call('body' => replace_result('0.0'))
    response.should be_success
    submission = @assignment.submissions.find_by_user_id(@student.id)
    submission.should be_present
    submission.score.should == 0
  end

  it "should reject non-numeric scores" do
    @assignment.submissions.find_by_user_id(@student.id).should be_nil
    make_call('body' => replace_result("OHAI SCORES"))
    check_unsupported
  end

  it "should reject if the assignment doesn't use this tool" do
    tool = @course.context_external_tools.create!(:shared_secret => 'test_secret_2', :consumer_key => 'test_key_2', :name => 'new tool')
    @assignment.update_attribute(:context_external_tool, tool)
    make_call('body' => replace_result('0.5'))
    response.status.should == "401 Unauthorized"
  end

  it "should be unsupported if the assignment switched to a new tool with the same shared secret" do
    tool = @course.context_external_tools.create!(:shared_secret => 'test_secret', :consumer_key => 'test_key', :name => 'new tool')
    @assignment.update_attribute(:context_external_tool, tool)
    make_call('body' => replace_result('0.5'))
    check_unsupported
  end

  it "should reject if the assignment is no longer a tool assignment" do
    @assignment.update_attributes(:context_external_tool => nil, :submission_types => 'online_upload')
    make_call('body' => replace_result('0.5'))
    response.status.should == "401 Unauthorized"
  end

  it "should verify the sourcedid is correct for this tool launch" do
    make_call('body' => replace_result('0.6', 'BAD SOURCE ID'))
    check_unsupported
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
