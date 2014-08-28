#
# Copyright (C) 2014 Instructure, Inc.
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

describe Polling::Poll do
  before :once do
    course
    @course.root_account.disable_feature!(:draft_state)
    teacher_in_course(course: @course, active_all: true)
  end

  context "creating a poll" do
    it "requires an associated user" do
      lambda { Polling::Poll.create!(question: 'A Test Poll') }.should raise_error(ActiveRecord::RecordInvalid,
                                                                        /User can't be blank/)
    end

    it "requires a question" do
      @poll = Polling::Poll.create(user: @teacher)
      @poll.should_not be_valid
    end

    it "saves successfully" do
      @poll = Polling::Poll.create!(user: @teacher, question: 'A Test Poll', description: 'A test description.')
      @poll.should be_valid
    end
  end

  describe "#closed_and_viewable_for?" do
    it "returns false if the latest poll session available to the user is opened" do
      student = student_in_course(active_user:true).user
      poll = @teacher.polls.create!(question: 'A Test Poll')
      session = poll.poll_sessions.create(course: @course)
      session.publish!

      poll.closed_and_viewable_for?(student).should be_false
    end

    context "the latest poll session available to the user is closed" do
      before(:each) do
        @student = student_in_course(active_user:true).user
        @poll = @teacher.polls.create!(question: 'A Test Poll')
        @choice = @poll.poll_choices.create!(text: 'Choice A', is_correct: true)
        @session = @poll.poll_sessions.create(course: @course)
      end

      it "returns true if the user has submitted" do
        @session.publish!
        @session.poll_submissions.create!(
          poll: @poll,
          user: @student,
          poll_choice: @choice
        )
        @session.close!

        @poll.closed_and_viewable_for?(@student).should be_true
      end

      it "returns false if the user hasn't submitted" do
        @session.publish!
        @session.close!
        @poll.closed_and_viewable_for?(@student).should be_false
      end
    end
  end

  describe "#total_results" do
    def create_submission(session, choice)
      student = student_in_course(active_user:true).user

      session.poll_submissions.create!(
        poll: @poll,
        user: student,
        poll_choice: choice
      )
    end

    before(:each) do
      @poll = @teacher.polls.create!(question: 'A Test Poll')
      @choice1 = @poll.poll_choices.create!(text: 'Choice A', is_correct: false)
      @choice2 = @poll.poll_choices.create!(text: 'Choice B', is_correct: true)
      @choice3 = @poll.poll_choices.create!(text: 'Choice B', is_correct: false)

      @section = @course.course_sections.create!(name: 'Section 2')
    end

    it "sums multiple poll session results together" do
      session1 = @poll.poll_sessions.new(course: @course, course_section: @section)
      session1.publish!
      create_submission(session1, @choice1)
      create_submission(session1, @choice1)
      create_submission(session1, @choice3)
      session1.close!

      session2 = @poll.poll_sessions.new(course: @course, course_section: @section)
      session2.publish!
      create_submission(session2, @choice2)
      create_submission(session2, @choice3)
      session2.close!

      session3 = @poll.poll_sessions.new(course: @course, course_section: @section)
      session3.publish!
      create_submission(session3, @choice1)
      session3.close!

      @poll.reload

      @poll.total_results.should == {
        @choice1.id => 3,
        @choice2.id => 1,
        @choice3.id => 2
      }
    end
  end
end
