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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe GroupMembership do
  
  it "should ensure a mutually exclusive relationship" do
    @gm = factory_with_protected_attributes(GroupMembership, valid_group_membership_attributes, false)
    @gm.should_receive(:ensure_mutually_exclusive_membership)
    @gm.save!
  end
  
  it "should dispatch a 'new_student_organized_group' message if the first membership in a student organized group" do
    course_with_teacher
    student = user_model
    @course.enroll_student(student)
    group = @course.groups.create(:group_category => GroupCategory.student_organized_for(@course))

    Notification.create(:name => "New Student Organized Group", :category => "TestImmediately")
    @teacher.communication_channels.create(:path => "test_channel_email_#{@teacher.id}", :path_type => "email").confirm

    group_membership = group.group_memberships.create(:user => student)
    group_membership.messages_sent.should be_include("New Student Organized Group")
  end
end

def group_membership_model(opts={})
  @group_membership = factory_with_protected_attributes(GroupMembership, valid_group_membership_attributes.merge(opts))
end

def valid_group_membership_attributes
  {
    :group_id => 1, 
    :user_id => 1
  }
end


#   include Workflow
#   
#   belongs_to :group
#   belongs_to :user
#   
#   before_save :ensure_mutually_exclusive_membership
#   before_save :assign_uuid
#   
#   def assign_uuid
#     self.uuid ||= UUIDSingleton.instance.generate
#   end
#   protected :assign_uuid
# 
#   def ensure_mutually_exclusive_membership
#     return unless self.group
#     self.group.peer_groups.each do |group|
#       member = group.group_memberships.find_by_user_id(self.user_id)
#       member.destroy if member
#     end
#   end
#   protected :ensure_mutually_exclusive_membership
#   
#   workflow do
#     state :new do
#       event :admit, :transitions_to => :admitted
#       event :reject, :transitions_to => :rejected
#     end
#     
#     state :admitted do
#       event :expel, :transitions_to => :expelled
#     end
#     
#     state :expelled
#     state :rejected
#     
#   end
#   
# end
