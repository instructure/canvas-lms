#
# Copyright (C) 2011 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../views_helper')

describe "/courses/_recent_event" do
  it "should render" do
    course_with_student
    assignment = @course.assignments.create!(:title => 'my assignment')
    view_context
    render :partial => "courses/recent_event", :object => assignment, :locals => { :is_hidden => false }
    expect(response).not_to be_nil
    expect(response.body).to match %r{<b class="event-details__title">my assignment</b>}
  end

  it "should render without a user" do
    course_factory
    assignment = @course.assignments.create!(:title => 'my assignment')
    view_context
    render :partial => "courses/recent_event", :object => assignment, :locals => { :is_hidden => false }
    expect(response).not_to be_nil
    expect(response.body).to match %r{<b class="event-details__title">my assignment</b>}
  end

  it "shows the context when asked to" do
    course_with_student
    event = @course.calendar_events.create(title: "some assignment", start_at: Time.zone.now)

    render partial: "courses/recent_event", object: event, locals: {is_hidden: false, show_context: true}

    expect(response.body).to include(@course.short_name)
  end

  it "doesn't show the context when not asked to" do
    course_with_student
    event = @course.calendar_events.create(title: "some assignment", start_at: Time.zone.now)

    render partial: "courses/recent_event", object: event, locals: {is_hidden: false}

    expect(response.body).to_not include(@course.name)
  end

  context 'assignments' do
    before do
      course_with_student(active_all: true)
      submission_model
      assign(:current_user, @user)
    end

    it 'shows points possible for an ungraded assignment' do
      render partial: "courses/recent_event", object: @assignment, locals: {is_hidden: false}

      expect(response.body).to include("#{@assignment.points_possible} points")
    end

    it 'shows the grade for a graded assignment' do
      @assignment.grade_student(@user, grade: 7, grader: @teacher)

      render partial: "courses/recent_event", object: @assignment, locals: {is_hidden: false}

      expect(response.body).to include("7 out of #{@assignment.points_possible}")
    end

    it 'shows the due date' do
      render partial: "courses/recent_event", object: @assignment, locals: {is_hidden: false}

      expect(response.body).to include(view.datetime_string(@assignment.due_at))
    end

    it 'shows overridden due date' do
      different_due_at = 2.days.from_now
      create_adhoc_override_for_assignment(@assignment, @user, due_at: different_due_at)

      render partial: "courses/recent_event", object: @assignment, locals: {is_hidden: false}

      expect(response.body).to include(view.datetime_string(different_due_at))
    end
  end

  context "assignment muting" do
    before(:each) do
      course_with_student
      view_context
      @quiz = @course.quizzes.create!
      @quiz.generate_quiz_data
      @quiz.workflow_state = 'available'
      @quiz.published_at = Time.zone.now
      @quiz.save

      @quiz_submission = @quiz.generate_submission(@user)
      Quizzes::SubmissionGrader.new(@quiz_submission).grade_submission

      @submission = @quiz_submission.submission
      Submission.any_instance.stubs(:grade).returns('1234567890')
    end

    it "should show the grade for a non-muted assignment" do
      render :partial => "courses/recent_event",
        :object => @quiz.assignment,
        :locals => { :is_hidden => false, :submissions => [ @submission ] }
      expect(response.body).to match(/1,234,567,890/)
    end

    it "should not show the grade for a muted assignment" do
      @quiz.assignment.mute!
      render :partial => "courses/recent_event",
        :object => @quiz.assignment,
        :locals => { :is_hidden => false, :submissions => [ @submission ] }
      expect(response.body).not_to match(/1,234,567,890/)
    end
  end
end

# Sidebar content
