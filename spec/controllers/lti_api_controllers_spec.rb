#
# Copyright (C) 2011 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../apis/api_spec_helper')

require 'nokogiri'

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

  def check_error_response(message, check_generated_sig=true)
    expect(response.body.strip).to_not be_empty, "Should not have an empty response body"

    json = JSON.parse response.body
    expect(json["errors"][0]["message"]).to eq message
    expect(json["error_report_id"]).to be > 0

    data = error_data(json)

    expect(data.key?('oauth_signature')).to be true
    expect(data.key?('oauth_signature_method')).to be true
    expect(data.key?('oauth_nonce')).to be true
    expect(data.key?('oauth_timestamp')).to be true
    expect(data.key?('generated_signature')).to be true if check_generated_sig

    expect(data['oauth_signature']).to_not be_empty
    expect(data['oauth_signature_method']).to_not be_empty
    expect(data['oauth_nonce']).to_not be_empty
    expect(data['oauth_timestamp']).to_not be_empty
    expect(data['generated_signature']).to_not be_empty if check_generated_sig
  end

  def error_data(json=nil)
    json ||= JSON.parse response.body
    error_report = ErrorReport.find json["error_report_id"]
    error_report.data
  end

  def make_call(opts = {})
    opts['path'] ||= "/api/lti/v1/tools/#{@tool.id}/grade_passback"
    opts['key'] ||= @tool.consumer_key
    opts['secret'] ||= @tool.shared_secret
    opts['content-type'] ||= 'application/xml'
    consumer = OAuth::Consumer.new(opts['key'], opts['secret'], :site => "https://www.example.com", :signature_method => "HMAC-SHA1")
    req = consumer.create_signed_request(:post, opts['path'], nil, :scheme => 'header', :timestamp => opts['timestamp'], :nonce => opts['nonce'])

    auth = req['Authorization']
    if opts['override_signature_method']
      auth.gsub! "HMAC-SHA1", opts['override_signature_method']
    end

    req.body = opts['body'] if opts['body']
    post "https://www.example.com#{req.path}",
      req.body,
      { "CONTENT_TYPE" => opts['content-type'], "HTTP_AUTHORIZATION" => auth }

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

  it "adds xml to an error report if the xml is invalid according to spec" do
    body = %{<imsx_POXEnvelopeRequest xmlns = "http://www.imsglobal.org/services/ltiv1p1/xsd/imsoms_v1p0"></imsx_POXEnvelopeRequest>}
    Canvas::Errors.expects(:capture).with { |_, opts| opts[:extra][:xml].present? }.returns({})
    make_call('body' => body)
  end

  it "should require a content-type of application/xml" do
    make_call('content-type' => 'application/other')
    assert_status(415)
  end

  context "OAuth Requests" do
    it "should fail on invalid signature method" do
      make_call('override_signature_method' => 'BawkBawk256')
      check_error_response("Invalid authorization header", false)
      data = error_data

      expect(data['error_class']).to eq "OAuth::Signature::UnknownSignatureMethod"
      assert_status(401)
    end

    it "should require the correct shared secret" do
      make_call('secret' => 'bad secret is bad')
      check_error_response("Invalid authorization header")

      data = error_data
      expect(data['error_class']).to eq "OAuth::Unauthorized"

      assert_status(401)
    end

    if Canvas.redis_enabled?
      it "should not allow the same nonce to be used more than once" do
        enable_cache do
          make_call('nonce' => 'not_so_random', 'content-type' => 'none')
          assert_status(415)
          make_call('nonce' => 'not_so_random', 'content-type' => 'none')
          assert_status(401)
          check_error_response("Duplicate nonce detected")
        end
      end
    end

    it "should block timestamps more than 90 minutes old" do
      # the 90 minutes value is suggested by the LTI spec
      make_call('timestamp' => 2.hours.ago.utc.to_i, 'content-type' => 'none')
      assert_status(401)
      expect(response.body).to match(/expired/i)
      check_error_response("Timestamp too old or too far in the future, request has expired")
    end
  end

  def replace_result(opts={})
    score = opts[:score]
    sourceid = opts[:sourceid]
    result_data = opts[:result_data]
    raw_score = opts[:raw_score]

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

    raw_score_xml = ''
    if raw_score
      raw_score_xml = <<-XML
          <resultTotalScore>
            <language>en</language>
            <textString>#{raw_score}</textString>
          </resultTotalScore>
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
          #{raw_score_xml}
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

  def check_failure(failure_type = 'unsupported', error_message = nil)
    expect(response).to be_success
    expect(response.content_type).to eq 'application/xml'
    xml = Nokogiri::XML.parse(response.body)
    expect(xml.at_css('imsx_POXEnvelopeResponse > imsx_POXHeader > imsx_POXResponseHeaderInfo > imsx_statusInfo > imsx_codeMajor').content).to eq failure_type
    expect(@assignment.submissions.not_placeholder.where(user_id: @student)).not_to be_exists
    desc = xml.at_css('imsx_description').content.match(/(?<description>.+)\n\[EID_(?<error_report>[^\]]+)\]/)
    expect(desc[:description]).to eq error_message if error_message
    expect(desc[:error_report]).to_not be_empty


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
      expect(@assignment.submissions.not_placeholder.where(user_id: @student)).not_to be_exists
      make_call('body' => replace_result(score: '0.6'))
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
      make_call('body' => replace_result(score: '0.6', sourceid: nil, result_data: {:text =>"oioi"}))
      check_success

      verify_xml(response)
      submission = @assignment.submissions.where(user_id: @student).first
      expect(submission.score).to eq 12
      expect(submission.body).to eq "oioi"
    end

    it "should set complex submission text" do
      text = CGI::escapeHTML("<p>stuff</p>")
      make_call('body' => replace_result(score: '0.6', sourceid: nil, result_data: {:text => "<![CDATA[#{text}]]>" }))
      check_success

      verify_xml(response)
      submission = @assignment.submissions.where(user_id: @student).first
      expect(submission.submission_type).to eq 'online_text_entry'
      expect(submission.body).to eq text
    end

    it "should set the submission data url" do
      make_call('body' => replace_result(score: '0.6', sourceid: nil, result_data: {:url =>"http://www.example.com/lti"}))
      check_success

      verify_xml(response)
      submission = @assignment.submissions.where(user_id: @student).first
      expect(submission.submission_type).to eq 'online_url'
      expect(submission.score).to eq 12
      expect(submission.url).to eq "http://www.example.com/lti"
    end

    it "should set the submission data text even with no score" do
      make_call('body' => replace_result(score: nil, sourceid: nil, result_data: {:text =>"oioi"}))
      check_success

      verify_xml(response)
      submission = @assignment.submissions.where(user_id: @student).first
      expect(submission.score).to eq nil
      expect(submission.body).to eq "oioi"
    end

    it "should fail if no score and not submission data" do
      make_call('body' => replace_result(score: nil, sourceid: nil))
      expect(response).to be_success
      xml = Nokogiri::XML.parse(response.body)
      expect(xml.at_css('imsx_codeMajor').content).to eq 'failure'
      expect(xml.at_css('imsx_description').content).to match /^No score given/

      expect(@assignment.submissions.not_placeholder.where(user_id: @student)).not_to be_exists
    end

    it "should fail if bad score given" do
      make_call('body' => replace_result(score: '1.5', sourceid: nil))
      expect(response).to be_success
      xml = Nokogiri::XML.parse(response.body)
      expect(xml.at_css('imsx_codeMajor').content).to eq 'failure'
      expect(xml.at_css('imsx_description').content).to match /^Score is not between 0 and 1/

      expect(@assignment.submissions.not_placeholder.where(user_id: @student)).not_to be_exists
    end

    it "should fail if assignment has no points possible" do
      @assignment.update_attributes(:points_possible => nil, :grading_type => 'percent')
      make_call('body' => replace_result(score: '0.75', sourceid: nil))
      expect(response).to be_success
      xml = Nokogiri::XML.parse(response.body)
      expect(xml.at_css('imsx_codeMajor').content).to eq 'failure'
      expect(xml.at_css('imsx_description').content).to match /^Assignment has no points possible\./
    end

    it "should pass if assignment has 0 points possible" do
      @assignment.update_attributes(:points_possible => 0, :grading_type => 'percent')
      make_call('body' => replace_result(score: '0.75', sourceid: nil))
      check_success

      submission = @assignment.submissions.where(user_id: @student).first
      expect(submission).to be_present
      expect(submission).to be_graded
      expect(submission).to be_submitted_at
      expect(submission.submission_type).to eql 'external_tool'
      expect(submission.score).to eq 0
    end


    it "should notify users if it fails because the assignment has no points" do
      @assignment.update_attributes(:points_possible => nil, :grading_type => 'percent')
      make_call('body' => replace_result(score: '0.75', sourceid: nil))
      expect(response).to be_success
      submissions = @assignment.submissions.where(user_id: @student).to_a
      comments    = submissions.first.submission_comments
      expect(submissions.count).to eq 1
      expect(comments.count).to eq 1
      expect(comments.first.comment).to eq <<-NO_POINTS.strip
An external tool attempted to grade this assignment as 75%, but was unable
to because the assignment has no points possible.
      NO_POINTS
    end

    it "should reject out of bound scores" do
      expect(@assignment.submissions.not_placeholder.where(user_id: @student)).not_to be_exists
      make_call('body' => replace_result(score: '-1'))
      check_failure('failure')
      make_call('body' => replace_result(score: '1.1'))
      check_failure('failure')

      make_call('body' => replace_result(score: '0.0'))
      check_success
      submission = @assignment.submissions.where(user_id: @student).first
      expect(submission).to be_present
      expect(submission.score).to eq 0

      make_call('body' => replace_result(score: '1.0'))
      check_success
      submission = @assignment.submissions.where(user_id: @student).first
      expect(submission).to be_present
      expect(submission.score).to eq 20
    end

    it "should reject non-numeric scores" do
      expect(@assignment.submissions.not_placeholder.where(user_id: @student)).not_to be_exists
      make_call('body' => replace_result(score: "OHAI SCORES"))
      check_failure('failure')
    end

    context "pass_fail zero point assignments" do
      it "should succeed with incomplete grade when score < 1" do
        @assignment.update_attributes(:points_possible => 10, :grading_type => 'pass_fail')
        make_call('body' => replace_result(score: '0.75', sourceid: nil))
        check_success

        verify_xml(response)

        submission = @assignment.submissions.where(user_id: @student).first
        expect(submission).to be_present
        expect(submission).to be_graded
        expect(submission).to be_submitted_at
        expect(submission.submission_type).to eql 'external_tool'
        expect(submission.score).to eq 0
        expect(submission.grade).to eq 'incomplete'
      end

      it "should succeed with incomplete grade when score < 1 for a 0 point assignment" do
        @assignment.update_attributes(:points_possible => 0, :grading_type => 'pass_fail')
        make_call('body' => replace_result(score: '0.75', sourceid: nil))
        check_success

        verify_xml(response)

        submission = @assignment.submissions.where(user_id: @student).first
        expect(submission).to be_present
        expect(submission).to be_graded
        expect(submission).to be_submitted_at
        expect(submission.submission_type).to eql 'external_tool'
        expect(submission.score).to eq 0
        expect(submission.grade).to eq 'incomplete'
      end

      it "should succeed with complete grade when score = 1" do
        @assignment.update_attributes(:points_possible => 0, :grading_type => 'pass_fail')
        make_call('body' => replace_result(score: '1', sourceid: nil))
        check_success

        verify_xml(response)

        submission = @assignment.submissions.where(user_id: @student).first
        expect(submission).to be_present
        expect(submission).to be_graded
        expect(submission).to be_submitted_at
        expect(submission.submission_type).to eql 'external_tool'
        expect(submission.score).to eq 0
        expect(submission.grade).to eq 'complete'
      end
    end

    context "sending raw score" do
      it "should set the raw score" do
        make_call('body' => replace_result(raw_score: '65'))
        check_success
        submission = @assignment.submissions.where(user_id: @student).first
        expect(submission).to be_present
        expect(submission.score).to eq 65
      end

      it "should ignore resultScore if raw score is sent" do
        make_call('body' => replace_result(score: '1', raw_score: '70'))
        check_success
        submission = @assignment.submissions.where(user_id: @student).first
        expect(submission).to be_present
        expect(submission.score).to eq 70
      end

      it "should reject non-numeric scores" do
        expect(@assignment.submissions.not_placeholder.where(user_id: @student)).not_to be_exists
        make_call('body' => replace_result(raw_score: "OHAI SCORES"))
        check_failure('failure')
      end

      it "should allow negative scores" do
        make_call('body' => replace_result(raw_score: '-7'))
        check_success
        submission = @assignment.submissions.where(user_id: @student).first
        expect(submission).to be_present
        expect(submission.score).to eq -7
      end

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
      @assignment.grade_student(@student, grade: "40%", grader: @teacher)

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
      @assignment.grade_student(@student, grade: "40%", grader: @teacher)

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
    @assignment.external_tool_tag.destroy_permanently!
    @assignment.external_tool_tag = nil
    tag = @assignment.build_external_tool_tag(:url => "http://example.net/one")
    tag.content_type = 'ContextExternalTool'
    tag.save!
    make_call('body' => replace_result(score: '0.5'))
    check_failure('failure', 'Assignment is no longer associated with this tool')
  end

  it "should be unsupported if the assignment switched to a new tool with the same shared secret" do
    tool = @course.context_external_tools.create!(:shared_secret => 'test_secret', :consumer_key => 'test_key', :name => 'new tool', :domain => 'example.net')
    @assignment.external_tool_tag.destroy_permanently!
    @assignment.external_tool_tag = nil
    tag = @assignment.build_external_tool_tag(:url => "http://example.net/one")
    tag.content_type = 'ContextExternalTool'
    tag.save!
    make_call('body' => replace_result(score: '0.5'))
    check_failure('failure', 'Assignment is no longer associated with this tool')
  end

  it "should reject if the assignment is no longer a tool assignment" do
    @assignment.update_attributes(:submission_types => 'online_upload')
    @assignment.reload.external_tool_tag.destroy_permanently!
    make_call('body' => replace_result(score: '0.5'))
    check_failure('failure', 'Assignment is no longer associated with this tool')
  end

  it "should verify the sourcedid is correct for this tool launch" do
    make_call('body' => replace_result(score: '0.6', sourceid: 'BAD SOURCE ID'))
    check_failure('failure', 'Invalid sourcedid')
  end

  it "fails if course is deleted" do
    opts = {'body' => replace_result(score: '0.6')}
    @course.destroy
    make_call(opts)

    check_failure('failure', 'Course is invalid')
  end

  it "fails if assignment is deleted" do
    opts = {'body' => replace_result(score: '0.6')}
    @assignment.destroy
    make_call(opts)

    check_failure('failure', 'Assignment is invalid')
  end

  it "fails if user enrollment is deleted" do
    opts = {'body' => replace_result(score: '0.6')}
    @course.student_enrollments.active.where(user_id: @student.id).first.destroy
    make_call(opts)

    check_failure('failure', 'User is no longer in course')
  end

  it "fails if tool is deleted" do
    opts = {'body' => replace_result(score: '0.6')}
    @tool.destroy
    make_call(opts)

    check_failure('failure', 'Assignment is no longer associated with this tool')
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

    def check_failure(failure_type = 'Failure', error_message = nil)
      expect(response).to be_success
      expect(response.content_type).to eq 'application/xml'
      xml = Nokogiri::XML.parse(response.body)
      expect(xml.at_css('message_response > statusinfo > codemajor').content).to eq failure_type
      expect(@assignment.submissions.not_placeholder.where(user_id: @student)).not_to be_exists
      xml
    end

    describe "basic-lis-updateresult" do
      it "should allow updating the submission score" do
        expect(@assignment.submissions.not_placeholder.where(user_id: @student)).not_to be_exists
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
        expect(@assignment.submissions.not_placeholder.where(user_id: @student)).not_to be_exists
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
        expect(@assignment.submissions.not_placeholder.where(user_id: @student)).not_to be_exists
        make_call('body' => update_result("OHAI SCORES"))
        check_failure('Failure')
      end

      it "should set the grader to the negative tool id" do
        make_call('body' => update_result('1.0'))

        check_success
        submission = @assignment.submissions.where(user_id: @student).first
        expect(submission.grader_id).to eq(-@tool.id)
      end
    end

    describe "basic-lis-readresult" do
      it "should return xml without result when no grade exists" do
        make_call('body' => read_result)
        xml = check_success
        expect(xml.at_css('message_response result')).to be_nil
      end

      it "should return the score if the assignment is scored" do
        @assignment.grade_student(@student, grade: "40%", grader: @teacher)

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
        @assignment.grade_student(@student, grade: "40%", grader: @teacher)

        make_call('body' => delete_result)
        xml = check_success
        expect(xml.at_css('message_response result')).to be_nil

        expect(@assignment.submission_for_student(@student)).not_to be_graded
        expect(@assignment.submission_for_student(@student).score).to be_nil
      end
    end

    it "should reject if the assignment doesn't use this tool" do
      tool = @course.context_external_tools.create!(:shared_secret => 'test_secret_2', :consumer_key => 'test_key_2', :name => 'new tool', :domain => 'example.net')
      @assignment.external_tool_tag.destroy_permanently!
      @assignment.external_tool_tag = nil
      tag = @assignment.build_external_tool_tag(:url => "http://example.net/one")
      tag.content_type = 'ContextExternalTool'
      tag.save!
      make_call('body' => update_result('0.5'))
      check_failure
    end

    it "should be unsupported if the assignment switched to a new tool with the same shared secret" do
      tool = @course.context_external_tools.create!(:shared_secret => 'test_secret', :consumer_key => 'test_key', :name => 'new tool', :domain => 'example.net')
      @assignment.external_tool_tag.destroy_permanently!
      @assignment.external_tool_tag = nil
      tag = @assignment.build_external_tool_tag(:url => "http://example.net/one")
      tag.content_type = 'ContextExternalTool'
      tag.save!
      make_call('body' => update_result('0.5'))
      check_failure
    end

    it "should reject if the assignment is no longer a tool assignment" do
      @assignment.update_attributes(:submission_types => 'online_upload')
      @assignment.reload.external_tool_tag.destroy_permanently!
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
