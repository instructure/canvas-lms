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

class GradeChangeEventTestHarness
  include Api::V1::GradeChangeEvent

  def url_root
    "http://www.example.com"
  end

  def feeds_calendar_url(feed_code)
    "feed_calendar_url(#{feed_code.inspect})"
  end

  def course_assignment_url(_course, _assignment)
    url_root
  end

  def api_v1_course_url(course)
    URI::DEFAULT_PARSER.escape("#{url_root}/api/v1/courses/#{course}")
  end

  def api_v1_course_assignment_url(course, assignment)
    URI::DEFAULT_PARSER.escape("#{url_root}/api/v1/courses/#{course}/assignments/#{assignment}")
  end

  def service_enabled?(_type)
    false
  end

  def course_assignment_submissions_url(course, assignment, _)
    URI::DEFAULT_PARSER.escape("#{url_root}/api/v1/courses/#{course}/assignments/#{assignment}/submissions?zip=0")
  end
end

describe Api::V1::GradeChangeEvent do
  subject { GradeChangeEventTestHarness.new }

  before do
    @request_id = SecureRandom.uuid
    allow(RequestContextGenerator).to receive_messages(request_id: @request_id)

    @domain_root_account = Account.default

    course_with_teacher(account: @domain_root_account)
    course_with_student(course: @course)

    @page_view = PageView.new do |p|
      p.assign_attributes({
                            request_id: @request_id,
                            remote_ip: "10.10.10.10"
                          })
    end

    allow(PageView).to receive_messages(
      find_by: @page_view,
      find_all_by_id: [@page_view]
    )

    @events = []

    @assignment = @course.assignments.create!(title: "Assignment", points_possible: 10)
    @submission = @assignment.grade_student(@student, grade: 8, grader: @teacher).first
    @events << Auditors::GradeChange.record(submission: @submission)

    @submission = @assignment.grade_student(@student, grade: 7, grader: @teacher).first
    @events << Auditors::GradeChange.record(submission: @submission)
    @previous_grade = @submission.grade

    @submission = @assignment.grade_student(@student, grade: 6, grader: @teacher, graded_anonymously: true).first
    @event = Auditors::GradeChange.record(submission: @submission)
    @events << @event
  end

  it "is formatted as a grade change event hash" do
    event = subject.grade_change_event_json(@event, @student, @session)

    expect(event[:id]).to eq @event.id
    expect(event[:created_at]).to eq @event.created_at.in_time_zone
    expect(event[:event_type]).to eq @event.event_type
    expect(event[:grade_before]).to eq @previous_grade
    expect(event[:grade_after]).to eq @submission.grade
    expect(event[:excused_before]).to be false
    expect(event[:excused_after]).to be false
    expect(event[:version_number]).to eq @submission.version_number
    expect(event[:graded_anonymously]).to eq @submission.graded_anonymously
    expect(event[:points_possible_before]).to eq @event.points_possible_before
    expect(event[:points_possible_after]).to eq @event.points_possible_after
    expect(event[:links][:assignment]).to eq Shard.relative_id_for(@assignment, Shard.current, Shard.current)
    expect(event[:links][:course]).to eq Shard.relative_id_for(@course, Shard.current, Shard.current)
    expect(event[:links][:student]).to eq Shard.relative_id_for(@student, Shard.current, Shard.current).to_s
    expect(event[:links][:grader]).to eq Shard.relative_id_for(@teacher, Shard.current, Shard.current).to_s
    expect(event[:links][:page_view]).to eq @page_view.id
  end

  it "does not include a value for 'course_override_grade'" do
    event = subject.grade_change_event_json(@event, @student, @session)
    expect(event).not_to have_key(:course_override_grade)
  end

  it "formats excused submissions" do
    @excused = @assignment.grade_student(@student, grader: @teacher, excused: true).first
    @event = Auditors::GradeChange.record(submission: @excused)

    event = subject.grade_change_event_json(@event, @student, @session)
    expect(event[:grade_before]).to eq @submission.grade
    expect(event[:grade_after]).to be_nil
    expect(event[:excused_before]).to be false
    expect(event[:excused_after]).to be true
  end

  it "formats formerly excused submissions" do
    @excused = @assignment.grade_student(@student, grader: @teacher, excused: true).first
    Auditors::GradeChange.record(submission: @excused)
    @unexcused = @assignment.grade_student(@student, grader: @teacher, excused: false).first
    @event = Auditors::GradeChange.record(submission: @unexcused)

    event = subject.grade_change_event_json(@event, @student, @session)
    expect(event[:grade_before]).to be_nil
    expect(event[:grade_after]).to be_nil
    expect(event[:excused_before]).to be true
    expect(event[:excused_after]).to be false
  end

  it "is formatted as an array of grade change event hashes" do
    expect(subject.grade_change_events_json(@events, @student, @session).size).to eql(@events.size)
  end

  it "is formatted as an array of compound grade change event hashes" do
    json_hash = subject.grade_change_events_compound_json(@events, @user, @session)

    expect(json_hash.keys.sort).to eq %i[events linked links]

    expect(json_hash[:links]).to eq({
                                      "events.assignment" => "#{subject.url_root}/api/v1/courses/{events.course}/assignments/{events.assignment}",
                                      "events.course" => "#{subject.url_root}/api/v1/courses/{events.course}",
                                      "events.student" => { href: nil, type: "user" },
                                      "events.grader" => { href: nil, type: "user" },
                                      "events.page_view" => nil
                                    })

    expect(json_hash[:events]).to eq subject.grade_change_events_json(@events, @user, @session)

    expect(json_hash[:linked].keys.sort).to eq %i[assignments courses page_views users]
    linked = json_hash[:linked]
    expect(linked[:assignments].size).to be(1)
    expect(linked[:courses].size).to be(1)
    expect(linked[:users].size).to be(2)
    expect(linked[:page_views].size).to be(1)
  end

  it "handles an empty result set" do
    json_hash = subject.grade_change_events_compound_json([], @user, @session)

    expect(json_hash.keys.sort).to eq %i[events linked links]

    expect(json_hash[:events]).to eq subject.grade_change_events_json([], @user, @session)

    expect(json_hash[:linked].keys.sort).to eq %i[assignments courses page_views users]
    linked = json_hash[:linked]
    expect(linked[:assignments].size).to be_zero
    expect(linked[:courses].size).to be_zero
    expect(linked[:users].size).to be_zero
    expect(linked[:page_views].size).to be_zero
  end

  describe "override grade change events" do
    let(:override_event) do
      override_grade_change = Auditors::GradeChange::OverrideGradeChange.new(
        grader: @teacher,
        old_grade: nil,
        old_score: nil,
        score: @course.student_enrollments.first.find_score
      )
      Auditors::GradeChange.record(override_grade_change:)
    end

    let(:override_event_json) do
      subject.grade_change_events_compound_json([override_event], @teacher, @session)
    end

    it "does not link to an assignment" do
      expect(override_event_json.dig(:events, 0, :links)).not_to have_key(:assignment)
    end

    it "includes true as the value of 'course_override_grade'" do
      expect(override_event_json.dig(:events, 0, :course_override_grade)).to be true
    end

    describe "grade fields" do
      let(:score) { @course.student_enrollments.first.find_score }

      describe "grade_before" do
        it "is returned as nil if grade_before and score_before are nil" do
          override_grade_change = Auditors::GradeChange::OverrideGradeChange.new(
            grader: @teacher,
            old_grade: nil,
            old_score: nil,
            score:
          )
          event = Auditors::GradeChange.record(override_grade_change:)
          event_json = subject.grade_change_event_json(event, @user, @session)
          expect(event_json[:grade_before]).to be_nil
        end

        it "is returned as the grade value if grade_before is present" do
          override_grade_change = Auditors::GradeChange::OverrideGradeChange.new(
            grader: @teacher,
            old_grade: "A-",
            old_score: 90,
            score:
          )
          event = Auditors::GradeChange.record(override_grade_change:)
          event_json = subject.grade_change_event_json(event, @user, @session)
          expect(event_json[:grade_before]).to eq "A-"
        end

        it "is returned as the score value if score_before is present but not grade_before" do
          override_grade_change = Auditors::GradeChange::OverrideGradeChange.new(
            grader: @teacher,
            old_grade: nil,
            old_score: 90,
            score:
          )
          event = Auditors::GradeChange.record(override_grade_change:)
          event_json = subject.grade_change_event_json(event, @user, @session)
          expect(event_json[:grade_before]).to eq "90%"
        end
      end

      describe "grade_after" do
        it "is returned as nil if grade_before and score_before are nil" do
          score.update!(override_score: nil)
          override_grade_change = Auditors::GradeChange::OverrideGradeChange.new(
            grader: @teacher,
            old_grade: nil,
            old_score: nil,
            score:
          )
          event = Auditors::GradeChange.record(override_grade_change:)
          event_json = subject.grade_change_event_json(event, @user, @session)
          expect(event_json[:grade_after]).to be_nil
        end

        it "is returned as the grade value if grade_after is present" do
          score.course.grading_standard_enabled = true
          score.update!(override_score: 80)
          override_grade_change = Auditors::GradeChange::OverrideGradeChange.new(
            grader: @teacher,
            old_grade: nil,
            old_score: nil,
            score:
          )
          event = Auditors::GradeChange.record(override_grade_change:)
          event_json = subject.grade_change_event_json(event, @user, @session)
          expect(event_json[:grade_after]).to eq "B-"
        end

        it "is returned as the score value if score_after is present but not grade_after" do
          score.update!(override_score: 80)
          override_grade_change = Auditors::GradeChange::OverrideGradeChange.new(
            grader: @teacher,
            old_grade: nil,
            old_score: nil,
            score:
          )
          event = Auditors::GradeChange.record(override_grade_change:)
          event_json = subject.grade_change_event_json(event, @user, @session)
          expect(event_json[:grade_after]).to eq "80%"
        end
      end
    end
  end
end
