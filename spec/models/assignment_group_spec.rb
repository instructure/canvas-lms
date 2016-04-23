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

  before(:once) do
    @valid_attributes = {
      :name => "value for name",
      :rules => "value for rules",
      :default_assignment_name => "value for default assignment name",
      :assignment_weighting_scheme => "value for assignment weighting scheme",
      :group_weight => 1.0
    }
    course_with_student(active_all: true)
    @course.update_attribute(:group_weighting_scheme, 'percent')
  end

  it "should act as list" do
    expect(AssignmentGroup).to be_respond_to(:acts_as_list)
  end

  context "visible assignments" do
    before(:each) do
      @ag = @course.assignment_groups.create!(@valid_attributes)
      @s = @course.course_sections.create!(name: "test section")
      student_in_section(@s, user: @student)
      assignments = (0...4).map { @course.assignments.create!({:title => "test_foo",
                                  :assignment_group => @ag,
                                  :points_possible => 10,
                                  :only_visible_to_overrides => true})}
      assignments.first.destroy
      assignments.second.grade_student(@student, {grade: 10})
      assignment_to_override = assignments.last
      create_section_override_for_assignment(assignment_to_override, course_section: @s)
      @course.reload
      @ag.reload
    end

    context "with differentiated assignments and draft state on" do
      it "should return only active assignments with overrides or grades for the user" do
        expect(@ag.active_assignments.count).to eq 3
        # one with override, one with grade
        expect(@ag.visible_assignments(@student).count).to eq 2
        expect(AssignmentGroup.visible_assignments(@student, @course, [@ag]).count).to eq 2
      end
    end

    context "logged out users" do
      it "should return published assignments for logged out users so that invited users can see them before accepting a course invite" do
        @course.active_assignments.first.unpublish
        expect(@ag.visible_assignments(nil).count).to eq 2
        expect(AssignmentGroup.visible_assignments(nil, @course, [@ag]).count).to eq 2
      end
    end
  end

  context "broadcast policy" do
    context "grade weight changed" do
      before(:once) do
        Notification.create!(name: 'Grade Weight Changed', category: 'TestImmediately')
        assignment_group_model
      end

      it "sends a notification when the grade weight changes" do
        @ag.update_attribute(:group_weight, 0.2)
        expect(@ag.context.messages_sent['Grade Weight Changed'].any?{|m| m.user_id == @student.id}).to be_truthy
      end

      it "sends a notification to observers when the grade weight changes" do
        course_with_observer(course: @course, associated_user_id: @student.id, active_all: true)
        @ag.reload.update_attribute(:group_weight, 0.2)
        expect(@ag.context.messages_sent['Grade Weight Changed'].any?{|m| m.user_id == @observer.id}).to be_truthy
      end
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
  @ag = @course.assignment_groups.create!(@valid_attributes.merge(opts))
end
