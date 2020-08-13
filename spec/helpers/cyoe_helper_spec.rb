#
# Copyright (C) 2017 - present Instructure, Inc.
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

require_relative '../conditional_release_spec_helper'

describe CyoeHelper do
  include CyoeHelper

  FakeItem = Struct.new(:id, :content_type, :graded?, :content).freeze
  FakeContent = Struct.new(:assignment?, :graded?).freeze
  FakeTag = Struct.new(:id, :assignment).freeze

  describe 'cyoeable item' do

    it 'should return false if an item is not a quiz or assignment' do
      topic = FakeItem.new(1, 'DiscussionTopic', false)
      expect(helper.cyoe_able?(topic)).to eq false
    end

    context 'graded' do
      it 'should return true for quizzes and assignments' do
        quiz = FakeItem.new(1, 'Quizzes::Quiz', true, FakeContent.new(true))
        assignment = FakeItem.new(1, 'Assignment', true, FakeContent.new(true, true))
        expect(helper.cyoe_able?(quiz)).to eq true
        expect(helper.cyoe_able?(assignment)).to eq true
      end
    end

    context 'ungraded' do
      it 'should not return true for quizzes or assignments' do
        quiz = FakeItem.new(1, 'Quizzes::Quiz', false)
        assignment = FakeItem.new(1, 'Assignment', false)
        expect(helper.cyoe_able?(quiz)).to eq false
        expect(helper.cyoe_able?(assignment)).to eq false
      end
    end
  end

  describe 'cyoe rules' do
    before do
      setup_course_with_native_conditional_release
      @context = @course
      @current_user = @student

      @mod = @course.context_modules.create!
      @tag = @mod.add_item(type: 'assignment', id: @trigger_assmt.id)
      @trigger_assmt.grade_student(@student, grade: 9, grader: @teacher)
    end

    it 'should return rules for the mastery path for a matched assignment' do
      set1 = @set1_assmt1.conditional_release_associations.first.assignment_set
      expect(helper.conditional_release_rule_for_module_item(@tag, :context => @course, :user => @student)[:selected_set_id]).to eq(set1.id)

      @tag2 = @mod.add_item(type: 'assignment', id: @set1_assmt1.id)
      expect(helper.conditional_release_rule_for_module_item(@tag2, :context => @course, :user => @student)).to be_nil
    end

    describe 'path data for student' do
      it 'should return url data for the mastery path if assignment set action is created' do
        mastery_path = helper.conditional_release_rule_for_module_item(@tag, {is_student: true, context: @course, user: @student})
        expect(mastery_path[:still_processing]).to be false
        expect(mastery_path[:modules_url]).to eq("/courses/#{@context.id}/modules")
      end

      it 'should return url data for the mastery path even if one of the unlocked items is unpublished' do
        set1 = @set1_assmt1.conditional_release_associations.first.assignment_set
        unpublised_assmt = @course.assignments.create!(:only_visible_to_overrides => true, :workflow_state => "unpublished")
        set1.assignment_set_associations.create!(:assignment => unpublised_assmt)

        mastery_path = helper.conditional_release_rule_for_module_item(@tag, {is_student: true, context: @course, user: @student})
        expect(mastery_path[:still_processing]).to be false # old code would have blown up because the unpublished assmt isn't visible
        expect(mastery_path[:modules_url]).to eq("/courses/#{@context.id}/modules")
      end

      it 'should list as processing if all requirements are met but assignment is not yet visible' do
        student2 = student_in_course(course: @course, active_all: true).user
        @current_user = student2
        expect(ConditionalRelease::OverrideHandler).to receive(:handle_grade_change).and_return(nil) # and do nothing
        @trigger_assmt.grade_student(student2, grade: 9, grader: @teacher)

        mastery_path = helper.conditional_release_rule_for_module_item(@tag, {is_student: true, context: @course, user: student2})
        expect(mastery_path[:still_processing]).to be true
      end

      it 'should set awaiting_choice to true if sets exist but none are selected' do
        @trigger_assmt.grade_student(@student, grade: 3, grader: @teacher)

        mastery_path = helper.conditional_release_rule_for_module_item(@tag, {is_student: true, context: @course, user: @student})
        expect(mastery_path[:choose_url]).to eq("/courses/#{@context.id}/modules/items/#{@tag.id}/choose")
        expect(mastery_path[:awaiting_choice]).to be true
      end
    end

  end
end
