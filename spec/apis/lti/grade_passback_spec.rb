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
    expect(response).to be_success
    expect(response.content_type).to eq 'application/xml'
    expect(Nokogiri::XML.parse(response.body).at_css('imsx_POXEnvelopeResponse > imsx_POXHeader > imsx_POXResponseHeaderInfo > imsx_statusInfo > imsx_codeMajor').content).to eq failure_type
    expect(@assignment.submissions.where(user_id: @student)).not_to be_exists
  end

  def check_success
    expect(response).to be_success
    expect(response.content_type).to eq 'application/xml'
    expect(Nokogiri::XML.parse(response.body).at_css('imsx_POXEnvelopeResponse > imsx_POXHeader > imsx_POXResponseHeaderInfo > imsx_statusInfo > imsx_codeMajor').content).to eq 'success'
  end

  describe "replaceResult" do
    
    def verify_xml(response)
      xml = Nokogiri::XML.parse(response.body)
      expect(xml.at_css('imsx_codeMajor').content).to eq 'success'
      expect(xml.at_css('imsx_messageRefIdentifier').content).to eq '999999123'
      expect(xml.at_css('imsx_operationRefIdentifier').content).to eq 'replaceResult'
      expect(xml.at_css('imsx_POXBody *:first').name).to eq 'replaceResultResponse'
    end
    
    it "should allow updating the submission score" do
      expect(@assignment.submissions.where(user_id: @student)).not_to be_exists
      make_call('body' => replace_result('0.6'))
      check_success
      
      verify_xml(response)
      
      submission = @assignment.submissions.where(user_id: @student).first
      expect(submission).to be_present
      expect(submission).to be_graded
      expect(submission).to be_submitted_at
      expect(submission.submission_type).to eql 'external_tool'
      expect(submission.score).to eq 12
    end
    
    it "should set the submission data text" do
      make_call('body' => replace_result('0.6', nil, {:text =>"oioi"}))
      check_success
    
      verify_xml(response)
      submission = @assignment.submissions.where(user_id: @student).first
      expect(submission.score).to eq 12
      expect(submission.body).to eq "oioi"
    end
    
    it "should set complex submission text" do
      text = CGI::escapeHTML("<p>stuff</p>")
      make_call('body' => replace_result('0.6', nil, {:text => "<![CDATA[#{text}]]>" }))
      check_success
    
      verify_xml(response)
      submission = @assignment.submissions.where(user_id: @student).first
      expect(submission.submission_type).to eq 'online_text_entry'
      expect(submission.body).to eq text
    end
    
    it "should set the submission data url" do
      make_call('body' => replace_result('0.6', nil, {:url =>"http://www.example.com/lti"}))
      check_success
    
      verify_xml(response)
      submission = @assignment.submissions.where(user_id: @student).first
      expect(submission.submission_type).to eq 'online_url'
      expect(submission.score).to eq 12
      expect(submission.url).to eq "http://www.example.com/lti"
    end
    
    it "should set the submission data text even with no score" do
      make_call('body' => replace_result(nil, nil, {:text =>"oioi"}))
      check_success
    
      verify_xml(response)
      submission = @assignment.submissions.where(user_id: @student).first
      expect(submission.score).to eq nil
      expect(submission.body).to eq "oioi"
    end
    
    it "should fail if no score and not submission data" do
      make_call('body' => replace_result(nil, nil))
      expect(response).to be_success
      xml = Nokogiri::XML.parse(response.body)
      expect(xml.at_css('imsx_codeMajor').content).to eq 'failure'
      expect(xml.at_css('imsx_description').content).to eq "No score given"

      expect(@assignment.submissions.where(user_id: @student)).not_to be_exists
    end
    
    it "should fail if bad score given" do
      make_call('body' => replace_result('1.5', nil))
      expect(response).to be_success
      xml = Nokogiri::XML.parse(response.body)
      expect(xml.at_css('imsx_codeMajor').content).to eq 'failure'
      expect(xml.at_css('imsx_description').content).to eq "Score is not between 0 and 1"

      expect(@assignment.submissions.where(user_id: @student)).not_to be_exists
    end

    it "should fail if assignment has no points possible" do
      @assignment.update_attributes(:points_possible => nil, :grading_type => 'percent')
      make_call('body' => replace_result('0.75', nil))
      expect(response).to be_success
      xml = Nokogiri::XML.parse(response.body)
      expect(xml.at_css('imsx_codeMajor').content).to eq 'failure'
      expect(xml.at_css('imsx_description').content).to eq "Assignment has no points possible."
    end

    it "should notify users if it fails because the assignment has no points" do
      @assignment.update_attributes(:points_possible => nil, :grading_type => 'percent')
      make_call('body' => replace_result('0.75', nil))
      expect(response).to be_success
      submissions = @assignment.submissions.where(user_id: @student).to_a
      comments    = submissions.first.submission_comments
      expect(submissions.count).to eq 1
      expect(comments.count).to eq 1
      expect(comments.first.comment).to eq <<-NO_POINTS
An external tool attempted to grade this assignment as 75%, but was unable
to because the assignment has no points possible.
      NO_POINTS
    end

    it "should reject out of bound scores" do
      expect(@assignment.submissions.where(user_id: @student)).not_to be_exists
      make_call('body' => replace_result('-1'))
      check_failure('failure')
      make_call('body' => replace_result('1.1'))
      check_failure('failure')

      make_call('body' => replace_result('0.0'))
      check_success
      submission = @assignment.submissions.where(user_id: @student).first
      expect(submission).to be_present
      expect(submission.score).to eq 0

      make_call('body' => replace_result('1.0'))
      check_success
      submission = @assignment.submissions.where(user_id: @student).first
      expect(submission).to be_present
      expect(submission.score).to eq 20
    end

    it "should reject non-numeric scores" do
      expect(@assignment.submissions.where(user_id: @student)).not_to be_exists
      make_call('body' => replace_result("OHAI SCORES"))
      check_failure('failure')
    end
  end

  describe "readResult" do
    it "should return an empty string when no grade exists" do
      make_call('body' => read_result)
      check_success

      xml = Nokogiri::XML.parse(response.body)
      expect(xml.at_css('imsx_codeMajor').content).to eq 'success'
      expect(xml.at_css('imsx_messageRefIdentifier').content).to eq '999999123'
      expect(xml.at_css('imsx_operationRefIdentifier').content).to eq 'readResult'
      expect(xml.at_css('imsx_POXBody *:first').name).to eq 'readResultResponse'
      expect(xml.at_css('imsx_POXBody > readResultResponse > result > resultScore > language').content).to eq 'en'
      expect(xml.at_css('imsx_POXBody > readResultResponse > result > resultScore > textString').content).to eq ''
    end

    it "should return the score if the assignment is scored" do
      @assignment.grade_student(@student, :grade => "40%")

      make_call('body' => read_result)
      check_success

      xml = Nokogiri::XML.parse(response.body)
      expect(xml.at_css('imsx_codeMajor').content).to eq 'success'
      expect(xml.at_css('imsx_messageRefIdentifier').content).to eq '999999123'
      expect(xml.at_css('imsx_operationRefIdentifier').content).to eq 'readResult'
      expect(xml.at_css('imsx_POXBody *:first').name).to eq 'readResultResponse'
      expect(xml.at_css('imsx_POXBody > readResultResponse > result > resultScore > language').content).to eq 'en'
      expect(xml.at_css('imsx_POXBody > readResultResponse > result > resultScore > textString').content).to eq '0.4'
    end
  end

  describe "deleteResult" do
    it "should succeed but do nothing when the submission isn't graded" do
      make_call('body' => delete_result)
      check_success
      xml = Nokogiri::XML.parse(response.body)
      expect(xml.at_css('imsx_codeMajor').content).to eq 'success'
      expect(xml.at_css('imsx_messageRefIdentifier').content).to eq '999999123'
      expect(xml.at_css('imsx_operationRefIdentifier').content).to eq 'deleteResult'
      expect(xml.at_css('imsx_POXBody *:first').name).to eq 'deleteResultResponse'
    end

    it "should delete the existing score for the submission (by creating a new version)" do
      @assignment.grade_student(@student, :grade => "40%")

      make_call('body' => delete_result)
      check_success
      xml = Nokogiri::XML.parse(response.body)
      expect(xml.at_css('imsx_codeMajor').content).to eq 'success'
      expect(xml.at_css('imsx_messageRefIdentifier').content).to eq '999999123'
      expect(xml.at_css('imsx_operationRefIdentifier').content).to eq 'deleteResult'
      expect(xml.at_css('imsx_POXBody *:first').name).to eq 'deleteResultResponse'

      expect(@assignment.submission_for_student(@student)).not_to be_graded
      expect(@assignment.submission_for_student(@student).score).to be_nil
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
      expect(response.body).to match(/nonce/i)
    end
  end

  it "should block timestamps more than 90 minutes old" do
    # the 90 minutes value is suggested by the LTI spec
    make_call('timestamp' => 2.hours.ago.utc.to_i, 'content-type' => 'none')
    assert_status(401)
    expect(response.body).to match(/expired/i)
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
      expect(response).to be_success
      expect(response.content_type).to eq 'application/xml'
      xml = Nokogiri::XML.parse(response.body)
      expect(xml.at_css('message_response > statusinfo > codemajor').content).to eq 'Success'
      expect(xml.at_css('message_response > statusinfo > codeminor').content).to eq 'fullsuccess'
      xml
    end

    def check_failure(failure_type = 'Unsupported')
      expect(response).to be_success
      expect(response.content_type).to eq 'application/xml'
      xml = Nokogiri::XML.parse(response.body)
      expect(xml.at_css('message_response > statusinfo > codemajor').content).to eq failure_type
      expect(@assignment.submissions.where(user_id: @student)).not_to be_exists
      xml
    end

    describe "basic-lis-updateresult" do
      it "should allow updating the submission score" do
        expect(@assignment.submissions.where(user_id: @student)).not_to be_exists
        make_call('body' => update_result('0.6'))
        xml = check_success

        expect(xml.at_css('message_response > result > sourcedid').content).to eq source_id()
        expect(xml.at_css('message_response > result > resultscore > resultvaluesourcedid').content).to eq 'decimal'
        expect(xml.at_css('message_response > result > resultscore > textstring').content).to eq '0.6'
        submission = @assignment.submissions.where(user_id: @student).first
        expect(submission).to be_present
        expect(submission).to be_graded
        expect(submission.score).to eq 12
      end

      it "should reject out of bound scores" do
        expect(@assignment.submissions.where(user_id: @student)).not_to be_exists
        make_call('body' => update_result('-1'))
        check_failure('Failure')
        make_call('body' => update_result('1.1'))
        check_failure('Failure')

        make_call('body' => update_result('0.0'))
        check_success
        submission = @assignment.submissions.where(user_id: @student).first
        expect(submission).to be_present
        expect(submission.score).to eq 0

        make_call('body' => update_result('1.0'))
        check_success
        submission = @assignment.submissions.where(user_id: @student).first
        expect(submission).to be_present
        expect(submission.score).to eq 20
      end

      it "should reject non-numeric scores" do
        expect(@assignment.submissions.where(user_id: @student)).not_to be_exists
        make_call('body' => update_result("OHAI SCORES"))
        check_failure('Failure')
      end

      it "should set the grader to nil" do
        make_call('body' => update_result('1.0'))

        check_success
        submission = @assignment.submissions.where(user_id: @student).first
        expect(submission.grader_id).to be_nil
      end
    end

    describe "basic-lis-readresult" do
      it "should return xml without result when no grade exists" do
        make_call('body' => read_result)
        xml = check_success
        expect(xml.at_css('message_response result')).to be_nil
      end

      it "should return the score if the assignment is scored" do
        @assignment.grade_student(@student, :grade => "40%")

        make_call('body' => read_result)
        xml = check_success
        expect(xml.at_css('message_response > result > sourcedid').content).to eq source_id()
        expect(xml.at_css('message_response > result > resultscore > textstring').content).to eq '0.4'
      end
    end

    describe "basic-lis-deleteresult" do
      it "should succeed but do nothing when the submission isn't graded" do
        make_call('body' => delete_result)
        xml = check_success
        expect(xml.at_css('message_response result')).to be_nil
      end

      it "should delete the existing score for the submission (by creating a new version)" do
        @assignment.grade_student(@student, :grade => "40%")

        make_call('body' => delete_result)
        xml = check_success
        expect(xml.at_css('message_response result')).to be_nil

        expect(@assignment.submission_for_student(@student)).not_to be_graded
        expect(@assignment.submission_for_student(@student).score).to be_nil
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
