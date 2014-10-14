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
    expect(AssignmentGroup).to be_respond_to(:acts_as_list)
  end

  context "visible assignments" do
    before(:each) do
      @u = factory_with_protected_attributes(User, :name => "some user", :workflow_state => "registered")
      @c = factory_with_protected_attributes(Course, :name => "some course", :workflow_state => "available")
      @ag = @c.assignment_groups.create!(@valid_attributes)
      @s = @c.course_sections.create!(name: "test section")
      student_in_section(@s, user: @u)
      assignments = (0...4).map { @c.assignments.create!({:title => "test_foo",
                                  :assignment_group => @ag,
                                  :points_possible => 10,
                                  :only_visible_to_overrides => true})}
      assignments.first.destroy
      assignments.second.grade_student(@u, {grade: 10})
      assignment_to_override = assignments.last
      create_section_override_for_assignment(assignment_to_override, course_section: @s)
      @c.reload
      @ag.reload
    end
    context "with differentiated assignments and draft state on" do
      it "should return only active assignments with overrides or grades for the user" do
        @c.enable_feature! :differentiated_assignments
        @c.enable_feature! :draft_state
        expect(@ag.active_assignments.count).to eq 3
        # one with override, one with grade
        expect(@ag.visible_assignments(@u).count).to eq 2
        expect(AssignmentGroup.visible_assignments(@u, @c, [@ag]).count).to eq 2
      end
    end

    context "with differentiated assignments off and draft state on" do
      it "should return all published assignments" do
        @c.disable_feature! :differentiated_assignments
        @c.enable_feature! :draft_state
        expect(@ag.active_assignments.count).to eq 3
        expect(@ag.visible_assignments(@u).count).to eq 3
        expect(AssignmentGroup.visible_assignments(@u, @c, [@ag]).count).to eq 3
      end
    end

    context "logged out users" do
      it "should return assignments for logged out users so that invited users can see them before accepting a course invite" do
        expect(@ag.visible_assignments(nil).count).to eq 3
        expect(AssignmentGroup.visible_assignments(nil, @c, [@ag]).count).to eq 3

      end
    end
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
    expect(@ag.state).to eql(:available)
  end

  it "should return never_drop list as ints" do
    expected = [ 9, 22, 16, 4 ]
    rules = "drop_lowest:2\n"
    expected.each do |val|
      rules += "never_drop:#{val}\n"
    end
    assignment_group_model :rules => rules
    result = @ag.rules_hash()
    expect(result['never_drop']).to eql(expected)
  end

  it "should return never_drop list as strings if `stringify_json_ids` is true" do
    expected = [ '9', '22', '16', '4' ]
    rules = "drop_highest:25\n"
    expected.each do |val|
      rules += "never_drop:#{val}\n"
    end

    assignment_group_model :rules => rules
    result = @ag.rules_hash({stringify_json_ids: true})
    expect(result['never_drop']).to eql(expected)
  end

  it "should return rules that aren't never_drops as ints" do
    rules = "drop_highest:25\n"
    assignment_group_model :rules => rules
    result = @ag.rules_hash()
    expect(result['drop_highest']).to eql(25)
  end

  it "should return rules that aren't never_drops as ints when `strigify_json_ids` is true" do
    rules = "drop_lowest:2\n"
    assignment_group_model :rules => rules
    result = @ag.rules_hash({stringify_json_ids: true})
    expect(result['drop_lowest']).to eql(2)
  end
end

def assignment_group_model(opts={})
  @u = factory_with_protected_attributes(User, :name => "some user", :workflow_state => "registered")
  @c = factory_with_protected_attributes(Course, :name => "some course", :workflow_state => "available")
  @c.enroll_student(@u)
  @ag = @c.assignment_groups.create!(@valid_attributes.merge(opts))
end
