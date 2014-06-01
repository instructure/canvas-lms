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
    @poll = Polling::Poll.create!(course: @course, title: 'A Test Poll')
    @poll_choice = Polling::PollChoice.new(poll: @poll, text: 'Poll Choice A')
    @poll_choice.is_correct = true
    @poll_choice.save
  end

  context "creating a poll submission" do
    it "requires an associated poll" do
      lambda { Polling::PollSubmission.create!(poll_choice: @poll_choice, user: @student) }.should raise_error(ActiveRecord::RecordInvalid,
                                                                        /Poll can't be blank/)
    end

    it "requires an associated poll choice" do
      lambda { Polling::PollSubmission.create!(poll: @poll, user: @student) }.should raise_error(ActiveRecord::RecordInvalid,
                                                                        /Poll choice can't be blank/)
    end

    it "requires a user" do
      lambda { Polling::PollSubmission.create!(poll: @poll, poll_choice: @poll_choice) }.should raise_error(ActiveRecord::RecordInvalid,
                                                                        /User can't be blank/)

    end

    it "saves successfully" do
      @poll_submission = Polling::PollSubmission.create(poll: @poll, poll_choice: @poll_choice, user: @student)
      @poll_submission.should be_valid
    end
  end
end
