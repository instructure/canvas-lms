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

describe AssignmentGroup do
  
  before(:each) do
    @valid_attributes = {
      :name => "value for name",
      :rules => "value for rules",
      :default_assignment_name => "value for default assignment name",
      :assignment_weighting_scheme => "value for assignment weighting scheme",
      :group_weight => 1.0
    }
  end
  
  it "should act as list" do
    AssignmentGroup.should be_respond_to(:acts_as_list)
  end
  
  context "broadcast policy" do
    context "grade weight changed" do
      # it "should have a 'Grade Weight Changed' policy" do
        # assignment_group_model
        # @ag.broadcast_policy_list.map {|bp| bp.dispatch}.should be_include('Grade Weight Changed')
      # end
      
      # it "should create a message when the grade weight changes on an assignment group" do
        # Notification.create!(:name => 'Grade Weight Changed')
        # assignment_group_model
        # @ag.group_weight = 0.2
        # @ag.save!
        # @ag.context.messages_sent.should be_include('Grade Weight Changed')
      # end
      
    end
  end
  
  it "should have a state machine" do
    assignment_group_model
    @ag.state.should eql(:available)
  end
  
end

def assignment_group_model(opts={})
  @u = factory_with_protected_attributes(User, :name => "some user", :workflow_state => "registered")
  @c = factory_with_protected_attributes(Course, :name => "some course", :workflow_state => "available")
  @c.enroll_student(@u)
  @ag = @c.assignment_groups.create!(@valid_attributes.merge(opts))
end
