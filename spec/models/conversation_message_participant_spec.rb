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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe ConversationMessageParticipant do
  before :once do
    teacher_in_course
    student_in_course
    @student1 = @student
    student_in_course
    @student2 = @student
  end

  describe "scopes" do
    before :once do
      @conv = conversation(@teacher, @student1, @student2)
      @msg = @conv.messages.first
    end

    describe "#active" do
      it "should ignore soft deletes" do
        @teacher.conversations.first.remove_messages(@msg)
        ConversationMessageParticipant.all.count.should eql 3
        ConversationMessageParticipant.all.map(&:workflow_state).sort.should eql ['active', 'active', 'deleted']
        ConversationMessageParticipant.active.map(&:workflow_state).should eql ['active', 'active']
      end

      it "should include nil workflow_state" do
        ConversationMessageParticipant.update_all(:workflow_state => nil)
        ConversationMessageParticipant.active.map(&:workflow_state).sort.should eql [nil, nil, nil]
      end
    end

    describe "#deleted" do
      it "should only include soft deletes" do
        @teacher.conversations.first.remove_messages(@msg)
        ConversationMessageParticipant.all.count.should eql 3
        ConversationMessageParticipant.deleted.map(&:workflow_state).should eql ['deleted']
      end
    end
  end
end
