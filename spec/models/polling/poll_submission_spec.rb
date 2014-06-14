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

describe Polling::PollSubmission do
  before(:each) do
    course_with_student
    @course.root_account.disable_feature!(:draft_state)
    @section = @course.course_sections.create!(name: 'Section 2')
    teacher_in_course(course: @course, active_all: true)

    @poll = Polling::Poll.create!(user: @teacher, question: 'A Test Poll')
    @poll_choice = Polling::PollChoice.new(poll: @poll, text: 'Poll Choice A')
    @poll_choice.is_correct = true
    @poll_choice.save

    @session = Polling::PollSession.create!(poll: @poll, course: @course, course_section: @section)
    @session.publish!
  end

  context "creating a poll submission" do
    it "requires an associated poll" do
      lambda { Polling::PollSubmission.create!(poll_choice: @poll_choice,
                                               user: @student,
                                               poll_session: @session) }.should raise_error(ActiveRecord::RecordInvalid,
                                                                                            /Poll can't be blank/)
    end

    it "requires an associated poll choice" do
      lambda { Polling::PollSubmission.create!(poll: @poll,
                                               user: @student,
                                               poll_session: @session) }.should raise_error(ActiveRecord::RecordInvalid,
                                                                                            /Poll choice can't be blank/)
    end

    it "requires a user" do
      lambda { Polling::PollSubmission.create!(poll: @poll,
                                               poll_choice: @poll_choice,
                                               poll_session: @session) }.should raise_error(ActiveRecord::RecordInvalid,
                                                                                            /User can't be blank/)
    end

    it "requires a poll session" do
      lambda { Polling::PollSubmission.create!(poll: @poll,
                                               user: @student,
                                               poll_choice: @poll_choice).should raise_error(ActiveRecord::RecordInvalid,
                                                                                             /Poll session can't be blank/)}
    end

    it "saves successfully" do
      @poll_submission = Polling::PollSubmission.create(poll: @poll, poll_choice: @poll_choice, user: @student, poll_session: @session)
      @poll_submission.should be_valid
    end

    it "restricts a user to one submission per session" do
      @poll_submission = Polling::PollSubmission.create!(poll: @poll, user: @student, poll_choice: @poll_choice, poll_session: @session)
      @poll_submission.should be_valid

      lambda { Polling::PollSubmission.create!(poll: @poll,
                                               user: @student,
                                               poll_choice: @poll_choice,
                                               poll_session: @session) }.should raise_error(ActiveRecord::RecordInvalid,
                                                                                            /can only submit one choice per poll session/)
    end

    it "allows multiple submissions across multiple sessions" do
      submission1 = Polling::PollSubmission.create!(poll: @poll, user: @student, poll_choice: @poll_choice, poll_session: @session)
      submission1.should be_valid

      session2 = Polling::PollSession.create!(poll: @poll, course: @course, course_section: @section)
      session2.publish!

      submission2 = Polling::PollSubmission.create!(poll: @poll, user: @student, poll_choice: @poll_choice, poll_session: session2)
      submission2.should be_valid
    end

    it "insures the associated poll session is published" do
      @session.close!
      lambda { Polling::PollSubmission.create!(poll: @poll,
                                               user: @student,
                                               poll_choice: @poll_choice,
                                               poll_session: @session) }.should raise_error(ActiveRecord::RecordInvalid,
                                                                                            /This poll session is not open for submissions/)
    end

    it "insures the poll choice is associated to the submission's poll" do
      new_poll = Polling::Poll.create!(user: @teacher, question: 'A New Poll')
      poll_choice = Polling::PollChoice.new(poll: new_poll, text: 'Poll Choice A')
      poll_choice.is_correct = true
      poll_choice.save

      lambda { Polling::PollSubmission.create!(poll: @poll,
                                               user: @student,
                                               poll_choice: poll_choice,
                                               poll_session: @session) }.should raise_error(ActiveRecord::RecordInvalid,
                                                                                            /That poll choice does not belong to the existing poll/)
    end
  end
end
