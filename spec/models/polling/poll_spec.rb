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
  before(:each) do
    course
    @course.root_account.disable_feature!(:draft_state)
  end

  context "creating a poll" do
    it "requires an associated course" do
      lambda { Polling::Poll.create!(title: 'A Test Poll') }.should raise_error(ActiveRecord::RecordInvalid,
                                                                        /Course can't be blank/)
    end

    it "requires a title" do
      @poll = Polling::Poll.create(course: @course)
      @poll.should_not be_valid
    end

    it "saves successfully" do
      @poll = Polling::Poll.create!(course: @course, title: 'A Test Poll')
      @poll.should be_valid
    end
  end
end
