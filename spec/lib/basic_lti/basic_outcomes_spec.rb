# frozen_string_literal: true

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

require "nokogiri"
require "webmock/rspec"

describe BasicLTI::BasicOutcomes do
  before do
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  before do
    course_model.offer
    @root_account = @course.root_account
    @account = account_model(root_account: @root_account, parent_account: @root_account)
    @course.update_attribute(:account, @account)
    @user = factory_with_protected_attributes(User, name: "some user", workflow_state: "registered")
    @course.enroll_student(@user)
  end

  after do
    WebMock.allow_net_connect!
  end

  let(:tool) do
    @course.context_external_tools.create(name: "a", url: "http://google.com", consumer_key: "12345", shared_secret: "secret")
  end

  let(:assignment) do
    @course.assignments.create!(
      {
        title: "value for title",
        description: "value for description",
        due_at: Time.zone.now,
        points_possible: "1.5",
        submission_types: "external_tool",
        external_tool_tag_attributes: { url: tool.url }
      }
    )
  end

  let(:xml) do
    Nokogiri::XML.parse <<~XML
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
    XML
  end

  let(:source_id) { gen_source_id }

  def gen_source_id(t: tool, c: @course, a: assignment, u: @user)
    tool.shard.activate do
      payload = [t.id, c.id, a.id, u.id].join("-")
      "#{payload}-#{Canvas::Security.hmac_sha1(payload, tool.shard.settings[:encryption_key])}"
    end
  end

  def expect_request_failure(request, description:, error_code:, body: nil)
    expect(request.code_major).to eq "failure"
    expect(request.body).to eq(body) if body
    expect(request.description).to eq description
    expect(request.error_code).to eq error_code
  end

  describe BasicLTI::BasicOutcomes::LtiResponse do
    subject { lti_response.needs_additional_review? }

    let(:lti_response) { BasicLTI::BasicOutcomes::LtiResponse.new(xml) }

    describe "#needs_additional_review?" do
      context "when the needsAdditionalReview element is present" do
        before do
          xml.at_css("imsx_POXBody > replaceResultRequest").add_child(
            "<submissionDetails><needsAdditionalReview/></submissionDetails>"
          )
        end

        it { is_expected.to be true }
      end

      context "when the needsAdditionalReview element is absent" do
        it { is_expected.to be false }
      end
    end
  end

  context "Exceptions" do
    it "BasicLTI::BasicOutcomes::Unauthorized should have 401 status" do
      raise BasicLTI::BasicOutcomes::Unauthorized, "Invalid signature"
    rescue BasicLTI::BasicOutcomes::Unauthorized => e
      expect(e.response_status).to be 401
    end

    it "sends unauthorized request metrics to datadog" do
      expect(InstStatsd::Statsd).to receive(:increment)
        .with("lti.1_1.basic_outcomes.bad_requests",
              tags: { error_code: "Unauthorized" })
      expect { raise BasicLTI::BasicOutcomes::Unauthorized, "some unauthorized reason" }
        .to raise_error(BasicLTI::BasicOutcomes::Unauthorized)
    end

    it "BasicLTI::BasicOutcomes::InvalidRequest should have 415 status" do
      raise BasicLTI::BasicOutcomes::InvalidRequest, "Invalid request"
    rescue BasicLTI::BasicOutcomes::InvalidRequest => e
      expect(e.response_status).to be 415
    end

    it "sends invalid request metrics to datadog" do
      expect(InstStatsd::Statsd).to receive(:increment)
        .with("lti.1_1.basic_outcomes.bad_requests",
              tags: { error_code: "InvalidRequest" })
      expect { raise BasicLTI::BasicOutcomes::InvalidRequest, "some invalid request reason" }
        .to raise_error(BasicLTI::BasicOutcomes::InvalidRequest)
    end
  end

  describe ".decode_source_id" do
    it "successfully decodes a source_id" do
      expect(described_class.decode_source_id(tool, source_id)).to eq [assignment, @user]
    end

    it "throws Invalid sourcedid if sourcedid is nil" do
      expect { described_class.decode_source_id(tool, nil) }
        .to raise_error(BasicLTI::Errors::InvalidSourceId, "Invalid sourcedid")
    end

    it "throws Invalid sourcedid if sourcedid is empty" do
      expect { described_class.decode_source_id(tool, "") }
        .to raise_error(BasicLTI::Errors::InvalidSourceId, "Invalid sourcedid")
    end

    it "throws Invalid signature if the signature is invalid" do
      bad_signature = source_id.split("-")[0..3].join("-") + "-asb9dksld9k3"
      expect { described_class.decode_source_id(tool, bad_signature) }
        .to raise_error(BasicLTI::Errors::InvalidSourceId, "Invalid signature")
    end

    it "throws 'Tool is invalid' if the tool doesn't match" do
      t = @course.context_external_tools
                 .create(name: "b", url: "http://google.com", consumer_key: "12345", shared_secret: "secret")
      expect { described_class.decode_source_id(tool, gen_source_id(t:)) }
        .to raise_error(BasicLTI::Errors::InvalidSourceId, "Tool is invalid")
    end

    it "throws Course is invalid if the course doesn't match" do
      @course.workflow_state = "deleted"
      @course.save!
      expect { described_class.decode_source_id(tool, source_id) }
        .to raise_error(BasicLTI::Errors::InvalidSourceId, "Course is invalid")
    end

    it "throws User is no longer in course isuser enrollment is missing" do
      @user.enrollments.destroy_all
      expect { described_class.decode_source_id(tool, source_id) }
        .to raise_error(BasicLTI::Errors::InvalidSourceId, "User is no longer in course")
    end

    it "throws Assignment is invalid if the Addignment doesn't match" do
      assignment.destroy
      expect { described_class.decode_source_id(tool, source_id) }
        .to raise_error(BasicLTI::Errors::InvalidSourceId, "Assignment is invalid")
    end

    it "throws Assignment is no longer associated with this tool if tool is deleted" do
      tool.destroy
      expect { described_class.decode_source_id(tool, source_id) }
        .to raise_error(BasicLTI::Errors::InvalidSourceId, "Assignment is no longer associated with this tool")
    end

    it "throws Assignment is no longer associated with this tool if tool doesn't match the url" do
      tag = assignment.external_tool_tag
      tag.url = "example.com"
      tag.save!
      expect { described_class.decode_source_id(tool, source_id) }
        .to raise_error(BasicLTI::Errors::InvalidSourceId, "Assignment is no longer associated with this tool")
    end

    it "throws Assignment is no longer associated with this tool if tag is missing" do
      assignment.external_tool_tag.delete
      expect { described_class.decode_source_id(tool, source_id) }
        .to raise_error(BasicLTI::Errors::InvalidSourceId, "Assignment is no longer associated with this tool")
    end

    context "jwt sourcedid" do
      before do
        fake_lti_secrets = {
          "lti-signing-secret" => Base64.encode64("signing-secret-vp04BNqApwdwUYPUI"),
          "lti-encryption-secret" => Base64.encode64("encryption-secret-5T14NjaTbcYjc4")
        }

        allow(Rails.application.credentials).to receive(:dig)
          .with(:lti, :signing_secret)
          .and_return(fake_lti_secrets["lti-signing-secret"])

        allow(Rails.application.credentials).to receive(:dig)
          .with(:lti, :encryption_secret)
          .and_return(fake_lti_secrets["lti-encryption-secret"])
      end

      let(:jwt_source_id) do
        BasicLTI::Sourcedid.new(tool, @course, assignment, @user).to_s
      end

      it "decodes a jwt signed sourcedid" do
        expect(described_class.decode_source_id(tool, jwt_source_id)).to eq [assignment, @user]
      end

      it "throws invalid JWT if token is unrecognized" do
        missing_signature = source_id.split("-")[0..3].join("-")
        expect { described_class.decode_source_id(tool, missing_signature) }
          .to raise_error(BasicLTI::Errors::InvalidSourceId, "Invalid sourcedid")
      end
    end
  end

  describe "#handle_request" do
    it "sets the response body when an invalid sourcedId is given" do
      xml.css("sourcedId").remove
      response = BasicLTI::BasicOutcomes::LtiResponse.new(xml)
      response.handle_request(tool)
      expect_request_failure(response, error_code: :sourcedid_invalid, description: "Invalid sourcedid")
      expect(response.body).not_to be_nil
    end

    context "with an unrecognized operation identifier" do
      before do
        xml.css("resultData").remove
        xml.css("replaceResultRequest").each do |node|
          node.replace(Nokogiri::XML::DocumentFragment.parse(
                         "<fakeResultRequest>#{xml.css("replaceResultRequest").inner_html}</fakeResultRequest>"
                       ))
        end
      end

      it "returns false" do
        response = BasicLTI::BasicOutcomes::LtiResponse.new(xml)
        result = response.handle_request(tool)
        expect(result).to be false
      end

      it "does not report a total count metric" do
        allow(InstStatsd::Statsd).to receive(:increment).and_call_original
        response = BasicLTI::BasicOutcomes::LtiResponse.new(xml)
        response.handle_request(tool)
        expect(InstStatsd::Statsd).not_to have_received(:increment).with("lti.1_1.basic_outcomes.requests")
      end
    end

    context "request metrics" do
      before do
        allow(InstStatsd::Statsd).to receive(:increment).and_call_original
      end

      it "increments a total count metric" do
        response = BasicLTI::BasicOutcomes::LtiResponse.new(xml)
        response.handle_request(tool)
        expect(InstStatsd::Statsd).to have_received(:increment).with("lti.1_1.basic_outcomes.requests", tags: { op: "replace_result", type: :basic })
      end

      context "when report_failure is called" do
        before do
          e = BasicLTI::Errors::InvalidSourceId.new("test error", :test)
          allow(BasicLTI::BasicOutcomes).to receive(:decode_source_id).and_raise(e)
        end

        it "increments a failure count metric" do
          response = BasicLTI::BasicOutcomes::LtiResponse.new(xml)
          response.handle_request(tool)
          expect(InstStatsd::Statsd).to have_received(:increment).with("lti.1_1.basic_outcomes.failures", tags: { op: "replace_result", type: :basic, error_code: :test })
        end
      end
    end

    context "when the sourcedid points to a concluded course" do
      before do
        @course.start_at = 1.month.ago
        @course.conclude_at = 1.day.ago
        @course.restrict_enrollments_to_course_dates = true
        @course.save
      end

      it "rejects replace_result" do
        xml.css("resultData").remove
        request = BasicLTI::BasicOutcomes.process_request(tool, xml)

        expect_request_failure(
          request,
          body: "<replaceResultResponse />",
          description: "Course not available for student",
          error_code: :course_not_available
        )
        expect(request.handle_request(tool)).to be_truthy
      end

      it "replace_result succeeds when section dates override course dates" do
        cs = CourseSection.where(id: @course.enrollments.where(user_id: @user).pluck(:course_section_id)).take
        cs.start_at = 1.day.ago
        cs.end_at = 1.day.from_now
        cs.restrict_enrollments_to_section_dates = true
        cs.save
        xml.css("resultData").remove
        request = BasicLTI::BasicOutcomes.process_request(tool, xml)

        expect(request.code_major).to eq "success"
        expect(request.body).to eq "<replaceResultResponse />"
        expect(request.handle_request(tool)).to be_truthy
      end

      it "rejects delete_result" do
        xml.css("resultData").remove
        xml.css("replaceResultRequest").each do |node|
          node.replace(Nokogiri::XML::DocumentFragment.parse(
                         "<deleteResultRequest>#{xml.css("replaceResultRequest").inner_html}</deleteResultRequest>"
                       ))
        end
        request = BasicLTI::BasicOutcomes.process_request(tool, xml)

        expect_request_failure(
          request,
          body: "<deleteResultResponse />",
          description: "Course not available for student",
          error_code: :course_not_available
        )
        expect(request.handle_request(tool)).to be_truthy
      end

      # not 100% sure they should be able to read when the course is concluded, but I think they can
      it "allows a read_result" do
        xml.css("resultData").remove
        xml.css("replaceResultRequest").each do |node|
          node.replace(Nokogiri::XML::DocumentFragment.parse(
                         "<readResultRequest>#{xml.css("replaceResultRequest").inner_html}</readResultRequest>"
                       ))
        end
        request = BasicLTI::BasicOutcomes.process_request(tool, xml)

        expect(request.code_major).to eq "success"
        expect(request.handle_request(tool)).to be_truthy
      end
    end
  end

  describe "#handle_replace_result" do
    it "accepts a grade" do
      xml.css("resultData").remove
      request = BasicLTI::BasicOutcomes.process_request(tool, xml)

      expect(request.code_major).to eq "success"
      expect(request.body).to eq "<replaceResultResponse />"
      expect(request.handle_request(tool)).to be_truthy
      submission = assignment.submissions.where(user_id: @user.id).first
      expected_value = assignment.points_possible * BigDecimal("0.92")
      expect(submission.grade).to eq expected_value.to_s
    end

    it "rejects a grade for an assignment with no points possible" do
      xml.css("resultData").remove
      assignment.points_possible = nil
      assignment.save!
      request = BasicLTI::BasicOutcomes.process_request(tool, xml)

      expect_request_failure(
        request,
        body: "<replaceResultResponse />",
        description: "Assignment has no points possible.",
        error_code: :no_points_possible
      )
    end

    it "doesn't explode when an assignment with no points possible receives a grade for an existing submission" do
      xml.css("resultData").remove
      assignment.points_possible = nil
      assignment.save!
      BasicLTI::BasicOutcomes.process_request(tool, xml)
      request = BasicLTI::BasicOutcomes.process_request(tool, xml)

      expect_request_failure(
        request,
        body: "<replaceResultResponse />",
        description: "Assignment has no points possible.",
        error_code: :no_points_possible
      )
    end

    it "handles tools that have a url mismatch with the assignment" do
      assignment.external_tool_tag_attributes = { url: "http://example.com/foo" }
      assignment.save!
      request = BasicLTI::BasicOutcomes.process_request(tool, xml)
      expect(request.code_major).to eq "failure"
      expect(request.body).to eq "<replaceResultResponse />"
      expect(request.description).to eq "Assignment is no longer associated with this tool"
      expect_request_failure(
        request,
        body: "<replaceResultResponse />",
        description: "Assignment is no longer associated with this tool",
        error_code: :assignment_tool_mismatch
      )
    end

    it "accepts a result data without grade" do
      xml.css("resultScore").remove
      request = BasicLTI::BasicOutcomes.process_request(tool, xml)
      expect(request.code_major).to eq "success"
      expect(request.body).to eq "<replaceResultResponse />"
      expect(request.handle_request(tool)).to be_truthy
      submission = assignment.submissions.where(user_id: @user.id).first
      expect(submission.body).to eq "text data for canvas submission"
      expect(submission.grade).to be_nil
      expect(submission.workflow_state).to eq "submitted"
    end

    it "fails if neither result data or a grade is sent" do
      xml.css("resultData").remove
      xml.css("resultScore").remove
      request = BasicLTI::BasicOutcomes.process_request(tool, xml)
      expect_request_failure(
        request,
        body: "<replaceResultResponse />",
        description: "No score given",
        error_code: :no_score
      )
    end

    it "Does not increment the attempt number" do
      xml.css("resultData").remove
      BasicLTI::BasicOutcomes.process_request(tool, xml)
      submission = assignment.submissions.where(user_id: @user.id).first
      expect(submission.attempt).to eq 1
    end

    it "when result data is not sent, only changes 'submitted_at' if the submission is not submitted yet" do
      xml.css("resultData").remove
      submission = assignment.submissions.where(user_id: @user.id).first
      submitted_at = nil
      Timecop.freeze do
        BasicLTI::BasicOutcomes.process_request(tool, xml)
        submitted_at = submission.reload.submitted_at
        expect(submitted_at).to eq Time.zone.now
      end
      Timecop.freeze(2.minutes.from_now) do
        BasicLTI::BasicOutcomes.process_request(tool, xml)
        expect(submission.reload.submitted_at).to eq submitted_at
      end
    end

    context "with submitted_at details" do
      let(:timestamp) { 1.day.ago.iso8601(3) }

      it "sets submitted_at to submitted_at details if resultData is not present" do
        xml.css("resultData").remove
        xml.at_css("imsx_POXBody > replaceResultRequest").add_child(
          "<submissionDetails><submittedAt>#{timestamp}</submittedAt></submissionDetails>"
        )
        BasicLTI::BasicOutcomes.process_request(tool, xml)
        submission = assignment.submissions.where(user_id: @user.id).first
        expect(submission.submitted_at.iso8601(3)).to eq timestamp
      end

      it "does not increment the submission count" do
        xml.css("resultData").remove
        xml.at_css("imsx_POXBody > replaceResultRequest").add_child(
          "<submissionDetails><submittedAt>#{timestamp}</submittedAt></submissionDetails>"
        )
        BasicLTI::BasicOutcomes.process_request(tool, xml)
        submission = assignment.submissions.where(user_id: @user.id).first
        expect(submission.attempt).to eq 1
      end

      it "sets submitted_at to submitted_at details if resultData is present" do
        xml.at_css("imsx_POXBody > replaceResultRequest").add_child(
          "<submissionDetails><submittedAt>#{timestamp}</submittedAt></submissionDetails>"
        )
        BasicLTI::BasicOutcomes.process_request(tool, xml)
        submission = assignment.submissions.where(user_id: @user.id).first
        expect(submission.submitted_at.iso8601(3)).to eq timestamp
      end

      context "with timestamp in future" do
        let(:timestamp) { Time.zone.now }

        it "returns error message for timestamp more than one minute in future" do
          xml.at_css("imsx_POXBody > replaceResultRequest").add_child(
            "<submissionDetails><submittedAt>#{timestamp}</submittedAt></submissionDetails>"
          )
          Timecop.freeze(2.minutes.ago) do
            request = BasicLTI::BasicOutcomes.process_request(tool, xml)
            expect_request_failure(
              request,
              body: "<replaceResultResponse />",
              description: "Invalid timestamp - timestamp in future",
              error_code: :timestamp_in_future
            )
          end
        end

        it "does not create submission" do
          xml.at_css("imsx_POXBody > replaceResultRequest").add_child(
            "<submissionDetails><submittedAt>#{timestamp}</submittedAt></submissionDetails>"
          )
          Timecop.freeze(2.minutes.ago) do
            BasicLTI::BasicOutcomes.process_request(tool, xml)
            expect(assignment.submissions.where(user_id: @user.id).first.submitted_at).to be_blank
          end
        end
      end

      context "with invalid timestamp" do
        let(:timestamp) { "a" }

        it "returns error message for invalid timestamp" do
          xml.at_css("imsx_POXBody > replaceResultRequest").add_child(
            "<submissionDetails><submittedAt>#{timestamp}</submittedAt></submissionDetails>"
          )
          request = BasicLTI::BasicOutcomes.process_request(tool, xml)
          expect_request_failure(
            request,
            body: "<replaceResultResponse />",
            description: "Invalid timestamp - timestamp not parseable",
            error_code: :timestamp_not_parseable
          )
        end

        it "does not create submission" do
          xml.at_css("imsx_POXBody > replaceResultRequest").add_child(
            "<submissionDetails><submittedAt>#{timestamp}</submittedAt></submissionDetails>"
          )
          BasicLTI::BasicOutcomes.process_request(tool, xml)
          expect(assignment.submissions.where(user_id: @user.id).first.submitted_at).to be_blank
        end
      end
    end

    context "with prioritizeNonToolGrade details" do
      before do
        xml.at_css("imsx_POXBody > replaceResultRequest").add_child(
          "<submissionDetails><prioritizeNonToolGrade/></submissionDetails>"
        )
      end

      it "is correctly parsed and identified" do
        response = BasicLTI::BasicOutcomes.process_request(tool, xml)
        expect(response).to be_prioritize_non_tool_grade
      end

      it "does not overwrite a non tool grade" do
        submission = assignment.grade_student(@user, grader: @teacher, grade: 177.0).first
        BasicLTI::BasicOutcomes.process_request(tool, xml)
        submission.reload
        expect(submission.score).to eq(177.0)
      end

      it "does not overwrite the grader id" do
        submission = assignment.grade_student(@user, grader: @teacher, grade: 177.0).first
        BasicLTI::BasicOutcomes.process_request(tool, xml)
        submission.reload
        expect(submission.grader_id).to eq(@teacher.id)
      end
    end

    context "without prioritizeNonToollGrade details" do
      it "is properly identified as not being there" do
        response = BasicLTI::BasicOutcomes.process_request(tool, xml)
        expect(response).not_to be_prioritize_non_tool_grade
      end

      it "overwrites a non tool grade" do
        submission = assignment.grade_student(@user, grader: @teacher, grade: 177.0).first
        BasicLTI::BasicOutcomes.process_request(tool, xml)
        submission.reload
        # 1.38 is assignment points possible of 1.5 * 92% from the xml
        expect(submission.score).to eq(1.38)
      end

      it "overwrites the non tool grader id" do
        submission = assignment.grade_student(@user, grader: @teacher, grade: 177.0).first
        BasicLTI::BasicOutcomes.process_request(tool, xml)
        submission.reload
        expect(submission.grader_id).to eq(-tool.id)
      end
    end

    it "accepts LTI launch URLs as a data format with a specific submission type" do
      xml.css("resultScore").remove
      xml.at_css("text").replace("<ltiLaunchUrl>http://example.com/launch</ltiLaunchUrl>")
      request = BasicLTI::BasicOutcomes.process_request(tool, xml)

      expect(request.code_major).to eq "success"
      expect(request.body).to eq "<replaceResultResponse />"
      expect(request.handle_request(tool)).to be_truthy
      submission = assignment.submissions.where(user_id: @user.id).first
      expect(submission.submission_type).to eq "basic_lti_launch"
    end

    context "quizzes.next submissions" do
      let(:tool) do
        @course.context_external_tools.create(
          name: "a",
          url: "http://google.com",
          consumer_key: "12345",
          shared_secret: "secret",
          tool_id: "Quizzes 2"
        )
      end

      let(:assignment) do
        @course.assignments.create!(
          {
            title: "Quizzes.next Quiz",
            description: "value for description",
            due_at: Time.zone.now,
            points_possible: "1.5",
            submission_types: "external_tool",
            grading_type: "letter_grade",
            external_tool_tag_attributes: { url: tool.url }
          }
        )
      end

      let(:submitted_at_timestamp) { 1.day.ago.iso8601(3) }

      it "stores the score and grade for quizzes.next assignments" do
        xml.css("resultData").remove
        xml.at_css("imsx_POXBody > replaceResultRequest > resultRecord > result").add_child(
          "<resultData><text>#{submitted_at_timestamp}</text>
          <url>http://example.com/launch</url></resultData>"
        )
        BasicLTI::BasicOutcomes.process_request(tool, xml)
        expect(assignment.submissions.first.grade).to eq "A-"
      end

      context "request metrics" do
        before do
          allow(InstStatsd::Statsd).to receive(:increment).and_call_original
        end

        it "tags count with request type quizzes" do
          BasicLTI::BasicOutcomes.process_request(tool, xml)
          expect(InstStatsd::Statsd).to have_received(:increment).with("lti.1_1.basic_outcomes.requests", tags: { op: "replace_result", type: :quizzes })
        end
      end
    end

    context "submissions" do
      it "creates a new submissions if there isn't one" do
        xml.css("resultData").remove
        expect { BasicLTI::BasicOutcomes.process_request(tool, xml) }
          .to change { assignment.submissions.not_placeholder.where(user_id: @user.id).count }.from(0).to(1)
      end

      it 'creates a new submission of type "external_tool" when a grade is passed back without a submission' do
        xml.css("resultData").remove
        BasicLTI::BasicOutcomes.process_request(tool, xml)
        expect(assignment.submissions.where(user_id: @user.id).first.submission_type).to eq "external_tool"
      end

      it "sets the submission type to external tool if the existing submission_type is nil" do
        submission = assignment.grade_student(
          @user,
          {
            grade: "92%",
            grader_id: -1
          }
        ).first
        xml.css("resultData").remove
        BasicLTI::BasicOutcomes.process_request(tool, xml)
        expect(submission.reload.submission_type).to eq "external_tool"
      end

      it "creates a new submission if result_data_text is sent" do
        submission = assignment.submit_homework(
          @user,
          {
            submission_type: "online_text_entry",
            body: "sample text",
            grade: "92%"
          }
        )
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
          }
        )
        xml.css("resultScore").remove
        xml.at_css("text").replace("<url>http://example.com/launch</url>")
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
          }
        )
        xml.css("resultScore").remove
        xml.at_css("text").replace("<ltiLaunchUrl>http://example.com/launch</ltiLaunchUrl>")
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
          }
        )
        xml.css("resultScore").remove
        xml.at_css("text").replace("<documentName>face.doc</documentName><downloadUrl>http://example.com/download</downloadUrl>")
        BasicLTI::BasicOutcomes.process_request(tool, xml)
        expect(Delayed::Job.strand_size("file_download/example.com")).to be > 0
        stub_request(:get, "http://example.com/download").to_return(status: 200, body: "file body")
        run_jobs
        expect(submission.reload.versions.count).to eq 2
        expect(submission.attachments.count).to eq 1
        expect(submission.attachments.first.display_name).to eq "face.doc"
      end

      it "doesn't change the submission type if only the score is sent" do
        submission_type = "online_text_entry"
        submission = assignment.submit_homework(
          @user,
          {
            submission_type:,
            body: "sample text",
            grade: "92%"
          }
        )
        xml.css("resultData").remove
        BasicLTI::BasicOutcomes.process_request(tool, xml)
        expect(submission.reload.submission_type).to eq submission_type
      end
    end

    context "sharding" do
      specs_require_sharding
      let(:source_id) { gen_source_id(u: @user1) }

      it "succeeds with cross-sharded users" do
        @shard1.activate do
          @root = Account.create
          @user1 = user_with_managed_pseudonym(active_all: true,
                                               account: @root,
                                               name: "Jimmy John",
                                               username: "other_shard@example.com",
                                               sis_user_id: "other_shard")
        end
        @course.enroll_student(@user1)
        xml.css("resultData").remove
        request = BasicLTI::BasicOutcomes.process_request(tool, xml)

        expect(request.code_major).to eq "success"
        expect(request.body).to eq "<replaceResultResponse />"
        expect(request.handle_request(tool)).to be_truthy
        submission = assignment.submissions.where(user_id: @user1.id).first
        expected_value = assignment.points_possible * BigDecimal("0.92")
        expect(submission.grade).to eq expected_value.to_s
      end
    end
  end

  context "with attachments" do
    before do
      xml.css("resultScore").remove
      xml.at_css("text").replace("<documentName>face.doc</documentName><downloadUrl>http://example.com/download</downloadUrl>")
    end

    it "if not provided should submit the homework at the submitted_at time of when the request was received" do
      submitted_at = Timecop.freeze(1.hour.ago) do
        BasicLTI::BasicOutcomes.process_request(tool, xml)
        Time.zone.now
      end
      stub_request(:get, "http://example.com/download").to_return(status: 200, body: "file body")
      run_jobs
      expect(assignment.submissions.find_by(user_id: @user).submitted_at).to eq submitted_at
    end

    it "retries attachments if they fail to upload" do
      submission = assignment.submit_homework(
        @user,
        {
          submission_type: "online_text_entry",
          body: "sample text",
          grade: "92%"
        }
      )
      BasicLTI::BasicOutcomes.process_request(tool, xml)
      expect(Delayed::Job.strand_size("file_download/example.com")).to be > 0
      stub_request(:get, "http://example.com/download").to_return(status: 500)
      Timecop.freeze do
        run_jobs
        expect(Delayed::Job.find_by(strand: "file_download/example.com/failed").run_at).to be > 5.seconds.from_now
      end
      expect(submission.reload.versions.count).to eq 1
      expect(submission.attachments.count).to eq 0
      expect(Attachment.last.file_state).to eq "errored"
      expect(Delayed::Job.strand_size("file_download/example.com/failed")).to be > 0
    end

    it "submits after the retries complete" do
      BasicLTI::BasicOutcomes.process_request(tool, xml)
      expect(Delayed::Job.strand_size("file_download/example.com")).to be > 0
      stub_const("BasicLTI::BasicOutcomes::MAX_ATTEMPTS", 1)
      stub_request(:get, "http://example.com/download").to_return(status: 500)
      run_jobs
      expect(Delayed::Job.strand_size("file_download/example.com/failed")).to eq 0
      submission = assignment.submissions.find_by(user: @user)
      expect(submission.reload.versions.count).to eq 1
      expect(submission.attachments.count).to eq 1
      expect(Attachment.last.file_state).to eq "errored"
    end

    it "submits after successful retry", custom_timeout: 60 do
      BasicLTI::BasicOutcomes.process_request(tool, xml)
      expect(Delayed::Job.strand_size("file_download/example.com")).to be > 0
      stub_request(:get, "http://example.com/download").to_return({ status: 500 }, { status: 200, body: "file body" })
      Timecop.freeze do
        run_jobs
        expect(Delayed::Job.strand_size("file_download/example.com/failed")).to be > 0
      end
      Timecop.freeze(6.seconds.from_now) do
        run_jobs
        expect(Delayed::Job.strand_size("file_download/example.com/failed")).to eq 0
        submission = assignment.submissions.find_by(user: @user)
        expect(submission.reload.versions.count).to eq 1
        expect(submission.attachments.count).to eq 1
        expect(submission.attachments.take.file_state).to eq "available"
      end
    end

    context "job metrics" do
      before do
        allow(InstStatsd::Statsd).to receive(:increment).and_call_original
      end

      context "on success" do
        before do
          stub_request(:get, "http://example.com/download").to_return(status: 200, body: "file body")
        end

        it "increments a total count metric" do
          BasicLTI::BasicOutcomes.process_request(tool, xml)
          run_jobs
          expect(InstStatsd::Statsd).to have_received(:increment).with("lti.1_1.basic_outcomes.fetch_jobs")
        end
      end

      context "on failure" do
        before do
          stub_request(:get, "http://example.com/download").to_return(status: 500)
        end

        it "increments a failure metric" do
          BasicLTI::BasicOutcomes.process_request(tool, xml)
          run_jobs
          expect(InstStatsd::Statsd).to have_received(:increment).with("lti.1_1.basic_outcomes.fetch_jobs_failures")
        end
      end
    end
  end

  describe "#process_request" do
    context "when assignment is a Quizzes.Next quiz" do
      let(:tool) do
        @course.context_external_tools.create(
          name: "a",
          url: "http://google.com",
          consumer_key: "12345",
          shared_secret: "secret",
          tool_id: "Quizzes 2"
        )
      end

      it "uses BasicLTI::QuizzesNextLtiResponse object" do
        expect(BasicLTI::QuizzesNextLtiResponse).to receive(:new).and_call_original
        BasicLTI::BasicOutcomes.process_request(tool, xml)
      end

      context "when quizzes_next_submission_history is off" do
        before do
          allow(tool.context.root_account).to receive(:feature_enabled?).and_call_original
          allow(tool.context.root_account).to receive(:feature_enabled?)
            .with(:quizzes_next_submission_history).and_return(false)
        end

        it "uses BasicLTI::BasicOutcomes::LtiResponse object" do
          expect(BasicLTI::BasicOutcomes::LtiResponse).to receive(:new).and_call_original
          expect(BasicLTI::QuizzesNextLtiResponse).not_to receive(:new)
          BasicLTI::BasicOutcomes.process_request(tool, xml)
        end
      end
    end

    context "when assignment is not a Quizzes.Next quiz" do
      it "uses BasicLTI::BasicOutcomes::LtiResponse object" do
        expect(BasicLTI::BasicOutcomes::LtiResponse).to receive(:new).and_call_original
        expect(BasicLTI::QuizzesNextLtiResponse).not_to receive(:new)
        BasicLTI::BasicOutcomes.process_request(tool, xml)
      end
    end
  end

  describe "LTIReponse.ensure_score_update_possible" do
    let(:lti_response) { BasicLTI::BasicOutcomes::LtiResponse }
    let(:submission) { Submission.find_by(assignment_id: assignment.id, user_id: @user.id) }

    it "invokes the block when there is no submission" do
      expect do |b|
        lti_response.ensure_score_update_possible(submission: nil, prioritize_non_tool_grade: :taco, &b)
      end.to yield_control
    end

    it "invokes the block when the grader_id is in the tool id range" do
      submission.grader_id = -100
      expect do |b|
        lti_response.ensure_score_update_possible(submission:, prioritize_non_tool_grade: :taco, &b)
      end.to yield_control
    end

    it "does not invoke the block when the grader_id is in the user id range and prioritize_non_tool_grade is true" do
      submission.grader_id = 100
      expect do |b|
        lti_response.ensure_score_update_possible(submission:, prioritize_non_tool_grade: true, &b)
      end.not_to yield_control
    end

    it "invokes the block when the grader_id is in the user id range and prioritize_non_tool_grade is false" do
      submission.grader_id = 100
      expect do |b|
        lti_response.ensure_score_update_possible(submission:, prioritize_non_tool_grade: false, &b)
      end.to yield_control
    end
  end
end
