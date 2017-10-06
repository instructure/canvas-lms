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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

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
      allow(ConditionalRelease::Service).to receive(:rules_for).and_return([
        {
          trigger_assignment: 1,
          locked: false,
          selected_set_id: 99,
          assignment_sets: [{assignments: [{assignment_id: 2}]}],
        }
      ])
    end

    it 'should return rules for the mastery path for a matched assignment' do
      content_tag = FakeTag.new(1, FakeItem.new(1, 'Assignment'))
      content_tag2 = FakeTag.new(1, FakeItem.new(2, 'Assignment'))
      expect(helper.conditional_release_rule_for_module_item(content_tag)[:selected_set_id]).to eq(99)
      expect(helper.conditional_release_rule_for_module_item(content_tag2)).to be_nil
    end

    describe 'path data for student' do
      before do
        @context = course_factory(active_all: true)
        @current_user = user_factory
      end

      it 'should return url data for the mastery path if assignments in set are visible' do
        allow(AssignmentStudentVisibility).to receive(:visible_assignment_ids_for_user).and_return([2])
        content_tag = FakeTag.new(1, FakeItem.new(1, 'Assignment'))
        mastery_path = helper.conditional_release_rule_for_module_item(content_tag, {is_student: true})
        expect(mastery_path[:still_processing]).to be false
        expect(mastery_path[:modules_url]).to eq("/courses/#{@context.id}/modules")
      end

      it 'should list as processing if all requirements are met but assignment is not yet visible' do
        content_tag = FakeTag.new(1, FakeItem.new(1, 'Assignment'))
        mastery_path = helper.conditional_release_rule_for_module_item(content_tag, {is_student: true})
        expect(mastery_path[:still_processing]).to be true
      end

      it 'should set awaiting_choice to true if sets exist but none are selected' do
        allow(ConditionalRelease::Service).to receive(:rules_for).and_return([
          {
            trigger_assignment: 1,
            locked: false,
            selected_set_id: nil,
            assignment_sets: [{assignments: [{assignment_id: 2}]}],
          }
        ])
        content_tag = FakeTag.new(1, FakeItem.new(1, 'Assignment'))
        mastery_path = helper.conditional_release_rule_for_module_item(content_tag, {is_student: true})
        expect(mastery_path[:choose_url]).to eq("/courses/#{@context.id}/modules/items/1/choose")
        expect(mastery_path[:awaiting_choice]).to be true
      end
    end

  end
end
