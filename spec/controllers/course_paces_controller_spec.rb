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

describe CoursePacesController do
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

    @another_section = @course.course_sections.create!

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
      @account_level_blackout_date = @course.account.calendar_events.create!(
        title: "blackout dates 2",
        start_at: "2021-10-04",
        end_at: "2021-10-04",
        blackout_date: true
      )

      @calendar_event_blackout_dates = [@account_level_blackout_date,
                                        CalendarEvent.create!({
                                                                title: "blackout dates 3",
                                                                start_at: "2021-10-05",
                                                                end_at: "2021-10-05",
                                                                context: @course,
                                                                blackout_date: true
                                                              })]
      @section = @course.course_sections.first
      @first_student_enrollment = @course.enrollments.find_by(user_id: @student.id)
      @last_student_enrollment = @course.enroll_student(@student, enrollment_state: "active", section: @another_section, allow_multiple_enrollments: true)
      @progress = @course_pace.create_publish_progress
      get :index, params: { course_id: @course.id }

      expect(response).to be_successful
      expect(assigns[:js_bundles].flatten).to include(:course_paces)
      js_env = controller.js_env
      expect(js_env[:BLACKOUT_DATES]).to eq(@course.blackout_dates.as_json(include_root: false))
      expect(js_env[:CALENDAR_EVENT_BLACKOUT_DATES]).to eq(@calendar_event_blackout_dates.as_json(include_root: false))
      expect(js_env[:COURSE]).to match(hash_including({
                                                        id: @course.id,
                                                        name: @course.name,
                                                        start_at: @course.start_at,
                                                        end_at: @course.end_at
                                                      }))
      expect(js_env[:ENROLLMENTS].length).to be(1)
      # only includes the most recent enrollment of each student
      expect(js_env[:ENROLLMENTS]).not_to include(@first_student_enrollment.id)
      expect(js_env[:ENROLLMENTS]).to include(@last_student_enrollment.id)
      expect(js_env[:ENROLLMENTS][@last_student_enrollment.id]).to match(hash_including({
                                                                                          id: @last_student_enrollment.id,
                                                                                          user_id: @student.id,
                                                                                          course_id: @course.id,
                                                                                          full_name: @student.name,
                                                                                          sortable_name: @student.sortable_name
                                                                                        }))
      expect(js_env[:SECTIONS].length).to be(2)
      expect(js_env[:SECTIONS][@section.id]).to match(hash_including({
                                                                       id: @section.id,
                                                                       course_id: @course.id,
                                                                       name: @section.name,
                                                                       start_at: @section.start_at,
                                                                       end_at: @section.end_at
                                                                     }))
      expect(js_env[:SECTIONS][@another_section.id]).to match(hash_including({
                                                                               id: @another_section.id,
                                                                               course_id: @course.id,
                                                                               name: @another_section.name,
                                                                               start_at: @another_section.start_at,
                                                                               end_at: @another_section.end_at
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

    context "paces publishing" do
      before :once do
        @course1 = course_factory
        @teacher1 = User.create!
        course_with_teacher(course: @course1, user: @teacher1, active_all: true)
        @course1.update(start_at: "2021-09-30", restrict_enrollments_to_course_dates: true)
        @course1.root_account.enable_feature!(:course_paces)
        @course1.enable_course_paces = true
        @course1.save!
        @course_pace1 = course_pace_model(course: @course1)

        @course2 = course_factory
        @teacher2 = User.create!
        course_with_teacher(course: @course2, user: @teacher2, active_all: true)
        @course2.update(start_at: "2021-09-30", restrict_enrollments_to_course_dates: true)
        @course2.root_account.enable_feature!(:course_paces)
        @course2.enable_course_paces = true
        @course2.save!
        @course_pace2 = course_pace_model(course: @course2)
      end

      it "only gets paces publishing for the current course" do
        @course_pace1.create_publish_progress
        @course_pace2.create_publish_progress

        user_session(@teacher1)

        get :index, params: { course_id: @course1.id }
        expect(response).to be_successful

        js_env = controller.js_env
        expect(js_env[:PACES_PUBLISHING].length).to eq(1)
      end

      it "does not return duplicate paces publishing for the same pace context" do
        @course_pace1.create_publish_progress
        @course_pace1.create_publish_progress
        section_pace = course_pace_model(course: @course1, course_section: @course1.default_section)
        section_pace.create_publish_progress

        user_session(@teacher1)

        get :index, params: { course_id: @course1.id }
        expect(response).to be_successful

        js_env = controller.js_env
        expect(js_env[:PACES_PUBLISHING].length).to eq(2)
      end

      it "removes the progress if the enrollment is no longer active" do
        student_enrollment = @course1.enroll_student(@student, enrollment_state: "active", allow_multiple_enrollments: true)
        # Stop other publishing progresses
        Progress.where(tag: "course_pace_publish").destroy_all
        student_enrollment_pace_model(student_enrollment:).create_publish_progress
        expect(Progress.where(tag: "course_pace_publish").count).to eq(1)
        student_pace_progress = Progress.find_by(tag: "course_pace_publish")
        student_enrollment.destroy
        # The enrollment destroy queues up the course pace
        expect(Progress.where(tag: "course_pace_publish").count).to eq(2)
        expect(Progress.all).to include(student_pace_progress)
        user_session(@teacher1)

        get :index, params: { course_id: @course1.id }
        expect(response).to be_successful

        js_env = controller.js_env
        expect(js_env[:PACES_PUBLISHING].length).to eq(1)
        expect(Progress.where(tag: "course_pace_publish").count).to eq(1)
        expect(Progress.all).not_to include(student_pace_progress)
      end
    end

    context "progress" do
      it "queues up a new job using the same progress if the delayed_job_id is missing" do
        progress = @course_pace.create_publish_progress
        delayed_job = progress.delayed_job
        progress.update!(delayed_job_id: nil)
        delayed_job.destroy
        get :index, params: { course_id: @course.id }
        expect(response).to be_successful
        expect(Progress.last.id).to eq(progress.id)
        progress.reload
        expect(progress.delayed_job_id).not_to be_nil
        expect(progress.delayed_job).not_to be_nil
      end

      it "creates a new progress and job if the delayed_job is missing" do
        progress = @course_pace.create_publish_progress
        progress.delayed_job.destroy
        get :index, params: { course_id: @course.id }
        expect(response).to be_successful
        expect(progress.reload.failed?).to be_truthy
        new_progress = Progress.last
        expect(new_progress.tag).to eq("course_pace_publish")
        expect(new_progress.delayed_job_id).not_to be_nil
        expect(new_progress.delayed_job).not_to be_nil
      end

      it "starts the progress' delayed job if queued" do
        progress = @course_pace.create_publish_progress
        delayed_job = progress.delayed_job
        original_run_at = delayed_job.run_at
        get :index, params: { course_id: @course.id }
        expect(response).to be_successful
        expect(delayed_job.reload.run_at).to be < original_run_at
      end
    end
  end

  describe "GET #api_show" do
    it "renders the specified course pace" do
      get :api_show, params: { course_id: @course.id, id: @course_pace.id }
      expect(response).to be_successful
      expect(response.parsed_body["course_pace"]["id"]).to eq(@course_pace.id)
    end

    it "renders the latest progress object associated with publishing" do
      Progress.create!(context: @course_pace, tag: "course_pace_publish", workflow_state: "failed")
      Progress.create!(context: @course_pace, tag: "course_pace_publish", workflow_state: "running")

      get :api_show, params: { course_id: @course.id, id: @course_pace.id }
      expect(response).to be_successful
      expect(response.parsed_body["progress"]["workflow_state"]).to eq("running")
    end

    it "renders a nil progress object if the most recent progress was completed" do
      Progress.create!(context: @course_pace, tag: "course_pace_publish", workflow_state: "failed")
      Progress.create!(context: @course_pace, tag: "course_pace_publish", workflow_state: "completed")

      get :api_show, params: { course_id: @course.id, id: @course_pace.id }
      expect(response).to be_successful
      expect(response.parsed_body["progress"]).to be_nil
    end

    # the show api returns all the paces with their assignable module items
    # if the user deletes the underlying learning object (e.g. assignment, quiz, ...)
    # it should get removed from the course_pace_module_items and
    # no longer be in the pace. Let's test that.
    describe "learning object deletion" do
      it "handles assignments" do
        a = @course.assignments.create! name: "Del this assn", workflow_state: "active"
        @mod1.add_item id: a.id, type: "assignment"

        get :api_show, params: { course_id: @course.id, id: @course_pace.id }
        pace = response.parsed_body["course_pace"]
        expect(pace["modules"][0]["items"].any? { |item| item["assignment_title"] == "Del this assn" }).to be_truthy

        a.destroy!

        get :api_show, params: { course_id: @course.id, id: @course_pace.id }
        pace = response.parsed_body["course_pace"]
        expect(pace["modules"][0]["items"].any? { |item| item["assignment_title"] == "Del this assn" }).to be_falsey
      end

      it "handles quizzes" do
        q = @course.quizzes.create!({ title: "Del this quiz", quiz_type: "assignment" })
        q.publish
        q.save!
        @mod1.add_item(type: "quiz", id: q.id)

        get :api_show, params: { course_id: @course.id, id: @course_pace.id }
        pace = response.parsed_body["course_pace"]
        expect(pace["modules"][0]["items"].any? { |item| item["assignment_title"] == "Del this quiz" }).to be_truthy

        q.destroy!

        get :api_show, params: { course_id: @course.id, id: @course_pace.id }
        pace = response.parsed_body["course_pace"]
        expect(pace["modules"][0]["items"].any? { |item| item["assignment_title"] == "Del this quiz" }).to be_falsey
      end

      it "handles graded discussions" do
        discussion_assignment = @course.assignments.create!(title: "Del this disc", workflow_state: "active")
        d = @course.discussion_topics.create!(assignment: discussion_assignment, title: "Del this disc")
        d.publish
        @mod1.add_item id: d.id, type: "DiscussionTopic"

        get :api_show, params: { course_id: @course.id, id: @course_pace.id }
        pace = response.parsed_body["course_pace"]
        expect(pace["modules"][0]["items"].any? { |item| item["assignment_title"] == "Del this disc" }).to be_truthy

        d.destroy!

        get :api_show, params: { course_id: @course.id, id: @course_pace.id }
        pace = response.parsed_body["course_pace"]
        expect(pace["modules"][0]["items"].any? { |item| item["assignment_title"] == "Del this disc" }).to be_falsey
      end
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

      response_body = response.parsed_body
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

      response_body = response.parsed_body
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
        get :new, params: { course_id: @course.id }
        expect(response).to be_successful
        expect(response.parsed_body["course_pace"]["id"]).to eq(@course_pace.id)
        expect(response.parsed_body["course_pace"]["published_at"]).not_to be_nil
      end

      it "returns a published course pace if one already exists" do
        published_course_pace = @course_pace
        course_pace_model(course: @course, workflow_state: "unpublished", published_at: nil)
        get :new, params: { course_id: @course.id }
        expect(response).to be_successful
        expect(response.parsed_body["course_pace"]["id"]).to eq(published_course_pace.id)
        expect(response.parsed_body["course_pace"]["published_at"]).not_to be_nil
      end

      it "ignores module items with no assignments for the pace scaffold" do
        @course_pace.destroy
        p = @course.wiki_pages.create! title: "P1", workflow_state: "active"
        @mod2.add_item id: p.id, type: "page"

        get :new, params: { course_id: @course.id }
        expect(response).to be_successful
        expect(response.parsed_body["course_pace"]["modules"].second["items"].count).to eq(2)
      end

      it "returns an instantiated course pace if one is not already available" do
        @course_pace.destroy
        expect(@course.course_paces.not_deleted.count).to eq(0)
        get :new, params: { course_id: @course.id }
        expect(response).to be_successful
        expect(@course.course_paces.not_deleted.count).to eq(0)
        json_response = response.parsed_body
        expect(json_response["course_pace"]["id"]).to be_nil
        expect(json_response["course_pace"]["published_at"]).to be_nil
        expect(json_response["course_pace"]["modules"].count).to eq(2)
        m1 = json_response["course_pace"]["modules"].first
        expect(m1["items"].count).to eq(1)
        expect(m1["items"].first["duration"]).to eq(0)
        expect(m1["items"].first["published"]).to be(true)
        m2 = json_response["course_pace"]["modules"].second
        expect(m2["items"].count).to eq(2)
        expect(m2["items"].first["duration"]).to eq(0)
        expect(m2["items"].first["published"]).to be(true)
        expect(m2["items"].second["duration"]).to eq(0)
        expect(m2["items"].second["published"]).to be(true)
      end

      it "starts the progress' delayed job and returns the progress object if queued" do
        progress = @course_pace.create_publish_progress
        delayed_job = progress.delayed_job
        original_run_at = delayed_job.run_at
        get :new, params: { course_id: @course.id }
        expect(response).to be_successful
        json_response = response.parsed_body
        expect(json_response["progress"]["workflow_state"]).to eq "queued"
        expect(json_response["progress"]["context_id"]).to eq @course_pace.id
        expect(delayed_job.reload.run_at).to be < original_run_at
      end
    end

    context "course_section" do
      it "returns a draft course pace" do
        get :new, params: { course_id: @course.id, course_section_id: @course_section.id }
        expect(response).to be_successful
        expect(response.parsed_body["course_pace"]["id"]).to be_nil
        expect(response.parsed_body["course_pace"]["published_at"]).to be_nil
      end

      it "returns a published section pace if one already exists" do
        section_pace_model(section: @course_section, workflow_state: "unpublished", published_at: nil)
        publised_section_pace = section_pace_model(section: @course_section)
        get :new, params: { course_id: @course.id, course_section_id: @course_section.id }
        expect(response).to be_successful
        expect(response.parsed_body["course_pace"]["id"]).to eq(publised_section_pace.id)
        expect(response.parsed_body["course_pace"]["published_at"]).not_to be_nil
      end

      it "ignores module items with no assignments for the pace scaffold" do
        @course_pace.destroy
        p = @course.wiki_pages.create! title: "P1", workflow_state: "active"
        @mod2.add_item id: p.id, type: "page"

        get :new, params: { course_id: @course.id, course_section_id: @course_section.id }
        expect(response).to be_successful
        expect(response.parsed_body["course_pace"]["modules"].second["items"].count).to eq(2)
      end

      it "returns an instantiated course pace if one is not already available" do
        expect(@course.course_paces.unpublished.for_section(@course_section).count).to eq(0)
        get :new, params: { course_id: @course.id, course_section_id: @course_section.id }
        expect(response).to be_successful
        expect(@course.course_paces.unpublished.for_section(@course_section).count).to eq(0)
        json_response = response.parsed_body
        expect(json_response["course_pace"]["id"]).to be_nil
        expect(json_response["course_pace"]["published_at"]).to be_nil
        expect(json_response["course_pace"]["course_section_id"]).to eq(@course_section.id)
        expect(json_response["course_pace"]["modules"].count).to eq(2)
        m1 = json_response["course_pace"]["modules"].first
        expect(m1["items"].count).to eq(1)
        expect(m1["items"].first["duration"]).to eq(0)
        expect(m1["items"].first["published"]).to be(true)
        m2 = json_response["course_pace"]["modules"].second
        expect(m2["items"].count).to eq(2)
        expect(m2["items"].first["duration"]).to eq(2)
        expect(m2["items"].first["published"]).to be(true)
        expect(m2["items"].second["duration"]).to eq(4)
        expect(m2["items"].second["published"]).to be(true)
      end
    end

    context "enrollment" do
      it "returns a draft course pace" do
        get :new, params: { course_id: @course.id, enrollment_id: @student_enrollment.id }
        expect(response).to be_successful
        expect(response.parsed_body["course_pace"]["id"]).to be_nil
        expect(response.parsed_body["course_pace"]["published_at"]).to be_nil
        expect(response.parsed_body["course_pace"]["user_id"]).to eq(@student.id)
      end

      it "returns a published student pace if one already exists" do
        student_enrollment_pace_model(student_enrollment: @student_enrollment, workflow_state: "unpublished", published_at: nil)
        publised_section_pace = student_enrollment_pace_model(student_enrollment: @student_enrollment)
        get :new, params: { course_id: @course.id, enrollment_id: @student_enrollment.id }
        expect(response).to be_successful
        expect(response.parsed_body["course_pace"]["id"]).to eq(publised_section_pace.id)
        expect(response.parsed_body["course_pace"]["published_at"]).not_to be_nil
      end

      it "ignores module items with no assignments for the pace scaffold" do
        @course_pace.destroy
        p = @course.wiki_pages.create! title: "P1", workflow_state: "active"
        @mod2.add_item id: p.id, type: "page"

        get :new, params: { course_id: @course.id, enrollment_id: @course.student_enrollments.first.id }
        expect(response).to be_successful
        expect(response.parsed_body["course_pace"]["modules"].second["items"].count).to eq(2)
      end

      it "returns an instantiated section pace if one is already published and the user is in that section" do
        @course_section.enrollments << @student_enrollment
        course_section_pace = course_pace_model(course: @course, course_section: @course_section)
        course_section_pace.publish
        get :new, params: { course_id: @course.id, enrollment_id: @student_enrollment.id }
        expect(response).to be_successful
        json_response = response.parsed_body
        expect(json_response["course_pace"]["id"]).to be_nil
        expect(json_response["course_pace"]["published_at"]).to be_nil
        expect(json_response["course_pace"]["section_id"]).to be_nil
        expect(json_response["course_pace"]["user_id"]).to eq(@student.id)
        m1 = json_response["course_pace"]["modules"].first
        expect(m1["items"].count).to eq(1)
        expect(m1["items"].first["duration"]).to eq(0)
        expect(m1["items"].first["published"]).to be(true)
        m2 = json_response["course_pace"]["modules"].second
        expect(m2["items"].count).to eq(2)
        expect(m2["items"].first["duration"]).to eq(0)
        expect(m2["items"].first["published"]).to be(true)
        expect(m2["items"].second["duration"]).to eq(0)
        expect(m2["items"].second["published"]).to be(true)
      end

      it "returns an instantiated course pace if one is not already available" do
        expect(@course.course_paces.unpublished.for_user(@student).count).to eq(0)
        get :new, params: { course_id: @course.id, enrollment_id: @student_enrollment.id }
        expect(response).to be_successful
        expect(@course.course_paces.unpublished.for_user(@student).count).to eq(0)
        json_response = response.parsed_body
        expect(json_response["course_pace"]["id"]).to be_nil
        expect(json_response["course_pace"]["published_at"]).to be_nil
        expect(json_response["course_pace"]["user_id"]).to eq(@student.id)
        expect(json_response["course_pace"]["modules"].count).to eq(2)
        m1 = json_response["course_pace"]["modules"].first
        expect(m1["items"].count).to eq(1)
        expect(m1["items"].first["duration"]).to eq(0)
        expect(m1["items"].first["published"]).to be(true)
        m2 = json_response["course_pace"]["modules"].second
        expect(m2["items"].count).to eq(2)
        expect(m2["items"].first["duration"]).to eq(2)
        expect(m2["items"].first["published"]).to be(true)
        expect(m2["items"].second["duration"]).to eq(4)
        expect(m2["items"].second["published"]).to be(true)
      end

      context "when the user is on another shard" do
        specs_require_sharding

        before :once do
          @shard2.activate do
            @student2 = user_factory(active_all: true)
          end
        end

        it "still creates the individual pace" do
          @course_pace.update!(hard_end_dates: false)
          enrollment = course_with_student(course: @course, user: @student2, active_all: true)
          get :new, params: { course_id: @course.id, enrollment_id: enrollment.id }
          expect(response).to be_successful
        end
      end
    end
  end

  describe "POST #publish" do
    it "starts a new background job to publish the course pace" do
      post :publish, params: { course_id: @course.id, id: @course_pace.id }
      expect(response).to be_successful
      json_response = response.parsed_body
      expect(json_response["context_type"]).to eq("CoursePace")
      expect(json_response["workflow_state"]).to eq("queued")
    end

    it "emits course_pacing.publishing.count_exceeding_limit to statsd when pace publishing processes exceeded limit" do
      allow(InstStatsd::Statsd).to receive(:count).and_call_original
      stub_const("CoursePacesController::COURSE_PACES_PUBLISHING_LIMIT", 5)

      Progress.destroy_all
      6.times do
        pace = course_pace_model(course: @course, course_section: @course.course_sections.create!)
        pace.create_publish_progress(run_at: Time.now)
      end

      post :publish, params: { course_id: @course.id, id: @course_pace.id }
      expect(InstStatsd::Statsd).to have_received(:count).with("course_pacing.publishing.count_exceeding_limit", 6)
    end
  end

  describe "POST #compress_dates" do
    it "returns a compressed list of dates" do
      course_pace_params = @valid_params.merge(end_date: @course_pace.start_date + 5.days)
      post :compress_dates, params: { course_id: @course.id, course_pace: course_pace_params }
      expect(response).to be_successful
      json_response = response.parsed_body
      expect(json_response.values).to eq(%w[2021-09-30 2021-10-05])
    end

    it "supports changing durations and start dates" do
      course_pace_params = @valid_params.merge(start_date: "2021-11-01", end_date: "2021-11-05")
      post :compress_dates, params: { course_id: @course.id, course_pace: course_pace_params }
      expect(response).to be_successful
      json_response = response.parsed_body
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
      json_response = response.parsed_body
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
      json_response = response.parsed_body
      expect(json_response.values).to eq(%w[2021-12-22 2021-12-28 2022-01-05 2022-01-12])
    end

    it "returns an error if the start date is after the end date" do
      course_pace_params = @valid_params.merge(start_date: "2022-01-27", end_date: "2022-01-20")
      post :compress_dates, params: { course_id: @course.id, course_pace: course_pace_params }
      expect(response).not_to be_successful
      json_response = response.parsed_body
      expect(json_response["errors"]).to eq("End date cannot be before start date")
    end

    it "returns uncompressed items if the end date is not set" do
      course_pace_params = @valid_params.merge(start_date: "2022-01-27", end_date: nil)
      post :compress_dates, params: { course_id: @course.id, course_pace: course_pace_params }
      expect(response).to be_successful
      json_response = response.parsed_body
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
        course_pace_module_items_attributes:
      )
      post :compress_dates, params: { course_id: @course.id, course_pace: course_pace_params }
      expect(response).to be_successful
      json_response = response.parsed_body
      expect(json_response.keys).to eq(course_pace_module_items_attributes.map { |i| i[:module_item_id].to_s })
    end

    it "prefers incoming blackout dates over what is already on the course" do
      # course starts at 2021-09-30
      course_pace_params = @valid_params.merge(end_date: @course_pace.start_date + 5.days)
      post :compress_dates, params: { course_id: @course.id,
                                      course_pace: course_pace_params,
                                      blackout_dates: [
                                        {
                                          event_title: "blackout dates 2",
                                          start_date: "2021-09-30", # thurs
                                          end_date: "2021-10-01" # fri
                                        }
                                      ] }
      expect(response).to be_successful
      json_response = response.parsed_body
      # skip the weekend, then due dates are mon and tues
      expect(json_response.values).to eq(%w[2021-10-04 2021-10-05])
    end
  end

  describe "DELETE #destroy" do
    it "requires the redesign feature flag" do
      delete :destroy, params: { course_id: @course.id, id: @course_pace.id }
      expect(response).not_to be_successful
      expect(response.code).to eq(404.to_s)
    end

    context "with the redesign feature flag" do
      before do
        Account.site_admin.enable_feature!(:course_paces_redesign)
      end

      it "deletes the pace" do
        section_pace = course_pace_model(course: @course, course_section: @course_section)
        delete :destroy, params: { course_id: @course.id, id: section_pace.id }
        expect(response).to be_successful
        expect(section_pace.reload.deleted?).to be(true)
      end

      it "does not allow deleting the published default course pace" do
        delete :destroy, params: { course_id: @course.id, id: @course_pace.id }
        expect(response).not_to be_successful
        json_response = response.parsed_body
        expect(@course_pace.reload.deleted?).not_to be(true)
        expect(json_response["errors"]).to eq("You cannot delete the default course pace.")
      end

      it "does not increment when the course pace delete api endpoint is called" do
        allow(InstStatsd::Statsd).to receive(:increment).and_call_original

        delete :destroy, params: { course_id: @course.id, id: @course_pace.id }
        expect(InstStatsd::Statsd).not_to have_received(:increment).with("course_pacing.deleted_course_pace")
      end

      context "with fallback paces" do
        before do
          Setting.set("course_pace_publish_interval", "0") # run publishes immediately
          @default_pace = @course_pace
          @default_pace_published_at = @default_pace.published_at
          @section_pace = course_pace_model(course: @course, course_section: @course_section)
          @section_pace_published_at = @section_pace.published_at
          @another_section_pace = course_pace_model(course: @course, course_section: @another_section)
          @another_section_pace_published_at = @another_section_pace.published_at
        end

        it "publishes the default pace if the enrollments don't have another pace" do
          delete :destroy, params: { course_id: @course.id, id: @section_pace.id }
          expect(response).to be_successful
          run_jobs
          expect(@section_pace.reload.deleted?).to be(true)
          expect(@default_pace.reload.published_at).to be > (@default_pace_published_at)
        end

        it "does not publish the default pace if the pace was not originally published" do
          @section_pace.update(workflow_state: "unpublished")

          delete :destroy, params: { course_id: @course.id, id: @section_pace.id }
          expect(response).to be_successful
          run_jobs
          expect(@section_pace.reload.deleted?).to be(true)
          expect(@default_pace.reload.published_at).to eq(@default_pace_published_at)
        end

        it "publishes another section pace if the enrollments are in two sections with paces" do
          student_in_section(@another_section, user: @student, allow_multiple_enrollments: true)
          student_in_section(@course_section, user: @student, allow_multiple_enrollments: true)

          delete :destroy, params: { course_id: @course.id, id: @section_pace.id }
          expect(response).to be_successful
          run_jobs
          expect(@section_pace.reload.deleted?).to be(true)
          expect(@default_pace.reload.published_at).to eq(@default_pace_published_at)
          expect(@another_section_pace.reload.published_at).to be > (@another_section_pace_published_at)
        end

        it "publishes the section pace if the student pace is deleted and the student is in a section with a pace" do
          student_enrollment_pace = course_pace_model(course: @course, user: @student)

          delete :destroy, params: { course_id: @course.id, id: student_enrollment_pace.id }
          expect(response).to be_successful
          run_jobs
          expect(student_enrollment_pace.reload.deleted?).to be(true)
          expect(@default_pace.reload.published_at).to eq(@default_pace_published_at)
          expect(@section_pace.reload.published_at).to be > (@section_pace_published_at)
        end

        it "publishes the default pace if a student pace is deleted and the student is not in a section with a pace" do
          @section_pace.destroy
          student_enrollment_pace = course_pace_model(course: @course, user: @student)

          delete :destroy, params: { course_id: @course.id, id: student_enrollment_pace.id }
          expect(response).to be_successful
          run_jobs
          expect(student_enrollment_pace.reload.deleted?).to be(true)
          expect(@default_pace.reload.published_at).to be > @default_pace_published_at
        end

        it "publishes multiple paces if the enrollments belong to sections with paces and enrollments without when a section pace is deleted" do
          another_student = user_factory(active_all: true)
          student_in_section(@another_section, user: another_student, allow_multiple_enrollments: true)
          student_in_section(@course_section, user: another_student, allow_multiple_enrollments: true)
          student_in_section(@course_section, user: @student, allow_multiple_enrollments: true)

          delete :destroy, params: { course_id: @course.id, id: @section_pace.id }
          expect(response).to be_successful
          run_jobs
          expect(@section_pace.reload.deleted?).to be(true)
          expect(@default_pace.reload.published_at).to be > (@default_pace_published_at)
          expect(@another_section_pace.reload.published_at).to be > (@another_section_pace_published_at)
        end
      end
    end
  end
end
