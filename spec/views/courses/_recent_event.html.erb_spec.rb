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
    response.should_not be_nil
    response.body.should =~ %r{<b>my assignment</b>}
  end

  it "should render without a user" do
    course
    assignment = @course.assignments.create!(:title => 'my assignment')
    view_context
    render :partial => "courses/recent_event", :object => assignment, :locals => { :is_hidden => false }
    response.should_not be_nil
    response.body.should =~ %r{<b>my assignment</b>}
  end

  context "assignment muting and tooltips" do
    before(:each) do
      course_with_student
      view_context
      @quiz = @course.quizzes.create!
      @quiz.generate_quiz_data
      @quiz.workflow_state = 'available'
      @quiz.published_at = Time.now
      @quiz.save
      @quiz.assignment.should_not be_nil

      @quiz_submission = @quiz.generate_submission(@user)
      Quizzes::SubmissionGrader.new(@quiz_submission).grade_submission

      @submission = @quiz_submission.submission
      Submission.any_instance.stubs(:score).returns(1234567890987654400)
    end

    it "should show the score for a non-muted assignment" do
      render :partial => "courses/recent_event", :object => @quiz.assignment, :locals => { :is_hidden => false, :submissions => [ @submission ] }
      response.body.should =~ /#{@submission.score}/
    end

    it "should not show the score for a muted assignment" do
      @quiz.assignment.mute!
      render :partial => "courses/recent_event", :object => @quiz.assignment, :locals => { :is_hidden => false, :submissions => [ @submission ] }
      response.body.should_not =~ /#{@submission.score}/
    end
  end
end

# Sidebar content
