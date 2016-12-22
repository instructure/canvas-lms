#
# Copyright (C) 2012 Instructure, Inc.
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

describe Collaborator do
  before :once do
    course_with_teacher(:active_all => true)
    @notification       = Notification.create!(:name => 'Collaboration Invitation')
    @author             = @teacher
    @collaboration      = Collaboration.new(:title => 'Test collaboration')
    @collaboration.context = @course
    @collaboration.type = 'EtherpadCollaboration'
    @collaboration.user = @author
  end

  context 'broadcast policy' do
    it 'should notify collaborating users', priority: "1", test_id: 193152 do
      user = user_with_pseudonym(:active_all => true)
      @course.enroll_student(user)
      NotificationPolicy.create(:notification => @notification,
                                :communication_channel => user.communication_channel,
                                :frequency => 'immediately')
      @collaboration.update_members([user])
      expect(@collaboration.collaborators.detect { |c| c.user_id == user.id }.
        messages_sent.keys).to eq ['Collaboration Invitation']
    end

    it 'should not notify the author' do
      NotificationPolicy.create(:notification => @notification,
                                :communication_channel => @author.communication_channel,
                                :frequency => 'immediately')
      @collaboration.update_members([@author])
      expect(@collaboration.reload.collaborators.detect { |c| c.user_id == @author.id }.
        messages_sent.keys).to be_empty

    end

    it 'should notify all members of a group' do
      group = group_model(:name => 'Test group', :context => @course)
      users = (1..2).map { user_with_pseudonym(:active_all => true) }
      users.each { |u| group.add_user(u, 'active') }
      @collaboration.update_members([], [group.id])
      expect(@collaboration.collaborators.detect { |c| c.group_id.present? }.
        messages_sent.keys).to include 'Collaboration Invitation'
    end
  end
end
