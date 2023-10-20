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

describe BasicLTI::QuizzesNextVersionedSubmission do
  subject { BasicLTI::QuizzesNextVersionedSubmission.new(assignment, @user) }

  before do
    course_model(workflow_state: "available")
    @root_account = @course.root_account
    @account = account_model(root_account: @root_account, parent_account: @root_account)
    @course.update_attribute(:account, @account)
    @user = factory_with_protected_attributes(User, name: "some user", workflow_state: "registered")
    @course.enroll_student(@user)
  end

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
        title: "value for title",
        description: "value for description",
        due_at: Time.zone.now + 1000,
        points_possible: "1.5",
        submission_types: "external_tool",
        external_tool_tag_attributes: { url: tool.url }
      }
    )
  end

  let(:source_id) { gen_source_id }

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
                  <ltiLaunchUrl>#{launch_url}</ltiLaunchUrl>
                </resultData>
              </result>
            </resultRecord>
          </replaceResultRequest>
        </imsx_POXBody>
      </imsx_POXEnvelopeRequest>
    XML
  end

  describe "#active?" do
    context "when submission is deleted" do
      before do
        subject.send(:submission).update_column :workflow_state, "deleted"
      end

      it "returns false" do
        expect(subject.active?).to be false
      end
    end

    context "when submission is active" do
      it "returns true" do
        expect(subject.active?).to be true
      end
    end
  end

  describe "#grade_history" do
    before do
      submission = assignment.submissions.first || Submission.find_or_initialize_by(assignment:, user: @user)
      url_grades.each do |h|
        grade = "#{TextHelper.round_if_whole(h[:grade] * 100)}%" if h[:grade]
        grade, score = assignment.compute_grade_and_score(grade, nil)
        submission.grade = grade
        submission.score = score
        submission.submission_type = "basic_lti_launch"
        submission.workflow_state = h[:workflow_state] || "submitted"
        submission.submitted_at = Time.zone.now
        submission.url = h[:url]
        submission.grader_id = -1
        submission.with_versioning(explicit: true) { submission.save! }
      end
    end

    context "without a submission" do
      let(:url_grades) { [] }

      it "outputs empty history" do
        expect(subject.grade_history).to be_empty
      end
    end

    context "with a version for each url" do
      let(:url_grades) do
        [
          { url: "https://abcdef.com/uuurrrlll00?p1=9&p2=11", grade: 0.11 },
          { url: "https://abcdef.com/uuurrrlll01?p1=10&p2=12", grade: 0.22 },
          { url: "https://abcdef.com/uuurrrlll02?p1=11&p2=13", grade: 0.33 },
          { url: "https://abcdef.com/uuurrrlll03?p1=12&p2=14", grade: 0.44 }
        ]
      end

      it "outputs all versions" do
        expect(
          subject.grade_history.map do |submission|
            [submission[:url], submission[:score], submission[:grade]]
          end
        ).to eq(
          url_grades.map do |x|
            [x[:url], assignment.points_possible * x[:grade], (assignment.points_possible * x[:grade]).to_s]
          end
        )
      end
    end

    context "with multiple versions for each url" do
      let(:urls) do
        %w[
          https://abcdef.com/uuurrrlll00?p1=9&p2=1
          https://abcdef.com/uuurrrlll01?p1=10&p2=2
          https://abcdef.com/uuurrrlll02?p1=11&p2=3
          https://abcdef.com/uuurrrlll03?p1=12&p2=4
        ]
      end

      let(:url_grades) do
        [
          # url 1 group
          { url: urls[1], grade: 0.99 },
          # url 0 group
          { url: urls[0], grade: 0.11 },
          { url: urls[0], grade: 0.12 },
          # url 1 group
          { url: urls[1], grade: 0.22 },
          { url: urls[1], grade: 0.23 },
          { url: urls[1], grade: 0.24 },
          # url 2 group
          { url: urls[2], grade: 0.33 },
          # url 3 group
          { url: urls[3], grade: 0.44 },
          { url: urls[3], grade: 0.45 },
          { url: urls[3], grade: 0.46 },
          { url: urls[3], grade: 0.47 },
          { url: urls[3], grade: 0.48 }
        ]
      end

      it "outputs only the latest version for each url(attempt)" do
        output_rows = [
          { url: urls[0], grade: 0.12 },
          { url: urls[1], grade: 0.24 },
          { url: urls[2], grade: 0.33 },
          { url: urls[3], grade: 0.48 }
        ]
        expect(
          subject.grade_history.map do |submission|
            [submission[:url], submission[:score], submission[:grade]]
          end
        ).to eq(
          output_rows.map do |x|
            [x[:url], assignment.points_possible * x[:grade], (assignment.points_possible * x[:grade]).to_s]
          end
        )
      end
    end

    context "when nil url is present" do
      context "when a submission has only a nil version" do
        let(:url_grades) do
          [
            { url: nil, grade: 0.33 }
          ]
        end

        it "outputs nothing" do
          expect(
            subject.grade_history.map do |submission|
              [submission[:url], submission[:score], submission[:grade]]
            end
          ).to eq([])
        end
      end

      context "when nils are mixed in history" do
        let(:url_grades) do
          [
            { url: "https://abcdef.com/uuurrrlll00?p1=9&p2=11", grade: 0.11 },
            { url: "https://abcdef.com/uuurrrlll01?p1=10&p2=12", grade: 0.22 },
            { url: nil, grade: 0.33 },
            { url: "https://abcdef.com/uuurrrlll03?p1=12&p2=14", grade: 0.44 },
            { url: nil, grade: 0.55 },
          ]
        end

        it "outputs only versions with an actual url" do
          expect(
            subject.grade_history.map do |submission|
              [submission[:url], submission[:score], submission[:grade]]
            end
          ).to eq(
            url_grades.filter_map do |x|
              next if x[:url].blank?

              [x[:url], assignment.points_possible * x[:grade], (assignment.points_possible * x[:grade]).to_s]
            end
          )
        end
      end

      context "when nil is present in an attempt history" do
        let(:url_grades) { [] }
        let(:submission_version_data) do
          time_now = Time.zone.now
          [
            { score: 50, url: "http://url1", submitted_at: time_now - 10.days },
            { score: 25, url: "http://url2", submitted_at: time_now - 8.days },
            { score: 55, url: "http://url1", submitted_at: time_now - 9.days },
            { score: nil, url: "http://url1", submitted_at: time_now - 3.days }
          ]
        end

        before do
          s = Submission.find_or_initialize_by(assignment:, user: @user)

          submission_version_data.each do |d|
            s.score = d[:score]
            s.submitted_at = d[:submitted_at]
            s.grader_id = -1
            s.url = d[:url]
            s.with_versioning(explicit: true) { s.save! }
          end
          s
        end

        it "outputs only attempts without being masked by a (score) nil version" do
          expect(subject.grade_history.count).to be(1)
          expect(subject.grade_history.first[:url]).to eq("http://url2")
          expect(subject.grade_history.first[:score]).to eq(25)
        end
      end
    end

    context "when nil score is present" do
      context "when all scores are nil" do
        let(:url_grades) do
          [
            { url: "https://abcdef.com/uuurrrlll00?p1=9&p2=11", grade: nil },
            { url: "https://abcdef.com/uuurrrlll01?p1=10&p2=12", grade: nil },
          ]
        end

        it "returns an empty history" do
          expect(subject.grade_history).to be_empty
        end
      end

      context "when score is nil but also graded" do
        let(:url_grades) do
          [
            { url: "https://abcdef.com/uuurrrlll00?p1=9&p2=11", grade: 0.88 },
            { url: "https://abcdef.com/uuurrrlll01?p1=10&p2=12", grade: nil },
            { url: "https://abcdef.com/uuurrrlll01?p1=10&p2=12", grade: nil, workflow_state: "graded" },
          ]
        end

        it "returns mix of scores and scores with nil that have been graded" do
          grade_history_response = subject.grade_history.map do |submission|
            [submission[:url], submission[:score], submission[:grade]]
          end

          expect(grade_history_response.length).to be 2
          expect(grade_history_response).to eq(
            url_grades.filter_map do |x|
              next if x[:grade].blank? && x[:workflow_state] != "graded"

              score = x[:grade] ? assignment.points_possible * x[:grade] : nil
              grade = score ? score.to_s : nil

              [x[:url], score, grade]
            end
          )
        end
      end
    end
  end

  describe "#commit_history" do
    subject { BasicLTI::QuizzesNextVersionedSubmission.new(assignment, @user) }

    before do
      allow(Submission).to receive(:find_or_initialize_by).and_return(submission)
    end

    let(:submission) do
      assignment.submissions.first || Submission.find_or_initialize_by(assignment:, user: @user)
    end

    let!(:notification) do
      Notification.create!(
        name: "Assignment Submitted",
        subject: "No Subject",
        category: "TestImmediately"
      )
    end

    let!(:resubmission_notification) do
      Notification.create!(
        name: "Assignment Resubmitted",
        subject: "No Subject",
        category: "TestImmediately"
      )
    end

    it "sends an 'Assignment Submitted' notification for the first attempt that is submitted" do
      expect(submission).to receive(:without_versioning).once.and_call_original
      expect(submission).to receive(:with_versioning).with(false).once.and_call_original

      # :with_versioning calls:
      # 1 - initialize_version
      # 2 - save_submission!
      expect(submission).to receive(:with_versioning).with({ explicit: true }).twice.and_call_original

      expect(BroadcastPolicy.notifier).to receive(:send_notification).with(
        submission,
        "Assignment Submitted",
        notification,
        any_args
      ).once

      subject.commit_history("http://url", "77", -1)
      expect(submission.versions.count).to eq 2
    end

    it "does not send an 'Assignment Submitted' notification after the first attempt submitted" do
      subject.commit_history("http://url", "77", -1)
      expect(submission.versions.count).to eq 2

      expect(BroadcastPolicy.notifier).not_to receive(:send_notification).with(
        submission,
        "Assignment Submitted",
        notification,
        any_args
      )

      subject.commit_history("http://url2", "90", -1)
      expect(submission.versions.count).to eq 3

      subject.commit_history("http://url3", "95", -1)
      expect(submission.versions.count).to eq 4
    end

    it "sends an 'Assignment Resubmitted' notification after the second attempt submitted" do
      subject.commit_history("http://url", "77", -1)
      expect(submission.versions.count).to eq 2

      expect(BroadcastPolicy.notifier).to receive(:send_notification).with(
        submission,
        "Assignment Resubmitted",
        resubmission_notification,
        any_args
      ).twice

      subject.commit_history("http://url2", "90", -1)
      expect(submission.versions.count).to eq 3

      subject.commit_history("http://url3", "100", -1)
      expect(submission.versions.count).to eq 4
    end

    it "does not send an 'Assignment Submitted' notification when an existing attempt is regraded" do
      subject.commit_history("http://url", "77", -1)
      expect(submission.versions.count).to eq 2

      expect(BroadcastPolicy.notifier).not_to receive(:send_notification).with(
        submission,
        "Assignment Submitted",
        notification,
        any_args
      )
      subject.commit_history("http://url", "100", -1)
      expect(submission.versions.count).to eq 2

      subject.commit_history("http://url", "80", -1)
      expect(submission.versions.count).to eq 2
    end

    it "does not send an 'Assignment Resubmitted' notification when an existing attempt is regraded" do
      subject.commit_history("http://url", "77", -1)
      expect(submission.versions.count).to eq 2

      expect(BroadcastPolicy.notifier).not_to receive(:send_notification).with(
        submission,
        resubmission_notification.name,
        resubmission_notification,
        any_args
      )
      subject.commit_history("http://url", "80", -1)
      expect(submission.versions.count).to eq 2

      subject.commit_history("http://url", "90", -1)
      expect(submission.versions.count).to eq 2

      subject.commit_history("http://url", "100", -1)
      expect(submission.versions.count).to eq 2
    end

    it "sends a 'Submission Graded' notification when a submission is regraded" do
      graded_notification = Notification.create!(
        name: "Submission Graded",
        subject: "No Subject",
        category: "TestImmediately"
      )
      subject.commit_history("http://url", "77", -1)

      expect(BroadcastPolicy.notifier).to receive(:send_notification).with(
        submission,
        "Submission Graded",
        graded_notification,
        any_args
      ).exactly(2).times

      subject.commit_history("http://url", "100", -1)
      subject.commit_history("http://url", "80", -1)
    end

    context "when needs_additional_review is true" do
      subject do
        BasicLTI::QuizzesNextVersionedSubmission.new(assignment, @user, needs_additional_review: true)
      end

      it "sets the submission's workflow_state to 'pending_review'" do
        assignment.grade_student(@user, grader: @teacher, score: 1337)
        subject.commit_history("http://url", "80", -1)
        expect(submission.reload.workflow_state).to eq(Submission.workflow_states.pending_review)
      end

      context "and then manual grading is completed" do
        subject do
          super().commit_history("http://url", "80", -1)
          BasicLTI::QuizzesNextVersionedSubmission.new(
            assignment,
            @user
          ).commit_history("http://url", grade, -1)

          assignment.submission_for_student(@user)
        end

        let(:grade) { raise "set in contexts" }

        shared_examples_for "contexts that grade a submission" do
          it "sets workflow_state to graded" do
            expect(subject.workflow_state).to eq Submission.workflow_states.graded
          end

          it "gives the correct score to the submission" do
            expect(subject.score).to eq grade.to_f
          end

          it "gives the correct grade to the submission" do
            expect(subject.grade).to eq grade
          end
        end

        context "with an unchanged score" do
          let(:grade) { "80" }

          it_behaves_like "contexts that grade a submission"
        end

        context "with a changed score" do
          let(:grade) { "90" }

          it_behaves_like "contexts that grade a submission"
        end
      end
    end

    context "with prioritizeNonToolGrade details" do
      let(:quiz_next_versioned_submission) { BasicLTI::QuizzesNextVersionedSubmission.new(assignment, @user, prioritize_non_tool_grade: true) }

      it "doesn't update the grade if a non-tool graded first" do
        assignment.grade_student(@user, grader: @teacher, score: 1337)
        submission.reload

        quiz_next_versioned_submission.commit_history("http://url", "80", -1)
        expect(submission.reload.score).to eq(1337)
      end

      it "doesn't update the grader if a non-tool graded first" do
        assignment.grade_student(@user, grader: @teacher, score: 1337)
        submission.reload

        quiz_next_versioned_submission.commit_history("http://url", "80", -1)
        expect(submission.grader_id).to eq(@teacher.id)
      end

      it "does update the score if a tool graded first" do
        submission.update!(workflow_state: "graded", grader_id: -1, score: 80)

        quiz_next_versioned_submission.commit_history("http://url", "10", -1)
        expect(submission.score).to eq(10)
      end

      it "does update the grader if a another tool graded first" do
        submission.update!(workflow_state: "graded", grader_id: -2, score: 80)

        quiz_next_versioned_submission.commit_history("http://url", "10", -1)
        expect(submission.grader_id).to eq(-1)
      end
    end

    context "when grading period is closed" do
      before do
        gpg = GradingPeriodGroup.create(
          course_id: @course.id,
          workflow_state: "active",
          title: "some school",
          weighted: true,
          display_totals_for_all_grading_periods: true
        )
        gp = GradingPeriod.create(
          weight: 40.0,
          start_date: 10.days.ago,
          end_date: 1.day.ago,
          title: "some title",
          workflow_state: "active",
          grading_period_group_id: gpg.id,
          close_date: 1.day.ago
        )

        submission.grading_period_id = gp.id
        submission.without_versioning(&:save!)
      end

      it "returns without processing" do
        expect(subject).not_to receive(:valid?)

        subject.commit_history("url", "77", -1)
      end
    end

    describe "submission posting" do
      it "posts the submission when the assignment is automatically posted" do
        subject.commit_history("url", "77", -1)
        expect(submission.reload).to be_posted
      end

      it "does not post the submission when the assignment is manually posted" do
        assignment.ensure_post_policy(post_manually: true)

        subject.commit_history("url", "77", -1)
        expect(submission.reload).not_to be_posted
      end

      it "does not update the submission's posted_at date when it is already posted" do
        submission.update!(posted_at: 1.day.ago)
        expect do
          subject.commit_history("url", "77", -1)
        end.not_to change { submission.reload.posted_at }
      end
    end
  end
end
