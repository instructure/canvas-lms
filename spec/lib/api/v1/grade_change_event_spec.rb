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

  def feeds_calendar_url(feed_code)
    "feed_calendar_url(#{feed_code.inspect})"
  end

  def course_assignment_url(course, assignment)
    'http://www.example.com'
  end

  def service_enabled?(type)
    false
  end

  before do
    @request_id = UUIDSingleton.instance.generate
    RequestContextGenerator.stubs( :request_id => @request_id )

    @domain_root_account = Account.default

    course_with_teacher(account: @domain_root_account)
    course_with_student_logged_in(course: @course)

    @page_view = PageView.new { |p|
      p.send(:attributes=, {
        :request_id => @request_id,
        :remote_ip => '10.10.10.10'
      }, false)
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
    event[:request_id].should == @event.request_id
    event[:links][:assignment].should == Shard.relative_id_for(@assignment)
    event[:links][:course].should == Shard.relative_id_for(@course)
    event[:links][:student].should == Shard.relative_id_for(@student)
    event[:links][:grader].should == Shard.relative_id_for(@teacher)
    event[:links][:page_view].should == @page_view.id
  end

  it "should be formatted as an array of grade change event hashes" do
    grade_change_events_json(@events, @student, @session).size.should eql(@events.size)
  end

  it "should be formatted as an array of compound grade change event hashes" do
    json_hash = grade_change_events_compound_json(@events, @user, @session)

    json_hash[:meta][:primaryCollection].should == 'events'
    json_hash[:events].should == grade_change_events_json(@events, @user, @session)
    json_hash[:assignments].size.should eql(1)
    json_hash[:courses].size.should eql(1)
    json_hash[:users].size.should eql(2)
    json_hash[:page_views].size.should eql(1)
  end

  it "should handle an empty result set" do
    json_hash = grade_change_events_compound_json([], @user, @session)

    json_hash[:meta][:primaryCollection].should == 'events'
    json_hash[:events].should == grade_change_events_json([], @user, @session)
    json_hash[:assignments].size.should be_zero
    json_hash[:courses].size.should be_zero
    json_hash[:users].size.should be_zero
    json_hash[:page_views].size.should be_zero
  end
end
