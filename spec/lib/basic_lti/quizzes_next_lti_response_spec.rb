# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

describe BasicLTI::QuizzesNextLtiResponse do
  before do
    course_model.offer
    @root_account = @course.root_account
    @account = account_model(root_account: @root_account, parent_account: @root_account)
    @course.update_attribute(:account, @account)
    @user = factory_with_protected_attributes(User, name: "some user", workflow_state: "registered")
    @course.enroll_student(@user)
  end

  let(:tool) do
    @course.context_external_tools.create(name: "a", url: "http://google.com", consumer_key: "12345", shared_secret: "secret", tool_id: "Quizzes 2")
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

  let(:source_id) { gen_source_id }

  let(:launch_url) { "https://abcdef.com/uuurrrlll00" }

  let(:timestamp) { 1.day.ago.iso8601(3) }

  let(:text) { "" }

  let(:grade) { "0.12" }

  let(:xml) do
    request_xml(source_id, launch_url, grade)
  end

  def gen_source_id(t: tool, c: @course, a: assignment, u: @user)
    tool.shard.activate do
      payload = [t.id, c.id, a.id, u.id].join("-")
      "#{payload}-#{Canvas::Security.hmac_sha1(payload, tool.shard.settings[:encryption_key])}"
    end
  end

  def request_xml(source_id, launch_url, grade)
    Nokogiri::XML.parse <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <imsx_POXEnvelopeRequest xmlns="http://www.imsglobal.org/services/ltiv1p1/xsd/imsoms_v1p0">
        <imsx_POXHeader>
          <imsx_POXRequestHeaderInfo>
            <imsx_version>V1.0</imsx_version>
            <imsx_messageIdentifier>8d4280b4-0e6f-484f-918d-efa4d0a5910e</imsx_messageIdentifier>
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
                  <textString>#{grade}</textString>
                </resultScore>
                <resultData>
                  <text>#{text}</text>
                  <url>#{launch_url}</url>
                </resultData>
              </result>
            </resultRecord>
            <submissionDetails>
              <submittedAt>#{timestamp}</submittedAt>
            </submissionDetails>
          </replaceResultRequest>
        </imsx_POXBody>
      </imsx_POXEnvelopeRequest>
    XML
  end

  describe "#handle_replace_result" do
    it "accepts a grade" do
      request = BasicLTI::BasicOutcomes.process_request(tool, xml)

      expect(request.code_major).to eq "success"
      expect(request.body).to eq "<replaceResultResponse />"
      expect(request.handle_request(tool)).to be_truthy
      submission = assignment.submissions.where(user_id: @user.id).first
      expect(submission.grade).to eq((assignment.points_possible * 0.12).to_s)
    end

    context "when the assignment is set to displays grade as complete/incomplete" do
      let(:assignment) do
        @course.assignments.create!(
          {
            title: "value for title",
            description: "value for description",
            due_at: Time.zone.now,
            points_possible: "1.5",
            submission_types: "external_tool",
            grading_type: "pass_fail",
            external_tool_tag_attributes: { url: tool.url }
          }
        )
      end

      context "when the assignment has nil points_possible" do
        subject { BasicLTI::BasicOutcomes.process_request(tool, xml) }

        let(:grading_type) { raise "set in examples" }

        before { assignment.update!(points_possible: nil, grading_type:) }

        context "and the grading_type requires points" do
          let(:grading_type) { Assignment::GRADING_TYPES.points }

          it "sets the assignment points_possible to the default" do
            expect { subject }.to change { assignment.reload.points_possible }
              .from(nil).to(Assignment::DEFAULT_POINTS_POSSIBLE)
          end

          it "sets code_major to 'success'" do
            expect(subject.code_major).to eq "success"
          end

          it "sets the submission grade to zero" do
            subject
            submission = assignment.submissions.where(user_id: @user.id).first
            expect(submission.grade).to eq "0"
          end
        end

        context "and the grading type does not require points" do
          let(:grading_type) { Assignment::GRADING_TYPES.not_graded }

          it "sets code major to 'failure'" do
            expect(subject.code_major).to eq "failure"
          end

          it "sets the failure description" do
            expect(subject.description).to eq "Assignment has no points possible."
          end
        end
      end

      it "shows complete when it receives a grade > 0" do
        request = BasicLTI::BasicOutcomes.process_request(tool, xml)

        expect(request.code_major).to eq "success"
        expect(request.body).to eq "<replaceResultResponse />"
        expect(request.handle_request(tool)).to be_truthy
        submission = assignment.submissions.where(user_id: @user.id).first
        expect(submission.grade).to eq "complete"
      end

      it "shows incomplete when it receives a grade = 0" do
        grade = 0
        xml = request_xml(source_id, launch_url, grade)

        request = BasicLTI::BasicOutcomes.process_request(tool, xml)

        expect(request.code_major).to eq "success"
        expect(request.body).to eq "<replaceResultResponse />"
        expect(request.handle_request(tool)).to be_truthy
        submission = assignment.submissions.where(user_id: @user.id).first
        expect(submission.grade).to eq "incomplete"
      end
    end

    it "doesn't explode when an assignment with no points possible receives a grade for an existing submission" do
      xml.css("resultData").remove

      assignment.update!(
        points_possible: nil,
        grading_type: Assignment::GRADING_TYPES.not_graded
      )

      BasicLTI::BasicOutcomes.process_request(tool, xml)
      request = BasicLTI::BasicOutcomes.process_request(tool, xml)

      expect(request.code_major).to eq "failure"
      expect(request.body).to eq "<replaceResultResponse />"
      expect(request.description).to eq "Assignment has no points possible."
    end

    it "handles tools that have a url mismatch with the assignment" do
      assignment.external_tool_tag_attributes = { url: "http://example.com/foo" }
      assignment.save!
      request = BasicLTI::BasicOutcomes.process_request(tool, xml)
      expect(request.code_major).to eq "failure"
      expect(request.body).to eq "<replaceResultResponse />"
      expect(request.description).to eq "Assignment is no longer associated with this tool"
    end

    it "fails if neither result data or a grade is sent" do
      xml.css("resultData").remove
      xml.css("resultScore").remove
      request = BasicLTI::BasicOutcomes.process_request(tool, xml)
      expect(request.code_major).to eq "failure"
      expect(request.body).to eq "<replaceResultResponse />"
    end

    it "reads 'submitted_at' from submissionDetails" do
      BasicLTI::BasicOutcomes.process_request(tool, xml)
      submission = assignment.submissions.where(user_id: @user.id).first
      expect(submission.submitted_at).to eq timestamp
    end

    context "when submission is deleted" do
      let(:submission) { Submission.find_or_initialize_by(assignment:, user: @user) }
      let(:quiz_lti_submission) { BasicLTI::QuizzesNextVersionedSubmission.new(assignment, @user) }

      before do
        allow(BasicLTI::QuizzesNextVersionedSubmission).to receive(:new).and_return(quiz_lti_submission)
        allow(quiz_lti_submission).to receive(:submission).and_return(submission)
        submission.update_column :workflow_state, "deleted"
      end

      it "reports failure" do
        request = BasicLTI::BasicOutcomes.process_request(tool, xml)
        expect(request.code_major).to eq "failure"
        expect(request.error_code).to eq :submission_deleted
        expect(request.description).to eq "Submission is deleted and cannot be modified."
      end
    end

    context "when submission validation raises an error" do
      let(:submission) { Submission.find_or_initialize_by(assignment:, user: @user) }
      let(:quiz_lti_submission) { BasicLTI::QuizzesNextVersionedSubmission.new(assignment, @user) }
      let(:grades) { [0.11, 0.22, 0.33] }
      let(:launch_urls) do
        [
          "https://abcdef.com/uuurrrlll01",
          "https://abcdef.com/uuurrrlll02",
          "https://abcdef.com/uuurrrlll03"
        ]
      end

      before do
        allow(BasicLTI::QuizzesNextVersionedSubmission).to receive(:new).and_return(quiz_lti_submission)
        allow(quiz_lti_submission).to receive(:submission).and_return(submission)
        3.times do |i|
          grade = "#{TextHelper.round_if_whole(grades[i] * 100)}%"
          grade, score = assignment.compute_grade_and_score(grade, nil)
          submission.grade = grade
          submission.score = score
          submission.submission_type = "basic_lti_launch"
          submission.workflow_state = "submitted"
          submission.submitted_at = Time.zone.now
          submission.url = launch_urls[i]
          submission.grader_id = -1
          submission.with_versioning(explicit: true) { submission.save! }
        end
        allow(submission).to receive(:grader_can_grade?).and_return(false)
      end

      context "when rolling back a submission version" do
        let(:text) { '{ "reopened": true }' }

        it "fails with validation error message" do
          request = BasicLTI::BasicOutcomes.process_request(tool, request_xml(source_id, launch_urls[1], grades[2]))
          expect(request.code_major).to eq "failure"
          expect(request.error_code).to eq :submission_revert_failed
          expect(request.description).to eq "Grade cannot be changed at this time: "
        end
      end

      it "fails with validation error message" do
        request = BasicLTI::BasicOutcomes.process_request(tool, xml)
        expect(request.code_major).to eq "failure"
        expect(request.error_code).to eq :submission_save_failed
        expect(request.description).to eq "Grade cannot be changed at this time: "
      end
    end

    context "result url" do
      it "reads the result_data_url when set" do
        BasicLTI::BasicOutcomes.process_request(tool, xml)
        submission = assignment.submissions.where(user_id: @user.id).first
        expect(submission.url).to eq launch_url
      end

      it "reads the result_data_launch_url when set" do
        xml.at_css("text").replace("<ltiLaunchUrl>http://example.com/launch</ltiLaunchUrl>")
        BasicLTI::BasicOutcomes.process_request(tool, xml)
        submission = assignment.submissions.where(user_id: @user.id).first
        expect(submission.url).to eq "http://example.com/launch"
      end
    end

    context "submissions" do
      it "creates a new submission if there isn't one" do
        expect { BasicLTI::BasicOutcomes.process_request(tool, xml) }
          .to change { assignment.submissions.not_placeholder.where(user_id: @user.id).count }.from(0).to(1)
        # it creates a unsubmitted version as well
        expect(assignment.submissions.not_placeholder.where(user_id: @user.id).first.versions.count).to be(2)
      end

      context "when the tool indicates further review is needed" do
        before do
          xml.at_css("imsx_POXBody > replaceResultRequest").add_child(
            "<submissionDetails><needsAdditionalReview/></submissionDetails>"
          )
        end

        it "sets the workflow state of the submission to 'pending_review'" do
          BasicLTI::BasicOutcomes.process_request(tool, xml)

          submission = assignment.submissions.where(user_id: @user.id).first
          expect(submission.workflow_state).to eq Submission.workflow_states.pending_review
        end
      end

      context "with previous versions" do
        let(:launch_urls) do
          [
            "https://abcdef.com/uuurrrlll01",
            "https://abcdef.com/uuurrrlll02",
            "https://abcdef.com/uuurrrlll03"
          ]
        end

        let(:grades) { [0.11, 0.22, 0.33] }

        before do
          BasicLTI::BasicOutcomes.process_request(tool, xml)
          submission = assignment.submissions.first
          3.times do |i|
            grade = "#{TextHelper.round_if_whole(grades[i] * 100)}%"
            grade, score = assignment.compute_grade_and_score(grade, nil)
            submission.grade = grade
            submission.score = score
            submission.submission_type = "basic_lti_launch"
            submission.workflow_state = "submitted"
            submission.submitted_at = Time.zone.now
            submission.url = launch_urls[i]
            submission.grader_id = -1
            submission.with_versioning(explicit: true) { submission.save! }
          end
        end

        it "doesn't add a version if last score and url of a submission are same" do
          expect do
            BasicLTI::BasicOutcomes.process_request(
              tool,
              request_xml(source_id, launch_urls[2], grades[2])
            )
          end
            .not_to change {
              assignment.submissions.not_placeholder.where(user_id: @user.id).first.versions.count
            }
        end

        it "doesn't add a version if last score of a submission is different, but urls are same" do
          expect do
            BasicLTI::BasicOutcomes.process_request(
              tool,
              request_xml(source_id, launch_urls[2], grades[1])
            )
          end
            .not_to change {
              assignment.submissions.not_placeholder.where(user_id: @user.id).first.versions.count
            }
        end

        it "adds a version if last url of a submission is different" do
          expect do
            BasicLTI::BasicOutcomes.process_request(
              tool,
              request_xml(source_id, launch_urls[1], grades[2])
            )
          end
            .to change {
              assignment.submissions.not_placeholder.where(user_id: @user.id).first.versions.count
            }.from(5).to(6)
        end
      end
    end

    context "when json is passed back in resultData/text" do
      let(:quiz_lti_submission) { BasicLTI::QuizzesNextVersionedSubmission.new(assignment, @user) }

      before do
        allow(BasicLTI::QuizzesNextVersionedSubmission).to receive(:new).and_return(quiz_lti_submission)
      end

      context "when submissionDetails passed includes submitted_at" do
        let(:timestamp) { 1.day.ago.iso8601(3) }

        it "reads 'submitted_at' from submissionDetails" do
          BasicLTI::BasicOutcomes.process_request(tool, xml)
          submission = assignment.submissions.where(user_id: @user.id).first
          expect(submission.submitted_at).to eq timestamp
        end

        it "doesn't revert submission history" do
          expect(quiz_lti_submission).not_to receive(:revert_history)
          BasicLTI::BasicOutcomes.process_request(tool, xml)
        end
      end

      context "when json passed includes graded_at" do
        let(:graded_at_time) { 5.hours.ago.iso8601(3) }
        let(:text) { "{ \"graded_at\" : \"#{graded_at_time}\" }" }

        before do
          submission = Submission.find_or_initialize_by(assignment:, user: @user)
          submission.grade = "0.67"
          submission.score = 0.67
          submission.graded_at = Time.zone.now
          submission.grade_matches_current_submission = true
          submission.grader_id = -1
          submission.url = launch_url
          submission.save!
        end

        it "reads 'graded_at' from resultData" do
          BasicLTI::BasicOutcomes.process_request(tool, xml)
          submission = assignment.submissions.where(user_id: @user.id).first
          expect(submission.graded_at).to eq graded_at_time
        end

        it "doesn't revert submission history" do
          expect(quiz_lti_submission).not_to receive(:revert_history)
          BasicLTI::BasicOutcomes.process_request(tool, xml)
        end
      end

      context "when json passed includes graded_at and reopened (true)" do
        let(:text) { "{ \"graded_at\" : \"#{1.day.ago.iso8601(3)}\", \"reopened\" : true }" }

        it "reads 'graded_at' from resultData" do
          expect(quiz_lti_submission).to receive(:revert_history).with(launch_url, -tool.id).and_call_original
          BasicLTI::BasicOutcomes.process_request(tool, xml)
        end
      end

      context "when json passed includes graded_at and reopened (false)" do
        let(:text) { "{ \"submitted_at\" : \"#{1.day.ago.iso8601(3)}\", \"reopened\" : false }" }

        it "reads 'graded_at' from submissionDetails" do
          expect(quiz_lti_submission).not_to receive(:revert_history)
          BasicLTI::BasicOutcomes.process_request(tool, xml)
        end
      end
    end
  end
end
