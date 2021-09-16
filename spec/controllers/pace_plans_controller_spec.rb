# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

require 'spec_helper'

describe PacePlansController, type: :controller do
  let(:valid_update_params) do
    {
      start_date: 1.year.ago.strftime('%Y-%m-%d'),
      end_date: 1.year.from_now.strftime('%Y-%m-%d'),
      workflow_state: 'active',
      pace_plan_module_items_attributes: [
        {
          id: @pace_plan.pace_plan_module_items.first.id,
          module_item_id: @pace_plan.pace_plan_module_items.first.module_item_id,
          duration: 1,
        },
        {
          id: @pace_plan.pace_plan_module_items.second.id,
          module_item_id: @pace_plan.pace_plan_module_items.second.module_item_id,
          duration: 10,
        },
      ],
    }
  end

  before :once do
    course_with_teacher(active_all: true)
    student_in_course(active_all: true)
    pace_plan_model(course: @course)

    @mod1 = @course.context_modules.create! name: 'M1'
    @a1 = @course.assignments.create! name: 'A1', workflow_state: 'unpublished'
    @mod1.add_item id: @a1.id, type: 'assignment'

    @mod2 = @course.context_modules.create! name: 'M2'
    @a2 = @course.assignments.create! name: 'A2', workflow_state: 'unpublished'
    @mod2.add_item id: @a2.id, type: 'assignment'
    @a3 = @course.assignments.create! name: 'A3', workflow_state: 'unpublished'
    @mod2.add_item id: @a3.id, type: 'assignment'

    @course.context_module_tags.each_with_index do |tag, i|
      @pace_plan.pace_plan_module_items.create! module_item: tag, duration: i * 2
    end

    @course.enable_pace_plans = true
    @course.save!
    @course.account.enable_feature!(:pace_plans)

    @valid_params = {
      start_date: 1.year.ago.strftime('%Y-%m-%d'),
      end_date: 1.year.from_now.strftime('%Y-%m-%d'),
      workflow_state: 'active',
      pace_plan_module_items_attributes: [
        {
          id: @pace_plan.pace_plan_module_items.first.id,
          module_item_id: @pace_plan.pace_plan_module_items.first.module_item_id,
          duration: 1,
        },
        {
          id: @pace_plan.pace_plan_module_items.second.id,
          module_item_id: @pace_plan.pace_plan_module_items.second.module_item_id,
          duration: 10,
        },
      ],
    }
  end

  before do
    user_session(@teacher)
  end

  describe "GET #show" do
    it "populates js_env with course, enrollment, sections, and pace_plan details" do
      @section = @course.course_sections.first
      @student_enrollment = @course.enrollments.find_by(user_id: @student.id)
      get :show, {params: {course_id: @course.id}}

      expect(response).to be_successful
      expect(assigns[:js_bundles].flatten).to include(:pace_plans)
      expect(controller.js_env[:BLACKOUT_DATES]).to eq([])
      expect(controller.js_env[:COURSE]).to match(hash_including({
       id: @course.id,
       name: @course.name,
       start_at: @course.start_at,
       end_at: @course.end_at
     }))
      expect(controller.js_env[:ENROLLMENTS].length).to be(1)
      expect(controller.js_env[:ENROLLMENTS][@student_enrollment.id]).to match(hash_including({
        id: @student_enrollment.id,
        user_id: @student.id,
        course_id: @course.id,
        full_name: @student.name,
        sortable_name: @student.sortable_name
      }))
      expect(controller.js_env[:SECTIONS].length).to be(1)
      expect(controller.js_env[:SECTIONS][@section.id]).to match(hash_including({
        id: @section.id,
        course_id: @course.id,
        name: @section.name,
        start_date: @section.start_at,
        end_date: @section.end_at
      }))
      expect(controller.js_env[:PACE_PLAN]).to match(hash_including({
        id: @pace_plan.id,
        course_id: @course.id,
        course_section_id: nil,
        user_id: nil,
        workflow_state: "active",
        exclude_weekends: true,
        hard_end_dates: true,
        context_id: @course.id,
        context_type: "Course"
      }))
      expect(controller.js_env[:PACE_PLAN][:modules].length).to be(2)
      expect(controller.js_env[:PACE_PLAN][:modules][0][:items].length).to be(1)
      expect(controller.js_env[:PACE_PLAN][:modules][1][:items].length).to be(2)
      expect(controller.js_env[:PACE_PLAN][:modules][1][:items][1]).to match(hash_including({
        assignment_title: @a3.title,
        module_item_type: 'Assignment',
        duration: 4
      }))
    end

    it "responds with not found if the pace_plans feature is disabled" do
      @course.account.disable_feature!(:pace_plans)
      assert_page_not_found do
        get :show, params: {course_id: @course.id}
      end
    end

    it "responds with not found if the enable_pace_plans setting is disabled" do
      @course.enable_pace_plans = false
      @course.save!
      assert_page_not_found do
        get :show, params: {course_id: @course.id}
      end
    end

    it "responds with forbidden if the user doesn't have authorization" do
      user_session(@student)
      get :show, params: {course_id: @course.id}
      assert_unauthorized
    end
  end

  describe "GET #api_show" do
    it "renders the specified pace plan" do
      get :api_show, params: { course_id: @course.id, id: @pace_plan.id }
      expect(response).to be_successful
      expect(JSON.parse(response.body)["pace_plan"]["id"]).to eq(@pace_plan.id)
    end
  end

  describe "PUT #update" do
    it "should update the PacePlan" do
      put :update, params: { course_id: @course.id, id: @pace_plan.id, pace_plan: valid_update_params }
      expect(response).to be_successful
      expect(@pace_plan.reload.start_date.to_s).to eq(valid_update_params[:start_date])
      expect(@pace_plan.end_date.to_s).to eq(valid_update_params[:end_date])
      expect(@pace_plan.workflow_state).to eq(valid_update_params[:workflow_state])
      expect(
        @pace_plan.pace_plan_module_items.joins(:module_item).find_by(content_tags: { content_id: @a1.id }).duration
      ).to eq(valid_update_params[:pace_plan_module_items_attributes][0][:duration])
      expect(
        @pace_plan.pace_plan_module_items.joins(:module_item).find_by(content_tags: { content_id: @a2.id }).duration
      ).to eq(valid_update_params[:pace_plan_module_items_attributes][1][:duration])

      response_body = JSON.parse(response.body)
      expect(response_body["id"]).to eq(@pace_plan.id)
    end
  end

  describe "POST #create" do
    let(:create_params) { valid_update_params.merge(course_id: @course.id, user_id: @student.id) }

    it "should create the PacePlan and all the PacePlanModuleItems" do
      pace_plan_count_before = PacePlan.count
      pace_plan_module_item_count_before = PacePlanModuleItem.count

      post :create, params: { course_id: @course.id, pace_plan: create_params }
      expect(response).to be_successful

      expect(PacePlan.count).to eq(pace_plan_count_before + 1)
      expect(PacePlanModuleItem.count).to eq(pace_plan_module_item_count_before + 2)

      pace_plan = PacePlan.last

      expect(pace_plan.start_date.to_s).to eq(valid_update_params[:start_date])
      expect(pace_plan.end_date.to_s).to eq(valid_update_params[:end_date])
      expect(pace_plan.workflow_state).to eq(valid_update_params[:workflow_state])
      expect(
        pace_plan.pace_plan_module_items.joins(:module_item).find_by(content_tags: { content_id: @a1.id }).duration
      ).to eq(valid_update_params[:pace_plan_module_items_attributes][0][:duration])
      expect(
        pace_plan.pace_plan_module_items.joins(:module_item).find_by(content_tags: { content_id: @a2.id }).duration
      ).to eq(valid_update_params[:pace_plan_module_items_attributes][1][:duration])
      expect(pace_plan.pace_plan_module_items.count).to eq(2)
    end
  end
end
