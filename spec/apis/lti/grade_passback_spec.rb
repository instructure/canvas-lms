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

describe LtiApiController, type: :request do
  before :once do
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
      { "CONTENT_TYPE" => opts['content-type'], "HTTP_AUTHORIZATION" => req['Authorization'] }
  end

  def source_id
    @tool.shard.activate do
      payload = [@tool.id, @course.id, @assignment.id, @student.id].join('-')
      "#{payload}-#{Canvas::Security.hmac_sha1(payload, @tool.shard.settings[:encryption_key])}"
    end
  end

  it "should respond 'unsupported' for any unknown xml body" do
    body = %{<imsx_POXEnvelopeRequest xmlns = "http://www.imsglobal.org/services/ltiv1p1/xsd/imsoms_v1p0"></imsx_POXEnvelopeRequest>}
    make_call('body' => body)
    check_failure
  end

  it "should require a content-type of application/xml" do
    make_call('content-type' => 'application/other')
    assert_status(415)
  end

  it "should require the correct shared secret" do
    make_call('secret' => 'bad secret is bad')
    assert_status(401)
  end

  def replace_result(score=nil, sourceid = nil, result_data=nil)
    sourceid ||= source_id()
    
    score_xml = ''
    if score
      score_xml = <<-XML
          <resultScore>
            <language>en</language>
            <textString>#{score}</textString>
          </resultScore>
      XML
    end
    
    result_data_xml = ''
    if result_data && !result_data.empty?
      result_data_xml = "<resultData>\n"
      result_data.each_pair do |key, val|
        result_data_xml += "<#{key}>#{val}</#{key}>"
      end
      result_data_xml += "\n</resultData>\n"
    end
    
    body = <<-XML
<?xml version = "1.0" encoding = "UTF-8"?>
<imsx_POXEnvelopeRequest xmlns = "http://www.imsglobal.org/services/ltiv1p1/xsd/imsoms_v1p0">
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
          #{score_xml}
          #{result_data_xml}
        </result>
      </resultRecord>
    </replaceResultRequest>
  </imsx_POXBody>
</imsx_POXEnvelopeRequest>
XML
  end

  def read_result(sourceid = nil)
    sourceid ||= source_id()
    body = <<-XML
<?xml version = "1.0" encoding = "UTF-8"?>
<imsx_POXEnvelopeRequest xmlns = "http://www.imsglobal.org/services/ltiv1p1/xsd/imsoms_v1p0">
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
    XML
  end

  def delete_result(sourceid = nil)
    sourceid ||= source_id()
    body = <<-XML
<?xml version = "1.0" encoding = "UTF-8"?>
<imsx_POXEnvelopeRequest xmlns = "http://www.imsglobal.org/services/ltiv1p1/xsd/imsoms_v1p0">
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
    XML
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
    
    def verify_xml(response)
      xml = Nokogiri::XML.parse(response.body)
      xml.at_css('imsx_codeMajor').content.should == 'success'
      xml.at_css('imsx_messageRefIdentifier').content.should == '999999123'
      xml.at_css('imsx_operationRefIdentifier').content.should == 'replaceResult'
      xml.at_css('imsx_POXBody *:first').name.should == 'replaceResultResponse'
    end
    
    it "should allow updating the submission score" do
      @assignment.submissions.find_by_user_id(@student.id).should be_nil
      make_call('body' => replace_result('0.6'))
      check_success
      
      verify_xml(response)
      
      submission = @assignment.submissions.find_by_user_id(@student.id)
      submission.should be_present
      submission.should be_graded
      submission.should be_submitted_at
      submission.submission_type.should eql 'external_tool'
      submission.score.should == 12
    end
    
    it "should set the submission data text" do
      make_call('body' => replace_result('0.6', nil, {:text =>"oioi"}))
      check_success
    
      verify_xml(response)
      submission = @assignment.submissions.find_by_user_id(@student.id)
      submission.score.should == 12
      submission.body.should == "oioi"
    end
    
    it "should set complex submission text" do
      text = CGI::escapeHTML("<p>stuff</p>")
      make_call('body' => replace_result('0.6', nil, {:text => "<![CDATA[#{text}]]>" }))
      check_success
    
      verify_xml(response)
      submission = @assignment.submissions.find_by_user_id(@student.id)
      submission.submission_type.should == 'online_text_entry'
      submission.body.should == text
    end
    
    it "should set the submission data url" do
      make_call('body' => replace_result('0.6', nil, {:url =>"http://www.example.com/lti"}))
      check_success
    
      verify_xml(response)
      submission = @assignment.submissions.find_by_user_id(@student.id)
      submission.submission_type.should == 'online_url'
      submission.score.should == 12
      submission.url.should == "http://www.example.com/lti"
    end
    
    it "should set the submission data text even with no score" do
      make_call('body' => replace_result(nil, nil, {:text =>"oioi"}))
      check_success
    
      verify_xml(response)
      submission = @assignment.submissions.find_by_user_id(@student.id)
      submission.score.should == nil
      submission.body.should == "oioi"
    end
    
    it "should fail if no score and not submission data" do
      make_call('body' => replace_result(nil, nil))
      response.should be_success
      xml = Nokogiri::XML.parse(response.body)
      xml.at_css('imsx_codeMajor').content.should == 'failure'
      xml.at_css('imsx_description').content.should == "No score given"
    
      @assignment.submissions.find_by_user_id(@student.id).should be_nil
    end
    
    it "should fail if bad score given" do
      make_call('body' => replace_result('1.5', nil))
      response.should be_success
      xml = Nokogiri::XML.parse(response.body)
      xml.at_css('imsx_codeMajor').content.should == 'failure'
      xml.at_css('imsx_description').content.should == "Score is not between 0 and 1"
    
      @assignment.submissions.find_by_user_id(@student.id).should be_nil
    end

    it "should fail if assignment has no points possible" do
      @assignment.update_attributes(:points_possible => nil, :grading_type => 'percent')
      make_call('body' => replace_result('0.75', nil))
      response.should be_success
      xml = Nokogiri::XML.parse(response.body)
      xml.at_css('imsx_codeMajor').content.should == 'failure'
      xml.at_css('imsx_description').content.should == "Assignment has no points possible."
    end

    it "should notify users if it fails because the assignment has no points" do
      @assignment.update_attributes(:points_possible => nil, :grading_type => 'percent')
      make_call('body' => replace_result('0.75', nil))
      response.should be_success
      submissions = @assignment.submissions.find_all_by_user_id(@student.id)
      comments    = submissions.first.submission_comments
      submissions.count.should == 1
      comments.count.should == 1
      comments.first.comment.should == <<-NO_POINTS
An external tool attempted to grade this assignment as 75%, but was unable
to because the assignment has no points possible.
      NO_POINTS
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
    @assignment.reload.external_tool_tag.destroy!
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
      assert_status(415)
      make_call('nonce' => 'not_so_random', 'content-type' => 'none')
      assert_status(401)
      response.body.should match(/nonce/i)
    end
  end

  it "should block timestamps more than 90 minutes old" do
    # the 90 minutes value is suggested by the LTI spec
    make_call('timestamp' => 2.hours.ago.utc.to_i, 'content-type' => 'none')
    assert_status(401)
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
        { 'CONTENT_TYPE' => 'application/x-www-form-urlencoded', "HTTP_AUTHORIZATION" => req['Authorization'] }
    end

    it "should require the correct shared secret" do
      make_call('secret' => 'bad secret is bad')
      assert_status(401)
    end

    def update_result(score, sourcedid = nil)
      sourcedid ||= source_id()
      body = {
        'lti_message_type' => 'basic-lis-updateresult',
        'sourcedid' => sourcedid,
        'result_resultscore_textstring' => score.to_s,
      }
    end

    def read_result(sourcedid = nil)
      sourcedid ||= source_id()
      body = {
        'lti_message_type' => 'basic-lis-readresult',
        'sourcedid' => sourcedid,
      }
    end

    def delete_result(sourcedid = nil)
      sourcedid ||= source_id()
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

        xml.at_css('message_response > result > sourcedid').content.should == source_id()
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

      it "should set the grader to nil" do
        make_call('body' => update_result('1.0'))

        check_success
        submission = @assignment.submissions.find_by_user_id(@student.id)
        submission.grader_id.should be_nil
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
        xml.at_css('message_response > result > sourcedid').content.should == source_id()
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
      @assignment.reload.external_tool_tag.destroy!
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
