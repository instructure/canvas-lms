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

describe PacePlansController, type: :controller do
  let(:valid_update_params) do
    {
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
    @student_enrollment = @student.enrollments.first

    @mod1 = @course.context_modules.create! name: 'M1'
    @a1 = @course.assignments.create! name: 'A1', workflow_state: 'active'
    @mod1.add_item id: @a1.id, type: 'assignment'

    @mod2 = @course.context_modules.create! name: 'M2'
    @a2 = @course.assignments.create! name: 'A2', workflow_state: 'published'
    @mod2.add_item id: @a2.id, type: 'assignment'
    @a3 = @course.assignments.create! name: 'A3', workflow_state: 'published'
    @mod2.add_item id: @a3.id, type: 'assignment'
    @mod2.add_item type: 'external_url', title: 'External URL', url: 'http://localhost'

    @course.context_module_tags.each_with_index do |tag, i|
      next unless tag.assignment

      @pace_plan.pace_plan_module_items.create! module_item: tag, duration: i * 2
    end

    @course.enable_pace_plans = true
    @course.save!
    @course.account.enable_feature!(:pace_plans)

    @course_section = @course.course_sections.first

    @valid_params = {
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

  describe "GET #index" do
    it "populates js_env with course, enrollment, sections, and pace_plan details" do
      @section = @course.course_sections.first
      @student_enrollment = @course.enrollments.find_by(user_id: @student.id)
      @progress = Progress.create!(context: @pace_plan, tag: 'pace_plan_publish')
      get :index, { params: { course_id: @course.id } }

      expect(response).to be_successful
      expect(assigns[:js_bundles].flatten).to include(:pace_plans)
      js_env = controller.js_env
      expect(js_env[:BLACKOUT_DATES]).to eq([])
      expect(js_env[:COURSE]).to match(hash_including({
                                                        id: @course.id,
                                                        name: @course.name,
                                                        start_at: @course.start_at,
                                                        end_at: @course.end_at
                                                      }))
      expect(js_env[:ENROLLMENTS].length).to be(1)
      expect(js_env[:ENROLLMENTS][@student_enrollment.id]).to match(hash_including({
                                                                                     id: @student_enrollment.id,
                                                                                     user_id: @student.id,
                                                                                     course_id: @course.id,
                                                                                     full_name: @student.name,
                                                                                     sortable_name: @student.sortable_name
                                                                                   }))
      expect(js_env[:SECTIONS].length).to be(1)
      expect(js_env[:SECTIONS][@section.id]).to match(hash_including({
                                                                       id: @section.id,
                                                                       course_id: @course.id,
                                                                       name: @section.name,
                                                                       start_at: @section.start_at,
                                                                       end_at: @section.end_at
                                                                     }))
      expect(js_env[:PACE_PLAN]).to match(hash_including({
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
      expect(js_env[:PACE_PLAN][:modules].length).to be(2)
      expect(js_env[:PACE_PLAN][:modules][0][:items].length).to be(1)
      expect(js_env[:PACE_PLAN][:modules][1][:items].length).to be(2)
      expect(js_env[:PACE_PLAN][:modules][1][:items][1]).to match(hash_including({
                                                                                   assignment_title: @a3.title,
                                                                                   module_item_type: 'Assignment',
                                                                                   duration: 4
                                                                                 }))

      expect(js_env[:PACE_PLAN_PROGRESS]).to match(hash_including({
                                                                    id: @progress.id,
                                                                    context_id: @progress.context_id,
                                                                    context_type: "PacePlan",
                                                                    tag: "pace_plan_publish",
                                                                    workflow_state: "queued"
                                                                  }))
    end

    it "does not create a pace plan if no primary pace plans are available" do
      @pace_plan.update(user_id: @student)
      expect(@course.pace_plans.count).to eq(1)
      expect(@course.pace_plans.primary).to be_empty
      get :index, params: { course_id: @course.id }
      pace_plan = @controller.instance_variable_get(:@pace_plan)
      expect(pace_plan).not_to be_nil
      expect(pace_plan.pace_plan_module_items.size).to eq(3)
      expect(@course.pace_plans.count).to eq(1)
      expect(@course.pace_plans.primary.count).to eq(0)
    end

    it "responds with not found if the pace_plans feature is disabled" do
      @course.account.disable_feature!(:pace_plans)
      assert_page_not_found do
        get :index, params: { course_id: @course.id }
      end
    end

    it "responds with not found if the enable_pace_plans setting is disabled" do
      @course.enable_pace_plans = false
      @course.save!
      assert_page_not_found do
        get :index, params: { course_id: @course.id }
      end
    end

    it "responds with forbidden if the user doesn't have authorization" do
      user_session(@student)
      get :index, params: { course_id: @course.id }
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
    it "updates the PacePlan" do
      put :update, params: { course_id: @course.id, id: @pace_plan.id, pace_plan: valid_update_params }
      expect(response).to be_successful
      expect(@pace_plan.reload.end_date.to_s).to eq(valid_update_params[:end_date])
      expect(@pace_plan.workflow_state).to eq(valid_update_params[:workflow_state])
      expect(
        @pace_plan.pace_plan_module_items.joins(:module_item).find_by(content_tags: { content_id: @a1.id }).duration
      ).to eq(valid_update_params[:pace_plan_module_items_attributes][0][:duration])
      expect(
        @pace_plan.pace_plan_module_items.joins(:module_item).find_by(content_tags: { content_id: @a2.id }).duration
      ).to eq(valid_update_params[:pace_plan_module_items_attributes][1][:duration])

      response_body = JSON.parse(response.body)
      expect(response_body["pace_plan"]["id"]).to eq(@pace_plan.id)

      # Pace plan's publish should be queued
      progress = Progress.last
      expect(progress.context).to eq(@pace_plan)
      expect(progress.workflow_state).to eq('queued')
      expect(response_body["progress"]["id"]).to eq(progress.id)
    end
  end

  describe "POST #create" do
    let(:create_params) { valid_update_params.merge(course_id: @course.id, user_id: @student.id) }

    it "creates the PacePlan and all the PacePlanModuleItems" do
      pace_plan_count_before = PacePlan.count
      pace_plan_module_item_count_before = PacePlanModuleItem.count

      post :create, params: { course_id: @course.id, pace_plan: create_params }
      expect(response).to be_successful

      expect(PacePlan.count).to eq(pace_plan_count_before + 1)
      expect(PacePlanModuleItem.count).to eq(pace_plan_module_item_count_before + 2)

      pace_plan = PacePlan.last

      response_body = JSON.parse(response.body)
      expect(response_body["pace_plan"]["id"]).to eq(pace_plan.id)

      expect(pace_plan.end_date.to_s).to eq(valid_update_params[:end_date])
      expect(pace_plan.workflow_state).to eq(valid_update_params[:workflow_state])
      expect(
        pace_plan.pace_plan_module_items.joins(:module_item).find_by(content_tags: { content_id: @a1.id }).duration
      ).to eq(valid_update_params[:pace_plan_module_items_attributes][0][:duration])
      expect(
        pace_plan.pace_plan_module_items.joins(:module_item).find_by(content_tags: { content_id: @a2.id }).duration
      ).to eq(valid_update_params[:pace_plan_module_items_attributes][1][:duration])
      expect(pace_plan.pace_plan_module_items.count).to eq(2)
      # Pace plan's publish should be queued
      progress = Progress.last
      expect(progress.context).to eq(pace_plan)
      expect(progress.workflow_state).to eq('queued')
      expect(response_body["progress"]["id"]).to eq(progress.id)
    end
  end

  describe "GET #new" do
    context "course" do
      it "returns a created pace plan if one already exists" do
        get :new, { params: { course_id: @course.id } }
        expect(response).to be_successful
        expect(JSON.parse(response.body)["pace_plan"]["id"]).to eq(@pace_plan.id)
        expect(JSON.parse(response.body)["pace_plan"]["published_at"]).not_to be_nil
      end

      it "returns an instantiated pace plan if one is not already available" do
        @pace_plan.destroy
        expect(@course.pace_plans.not_deleted.count).to eq(0)
        get :new, { params: { course_id: @course.id } }
        expect(response).to be_successful
        expect(@course.pace_plans.not_deleted.count).to eq(0)
        json_response = JSON.parse(response.body)
        expect(json_response["pace_plan"]["id"]).to eq(nil)
        expect(json_response["pace_plan"]["published_at"]).to eq(nil)
        expect(json_response["pace_plan"]["modules"].count).to eq(2)
        m1 = json_response["pace_plan"]["modules"].first
        expect(m1["items"].count).to eq(1)
        expect(m1["items"].first["duration"]).to eq(0)
        expect(m1["items"].first["published"]).to eq(true)
        m2 = json_response["pace_plan"]["modules"].second
        expect(m2["items"].count).to eq(2)
        expect(m2["items"].first["duration"]).to eq(0)
        expect(m2["items"].first["published"]).to eq(true)
        expect(m2["items"].second["duration"]).to eq(0)
        expect(m2["items"].second["published"]).to eq(true)
      end
    end

    context "course_section" do
      it "returns a draft pace plan" do
        get :new, { params: { course_id: @course.id, course_section_id: @course_section.id } }
        expect(response).to be_successful
        expect(JSON.parse(response.body)["pace_plan"]["id"]).to eq(nil)
        expect(JSON.parse(response.body)["pace_plan"]["published_at"]).to eq(nil)
      end

      it "returns an instantiated pace plan if one is not already available" do
        expect(@course.pace_plans.unpublished.for_section(@course_section).count).to eq(0)
        get :new, { params: { course_id: @course.id, course_section_id: @course_section.id } }
        expect(response).to be_successful
        expect(@course.pace_plans.unpublished.for_section(@course_section).count).to eq(0)
        json_response = JSON.parse(response.body)
        expect(json_response["pace_plan"]["id"]).to eq(nil)
        expect(json_response["pace_plan"]["published_at"]).to eq(nil)
        expect(json_response["pace_plan"]["course_section_id"]).to eq(@course_section.id)
        expect(json_response["pace_plan"]["modules"].count).to eq(2)
        m1 = json_response["pace_plan"]["modules"].first
        expect(m1["items"].count).to eq(1)
        expect(m1["items"].first["duration"]).to eq(0)
        expect(m1["items"].first["published"]).to eq(true)
        m2 = json_response["pace_plan"]["modules"].second
        expect(m2["items"].count).to eq(2)
        expect(m2["items"].first["duration"]).to eq(2)
        expect(m2["items"].first["published"]).to eq(true)
        expect(m2["items"].second["duration"]).to eq(4)
        expect(m2["items"].second["published"]).to eq(true)
      end
    end

    context "enrollment" do
      it "returns a draft pace plan" do
        get :new, { params: { course_id: @course.id, enrollment_id: @course.student_enrollments.first.id } }
        expect(response).to be_successful
        expect(JSON.parse(response.body)["pace_plan"]["id"]).to eq(nil)
        expect(JSON.parse(response.body)["pace_plan"]["published_at"]).to eq(nil)
        expect(JSON.parse(response.body)["pace_plan"]["user_id"]).to eq(@student.id)
      end

      it "returns an instantiated pace plan if one is not already available" do
        expect(@course.pace_plans.unpublished.for_user(@student).count).to eq(0)
        get :new, { params: { course_id: @course.id, enrollment_id: @student_enrollment.id } }
        expect(response).to be_successful
        expect(@course.pace_plans.unpublished.for_user(@student).count).to eq(0)
        json_response = JSON.parse(response.body)
        expect(json_response["pace_plan"]["id"]).to eq(nil)
        expect(json_response["pace_plan"]["published_at"]).to eq(nil)
        expect(json_response["pace_plan"]["user_id"]).to eq(@student.id)
        expect(json_response["pace_plan"]["modules"].count).to eq(2)
        m1 = json_response["pace_plan"]["modules"].first
        expect(m1["items"].count).to eq(1)
        expect(m1["items"].first["duration"]).to eq(0)
        expect(m1["items"].first["published"]).to eq(true)
        m2 = json_response["pace_plan"]["modules"].second
        expect(m2["items"].count).to eq(2)
        expect(m2["items"].first["duration"]).to eq(2)
        expect(m2["items"].first["published"]).to eq(true)
        expect(m2["items"].second["duration"]).to eq(4)
        expect(m2["items"].second["published"]).to eq(true)
      end
    end
  end

  describe "POST #publish" do
    it "starts a new background job to publish the pace plan" do
      post :publish, params: { course_id: @course.id, id: @pace_plan.id }
      expect(response).to be_successful
      json_response = JSON.parse(response.body)
      expect(json_response["context_type"]).to eq("PacePlan")
      expect(json_response["workflow_state"]).to eq("queued")
    end
  end
end
