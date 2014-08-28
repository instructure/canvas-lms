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

describe Api::V1::GradeChangeEvent do
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

  before do
    pending("needs auditors cassandra keyspace configured") unless Auditors::GradeChange::Stream.available?

    @request_id = CanvasUUID.generate
    RequestContextGenerator.stubs( :request_id => @request_id )

    @domain_root_account = Account.default

    course_with_teacher(account: @domain_root_account)
    course_with_student_logged_in(course: @course)

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

    @submission = @assignment.grade_student(@student, grade: 6, grader: @teacher).first
    @event = Auditors::GradeChange.record(@submission)
    @events << @event
  end

  it "should be formatted as a grade change event hash" do
    event = grade_change_event_json(@event, @student, @session)

    event[:id].should == @event.id
    event[:created_at].should == @event.created_at.in_time_zone
    event[:event_type].should == @event.event_type
    event[:grade_before].should == @previous_grade
    event[:grade_after].should == @submission.grade
    event[:version_number].should == @submission.version_number
    event[:links][:assignment].should == Shard.relative_id_for(@assignment, Shard.current, Shard.current)
    event[:links][:course].should == Shard.relative_id_for(@course, Shard.current, Shard.current)
    event[:links][:student].should == Shard.relative_id_for(@student, Shard.current, Shard.current)
    event[:links][:grader].should == Shard.relative_id_for(@teacher, Shard.current, Shard.current)
    event[:links][:page_view].should == @page_view.id
  end

  it "should be formatted as an array of grade change event hashes" do
    grade_change_events_json(@events, @student, @session).size.should eql(@events.size)
  end

  it "should be formatted as an array of compound grade change event hashes" do
    json_hash = grade_change_events_compound_json(@events, @user, @session)

    json_hash.keys.sort.should == [:events, :linked, :links]

    json_hash[:links].should == {
      "events.assignment" => "#{url_root}/api/v1/courses/{events.course}/assignments/{events.assignment}",
      "events.course" => "#{url_root}/api/v1/courses/{events.course}",
      "events.student" => { href: nil, type: 'user' },
      "events.grader" => { href: nil, type: 'user' },
      "events.page_view" => nil
    }

    json_hash[:events].should == grade_change_events_json(@events, @user, @session)

    json_hash[:linked].keys.sort.should == [:assignments, :courses, :page_views, :users]
    linked = json_hash[:linked]
    linked[:assignments].size.should eql(1)
    linked[:courses].size.should eql(1)
    linked[:users].size.should eql(2)
    linked[:page_views].size.should eql(1)
  end

  it "should handle an empty result set" do
    json_hash = grade_change_events_compound_json([], @user, @session)

    json_hash.keys.sort.should == [:events, :linked, :links]

    json_hash[:events].should == grade_change_events_json([], @user, @session)

    json_hash[:linked].keys.sort.should == [:assignments, :courses, :page_views, :users]
    linked = json_hash[:linked]
    linked[:assignments].size.should be_zero
    linked[:courses].size.should be_zero
    linked[:users].size.should be_zero
    linked[:page_views].size.should be_zero
  end
end
