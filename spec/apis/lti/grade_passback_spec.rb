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
    @tool = @course.context_external_tools.create!(:shared_secret => 'test_secret', :consumer_key => 'test_key', :name => 'my grade passback test tool', :domain => 'example.com')
    assignment_model(:course => @course, :name => 'tool assignment', :submission_types => 'external_tool', :points_possible => 20, :grading_type => 'points')
    tag = @assignment.build_external_tool_tag(:url => "http://example.com/one")
    tag.content_type = 'ContextExternalTool'
    tag.save!
  end

  def make_call(opts = {})
    opts['path'] ||= "/api/lti/v1/tools/#{@tool.id}/grade_passback"
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
    check_failure
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
    sourceid ||= BasicLTI::BasicOutcomes.encode_source_id(@tool, @course, @assignment, @student)
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

  def read_result(sourceid = nil)
    sourceid ||= BasicLTI::BasicOutcomes.encode_source_id(@tool, @course, @assignment, @student)
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
    <readResultRequest>
      <resultRecord>
        <sourcedGUID>
          <sourcedId>#{sourceid}</sourcedId>
        </sourcedGUID>
      </resultRecord>
    </readResultRequest>
  </imsx_POXBody>
</imsx_POXEnvelopeRequest>
    }
  end

  def delete_result(sourceid = nil)
    sourceid ||= BasicLTI::BasicOutcomes.encode_source_id(@tool, @course, @assignment, @student)
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
    <deleteResultRequest>
      <resultRecord>
        <sourcedGUID>
          <sourcedId>#{sourceid}</sourcedId>
        </sourcedGUID>
      </resultRecord>
    </deleteResultRequest>
  </imsx_POXBody>
</imsx_POXEnvelopeRequest>
    }
  end

  def check_failure(failure_type = 'unsupported')
    response.should be_success
    response.content_type.should == 'application/xml'
    Nokogiri::XML.parse(response.body).at_css('imsx_POXEnvelopeResponse > imsx_POXHeader > imsx_POXResponseHeaderInfo > imsx_statusInfo > imsx_codeMajor').content.should == failure_type
    @assignment.submissions.find_by_user_id(@student.id).should be_nil
  end

  def check_success
    response.should be_success
    response.content_type.should == 'application/xml'
    Nokogiri::XML.parse(response.body).at_css('imsx_POXEnvelopeResponse > imsx_POXHeader > imsx_POXResponseHeaderInfo > imsx_statusInfo > imsx_codeMajor').content.should == 'success'
  end

  describe "replaceResult" do
    it "should allow updating the submission score" do
      @assignment.submissions.find_by_user_id(@student.id).should be_nil
      make_call('body' => replace_result('0.6'))
      check_success

      xml = Nokogiri::XML.parse(response.body)
      xml.at_css('imsx_codeMajor').content.should == 'success'
      xml.at_css('imsx_messageRefIdentifier').content.should == '999999123'
      xml.at_css('imsx_operationRefIdentifier').content.should == 'replaceResult'
      xml.at_css('imsx_POXBody *:first').name.should == 'replaceResultResponse'
      submission = @assignment.submissions.find_by_user_id(@student.id)
      submission.should be_present
      submission.should be_graded
      submission.should be_submitted_at
      submission.submission_type.should eql 'external_tool'
      submission.score.should == 12
    end

    it "should reject out of bound scores" do
      @assignment.submissions.find_by_user_id(@student.id).should be_nil
      make_call('body' => replace_result('-1'))
      check_failure('failure')
      make_call('body' => replace_result('1.1'))
      check_failure('failure')

      make_call('body' => replace_result('0.0'))
      check_success
      submission = @assignment.submissions.find_by_user_id(@student.id)
      submission.should be_present
      submission.score.should == 0

      make_call('body' => replace_result('1.0'))
      check_success
      submission = @assignment.submissions.find_by_user_id(@student.id)
      submission.should be_present
      submission.score.should == 20
    end

    it "should reject non-numeric scores" do
      @assignment.submissions.find_by_user_id(@student.id).should be_nil
      make_call('body' => replace_result("OHAI SCORES"))
      check_failure('failure')
    end
  end

  describe "readResult" do
    it "should return an empty string when no grade exists" do
      make_call('body' => read_result)
      check_success

      xml = Nokogiri::XML.parse(response.body)
      xml.at_css('imsx_codeMajor').content.should == 'success'
      xml.at_css('imsx_messageRefIdentifier').content.should == '999999123'
      xml.at_css('imsx_operationRefIdentifier').content.should == 'readResult'
      xml.at_css('imsx_POXBody *:first').name.should == 'readResultResponse'
      xml.at_css('imsx_POXBody > readResultResponse > result > resultScore > language').content.should == 'en'
      xml.at_css('imsx_POXBody > readResultResponse > result > resultScore > textString').content.should == ''
    end

    it "should return the score if the assignment is scored" do
      @assignment.grade_student(@student, :grade => "40%")

      make_call('body' => read_result)
      check_success

      xml = Nokogiri::XML.parse(response.body)
      xml.at_css('imsx_codeMajor').content.should == 'success'
      xml.at_css('imsx_messageRefIdentifier').content.should == '999999123'
      xml.at_css('imsx_operationRefIdentifier').content.should == 'readResult'
      xml.at_css('imsx_POXBody *:first').name.should == 'readResultResponse'
      xml.at_css('imsx_POXBody > readResultResponse > result > resultScore > language').content.should == 'en'
      xml.at_css('imsx_POXBody > readResultResponse > result > resultScore > textString').content.should == '0.4'
    end
  end

  describe "deleteResult" do
    it "should succeed but do nothing when the submission isn't graded" do
      make_call('body' => delete_result)
      check_success
      xml = Nokogiri::XML.parse(response.body)
      xml.at_css('imsx_codeMajor').content.should == 'success'
      xml.at_css('imsx_messageRefIdentifier').content.should == '999999123'
      xml.at_css('imsx_operationRefIdentifier').content.should == 'deleteResult'
      xml.at_css('imsx_POXBody *:first').name.should == 'deleteResultResponse'
    end

    it "should delete the existing score for the submission (by creating a new version)" do
      @assignment.grade_student(@student, :grade => "40%")

      make_call('body' => delete_result)
      check_success
      xml = Nokogiri::XML.parse(response.body)
      xml.at_css('imsx_codeMajor').content.should == 'success'
      xml.at_css('imsx_messageRefIdentifier').content.should == '999999123'
      xml.at_css('imsx_operationRefIdentifier').content.should == 'deleteResult'
      xml.at_css('imsx_POXBody *:first').name.should == 'deleteResultResponse'

      @assignment.submission_for_student(@student).should_not be_graded
      @assignment.submission_for_student(@student).score.should be_nil
    end
  end

  it "should reject if the assignment doesn't use this tool" do
    tool = @course.context_external_tools.create!(:shared_secret => 'test_secret_2', :consumer_key => 'test_key_2', :name => 'new tool', :domain => 'example.net')
    @assignment.external_tool_tag.destroy!
    @assignment.external_tool_tag = nil
    tag = @assignment.build_external_tool_tag(:url => "http://example.net/one")
    tag.content_type = 'ContextExternalTool'
    tag.save!
    make_call('body' => replace_result('0.5'))
    check_failure
  end

  it "should be unsupported if the assignment switched to a new tool with the same shared secret" do
    tool = @course.context_external_tools.create!(:shared_secret => 'test_secret', :consumer_key => 'test_key', :name => 'new tool', :domain => 'example.net')
    @assignment.external_tool_tag.destroy!
    @assignment.external_tool_tag = nil
    tag = @assignment.build_external_tool_tag(:url => "http://example.net/one")
    tag.content_type = 'ContextExternalTool'
    tag.save!
    make_call('body' => replace_result('0.5'))
    check_failure
  end

  it "should reject if the assignment is no longer a tool assignment" do
    @assignment.update_attributes(:submission_types => 'online_upload')
    @assignment.external_tool_tag.destroy!
    make_call('body' => replace_result('0.5'))
    check_failure
  end

  it "should verify the sourcedid is correct for this tool launch" do
    make_call('body' => replace_result('0.6', 'BAD SOURCE ID'))
    check_failure
  end

  if Canvas.redis_enabled?
    it "should not allow the same nonce to be used more than once" do
      make_call('nonce' => 'not_so_random', 'content-type' => 'none')
      response.status.should == "415 Unsupported Media Type"
      make_call('nonce' => 'not_so_random', 'content-type' => 'none')
      response.status.should == "401 Unauthorized"
      response.body.should match(/nonce/i)
    end
  end

  it "should block timestamps more than 90 minutes old" do
    # the 90 minutes value is suggested by the LTI spec
    make_call('timestamp' => 2.hours.ago.utc.to_i, 'content-type' => 'none')
    response.status.should == "401 Unauthorized"
    response.body.should match(/expired/i)
  end

  describe "blti extensions 0.0.4" do
    def make_call(opts = {})
      opts['path'] ||= "/api/lti/v1/tools/#{@tool.id}/ext_grade_passback"
      opts['key'] ||= @tool.consumer_key
      opts['secret'] ||= @tool.shared_secret
      consumer = OAuth::Consumer.new(opts['key'], opts['secret'], :site => "https://www.example.com", :signature_method => "HMAC-SHA1")
      req = consumer.create_signed_request(:post, opts['path'], nil, { :scheme => 'header', :timestamp => opts['timestamp'], :nonce => opts['nonce'] }, opts['body'])
      post "https://www.example.com#{req.path}",
        req.body,
        { 'content-type' => 'application/x-www-form-urlencoded', "Authorization" => req['Authorization'] }
    end

    it "should require the correct shared secret" do
      make_call('secret' => 'bad secret is bad')
      response.status.should == "401 Unauthorized"
    end

    def sourceid
      BasicLTI::BasicOutcomes.encode_source_id(@tool, @course, @assignment, @student)
    end

    def update_result(score, sourcedid = nil)
      sourcedid ||= sourceid
      body = {
        'lti_message_type' => 'basic-lis-updateresult',
        'sourcedid' => sourcedid,
        'result_resultscore_textstring' => score.to_s,
      }
    end

    def read_result(sourcedid = nil)
      sourcedid ||= sourceid
      body = {
        'lti_message_type' => 'basic-lis-readresult',
        'sourcedid' => sourcedid,
      }
    end

    def delete_result(sourcedid = nil)
      sourcedid ||= sourceid
      body = {
        'lti_message_type' => 'basic-lis-deleteresult',
        'sourcedid' => sourcedid,
      }
    end

    def check_success
      response.should be_success
      response.content_type.should == 'application/xml'
      xml = Nokogiri::XML.parse(response.body)
      xml.at_css('message_response > statusinfo > codemajor').content.should == 'Success'
      xml.at_css('message_response > statusinfo > codeminor').content.should == 'fullsuccess'
      xml
    end

    def check_failure(failure_type = 'Unsupported')
      response.should be_success
      response.content_type.should == 'application/xml'
      xml = Nokogiri::XML.parse(response.body)
      xml.at_css('message_response > statusinfo > codemajor').content.should == failure_type
      @assignment.submissions.find_by_user_id(@student.id).should be_nil
      xml
    end

    describe "basic-lis-updateresult" do
      it "should allow updating the submission score" do
        @assignment.submissions.find_by_user_id(@student.id).should be_nil
        make_call('body' => update_result('0.6'))
        xml = check_success

        xml.at_css('message_response > result > sourcedid').content.should == sourceid
        xml.at_css('message_response > result > resultscore > resultvaluesourcedid').content.should == 'decimal'
        xml.at_css('message_response > result > resultscore > textstring').content.should == '0.6'
        submission = @assignment.submissions.find_by_user_id(@student.id)
        submission.should be_present
        submission.should be_graded
        submission.score.should == 12
      end

      it "should reject out of bound scores" do
        @assignment.submissions.find_by_user_id(@student.id).should be_nil
        make_call('body' => update_result('-1'))
        check_failure('Failure')
        make_call('body' => update_result('1.1'))
        check_failure('Failure')

        make_call('body' => update_result('0.0'))
        check_success
        submission = @assignment.submissions.find_by_user_id(@student.id)
        submission.should be_present
        submission.score.should == 0

        make_call('body' => update_result('1.0'))
        check_success
        submission = @assignment.submissions.find_by_user_id(@student.id)
        submission.should be_present
        submission.score.should == 20
      end

      it "should reject non-numeric scores" do
        @assignment.submissions.find_by_user_id(@student.id).should be_nil
        make_call('body' => update_result("OHAI SCORES"))
        check_failure('Failure')
      end
    end

    describe "basic-lis-readresult" do
      it "should return xml without result when no grade exists" do
        make_call('body' => read_result)
        xml = check_success
        xml.at_css('message_response result').should be_nil
      end

      it "should return the score if the assignment is scored" do
        @assignment.grade_student(@student, :grade => "40%")

        make_call('body' => read_result)
        xml = check_success
        xml.at_css('message_response > result > sourcedid').content.should == sourceid
        xml.at_css('message_response > result > resultscore > textstring').content.should == '0.4'
      end
    end

    describe "basic-lis-deleteresult" do
      it "should succeed but do nothing when the submission isn't graded" do
        make_call('body' => delete_result)
        xml = check_success
        xml.at_css('message_response result').should be_nil
      end

      it "should delete the existing score for the submission (by creating a new version)" do
        @assignment.grade_student(@student, :grade => "40%")

        make_call('body' => delete_result)
        xml = check_success
        xml.at_css('message_response result').should be_nil

        @assignment.submission_for_student(@student).should_not be_graded
        @assignment.submission_for_student(@student).score.should be_nil
      end
    end

    it "should reject if the assignment doesn't use this tool" do
      tool = @course.context_external_tools.create!(:shared_secret => 'test_secret_2', :consumer_key => 'test_key_2', :name => 'new tool', :domain => 'example.net')
      @assignment.external_tool_tag.destroy!
      @assignment.external_tool_tag = nil
      tag = @assignment.build_external_tool_tag(:url => "http://example.net/one")
      tag.content_type = 'ContextExternalTool'
      tag.save!
      make_call('body' => update_result('0.5'))
      check_failure
    end

    it "should be unsupported if the assignment switched to a new tool with the same shared secret" do
      tool = @course.context_external_tools.create!(:shared_secret => 'test_secret', :consumer_key => 'test_key', :name => 'new tool', :domain => 'example.net')
      @assignment.external_tool_tag.destroy!
      @assignment.external_tool_tag = nil
      tag = @assignment.build_external_tool_tag(:url => "http://example.net/one")
      tag.content_type = 'ContextExternalTool'
      tag.save!
      make_call('body' => update_result('0.5'))
      check_failure
    end

    it "should reject if the assignment is no longer a tool assignment" do
      @assignment.update_attributes(:submission_types => 'online_upload')
      @assignment.external_tool_tag.destroy!
      make_call('body' => update_result('0.5'))
      check_failure
    end

    it "should verify the sourcedid is correct for this tool launch" do
      make_call('body' => update_result('0.6', 'BAD SOURCE ID'))
      check_failure
    end

    it "should not require an authenticity token" do
      enable_forgery_protection do
        make_call('body' => read_result)
        check_success
      end
    end
  end
end
