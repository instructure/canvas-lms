#
# Copyright (C) 2013 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

require 'nokogiri'

describe BasicLTI::BasicOutcomes do
  before(:each) do
    course_model
    @root_account = @course.root_account
    @account = account_model(:root_account => @root_account, :parent_account => @root_account)
    @course.update_attribute(:account, @account)
    @user = factory_with_protected_attributes(User, :name => "some user", :workflow_state => "registered")
    @course.enroll_student(@user)
  end

  let(:tool) do
    @course.context_external_tools.create(:name => "a", :url => "http://google.com", :consumer_key => '12345', :shared_secret => 'secret')
  end

  let(:assignment) do
    @course.assignments.create!(
      {
          title: "value for title",
          description: "value for description",
          due_at: Time.now,
          points_possible: "1.5",
          submission_types: 'external_tool',
          external_tool_tag_attributes: {url: tool.url}
      }
    )
  end

  let(:source_id) {gen_source_id}

  def gen_source_id(t: tool, c: @course, a: assignment, u: @user)
    tool.shard.activate do
      payload = [t.id, c.id, a.id, u.id].join('-')
      "#{payload}-#{Canvas::Security.hmac_sha1(payload, tool.shard.settings[:encryption_key])}"
    end
  end

  let(:xml) do
    Nokogiri::XML.parse %Q{
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
                <sourcedId>#{source_id}</sourcedId>
              </sourcedGUID>
              <result>
                <resultScore>
                  <language>en</language>
                  <textString>0.92</textString>
                </resultScore>
                <resultData>
                  <text>text data for canvas submission</text>
                </resultData>
              </result>
            </resultRecord>
          </replaceResultRequest>
        </imsx_POXBody>
      </imsx_POXEnvelopeRequest>
    }
  end

  context "Exceptions" do
    it "BasicLTI::BasicOutcomes::Unauthorized should have 401 status" do

      begin
        raise BasicLTI::BasicOutcomes::Unauthorized, "Invalid signature"
      rescue BasicLTI::BasicOutcomes::Unauthorized => e
        expect(e.response_status).to be 401
      end
    end

    it "BasicLTI::BasicOutcomes::InvalidRequest should have 415 status" do

      begin
        raise BasicLTI::BasicOutcomes::InvalidRequest, "Invalid request"
      rescue BasicLTI::BasicOutcomes::InvalidRequest => e
        expect(e.response_status).to be 415
      end
    end
  end

  describe ".decode_source_id" do
    it 'successfully decodes a source_id' do
      expect(described_class.decode_source_id(tool, source_id)).to eq [@course, assignment, @user]
    end

    it 'throws Invalid sourcedid if sourcedid is nil' do
      expect{described_class.decode_source_id(tool, nil)}.
        to raise_error(BasicLTI::Errors::InvalidSourceId, 'Invalid sourcedid')
    end

    it 'throws Invalid sourcedid if sourcedid is empty' do
      expect{described_class.decode_source_id(tool, "")}.
        to raise_error(BasicLTI::Errors::InvalidSourceId, 'Invalid sourcedid')
    end

    it 'throws Invalid signature if the signature is invalid' do
      bad_signature = source_id.split('-')[0..3].join('-') + '-asb9dksld9k3'
      expect{described_class.decode_source_id(tool, bad_signature)}.
        to raise_error(BasicLTI::Errors::InvalidSourceId, 'Invalid signature')
    end

    it "throws 'Tool is invalid' if the tool doesn't match" do
      t = @course.context_external_tools.
        create(:name => "b", :url => "http://google.com", :consumer_key => '12345', :shared_secret => 'secret')
      expect{described_class.decode_source_id(tool, gen_source_id(t: t))}.
        to raise_error(BasicLTI::Errors::InvalidSourceId, 'Tool is invalid')
    end

    it "throws Course is invalid if the course doesn't match" do
      @course.workflow_state = 'deleted'
      @course.save!
      expect{described_class.decode_source_id(tool, source_id)}.
        to raise_error(BasicLTI::Errors::InvalidSourceId, 'Course is invalid')
    end

    it "throws User is no longer in course isuser enrollment is missing" do
      @user.enrollments.destroy_all
      expect{described_class.decode_source_id(tool, source_id)}.
        to raise_error(BasicLTI::Errors::InvalidSourceId, 'User is no longer in course')
    end

    it "throws Assignment is invalid if the Addignment doesn't match" do
      assignment.destroy
      expect{described_class.decode_source_id(tool, source_id)}.
        to raise_error(BasicLTI::Errors::InvalidSourceId, 'Assignment is invalid')
    end

    it "throws Assignment is no longer associated with this tool if tool is deleted" do
      tool.destroy
      expect{described_class.decode_source_id(tool, source_id)}.
        to raise_error(BasicLTI::Errors::InvalidSourceId, 'Assignment is no longer associated with this tool')
    end

    it "throws Assignment is no longer associated with this tool if tool doesn't match the url" do
      tag = assignment.external_tool_tag
      tag.url = 'example.com'
      tag.save!
      expect{described_class.decode_source_id(tool, source_id)}.
        to raise_error(BasicLTI::Errors::InvalidSourceId, 'Assignment is no longer associated with this tool')
    end

    it "throws Assignment is no longer associated with this tool if tag is missing" do
      assignment.external_tool_tag.delete
      expect{described_class.decode_source_id(tool, source_id)}.
        to raise_error(BasicLTI::Errors::InvalidSourceId, 'Assignment is no longer associated with this tool')
    end

    context "jwt sourcedid" do
      before do
        dynamic_settings = {
          "lti-signing-secret" => 'signing-secret-vp04BNqApwdwUYPUI',
          "lti-encryption-secret" => 'encryption-secret-5T14NjaTbcYjc4'
        }
        allow(Canvas::DynamicSettings).to receive(:find) { dynamic_settings }
      end

      let(:jwt_source_id) do
        BasicLTI::Sourcedid.new(tool, @course, assignment, @user).to_s
      end

      it "decodes a jwt signed sourcedid" do
        expect(described_class.decode_source_id(tool, jwt_source_id)).to eq [@course, assignment, @user]
      end

      it 'throws invalid JWT if token is unrecognized' do
        missing_signature = source_id.split('-')[0..3].join('-')
        expect{described_class.decode_source_id(tool, missing_signature)}.
          to raise_error(BasicLTI::Errors::InvalidSourceId, 'Invalid sourcedid')
      end

    end
  end

  describe "#handle_request" do
    it "sets the response body when an invalid sourcedId is given" do
      xml.css('sourcedId').remove
      response = BasicLTI::BasicOutcomes::LtiResponse.new(xml)
      response.handle_request(tool)
      expect(response.code_major).to eq('failure')
      expect(response.description).to eq('Invalid sourcedid')
      expect(response.body).not_to be_nil
    end
  end

  describe "#handle_replaceResult" do
    it "accepts a grade" do
      xml.css('resultData').remove
      request = BasicLTI::BasicOutcomes.process_request(tool, xml)

      expect(request.code_major).to eq 'success'
      expect(request.body).to eq '<replaceResultResponse />'
      expect(request.handle_request(tool)).to be_truthy
      submission = assignment.submissions.where(user_id: @user.id).first
      expect(submission.grade).to eq (assignment.points_possible * 0.92).to_s
    end

    it "rejects a grade for an assignment with no points possible" do
      xml.css('resultData').remove
      assignment.points_possible = nil
      assignment.save!
      request = BasicLTI::BasicOutcomes.process_request(tool, xml)

      expect(request.code_major).to eq 'failure'
      expect(request.body).to eq '<replaceResultResponse />'
      expect(request.description).to eq 'Assignment has no points possible.'
    end

    it "doesn't explode when an assignment with no points possible receives a grade for an existing submission " do
      xml.css('resultData').remove
      assignment.points_possible = nil
      assignment.save!
      BasicLTI::BasicOutcomes.process_request(tool, xml)
      request = BasicLTI::BasicOutcomes.process_request(tool, xml)

      expect(request.code_major).to eq 'failure'
      expect(request.body).to eq '<replaceResultResponse />'
      expect(request.description).to eq 'Assignment has no points possible.'
    end

    it 'handles tools that have a url mismatch with the assignment' do
      assignment.external_tool_tag_attributes = {url: 'http://example.com/foo'}
      assignment.save!
      request = BasicLTI::BasicOutcomes.process_request(tool, xml)
      expect(request.code_major).to eq 'failure'
      expect(request.body).to eq '<replaceResultResponse />'
      expect(request.description).to eq 'Assignment is no longer associated with this tool'
    end

    it "accepts a result data without grade" do
      xml.css('resultScore').remove
      request = BasicLTI::BasicOutcomes.process_request(tool, xml)
      expect(request.code_major).to eq 'success'
      expect(request.body).to eq '<replaceResultResponse />'
      expect(request.handle_request(tool)).to be_truthy
      submission = assignment.submissions.where(user_id: @user.id).first
      expect(submission.body).to eq 'text data for canvas submission'
      expect(submission.grade).to be_nil
      expect(submission.workflow_state).to eq 'submitted'
    end

    it "fails if neither result data or a grade is sent" do
      xml.css('resultData').remove
      xml.css('resultScore').remove
      request = BasicLTI::BasicOutcomes.process_request(tool, xml)
      expect(request.code_major).to eq 'failure'
      expect(request.body).to eq '<replaceResultResponse />'
    end

    it "Does not change the attempt number" do
      xml.css('resultData').remove
      now = Time.now.utc
      BasicLTI::BasicOutcomes.process_request(tool, xml)
      submission = assignment.submissions.where(user_id: @user.id).first
      expect(submission.attempt).to eq 1
    end

    context 'with submitted_at details' do
      let(:timestamp) { 1.day.ago.iso8601(3) }

      it "sets submitted_at to submitted_at details if resultData is not present" do
        xml.css('resultData').remove
        xml.at_css('imsx_POXBody > replaceResultRequest').add_child(
          "<submissionDetails><submittedAt>#{timestamp}</submittedAt></submissionDetails>"
        )
        BasicLTI::BasicOutcomes.process_request(tool, xml)
        submission = assignment.submissions.where(user_id: @user.id).first
        expect(submission.submitted_at.iso8601(3)).to eq timestamp
      end

      it "sets submitted_at to submitted_at details if resultData is present" do
        xml.at_css('imsx_POXBody > replaceResultRequest').add_child(
          "<submissionDetails><submittedAt>#{timestamp}</submittedAt></submissionDetails>"
        )
        BasicLTI::BasicOutcomes.process_request(tool, xml)
        submission = assignment.submissions.where(user_id: @user.id).first
        expect(submission.submitted_at.iso8601(3)).to eq timestamp
      end

      context 'with timestamp in future' do
        let(:timestamp) { Time.zone.now }

        it 'returns error message for timestamp more than one minute in future' do
          xml.at_css('imsx_POXBody > replaceResultRequest').add_child(
            "<submissionDetails><submittedAt>#{timestamp}</submittedAt></submissionDetails>"
          )
          Timecop.freeze(2.minutes.ago) do
            request = BasicLTI::BasicOutcomes.process_request(tool, xml)
            expect(request.code_major).to eq 'failure'
            expect(request.body).to eq '<replaceResultResponse />'
            expect(request.description).to eq 'Invalid timestamp - timestamp in future'
          end
        end

        it 'does not create submission' do
          xml.at_css('imsx_POXBody > replaceResultRequest').add_child(
            "<submissionDetails><submittedAt>#{timestamp}</submittedAt></submissionDetails>"
          )
          Timecop.freeze(2.minutes.ago) do
            request = BasicLTI::BasicOutcomes.process_request(tool, xml)
            expect(assignment.submissions.where(user_id: @user.id).first.submitted_at).to be_blank
          end
        end
      end

      context 'with invalid timestamp' do
        let(:timestamp) { 'a' }

        it 'returns error message for invalid timestamp' do
          xml.at_css('imsx_POXBody > replaceResultRequest').add_child(
            "<submissionDetails><submittedAt>#{timestamp}</submittedAt></submissionDetails>"
          )
          request = BasicLTI::BasicOutcomes.process_request(tool, xml)
          expect(request.code_major).to eq 'failure'
          expect(request.body).to eq '<replaceResultResponse />'
          expect(request.description).to eq 'Invalid timestamp - timestamp not parseable'
        end

        it 'does not create submission' do
          xml.at_css('imsx_POXBody > replaceResultRequest').add_child(
            "<submissionDetails><submittedAt>#{timestamp}</submittedAt></submissionDetails>"
          )
          request = BasicLTI::BasicOutcomes.process_request(tool, xml)
          expect(assignment.submissions.where(user_id: @user.id).first.submitted_at).to be_blank
        end
      end
    end

    it 'accepts LTI launch URLs as a data format with a specific submission type' do
      xml.css('resultScore').remove
      xml.at_css('text').replace('<ltiLaunchUrl>http://example.com/launch</ltiLaunchUrl>')
      request = BasicLTI::BasicOutcomes.process_request(tool, xml)

      expect(request.code_major).to eq 'success'
      expect(request.body).to eq '<replaceResultResponse />'
      expect(request.handle_request(tool)).to be_truthy
      submission = assignment.submissions.where(user_id: @user.id).first
      expect(submission.submission_type).to eq 'basic_lti_launch'
    end

    context "submissions" do

      it "creates a new submissions if there isn't one" do
        xml.css('resultData').remove
        expect{BasicLTI::BasicOutcomes.process_request(tool, xml)}.
          to change{assignment.submissions.not_placeholder.where(user_id: @user.id).count}.from(0).to(1)
      end

      it 'creates a new submission of type "external_tool" when a grade is passed back without a submission' do
        xml.css('resultData').remove
        BasicLTI::BasicOutcomes.process_request(tool, xml)
        expect(assignment.submissions.where(user_id: @user.id).first.submission_type).to eq 'external_tool'
      end

      it "sets the submission type to external tool if the existing submission_type is nil" do
        submission = assignment.grade_student(
          @user,
          {
            grade: "92%",
            grader_id: -1
          }).first
        xml.css('resultData').remove
        BasicLTI::BasicOutcomes.process_request(tool, xml)
        expect(submission.reload.submission_type).to eq 'external_tool'
      end

      it "creates a new submission if result_data_text is sent" do
        submission = assignment.submit_homework(
          @user,
          {
            submission_type: "online_text_entry",
            body: "sample text",
            grade: "92%"
          })
        BasicLTI::BasicOutcomes.process_request(tool, xml)
        expect(submission.reload.versions.count).to eq 2
      end

      it "creates a new submission if result_data_url is sent" do
        submission = assignment.submit_homework(
          @user,
          {
            submission_type: "online_text_entry",
            body: "sample text",
            grade: "92%"
          })
        xml.css('resultScore').remove
        xml.at_css('text').replace('<url>http://example.com/launch</url>')
        BasicLTI::BasicOutcomes.process_request(tool, xml)
        expect(submission.reload.versions.count).to eq 2
      end

      it "creates a new submission if result_data_launch_url is sent" do
        submission = assignment.submit_homework(
          @user,
          {
            submission_type: "online_text_entry",
            body: "sample text",
            grade: "92%"
          })
        xml.css('resultScore').remove
        xml.at_css('text').replace('<ltiLaunchUrl>http://example.com/launch</ltiLaunchUrl>')
        BasicLTI::BasicOutcomes.process_request(tool, xml)
        expect(submission.reload.versions.count).to eq 2
      end

      it "creates a new submission if result_data_download_url is sent" do
        submission = assignment.submit_homework(
          @user,
          {
            submission_type: "online_text_entry",
            body: "sample text",
            grade: "92%"
          })
        xml.css('resultScore').remove
        xml.at_css('text').replace('<documentName>face.doc</documentName><downloadUrl>http://example.com/download</downloadUrl>')
        BasicLTI::BasicOutcomes.process_request(tool, xml)
        expect(Delayed::Job.strand_size('file_download/example.com')).to be > 0
        run_jobs
        expect(submission.reload.versions.count).to eq 2
        expect(submission.attachments.count).to eq 1
        expect(submission.attachments.first.display_name).to eq "face.doc"
      end

      it "doesn't change the submission type if only the score is sent" do
        submission_type = 'online_text_entry'
        submission = assignment.submit_homework(
          @user,
          {
            submission_type: submission_type,
            body: "sample text",
            grade: "92%"
          })
        xml.css('resultData').remove
        BasicLTI::BasicOutcomes.process_request(tool, xml)
        expect(submission.reload.submission_type).to eq submission_type
      end
    end
  end
end
