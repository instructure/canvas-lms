#
# Copyright (C) 2013 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')

class GradeChangeEventTestHarness
  include Api::V1::GradeChangeEvent

  def url_root
    'http://www.example.com'
  end

  def feeds_calendar_url(feed_code)
    "feed_calendar_url(#{feed_code.inspect})"
  end

  def course_assignment_url(course, assignment)
    url_root
  end

  def api_v1_course_url(course)
    URI.encode("#{url_root}/api/v1/courses/#{course}")
  end

  def api_v1_course_assignment_url(course, assignment)
    URI.encode("#{url_root}/api/v1/courses/#{course}/assignments/#{assignment}")
  end

  def service_enabled?(type)
    false
  end

  def course_assignment_submissions_url(course, assignment, _)
    URI.encode("#{url_root}/api/v1/courses/#{course}/assignments/#{assignment}/submissions?zip=0")
  end
end

describe Api::V1::GradeChangeEvent do
  subject { GradeChangeEventTestHarness.new }

  before do
    skip("needs auditors cassandra keyspace configured") unless Auditors::GradeChange::Stream.available?

    @request_id = SecureRandom.uuid
    RequestContextGenerator.stubs( :request_id => @request_id )

    @domain_root_account = Account.default

    course_with_teacher(account: @domain_root_account)
    course_with_student(course: @course)

    @page_view = PageView.new { |p|
      p.assign_attributes({
        :request_id => @request_id,
        :remote_ip => '10.10.10.10'
      }, :without_protection => true)
    }

    PageView.stubs(
      :find_by_id => @page_view,
      :find_all_by_id => [ @page_view ]
    )

    @events = []

    @assignment = @course.assignments.create!(:title => 'Assignment', :points_possible => 10)
    @submission = @assignment.grade_student(@student, grade: 8, grader: @teacher).first
    @events << Auditors::GradeChange.record(@submission)

    @submission = @assignment.grade_student(@student, grade: 7, grader: @teacher).first
    @events << Auditors::GradeChange.record(@submission)
    @previous_grade = @submission.grade

    @submission = @assignment.grade_student(@student, grade: 6, grader: @teacher, graded_anonymously: true).first
    @event = Auditors::GradeChange.record(@submission)
    @events << @event
  end

  it "should be formatted as a grade change event hash" do
    event = subject.grade_change_event_json(@event, @student, @session)

    expect(event[:id]).to eq @event.id
    expect(event[:created_at]).to eq @event.created_at.in_time_zone
    expect(event[:event_type]).to eq @event.event_type
    expect(event[:grade_before]).to eq @previous_grade
    expect(event[:grade_after]).to eq @submission.grade
    expect(event[:excused_before]).to eq false
    expect(event[:excused_after]).to eq false
    expect(event[:version_number]).to eq @submission.version_number
    expect(event[:graded_anonymously]).to eq @submission.graded_anonymously
    expect(event[:links][:assignment]).to eq Shard.relative_id_for(@assignment, Shard.current, Shard.current)
    expect(event[:links][:course]).to eq Shard.relative_id_for(@course, Shard.current, Shard.current)
    expect(event[:links][:student]).to eq Shard.relative_id_for(@student, Shard.current, Shard.current)
    expect(event[:links][:grader]).to eq Shard.relative_id_for(@teacher, Shard.current, Shard.current)
    expect(event[:links][:page_view]).to eq @page_view.id
  end

  it "formats excused submissions" do
    @excused = @assignment.grade_student(@student, grader: @teacher, excused: true).first
    @event = Auditors::GradeChange.record(@excused)

    event = subject.grade_change_event_json(@event, @student, @session)
    expect(event[:grade_before]).to eq @submission.grade
    expect(event[:grade_after]).to eq nil
    expect(event[:excused_before]).to eq false
    expect(event[:excused_after]).to eq true
  end

  it "formats formerly excused submissions" do
    @excused = @assignment.grade_student(@student, grader: @teacher, excused: true).first
    Auditors::GradeChange.record(@excused)
    @unexcused = @assignment.grade_student(@student, grader: @teacher, excused: false).first
    @event = Auditors::GradeChange.record(@unexcused)

    event = subject.grade_change_event_json(@event, @student, @session)
    expect(event[:grade_before]).to eq nil
    expect(event[:grade_after]).to eq nil
    expect(event[:excused_before]).to eq true
    expect(event[:excused_after]).to eq false
  end

  it "should be formatted as an array of grade change event hashes" do
    expect(subject.grade_change_events_json(@events, @student, @session).size).to eql(@events.size)
  end

  it "should be formatted as an array of compound grade change event hashes" do
    json_hash = subject.grade_change_events_compound_json(@events, @user, @session)

    expect(json_hash.keys.sort).to eq [:events, :linked, :links]

    expect(json_hash[:links]).to eq({
      "events.assignment" => "#{subject.url_root}/api/v1/courses/{events.course}/assignments/{events.assignment}",
      "events.course" => "#{subject.url_root}/api/v1/courses/{events.course}",
      "events.student" => { href: nil, type: 'user' },
      "events.grader" => { href: nil, type: 'user' },
      "events.page_view" => nil
    })

    expect(json_hash[:events]).to eq subject.grade_change_events_json(@events, @user, @session)

    expect(json_hash[:linked].keys.sort).to eq [:assignments, :courses, :page_views, :users]
    linked = json_hash[:linked]
    expect(linked[:assignments].size).to eql(1)
    expect(linked[:courses].size).to eql(1)
    expect(linked[:users].size).to eql(2)
    expect(linked[:page_views].size).to eql(1)
  end

  it "should handle an empty result set" do
    json_hash = subject.grade_change_events_compound_json([], @user, @session)

    expect(json_hash.keys.sort).to eq [:events, :linked, :links]

    expect(json_hash[:events]).to eq subject.grade_change_events_json([], @user, @session)

    expect(json_hash[:linked].keys.sort).to eq [:assignments, :courses, :page_views, :users]
    linked = json_hash[:linked]
    expect(linked[:assignments].size).to be_zero
    expect(linked[:courses].size).to be_zero
    expect(linked[:users].size).to be_zero
    expect(linked[:page_views].size).to be_zero
  end
end
