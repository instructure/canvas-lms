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

describe CoursePacesController, type: :controller do
  let(:valid_update_params) do
    {
      hard_end_dates: true,
      end_date: 1.year.from_now.strftime("%Y-%m-%d"),
      workflow_state: "active",
      course_pace_module_items_attributes: [
        {
          id: @course_pace.course_pace_module_items.first.id,
          module_item_id: @course_pace.course_pace_module_items.first.module_item_id,
          duration: 1,
        },
        {
          id: @course_pace.course_pace_module_items.second.id,
          module_item_id: @course_pace.course_pace_module_items.second.module_item_id,
          duration: 10,
        },
      ],
    }
  end

  before :once do
    course_with_teacher(active_all: true)
    @course.update(start_at: "2021-09-30", restrict_enrollments_to_course_dates: true)
    @course.root_account.enable_feature!(:course_paces)
    @course.enable_course_paces = true
    @course.save!
    student_in_course(active_all: true)
    course_pace_model(course: @course)
    @student_enrollment = @student.enrollments.first

    @mod1 = @course.context_modules.create! name: "M1"
    @a1 = @course.assignments.create! name: "A1", workflow_state: "active"
    @mod1.add_item id: @a1.id, type: "assignment"

    @mod2 = @course.context_modules.create! name: "M2"
    @a2 = @course.assignments.create! name: "A2", workflow_state: "published"
    @mod2.add_item id: @a2.id, type: "assignment"
    @a3 = @course.assignments.create! name: "A3", workflow_state: "published"
    @mod2.add_item id: @a3.id, type: "assignment"
    @mod2.add_item type: "external_url", title: "External URL", url: "http://localhost"

    @course_pace.course_pace_module_items.each_with_index do |ppmi, i|
      ppmi.update! duration: i * 2
    end

    @course.enable_course_paces = true
    @course.blackout_dates = [BlackoutDate.new({
                                                 event_title: "blackout dates 1",
                                                 start_date: "2021-10-03",
                                                 end_date: "2021-10-03"
                                               })]
    @course.save!
    @course.account.enable_feature!(:course_paces)

    @course_section = @course.course_sections.first

    @valid_params = {
      hard_end_dates: true,
      end_date: 1.year.from_now.strftime("%Y-%m-%d"),
      workflow_state: "active",
      course_pace_module_items_attributes: [
        {
          id: @course_pace.course_pace_module_items.first.id,
          module_item_id: @course_pace.course_pace_module_items.first.module_item_id,
          duration: 1,
        },
        {
          id: @course_pace.course_pace_module_items.second.id,
          module_item_id: @course_pace.course_pace_module_items.second.module_item_id,
          duration: 10,
        },
      ],
    }
  end

  before do
    user_session(@teacher)
  end

  describe "GET #index" do
    it "populates js_env with course, enrollment, sections, blackout_dates, and course_pace details" do
      @section = @course.course_sections.first
      @student_enrollment = @course.enrollments.find_by(user_id: @student.id)
      @progress = @course_pace.create_publish_progress
      get :index, { params: { course_id: @course.id } }

      expect(response).to be_successful
      expect(assigns[:js_bundles].flatten).to include(:course_paces)
      js_env = controller.js_env
      expect(js_env[:BLACKOUT_DATES]).to eq(@course.blackout_dates.as_json(include_root: false))
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
      expect(js_env[:COURSE_PACE]).to match(hash_including({
                                                             id: @course_pace.id,
                                                             course_id: @course.id,
                                                             course_section_id: nil,
                                                             user_id: nil,
                                                             workflow_state: "active",
                                                             exclude_weekends: true,
                                                             hard_end_dates: true,
                                                             context_id: @course.id,
                                                             context_type: "Course"
                                                           }))
      expect(js_env[:COURSE_PACE][:modules].length).to be(2)
      expect(js_env[:COURSE_PACE][:modules][0][:items].length).to be(1)
      expect(js_env[:COURSE_PACE][:modules][1][:items].length).to be(2)
      expect(js_env[:COURSE_PACE][:modules][1][:items][1]).to match(hash_including({
                                                                                     assignment_title: @a3.title,
                                                                                     module_item_type: "Assignment",
                                                                                     duration: 4
                                                                                   }))

      expect(js_env[:COURSE_PACE_PROGRESS]).to match(hash_including({
                                                                      id: @progress.id,
                                                                      context_id: @progress.context_id,
                                                                      context_type: "CoursePace",
                                                                      tag: "course_pace_publish",
                                                                      workflow_state: "queued"
                                                                    }))
    end

    it "does not create a course pace if no primary course paces are available" do
      @course_pace.update(user_id: @student)
      expect(@course.course_paces.count).to eq(1)
      expect(@course.course_paces.primary).to be_empty
      get :index, params: { course_id: @course.id }
      course_pace = @controller.instance_variable_get(:@course_pace)
      expect(course_pace).not_to be_nil
      expect(course_pace.course_pace_module_items.size).to eq(3)
      expect(@course.course_paces.count).to eq(1)
      expect(@course.course_paces.primary.count).to eq(0)
    end

    it "responds with not found if the course_paces feature is disabled" do
      @course.account.disable_feature!(:course_paces)
      assert_page_not_found do
        get :index, params: { course_id: @course.id }
      end
    end

    it "responds with not found if the enable_course_paces setting is disabled" do
      @course.enable_course_paces = false
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

    context "progress" do
      it "starts the progress' delayed job if queued" do
        progress = @course_pace.create_publish_progress
        delayed_job = progress.delayed_job
        original_run_at = delayed_job.run_at
        get :index, { params: { course_id: @course.id } }
        expect(response).to be_successful
        expect(delayed_job.reload.run_at).to be < original_run_at
      end
    end
  end

  describe "GET #api_show" do
    it "renders the specified course pace" do
      get :api_show, params: { course_id: @course.id, id: @course_pace.id }
      expect(response).to be_successful
      expect(JSON.parse(response.body)["course_pace"]["id"]).to eq(@course_pace.id)
    end

    it "renders the latest progress object associated with publishing" do
      Progress.create!(context: @course_pace, tag: "course_pace_publish", workflow_state: "failed")
      Progress.create!(context: @course_pace, tag: "course_pace_publish", workflow_state: "running")

      get :api_show, params: { course_id: @course.id, id: @course_pace.id }
      expect(response).to be_successful
      expect(JSON.parse(response.body)["progress"]["workflow_state"]).to eq("running")
    end

    it "renders a nil progress object if the most recent progress was completed" do
      Progress.create!(context: @course_pace, tag: "course_pace_publish", workflow_state: "failed")
      Progress.create!(context: @course_pace, tag: "course_pace_publish", workflow_state: "completed")

      get :api_show, params: { course_id: @course.id, id: @course_pace.id }
      expect(response).to be_successful
      expect(JSON.parse(response.body)["progress"]).to be_nil
    end
  end

  describe "PUT #update" do
    it "updates the CoursePace" do
      put :update, params: { course_id: @course.id, id: @course_pace.id, course_pace: valid_update_params }
      expect(response).to be_successful
      expect(@course_pace.reload.end_date.to_date.to_s).to eq(valid_update_params[:end_date])
      expect(@course_pace.workflow_state).to eq(valid_update_params[:workflow_state])
      expect(
        @course_pace.course_pace_module_items.joins(:module_item).find_by(content_tags: { content_id: @a1.id }).duration
      ).to eq(valid_update_params[:course_pace_module_items_attributes][0][:duration])
      expect(
        @course_pace.course_pace_module_items.joins(:module_item).find_by(content_tags: { content_id: @a2.id }).duration
      ).to eq(valid_update_params[:course_pace_module_items_attributes][1][:duration])

      response_body = JSON.parse(response.body)
      expect(response_body["course_pace"]["id"]).to eq(@course_pace.id)

      # Course pace's publish should be queued
      progress = Progress.last
      expect(progress.context).to eq(@course_pace)
      expect(progress.workflow_state).to eq("queued")
      expect(response_body["progress"]["id"]).to eq(progress.id)
    end
  end

  describe "POST #create" do
    let(:create_params) { valid_update_params.merge(course_id: @course.id, user_id: @student.id) }

    it "creates the CoursePace and all the CoursePaceModuleItems" do
      course_pace_count_before = CoursePace.count
      course_pace_module_item_count_before = CoursePaceModuleItem.count

      post :create, params: { course_id: @course.id, course_pace: create_params }
      expect(response).to be_successful

      expect(CoursePace.count).to eq(course_pace_count_before + 1)
      expect(CoursePaceModuleItem.count).to eq(course_pace_module_item_count_before + 2)

      course_pace = CoursePace.last

      response_body = JSON.parse(response.body)
      expect(response_body["course_pace"]["id"]).to eq(course_pace.id)

      expect(course_pace.end_date.to_date.to_s).to eq(valid_update_params[:end_date])
      expect(course_pace.workflow_state).to eq(valid_update_params[:workflow_state])
      expect(
        course_pace.course_pace_module_items.joins(:module_item).find_by(content_tags: { content_id: @a1.id }).duration
      ).to eq(valid_update_params[:course_pace_module_items_attributes][0][:duration])
      expect(
        course_pace.course_pace_module_items.joins(:module_item).find_by(content_tags: { content_id: @a2.id }).duration
      ).to eq(valid_update_params[:course_pace_module_items_attributes][1][:duration])
      expect(course_pace.course_pace_module_items.count).to eq(2)
      # Course pace's publish should be queued
      progress = Progress.last
      expect(progress.context).to eq(course_pace)
      expect(progress.workflow_state).to eq("queued")
      expect(response_body["progress"]["id"]).to eq(progress.id)
    end
  end

  describe "GET #new" do
    context "course" do
      it "returns a created course pace if one already exists" do
        get :new, { params: { course_id: @course.id } }
        expect(response).to be_successful
        expect(JSON.parse(response.body)["course_pace"]["id"]).to eq(@course_pace.id)
        expect(JSON.parse(response.body)["course_pace"]["published_at"]).not_to be_nil
      end

      it "returns an instantiated course pace if one is not already available" do
        @course_pace.destroy
        expect(@course.course_paces.not_deleted.count).to eq(0)
        get :new, { params: { course_id: @course.id } }
        expect(response).to be_successful
        expect(@course.course_paces.not_deleted.count).to eq(0)
        json_response = JSON.parse(response.body)
        expect(json_response["course_pace"]["id"]).to eq(nil)
        expect(json_response["course_pace"]["published_at"]).to eq(nil)
        expect(json_response["course_pace"]["modules"].count).to eq(2)
        m1 = json_response["course_pace"]["modules"].first
        expect(m1["items"].count).to eq(1)
        expect(m1["items"].first["duration"]).to eq(0)
        expect(m1["items"].first["published"]).to eq(true)
        m2 = json_response["course_pace"]["modules"].second
        expect(m2["items"].count).to eq(2)
        expect(m2["items"].first["duration"]).to eq(0)
        expect(m2["items"].first["published"]).to eq(true)
        expect(m2["items"].second["duration"]).to eq(0)
        expect(m2["items"].second["published"]).to eq(true)
      end
    end

    context "course_section" do
      it "returns a draft course pace" do
        get :new, { params: { course_id: @course.id, course_section_id: @course_section.id } }
        expect(response).to be_successful
        expect(JSON.parse(response.body)["course_pace"]["id"]).to eq(nil)
        expect(JSON.parse(response.body)["course_pace"]["published_at"]).to eq(nil)
      end

      it "returns an instantiated course pace if one is not already available" do
        expect(@course.course_paces.unpublished.for_section(@course_section).count).to eq(0)
        get :new, { params: { course_id: @course.id, course_section_id: @course_section.id } }
        expect(response).to be_successful
        expect(@course.course_paces.unpublished.for_section(@course_section).count).to eq(0)
        json_response = JSON.parse(response.body)
        expect(json_response["course_pace"]["id"]).to eq(nil)
        expect(json_response["course_pace"]["published_at"]).to eq(nil)
        expect(json_response["course_pace"]["course_section_id"]).to eq(@course_section.id)
        expect(json_response["course_pace"]["modules"].count).to eq(2)
        m1 = json_response["course_pace"]["modules"].first
        expect(m1["items"].count).to eq(1)
        expect(m1["items"].first["duration"]).to eq(0)
        expect(m1["items"].first["published"]).to eq(true)
        m2 = json_response["course_pace"]["modules"].second
        expect(m2["items"].count).to eq(2)
        expect(m2["items"].first["duration"]).to eq(2)
        expect(m2["items"].first["published"]).to eq(true)
        expect(m2["items"].second["duration"]).to eq(4)
        expect(m2["items"].second["published"]).to eq(true)
      end
    end

    context "enrollment" do
      it "returns a draft course pace" do
        get :new, { params: { course_id: @course.id, enrollment_id: @course.student_enrollments.first.id } }
        expect(response).to be_successful
        expect(JSON.parse(response.body)["course_pace"]["id"]).to eq(nil)
        expect(JSON.parse(response.body)["course_pace"]["published_at"]).to eq(nil)
        expect(JSON.parse(response.body)["course_pace"]["user_id"]).to eq(@student.id)
      end

      it "returns an instantiated course pace if one is not already available" do
        expect(@course.course_paces.unpublished.for_user(@student).count).to eq(0)
        get :new, { params: { course_id: @course.id, enrollment_id: @student_enrollment.id } }
        expect(response).to be_successful
        expect(@course.course_paces.unpublished.for_user(@student).count).to eq(0)
        json_response = JSON.parse(response.body)
        expect(json_response["course_pace"]["id"]).to eq(nil)
        expect(json_response["course_pace"]["published_at"]).to eq(nil)
        expect(json_response["course_pace"]["user_id"]).to eq(@student.id)
        expect(json_response["course_pace"]["modules"].count).to eq(2)
        m1 = json_response["course_pace"]["modules"].first
        expect(m1["items"].count).to eq(1)
        expect(m1["items"].first["duration"]).to eq(0)
        expect(m1["items"].first["published"]).to eq(true)
        m2 = json_response["course_pace"]["modules"].second
        expect(m2["items"].count).to eq(2)
        expect(m2["items"].first["duration"]).to eq(2)
        expect(m2["items"].first["published"]).to eq(true)
        expect(m2["items"].second["duration"]).to eq(4)
        expect(m2["items"].second["published"]).to eq(true)
      end
    end
  end

  describe "POST #publish" do
    it "starts a new background job to publish the course pace" do
      post :publish, params: { course_id: @course.id, id: @course_pace.id }
      expect(response).to be_successful
      json_response = JSON.parse(response.body)
      expect(json_response["context_type"]).to eq("CoursePace")
      expect(json_response["workflow_state"]).to eq("queued")
    end
  end

  describe "POST #compress_dates" do
    it "returns a compressed list of dates" do
      course_pace_params = @valid_params.merge(end_date: @course_pace.start_date + 5.days)
      post :compress_dates, params: { course_id: @course.id, course_pace: course_pace_params }
      expect(response).to be_successful
      json_response = JSON.parse(response.body)
      expect(json_response.values).to eq(%w[2021-09-30 2021-10-05])
    end

    it "supports changing durations and start dates" do
      course_pace_params = @valid_params.merge(start_date: "2021-11-01", end_date: "2021-11-05")
      post :compress_dates, params: { course_id: @course.id, course_pace: course_pace_params }
      expect(response).to be_successful
      json_response = JSON.parse(response.body)
      expect(json_response.values).to eq(%w[2021-11-01 2021-11-05])
    end

    it "squishes proportionally and ends on the end date" do
      course_pace_params = @valid_params.merge(
        start_date: "2021-12-27",
        end_date: "2021-12-31",
        course_pace_module_items_attributes: [
          {
            id: @course_pace.course_pace_module_items.first.id,
            module_item_id: @course_pace.course_pace_module_items.first.module_item_id,
            duration: 2,
          },
          {
            id: @course_pace.course_pace_module_items.second.id,
            module_item_id: @course_pace.course_pace_module_items.second.module_item_id,
            duration: 4,
          },
          {
            id: @course_pace.course_pace_module_items.third.id,
            module_item_id: @course_pace.course_pace_module_items.third.module_item_id,
            duration: 6,
          },
        ]
      )

      post :compress_dates, params: { course_id: @course.id, course_pace: course_pace_params }
      expect(response).to be_successful
      json_response = JSON.parse(response.body)
      expect(json_response.values).to eq(%w[2021-12-28 2021-12-29 2021-12-31])
    end

    it "rolls over years properly" do
      assignment = @course.assignments.create! name: "A4", workflow_state: "active"
      @mod1.add_item id: assignment.id, type: "assignment"
      tag = @mod1.add_item id: assignment.id, type: "assignment"
      @course_pace.course_pace_module_items.create! module_item: tag, duration: 8

      course_pace_params = @valid_params.merge(
        start_date: "2021-12-13",
        end_date: "2022-01-12",
        exclude_weekends: true,
        course_pace_module_items_attributes: [
          {
            id: @course_pace.course_pace_module_items.first.id,
            module_item_id: @course_pace.course_pace_module_items.first.module_item_id,
            duration: 7,
          },
          {
            id: @course_pace.course_pace_module_items.second.id,
            module_item_id: @course_pace.course_pace_module_items.second.module_item_id,
            duration: 6,
          },
          {
            id: @course_pace.course_pace_module_items.third.id,
            module_item_id: @course_pace.course_pace_module_items.third.module_item_id,
            duration: 5,
          },
          {
            id: @course_pace.course_pace_module_items.third.id,
            module_item_id: @course_pace.course_pace_module_items.fourth.module_item_id,
            duration: 5,
          },
        ]
      )

      post :compress_dates, params: { course_id: @course.id, course_pace: course_pace_params }
      expect(response).to be_successful
      json_response = JSON.parse(response.body)
      expect(json_response.values).to eq(%w[2021-12-22 2021-12-28 2022-01-05 2022-01-12])
    end

    it "returns an error if the start date is after the end date" do
      course_pace_params = @valid_params.merge(start_date: "2022-01-27", end_date: "2022-01-20")
      post :compress_dates, params: { course_id: @course.id, course_pace: course_pace_params }
      expect(response).not_to be_successful
      json_response = JSON.parse(response.body)
      expect(json_response["errors"]).to eq("End date cannot be before start date")
    end

    it "returns uncompressed items if the end date is not set" do
      course_pace_params = @valid_params.merge(start_date: "2022-01-27", end_date: nil)
      post :compress_dates, params: { course_id: @course.id, course_pace: course_pace_params }
      expect(response).to be_successful
      json_response = JSON.parse(response.body)
      expect(json_response.values).to eq(%w[2022-01-28 2022-02-11])
    end

    it "returns the dates in the correct order" do
      @mod3 = @course.context_modules.create! name: "M3"
      2.times do |i|
        assignment = @course.assignments.create! name: i, workflow_state: "published"
        @mod3.add_item id: assignment.id, type: "assignment"
      end

      course_pace_module_items_attributes = @course_pace.course_pace_module_items.order(:id).map do |ppmi|
        {
          id: ppmi.id,
          module_item_id: ppmi.module_item_id,
          duration: 1
        }
      end

      course_pace_params = @valid_params.merge(
        start_date: "2021-11-01",
        end_date: "2021-11-06",
        course_pace_module_items_attributes: course_pace_module_items_attributes
      )
      post :compress_dates, params: { course_id: @course.id, course_pace: course_pace_params }
      expect(response).to be_successful
      json_response = JSON.parse(response.body)
      expect(json_response.keys).to eq(course_pace_module_items_attributes.map { |i| i[:module_item_id].to_s })
    end
  end
end
