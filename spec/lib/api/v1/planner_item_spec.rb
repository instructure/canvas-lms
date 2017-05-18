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

require_relative '../../../spec_helper'

describe Api::V1::PlannerItem do
  class PlannerItemHarness
    include Api::V1::PlannerItem

    def api_v1_users_todo_ignore_url(*args); end
    def assignment_json(*args); end
    def speed_grader_course_gradebook_url(*args); end
    def quiz_json(*args); end
    def course_quiz_url(*args); end
    def course_assignment_url(*args); end
    def wiki_page_json(*args); end
    def discussion_topic_api_json(*args); end
    def named_context_url(*args); end
  end

  before :once do
    course_factory
    @course.root_account.enable_feature!(:student_planner)

    teacher_in_course
    student_in_course
    for_course = { course: @course }

    assignment_quiz [], for_course
    group_assignment_discussion for_course
    assignment_model for_course

    @teacher_override = planner_override_model(plannable: @assignment, user: @teacher)
    @student_override = planner_override_model(plannable: @assignment, user: @student, visible: false)
  end

  describe '.planner_item_json' do
    let(:api) { PlannerItemHarness.new }
    let(:session) { Object.new }

    before :once do
      @teacher_hash = api.planner_item_json(@assignment, @teacher, session, 'submitting')
      @student_hash = api.planner_item_json(@assignment, @student, session, 'submitting')
      @hash = api.planner_item_json(@quiz.assignment, @student, session, 'submitting')
    end

    context 'with an existing planner override' do
      it 'should return the planner visibility state' do
        expect(@teacher_hash[:visible_in_planner]).to eq true
        expect(@student_hash[:visible_in_planner]).to eq false
      end

      it 'should return the planner override id' do
        expect(@teacher_hash[:planner_override].id).to eq @teacher_override.id
        expect(@student_hash[:planner_override].id).to eq @student_override.id
      end
    end

    context 'without an existing planner override' do
      it 'should return true for `visible_in_planner`' do
        expect(@hash[:visible_in_planner]).to eq true
      end

      it 'should have a nil planner_override value' do
        expect(@hash[:planner_override]).to be_nil
      end
    end

    describe 'object types' do
      before :once do
        @assignment_hash = api.planner_item_json(@assignment, @student, session, 'submitting')
        @topic_hash = api.planner_item_json(@topic.assignment, @student, session, 'submitting')
        @quiz_hash = api.planner_item_json(@quiz.assignment, @student, session, 'submitting')
      end

      it 'should include the respective jsons for the given object type' do
        expect(@assignment_hash.has_key?(:plannable)).to be_truthy
        expect(@topic_hash.has_key?(:plannable)).to be_truthy
        expect(@quiz_hash.has_key?(:plannable)).to be_truthy
      end
    end

    describe 'status' do
      before :once do
        @assignment_hash = api.planner_item_json(@assignment, @student, session, 'submitting')
      end

      it 'should return the statuses for the learning object'
    end

    describe 'activity' do
      before :once do
        @topic_hash = api.planner_item_json(@topic.assignment, @student, session, 'submitting')
      end

      it 'should return the latest activity for the learning object'
    end
  end
end
