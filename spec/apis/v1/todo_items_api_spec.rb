# frozen_string_literal: true

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

require_relative "../api_spec_helper"

describe UsersController, type: :request do
  include Api
  include Api::V1::Assignment
  def update_assignment_json
    @a1_json["assignment"] = controller.assignment_json(@a1, @user, session, include_all_dates: true).as_json
    @a2_json["assignment"] = controller.assignment_json(@a2, @user, session, include_all_dates: true).as_json
  end

  def strip_secure_params(json)
    json["assignment"].delete("secure_params")
    json
  end

  before :once do
    course_with_teacher(active_all: true, course_name: "Teacher Course", user: user_with_pseudonym(active_all: true))
    @teacher_course = @course
    @student_course = course_factory(active_course: true, course_name: "Student Course")
    @student_course.enroll_student(@user).accept!
    # an assignment i need to submit (needs_submitting)
    @a1 = Assignment.create!(context: @student_course, due_at: 6.days.from_now, title: "required work", submission_types: "online_text_entry", points_possible: 10)

    # an assignment i created, and a student who submits the assignment (needs_grading)
    @a2 = Assignment.create!(context: @teacher_course, due_at: 1.day.from_now, title: "text", submission_types: "online_text_entry", points_possible: 15)
    @me = @user
    student = user_factory(active_all: true)
    @user = @me
    @teacher_course.enroll_student(student).accept!
    @sub = @a2.reload.submit_homework(student, submission_type: "online_text_entry", body: "done")
    @a2.reload
  end

  before do
    @a1_json =
      {
        "type" => "submitting",
        "assignment" => {},
        "ignore" => api_v1_users_todo_ignore_url(@a1.asset_string, "submitting", permanent: 0),
        "ignore_permanently" => api_v1_users_todo_ignore_url(@a1.asset_string, "submitting", permanent: 1),
        "html_url" => "#{course_assignment_url(@a1.context_id, @a1.id)}#submit",
        "context_type" => "Course",
        "context_name" => "Student Course",
        "course_id" => @student_course.id,
      }
    @a2_json =
      {
        "type" => "grading",
        "assignment" => {},
        "needs_grading_count" => 1,
        "ignore" => api_v1_users_todo_ignore_url(@a2.asset_string, "grading", permanent: 0),
        "ignore_permanently" => api_v1_users_todo_ignore_url(@a2.asset_string, "grading", permanent: 1),
        "html_url" => speed_grader_course_gradebook_url(@a2.context_id, assignment_id: @a2.id),
        "context_type" => "Course",
        "context_name" => "Teacher Course",
        "course_id" => @teacher_course.id,
      }
  end

  def another_submission
    @me = @user
    student2 = user_factory(active_all: true)
    @user = @me
    @teacher_course.enroll_student(student2).accept!
    @sub2 = @a2.reload.submit_homework(student2,
                                       submission_type: "online_text_entry",
                                       body: "me too")
    @a2.reload
  end

  it "checks for auth" do
    get("/api/v1/users/self/todo")
    assert_status(401)

    @course = factory_with_protected_attributes(Course, course_valid_attributes)
    raw_api_call(:get,
                 "/api/v1/courses/#{@course.id}/todo",
                 controller: "courses",
                 action: "todo_items",
                 format: "json",
                 course_id: @course.to_param)
    assert_status(401)
  end

  it "returns a global user todo list" do
    json = api_call(:get,
                    "/api/v1/users/self/todo",
                    controller: "users",
                    action: "todo_items",
                    format: "json")
    update_assignment_json
    json = json.sort_by { |t| t["assignment"]["id"] }
    expect(strip_secure_params(json.first)).to eq strip_secure_params(@a1_json)
    expect(strip_secure_params(json.second)).to eq strip_secure_params(@a2_json)
  end

  it "returns a course-specific todo list for a student" do
    json = api_call(:get,
                    "/api/v1/courses/#{@student_course.id}/todo",
                    controller: "courses",
                    action: "todo_items",
                    format: "json",
                    course_id: @student_course.to_param)
           .first

    update_assignment_json
    expect(strip_secure_params(json)).to eq strip_secure_params(@a1_json)
  end

  it "returns a course-specific todo list for a teacher" do
    json = api_call(:get,
                    "/api/v1/courses/#{@teacher_course.id}/todo",
                    controller: "courses",
                    action: "todo_items",
                    format: "json",
                    course_id: @teacher_course.to_param)
           .first
    update_assignment_json
    expect(strip_secure_params(json)).to eq strip_secure_params(@a2_json)
  end

  it "returns a list for users who are both teachers and students" do
    @student_course.enroll_teacher(@user)
    @teacher_course.enroll_student(@user)
    json = api_call(:get,
                    "/api/v1/users/self/todo",
                    controller: "users",
                    action: "todo_items",
                    format: "json")
    @a1_json.deep_merge!({ "assignment" => { "needs_grading_count" => 0 } })
    json = json.sort_by { |t| t["assignment"]["id"] }
    update_assignment_json
    expect(strip_secure_params(json.first)).to eq strip_secure_params(@a1_json)
    expect(strip_secure_params(json.second)).to eq strip_secure_params(@a2_json)
  end

  it "does not crash when mixing items with/without due dates (users controller)" do
    @a2.update(due_at: nil)
    api_call(:get,
             "/api/v1/users/self/todo",
             controller: "users",
             action: "todo_items",
             format: "json")
    expect(response).to be_successful
  end

  it "does not crash when mixing items with/without due dates (courses controller)" do
    @teacher_course.enroll_student(@teacher).accept!
    @a2.update(due_at: nil)
    Assignment.create!(context: @teacher_course, due_at: 1.day.from_now, title: "text", submission_types: "online_text_entry", points_possible: 15)
    api_call(:get,
             "/api/v1/courses/#{@teacher_course.id}/todo",
             controller: "courses",
             action: "todo_items",
             format: "json",
             per_page: 5,
             course_id: @teacher_course.to_param)
    expect(response).to be_successful
  end

  it "ignores a todo item permanently" do
    api_call(:delete,
             @a2_json["ignore_permanently"],
             controller: "users",
             action: "ignore_item",
             format: "json",
             purpose: "grading",
             asset_string: "assignment_#{@a2.id}",
             permanent: "1")
    expect(response).to be_successful

    json = api_call(:get,
                    "/api/v1/courses/#{@teacher_course.id}/todo",
                    controller: "courses",
                    action: "todo_items",
                    format: "json",
                    course_id: @teacher_course.to_param)
    expect(json).to eq []

    # after new student submission, still ignored
    another_submission
    json = api_call(:get,
                    "/api/v1/courses/#{@teacher_course.id}/todo",
                    controller: "courses",
                    action: "todo_items",
                    format: "json",
                    course_id: @teacher_course.to_param)
    expect(json).to eq []
  end

  it "ignores a todo item until the next change" do
    api_call(:delete,
             @a2_json["ignore"],
             controller: "users",
             action: "ignore_item",
             format: "json",
             purpose: "grading",
             asset_string: "assignment_#{@a2.id}",
             permanent: "0")
    expect(response).to be_successful

    json = api_call(:get,
                    "/api/v1/courses/#{@teacher_course.id}/todo",
                    controller: "courses",
                    action: "todo_items",
                    format: "json",
                    course_id: @teacher_course.to_param)
    expect(json).to eq []

    # after new student submission, no longer ignored
    another_submission
    json = api_call(:get,
                    "/api/v1/courses/#{@teacher_course.id}/todo",
                    controller: "courses",
                    action: "todo_items",
                    format: "json",
                    course_id: @teacher_course.to_param)
    @a2_json["needs_grading_count"] = 2
    @a2_json["assignment"]["needs_grading_count"] = 2
    update_assignment_json
    expect(strip_secure_params(json.first)).to eq strip_secure_params(@a2_json)
  end

  it "ignores excused assignments for students" do
    @student_course.enroll_teacher(@teacher)
    @a1.grade_student(@me, excuse: true, grader: @teacher)

    json = api_call(:get,
                    "/api/v1/courses/#{@student_course.id}/todo",
                    controller: "courses",
                    action: "todo_items",
                    format: "json",
                    course_id: @student_course.to_param)

    expect(json).to eq []
  end

  it "includes future assignments that don't expect an online submission (courses endpoint)" do
    past_ungraded = @student_course.assignments.create! due_at: 2.days.ago, workflow_state: "published", submission_types: "not_graded"
    ungraded = @student_course.assignments.create! due_at: 2.days.from_now, workflow_state: "published", submission_types: "not_graded"
    due_overridden = @student_course.assignments.create! workflow_state: "published", submission_types: "not_graded"
    create_adhoc_override_for_assignment(due_overridden, @user, { due_at: 2.days.from_now })
    json = api_call :get,
                    "/api/v1/courses/#{@student_course.id}/todo",
                    controller: "courses",
                    action: "todo_items",
                    format: "json",
                    course_id: @student_course.to_param
    expect(json.map { |e| e["assignment"]["id"] }).to include ungraded.id, due_overridden.id
    expect(json.map { |e| e["assignment"]["id"] }).not_to include past_ungraded.id
  end

  it "includes future assignments that don't expect an online submission (users endpoint)" do
    past_ungraded = @student_course.assignments.create! due_at: 2.days.ago, workflow_state: "published", submission_types: "not_graded"
    ungraded = @student_course.assignments.create! due_at: 2.days.from_now, workflow_state: "published", submission_types: "not_graded"
    due_overridden = @student_course.assignments.create! workflow_state: "published", submission_types: "not_graded"
    create_adhoc_override_for_assignment(due_overridden, @user, { due_at: 2.days.from_now })
    json = api_call :get, "/api/v1/users/self/todo", controller: "users", action: "todo_items", format: "json"
    expect(json.map { |e| e["assignment"]["id"] }).to include ungraded.id, due_overridden.id
    expect(json.map { |e| e["assignment"]["id"] }).not_to include past_ungraded.id
  end

  it "respects grading permissions (users endpoint)" do
    course_with_ta(course: @teacher_course, active_all: true)
    @ta = @user
    json = api_call :get, "/api/v1/users/self/todo", controller: "users", action: "todo_items", format: "json"
    expect(json.map { |e| e["assignment"]["id"] }).to include @a2.id

    RoleOverride.create!(context: @course.account,
                         permission: "manage_grades",
                         role: ta_role,
                         enabled: false)

    json = api_call :get, "/api/v1/users/self/todo", controller: "users", action: "todo_items", format: "json"
    expect(json.length).to eq 0
  end

  it "does not include items from courses concluded by terms dates if the user is also an admin" do
    account_admin_user(account: @teacher_course.root_account, user: @user)
    json = api_call :get, "/api/v1/users/self/todo", controller: "users", action: "todo_items", format: "json"
    expect(json.map { |e| e["assignment"]["id"] }).to include @a2.id

    et = @teacher_course.enrollment_term
    et.end_at = 1.day.ago
    et.save!

    json = api_call :get, "/api/v1/users/self/todo", controller: "users", action: "todo_items", format: "json"
    expect(json).to eq []
  end

  it "includes ungraded quizzes by request" do
    survey = @student_course.quizzes.create!(quiz_type: "survey", due_at: 1.day.from_now)
    survey.publish!
    past_survey = @student_course.quizzes.create!(quiz_type: "survey", due_at: 1.day.ago)
    past_survey.publish!

    # course endpoint
    json = api_call :get,
                    "/api/v1/courses/#{@student_course.id}/todo",
                    controller: "courses",
                    action: "todo_items",
                    format: "json",
                    course_id: @student_course.to_param
    expect(json.filter_map { |el| el["quiz"] && el["quiz"]["id"] }).to eql([])

    json = api_call :get,
                    "/api/v1/courses/#{@student_course.id}/todo?include[]=ungraded_quizzes",
                    controller: "courses",
                    action: "todo_items",
                    format: "json",
                    course_id: @student_course.to_param,
                    include: %w[ungraded_quizzes]
    expect(json.filter_map { |el| el["quiz"] && el["quiz"]["id"] }).to eql([survey.id])

    # user endpoint
    json = api_call :get, "/api/v1/users/self/todo", controller: "users", action: "todo_items", format: "json"
    expect(json.filter_map { |el| el["quiz"] && el["quiz"]["id"] }).to eql([])

    json = api_call :get,
                    "/api/v1/users/self/todo?include[]=ungraded_quizzes",
                    controller: "users",
                    action: "todo_items",
                    format: "json",
                    include: %w[ungraded_quizzes]
    expect(json.filter_map { |el| el["quiz"] && el["quiz"]["id"] }).to eql([survey.id])
  end

  it "doesn't include ungraded quizzes if not assigned to user" do
    survey = @student_course.quizzes.create!(quiz_type: "survey", due_at: 1.day.from_now, only_visible_to_overrides: true)
    survey.publish!
    survey.assignment_overrides.create!(set: @course.default_section)

    survey2 = @student_course.quizzes.create!(quiz_type: "survey", due_at: 1.day.from_now, only_visible_to_overrides: true)
    survey2.publish!
    section = @course.course_sections.create!
    survey2.assignment_overrides.create!(set: section)

    json = api_call :get,
                    "/api/v1/users/self/todo?include[]=ungraded_quizzes",
                    controller: "users",
                    action: "todo_items",
                    format: "json",
                    include: %w[ungraded_quizzes]
    expect(json.filter_map { |el| el["quiz"] && el["quiz"]["id"] }).to eql([survey.id])
  end

  it "works correctly when turnitin is enabled" do
    expect_any_instantiation_of(@a2.context).to receive(:turnitin_enabled?).and_return true
    api_call(:get,
             "/api/v1/users/self/todo",
             controller: "users",
             action: "todo_items",
             format: "json")
    expect(response).to be_successful
  end

  it "doesnt include anything over 4 weeks old" do
    @student_course.assignments.create! due_at: 5.weeks.ago, workflow_state: "published", submission_types: "not_graded"
    past_survey = @student_course.quizzes.create!(quiz_type: "survey", due_at: 5.weeks.ago)
    past_survey.publish!

    json = api_call :get,
                    "/api/v1/users/self/todo?include[]=ungraded_quizzes",
                    controller: "users",
                    action: "todo_items",
                    format: "json",
                    include: %w[ungraded_quizzes]
    expect(json.filter_map { |el| el["quiz"] && el["quiz"]["id"] }).to eql([])

    json = api_call :get,
                    "/api/v1/courses/#{@student_course.id}/todo?include[]=ungraded_quizzes",
                    controller: "courses",
                    action: "todo_items",
                    format: "json",
                    course_id: @student_course.to_param,
                    include: %w[ungraded_quizzes]
    expect(json.filter_map { |el| el["quiz"] && el["quiz"]["id"] }).to eql([])
  end

  context "when the assignment is differentiated/ has overrides" do
    before do
      @course = course_factory(active_all: true)
      @section = @course.course_sections.create!

      @user = user_factory(active_all: true)
      @course.enroll_student(@user, { section: @section }).accept!

      ao = differentiated_assignment(context: @course, course_section: @section, due_at: nil, submission_types: "online_text_entry")
      ao.due_at = 1.day.from_now
      ao.due_at_overridden = true
      ao.save!

      survey = @course.quizzes.create!(quiz_type: "survey", only_visible_to_overrides: true, due_at: nil)
      so = survey.assignment_overrides.create!(set: @section)
      so.due_at = 1.day.from_now
      so.due_at_overridden = true
      so.save!
      survey.publish!
    end

    it "includes assignments/quizzes with no due_at (users controller)" do
      json = api_call(:get,
                      "/api/v1/users/self/todo?include[]=ungraded_quizzes",
                      controller: "users",
                      action: "todo_items",
                      format: "json",
                      include: %w[ungraded_quizzes])
      expect(json.count).to be(2)
    end

    it "includes assignments/quizzes with no due_at (courses controller)" do
      json = api_call(:get,
                      "/api/v1/courses/#{@course.id}/todo?include[]=ungraded_quizzes",
                      controller: "courses",
                      action: "todo_items",
                      format: "json",
                      course_id: @course.to_param,
                      include: %w[ungraded_quizzes])
      expect(json.count).to be(2)
    end
  end

  context "with pagination" do
    before :once do
      @teacher = course_with_teacher(active_all: true).user
      @teacher_course = @course
      @student_course = course_factory(active_course: true)
      @student_course.enroll_student(@teacher).accept(true)
      # an assignment i need to submit (needs_submitting)
      batch = [120, 13, 147, 79, 161, 119, 81, 57, 134, 21].map do |i|
        {
          context_type: "Course",
          context_id: @student_course.id,
          root_account_id: @student_course.root_account_id,
          due_at: i.hours.from_now, # randomized due dates for the next 7ish days
          title: "required work",
          submission_types: "online_text_entry",
          points_possible: 10,
          workflow_state: "published"
        }
      end
      Assignment.bulk_insert(batch)
      @student_assignments = @student_course.assignments
      batch = @student_assignments.map do |a|
        {
          cached_due_date: a.due_date,
          assignment_id: a.id,
          course_id: @student_course.id,
          user_id: @teacher.id,
          workflow_state: "unsubmitted"
        }
      end
      Submission.bulk_insert(batch)

      # an assignment i created, and a student who submits the assignment (needs_grading)
      @student = user_factory(active_all: true)
      @teacher_course.enroll_student(@student).accept!
      batch = [89, 10, 39, 6, 34, 55, 95, 103, 126, 107].map do |i|
        {
          context_type: "Course",
          context_id: @teacher_course.id,
          root_account_id: @teacher_course.root_account_id,
          due_at: i.hours.from_now, # randomized due dates for the next 7ish days
          title: "text",
          submission_types: "online_text_entry",
          points_possible: 15,
          workflow_state: "published"
        }
      end
      Assignment.bulk_insert(batch)
      @teacher_assignments = @teacher_course.assignments
      batch = @teacher_assignments.map do |a|
        {
          cached_due_date: a.due_at,
          assignment_id: a.id,
          course_id: @teacher_course.id,
          user_id: @student.id,
          workflow_state: "submitted",
          submission_type: "online_text_entry",
          body: "done"
        }
      end
      Submission.bulk_insert(batch)
      @user = @teacher
    end

    it "paginates (users controller)" do
      json = api_call(:get,
                      "/api/v1/users/self/todo",
                      controller: "users",
                      action: "todo_items",
                      format: "json",
                      per_page: 10)
      response_ids = json.map { |todo| todo["assignment"]["id"] }

      json_next = follow_pagination_link("next", {
                                           controller: "users",
                                           action: "todo_items",
                                           format: "json",
                                           per_page: 10
                                         })
      response_ids += json_next.map { |todo| todo["assignment"]["id"] }

      expect(response_ids).to eq((@teacher_assignments + @student_assignments).sort_by(&:due_at).map(&:id))
    end

    it "paginated (courses controller)" do
      json = api_call(:get,
                      "/api/v1/courses/#{@student_course.id}/todo",
                      controller: "courses",
                      action: "todo_items",
                      format: "json",
                      per_page: 5,
                      course_id: @student_course.to_param)
      response_ids = json.map { |todo| todo["assignment"]["id"] }
      json_next = follow_pagination_link("next", {
                                           controller: "courses",
                                           action: "todo_items",
                                           format: "json",
                                           per_page: 5,
                                           course_id: @student_course.to_param
                                         })
      response_ids += json_next.map { |todo| todo["assignment"]["id"] }

      expect(response_ids).to eq(@student_assignments.sort_by(&:due_at).map(&:id))
    end
  end

  describe "todo_item_count" do
    before :once do
      @teacher = course_with_teacher(active_all: true, user: user_with_pseudonym(active_all: true))
      @teacher_course = @course
      @student_course = course_factory(active_all: true)
      @student_course.enroll_student(@user).accept!
      # an assignment i need to submit (needs_submitting)
      batch = []
      18.times do
        batch << { context_type: "Course",
                   context_id: @student_course.id,
                   root_account_id: @student_course.root_account_id,
                   due_at: 6.days.from_now,
                   title: "required work",
                   submission_types: "online_text_entry",
                   points_possible: 10,
                   workflow_state: "published" }
      end
      Assignment.bulk_insert(batch)

      assignments = @student_course.assignments
      batch = assignments.map do |a|
        { cached_due_date: 6.days.from_now,
          assignment_id: a.id,
          course_id: a.context_id,
          user_id: @user.id,
          workflow_state: "unsubmitted" }
      end
      Submission.bulk_insert(batch)

      # one assignment submitted
      assignment = @student_course.assignments.first
      assignment.submit_homework(@user, submission_type: "online_text_entry", body: "done")
      # one assignment ignored
      assignment = @student_course.assignments[1]
      @user.ignore_item!(assignment, "submitting", true)

      # an assignment i created, and a student who submits the assignment (needs_grading)
      @me = @user
      @student = user_factory(active_all: true)
      @user = @me
      @teacher_course.enroll_student(@student).accept!
      @teacher_assignment_ids = []

      3.times do
        a = Assignment.create!(context: @teacher_course,
                               due_at: 1.day.from_now,
                               title: "text",
                               submission_types: "online_text_entry",
                               points_possible: 15)
        a.submit_homework(@student, submission_type: "online_text_entry", body: "done")
        @teacher_assignment_ids << a.id
      end
      # one assignment graded
      submission = @teacher_course.assignments[0].submissions[0]
      submission.workflow_state = "graded"
      submission.score = 90
      submission.save!
      # one assignment ignored
      assignment = @teacher_course.assignments[1]
      @user.ignore_item!(assignment, "grading", true)
    end

    it "checks for auth" do
      get("/api/v1/users/self/todo_item_count")
      assert_status(401)
    end

    it "returns the correct count" do
      json = api_call(:get,
                      "/api/v1/users/self/todo_item_count",
                      controller: "users",
                      action: "todo_item_count",
                      format: "json")
      expect(json["needs_grading_count"]).to eq 1
      expect(json["assignments_needing_submitting"]).to eq 16
    end

    it "doesn't count assignments that don't need grading" do
      a = Assignment.create!(context: @teacher_course,
                             due_at: 1.day.from_now,
                             title: "no grading",
                             submission_types: "on_paper",
                             points_possible: 15)
      a.submit_homework(@student, submission_type: "on_paper")

      json = api_call(:get,
                      "/api/v1/users/self/todo_item_count",
                      controller: "users",
                      action: "todo_item_count",
                      format: "json")
      expect(json["needs_grading_count"]).to eq 1
    end

    it "doesn't count submissions on deleted assignments" do
      @teacher_course.assignments.last.destroy
      json = api_call(:get,
                      "/api/v1/users/self/todo_item_count",
                      controller: "users",
                      action: "todo_item_count",
                      format: "json")
      expect(json["needs_grading_count"]).to eq 0
    end
  end
end
