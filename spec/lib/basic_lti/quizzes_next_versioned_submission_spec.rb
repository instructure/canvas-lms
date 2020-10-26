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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe BasicLTI::QuizzesNextVersionedSubmission do
  before(:each) do
    course_model(workflow_state: 'available')
    @root_account = @course.root_account
    @account = account_model(:root_account => @root_account, :parent_account => @root_account)
    @course.update_attribute(:account, @account)
    @user = factory_with_protected_attributes(User, :name => "some user", :workflow_state => "registered")
    @course.enroll_student(@user)
  end

  subject { BasicLTI::QuizzesNextVersionedSubmission.new(assignment, @user) }

  let(:tool) do
    @course.context_external_tools.create(name: "a", url: "http://google.com", consumer_key: '12345', shared_secret: 'secret', tool_id: "Quizzes 2")
  end

  let(:assignment) do
    @course.assignments.create!(
      {
        title: "value for title",
        description: "value for description",
        due_at: Time.zone.now + 1000,
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

  def request_xml(source_id, launch_url, grade)
    Nokogiri::XML.parse %{
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
    }
  end

  describe "#grade_history" do
    before do
      submission = assignment.submissions.first || Submission.find_or_initialize_by(assignment: assignment, user: @user)
      url_grades.each do |h|
        grade = "#{TextHelper.round_if_whole(h[:grade] * 100)}%"
        grade, score = assignment.compute_grade_and_score(grade, nil)
        submission.grade = grade
        submission.score = score
        submission.submission_type = 'basic_lti_launch'
        submission.workflow_state = 'submitted'
        submission.submitted_at = Time.zone.now
        submission.url = h[:url]
        submission.grader_id = -1
        submission.with_versioning(:explicit => true) { submission.save! }
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
          { url: 'https://abcdef.com/uuurrrlll00?p1=9&p2=11', grade: 0.11 },
          { url: 'https://abcdef.com/uuurrrlll01?p1=10&p2=12', grade: 0.22 },
          { url: 'https://abcdef.com/uuurrrlll02?p1=11&p2=13', grade: 0.33 },
          { url: 'https://abcdef.com/uuurrrlll03?p1=12&p2=14', grade: 0.44 }
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
        %w(
          https://abcdef.com/uuurrrlll00?p1=9&p2=1
          https://abcdef.com/uuurrrlll01?p1=10&p2=2
          https://abcdef.com/uuurrrlll02?p1=11&p2=3
          https://abcdef.com/uuurrrlll03?p1=12&p2=4
        )
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

      it "outputs only the lastest version for each url(attempt)" do
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
            { url: 'https://abcdef.com/uuurrrlll00?p1=9&p2=11', grade: 0.11 },
            { url: 'https://abcdef.com/uuurrrlll01?p1=10&p2=12', grade: 0.22 },
            { url: nil, grade: 0.33 },
            { url: 'https://abcdef.com/uuurrrlll03?p1=12&p2=14', grade: 0.44 },
            { url: nil, grade: 0.55 },
          ]
        end

        it "outputs only versions with an actual url" do
          expect(
            subject.grade_history.map do |submission|
              [submission[:url], submission[:score], submission[:grade]]
            end
          ).to eq(
            url_grades.map do |x|
              next if x[:url].blank?
              [x[:url], assignment.points_possible * x[:grade], (assignment.points_possible * x[:grade]).to_s]
            end.compact
          )
        end
      end

      context "when nil is present in an attempt history" do
        let(:url_grades) { [] }
        let(:submission_version_data) do
          time_now = Time.zone.now
          [
            { score: 50, url: 'http://url1', submitted_at: time_now - 10.days },
            { score: 25, url: 'http://url2', submitted_at: time_now - 8.days },
            { score: 55, url: 'http://url1', submitted_at: time_now - 9.days },
            { score: nil, url: 'http://url1', submitted_at: time_now - 3.days }
          ]
        end

        before do
          s = Submission.find_or_initialize_by(assignment: assignment, user: @user)

          submission_version_data.each do |d|
            s.score = d[:score]
            s.submitted_at = d[:submitted_at]
            s.grader_id = -1
            s.url = d[:url]
            s.with_versioning(:explicit => true) { s.save! }
          end
          s
        end

        it "outputs only attempts without being masked by a (score) nil version" do
          expect(subject.grade_history.count).to be(1)
          expect(subject.grade_history.first[:url]).to eq('http://url2')
          expect(subject.grade_history.first[:score]).to eq(25)
        end
      end
    end
  end

  describe "#commit_history" do
    before do
      allow(Submission).to receive(:find_or_initialize_by).and_return(submission)
    end

    subject { BasicLTI::QuizzesNextVersionedSubmission.new(assignment, @user) }

    let(:submission) do
      assignment.submissions.first || Submission.find_or_initialize_by(assignment: assignment, user: @user)
    end

    let!(:notification) do
      Notification.create!(
        name: "Assignment Submitted",
        workflow_state: "active",
        subject: "No Subject",
        category: "TestImmediately"
      )
    end

    it "sends notification to users" do
      expect(submission).to receive(:without_versioning).and_call_original
      # expect 4 :save! calls:
      # 1 - save an initial unsubmitted version; 2 - create a new data version;
      # 3 - update status to submitted; 4 - update actual data (score, url, ...)
      expect(submission).to receive(:save!).exactly(4).times.and_call_original
      expect(BroadcastPolicy.notifier).to receive(:send_notification).with(
        submission,
        "Assignment Submitted",
        notification,
        any_args
      )

      subject.commit_history('http://url', '77', -1)
    end

    it "sends an 'Assignment Submitted' notification for each new attempt that is submitted" do
      expect(BroadcastPolicy.notifier).to receive(:send_notification).with(
        submission,
        "Assignment Submitted",
        notification,
        any_args
      ).exactly(3).times

      subject.commit_history('http://url', '77', -1)
      subject.commit_history('http://url2', '100', -1)
      subject.commit_history('http://url3', '90', -1)
    end

    it "does not send an 'Assignment Submitted' notification when an existing attempt is regraded" do
      expect(BroadcastPolicy.notifier).to receive(:send_notification).with(
        submission,
        "Assignment Submitted",
        notification,
        any_args
      ).exactly(1).time

      subject.commit_history('http://url', '77', -1)
      subject.commit_history('http://url', '100', -1)
      subject.commit_history('http://url', '80', -1)
    end

    it "sends a 'Submission Graded' notification when a submission is regraded" do
      graded_notification = Notification.create!(
        name: "Submission Graded",
        workflow_state: "active",
        subject: "No Subject",
        category: "TestImmediately"
      )
      subject.commit_history('http://url', '77', -1)

      expect(BroadcastPolicy.notifier).to receive(:send_notification).with(
        submission,
        "Submission Graded",
        graded_notification,
        any_args
      ).exactly(2).times

      subject.commit_history('http://url', '100', -1)
      subject.commit_history('http://url', '80', -1)
    end

    context 'when grading period is closed' do
      before do
        gpg = GradingPeriodGroup.create(
          course_id: @course.id,
          workflow_state: 'active',
          title: 'some school',
          weighted: true,
          display_totals_for_all_grading_periods: true
        )
        gp = GradingPeriod.create(
          weight: 40.0,
          start_date: Time.zone.now - 10.days,
          end_date: Time.zone.now - 1.day,
          title: 'some title',
          workflow_state: 'active',
          grading_period_group_id: gpg.id,
          close_date: Time.zone.now - 1.day
        )

        submission.grading_period_id = gp.id
        submission.without_versioning(&:save!)
      end

      it "returns without processing" do
        expect(subject).not_to receive(:valid?)

        subject.commit_history('url', '77', -1)
      end
    end

    describe "submission posting" do
      it "posts the submission when the assignment is automatically posted" do
        subject.commit_history('url', '77', -1)
        expect(submission.reload).to be_posted
      end

      it "does not post the submission when the assignment is manually posted" do
        assignment.ensure_post_policy(post_manually: true)

        subject.commit_history('url', '77', -1)
        expect(submission.reload).not_to be_posted
      end

      it "does not update the submission's posted_at date when it is already posted" do
        submission.update!(posted_at: 1.day.ago)
        expect {
          subject.commit_history('url', '77', -1)
        }.not_to change { submission.reload.posted_at }
      end
    end
  end
end
