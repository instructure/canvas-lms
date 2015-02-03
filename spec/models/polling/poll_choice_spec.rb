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

describe Polling::PollChoice do
  before(:each) do
    course
    teacher_in_course(course: @course, active_all: true)
    @poll = Polling::Poll.create!(user: @teacher, question: 'A Test Poll')
  end

  context "creating a poll choice" do
    it "requires an associated poll" do
        expect { Polling::PollChoice.create!(is_correct: false, text: 'Poll Choice A') }.to raise_error(ActiveRecord::RecordInvalid,
                                                                                    /Poll can't be blank/)
    end

    it "saves successfully" do
      @poll_choice = Polling::PollChoice.new(poll: @poll, text: 'A Poll Choice', is_correct: true)
      @poll_choice.save
      expect(@poll_choice).to be_valid
    end
  end
end
