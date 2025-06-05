# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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
require_relative "../locked_examples"
require_relative "../../lti_spec_helper"
require_relative "../../lti2_spec_helper"

describe AssignmentsApiController, type: :request do
  include Api
  include Api::V1::Assignment
  include Api::V1::Submission
  include LtiSpecHelper

  specs_require_sharding

  context "locked api item" do
    let(:item_type) { "assignment" }

    include_examples "a locked api item"

    let_once(:locked_item) do
      @course.assignments.create!(title: "Locked Assignment")
    end

    def api_get_json
      api_get_assignment_in_course(locked_item, @course)
    end
  end

  def create_submitted_assignment_with_user(user = @user)
    now = Time.zone.now
    assignment = @course.assignments.create!(
      title: "dawg you gotta submit this",
      submission_types: "online_url"
    )
    submission = bare_submission_model assignment,
                                       user,
                                       score: "99",
                                       grade: "99",
                                       grader_id: @teacher.id,
                                       submitted_at: now,
                                       grade_matches_current_submission: true
    [assignment, submission]
  end

  def create_override_for_assignment(assignment = @assignment)
    override = assignment.assignment_overrides.build
    override.title = "I am overridden and being returned in the API!"
    override.set = @section
    override.set_type = "CourseSection"
    override.due_at = 2.days.from_now
    override.unlock_at = 1.day.from_now
    override.lock_at = 3.days.from_now
    override.due_at_overridden = true
    override.lock_at_overridden = true
    override.unlock_at_overridden = true
    override.save!
    override
  end

  describe "GET courses/:course_id/assignments/:assignment_id/users/:user_id/group_members" do
    before :once do
      course_with_teacher(active_all: true)
      @student1 = user_factory(active_all: true)
      @student2 = user_factory(active_all: true)
      @student3 = user_factory(active_all: true)
      @course.enroll_student(@student1).accept!
      @course.enroll_student(@student2).accept!
      @course.enroll_student(@student3).accept!
      group_category = @course.group_categories.create!(name: "Category")
      group1 = @course.groups.create!(name: "Group 1", group_category:)
      group1.add_user(@student1)
      group1.add_user(@student2)
      group2 = @course.groups.create!(name: "Group 2", group_category:)
      group2.add_user(@student3)
      @assignment = @course.assignments.create!(name: "group assignment", group_category:)
    end

    it "returns not found if a bogus assignment id is requested" do
      user_session(@teacher)

      api_call(:get,
               "/api/v1/courses/#{@course.id}/assignments/10987654321/users/#{@student1.id}/group_members",
               {
                 controller: "assignments_api",
                 action: "student_group_members",
                 format: "json",
                 course_id: @course.id.to_s,
                 assignment_id: 10_987_654_321,
                 user_id: @student1.id.to_s
               },
               {},
               {},
               { expected_status: 404 })
    end

    it "returns unauthorized if...not authorized" do
      original_course = @course
      course_with_teacher(active_all: true)
      user_session(@teacher)

      api_call(:get,
               "/api/v1/courses/#{original_course.id}/assignments/#{@assignment.id}/users/#{@student1.id}/group_members",
               {
                 controller: "assignments_api",
                 action: "student_group_members",
                 format: "json",
                 course_id: original_course.id.to_s,
                 assignment_id: @assignment.id.to_s,
                 user_id: @student1.id.to_s
               },
               {},
               {},
               { expected_status: 403 })
    end

    it "returns the ids and names of users in the same group as the student" do
      user_session(@teacher)

      json = api_call(:get,
                      "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/users/#{@student1.id}/group_members",
                      {
                        controller: "assignments_api",
                        action: "student_group_members",
                        format: "json",
                        course_id: @course.id.to_s,
                        assignment_id: @assignment.id,
                        user_id: @student1.id.to_s
                      },
                      {},
                      {},
                      { expected_status: 200 })

      expect(json).to contain_exactly(
        { "id" => @student1.id.to_s, "name" => @student1.name },
        { "id" => @student2.id.to_s, "name" => @student2.name }
      )
    end

    it "returns an array with the student only if not a group assignment" do
      @assignment = @course.assignments.create!(name: "individual assignment")
      user_session(@teacher)

      json = api_call(:get,
                      "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/users/#{@student1.id}/group_members",
                      {
                        controller: "assignments_api",
                        action: "student_group_members",
                        format: "json",
                        course_id: @course.id.to_s,
                        assignment_id: @assignment.id,
                        user_id: @student1.id.to_s
                      },
                      {},
                      {},
                      { expected_status: 200 })

      expect(json).to contain_exactly({ "id" => @student1.id.to_s, "name" => @student1.name })
    end
  end

  describe "GET /courses/:course_id/assignments (#index)" do
    before :once do
      course_with_teacher(active_all: true)
    end

    describe "checkpoints in-place" do
      before do
        @course.account.enable_feature!(:discussion_checkpoints)

        assignment = @course.assignments.create!(title: "Assignment 1", has_sub_assignments: true)
        @c1 = assignment.sub_assignments.create!(context: assignment.context, sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC, points_possible: 5, due_at: 3.days.from_now)
        @c2 = assignment.sub_assignments.create!(context: assignment.context, sub_assignment_tag: CheckpointLabels::REPLY_TO_ENTRY, points_possible: 10, due_at: 5.days.from_now)

        user = user_factory(active_all: true)
        @course.enroll_student(user).accept!
        @students = [user]
        @course.enroll_teacher(@teacher, enrollment_state: "active")

        create_adhoc_override_for_assignment(@c2, @students, due_at: 2.days.from_now)
        create_adhoc_override_for_assignment(@c1, @students, due_at: 2.days.from_now)
      end

      it "Returns overrides for teacher" do
        json = api_get_assignments_index_from_course_as_user(@course, @teacher, include: ["checkpoints"])
        assignment = json.first
        checkpoints = assignment["checkpoints"]
        first_checkpoint = checkpoints.find { |c| c["tag"] == CheckpointLabels::REPLY_TO_TOPIC }
        second_checkpoint = checkpoints.find { |c| c["tag"] == CheckpointLabels::REPLY_TO_ENTRY }

        expect(assignment["has_sub_assignments"]).to be_truthy

        expect(checkpoints.length).to eq 2
        expect(checkpoints.pluck("name")).to match_array [@c1.name, @c2.name]
        expect(checkpoints.pluck("tag")).to match_array [@c1.sub_assignment_tag, @c2.sub_assignment_tag]
        expect(checkpoints.pluck("points_possible")).to match_array [@c1.points_possible, @c2.points_possible]
        expect(checkpoints.pluck("due_at")).to match_array [@c1.assignment_overrides.first.due_at.iso8601, @c2.assignment_overrides.first.due_at.iso8601]
        expect(checkpoints.pluck("only_visible_to_overrides")).to match_array [@c1.only_visible_to_overrides, @c2.only_visible_to_overrides]
        expect(first_checkpoint["overrides"].length).to eq 1
        expect(second_checkpoint["overrides"].length).to eq 1
        expect(second_checkpoint["overrides"].first["assignment_id"]).to eq @c2.id
        expect(second_checkpoint["overrides"].first["student_ids"]).to match_array @students.map(&:id)
      end

      it "hides cehckpoint override info from students" do
        json = api_get_assignments_index_from_course_as_user(@course, @students.first, include: ["checkpoints"])
        assignment = json.first
        checkpoints = assignment["checkpoints"]
        first_checkpoint = checkpoints.find { |c| c["tag"] == CheckpointLabels::REPLY_TO_TOPIC }
        second_checkpoint = checkpoints.find { |c| c["tag"] == CheckpointLabels::REPLY_TO_ENTRY }

        expect(assignment["has_sub_assignments"]).to be_truthy

        expect(checkpoints.length).to eq 2
        expect(checkpoints.pluck("name")).to match_array [@c1.name, @c2.name]
        expect(checkpoints.pluck("tag")).to match_array [@c1.sub_assignment_tag, @c2.sub_assignment_tag]
        expect(checkpoints.pluck("points_possible")).to match_array [@c1.points_possible, @c2.points_possible]
        expect(checkpoints.pluck("due_at")).to match_array [@c1.assignment_overrides.first.due_at.iso8601, @c2.assignment_overrides.first.due_at.iso8601]
        expect(checkpoints.pluck("only_visible_to_overrides")).to match_array [@c1.only_visible_to_overrides, @c2.only_visible_to_overrides]
        expect(first_checkpoint["overrides"].length).to eq 0
        expect(second_checkpoint["overrides"].length).to eq 0
      end
    end

    it "returns forbidden for users who cannot :read the course" do
      # unpublished course with invited student
      course_with_student
      expect(@course.grants_right?(@student, :read)).to be_falsey

      api_call(:get,
               "/api/v1/courses/#{@course.id}/assignments",
               {
                 controller: "assignments_api",
                 action: "index",
                 format: "json",
                 course_id: @course.id.to_s
               },
               {},
               {},
               { expected_status: 403 })
    end

    context "when the 'new_quizzes' query param is set" do
      subject do
        api_get_assignments_index_from_course(course, { new_quizzes: true })
      end

      let!(:new_quizzes_assignment) do
        a = assignment_model(submission_types: "external_tool", course:, title: "New Quizzes")
        a.external_tool_tag_attributes = { content: tool }
        a.save!
        a
      end

      let(:course) { @course }
      let(:tool) do
        course.context_external_tools.create!(
          name: "Quizzes.Next",
          consumer_key: "test_key",
          shared_secret: "test_secret",
          tool_id: "Quizzes 2",
          url: "http://example.com/launch"
        )
      end

      before do
        course.assignments.create!(title: "Non Quiz Assignment")
      end

      it "only includes the New Quizzes assignments" do
        expect(subject.count).to eq 1
        expect(subject.first["id"]).to eq new_quizzes_assignment.id
      end
    end

    it "includes in_closed_grading_period in returned json" do
      @course.assignments.create!(title: "Example Assignment")
      json = api_get_assignments_index_from_course(@course)
      expect(json.first).to have_key("in_closed_grading_period")
    end

    it "includes ab_guid in returned json when included[]='ab_guid' is passed" do
      @course.assignments.create!(title: "Example Assignment")
      json = api_get_assignments_index_from_course(@course, include: ["ab_guid"])
      expect(json.first).to have_key("ab_guid")
    end

    it "does not include ab_guid in returned json when included[]='ab_guid' is not passed" do
      @course.assignments.create!(title: "Example Assignment")
      json = api_get_assignments_index_from_course(@course)
      expect(json.first).not_to have_key("ab_guid")
    end

    it "includes due_date_required in returned json" do
      @course.assignments.create!(title: "Example Assignment")
      json = api_get_assignments_index_from_course(@course)
      expect(json.first).to have_key("due_date_required")
    end

    it "includes name_length_required in returned json with default value" do
      @course.assignments.create!(title: "Example Assignment")
      json = api_get_assignments_index_from_course(@course)
      expect(json.first["max_name_length"]).to eq(255)
    end

    it "includes name_length_required in returned json with custom value" do
      a = @course.account
      a.settings[:sis_syncing] = { value: true }
      a.settings[:sis_assignment_name_length] = { value: true }
      a.enable_feature!(:new_sis_integrations)
      a.settings[:sis_assignment_name_length_input] = { value: 20 }
      a.save!
      @course.assignments.create!(title: "Example Assignment", post_to_sis: true)
      json = api_get_assignments_index_from_course(@course)
      expect(json.first["max_name_length"]).to eq(20)
    end

    it "returns all assignments using paging" do
      group1 = @course.assignment_groups.create!(name: "group1")
      5.times do
        @course.assignments.create!(title: "assignment1",
                                    assignment_group: group1)
               .update_attribute(:position, 0)
      end
      assignment_ids = []
      page = 1
      loop do
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/assignments.json?per_page=2&page=#{page}",
                        {
                          controller: "assignments_api",
                          action: "index",
                          format: "json",
                          course_id: @course.id.to_s,
                          per_page: "2",
                          page: page.to_s
                        })
        assignment_ids.concat(json.pluck("id"))
        break if json.length == 1

        page += 1
      end
      expect(assignment_ids.count).to eq(5)
      expect(assignment_ids.uniq.count).to eq(5)
    end

    describe "assignments" do
      before :once do
        @group1 = @course.assignment_groups.create!(name: "group1")
        @group1.update_attribute(:position, 10)
        @group2 = @course.assignment_groups.create!(name: "group2")
        @group2.update_attribute(:position, 7)
        group3 = @course.assignment_groups.create!(name: "group3")
        group3.update_attribute(:position, 12)
        @course.assignments.create!(title: "assignment1",
                                    assignment_group: @group2)
               .update_attribute(:position, 2)
        @course.assignments.create!(title: "assignment2",
                                    assignment_group: @group2)
               .update_attribute(:position, 1)
        @course.assignments.create!(title: "assignment3",
                                    assignment_group: @group1)
               .update_attribute(:position, 1)
        @course.assignments.create!(title: "assignment4",
                                    assignment_group: group3)
               .update_attribute(:position, 3)
        @course.assignments.create!(title: "assignment5",
                                    assignment_group: @group1)
               .update_attribute(:position, 2)
        @course.assignments.create!(title: "assignment6",
                                    assignment_group: @group2)
               .update_attribute(:position, 3)
        @course.assignments.create!(title: "assignment7",
                                    assignment_group: group3)
               .update_attribute(:position, 2)
        @course.assignments.create!(title: "assignment8",
                                    assignment_group: group3)
               .update_attribute(:position, 1)
      end

      it "sorts the returned list of assignments" do
        # the API returns the assignments sorted by
        # [assignment_groups.position, assignments.position]
        json = api_get_assignments_index_from_course(@course)
        order = json.pluck("name")
        expect(order).to eq %w[assignment2
                               assignment1
                               assignment6
                               assignment3
                               assignment5
                               assignment8
                               assignment7
                               assignment4]
      end

      it "only returns post_to_sis assignments" do
        Assignment.where(assignment_group_id: [@group1, @group2]).update_all(post_to_sis: true)
        json = api_get_assignments_index_from_course(@course, post_to_sis: true)
        post_to_sis = json.pluck("name")
        expect(post_to_sis).to eq %w[assignment2 assignment1 assignment6 assignment3 assignment5]
      end

      it "only returns assignments that do not have post_to_sis" do
        Assignment.where(assignment_group_id: [@group1, @group2]).update_all(post_to_sis: true)
        json = api_get_assignments_index_from_course(@course, post_to_sis: false)
        post_to_sis = json.pluck("name")
        expect(post_to_sis).to eq %w[assignment8 assignment7 assignment4]
      end

      it "fails for post_to_sis assignments when user cannot manage assignments" do
        Assignment.where(assignment_group_id: [@group1, @group2]).update_all(post_to_sis: true)
        @user = User.create!(name: " no permissions")
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/assignments.json",
                        {
                          controller: "assignments_api",
                          action: "index",
                          format: "json",
                          post_to_sis: true,
                          course_id: @course.id.to_s
                        },
                        {},
                        {},
                        expected_status: 403)
        expect(json["status"]).to eq "unauthorized"
      end

      it "sorts the returned list of assignments by name" do
        # the API returns the assignments sorted by
        # [assignment_groups.position, assignments.position]
        json = api_get_assignments_index_from_course(@course, order_by: "name")
        order = json.pluck("name")
        expect(order).to eq %w[assignment1
                               assignment2
                               assignment3
                               assignment4
                               assignment5
                               assignment6
                               assignment7
                               assignment8]
      end

      context "by due date" do
        before :once do
          @section1 = @course.course_sections.create! name: "section1"
          @student1 = student_in_course(name: "student1", active_all: true, section: @section1).user

          @section2 = @course.course_sections.create! name: "section2"
          @student2 = student_in_course(name: "student2", active_all: true, section: @section2).user

          due_at = 1.month.ago
          @course.assignments.where(title: %w[assignment1 assignment4 assignment7]).each do |a|
            a.due_at = due_at
            a.save!
          end
          assignment_override_model(assignment: @course.assignments.find_by(title: "assignment4"),
                                    set: @section1,
                                    due_at: 2.months.from_now)

          due_at = 1.month.from_now
          @course.assignments.where(title: %w[assignment2 assignment3 assignment5]).each do |a|
            a.due_at = due_at
            a.save!
          end
          assignment_override_model(assignment: @course.assignments.find_by(title: "assignment3"),
                                    set: @section2,
                                    due_at: 2.months.ago)
          assignment_override_model(assignment: @course.assignments.find_by(title: "assignment3"),
                                    set: @course.default_section,
                                    due_at: 3.months.from_now)

          SubmissionLifecycleManager.recompute_course(@course, run_immediately: true)
        end

        describe "sharding" do
          before do
            @shard1.activate do
              account = Account.create!
              @cs_course = Course.create!(account:)
              @cs_course.workflow_state = "available"
              @cs_course.save!
              @cs_course.assignments.create name: "assignment1"
            end
          end

          it "returns assignments in the contexts' shard as a teacher" do
            @shard1.activate do
              @cs_course.enroll_user(@user, "TeacherEnrollment", enrollment_state: "active")
            end

            json = api_get_assignments_index_from_course(@cs_course, order_by: "due_at")

            expect(json.pluck("name")).to eq %w[assignment1]
          end

          it "returns assignments in the contexts' shard as a student" do
            @shard1.activate do
              @cs_course.enroll_user(@user, "StudentEnrollment", enrollment_state: "active")
            end

            json = api_get_assignments_index_from_course(@cs_course, order_by: "due_at")

            expect(json.pluck("name")).to eq %w[assignment1]
          end

          it "returns user assignments in the contexts' shard as a teacher" do
            @shard1.activate do
              @cs_course.enroll_user(@user, "TeacherEnrollment", enrollment_state: "active")
            end

            json = api_get_assignments_user_index(@user, @cs_course, @user, order_by: "due_at")

            expect(json.pluck("name")).to eq %w[assignment1]
          end

          it "returns user assignments in the contexts' shard as a student" do
            @shard1.activate do
              @cs_course.enroll_user(@user, "StudentEnrollment", enrollment_state: "active")
            end

            json = api_get_assignments_user_index(@user, @cs_course, @user, order_by: "due_at")

            expect(json.pluck("name")).to eq %w[assignment1]
          end
        end

        it "sorts the returned list of assignments by latest due date for teachers (nulls last)" do
          json = api_get_assignments_user_index(@teacher, @course, @teacher, order_by: "due_at")
          order = %w[assignment1 assignment7 assignment2 assignment5 assignment4 assignment3 assignment6 assignment8]
          expect(json.pluck("name")).to eq order
          expect(json.sort_by { |a| [a["due_at"] || CanvasSort::Last, a["name"]] }.pluck("name")).to eq order
        end

        it "sorts the returned list of assignments by overridden due date for students (nulls last)" do
          json = api_get_assignments_user_index(@student1, @course, @teacher, order_by: "due_at")
          order = %w[assignment1 assignment7 assignment2 assignment3 assignment5 assignment4 assignment6 assignment8]
          expect(json.pluck("name")).to eq order
          expect(json.sort_by { |a| [a["due_at"] || CanvasSort::Last, a["name"]] }.pluck("name")).to eq order

          json = api_get_assignments_user_index(@student2, @course, @teacher, order_by: "due_at")
          order = %w[assignment3 assignment1 assignment4 assignment7 assignment2 assignment5 assignment6 assignment8]
          expect(json.pluck("name")).to eq order
          expect(json.sort_by { |a| [a["due_at"] || CanvasSort::Last, a["name"]] }.pluck("name")).to eq order
        end
      end

      it "returns assignments by assignment group" do
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/assignment_groups/#{@group2.id}/assignments",
                        {
                          controller: "assignments_api",
                          action: "index",
                          format: "json",
                          course_id: @course.to_param,
                          assignment_group_id: @group2.to_param
                        })
        expect(json.pluck("name")).to match_array(%w[assignment1 assignment2 assignment6])
      end
    end

    it "searches for assignments by title" do
      2.times { |i| @course.assignments.create!(title: "First_#{i}") }
      ids = @course.assignments.map(&:id)
      2.times { |i| @course.assignments.create!(title: "second_#{i}") }

      json = api_call(:get,
                      "/api/v1/courses/#{@course.id}/assignments.json?search_term=fir",
                      {
                        controller: "assignments_api",
                        action: "index",
                        format: "json",
                        course_id: @course.id.to_s,
                        search_term: "fir"
                      })
      expect(json.pluck("id").sort).to eq ids.sort
    end

    it "allows filtering based on assignment_ids[] parameter" do
      5.times { |i| @course.assignments.create!(title: "a_#{i}") }
      all_ids = @course.assignments.pluck(:id).map(&:to_s)
      some_ids = all_ids.slice(1, 3)
      query_string = some_ids.map { |id| "assignment_ids[]=#{id}" }.join("&")

      json = api_call(:get,
                      "/api/v1/courses/#{@course.id}/assignments.json?#{query_string}",
                      {
                        controller: "assignments_api",
                        action: "index",
                        format: "json",
                        course_id: @course.id.to_s,
                        assignment_ids: some_ids
                      })

      expect(json.length).to eq 3
      expect(json.pluck("id").map(&:to_s).sort).to eq some_ids.sort
    end

    it "fails if given an assignment_id that does not exist" do
      good_assignment = @course.assignments.create!(title: "assignment")
      bad_assignment = @course.assignments.create!(title: "assignment")
      bad_assignment.destroy!
      bad_id = bad_assignment.id
      api_call(:get,
               "/api/v1/courses/#{@course.id}/assignments.json?assignment_ids[]=#{good_assignment.id}&assignment_ids[]=#{bad_id}",
               {
                 controller: "assignments_api",
                 action: "index",
                 format: "json",
                 course_id: @course.id.to_s,
                 assignment_ids: [good_assignment.id.to_s, bad_id.to_s]
               },
               {},
               {},
               {
                 expected_status: 400
               })
    end

    it "fails when given an assignment_id without permissions" do
      student_in_course
      bad_assignment = @course.assignments.create!(title: "assignment") # not published
      bad_assignment.workflow_state = :unpublished
      bad_assignment.save!
      api_call_as_user(@student,
                       :get,
                       "/api/v1/courses/#{@course.id}/assignments.json?assignment_ids[]=#{bad_assignment.id}",
                       {
                         controller: "assignments_api",
                         action: "index",
                         format: "json",
                         course_id: @course.id.to_s,
                         assignment_ids: [bad_assignment.id.to_s]
                       },
                       {},
                       {},
                       {
                         expected_status: 400
                       })
    end

    it "fails if given too many assignment_ids" do
      all_ids = (1...(Api::MAX_PER_PAGE + 10)).map(&:to_s)
      query_string = all_ids.map { |id| "assignment_ids[]=#{id}" }.join("&")
      api_call(:get,
               "/api/v1/courses/#{@course.id}/assignments.json?#{query_string}",
               {
                 controller: "assignments_api",
                 action: "index",
                 format: "json",
                 course_id: @course.id.to_s,
                 assignment_ids: all_ids
               },
               {},
               {},
               {
                 expected_status: 400
               })
    end

    it "returns the assignments list with API-formatted Rubric data" do
      # the API changes the structure of the data quite a bit, to hide
      # implementation details and ease API use.
      @group = @course.assignment_groups.create!({ name: "some group" })
      @assignment = @course.assignments.create!(title: "some assignment",
                                                assignment_group: @group,
                                                points_possible: 12)
      @assignment.update_attribute(:submission_types,
                                   "online_upload,online_text_entry,online_url,media_recording")
      @rubric = rubric_model(user: @user,
                             context: @course,
                             data: larger_rubric_data,
                             title: "some rubric",
                             points_possible: 12,
                             free_form_criterion_comments: true)

      @rubric.data.push(
        {
          id: "crit3",
          description: "Criterion With Range",
          long_description: "Long Criterion With Range",
          points: 5,
          criterion_use_range: true,
          ratings:
            [{ id: "rat1",
               description: "Full Marks",
               long_description: "Student did a great job.",
               points: 5.0 }]
        }
      )

      @assignment.build_rubric_association(rubric: @rubric,
                                           purpose: "grading",
                                           use_for_grading: true,
                                           context: @course)
      @assignment.rubric_association.save!
      json = api_get_assignments_index_from_course(@course)
      expect(json.first["rubric_settings"]).to eq({
                                                    "id" => @rubric.id,
                                                    "title" => "some rubric",
                                                    "points_possible" => 12,
                                                    "free_form_criterion_comments" => true,
                                                    "hide_score_total" => false,
                                                    "hide_points" => false,
                                                  })
      expect(json.first["rubric"]).to eq [
        {
          "id" => "crit1",
          "points" => 10,
          "description" => "Crit1",
          "criterion_use_range" => false,
          "ratings" => [
            { "id" => "rat1", "points" => 10, "description" => "A", "long_description" => "" },
            { "id" => "rat2", "points" => 7, "description" => "B", "long_description" => "" },
            { "id" => "rat3", "points" => 0, "description" => "F", "long_description" => "" }
          ]
        },
        {
          "id" => "crit2",
          "points" => 2,
          "description" => "Crit2",
          "criterion_use_range" => false,
          "ratings" => [
            { "id" => "rat1", "points" => 2, "description" => "Pass", "long_description" => "" },
            { "id" => "rat2", "points" => 0, "description" => "Fail", "long_description" => "" },
          ]
        },
        {
          "id" => "crit3",
          "points" => 5,
          "description" => "Criterion With Range",
          "long_description" => "Long Criterion With Range",
          "criterion_use_range" => true,
          "ratings" => [
            { "id" => "rat1",
              "points" => 5,
              "description" => "Full Marks",
              "long_description" => "Student did a great job." }
          ]
        }
      ]
    end

    it "returns learning outcome info with rubric criterions if available" do
      @group = @course.assignment_groups.create!({ name: "some group" })
      @assignment = @course.assignments.create!(title: "some assignment",
                                                assignment_group: @group,
                                                points_possible: 12)
      @assignment.update_attribute(:submission_types,
                                   "online_upload,online_text_entry,online_url,media_recording")

      criterion = valid_rubric_attributes[:data].first
      @outcome = @course.created_learning_outcomes.build(
        title: "My Outcome",
        description: "Description of my outcome",
        vendor_guid: "vendorguid9000"
      )
      @outcome.rubric_criterion = criterion
      @outcome.save!

      rubric_data = [criterion.merge({ learning_outcome_id: @outcome.id })]

      @rubric = rubric_model(user: @user,
                             context: @course,
                             data: rubric_data,
                             points_possible: 12,
                             free_form_criterion_comments: true)

      @assignment.build_rubric_association(rubric: @rubric,
                                           purpose: "grading",
                                           use_for_grading: true,
                                           context: @course)
      @assignment.rubric_association.save!
      json = api_get_assignments_index_from_course(@course)

      expect(json.first["rubric"].first["outcome_id"]).to eq @outcome.id
      expect(json.first["rubric"].first["vendor_guid"]).to eq "vendorguid9000"
    end

    it "excludes deleted assignments in the list return" do
      @context = @course
      @assignment = @course.assignments.create!(
        title: "assignment1",
        submission_types: "discussion_topic",
        discussion_topic: discussion_topic_model
      )
      @assignment.reload
      @assignment.destroy
      json = api_get_assignments_index_from_course(@course)
      expect(json.size).to eq 0
    end

    describe "assignment bucketing" do
      before :once do
        @now = Time.zone.now
        course_with_student(active_all: true)
        @student1 = @user
        @section = @course.course_sections.create!(name: "test section")
        student_in_section(@section, user: @student1)

        @student2 = create_users(1, return_type: :record).first
        @course.enroll_student(@student2, enrollment_state: "active")
        @section2 = @course.course_sections.create!(name: "second test section")
        student_in_section(@section2, user: @student2)

        # names based on student 1's due dates
        @past_assignment = @course.assignments.create!(title: "past", only_visible_to_overrides: true, due_at: 10.days.ago(@now))
        create_section_override_for_assignment(@past_assignment, { course_section: @section, due_at: 10.days.ago(@now) })

        @overdue_assignment = @course.assignments.create!(title: "overdue", only_visible_to_overrides: true, submission_types: "online")
        create_section_override_for_assignment(@overdue_assignment, { course_section: @section, due_at: 10.days.ago(@now) })

        @far_future_assignment = @course.assignments.create!(title: "far future", only_visible_to_overrides: true)
        create_section_override_for_assignment(@far_future_assignment, { course_section: @section, due_at: 30.days.from_now(@now) })

        @upcoming_assignment = @course.assignments.create!(title: "upcoming", only_visible_to_overrides: true)
        create_section_override_for_assignment(@upcoming_assignment, { course_section: @section, due_at: 1.day.from_now(@now) })

        @undated_assignment = @course.assignments.create!(title: "undated", only_visible_to_overrides: true)
        override = create_section_override_for_assignment(@undated_assignment, { course_section: @section, due_at: nil })
        override.due_at = nil
        override.save

        # student2 overrides
        create_section_override_for_assignment(@past_assignment, { course_section: @section2, due_at: 10.days.ago(@now) })
        create_section_override_for_assignment(@far_future_assignment, { course_section: @section2, due_at: 10.days.ago(@now) })
      end

      before do
        user_session(@student1)
      end

      it "returns an error with an invalid bucket" do
        raw_api_call(:get,
                     "/api/v1/courses/#{@course.id}/assignments.json",
                     { controller: "assignments_api",
                       action: "index",
                       format: "json",
                       course_id: @course.id.to_s,
                       bucket: "invalid bucket name" })

        expect(response).not_to be_successful
        json = JSON.parse response.body
        expect(json["errors"]["bucket"].first["message"]).to eq "bucket name must be one of the following: past, overdue, undated, ungraded, unsubmitted, upcoming, future"
      end

      def assignment_index_bucketed_api_call(bucket, opts = {})
        api_call(:get,
                 "/api/v1/courses/#{@course.id}/assignments.json",
                 { controller: "assignments_api",
                   action: "index",
                   format: "json",
                   course_id: @course.id.to_s,
                   bucket: }.merge(opts))
      end

      def assert_call_gets_assignments(bucket, assignments)
        assignments_json = assignment_index_bucketed_api_call(bucket)
        expect(assignments_json.pluck("id").sort).to eq assignments.map(&:id).sort
        if assignments_json.any?
          expect(assignments_json.first["bucket"]).to eq bucket
        end
      end

      def assert_calls_get_assignments(expectations)
        expectations.each do |bucket, assignments|
          assert_call_gets_assignments(bucket.to_s, assignments)
        end
      end

      context "as a student" do
        it "buckets assignments properly" do
          assert_calls_get_assignments(
            future: [@upcoming_assignment, @far_future_assignment, @undated_assignment],
            upcoming: [@upcoming_assignment],
            past: [@past_assignment, @overdue_assignment],
            undated: [@undated_assignment],
            overdue: [@overdue_assignment]
          )
        end

        it "applies overrides properly to different students" do
          # as student1
          assert_call_gets_assignments("past", [@past_assignment, @overdue_assignment])

          user_session(@student2)
          @user = @student2

          assert_call_gets_assignments("past", [@past_assignment, @far_future_assignment])
        end
      end

      context "as a teacher" do
        before do
          @teacher = @course.teachers.first
          user_session(@teacher)
          @user = @teacher
        end

        it "includes assignments in buckets if any assigned students meet the criteria" do
          assert_calls_get_assignments(
            past: [@past_assignment, @overdue_assignment, @far_future_assignment],
            undated: [@undated_assignment]
          )
        end

        it "supports sorting bucketed assignments by name" do
          @course.assignments.create!(title: "z", due_at: 2.days.from_now(@now))
          @course.assignments.create!(title: "a", due_at: 3.days.from_now(@now))
          assignments_json = assignment_index_bucketed_api_call(:upcoming, order_by: :name)
          expect(assignments_json.pluck("name")).to eq %w[a upcoming z]
        end

        it "supports sorting bucketed assignments by latest due date, ascending" do
          z_assignment = @course.assignments.create!(title: "z")
          create_adhoc_override_for_assignment(z_assignment, @student1, due_at: 1.hour.from_now(@now))
          create_adhoc_override_for_assignment(z_assignment, @student2, due_at: 2.hours.from_now(@now))

          a_assignment = @course.assignments.create!(title: "a")
          create_adhoc_override_for_assignment(a_assignment, @student1, due_at: 1.hour.ago(@now))
          create_adhoc_override_for_assignment(a_assignment, @student2, due_at: 2.days.from_now(@now))

          assignments_json = assignment_index_bucketed_api_call(:upcoming, order_by: :due_at)
          expect(assignments_json.pluck("name")).to eq %w[z upcoming a]
        end
      end

      context "as an observer" do
        before :once do
          @observer = User.create
          @user = @observer
        end

        before do
          user_session(@observer)
        end

        it "gets the same results as a student when only observing one student" do
          @observer_enrollment = @course.enroll_user(@observer, "ObserverEnrollment", section: @section2, enrollment_state: "active")
          @observer_enrollment.update_attribute(:associated_user_id, @student1.id)

          assert_calls_get_assignments(
            future: [@upcoming_assignment, @far_future_assignment, @undated_assignment],
            upcoming: [@upcoming_assignment],
            past: [@past_assignment, @overdue_assignment],
            undated: [@undated_assignment],
            overdue: [@overdue_assignment]
          )
        end

        it "includes assignments in buckets if any observed students meet the criteria" do
          @observer_enrollment = @course.enroll_user(@observer, "ObserverEnrollment", section: @section, enrollment_state: "active", allow_multiple_enrollments: true)
          @observer_enrollment.update_attribute(:associated_user_id, @student1.id)
          @observer_enrollment = @course.enroll_user(@observer, "ObserverEnrollment", section: @section, enrollment_state: "active", allow_multiple_enrollments: true)
          @observer_enrollment.update_attribute(:associated_user_id, @student2.id)

          assert_calls_get_assignments(
            future: [@upcoming_assignment, @far_future_assignment, @undated_assignment],
            upcoming: [@upcoming_assignment],
            past: [@past_assignment, @overdue_assignment, @far_future_assignment],
            undated: [@undated_assignment],
            overdue: [@overdue_assignment]
          )
        end
      end
    end

    describe "enable draft" do
      before :once do
        course_with_teacher(active_all: true)
        @assignment = @course.assignments.create name: "some assignment"
        @assignment.workflow_state = "unpublished"
        @assignment.save!
      end

      it "includes published flag for accounts that do have enabled_draft" do
        @json = api_get_assignment_in_course(@assignment, @course)

        expect(@json).to have_key("published")
        expect(@json["published"]).to be_falsey
      end

      it "includes in_closed_grading_period in returned json" do
        @course.assignments.create!(title: "Example Assignment")
        json = api_get_assignment_in_course(@assignment, @course)
        expect(json).to have_key("in_closed_grading_period")
      end
    end

    describe "updating an assignment with locked ranges" do
      before :once do
        course_with_teacher(active_all: true)
      end

      it "does not allow updating due date to invalid lock range" do
        json = api_create_assignment_in_course(@course, { name: "aaron assignment" })
        @assignment = Assignment.find(json["id"])
        @assignment.unlock_at = 1.week.ago
        @assignment.lock_at = 3.days.ago
        @assignment.save!

        api_call(:put,
                 "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}",
                 { controller: "assignments_api",
                   action: "update",
                   format: "json",
                   course_id: @course.id.to_s,
                   id: @assignment.to_param },
                 { assignment: { due_at: 2.days.ago.iso8601 } },
                 {},
                 { expected_status: 400 })
      end

      it "allows updating due date to invalid lock range if lock range is also updated" do
        json = api_create_assignment_in_course(@course, { name: "aaron assignment" })
        @assignment = Assignment.find(json["id"])
        @assignment.unlock_at = 1.week.ago
        @assignment.lock_at = 3.days.ago
        @assignment.save!

        api_call(:put,
                 "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}",
                 { controller: "assignments_api",
                   action: "update",
                   format: "json",
                   course_id: @course.id.to_s,
                   id: @assignment.to_param },
                 { assignment: { unlock_at: 4.days.ago.iso8601,
                                 lock_at: 1.day.ago.iso8601,
                                 due_at: 2.days.ago.iso8601 } },
                 {},
                 { expected_status: 200 })
      end

      it "allows assignment update due_date within locked range" do
        json = api_create_assignment_in_course(@course, { name: "aaron assignment" })
        @assignment = Assignment.find(json["id"])
        @assignment.unlock_at = Time.zone.parse("2011-01-02T00:00:00Z")
        @assignment.lock_at = Time.zone.parse("2011-01-10T00:00:00Z")
        @assignment.save!

        api_call(:put,
                 "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}",
                 { controller: "assignments_api",
                   action: "update",
                   format: "json",
                   course_id: @course.id.to_s,
                   id: @assignment.to_param },
                 { assignment: { due_at: "2011-01-05T00:00:00Z" } },
                 {},
                 { expected_status: 200 })
      end

      it "does not allow assignment update due_date before locked range" do
        json = api_create_assignment_in_course(@course, { "name" => "my assignment" })
        @assignment = Assignment.find(json["id"])
        @assignment.unlock_at = Time.zone.parse("2011-01-02T00:00:00Z")
        @assignment.lock_at = Time.zone.parse("2011-01-10T00:00:00Z")
        @assignment.save!

        api_call(:put,
                 "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}",
                 { controller: "assignments_api",
                   action: "update",
                   format: "json",
                   course_id: @course.id.to_s,
                   id: @assignment.to_param },
                 { assignment: { due_at: "2011-01-01T00:00:00Z" } },
                 {},
                 { expected_status: 400 })
      end

      it "allows assignment update due_date with no locked ranges" do
        json = api_create_assignment_in_course(@course, { "name" => "blerp assignment" })
        @assignment = Assignment.find(json["id"])

        api_call(:put,
                 "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}",
                 { controller: "assignments_api",
                   action: "update",
                   format: "json",
                   course_id: @course.id.to_s,
                   id: @assignment.to_param },
                 { assignment: { due_at: "2011-01-01T00:00:00Z" } },
                 {},
                 { expected_status: 200 })
      end

      it "does not allow assignment update due_date after locked range" do
        json = api_create_assignment_in_course(@course, { "name" => "wow assignment" })
        @assignment = Assignment.find(json["id"])
        @assignment.unlock_at = Time.zone.parse("2011-01-02T00:00:00Z")
        @assignment.lock_at = Time.zone.parse("2011-01-10T00:00:00Z")
        @assignment.save!

        api_call(:put,
                 "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}",
                 { controller: "assignments_api",
                   action: "update",
                   format: "json",
                   course_id: @course.id.to_s,
                   id: @assignment.to_param },
                 { assignment: { due_at: "2012-01-01T00:00:00Z" } },
                 {},
                 { expected_status: 400 })
      end

      it "does not skip due date validation just because it somehow passed in no overrides" do
        @assignment = @course.assignments.create!(
          unlock_at: Time.zone.parse("2011-01-02T00:00:00Z"),
          due_at: Time.zone.parse("2012-01-04T00:00:00Z")
        )

        # have to make the call without helpers to pass in an empty array correctly
        p = Account.default.pseudonyms.create!(unique_id: "#{@user.id}@example.com", user: @user)
        allow_any_instantiation_of(p).to receive(:works_for_account?).and_return(true)
        put "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}",
            params: { assignment: { lock_at: "2012-01-03T00:00:00Z", assignment_overrides: [] } }.to_json,
            headers: { "CONTENT_TYPE" => "application/json", "HTTP_AUTHORIZATION" => "Bearer #{access_token_for_user(@user)}" }
        expect(response.code.to_i).to eq 400
        expect(@assignment.reload.lock_at).to be_nil
      end

      it "allows assignment update due_date on locked range" do
        json = api_create_assignment_in_course(@course, { "name" => "cool assignment" })
        @assignment = Assignment.find(json["id"])
        @assignment.unlock_at = Time.zone.parse("2011-01-01T00:00:00Z")
        @assignment.lock_at = Time.zone.parse("2011-01-10T00:00:00Z")
        @assignment.save!

        api_call(:put,
                 "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}",
                 { controller: "assignments_api",
                   action: "update",
                   format: "json",
                   course_id: @course.id.to_s,
                   id: @assignment.to_param },
                 { assignment: { due_at: "2011-01-01T00:00:00Z" } },
                 {},
                 { expected_status: 200 })
      end
    end

    describe "differentiated assignments" do
      def setup_DA
        @course_section = @course.course_sections.create
        @student1, @student2, @student3 = create_users(3, return_type: :record)
        @assignment = @course.assignments.create!(title: "title", only_visible_to_overrides: true)
        @course.enroll_student(@student2, enrollment_state: "active")
        @section = @course.course_sections.create!(name: "test section")
        @section2 = @course.course_sections.create!(name: "second test section")
        student_in_section(@section, user: @student1)
        create_section_override_for_assignment(@assignment, { course_section: @section })
        @assignment2 = @course.assignments.create!(title: "title2", only_visible_to_overrides: true)
        create_section_override_for_assignment(@assignment2, { course_section: @section2 })
        @course.reload
      end

      before :once do
        course_with_teacher(active_all: true)
        @assignment = @course.assignments.create(name: "differentiated assignment")
        section = @course.course_sections.create!(name: "second test section")
        create_section_override_for_assignment(@assignment, { course_section: section })
        assignment_override_model(assignment: @assignment, set_type: "Noop", title: "Just a Tag")
      end

      before do
        user_session(@teacher)
      end

      it "includes overrides if overrides flag is included in the params" do
        allow(ConditionalRelease::Service).to receive(:enabled_in_context?).and_return(true)
        assignments_json = api_call(:get,
                                    "/api/v1/courses/#{@course.id}/assignments",
                                    {
                                      controller: "assignments_api",
                                      action: "index",
                                      format: "json",
                                      course_id: @course.id.to_s,
                                    },
                                    include: ["overrides"])
        expect(assignments_json[0].keys).to include("overrides")
        expect(assignments_json[0]["overrides"].length).to eq 2
      end

      it "includes the only_visible_to_overrides flag if differentiated assignments is on" do
        @json = api_get_assignment_in_course(@assignment, @course)
        expect(@json).to have_key("only_visible_to_overrides")
        expect(@json["only_visible_to_overrides"]).to be_falsey
      end

      it "includes visibility data if included" do
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/assignments.json",
                        {
                          controller: "assignments_api",
                          action: "index",
                          format: "json",
                          course_id: @course.id.to_s
                        },
                        include: ["assignment_visibility"])
        expect(json).to all(have_key("assignment_visibility"))
      end

      it "shows all assignments" do
        setup_DA
        count = @course.assignments.reload.length
        json = api_get_assignments_index_from_course(@course)
        expect(json.length).to eq count
      end

      context "as a student" do
        before :once do
          course_factory(active_all: true)
          setup_DA
        end

        it "shows visible assignments" do
          user_session @student1
          @user = @student1
          json = api_get_assignments_index_from_course(@course)
          expect(json.length).to eq 1
          expect(json.first["id"]).to eq @assignment.id
        end

        it "does not show non-visible assignments" do
          user_session @student2
          @user = @student2
          json = api_get_assignments_index_from_course(@course)
          expect(json).to eq []
        end

        it "does not show assignments assigned to the user's inactive section enrollment" do
          @course.enroll_student(@student2,
                                 allow_multiple_enrollments: true,
                                 enrollment_state: "inactive",
                                 section: @section2)

          user_session @student2
          @user = @student2
          json = api_get_assignments_index_from_course(@course)
          expect(json).to eq []
        end
      end

      context "as an observer" do
        before :once do
          course_factory(active_all: true)
          setup_DA
          @observer = User.create
          @observer_enrollment = @course.enroll_user(@observer, "ObserverEnrollment", section: @course.course_sections.first, enrollment_state: "active", allow_multiple_enrollments: true)
        end

        it "shows assignments visible to observed student" do
          @observer_enrollment.update_attribute(:associated_user_id, @student1.id)
          user_session @observer
          @user = @student1
          json = api_get_assignments_index_from_course(@course)
          expect(json.length).to eq 1
          expect(json.first["id"]).to eq @assignment.id
        end

        it "does not show assignments not visible to observed student" do
          @observer_enrollment.update_attribute(:associated_user_id, @student2.id)
          user_session @observer
          @user = @student2
          json = api_get_assignments_index_from_course(@course)
          expect(json).to eq []
        end

        it "shows assignments visible to any of the observed students" do
          @observer_enrollment.update_attribute(:associated_user_id, @student2.id)
          @course.enroll_user(@observer, "ObserverEnrollment", { allow_multiple_enrollments: true, associated_user_id: @student1.id })
          user_session @observer
          @user = @student1
          json = api_get_assignments_index_from_course(@course)
          expect(json.length).to eq 1
          expect(json.first["id"]).to eq @assignment.id
        end
      end
    end

    describe "score statistics" do
      def setup_course
        @course_section = @course.course_sections.create
        @section = @course.course_sections.create!(name: "test section")
        @students = create_users_in_course(@course, 10, return_type: :record)
        @students.each do |student|
          student_in_section(@section, user: student)
        end
      end

      def setup_graded_submissions(count = 5)
        @assignment = @course.assignments.create!(title: "title", points_possible: "20.0")

        # Generate an array with min=10, max=18, mean=14
        scores = [10] + ([14] * (count - 2)) + [18]

        @students.take(count).each do |student|
          score = scores.pop.to_s
          @assignment.grade_student student, grade: score, grader: @teacher
        end

        ScoreStatisticsGenerator.update_score_statistics(@course.id)
      end

      context "as a student" do
        before do
          setup_course
        end

        it "shows min, max, and mean when include flag set" do
          allow(Account.site_admin).to receive(:feature_enabled?).and_call_original
          allow(Account.site_admin).to receive(:feature_enabled?).with(:enhanced_grade_statistics).and_return(true)

          setup_graded_submissions
          user_session @students[0]
          @user = @students[0]

          json = api_call(
            :get,
            "/api/v1/courses/#{@course.id}/assignments",
            {
              controller: "assignments_api",
              action: "index",
              format: "json",
              course_id: @course.id.to_s
            },
            include: ["score_statistics", "submission"]
          )
          assign = json.first
          expect(assign["score_statistics"]).to eq({ "min" => 10, "max" => 18, "mean" => 14, "lower_q" => 14, "median" => 14, "upper_q" => 14 })
        end

        it "does not show score statistics when include flag not set" do
          setup_graded_submissions
          user_session @students[0]
          @user = @students[0]

          json = api_call(
            :get,
            "/api/v1/courses/#{@course.id}/assignments",
            {
              controller: "assignments_api",
              action: "index",
              format: "json",
              course_id: @course.id.to_s
            },
            include: ["submission"]
          )
          assign = json.first
          expect(assign["score_statistics"]).to be_nil
        end

        it "does not show statistics when there are less than 5 graded submissions" do
          setup_graded_submissions 4
          user_session @students[0]
          @user = @students[0]

          json = api_call(
            :get,
            "/api/v1/courses/#{@course.id}/assignments",
            {
              controller: "assignments_api",
              action: "index",
              format: "json",
              course_id: @course.id.to_s
            },
            include: ["score_statistics", "submission"]
          )
          assign = json.first
          expect(assign["score_statistics"]).to be_nil
        end

        it "does not show statistics when the student's submission is not graded" do
          setup_graded_submissions

          # The sixth student will not have a graded assignment
          ungraded_student = @students[5]

          user_session ungraded_student
          @user = ungraded_student

          json = api_call(
            :get,
            "/api/v1/courses/#{@course.id}/assignments",
            {
              controller: "assignments_api",
              action: "index",
              format: "json",
              course_id: @course.id.to_s
            },
            include: ["score_statistics", "submission"]
          )
          assign = json.first
          expect(assign["score_statistics"]).to be_nil
        end
      end

      context "in a course which has distributions disabled" do
        before :once do
          setup_course
          @course.update(hide_distribution_graphs: true)
        end

        it "does not show score statistics to a student" do
          setup_graded_submissions
          user_session @students[0]
          @user = @students[0]

          json = api_call(
            :get,
            "/api/v1/courses/#{@course.id}/assignments",
            {
              controller: "assignments_api",
              action: "index",
              format: "json",
              course_id: @course.id.to_s
            },
            include: ["score_statistics", "submission"]
          )
          assign = json.first
          expect(assign["score_statistics"]).to be_nil
        end

        it "shoulds not show score statistics to observers" do
          setup_graded_submissions

          @observer = User.create!
          observer_enrollment = @course.enroll_user(@observer, "ObserverEnrollment", enrollment_state: "active")
          observer_enrollment.update_attribute(:associated_user_id, @students[0].id)
          @user = @observer

          json = api_call(
            :get,
            "/api/v1/courses/#{@course.id}/assignments",
            {
              controller: "assignments_api",
              action: "index",
              format: "json",
              course_id: @course.id.to_s
            },
            include: %w[score_statistics submission observed_users]
          )
          assign = json.first
          expect(assign["score_statistics"]).to be_nil
        end
      end

      context "as an observer" do
        before :once do
          @observers = create_users(10, return_type: :record)
          @observer_enrollments = create_enrollments(@course, @observers, enrollment_type: "ObserverEnrollment", return_type: :record)
        end

        before do
          @observer = @observers.pop
          @observer_enrollment = @observer_enrollments.pop
          setup_course
        end

        it "shoulds show score statistics when include flag is set" do
          allow(Account.site_admin).to receive(:feature_enabled?).and_call_original
          allow(Account.site_admin).to receive(:feature_enabled?).with(:enhanced_grade_statistics).and_return(true)

          setup_graded_submissions

          @observer_enrollment.update_attribute(:associated_user_id, @students[0].id)
          @user = @observer

          json = api_call(
            :get,
            "/api/v1/courses/#{@course.id}/assignments",
            {
              controller: "assignments_api",
              action: "index",
              format: "json",
              course_id: @course.id.to_s
            },
            include: %w[score_statistics submission observed_users]
          )
          assign = json.first
          expect(assign["score_statistics"]).to eq({ "min" => 10, "max" => 18, "mean" => 14, "lower_q" => 14, "median" => 14, "upper_q" => 14 })
        end

        it "shoulds not show score statistics when no observed student has a grade" do
          setup_graded_submissions

          @observer_enrollment.update_attribute(:associated_user_id, @students[5].id)
          @user = @observer

          json = api_call(
            :get,
            "/api/v1/courses/#{@course.id}/assignments",
            {
              controller: "assignments_api",
              action: "index",
              format: "json",
              course_id: @course.id.to_s
            },
            include: %w[score_statistics submission observed_users]
          )
          assign = json.first
          expect(assign["score_statistics"]).to be_nil
        end

        it "shoulds show score statistics when any observed student has a grade" do
          allow(Account.site_admin).to receive(:feature_enabled?).and_call_original
          allow(Account.site_admin).to receive(:feature_enabled?).with(:enhanced_grade_statistics).and_return(true)

          setup_graded_submissions

          @observer_enrollment.update_attribute(:associated_user_id, @students[5].id)

          observer_enrollment2 = @course.enroll_user(@observer, "ObserverEnrollment", enrollment_state: "active", allow_multiple_enrollments: true)
          observer_enrollment2.update_attribute(:associated_user_id, @students[3].id)
          observer_enrollment3 = @course.enroll_user(@observer, "ObserverEnrollment", enrollment_state: "active", allow_multiple_enrollments: true)
          observer_enrollment3.update_attribute(:associated_user_id, @students[7].id)

          @user = @observer

          json = api_call(
            :get,
            "/api/v1/courses/#{@course.id}/assignments",
            {
              controller: "assignments_api",
              action: "index",
              format: "json",
              course_id: @course.id.to_s
            },
            include: %w[score_statistics submission observed_users]
          )
          assign = json.first
          expect(assign["score_statistics"]).to eq({ "min" => 10, "max" => 18, "mean" => 14, "lower_q" => 14, "median" => 14, "upper_q" => 14 })
        end

        it "shoulds not show score statistics when less than 5 students have a graded assignment" do
          setup_graded_submissions 4

          @observer_enrollment.update_attribute(:associated_user_id, @students[0].id)
          @user = @observer

          json = api_call(
            :get,
            "/api/v1/courses/#{@course.id}/assignments",
            {
              controller: "assignments_api",
              action: "index",
              format: "json",
              course_id: @course.id.to_s
            },
            include: %w[score_statistics submission observed_users]
          )
          assign = json.first
          expect(assign["score_statistics"]).to be_nil
        end
      end
    end

    it "includes submission info with include flag" do
      course_with_student_logged_in(active_all: true)
      assignment, submission = create_submitted_assignment_with_user(@user)
      json = api_call(:get,
                      "/api/v1/courses/#{@course.id}/assignments.json",
                      {
                        controller: "assignments_api",
                        action: "index",
                        format: "json",
                        course_id: @course.id.to_s
                      },
                      include: ["submission"])
      assign = json.first
      s_json = controller.submission_json(
        submission,
        assignment,
        @user,
        session,
        assignment.context,
        { include: ["submission"] }
      ).to_json
      expect(assign["submission"]).to eq(json_parse(s_json))
    end

    it "includes all_dates with include flag" do
      course_with_student_logged_in(active_all: true)
      @course.assignments.create!(title: "all_date_test", submission_types: "online_url")
      json = api_call(:get,
                      "/api/v1/courses/#{@course.id}/assignments.json",
                      {
                        controller: "assignments_api",
                        action: "index",
                        format: "json",
                        course_id: @course.id.to_s
                      },
                      include: ["all_dates"])
      assign = json.first
      expect(assign["all_dates"]).not_to be_nil
    end

    it "doesn't include all_dates if there are too many" do
      course_with_teacher_logged_in(active_all: true)
      s1 = student_in_course(course: @course, active_all: true).user
      s2 = student_in_course(course: @course, active_all: true).user

      a = @course.assignments.create!(title: "all_date_test", submission_types: "online_url", only_visible_to_overrides: true)
      o1 = assignment_override_model(assignment: a)
      o1.assignment_override_students.create!(user: s1)

      stub_const("Api::V1::Assignment::ALL_DATES_LIMIT", 2)

      @user = @teacher
      json = api_call(:get,
                      "/api/v1/courses/#{@course.id}/assignments.json",
                      { controller: "assignments_api", action: "index", format: "json", course_id: @course.id.to_s },
                      include: ["all_dates"])
      expect(json.first["all_dates"].count).to eq 1

      o2 = assignment_override_model(assignment: a)
      o2.assignment_override_students.create!(user: s2)

      json = api_call(:get,
                      "/api/v1/courses/#{@course.id}/assignments.json",
                      { controller: "assignments_api", action: "index", format: "json", course_id: @course.id.to_s },
                      include: ["all_dates"])
      expect(json.first["all_dates"]).to be_nil
      expect(json.first["all_dates_count"]).to eq 2
    end

    it "returns due dates as they apply to the user" do
      course_with_student(active_all: true)
      @user = @student
      @student.enrollments.each(&:destroy_permanently!)
      @assignment = @course.assignments.create!(title: "Test Assignment", description: "public stuff")
      @section = @course.course_sections.create!(name: "afternoon delight")
      @course.enroll_user(@student, "StudentEnrollment", section: @section, enrollment_state: :active)
      override = create_override_for_assignment
      json = api_get_assignments_index_from_course(@course).first
      expect(json["due_at"]).to eq override.due_at.iso8601
      expect(json["unlock_at"]).to eq override.unlock_at.iso8601
      expect(json["lock_at"]).to eq override.lock_at.iso8601
    end

    it "returns original assignment due dates" do
      course_with_student(active_all: true)
      @user = @teacher
      @student.enrollments.each(&:destroy_permanently!)
      @assignment = @course.assignments.create!(
        title: "Test Assignment",
        description: "public stuff",
        due_at: 1.day.from_now,
        unlock_at: Time.zone.now,
        lock_at: 2.days.from_now
      )
      @section = @course.course_sections.create! name: "afternoon delight"
      @course.enroll_user(@student,
                          "StudentEnrollment",
                          section: @section,
                          enrollment_state: :active)
      create_override_for_assignment
      json = api_call(:get,
                      "/api/v1/courses/#{@course.id}/assignments.json",
                      {
                        controller: "assignments_api",
                        action: "index",
                        format: "json",
                        course_id: @course.id.to_s
                      },
                      override_assignment_dates: "false").first
      expect(json["due_at"]).to eq @assignment.due_at.iso8601
      expect(json["unlock_at"]).to eq @assignment.unlock_at.iso8601
      expect(json["lock_at"]).to eq @assignment.lock_at.iso8601
    end

    describe "draft state" do
      before :once do
        course_with_student(active_all: true)
        @published = @course.assignments.create!({ name: "published assignment" })
        @published.workflow_state = "published"
        @published.save!

        @unpublished = @course.assignments.create!({ name: "unpublished assignment" })
        @unpublished.workflow_state = "unpublished"
        @unpublished.save!
      end

      it "only shows published assignments to students" do
        json = api_get_assignments_index_from_course(@course)
        expect(json.length).to eq 1
        expect(json[0]["id"]).to eq @published.id
      end

      it "shows unpublished assignments to teachers" do
        user_factory
        @enrollment = @course.enroll_user(@user, "TeacherEnrollment")
        @enrollment.course = @course # set the reverse association

        json = api_get_assignments_index_from_course(@course)
        expect(json.length).to eq 2
        expect(json[0]["id"]).to eq @published.id
        expect(json[1]["id"]).to eq @unpublished.id
      end
    end

    it "returns the url attribute for external tools" do
      course_with_student(active_all: true)
      assignment = @course.assignments.create!
      @tool_tag = ContentTag.new({ url: "http://www.example.com", new_tab: false })
      @tool_tag.context = assignment
      @tool_tag.save!
      assignment.submission_types = "external_tool"
      assignment.save!
      expect(assignment.external_tool_tag).not_to be_nil
      @json = api_get_assignments_index_from_course(@course)

      expect(@json[0]).to include("url")
      uri = URI(@json[0]["url"])
      expect(uri.path).to eq "/api/v1/courses/#{@course.id}/external_tools/sessionless_launch"
      expect(uri.query).to include("assignment_id=")
    end
  end

  describe "GET /users/:user_id/courses/:course_id/assignments (#user_index)" do
    describe "checkpoints in-place" do
      before do
        course_with_teacher(active_all: true)
        @course.account.enable_feature!(:discussion_checkpoints)

        assignment = @course.assignments.create!(title: "Assignment 1", has_sub_assignments: true)
        @c1 = assignment.sub_assignments.create!(context: assignment.context, sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC, points_possible: 5, due_at: 3.days.from_now)
        @c2 = assignment.sub_assignments.create!(context: assignment.context, sub_assignment_tag: CheckpointLabels::REPLY_TO_ENTRY, points_possible: 10, due_at: 5.days.from_now)
      end

      it "returns the assignments list with API-formatted Checkpoint data" do
        json = api_get_assignments_user_index(@teacher, @course, @teacher, include: ["checkpoints"])
        assignment = json.first
        checkpoints = assignment["checkpoints"]

        expect(assignment["has_sub_assignments"]).to be_truthy

        expect(checkpoints.length).to eq 2
        expect(checkpoints.pluck("name")).to match_array [@c1.name, @c2.name]
        expect(checkpoints.pluck("tag")).to match_array [@c1.sub_assignment_tag, @c2.sub_assignment_tag]
        expect(checkpoints.pluck("points_possible")).to match_array [@c1.points_possible, @c2.points_possible]
        expect(checkpoints.pluck("due_at")).to match_array [@c1.due_at.iso8601, @c2.due_at.iso8601]
        expect(checkpoints.pluck("only_visible_to_overrides")).to match_array [@c1.only_visible_to_overrides, @c2.only_visible_to_overrides]
      end

      it "excludes checkpointed assignments if exclude_checkpoints is enabled" do
        json = api_get_assignments_user_index(@teacher, @course, @teacher, exclude_checkpoints: true)
        expect(json.length).to eq 0
        json = api_get_assignments_user_index(@teacher, @course, @teacher)
        expect(json.length).to eq 1
      end
    end

    it "returns data for user calling on self" do
      course_with_student_submissions(active_all: true)
      json = api_get_assignments_user_index(@student, @course)
      expect(json[0]["course_id"]).to eq @course.id
    end

    it "returns assignments for authorized observer" do
      course_with_student_submissions(active_all: true)
      parent = User.create!
      add_linked_observer(@student, parent)
      json = api_get_assignments_user_index(@student, @course, parent)
      expect(json[0]["course_id"]).to eq @course.id
    end

    it "returns unauthorized for users who cannot :read the course" do
      # unpublished course with invited student
      course_with_student
      expect(@course.grants_right?(@student, :read)).to be_falsey
      api_call(:get,
               "/api/v1/users/#{@student.id}/courses/#{@course.id}/assignments",
               { controller: "assignments_api",
                 action: "user_index",
                 format: "json",
                 course_id: @course.id,
                 user_id: @student.id.to_s },
               {},
               {},
               { expected_status: 403 })
    end

    it "returns data for for teacher who can read target student data" do
      course_with_student_submissions(active_all: true)

      json = api_get_assignments_user_index(@student, @course, @teacher)
      expect(json[0]["course_id"]).to eq @course.id
    end

    it "returns data for ta who can read target student data" do
      course_with_teacher(active_all: true)
      section = add_section("section")
      student = student_in_section(section)
      ta = ta_in_section(section)

      api_get_assignments_user_index(student, @course, ta)
      expect(response).to be_successful
    end

    it "returns unauthorized for ta who cannot read target student data" do
      course_with_teacher(active_all: true)
      s1 = add_section("for student")
      s2 = add_section("for ta")
      student = student_in_section(s1)
      ta = ta_in_section(s2)

      api_call_as_user(ta,
                       :get,
                       "/api/v1/users/#{student.id}/courses/#{@course.id}/assignments",
                       { controller: "assignments_api",
                         action: "user_index",
                         format: "json",
                         course_id: @course.id,
                         user_id: student.id.to_s },
                       {},
                       {},
                       { expected_status: 403 })
    end
  end

  describe "POST 'duplicate'" do
    before :once do
      course_with_teacher(active_all: true)
      student_in_course(active_all: true)
    end

    it "students cannot duplicate" do
      assignment = @course.assignments.create(
        title: "some assignment",
        assignment_group: @group,
        due_at: 1.week.from_now
      )
      api_call_as_user(@student,
                       :post,
                       "/api/v1/courses/#{@course.id}/assignments/#{assignment.id}/duplicate.json",
                       { controller: "assignments_api",
                         action: "duplicate",
                         format: "json",
                         course_id: @course.id.to_s,
                         assignment_id: assignment.id.to_s },
                       {},
                       {},
                       { expected_status: 403 })
    end

    it "duplicates if teacher" do
      assignment = @course.assignments.create(
        title: "some assignment",
        assignment_group: @group,
        due_at: 1.week.from_now
      )
      assignment.save!
      assignment.insert_at(1)
      json = api_call_as_user(@teacher,
                              :post,
                              "/api/v1/courses/#{@course.id}/assignments/#{assignment.id}/duplicate.json",
                              { controller: "assignments_api",
                                action: "duplicate",
                                format: "json",
                                course_id: @course.id.to_s,
                                assignment_id: assignment.id.to_s },
                              {},
                              {},
                              { expected_status: 200 })
      expect(json["name"]).to eq "some assignment Copy"

      expect(json["assignment_group_id"]).to eq assignment.assignment_group_id

      # The new assignment should have the desired position, and nothing else
      # in the group should have the same position.
      new_id = json["id"]
      new_position = json["position"]
      expect(new_position).to eq 2
      assignments_in_group = Assignment.active
                                       .by_assignment_group_id(assignment.assignment_group_id)
                                       .pluck("id", "position")
      assignments_in_group.each do |id, position|
        if id != new_id
          expect(position).not_to eq(new_position)
        end
      end
    end

    it "requires non-quiz" do
      assignment = @course.assignments.create(title: "some assignment")
      assignment.quiz = @course.quizzes.create
      api_call_as_user(@teacher,
                       :post,
                       "/api/v1/courses/#{@course.id}/assignments/#{assignment.id}/duplicate.json",
                       { controller: "assignments_api",
                         action: "duplicate",
                         format: "json",
                         course_id: @course.id.to_s,
                         assignment_id: assignment.id.to_s },
                       {},
                       {},
                       { expected_status: 400 })
    end

    it "duplicates discussion topic" do
      assignment = group_discussion_assignment.assignment
      api_call_as_user(@teacher,
                       :post,
                       "/api/v1/courses/#{@course.id}/assignments/#{assignment.id}/duplicate.json",
                       { controller: "assignments_api",
                         action: "duplicate",
                         format: "json",
                         course_id: @course.id.to_s,
                         assignment_id: assignment.id.to_s },
                       {},
                       {},
                       { expected_status: 200 })
    end

    it "duplicates wiki page assignment" do
      assignment = wiki_page_assignment_model({ title: "Wiki Page Assignment" })
      assignment.save!
      json = api_call_as_user(@teacher,
                              :post,
                              "/api/v1/courses/#{@course.id}/assignments/#{assignment.id}/duplicate.json",
                              { controller: "assignments_api",
                                action: "duplicate",
                                format: "json",
                                course_id: @course.id.to_s,
                                assignment_id: assignment.id.to_s },
                              {},
                              {},
                              { expected_status: 200 })
      expect(json["name"]).to eq "Wiki Page Assignment Copy"
    end

    it "requires non-deleted assignment" do
      assignment = @course.assignments.create(
        title: "some assignment",
        workflow_state: "deleted"
      )
      # assignment.save!
      api_call_as_user(@teacher,
                       :post,
                       "/api/v1/courses/#{@course.id}/assignments/#{assignment.id}/duplicate.json",
                       { controller: "assignments_api",
                         action: "duplicate",
                         format: "json",
                         course_id: @course.id.to_s,
                         assignment_id: assignment.id.to_s },
                       {},
                       {},
                       { expected_status: 400 })
    end

    it "requires existing assignment" do
      assignment = @course.assignments.create(
        title: "some assignment",
        workflow_state: "deleted"
      )
      assignment.save!
      assignment_id = Assignment.maximum(:id) + 100
      api_call_as_user(@teacher,
                       :post,
                       "/api/v1/courses/#{@course.id}/assignments/#{assignment_id}/duplicate.json",
                       { controller: "assignments_api",
                         action: "duplicate",
                         format: "json",
                         course_id: @course.id.to_s,
                         assignment_id: assignment_id.to_s },
                       {},
                       {},
                       { expected_status: 400 })
    end

    it "creates audit events for the duplicated assignment if it is auditable" do
      anonymous_assignment = @course.assignments.create!(anonymous_grading: true)

      api_call_as_user(
        @teacher,
        :post,
        "/api/v1/courses/#{@course.id}/assignments/#{anonymous_assignment.id}/duplicate.json",
        {
          controller: "assignments_api",
          action: "duplicate",
          format: "json",
          course_id: @course.id.to_s,
          assignment_id: anonymous_assignment.id.to_s
        },
        {},
        {},
        { expected_status: 200 }
      )

      new_assignment = Assignment.find_by!(duplicate_of: anonymous_assignment.id)
      audit_event = AnonymousOrModerationEvent.find_by!(assignment_id: new_assignment)
      aggregate_failures do
        expect(audit_event.event_type).to eq "assignment_created"
        expect(audit_event.payload["anonymous_grading"]).to be true
      end
    end

    it "creates audit events even if assignments are inserted in the middle of the assignment group" do
      anonymous_assignment = @course.assignments.create!(anonymous_grading: true)
      @course.assignments.create!(title: "placeholder so duplicated assignment isn't last")

      api_call_as_user(
        @teacher,
        :post,
        "/api/v1/courses/#{@course.id}/assignments/#{anonymous_assignment.id}/duplicate.json",
        {
          controller: "assignments_api",
          action: "duplicate",
          format: "json",
          course_id: @course.id.to_s,
          assignment_id: anonymous_assignment.id.to_s
        },
        {},
        {},
        { expected_status: 200 }
      )

      new_assignment = Assignment.find_by!(duplicate_of: anonymous_assignment.id)
      audit_event = AnonymousOrModerationEvent.find_by!(assignment_id: new_assignment)
      aggregate_failures do
        expect(audit_event.event_type).to eq "assignment_created"
        expect(audit_event.payload["anonymous_grading"]).to be true
      end
    end

    context "when the assignment is duplicated in context" do
      subject do
        api_call_as_user(
          @teacher,
          :post,
          "/api/v1/courses/#{@course.id}/assignments/#{assignment.id}/duplicate.json",
          {
            controller: "assignments_api",
            action: "duplicate",
            format: "json",
            course_id: @course.id.to_s,
            assignment_id: assignment.id.to_s
          },
          {},
          {},
          { expected_status: 200 }
        )
      end

      let(:assignment) do
        @course.assignments.create!(
          title: "some assignment",
          assignment_group: @group,
          due_at: 1.week.from_now
        )
      end

      it 'sets the assignment "resource_map" to a value indicating a map is not needed' do
        expect_any_instance_of(Assignment).to receive(:resource_map=).with("duplicated_in_context")

        subject
      end
    end

    context "when the assignment is duplicated into a new context" do
      subject do
        api_call_as_user(
          @teacher,
          :post,
          "/api/v1/courses/#{@course.id}/assignments/#{assignment.id}/duplicate.json",
          {
            controller: "assignments_api",
            action: "duplicate",
            format: "json",
            course_id: @course.id.to_s,
            assignment_id: assignment.id.to_s,
            target_course_id: new_course.id
          },
          {},
          {},
          { expected_status: 200 }
        )
      end

      let(:assignment) do
        @course.assignments.create!(
          title: "some assignment",
          assignment_group: @group,
          due_at: 1.week.from_now
        )
      end

      let(:new_course) do
        new_course = create_course
        new_course.enroll_teacher(@teacher, enrollment_state: "active")
        new_course
      end

      it 'sets the assignment "resource_map" to a value indicating a map is not needed' do
        expect_any_instance_of(Assignment).not_to receive(:resource_map=)

        subject
      end

      it 'sets the assignment "resource_map" to a value indicating a map is needed when past imports exist' do
        allow_any_instance_of(Assignment).to receive(:quiz_lti?).and_return(true)
        master_template = MasterCourses::MasterTemplate.create!(course: @course)
        MasterCourses::ChildSubscription.create!(master_template:, child_course: new_course)
        expect_any_instance_of(Assignment).to receive(:resource_map=)

        subject
      end

      it 'sets the "resource_map" to equal the one from this course\'s content migration' do
        allow_any_instance_of(Assignment).to receive(:quiz_lti?).and_return(true)
        cm = instance_double(ContentMigration, asset_map_url: "some_s3_url")
        allow(ContentMigration).to receive(:find_most_recent_by_course_ids).and_return(cm)

        expect(ContentMigration).to receive(:find_most_recent_by_course_ids).with(@course.global_id, new_course.global_id)
        expect_any_instance_of(Assignment).to receive(:resource_map=).with("some_s3_url")
        subject
      end

      it 'does not set the "resource_map" when the assignment is not a quiz_lti' do
        allow_any_instance_of(Assignment).to receive(:quiz_lti?).and_return(false)
        master_template = MasterCourses::MasterTemplate.create!(course: @course)
        MasterCourses::ChildSubscription.create!(master_template:, child_course: new_course)
        expect_any_instance_of(Assignment).not_to receive(:resource_map=)

        subject
      end
    end

    context "Quizzes.Next course copy retry" do
      let(:assignment) do
        @course.assignments.create(
          title: "some assignment",
          assignment_group: @group,
          due_at: 1.week.from_now,
          submission_types: "external_tool"
        )
      end

      let(:course_copied) do
        course = @course.dup
        course.name = "target course"
        course.workflow_state = "available"
        course.save!
        course.enroll_teacher(@teacher, enrollment_state: "active")
        course
      end

      let!(:failed_assignment) do
        course_copied.assignments.create(
          title: "failed assignment",
          workflow_state: "failed_to_duplicate",
          duplicate_of_id: assignment.id
        )
      end

      before do
        tool = @course.context_external_tools.create!(
          name: "bob",
          url: "http://www.google.com",
          consumer_key: "bob",
          shared_secret: "bob",
          tool_id: "Quizzes 2",
          privacy_level: "public"
        )
        tag = ContentTag.create(content: tool, url: tool.url, context: assignment)
        assignment.external_tool_tag = tag
        assignment.save!
      end

      it "creates a new assignment with workflow_state duplicating" do
        url = "/api/v1/courses/#{@course.id}/assignments/#{assignment.id}/duplicate.json" \
              "?target_assignment_id=#{failed_assignment.id}&target_course_id=#{course_copied.id}"

        expect do
          api_call_as_user(
            @teacher,
            :post,
            url,
            {
              controller: "assignments_api",
              action: "duplicate",
              format: "json",
              course_id: @course.id.to_s,
              assignment_id: assignment.id.to_s,
              target_assignment_id: failed_assignment.id,
              target_course_id: course_copied.id
            },
            {},
            {},
            { expected_status: 200 }
          )
        end.to change { course_copied.assignments.where(duplicate_of_id: assignment.id).count }.by 1
        duplicated_assignments = course_copied.assignments.where(duplicate_of_id: assignment.id)
        expect(duplicated_assignments.count).to eq 2
        new_assignment = duplicated_assignments.where.not(id: failed_assignment.id).first
        expect(new_assignment.workflow_state).to eq("duplicating")
      end

      it "prevents duplicating an assignment that the user does not have permission to update" do
        account = Account.create!
        target_course = account.courses.create!
        target_assignment = target_course.assignments.create!
        url = "/api/v1/courses/#{@course.id}/assignments/#{assignment.id}/duplicate.json" \
              "?target_assignment_id=#{target_assignment.id}&target_course_id=#{target_course.id}"
        api_call_as_user(
          @teacher,
          :post,
          url,
          {
            controller: "assignments_api",
            action: "duplicate",
            format: "json",
            course_id: @course.id.to_s,
            assignment_id: assignment.id.to_s,
            target_assignment_id: target_assignment.id,
            target_course_id: target_course.id
          },
          {},
          {},
          { expected_status: 403 }
        )
      end

      context "when result_type is specified (Quizzes.Next serialization)" do
        before do
          @course.root_account.enable_feature!(:newquizzes_on_quiz_page)
        end

        it "outputs quiz shell json using quizzes.next serializer" do
          url = "/api/v1/courses/#{@course.id}/assignments/#{assignment.id}/duplicate.json" \
                "?target_assignment_id=#{failed_assignment.id}&target_course_id=#{course_copied.id}" \
                "&result_type=Quiz"

          json = api_call_as_user(
            @teacher,
            :post,
            url,
            {
              controller: "assignments_api",
              action: "duplicate",
              format: "json",
              course_id: @course.id.to_s,
              assignment_id: assignment.id.to_s,
              target_assignment_id: failed_assignment.id,
              target_course_id: course_copied.id,
              result_type: "Quiz"
            }
          )
          expect(json["quiz_type"]).to eq("quizzes.next")
        end
      end

      context "when retrying blueprint child" do
        let!(:failed_blueprint_assignment) do
          course_copied.assignments.create(
            title: "failed assignment",
            workflow_state: "failed_to_duplicate",
            duplicate_of_id: assignment.id,
            migration_id: "mastercourse_xxxxxx"
          )
        end

        it "creates a new assignment with workflow_state duplicating preserving migration_id" do
          url = "/api/v1/courses/#{@course.id}/assignments/#{assignment.id}/duplicate.json" \
                "?target_assignment_id=#{failed_blueprint_assignment.id}&target_course_id=#{course_copied.id}"

          json = api_call_as_user(
            @teacher,
            :post,
            url,
            {
              controller: "assignments_api",
              action: "duplicate",
              format: "json",
              course_id: @course.id.to_s,
              assignment_id: assignment.id.to_s,
              target_assignment_id: failed_blueprint_assignment.id,
              target_course_id: course_copied.id
            }
          )
          expect(Assignment.find(json["id"].to_i).migration_id).to eq(failed_blueprint_assignment.migration_id)
          expect(Assignment.find(failed_blueprint_assignment.id).migration_id).to be_nil
        end
      end
    end
  end

  describe "POST retry_alignment_clone" do
    before :once do
      course_with_teacher(active_all: true)
      student_in_course(active_all: true)
    end

    it "retries the alignment cloning process successfully" do
      assignment = @course.assignments.create(
        title: "some assignment",
        assignment_group: @group,
        due_at: 1.week.from_now
      )
      assignment.update_attribute(:workflow_state, "failed_to_clone_outcome_alignment")
      api_call_as_user(@user,
                       :post,
                       "/api/v1/courses/#{@course.id}/assignments/#{assignment.id}/retry_alignment_clone",
                       { controller: "assignments_api",
                         action: "retry_alignment_clone",
                         format: "json",
                         course_id: @course.id.to_s,
                         assignment_id: assignment.id.to_s,
                         target_course_id: @course.id.to_s,
                         target_assignment_id: assignment.id.to_s },
                       {},
                       {},
                       { expected_status: 200 })
    end

    it "returns 400 when the state is incorrect" do
      assignment = @course.assignments.create(
        title: "some assignment",
        assignment_group: @group,
        due_at: 1.week.from_now
      )
      api_call_as_user(@user,
                       :post,
                       "/api/v1/courses/#{@course.id}/assignments/#{assignment.id}/retry_alignment_clone",
                       { controller: "assignments_api",
                         action: "retry_alignment_clone",
                         format: "json",
                         course_id: @course.id.to_s,
                         assignment_id: assignment.id.to_s,
                         target_course_id: @course.id.to_s,
                         target_assignment_id: assignment.id.to_s },
                       {},
                       {},
                       { expected_status: 400 })
    end
  end

  describe "POST /courses/:course_id/assignments (#create)" do
    def create_assignment_json(group, group_category)
      { "name" => "some assignment",
        "position" => "1",
        "points_possible" => "12",
        "due_at" => "2011-01-01T00:00:00Z",
        "lock_at" => "2011-01-03T00:00:00Z",
        "unlock_at" => "2010-12-31T00:00:00Z",
        "description" => "assignment description",
        "assignment_group_id" => group.id,
        "submission_types" => [
          "online_upload"
        ],
        "notify_of_update" => true,
        "allowed_extensions" => [
          "docx", "ppt"
        ],
        "grade_group_students_individually" => true,
        "automatic_peer_reviews" => true,
        "peer_reviews" => true,
        "peer_reviews_assign_at" => "2011-01-02T00:00:00Z",
        "peer_review_count" => 2,
        "group_category_id" => group_category.id,
        "turnitin_enabled" => true,
        "vericite_enabled" => true,
        "grading_type" => "points",
        "allowed_attempts" => 2 }
    end

    before :once do
      course_with_teacher(active_all: true)
    end

    it "serializes post_to_sis when true" do
      a = @course.account
      a.settings[:sis_default_grade_export] = { locked: false, value: true }
      a.save!
      group = @course.assignment_groups.create!({ name: "first group" })
      group_category = @course.group_categories.create!(name: "foo")
      json = api_create_assignment_in_course(@course, create_assignment_json(group, group_category))
      expect(json["post_to_sis"]).to be true
    end

    it "serializes post_to_sis when false" do
      a = @course.account
      a.settings[:sis_default_grade_export] = { locked: false, value: false }
      a.save!
      group = @course.assignment_groups.create!({ name: "first group" })
      group_category = @course.group_categories.create!(name: "foo")
      json = api_create_assignment_in_course(@course, create_assignment_json(group, group_category))
      expect(json["post_to_sis"]).to be false
    end

    it "accepts a value for post_to_sis" do
      a = @course.account
      a.settings[:sis_default_grade_export] = { locked: false, value: false }
      a.save!
      json = api_create_assignment_in_course(@course, { "post_to_sis" => true })

      assignment = Assignment.find(json["id"])
      expect(assignment.post_to_sis).to be true
    end

    it "does not overwrite post_to_sis with default if missing in update params" do
      a = @course.account
      a.settings[:sis_default_grade_export] = { locked: false, value: true }
      a.save!
      json = api_create_assignment_in_course(@course, { "name" => "some assignment" })
      @assignment = Assignment.find(json["id"])
      expect(@assignment.post_to_sis).to be true
      a.settings[:sis_default_grade_export] = { locked: false, value: false }
      a.save!

      api_call(:put,
               "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}",
               {
                 controller: "assignments_api",
                 action: "update",
                 format: "json",
                 course_id: @course.id.to_s,
                 id: @assignment.to_param
               },
               { assignment: { points_possible: 10 } })
      @assignment.reload
      expect(@assignment.post_to_sis).to be true
    end

    it "returns forbidden for users who do not have permission" do
      student_in_course(active_all: true)
      @group = @course.assignment_groups.create!({ name: "some group" })
      @group_category = @course.group_categories.create!(name: "foo")

      @user = @student
      api_call(:post,
               "/api/v1/courses/#{@course.id}/assignments",
               {
                 controller: "assignments_api",
                 action: "create",
                 format: "json",
                 course_id: @course.id.to_s
               },
               create_assignment_json(@group, @group_category),
               {},
               { expected_status: 403 })
    end

    it "allows authenticated users to create assignments" do
      @course.assignment_groups.create!({ name: "first group" })
      @group = @course.assignment_groups.create!({ name: "some group" })
      @course.assignment_groups.create!({ name: "last group",
                                          position: 2 })
      @group_category = @course.group_categories.create!(name: "foo")
      expect_any_instantiation_of(@course).to receive(:turnitin_enabled?)
        .at_least(:once).and_return true
      expect_any_instantiation_of(@course).to receive(:vericite_enabled?)
        .at_least(:once).and_return true
      @json = api_create_assignment_in_course(@course,
                                              create_assignment_json(@group, @group_category))
      @group_category.reload
      @assignment = Assignment.find @json["id"]
      @assignment.reload
      expect(@json["id"]).to eq @assignment.id
      expect(@json["assignment_group_id"]).to eq @group.id
      expect(@json["name"]).to eq "some assignment"
      expect(@json["course_id"]).to eq @course.id
      expect(@json["description"]).to eq "assignment description"
      expect(@json["lock_at"]).to eq @assignment.lock_at.iso8601
      expect(@json["unlock_at"]).to eq @assignment.unlock_at.iso8601
      expect(@json["automatic_peer_reviews"]).to be true
      expect(@json["peer_reviews"]).to be true
      expect(@json["peer_review_count"]).to eq 2
      expect(@json["peer_reviews_assign_at"]).to eq(
        @assignment.peer_reviews_assign_at.iso8601
      )
      expect(@json["position"]).to eq 1
      expect(@json["group_category_id"]).to eq @group_category.id
      expect(@json["turnitin_enabled"]).to be true
      expect(@json["vericite_enabled"]).to be true
      expect(@json["turnitin_settings"]).to eq({
                                                 "originality_report_visibility" => "immediate",
                                                 "s_paper_check" => true,
                                                 "submit_papers_to" => true,
                                                 "internet_check" => true,
                                                 "journal_check" => true,
                                                 "exclude_biblio" => true,
                                                 "exclude_quoted" => true,
                                                 "exclude_small_matches_type" => nil,
                                                 "exclude_small_matches_value" => nil
                                               })
      expect(@json["allowed_extensions"]).to match_array [
        "docx", "ppt"
      ]
      expect(@json["points_possible"]).to eq 12
      expect(@json["grading_type"]).to eq "points"
      expect(@json["due_at"]).to eq @assignment.due_at.iso8601
      expect(@json["html_url"]).to eq course_assignment_url(@course, @assignment)
      expect(@json["needs_grading_count"]).to eq 0
      expect(@json["allowed_attempts"]).to eq 2

      expect(Assignment.count).to eq 1
    end

    it "does not allow assignment titles longer than 255 characters" do
      name_too_long = "a" * 256

      expect do
        raw_api_call(:post,
                     "/api/v1/courses/#{@course.id}/assignments.json",
                     {
                       controller: "assignments_api",
                       action: "create",
                       format: "json",
                       course_id: @course.id.to_s
                     },
                     { assignment: { "name" => name_too_long } })
        assert_status(400)
      end.not_to change(Assignment, :count)
    end

    it "does not allow modifying turnitin_enabled when not enabled on the context" do
      expect_any_instance_of(Course).to receive(:turnitin_enabled?).at_least(:once).and_return false
      response = api_create_assignment_in_course(@course,
                                                 { "name" => "some assignment",
                                                   "turnitin_enabled" => false })

      expect(response.keys).not_to include "turnitin_enabled"
      expect(Assignment.last.turnitin_enabled).to be_falsey
    end

    it "does not allow modifying vericite_enabled when not enabled on the context" do
      expect_any_instance_of(Course).to receive(:vericite_enabled?).at_least(:once).and_return false
      response = api_create_assignment_in_course(@course,
                                                 { "name" => "some assignment",
                                                   "vericite_enabled" => false })

      expect(response.keys).not_to include "vericite_enabled"
      expect(Assignment.last.vericite_enabled).to be_falsey
    end

    it "processes html content in description on create" do
      should_process_incoming_user_content(@course) do |content|
        api_create_assignment_in_course(@course, { "description" => content })

        a = Assignment.last
        a.reload
        a.description
      end
    end

    it "does not allow creating an assignment with allowed_extensions longer than 255" do
      api_create_assignment_in_course(@course, { description: "description",
                                                 allowed_extensions: "--docx" * 50 })
      json = JSON.parse response.body
      expect(json["errors"]).to_not be_nil
      expect(json["errors"]&.keys).to eq ["assignment[allowed_extensions]"]
      expect(json["errors"]["assignment[allowed_extensions]"].first["message"]).to eq("Value too long, allowed length is 255")
    end

    it "sets the lti_context_id if provided" do
      lti_assignment_id = SecureRandom.uuid
      jwt = Canvas::Security.create_jwt(lti_assignment_id:)

      api_create_assignment_in_course(@course, { "description" => "description",
                                                 "secure_params" => jwt })

      a = Assignment.last
      expect(a.lti_context_id).to eq(lti_assignment_id)
    end

    it "does not allow creating an assignment with the same lti_context_id" do
      lti_assignment_id = SecureRandom.uuid
      jwt = Canvas::Security.create_jwt(lti_assignment_id:)

      api_create_assignment_in_course(@course, { "description" => "description",
                                                 "secure_params" => jwt })
      expect(response).to have_http_status :created

      api_create_assignment_in_course(@course, { "description" => "description",
                                                 "secure_params" => jwt })
      json = JSON.parse response.body
      expect(json["errors"]).to_not be_nil
      expect(json["errors"]&.keys).to eq ["assignment[lti_context_id]"]
      expect(json["errors"]["assignment[lti_context_id]"].first["message"]).to eq("lti_context_id should be unique")
    end

    context "set the configuration LTI 1 tool if provided" do
      let(:tool) { @course.context_external_tools.create!(name: "a", url: "http://www.google.com", consumer_key: "12345", shared_secret: "secret") }
      let(:a) { Assignment.last }

      before do
        api_create_assignment_in_course(@course, {
                                          "description" => "description",
                                          "similarityDetectionTool" => tool.id,
                                          "configuration_tool_type" => "ContextExternalTool",
                                          "submission_type" => "online",
                                          "submission_types" => submission_types
                                        })
      end

      context "with online_upload" do
        let(:submission_types) { ["online_upload"] }

        it "sets the configuration LTI 1 tool if one is provided" do
          expect(a.tool_settings_tool).to eq(tool)
        end
      end

      context "with online_text_entry" do
        let(:submission_types) { ["online_text_entry"] }

        it "sets the configuration LTI 1 tool if one is provided" do
          expect(a.tool_settings_tool).to eq(tool)
        end
      end
    end

    it "does set the visibility settings" do
      tool = @course.context_external_tools.create!(name: "a", url: "http://www.google.com", consumer_key: "12345", shared_secret: "secret")
      response = api_create_assignment_in_course(@course, {
                                                   "description" => "description",
                                                   "similarityDetectionTool" => tool.id,
                                                   "configuration_tool_type" => "ContextExternalTool",
                                                   "submission_type" => "online",
                                                   "submission_types" => ["online_upload"],
                                                   "report_visibility" => "after_grading"
                                                 })
      a = Assignment.find response["id"]
      expect(a.turnitin_settings[:originality_report_visibility]).to eq("after_grading")
    end

    it "gives plagiarism platform settings priority of plagiarism plugins for Vericite" do
      tool = @course.context_external_tools.create!(name: "a", url: "http://www.google.com", consumer_key: "12345", shared_secret: "secret")
      response = api_create_assignment_in_course(@course, {
                                                   "description" => "description",
                                                   "similarityDetectionTool" => tool.id,
                                                   "configuration_tool_type" => "ContextExternalTool",
                                                   "submission_type" => "online",
                                                   "submission_types" => ["online_upload"],
                                                   "report_visibility" => "after_grading",
                                                   "vericite_settings" => {
                                                     "originality_report_visibility" => "immediately",
                                                     "exclude_quoted" => true,
                                                     "exclude_self_plag" => true,
                                                     "store_in_index" => true
                                                   }
                                                 })
      a = Assignment.find response["id"]
      expect(a.turnitin_settings[:originality_report_visibility]).to eq("after_grading")
    end

    it "gives plagiarism platform settings priority of plagiarism plugins for TII" do
      tool = @course.context_external_tools.create!(name: "a", url: "http://www.google.com", consumer_key: "12345", shared_secret: "secret")
      response = api_create_assignment_in_course(@course, {
                                                   "description" => "description",
                                                   "similarityDetectionTool" => tool.id,
                                                   "configuration_tool_type" => "ContextExternalTool",
                                                   "submission_type" => "online",
                                                   "submission_types" => ["online_upload"],
                                                   "report_visibility" => "after_grading",
                                                   "turnitin_settings" => {
                                                     "originality_report_visibility" => "immediately",
                                                     "exclude_quoted" => true,
                                                     "exclude_self_plag" => true,
                                                     "store_in_index" => true
                                                   }
                                                 })
      a = Assignment.find response["id"]
      expect(a.turnitin_settings[:originality_report_visibility]).to eq("after_grading")
    end

    context "LTI 2.x" do
      include_context "lti2_spec_helper"

      let(:teacher) { teacher_in_course(course:) }

      it "checks for tool installation in entire account chain" do
        user_session teacher
        allow_any_instance_of(AssignmentConfigurationToolLookup).to receive(:create_subscription).and_return true
        api_create_assignment_in_course(course, {
                                          "description" => "description",
                                          "similarityDetectionTool" => message_handler.id,
                                          "configuration_tool_type" => "Lti::MessageHandler",
                                          "submission_type" => "online",
                                          "submission_types" => ["online_upload"]
                                        })
        new_assignment = Assignment.find(JSON.parse(response.body)["id"])
        expect(new_assignment.tool_settings_tool).to eq message_handler
      end

      context "when no tool association exists" do
        let(:assignment) { assignment_model(course: @course) }
        let(:update_response) do
          put "/api/v1/courses/#{assignment.course.id}/assignments/#{assignment.id}", params: {
            assignment: { name: "banana" }
          }
        end

        it "does not attempt to clear tool associations" do
          expect(assignment).not_to receive(:clear_tool_settings_tools)
          update_response
        end
      end

      context "when a tool association already exists" do
        let(:assignment) do
          a = assignment_model(course: @course)
          a.tool_settings_tool = message_handler
          a.save!
          a
        end
        let(:update_response) do
          put "/api/v1/courses/#{assignment.course.id}/assignments/#{assignment.id}", params:
        end
        let(:lookups) { assignment.assignment_configuration_tool_lookups }

        before do
          user_session(@user)
        end

        it "shows webhook subscription information on the assignment with ?include[]=include_webhook_info" do
          tool_proxy.update(subscription_id: SecureRandom.uuid)
          json = api_call(
            :get,
            "/api/v1/courses/#{course.id}/assignments/#{assignment.id}.json",
            { controller: "assignments_api",
              action: "show",
              format: "json",
              course_id: course.id.to_s,
              id: assignment.id.to_s,
              include: "webhook_info" }
          )
          expect(json["webhook_info"]).to eq(
            {
              "product_code" => product_family.product_code,
              "vendor_code" => product_family.vendor_code,
              "resource_type_code" => "code",
              "tool_proxy_id" => tool_proxy.id,
              "tool_proxy_created_at" => tool_proxy.created_at.iso8601,
              "tool_proxy_updated_at" => tool_proxy.updated_at.iso8601,
              "tool_proxy_name" => tool_proxy.name,
              "tool_proxy_context_type" => tool_proxy.context_type,
              "tool_proxy_context_id" => tool_proxy.context_id,
              "subscription_id" => tool_proxy.subscription_id,
            }
          )
        end

        context "when changing the workflow state" do
          let(:params) do
            {
              assignment: {
                published: true
              }
            }
          end

          it "does not attempt to clear tool associations" do
            expect(assignment).not_to receive(:clear_tool_settings_tools)
            update_response
          end

          it "does not delete asset processors" do
            ap = assignment.lti_asset_processors.create!(
              context_external_tool: external_tool_1_3_model
            )
            assignment.update! submission_types: "online_upload"

            update_response
            expect(ap.reload.workflow_state).to eq("active")
          end
        end

        context "when switching to unsupported submission type" do
          let(:params) do
            {
              assignment: {
                name: "banana",
                submission_types: ["online_upload"]
              }
            }
          end

          it "destroys tool associations" do
            expect do
              update_response
            end.to change(lookups, :count).from(1).to(0)
          end
        end
      end

      context "sets the configuration LTI 2 tool" do
        shared_examples_for "sets the tools_settings_tool" do
          let(:submission_types) { raise "Override in spec" }
          let(:context) { raise "Override in spec" }

          it "sets the tool correctly" do
            tool_proxy.update(context:)
            allow_any_instance_of(AssignmentConfigurationToolLookup).to receive(:create_subscription).and_return true
            Lti::ToolProxyBinding.create(context:, tool_proxy:)
            api_create_assignment_in_course(
              @course,
              {
                "description" => "description",
                "similarityDetectionTool" => message_handler.id,
                "configuration_tool_type" => "Lti::MessageHandler",
                "submission_type" => "online",
                "submission_types" => submission_types
              }
            )
            a = Assignment.last
            expect(a.tool_settings_tool).to eq(message_handler)
          end
        end

        context "in account context" do
          context "with online_upload" do
            it_behaves_like "sets the tools_settings_tool" do
              let(:submission_types) { ["online_upload"] }
              let(:context) { @course.account }
            end
          end

          context "with online_text_entry" do
            it_behaves_like "sets the tools_settings_tool" do
              let(:submission_types) { ["online_text_entry"] }
              let(:context) { @course.account }
            end
          end
        end

        context "in course context" do
          context "with online_upload" do
            it_behaves_like "sets the tools_settings_tool" do
              let(:submission_types) { ["online_upload"] }
              let(:context) { @course }
            end
          end

          context "with online_text_entry" do
            it_behaves_like "sets the tools_settings_tool" do
              let(:submission_types) { ["online_text_entry"] }
              let(:context) { @course }
            end
          end
        end
      end
    end

    context "LTI 1.3" do
      let(:tool) do
        @course.context_external_tools.create!(
          name: "LTI Test Tool",
          consumer_key: "key",
          shared_secret: "secret",
          use_1_3: true,
          developer_key: DeveloperKey.create!,
          tool_id: "LTI Test Tool",
          url: "http://lti13testtool.docker/launch"
        )
      end
      let(:external_tool_tag_attributes) do
        {
          content_id: tool.id,
          content_type: "context_external_tool",
          custom_params: nil,
          external_data: "",
          new_tab: "0",
          url: "http://lti13testtool.docker/launch"
        }
      end
      let(:assignment_params) do
        {
          submission_types: ["external_tool"],
          external_tool_tag_attributes:
        }
      end

      context "with custom_params" do
        let(:external_tool_tag_attributes) { super().merge({ custom_params: }) }
        let(:custom_params) do
          {
            "context_id" => "$Context.id"
          }
        end

        it "creates the assignment and sets `custom_params` on the Lti::ResourceLink" do
          response = api_call(:post,
                              "/api/v1/courses/#{@course.id}/assignments",
                              {
                                controller: "assignments_api",
                                action: "create",
                                format: "json",
                                course_id: @course.id.to_s
                              },
                              { assignment: assignment_params },
                              { expected_status: 200 })

          expect(response["external_tool_tag_attributes"]["custom_params"]).to eq custom_params
          @course.reload
          expect(@course.assignments.count).to be 1
          expect(@course.assignments.last.primary_resource_link.custom).to eq custom_params
        end

        context "invalid custom params" do
          let(:custom_params) do
            {
              "hello" => {
                "there" => "general"
              }
            }
          end

          it "returns a 400 and doesn't create the assignment" do
            response = api_call(:post,
                                "/api/v1/courses/#{@course.id}/assignments",
                                {
                                  controller: "assignments_api",
                                  action: "create",
                                  format: "json",
                                  course_id: @course.id.to_s
                                },
                                { assignment: assignment_params },
                                { expected_status: 400 })
            expect(response["errors"].length).to be 1
            expect(@course.assignments.count).to be 0
          end
        end

        context "when Quizzes 2 tool is selected" do
          let(:tool) do
            @course.context_external_tools.create!(
              name: "Quizzes.Next",
              consumer_key: "test_key",
              shared_secret: "test_secret",
              tool_id: "Quizzes 2",
              url: "http://example.com/launch"
            )
          end
          let(:external_tool_tag_attributes) do
            {
              content_id: tool.id,
              content_type: "context_external_tool",
              custom_params:,
              external_data: "",
              new_tab: "0",
              url: "http://example.com/launch"
            }
          end

          it "doesn't retain peer review settings" do
            api_call(:post,
                     "/api/v1/courses/#{@course.id}/assignments",
                     {
                       controller: "assignments_api",
                       action: "create",
                       format: "json",
                       course_id: @course.id.to_s
                     },
                     { assignment: assignment_params },
                     { expected_status: 200 })

            expect(@course.assignments.last.peer_reviews).to be_falsey
          end
        end

        context "custom params isn't a Hash/JS Object" do
          let(:custom_params) { "Lies, deception!" }

          it "responds with a 400 and doesn't create the assignment" do
            api_call(:post,
                     "/api/v1/courses/#{@course.id}/assignments",
                     {
                       controller: "assignments_api",
                       action: "create",
                       format: "json",
                       course_id: @course.id.to_s
                     },
                     { assignment: assignment_params },
                     { expected_status: 400 })
            expect(@course.reload.assignments.count).to be 0
          end
        end
      end
    end

    it "does not set the configuration tool if the submission type is not online with uploads" do
      tool = @course.context_external_tools.create!(name: "a", url: "http://www.google.com", consumer_key: "12345", shared_secret: "secret")
      api_create_assignment_in_course(@course, { "description" => "description",
                                                 "similarityDetectionTool" => tool.id,
                                                 "configuration_tool_type" => "ContextExternalTool" })

      a = Assignment.last
      expect(a.tool_settings_tool).not_to eq(tool)
    end

    it "allows valid submission types as an array" do
      raw_api_call(:post,
                   "/api/v1/courses/#{@course.id}/assignments",
                   { controller: "assignments_api",
                     action: "create",
                     format: "json",
                     course_id: @course.id.to_s },
                   { assignment: {
                     "name" => "some assignment",
                     "submission_types" => [
                       "online_upload",
                       "online_url"
                     ]
                   } })
      expect(response).to be_successful
    end

    it "allows valid submission types as a string (quick add dialog)" do
      raw_api_call(:post,
                   "/api/v1/courses/#{@course.id}/assignments",
                   { controller: "assignments_api",
                     action: "create",
                     format: "json",
                     course_id: @course.id.to_s },
                   { assignment: {
                     "name" => "some assignment",
                     "submission_types" => "not_graded"
                   } })
      expect(response).to be_successful
    end

    it "does not allow unpermitted submission types" do
      raw_api_call(:post,
                   "/api/v1/courses/#{@course.id}/assignments",
                   { controller: "assignments_api",
                     action: "create",
                     format: "json",
                     course_id: @course.id.to_s },
                   { assignment: {
                     "name" => "some assignment",
                     "submission_types" => [
                       "on_papers"
                     ]
                   } })
      expect(response).to have_http_status :bad_request
    end

    it "calls SubmissionLifecycleManager only once" do
      student_in_course(course: @course, active_enrollment: true)

      @adhoc_due_at = 5.days.from_now
      @section_due_at = 7.days.from_now

      @user = @teacher

      assignment_params = {
        assignment: {
          "name" => "some assignment",
          "assignment_overrides" => {
            "0" => {
              "student_ids" => [@student.id],
              "due_at" => @adhoc_due_at.iso8601
            },
            "1" => {
              "course_section_id" => @course.default_section.id,
              "due_at" => @section_due_at.iso8601
            },
            "2" => {
              "title" => "Helpful Tag",
              "noop_id" => 999
            }
          }
        }
      }

      controller_params = {
        controller: "assignments_api",
        action: "create",
        format: "json",
        course_id: @course.id.to_s
      }

      submission_lifecycle_manager = instance_double(SubmissionLifecycleManager)
      allow(SubmissionLifecycleManager).to receive(:new).and_return(submission_lifecycle_manager)

      expect(submission_lifecycle_manager).to receive(:recompute).once

      @json = api_call(
        :post,
        "/api/v1/courses/#{@course.id}/assignments.json",
        controller_params,
        assignment_params
      )
    end

    it "allows creating an assignment with overrides via the API" do
      student_in_course(course: @course, active_enrollment: true)

      @adhoc_due_at = 5.days.from_now
      @section_due_at = 7.days.from_now

      @user = @teacher

      assignment_params = {
        assignment: {
          "name" => "some assignment",
          "assignment_overrides" => {
            "0" => {
              "student_ids" => [@student.id],
              "due_at" => @adhoc_due_at.iso8601
            },
            "1" => {
              "course_section_id" => @course.default_section.id,
              "due_at" => @section_due_at.iso8601
            },
            "2" => {
              "title" => "Helpful Tag",
              "noop_id" => 999
            }
          }
        }
      }

      controller_params = {
        controller: "assignments_api",
        action: "create",
        format: "json",
        course_id: @course.id.to_s
      }

      @json = api_call(
        :post,
        "/api/v1/courses/#{@course.id}/assignments.json",
        controller_params,
        assignment_params
      )

      @assignment = Assignment.find @json["id"]
      expect(@assignment.assignment_overrides.count).to eq 3

      @adhoc_override = @assignment.assignment_overrides.where(set_type: "ADHOC").first
      expect(@adhoc_override).not_to be_nil
      expect(@adhoc_override.set).to eq [@student]
      expect(@adhoc_override.due_at_overridden).to be_truthy
      expect(@adhoc_override.due_at.to_i).to eq @adhoc_due_at.to_i
      expect(@adhoc_override.title).to eq "1 student"

      @section_override = @assignment.assignment_overrides.where(set_type: "CourseSection").first
      expect(@section_override).not_to be_nil
      expect(@section_override.set).to eq @course.default_section
      expect(@section_override.due_at_overridden).to be_truthy
      expect(@section_override.due_at.to_i).to eq @section_due_at.to_i

      @noop_override = @assignment.assignment_overrides.where(set_type: "Noop").first
      expect(@noop_override).not_to be_nil
      expect(@noop_override.set).to be_nil
      expect(@noop_override.set_type).to eq "Noop"
      expect(@noop_override.set_id).to eq 999
      expect(@noop_override.title).to eq "Helpful Tag"
      expect(@noop_override.due_at_overridden).to be_falsey
    end

    it "accepts configuration argument to split needs grading by section" do
      student_in_course(course: @course, active_enrollment: true)
      @user = @teacher

      api_call(:post,
               "/api/v1/courses/#{@course.id}/assignments.json",
               { controller: "assignments_api",
                 action: "create",
                 format: "json",
                 course_id: @course.id.to_s },
               { assignment: {
                 "name" => "some assignment",
                 "assignment_overrides" => {
                   "0" => {
                     "student_ids" => [@student.id],
                     "title" => "some title"
                   },
                   "1" => {
                     "course_section_id" => @course.default_section.id
                   }
                 }
               } })

      assignments_json = api_call(:get,
                                  "/api/v1/courses/#{@course.id}/assignments.json",
                                  { controller: "assignments_api",
                                    action: "index",
                                    format: "json",
                                    course_id: @course.id.to_s },
                                  { needs_grading_count_by_section: "true" })
      expect(assignments_json[0].keys).to include("needs_grading_count_by_section")

      assignment_id = assignments_json[0]["id"]
      show_json = api_call(:get,
                           "/api/v1/courses/#{@course.id}/assignments/#{assignment_id}.json",
                           { controller: "assignments_api",
                             action: "show",
                             format: "json",
                             course_id: @course.id.to_s,
                             id: assignment_id.to_s },
                           { needs_grading_count_by_section: "true" })
      expect(show_json.keys).to include("needs_grading_count_by_section")
    end

    context "adhoc overrides" do
      def adhoc_override_api_call(rest_method, endpoint, action, opts = {})
        overrides = [{
          "student_ids" => opts[:student_ids] || [],
          "title" => opts[:title] || "adhoc override",
          "due_at" => opts[:adhoc_due_at] || 5.days.from_now.iso8601
        }]

        overrides.concat(opts[:additional_overrides]) if opts[:additional_overrides]
        overrides_hash = ((0...overrides.size).zip overrides).to_h

        api_params = {
          controller: "assignments_api",
          action:,
          format: "json",
          course_id: @course.id.to_s
        }
        api_params.merge!(opts[:additional_api_params]) if opts[:additional_api_params]

        api_call(rest_method,
                 "/api/v1/courses/#{@course.id}/#{endpoint}",
                 api_params,
                 {
                   assignment: {
                     "name" => "some assignment",
                     "assignment_overrides" => overrides_hash,
                   }
                 })
      end

      def api_call_to_create_adhoc_override(opts = {})
        adhoc_override_api_call(:post, "assignments.json", "create", opts)
      end

      def api_call_to_update_adhoc_override(opts = {})
        opts[:additional_api_params] = { id: @assignment.id.to_s }
        adhoc_override_api_call(:put, "assignments/#{@assignment.id}", "update", opts)
      end

      it "allows the update of an adhoc override with one more student" do
        student_in_course(course: @course, active_enrollment: true)
        @first_student = @student
        student_in_course(course: @course, active_enrollment: true)

        @user = @teacher
        json = api_call_to_create_adhoc_override(student_ids: [@student.id])

        @assignment = Assignment.find json["id"]
        @assignment.assignment_overrides.active.where(set_type: "ADHOC").first

        expect(@assignment.assignment_overrides.count).to eq 1

        api_call_to_update_adhoc_override(student_ids: [@student.id, @first_student.id])

        ao = @assignment.assignment_overrides.active.where(set_type: "ADHOC").first
        expect(ao.set).to match_array([@student, @first_student])
      end

      it "allows the update of an adhoc override with one less student" do
        student_in_course(course: @course, active_enrollment: true)
        @first_student = @student
        student_in_course(course: @course, active_enrollment: true)

        @user = @teacher
        json = api_call_to_create_adhoc_override(student_ids: [@student.id, @first_student.id])
        @assignment = Assignment.find json["id"]

        api_call_to_update_adhoc_override(student_ids: [@student.id])

        expect(AssignmentOverrideStudent.active.count).to eq 1
      end

      it "allows the update of an adhoc override with different student" do
        student_in_course(course: @course, active_enrollment: true)
        @first_student = @student
        student_in_course(course: @course, active_enrollment: true)

        @user = @teacher
        json = api_call_to_create_adhoc_override(student_ids: [@student.id])
        @assignment = Assignment.find json["id"]

        expect(@assignment.assignment_overrides.count).to eq 1

        adhoc_override = @assignment.assignment_overrides.active.where(set_type: "ADHOC").first
        expect(adhoc_override.set).to eq [@student]

        api_call_to_update_adhoc_override(student_ids: [@first_student.id])

        ao = @assignment.assignment_overrides.active.where(set_type: "ADHOC").first
        expect(ao.set).to eq [@first_student]
      end
    end

    context "notifications" do
      before :once do
        student_in_course(course: @course, active_enrollment: true)
        course_with_ta(course: @course, active_enrollment: true)
        @course.course_sections.create!

        @notification = Notification.create!(name: "Assignment Created", category: "TestImmediately")

        @student.register!
        @student.communication_channels.create(path: "student@instructure.com").confirm!
      end

      it "takes overrides into account in the assignment-created notification " \
         "for assignments created with overrides" do
        @ta.register!
        @ta.communication_channels.create(path: "ta@instructure.com").confirm!

        @override_due_at = Time.zone.parse("2002 Jun 22 12:00:00")

        @user = @teacher
        json = api_call(:post,
                        "/api/v1/courses/#{@course.id}/assignments.json",
                        {
                          controller: "assignments_api",
                          action: "create",
                          format: "json",
                          course_id: @course.id.to_s
                        },
                        { assignment: {
                          "name" => "some assignment",
                          "assignment_overrides" => {
                            "0" => {
                              "course_section_id" => @student.enrollments.first.course_section.id,
                              "due_at" => @override_due_at.iso8601
                            }
                          }
                        } })
        assignment = Assignment.find(json["id"])
        assignment.publish if assignment.unpublished?

        expect(@student.messages.detect { |m| m.notification_id == @notification.id }.body)
          .to include "Jun 22"
        expect(@ta.messages.detect { |m| m.notification_id == @notification.id }.body)
          .to include "Multiple Dates"
      end

      it "only notifies students with visibility on creation" do
        section2 = @course.course_sections.create!
        student2 = student_in_section(section2, user: user_with_communication_channel(active_all: true))

        @user = @teacher
        api_call(:post,
                 "/api/v1/courses/#{@course.id}/assignments.json",
                 {
                   controller: "assignments_api",
                   action: "create",
                   format: "json",
                   course_id: @course.id.to_s
                 },
                 { assignment: {
                   "name" => "some assignment",
                   "published" => true,
                   "only_visible_to_overrides" => true,
                   "assignment_overrides" => {
                     "0" => {
                       "course_section_id" => section2.id,
                       "due_at" => Time.zone.parse("2002 Jun 22 12:00:00").iso8601
                     }
                   }
                 } })
        expect(@student.messages).to be_empty
        expect(student2.messages.detect { |m| m.notification_id == @notification.id }).to be_present
      end

      it "sends notification of creation on save and publish" do
        assignment = @course.assignments.new(name: "blah")
        assignment.workflow_state = "unpublished"
        assignment.save!

        @user = @teacher
        api_call(:put,
                 "/api/v1/courses/#{@course.id}/assignments/#{assignment.id}",
                 {
                   controller: "assignments_api",
                   action: "update",
                   format: "json",
                   course_id: @course.id.to_s,
                   id: assignment.to_param
                 },
                 { assignment: {
                   "published" => true,
                   "assignment_overrides" => {
                     "0" => {
                       "course_section_id" => @student.enrollments.first.course_section.id,
                       "due_at" => 1.day.from_now.iso8601
                     }
                   }
                 } })
        expect(@student.messages.detect { |m| m.notification_id == @notification.id }).to be_present
      end

      it "sends notification on due date update (even if other overrides are passed in)" do
        section2 = @course.course_sections.create!
        assignment = @course.assignments.create!(name: "blah", workflow_state: "published", due_at: 1.hour.from_now)
        Assignment.where(id: assignment).update_all(created_at: 5.hours.ago)

        notification = Notification.create!(name: "Assignment Due Date Changed")
        @student.email_channel.notification_policies.create!(notification:, frequency: "immediately")

        @user = @teacher
        api_call(:put,
                 "/api/v1/courses/#{@course.id}/assignments/#{assignment.id}",
                 {
                   controller: "assignments_api",
                   action: "update",
                   format: "json",
                   course_id: @course.id.to_s,
                   id: assignment.to_param
                 },
                 {
                   assignment: {
                     "due_at" => 2.days.from_now.iso8601,
                     "assignment_overrides" => { "0" => { "course_section_id" => section2.id, "due_at" => 1.day.from_now.iso8601 } }
                   }
                 })
        expect(@student.messages.detect { |m| m.notification_id == notification.id }).to be_present
      end

      it "uses new overrides for notifications of creation on save and publish" do
        assignment = @course.assignments.create!(name: "blah",
                                                 workflow_state: "unpublished",
                                                 only_visible_to_overrides: true)
        assignment.assignment_overrides.create!(title: "blah", set: @course.default_section, set_type: "CourseSection")

        section2 = @course.course_sections.create!
        student2 = student_in_section(section2, user: user_with_communication_channel(active_all: true))

        @user = @teacher
        api_call(:put,
                 "/api/v1/courses/#{@course.id}/assignments/#{assignment.id}",
                 {
                   controller: "assignments_api",
                   action: "update",
                   format: "json",
                   course_id: @course.id.to_s,
                   id: assignment.to_param
                 },
                 {
                   assignment: {
                     "published" => true,
                     "assignment_overrides" => {
                       "0" => {
                         "course_section_id" => section2.id,
                         "due_at" => 1.day.from_now.iso8601
                       }
                     }
                   }
                 })
        expect(@student.messages).to be_empty
        expect(student2.messages.detect { |m| m.notification_id == @notification.id }).to be_present
      end

      it "updates only_visible_to_overrides to false if updating overall date" do
        assignment = @course.assignments.create!(name: "blah",
                                                 workflow_state: "unpublished",
                                                 only_visible_to_overrides: true)
        section2 = @course.course_sections.create!

        @user = @teacher
        json = api_call(:put,
                        "/api/v1/courses/#{@course.id}/assignments/#{assignment.id}",
                        {
                          controller: "assignments_api",
                          action: "update",
                          format: "json",
                          course_id: @course.id.to_s,
                          id: assignment.to_param
                        },
                        {
                          assignment: {
                            "published" => true,
                            "due_at" => 1.day.from_now.iso8601,
                            "assignment_overrides" => {
                              "0" => {
                                "course_section_id" => section2.id,
                                "due_at" => 1.day.from_now.iso8601
                              }
                            }
                          }
                        })
        expect(json["only_visible_to_overrides"]).to be false
      end
    end

    it "does not allow an assignment_group_id that is not a number" do
      student_in_course(course: @course, active_enrollment: true)
      @user = @teacher

      raw_api_call(:post,
                   "/api/v1/courses/#{@course.id}/assignments",
                   { controller: "assignments_api",
                     action: "create",
                     format: "json",
                     course_id: @course.id.to_s },
                   { assignment: {
                     "name" => "some assignment",
                     "assignment_group_id" => "foo"
                   } })

      expect(response).not_to be_successful
      json = JSON.parse response.body
      expect(json["errors"]["assignment[assignment_group_id]"].first["message"])
        .to eq "must be a positive number"
    end

    context "discussion topic assignments" do
      it "prevents creating assignments with group category IDs and discussions" do
        course_with_teacher(active_all: true)
        group_category = @course.group_categories.create!(name: "foo")
        raw_api_call(:post,
                     "/api/v1/courses/#{@course.id}/assignments",
                     { controller: "assignments_api",
                       action: "create",
                       format: "json",
                       course_id: @course.id.to_s },
                     { assignment: {
                       "name" => "some assignment",
                       "group_category_id" => group_category.id,
                       "submission_types" => [
                         "discussion_topic"
                       ],
                       "discussion_topic" => {
                         "title" => "some assignment"
                       }
                     } })
        expect(response).to have_http_status :bad_request
      end
    end

    context "with grading periods" do
      def call_create(params, expected_status)
        api_call_as_user(
          @current_user,
          :post,
          "/api/v1/courses/#{@course.id}/assignments",
          {
            controller: "assignments_api",
            action: "create",
            format: "json",
            course_id: @course.id.to_s
          },
          {
            assignment: create_assignment_json(@group, @group_category).merge(params)
          },
          {},
          { expected_status: }
        )
      end

      before :once do
        grading_period_group = Factories::GradingPeriodGroupHelper.new.create_for_account(@course.root_account)
        term = @course.enrollment_term
        term.grading_period_group = grading_period_group
        term.save!
        Factories::GradingPeriodHelper.new.create_for_group(grading_period_group, {
                                                              start_date: 2.weeks.ago, end_date: 2.days.ago, close_date: 1.day.ago
                                                            })
        course_with_student(course: @course)
        account_admin_user(account: @course.root_account)
        @group = @course.assignment_groups.create!(name: "Example Group")
        @group_category = @course.group_categories.create!(name: "Example Group Category")
      end

      context "when the user is a teacher" do
        before do
          @current_user = @teacher
        end

        it "allows setting the due date in an open grading period" do
          due_date = 3.days.from_now.iso8601
          call_create({ due_at: due_date, lock_at: nil, unlock_at: nil }, 201)
          expect(@course.assignments.last.due_at).to eq due_date
        end

        it "does not allow setting the due date in a closed grading period" do
          call_create({ due_at: 3.days.ago.iso8601, lock_at: nil, unlock_at: nil }, 403)
          json = JSON.parse response.body
          expect(json["errors"].keys).to include "due_at"
        end

        it "allows setting the due date in a closed grading period when only visible to overrides" do
          due_date = 3.days.ago.iso8601
          call_create({ due_at: due_date, lock_at: nil, unlock_at: nil, only_visible_to_overrides: true }, 201)
          expect(@course.assignments.last.due_at).to eq due_date
        end

        it "does not allow a nil due date when the last grading period is closed" do
          call_create({ due_at: nil }, 403)
          json = JSON.parse response.body
          expect(json["errors"].keys).to include "due_at"
        end

        it "does not allow setting an override due date in a closed grading period" do
          override_params = [{ student_ids: [@student.id], due_at: 3.days.ago.iso8601, lock_at: nil, unlock_at: nil }]
          params = { due_at: 3.days.from_now.iso8601, assignment_overrides: override_params }
          call_create(params, 403)
          json = JSON.parse response.body
          expect(json["errors"].keys).to include "due_at"
        end

        it "does not allow a nil override due date when the last grading period is closed" do
          override_params = [{ student_ids: [@student.id], due_at: nil }]
          params = { due_at: 3.days.from_now.iso8601,
                     assignment_overrides: override_params,
                     lock_at: nil,
                     unlock_at: nil }
          call_create(params, 403)
          json = JSON.parse response.body
          expect(json["errors"].keys).to include "due_at"
        end

        it "allows a due date in a closed grading period when the assignment is not graded" do
          due_date = 3.days.ago.iso8601
          call_create({ due_at: due_date, lock_at: nil, unlock_at: nil, submission_types: "not_graded" }, 201)
          expect(@course.assignments.last.due_at).to eq due_date
        end

        it "allows a nil due date when not graded and the last grading period is closed" do
          call_create({ due_at: nil, submission_types: "not_graded" }, 201)
          expect(@course.assignments.last.due_at).to be_nil
        end

        it "ignores setting allowed_attempts to -1 when it's actually nil on the model" do
          @assignment = @course.assignments.create!(due_at: 3.days.ago.iso8601)
          api_call_as_user(@current_user,
                           :put,
                           "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}",
                           { controller: "assignments_api", action: "update", format: "json", course_id: @course.id.to_s, id: @assignment.to_param },
                           { assignment: { description: "new description", allowed_attempts: -1 } },
                           {},
                           { expected_status: 200 })
          expect(@assignment.reload.description).to eq "new description"
        end
      end

      context "when the user is an admin" do
        before do
          @current_user = @admin
        end

        it "allows setting the due date in a closed grading period" do
          due_date = 3.days.ago.iso8601
          call_create({ due_at: due_date, lock_at: nil, unlock_at: nil }, 201)
          json = JSON.parse response.body
          expect(json["due_at"]).to eq due_date
        end

        it "allows a nil due date when the last grading period is closed" do
          call_create({ due_at: nil }, 201)
          json = JSON.parse response.body
          expect(json["due_at"]).to be_nil
        end

        it "allows setting an override due date in a closed grading period" do
          due_date = 3.days.ago.iso8601
          override_params = [{ student_ids: [@student.id], due_at: due_date }]
          params = { due_at: 5.days.from_now.iso8601, lock_at: nil, assignment_overrides: override_params }
          call_create(params, 201)
          json = JSON.parse response.body
          assignment = Assignment.find(json["id"])
          expect(assignment.assignment_overrides.first.due_at).to eq due_date
        end

        it "allows a nil override due date when the last grading period is closed" do
          override_params = [{ student_ids: [@student.id], due_at: nil }]
          params = { due_at: 3.days.from_now.iso8601, lock_at: nil, assignment_overrides: override_params }
          call_create(params, 201)
          json = JSON.parse response.body
          assignment = Assignment.find(json["id"])
          expect(assignment.assignment_overrides.first.due_at).to be_nil
        end
      end
    end

    context "sis validations enabled" do
      before do
        a = @course.account
        a.enable_feature!(:new_sis_integrations)
        a.settings[:sis_syncing] = { value: true }
        a.settings[:sis_require_assignment_due_date] = { value: true }
        a.save!
      end

      it "saves with a section override with a valid due_date" do
        assignment_params = {
          "post_to_sis" => true,
          "assignment_overrides" => {
            "0" => {
              "course_section_id" => @course.default_section.id,
              "due_at" => 7.days.from_now.iso8601
            }
          }
        }

        json = api_create_assignment_in_course(@course, assignment_params)

        expect(json["errors"]).to be_nil
      end

      it "does not save with a section override without a due date" do
        assignment_params = {
          "post_to_sis" => true,
          "assignment_overrides" => {
            "0" => {
              "course_section_id" => @course.default_section.id,
              "due_at" => nil
            }
          }
        }

        json = api_create_assignment_in_course(@course, assignment_params)

        expect(json["errors"]&.keys).to eq ["due_at"]
      end

      it "saves with an empty section override" do
        assignment_params = {
          "due_at" => 7.days.from_now.iso8601,
          "post_to_sis" => true,
          "assignment_overrides" => {}
        }

        json = api_create_assignment_in_course(@course, assignment_params)

        expect(json["errors"]).to be_nil
      end

      it "does not save without a due date" do
        json = api_create_assignment_in_course(@course, "post_to_sis" => true)

        expect(json["errors"]&.keys).to eq ["due_at"]
      end

      it "saves with an assignment with a valid due_date" do
        assignment_params = {
          "post_to_sis" => true,
          "due_at" => 7.days.from_now.iso8601
        }

        json = api_create_assignment_in_course(@course, assignment_params)

        expect(json["errors"]).to be_nil
      end

      it "saves with an assignment with a valid title" do
        account = @course.account
        account.settings[:sis_assignment_name_length] = { value: true }
        account.settings[:sis_assignment_name_length_input] = { value: 10 }
        account.save!

        assignment_params = {
          "name" => "Gil Faizon",
          "post_to_sis" => true,
          "due_at" => 7.days.from_now.iso8601
        }

        json = api_create_assignment_in_course(@course, assignment_params)

        expect(json["errors"]).to be_nil
      end

      it "does not save with an assignment with an invalid title length" do
        account = @course.account
        account.settings[:sis_assignment_name_length] = { value: true }
        account.settings[:sis_assignment_name_length_input] = { value: 10 }
        account.save!

        assignment_params = {
          "name" => "Too Much Tuna",
          "post_to_sis" => true,
          "due_at" => 7.days.from_now.iso8601
        }

        json = api_create_assignment_in_course(@course, assignment_params)

        expect(json["errors"]).to_not be_nil
        expect(json["errors"]&.keys).to eq ["title"]
        expect(json["errors"]["title"].first["message"]).to eq("The title cannot be longer than 10 characters")
      end

      it "caches overrides correctly" do
        enable_cache(:redis_cache_store) do
          sec1 = @course.course_sections.create! name: "sec1"
          sec2 = @course.course_sections.create! name: "sec2"
          json = api_create_assignment_in_course(@course,
                                                 { name: "test",
                                                   post_to_sis: true,
                                                   assignment_overrides: [
                                                     { course_section_id: sec1.id, due_at: 1.week.from_now },
                                                     { course_section_id: sec2.id, due_at: 2.weeks.from_now }
                                                   ] })
          assignment = Assignment.find(json["id"])
          cached_overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(assignment, @teacher)
          expect(cached_overrides.map(&:set)).to match_array([sec1, sec2])
        end
      end
    end
  end

  describe "PUT /courses/:course_id/assignments/:id (#update)" do
    before :once do
      course_with_teacher(active_all: true)
    end

    context "when the current user can update assignments but cannot grade submissions" do
      before(:once) do
        course_with_student(active_all: true)
        @course.account.role_overrides.create!(permission: "manage_grades", enabled: false, role: admin_role)
        account_admin_user(active_all: true)
        @assignment = @course.assignments.create!(
          name: "some assignment",
          grading_type: "points",
          points_possible: 15
        )
        @assignment.grade_student(@student, grade: 15, grader: @teacher)
      end

      it "succeeds if points possible is provided but it matches current points possible" do
        api_update_assignment_call(@course, @assignment, { points_possible: 15 })
        expect(response).to be_successful
      end

      it "returns unauthorized if attempting to change points possible" do
        api_update_assignment_call(@course, @assignment, { points_possible: 12 })
        expect(response).to be_forbidden
      end

      it "succeeds if grading_type is provided but it matches current grading_type" do
        api_update_assignment_call(@course, @assignment, { grading_type: "points" })
        expect(response).to be_successful
      end

      it "returns unauthorized if attempting to change grading_type" do
        api_update_assignment_call(@course, @assignment, { grading_type: "percent" })
        expect(response).to be_forbidden
      end

      it "succeeds if grading_standard_id is provided but it matches current grading_standard_id" do
        grading_standard = grading_standard_for(@course)
        @assignment.update!(grading_standard:)
        api_update_assignment_call(@course, @assignment, { grading_standard_id: grading_standard.id })
        expect(response).to be_successful
      end

      it "succeeds if grading_standard_id is empty string and assignment does not have a grading standard" do
        api_update_assignment_call(@course, @assignment, { grading_standard_id: "" })
        expect(response).to be_successful
      end

      it "returns forbidden if attempting to change grading_standard_id" do
        grading_standard = grading_standard_for(@course)
        @assignment.update!(grading_standard:)
        api_update_assignment_call(@course, @assignment, { grading_standard_id: nil })
        expect(response).to be_forbidden
      end

      it "succeeds if not provided attributes that trigger a regrade" do
        api_update_assignment_call(@course, @assignment, { title: "changed assignment name" })
        expect(response).to be_successful
      end
    end

    it "returns forbidden for users who do not have permission" do
      course_with_student(active_all: true)
      @assignment = @course.assignments.create!({
                                                  name: "some assignment",
                                                  points_possible: 15
                                                })

      api_update_assignment_call(@course, @assignment, { points_possible: 10 })

      expect(response).to have_http_status :forbidden
    end

    it "allows user with grading rights to update assignment grading type" do
      course_with_student(active_all: true)
      @assignment = @course.assignments.create!(
        name: "some assignment",
        points_possible: 15,
        grading_type: "points"
      )
      @assignment.grade_student(@student, grade: 15, grader: @teacher)

      @user = @teacher
      api_update_assignment_call(@course, @assignment, { grading_type: "percent" })
      expect(response).to be_successful
      expect(@assignment.grading_type).to eq "percent"
    end

    it "allows user without grading rights to update non-grading attributes on a graded assignment" do
      course_with_student(active_all: true)
      @assignment = @course.assignments.create!(
        name: "some assignment",
        points_possible: 15,
        grading_type: "points"
      )
      @assignment.grade_student(@student, grade: 15, grader: @teacher)
      RoleOverride.create!(permission: "manage_grades", enabled: false, context: @course.account, role: admin_role)
      account_admin_user(active_all: true)

      api_update_assignment_call(@course, @assignment, { name: "some really cool assignment" })
      expect(response).to be_successful
      expect(@assignment.name).to eq "some really cool assignment"
    end

    it "allows user to update grading_type without grading rights when no submissions have been graded" do
      @assignment = @course.assignments.create!(
        name: "some assignment",
        points_possible: 15,
        grading_type: "points"
      )

      RoleOverride.create!(permission: "manage_grades", enabled: false, context: @course.account, role: admin_role)
      account_admin_user(active_all: true)

      api_update_assignment_call(@course, @assignment, { grading_type: "percent" })
      expect(response).to be_successful
      expect(@assignment.grading_type).to eq "percent"
    end

    it "updates published/unpublished" do
      @assignment = @course.assignments.create({
                                                 name: "some assignment",
                                                 points_possible: 15
                                               })
      @assignment.workflow_state = "unpublished"
      @assignment.save!

      # change it to published
      api_update_assignment_call(@course, @assignment, { "published" => true })
      @assignment.reload
      expect(@assignment.workflow_state).to eq "published"

      # change it back to unpublished
      api_update_assignment_call(@course, @assignment, { "published" => false })
      @assignment.reload
      expect(@assignment.workflow_state).to eq "unpublished"

      course_with_student(active_all: true, course: @course)
      @assignment.submit_homework(@student, submission_type: "online_text_entry")
      @assignment.publish
      @user = @teacher
      raw_api_call(
        :put,
        "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}.json",
        {
          controller: "assignments_api",
          action: "update",
          format: "json",
          course_id: @course.id.to_s,
          id: @assignment.id.to_s
        },
        { assignment: { published: false } }
      )
      expect(response).not_to be_successful
      json = JSON.parse response.body
      expect(json["errors"]["published"].first["message"])
        .to eq "Can't unpublish if there are student submissions"
    end

    it "updates using lti_context_id" do
      @assignment = @course.assignments.create({
                                                 name: "some assignment",
                                                 points_possible: 15
                                               })
      raw_api_call(:put,
                   "/api/v1/courses/#{@course.id}/assignments/lti_context_id:#{@assignment.lti_context_id}.json",
                   { controller: "assignments_api",
                     action: "update",
                     format: "json",
                     course_id: @course.id.to_s,
                     id: "lti_context_id:#{@assignment.lti_context_id}" },
                   {
                     assignment: { published: false }
                   })
      expect(JSON.parse(response.body)["id"]).to eq @assignment.id
    end

    it "400s with invalid date times" do
      the_date = 1.day.ago
      @assignment = @course.assignments.create({
                                                 name: "some assignment",
                                                 points_possible: 15
                                               })
      @assignment.due_at = the_date
      @assignment.lock_at = the_date
      @assignment.unlock_at = the_date
      @assignment.peer_reviews_assign_at = the_date
      @assignment.save!
      raw_api_update_assignment(@course,
                                @assignment,
                                { "peer_reviews_assign_at" => "1/1/2013" })
      expect(response).not_to be_successful
      expect(response).to have_http_status :bad_request
      json = JSON.parse response.body
      expect(json["errors"]["assignment[peer_reviews_assign_at]"].first["message"])
        .to eq "Invalid datetime for peer_reviews_assign_at"
    end

    it "allows clearing dates" do
      the_date = 1.day.ago
      @assignment = @course.assignments.create({
                                                 name: "some assignment",
                                                 points_possible: 15
                                               })
      @assignment.due_at = the_date
      @assignment.lock_at = the_date
      @assignment.unlock_at = the_date
      @assignment.peer_reviews_assign_at = the_date
      @assignment.save!

      api_update_assignment_call(@course,
                                 @assignment,
                                 { "due_at" => nil,
                                   "lock_at" => "",
                                   "unlock_at" => nil,
                                   "peer_reviews_assign_at" => nil })
      expect(response).to be_successful
      @assignment.reload

      expect(@assignment.due_at).to be_nil
      expect(@assignment.lock_at).to be_nil
      expect(@assignment.unlock_at).to be_nil
      expect(@assignment.peer_reviews_assign_at).to be_nil
    end

    it "unsets submission types if set to not_graded" do
      # the same way it would in the UI
      @assignment = @course.assignments.create!(
        name: "some assignment",
        points_possible: 15,
        submission_types: "online_text_entry",
        grading_type: "percent"
      )

      api_update_assignment_call(@course, @assignment, { "grading_type" => "not_graded" })
      expect(response).to be_successful
      @assignment.reload

      expect(@assignment.grading_type).to eq "not_graded"
      expect(@assignment.submission_types).to eq "not_graded"
    end

    it "leaves ab_guid alone if not included in update params" do
      @assignment = @course.assignments.create!(
        name: "some assignment",
        points_possible: 15,
        submission_types: "online_text_entry",
        grading_type: "percent",
        ab_guid: ["a", "b"]
      )
      api_update_assignment_call(@course, @assignment, title: "new title")
      expect(response).to be_successful
      expect(@assignment.reload.ab_guid).to eq ["a", "b"]
    end

    it "updates ab_guid if included in update params" do
      @assignment = @course.assignments.create!(
        name: "some assignment",
        points_possible: 15,
        submission_types: "online_text_entry",
        grading_type: "percent",
        ab_guid: ["a", "b"]
      )
      api_update_assignment_call(@course, @assignment, ab_guid: ["c", "d"])
      expect(response).to be_successful
      expect(@assignment.reload.ab_guid).to eq ["c", "d"]
    end

    it "updates ab_guid to empty array if included in update params and empty" do
      @assignment = @course.assignments.create!(
        name: "some assignment",
        points_possible: 15,
        submission_types: "online_text_entry",
        grading_type: "percent",
        ab_guid: ["a", "b"]
      )
      api_update_assignment_call(@course, @assignment, ab_guid: [])
      expect(response).to be_successful
      expect(@assignment.reload.ab_guid).to eq []
    end

    it "updates ab_guid to empty array if included in update params and is empty string" do
      @assignment = @course.assignments.create!(
        name: "some assignment",
        points_possible: 15,
        submission_types: "online_text_entry",
        grading_type: "percent",
        ab_guid: ["a", "b"]
      )
      api_update_assignment_call(@course, @assignment, ab_guid: "")
      expect(response).to be_successful
      expect(@assignment.reload.ab_guid).to eq []
    end

    it "updates ab_guid to a single element array if a string is passed in" do
      @assignment = @course.assignments.create!(
        name: "some assignment",
        points_possible: 15,
        submission_types: "online_text_entry",
        grading_type: "percent",
        ab_guid: ["a", "b"]
      )
      api_update_assignment_call(@course, @assignment, ab_guid: "c")
      expect(response).to be_successful
      expect(@assignment.reload.ab_guid).to eq ["c"]
    end

    describe "annotatable attachment" do
      before(:once) do
        @assignment = @course.assignments.create!(name: "Some Assignment")
        @attachment = attachment_model(content_type: "application/pdf", context: @course)
      end

      let(:endpoint_params) do
        {
          action: :update,
          controller: :assignments_api,
          course_id: @course.id,
          format: :json,
          id: @assignment.id
        }
      end

      it "sets the assignment's annotatable_attachment_id when id is present and type is student_annotation" do
        @attachment.update!(folder: @course.student_annotation_documents_folder)

        api_call(
          :put,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}",
          endpoint_params,
          { assignment: { annotatable_attachment_id: @attachment.id, submission_types: ["student_annotation"] } }
        )
        expect(@assignment.reload.annotatable_attachment_id).to be @attachment.id
      end

      it "copies the given attachment to a special folder and uses that attachment instead of the supplied one" do
        api_call(
          :put,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}",
          endpoint_params,
          { assignment: { annotatable_attachment_id: @attachment.id, submission_types: ["student_annotation"] } }
        )

        annotation_documents_folder = @course.student_annotation_documents_folder
        clone_attachment = annotation_documents_folder.active_file_attachments.find_by(md5: @attachment.md5)
        expect(@assignment.reload.annotatable_attachment_id).to be clone_attachment.id
      end

      it "does not set the assignment's annotatable_attachment_id when type is not student_annotation" do
        api_call(
          :put,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}",
          endpoint_params,
          { assignment: { annotatable_attachment_id: @attachment.id, submission_types: ["online_text_entry"] } }
        )
        expect(@assignment.reload.annotatable_attachment_id).to be_nil
      end

      it "returns bad_request when the user did not include an attachment id for an student_annotation type" do
        api_call(
          :put,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}",
          endpoint_params,
          { assignment: { submission_types: ["student_annotation"] } }
        )

        expect(response).to have_http_status(:bad_request)
      end

      it "returns bad_request when the user doesn't have read access to the attachment" do
        second_course = Course.create!
        attachment_attrs = valid_attachment_attributes.merge(context: second_course)
        second_attachment = Attachment.create!(attachment_attrs)

        api_call(
          :put,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}",
          endpoint_params,
          { assignment: { annotatable_attachment_id: second_attachment.id, submission_types: ["student_annotation"] } }
        )

        aggregate_failures do
          expect(response).to have_http_status(:bad_request)
          expect(@assignment.reload.annotatable_attachment_id).to be_nil
        end
      end

      it "returns bad_request when the attachment doesn't exist" do
        api_call(
          :put,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}",
          endpoint_params,
          { assignment: { annotatable_attachment_id: Attachment.last.id + 1, submission_types: ["student_annotation"] } }
        )

        aggregate_failures do
          expect(response).to have_http_status(:bad_request)
          expect(@assignment.reload.annotatable_attachment_id).to be_nil
        end
      end

      it "removes the assignment's annotatable_attachment_id when an empty string is passed" do
        api_call(
          :put,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}",
          endpoint_params,
          { assignment: { annotatable_attachment_id: "" } }
        )
        expect(@assignment.reload.annotatable_attachment_id).to be_nil
      end

      it "removes the assignment's annotatable_attachment_id when the type is not student_annotation" do
        @assignment.update!(annotatable_attachment: @attachment)

        api_call(
          :put,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}",
          endpoint_params,
          { assignment: { annotatable_attachment_id: @attachment.id, submission_types: ["online_text_entry"] } }
        )
        expect(@assignment.reload.annotatable_attachment_id).to be_nil
      end

      it "does not remove the assignment's annotatable_attachment_id when submission_types is not a param" do
        @assignment.update!(annotatable_attachment: @attachment)

        expect do
          api_call(
            :put,
            "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}",
            endpoint_params,
            { assignment: { name: "unrelated change to attachment" } }
          )
        end.not_to change {
          @assignment.reload.annotatable_attachment_id
        }
      end
    end

    describe "final_grader_id" do
      before(:once) do
        course_with_teacher(active_all: true)
        course_with_teacher(active_all: true)
      end

      it 'allows updating final_grader_id for a participating instructor with "Select Final Grade" permissions' do
        assignment = @course.assignments.create!(name: "Some Assignment", moderated_grading: true, grader_count: 2)
        api_call(
          :put,
          "/api/v1/courses/#{@course.id}/assignments/#{assignment.id}",
          {
            controller: "assignments_api",
            action: "update",
            format: "json",
            course_id: @course.id,
            id: assignment.to_param
          },
          { assignment: { final_grader_id: @teacher.id } }
        )
        expect(json_parse(response.body)["final_grader_id"]).to eq @teacher.id
      end

      it 'does not allow updating final_grader_id if the user does not have "Select Final Grade" permissions' do
        assignment = @course.assignments.create!(name: "Some Assignment", moderated_grading: true, grader_count: 2)
        @course.root_account.role_overrides.create!(
          permission: "select_final_grade",
          role: teacher_role,
          enabled: false
        )
        api_call(
          :put,
          "/api/v1/courses/#{@course.id}/assignments/#{assignment.id}",
          {
            controller: "assignments_api",
            action: "update",
            format: "json",
            course_id: @course.id,
            id: assignment.to_param
          },
          { assignment: { final_grader_id: @teacher.id } }
        )
        error = json_parse(response.body)["errors"]["final_grader_id"].first
        expect(error["message"]).to eq "user does not have permission to select final grade"
      end

      it "does not allow updating final_grader_id if the user is not active in the course" do
        assignment = @course.assignments.create!(name: "Some Assignment", moderated_grading: true, grader_count: 2)
        deactivated_teacher = User.create!
        deactivated_teacher = @course.enroll_teacher(deactivated_teacher, enrollment_state: "inactive")
        api_call(
          :put,
          "/api/v1/courses/#{@course.id}/assignments/#{assignment.id}",
          {
            controller: "assignments_api",
            action: "update",
            format: "json",
            course_id: @course.id,
            id: assignment.to_param
          },
          { assignment: { final_grader_id: deactivated_teacher.id } }
        )
        error = json_parse(response.body)["errors"]["final_grader_id"].first
        expect(error["message"]).to eq "course has no active instructors with this ID"
      end

      it "does not allow updating final_grader_id if the course has no user with the supplied ID" do
        user_not_enrolled_in_course = User.create!
        assignment = @course.assignments.create!(name: "Some Assignment", moderated_grading: true, grader_count: 2)
        api_call(
          :put,
          "/api/v1/courses/#{@course.id}/assignments/#{assignment.id}",
          {
            controller: "assignments_api",
            action: "update",
            format: "json",
            course_id: @course.id,
            id: assignment.to_param
          },
          { assignment: { final_grader_id: user_not_enrolled_in_course.id } }
        )
        error = json_parse(response.body)["errors"]["final_grader_id"].first
        expect(error["message"]).to eq "course has no active instructors with this ID"
      end
    end

    it "allows updating grader_count" do
      course_with_teacher(active_all: true)
      assignment = @course.assignments.create!(name: "Some Assignment", moderated_grading: true, grader_count: 1)
      api_call(
        :put,
        "/api/v1/courses/#{@course.id}/assignments/#{assignment.id}",
        {
          controller: "assignments_api",
          action: "update",
          format: "json",
          course_id: @course.id,
          id: assignment.to_param
        },
        { assignment: { grader_count: 4 } }
      )
      expect(json_parse(response.body)["grader_count"]).to eq 4
    end

    it "allows updating graders_anonymous_to_graders" do
      course_with_teacher(active_all: true)
      assignment = @course.assignments.create!(name: "Some Assignment", moderated_grading: true, grader_count: 2)
      api_call(
        :put,
        "/api/v1/courses/#{@course.id}/assignments/#{assignment.id}",
        {
          controller: "assignments_api",
          action: "update",
          format: "json",
          course_id: @course.id,
          id: assignment.to_param
        },
        { assignment: { graders_anonymous_to_graders: true } }
      )
      expect(json_parse(response.body)["graders_anonymous_to_graders"]).to be true
    end

    it "allows updating grader_comments_visible_to_graders" do
      course_with_teacher(active_all: true)
      assignment = @course.assignments.create!(name: "Some Assignment", moderated_grading: true, grader_count: 2)
      api_call(
        :put,
        "/api/v1/courses/#{@course.id}/assignments/#{assignment.id}",
        {
          controller: "assignments_api",
          action: "update",
          format: "json",
          course_id: @course.id,
          id: assignment.to_param
        },
        { assignment: { grader_comments_visible_to_graders: false } }
      )
      expect(json_parse(response.body)["grader_comments_visible_to_graders"]).to be false
    end

    it "allows updating grader_names_visible_to_final_grader" do
      course_with_teacher(active_all: true)
      assignment = @course.assignments.create!(name: "Some Assignment", moderated_grading: true, grader_count: 2)
      api_call(
        :put,
        "/api/v1/courses/#{@course.id}/assignments/#{assignment.id}",
        {
          controller: "assignments_api",
          action: "update",
          format: "json",
          course_id: @course.id,
          id: assignment.to_param
        },
        { assignment: { grader_names_visible_to_final_grader: false } }
      )
      expect(json_parse(response.body)["grader_names_visible_to_final_grader"]).to be false
    end

    it "does not allow updating an assignment title to longer than 255 characters" do
      course_with_teacher(active_all: true)
      name_too_long = "a" * 256
      # create an assignment
      @json = api_create_assignment_in_course(@course, { "name" => "some name" })
      @assignment = Assignment.find @json["id"]
      @assignment.reload

      # not update an assignment with a name too long
      raw_api_call(
        :put,
        "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}.json",
        {
          controller: "assignments_api",
          action: "update",
          format: "json",
          course_id: @course.id.to_s,
          id: @assignment.id.to_s
        },
        { assignment: { "name" => name_too_long } }
      )
      assert_status(400)
      @assignment.reload
      expect(@assignment.name).to eq "some name"
    end

    it "disallows updating deleted assignments" do
      course_with_teacher(active_all: true)
      @assignment = @course.assignments.create!({
                                                  name: "some assignment",
                                                  points_possible: 15
                                                })
      @assignment.destroy

      api_call(:put,
               "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}",
               {
                 controller: "assignments_api",
                 action: "update",
                 format: "json",
                 course_id: @course.id.to_s,
                 id: @assignment.to_param
               },
               { "points_possible" => 10 },
               {},
               { expected_status: 404 })
    end

    it "allows trying to update points (that get ignored) on an ungraded assignment when locked" do
      other_course = Account.default.courses.create!
      template = MasterCourses::MasterTemplate.set_as_master_course(other_course)
      original_assmt = other_course.assignments.create!(title: "blah", description: "bloo")
      tag = template.create_content_tag_for!(original_assmt, restrictions: { points: true })

      course_with_teacher(active_all: true)
      @assignment = @course.assignments.create!(name: "something", migration_id: tag.migration_id, submission_types: "not_graded")

      api_call(:put,
               "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}.json",
               {
                 controller: "assignments_api",
                 action: "update",
                 format: "json",
                 course_id: @course.id.to_s,
                 id: @assignment.id.to_s
               },
               { assignment: { points_possible: 0 } },
               {},
               { expected_status: 200 })
    end

    context "without overrides or frozen attributes" do
      before :once do
        @start_group = @course.assignment_groups.create!({ name: "start group" })
        @group = @course.assignment_groups.create!({ name: "new group" })
        @assignment = @course.assignments.create!(title: "some assignment",
                                                  points_possible: 15,
                                                  description: "blah",
                                                  position: 2,
                                                  peer_review_count: 2,
                                                  peer_reviews: true,
                                                  peer_reviews_due_at: Time.zone.now,
                                                  grading_type: "percent",
                                                  due_at: nil)
        @assignment.assignment_group = @start_group
        @assignment.group_category = @assignment.context.group_categories.create!(name: "foo")
        @assignment.save!

        @new_grading_standard = grading_standard_for(@course)
      end

      before do
        @json = api_update_assignment_call(@course, @assignment, {
                                             "name" => "some assignment",
                                             "points_possible" => "12",
                                             "assignment_group_id" => @group.id,
                                             "peer_reviews" => false,
                                             "grading_standard_id" => @new_grading_standard.id,
                                             "group_category_id" => nil,
                                             "description" => "assignment description",
                                             "grading_type" => "letter_grade",
                                             "due_at" => "2011-01-01T00:00:00Z",
                                             "position" => 1,
                                             "allowed_attempts" => 10
                                           })
        @assignment.reload
      end

      it "returns, but does not update, the assignment's id" do
        expect(@json["id"]).to eq @assignment.id
      end

      it "updates the assignment's assignment group id" do
        expect(@assignment.assignment_group_id).to eq @group.id
        expect(@json["assignment_group_id"]).to eq @group.id
      end

      it "updates the title/name of the assignment" do
        expect(@assignment.title).to eq "some assignment"
        expect(@json["name"]).to eq "some assignment"
      end

      it "returns, but doesn't update, the assignment's course_id" do
        expect(@assignment.context_id).to eq @course.id
        expect(@json["course_id"]).to eq @course.id
      end

      it "updates the assignment's description" do
        expect(@assignment.description).to eq "assignment description"
        expect(@json["description"]).to eq "assignment description"
      end

      it "updates the assignment's position" do
        expect(@assignment.position).to eq 1
        expect(@json["position"]).to eq @assignment.position
      end

      it "updates the assignment's points possible" do
        expect(@assignment.points_possible).to eq 12
        expect(@json["points_possible"]).to eq @assignment.points_possible
      end

      it "updates the assignment's grading_type" do
        expect(@assignment.grading_type).to eq "letter_grade"
        expect(@json["grading_type"]).to eq @assignment.grading_type
      end

      it "updates the assignments grading_type when outcome not provided" do
        @json = api_update_assignment_call(@course, @assignment, {
                                             "grading_type" => "points"
                                           })
        @assignment.reload
        expect(@assignment.grading_type).to eq "points"
        expect(@json["grading_type"]).to eq @assignment.grading_type
      end

      it "updates the assignments grading_type when type is empty" do
        @json = api_update_assignment_call(@course, @assignment, { grading_type: "" })
        @assignment.reload
        expect(@assignment.grading_type).to eq "points"
        expect(@json["grading_type"]).to eq @assignment.grading_type
      end

      it "returns, but does not change, the needs_grading_count" do
        expect(@assignment.needs_grading_count).to eq 0
        expect(@json["needs_grading_count"]).to eq 0
      end

      it "updates the assignment's due_at" do
        # fancy midnight
        expect(@json["due_at"]).to eq "2011-01-01T23:59:59Z"
      end

      it "updates the assignment's submission types" do
        expect(@assignment.submission_types).to eq "none"
        expect(@json["submission_types"]).to eq ["none"]
      end

      it "updates the group_category_id" do
        expect(@json["group_category_id"]).to be_nil
      end

      it "returns the html_url, which is a URL to the assignment" do
        expect(@json["html_url"]).to eq course_assignment_url(@course, @assignment)
      end

      it "updates the peer reviews info" do
        expect(@assignment.peer_reviews).to be false
        expect(@json).not_to have_key("peer_review_count")
        expect(@json).not_to have_key("peer_reviews_assign_at")
      end

      it "updates the grading standard" do
        expect(@assignment.grading_standard_id).to eq @new_grading_standard.id
        expect(@json["grading_standard_id"]).to eq @new_grading_standard.id
      end

      it "updates the allowed_attempts" do
        expect(@json["allowed_attempts"]).to eq 10
      end
    end

    it "is not able to update position to nil" do
      @assignment = @course.assignments.create!
      json = api_update_assignment_call(@course, @assignment, { "position" => "" })
      @assignment.reload
      expect(json["position"]).to eq 1
      expect(@assignment.position).to eq 1
    end

    it "processes html content in description on update" do
      @assignment = @course.assignments.create!

      should_process_incoming_user_content(@course) do |content|
        api_update_assignment_call(@course, @assignment, {
                                     "description" => content
                                   })

        @assignment.reload
        @assignment.description
      end
    end

    context "with assignment overrides on the assignment" do
      describe "updating assignment overrides" do
        before :once do
          student_in_course(course: @course, active_enrollment: true)
          @assignment = @course.assignments.create!
          @group_category = @assignment.context.group_categories.create!(name: "foo")
          @assignment.group_category = @group_category
          @assignment.save!
          @group = group_model(context: @course, group_category: @assignment.group_category)
          @adhoc_due_at = 5.days.from_now
          @section_due_at = 7.days.from_now
          @group_due_at = 3.days.from_now
          @user = @teacher
        end

        let(:update_assignment) do
          api_update_assignment_call(@course, @assignment, {
                                       "name" => "Assignment With Overrides",
                                       "assignment_overrides" => {
                                         "0" => {
                                           "student_ids" => [@student.id],
                                           "title" => "adhoc override",
                                           "due_at" => @adhoc_due_at.iso8601
                                         },
                                         "1" => {
                                           "course_section_id" => @course.default_section.id,
                                           "due_at" => @section_due_at.iso8601
                                         },
                                         "2" => {
                                           "title" => "Group override",
                                           "set_id" => @group_category.id,
                                           "group_id" => @group.id,
                                           "due_at" => @group_due_at.iso8601
                                         },
                                         "3" => {
                                           "title" => "Helpful Tag",
                                           "noop_id" => 999
                                         }
                                       }
                                     })
          @assignment.reload
        end

        let(:update_assignment_only) do
          api_update_assignment_call(@course, @assignment, {
                                       "name" => "Assignment With Overrides",
                                       "due_at" => 1.week.from_now.iso8601,
                                       "assignment_overrides" => {
                                         "0" => {
                                           "student_ids" => [@student.id],
                                           "title" => "adhoc override",
                                           "due_at" => @adhoc_due_at.iso8601
                                         },
                                         "1" => {
                                           "course_section_id" => @course.default_section.id,
                                           "due_at" => @section_due_at.iso8601
                                         },
                                         "2" => {
                                           "title" => "Group override",
                                           "set_id" => @group_category.id,
                                           "group_id" => @group.id,
                                           "due_at" => @group_due_at.iso8601
                                         },
                                         "3" => {
                                           "title" => "Helpful Tag",
                                           "noop_id" => 999
                                         }
                                       }
                                     })
          @assignment.reload
        end

        describe "SubmissionLifecycleManager" do
          it "is called only once when there are changes to overrides" do
            submission_lifecycle_manager = instance_double(SubmissionLifecycleManager)
            allow(SubmissionLifecycleManager).to receive(:new).and_return(submission_lifecycle_manager)

            expect(submission_lifecycle_manager).to receive(:recompute).once

            update_assignment
          end

          it "is not called when there are no changes to overrides or assignment" do
            update_assignment

            submission_lifecycle_manager = instance_double(SubmissionLifecycleManager)
            allow(SubmissionLifecycleManager).to receive(:new).and_return(submission_lifecycle_manager)

            expect(submission_lifecycle_manager).not_to receive(:recompute)

            update_assignment
          end

          it "is called only once when there are changes to the assignment but not to the overrides" do
            update_assignment

            submission_lifecycle_manager = instance_double(SubmissionLifecycleManager)
            allow(SubmissionLifecycleManager).to receive(:new).and_return(submission_lifecycle_manager)

            expect(submission_lifecycle_manager).to receive(:recompute).once

            update_assignment_only
          end
        end

        it "updates any ADHOC overrides" do
          update_assignment
          expect(@assignment.assignment_overrides.count).to eq 4
          @adhoc_override = @assignment.assignment_overrides.where(set_type: "ADHOC").first
          expect(@adhoc_override).not_to be_nil
          expect(@adhoc_override.set).to eq [@student]
          expect(@adhoc_override.due_at_overridden).to be_truthy
          expect(@adhoc_override.due_at.to_i).to eq @adhoc_due_at.to_i
        end

        it "updates any CourseSection overrides" do
          update_assignment
          @section_override = @assignment.assignment_overrides.where(set_type: "CourseSection").first
          expect(@section_override).not_to be_nil
          expect(@section_override.set).to eq @course.default_section
          expect(@section_override.due_at_overridden).to be_truthy
          expect(@section_override.due_at.to_i).to eq @section_due_at.to_i
        end

        it "updates any Group overrides" do
          update_assignment
          @group_override = @assignment.assignment_overrides.where(set_type: "Group").first
          expect(@group_override).not_to be_nil
          expect(@group_override.set).to eq @group
          expect(@group_override.due_at_overridden).to be_truthy
          expect(@group_override.due_at.to_i).to eq @group_due_at.to_i
        end

        it "updates any Noop overrides" do
          update_assignment
          @noop_override = @assignment.assignment_overrides.where(set_type: "Noop").first
          expect(@noop_override).not_to be_nil
          expect(@noop_override.set).to be_nil
          expect(@noop_override.set_type).to eq "Noop"
          expect(@noop_override.set_id).to eq 999
          expect(@noop_override.title).to eq "Helpful Tag"
          expect(@noop_override.due_at_overridden).to be_falsey
        end

        it "overrides the assignment for the user" do
          @assignment.update!(due_at: 1.day.from_now)
          response = api_update_assignment_call(@course,
                                                @assignment,
                                                assignment_overrides: {
                                                  0 => {
                                                    course_section_id: @course.default_section.id,
                                                    due_at: @section_due_at.iso8601
                                                  }
                                                })
          expect(response["due_at"]).to eq(@section_due_at.iso8601)
        end

        it "updates overrides for inactive students" do
          @enrollment.deactivate
          update_assignment
          expect(@assignment.assignment_overrides.count).to eq 4
          @adhoc_override = @assignment.assignment_overrides.where(set_type: "ADHOC").first
          expect(@adhoc_override).not_to be_nil
          expect(@adhoc_override.set).to eq [@student]
          expect(@adhoc_override.due_at_overridden).to be_truthy
          expect(@adhoc_override.due_at.to_i).to eq @adhoc_due_at.to_i
        end

        it "updates overrides for concluded students" do
          @enrollment.conclude
          update_assignment
          expect(@assignment.assignment_overrides.count).to eq 4
          @adhoc_override = @assignment.assignment_overrides.where(set_type: "ADHOC").first
          expect(@adhoc_override).not_to be_nil
          expect(@adhoc_override.set).to eq [@student]
          expect(@adhoc_override.due_at_overridden).to be_truthy
          expect(@adhoc_override.due_at.to_i).to eq @adhoc_due_at.to_i
        end

        it "does not create overrides when student_ids is invalid" do
          api_update_assignment_call(@course, @assignment, {
                                       "name" => "Assignment With Overrides",
                                       "assignment_overrides" => {
                                         "0" => {
                                           "student_ids" => "bad parameter",
                                           "title" => "adhoc override",
                                           "due_at" => @adhoc_due_at.iso8601
                                         }
                                       }
                                     })
          expect(@assignment.assignment_overrides.count).to eq 0
        end

        it "does not override the assignment for the user if passed false for override_dates" do
          @assignment.update!(due_at: 1.day.from_now)
          response = api_update_assignment_call(@course,
                                                @assignment,
                                                override_dates: false,
                                                assignment_overrides: {
                                                  0 => {
                                                    course_section_id: @course.default_section.id,
                                                    due_at: @section_due_at.iso8601
                                                  }
                                                })
          expect(response["due_at"]).to eq(@assignment.due_at.iso8601)
        end

        it "does not override the assignment if restricted by master course" do
          other_course = Account.default.courses.create!
          template = MasterCourses::MasterTemplate.set_as_master_course(other_course)
          original_assmt = other_course.assignments.create!(title: "blah", description: "bloo")
          tag = template.create_content_tag_for!(original_assmt, restrictions: { content: true, due_dates: true })

          @assignment.update_attribute(:migration_id, tag.migration_id)

          api_call(:put,
                   "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}.json",
                   {
                     controller: "assignments_api",
                     action: "update",
                     format: "json",
                     course_id: @course.id.to_s,
                     id: @assignment.id.to_s
                   },
                   { assignment: { assignment_overrides: { 0 => { course_section_id: @course.default_section.id, due_at: @section_due_at.iso8601 } } } },
                   {},
                   { expected_status: 403 })
          expect(@assignment.assignment_overrides).to_not be_exists

          tag.update_attribute(:restrictions, { content: true }) # unrestrict due_dates

          api_update_assignment_call(@course,
                                     @assignment,
                                     assignment_overrides: { 0 => { course_section_id: @course.default_section.id, due_at: @section_due_at.iso8601 } })
          expect(@assignment.assignment_overrides).to be_exists
        end
      end

      describe "deleting all CourseSection overrides from assignment" do
        it "works when :assignment_overrides key is nil" do
          student_in_course(course: @course, active_all: true)
          @assignment = @course.assignments.create!
          Assignment.where(id: @assignment).update_all(created_at: 1.day.ago)
          @section_due_at = 7.days.from_now
          @params = {
            "name" => "Assignment With Overrides",
            "assignment_overrides" => {}
          }
          @user = @teacher

          expect(@params).to have_key("assignment_overrides")

          api_update_assignment_call(@course, @assignment, @params)
          expect(@assignment.assignment_overrides.active.count).to eq 0
        end
      end

      describe "for a group assignment with group overrides" do
        let(:old_group_category) do
          category = @course.group_categories.create!(name: "old")
          category.create_groups(1)
          category
        end
        let(:old_group) { old_group_category.groups.first }

        let(:new_group_category) do
          category = @course.group_categories.create!(name: "new")
          category.create_groups(1)
          category
        end
        let(:new_group) { new_group_category.groups.first }

        it "removes overrides for groups in the old group category when changing the group" do
          assignment = @course.assignments.create!(group_category_id: old_group_category.id)
          assignment.assignment_overrides.create(set: old_group)

          params = {
            assignment_overrides: [
              {
                due_at: nil,
                group_id: new_group.id,
                title: "group override"
              }
            ],
            group_category_id: new_group_category.id,
          }

          api_update_assignment_call(@course, assignment, params)
          assignment.reload

          expect(assignment.active_assignment_overrides.pluck(:set_type, :set_id)).to eq [
            ["Group", new_group.id]
          ]
        end

        it "removes overrides for groups in the old group category when removing the group" do
          assignment = @course.assignments.create!(group_category_id: old_group_category.id)
          assignment.assignment_overrides.create(set: old_group)

          params = {
            assignment_overrides: [
              {
                course_section_id: @course.course_sections.first.id,
                due_at: nil,
                title: "section override instead"
              }
            ],
            group_category_id: nil,
          }

          api_update_assignment_call(@course, assignment, params)
          assignment.reload

          expect(assignment.active_assignment_overrides.pluck(:set_type, :set_id)).to eq [
            ["CourseSection", @course.course_sections.first.id]
          ]
        end
      end
    end

    context "broadcasting while updating overrides" do
      before :once do
        @notification = Notification.create!(name: "Assignment Changed", category: "TestImmediately")
        student_in_course(course: @course, active_all: true)
        @student.communication_channels.create(path: "student@instructure.com").confirm!

        @assignment = @course.assignments.create!
        @assignment.unmute!
        Assignment.where(id: @assignment).update_all(created_at: 1.day.ago)
        @adhoc_due_at = 5.days.from_now
        @section_due_at = 7.days.from_now
        @params = {
          "name" => "Assignment With Overrides",
          "assignment_overrides" => {
            "0" => {
              "student_ids" => [@student.id],
              "title" => "adhoc override",
              "due_at" => @adhoc_due_at.iso8601
            },
            "1" => {
              "course_section_id" => @course.default_section.id,
              "due_at" => @section_due_at.iso8601
            }
          }
        }
      end

      it "does not send assignment_changed if notify_of_update is not set" do
        @user = @teacher
        api_update_assignment_call(@course, @assignment, @params)
        expect(@student.messages.detect { |m| m.notification_id == @notification.id }).to be_nil
      end

      it "sends assignment_changed if notify_of_update is set" do
        @user = @teacher
        api_update_assignment_call(@course, @assignment, @params.merge({ notify_of_update: true }))
        expect(@student.messages.detect { |m| m.notification_id == @notification.id }).to be_present
      end
    end

    context "when turnitin is enabled on the context" do
      before :once do
        plugin = Canvas::Plugin.find(:vericite)
        plugin_setting = PluginSetting.find_by(name: plugin.id) || PluginSetting.new(name: plugin.id, settings: plugin.default_settings)
        plugin_setting.posted_settings = { comments: "vericite comments" }
        plugin_setting.save!
        @assignment = @course.assignments.create!
        acct = @course.account
        acct.turnitin_account_id = 0
        acct.turnitin_shared_secret = "blah"
        acct.settings[:enable_turnitin] = true
        acct.settings[:enable_vericite] = true
        acct.save!
        @student = User.create!
        @course.enroll_user(@student, "StudentEnrollment", section: @section, enrollment_state: :active)
      end

      it "allows setting turnitin_enabled" do
        expect(@assignment).not_to be_turnitin_enabled
        api_update_assignment_call(@course, @assignment, {
                                     "turnitin_enabled" => "1",
                                   })
        expect(@assignment.reload).to be_turnitin_enabled
        api_update_assignment_call(@course, @assignment, {
                                     "turnitin_enabled" => "0",
                                   })
        expect(@assignment.reload).not_to be_turnitin_enabled
      end

      it "does not allow changing turnitin setting after submissions have been made" do
        expect do
          api_update_assignment_call(@course, @assignment, {
                                       "turnitin_enabled" => "1",
                                     })
        end.to change {
          @assignment.reload.turnitin_enabled
        }

        @assignment.submit_homework(@student, submission_type: "online_text_entry")

        expect do
          json = api_update_assignment_call(@course, @assignment, {
                                              "turnitin_enabled" => "0",
                                            })
          expect(json["errors"]["turnitin_enabled"][0]["message"]).to eq("The plagiarism platform settings can't be changed because students have already submitted on this assignment")
        end.not_to change {
          @assignment.reload.turnitin_enabled
        }
      end

      it "does not allow changing vericite setting after submissions have been made" do
        expect do
          api_update_assignment_call(@course, @assignment, {
                                       "vericite_enabled" => "1",
                                     })
        end.to change {
          @assignment.reload.vericite_enabled
        }

        @assignment.submit_homework(@student, submission_type: "online_text_entry")

        expect do
          json = api_update_assignment_call(@course, @assignment, {
                                              "vericite_enabled" => "0",
                                            })
          expect(json["errors"]["vericite_enabled"][0]["message"]).to eq("The plagiarism platform settings can't be changed because students have already submitted on this assignment")
        end.not_to change {
          @assignment.reload.vericite_enabled
        }
      end

      it "allows setting valid turnitin_settings" do
        update_settings = {
          originality_report_visibility: "after_grading",
          s_paper_check: "0",
          internet_check: false,
          journal_check: "1",
          exclude_biblio: true,
          exclude_quoted: "0",
          submit_papers_to: "1",
          exclude_small_matches_type: "percent",
          exclude_small_matches_value: 50
        }

        json = api_update_assignment_call(@course, @assignment, {
                                            turnitin_settings: update_settings
                                          })
        expect(json["turnitin_settings"]).to eq({
                                                  "originality_report_visibility" => "after_grading",
                                                  "s_paper_check" => false,
                                                  "internet_check" => false,
                                                  "journal_check" => true,
                                                  "exclude_biblio" => true,
                                                  "exclude_quoted" => false,
                                                  "submit_papers_to" => true,
                                                  "exclude_small_matches_type" => "percent",
                                                  "exclude_small_matches_value" => 50
                                                })

        expect(@assignment.reload.turnitin_settings).to eq({
                                                             "originality_report_visibility" => "after_grading",
                                                             "s_paper_check" => "0",
                                                             "internet_check" => "0",
                                                             "journal_check" => "1",
                                                             "exclude_biblio" => "1",
                                                             "exclude_quoted" => "0",
                                                             "submit_papers_to" => "1",
                                                             "exclude_type" => "2",
                                                             "exclude_value" => "50",
                                                             "s_view_report" => "1"
                                                           })
      end

      it "does not allow setting invalid turnitin_settings" do
        update_settings = {
          blah: "1"
        }.with_indifferent_access

        api_update_assignment_call(@course, @assignment, {
                                     turnitin_settings: update_settings
                                   })
        expect(@assignment.reload.turnitin_settings["blah"]).to be_nil
      end
    end

    context "when a non-admin tries to update a frozen assignment" do
      before :once do
        @assignment = create_frozen_assignment_in_course(@course)
      end

      before do
        allow(PluginSetting).to receive(:settings_for_plugin).and_return({ "title" => "yes" }).at_least(:once)
      end

      it "doesn't allow the non-admin to update a frozen attribute" do
        title_before_update = @assignment.title
        raw_api_update_assignment(@course, @assignment, {
                                    name: "should not change!"
                                  })
        expect(response).to have_http_status :bad_request
        expect(@assignment.reload.title).to eq title_before_update
      end

      it "does allow editing a non-frozen attribute" do
        raw_api_update_assignment(@course, @assignment, {
                                    points_possible: 15
                                  })
        assert_status(200)
        expect(@assignment.reload.points_possible).to eq 15
      end
    end

    context "when an admin tries to update a completely frozen assignment" do
      it "allows the admin to update the frozen assignment" do
        @user = account_admin_user
        course_with_teacher(active_all: true, user: @user)
        expect(PluginSetting).to receive(:settings_for_plugin)
          .and_return(fully_frozen_settings).at_least(:once)
        @assignment = create_frozen_assignment_in_course(@course)
        raw_api_update_assignment(@course, @assignment, {
                                    "name" => "This changes!"
                                  })
        expect(@assignment.title).to eq "This changes!"
        assert_status(200)
      end
    end

    context "differentiated assignments" do
      before :once do
        @assignment = @course.assignments.create(name: "test", only_visible_to_overrides: false)
        @flag_before = @assignment.only_visible_to_overrides
      end

      it "updates the only_visible_to_overrides flag if differentiated assignments is on" do
        raw_api_update_assignment(@course, @assignment, {
                                    only_visible_to_overrides: !@flag_before
                                  })
        expect(@assignment.reload.only_visible_to_overrides).to eq !@flag_before
      end
    end

    context "when an admin tried to update a grading_standard" do
      before(:once) do
        account_admin_user(user: @user)
        @assignment = @course.assignments.create({ name: "some assignment" })
        @assignment.save!
        @account_standard = @course.account.grading_standards.create!(title: "account standard", standard_data: { a: { name: "A", value: "95" }, b: { name: "B", value: "80" }, f: { name: "F", value: "" } })
        @course_standard = @course.grading_standards.create!(title: "course standard", standard_data: { a: { name: "A", value: "95" }, b: { name: "B", value: "80" }, f: { name: "F", value: "" } })
      end

      it "allows setting an account grading standard" do
        raw_api_call(
          :put,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}.json",
          {
            controller: "assignments_api",
            action: "update",
            format: "json",
            course_id: @course.id.to_s,
            id: @assignment.id.to_s
          },
          { assignment: { grading_standard_id: @account_standard.id } }
        )
        @assignment.reload
        expect(@assignment.grading_standard).to eq @account_standard
      end

      it "allows setting a course level grading standard" do
        raw_api_call(
          :put,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}.json",
          {
            controller: "assignments_api",
            action: "update",
            format: "json",
            course_id: @course.id.to_s,
            id: @assignment.id.to_s
          },
          { assignment: { grading_standard_id: @course_standard.id } }
        )
        @assignment.reload
        expect(@assignment.grading_standard).to eq @course_standard
      end

      it "updates a sub account level grading standard" do
        sub_account = @course.account.sub_accounts.create!
        c2 = sub_account.courses.create!
        assignment2 = c2.assignments.create({ name: "some assignment" })
        assignment2.save!
        sub_account_standard = sub_account.grading_standards.create!(title: "sub account standard", standard_data: { a: { name: "A", value: "95" }, b: { name: "B", value: "80" }, f: { name: "F", value: "" } })
        raw_api_call(
          :put,
          "/api/v1/courses/#{c2.id}/assignments/#{assignment2.id}.json",
          {
            controller: "assignments_api",
            action: "update",
            format: "json",
            course_id: c2.id.to_s,
            id: assignment2.id.to_s
          },
          { assignment: { grading_standard_id: sub_account_standard.id } }
        )
        assignment2.reload
        expect(assignment2.grading_standard).to eq sub_account_standard
      end

      it "does not update grading standard from sub account not on account chain" do
        sub_account = @course.account.sub_accounts.create!
        sub_account2 = @course.account.sub_accounts.create!
        c2 = sub_account.courses.create!
        assignment2 = c2.assignments.create({ name: "some assignment" })
        assignment2.save!
        sub_account_standard = sub_account2.grading_standards.create!(title: "sub account standard", standard_data: { a: { name: "A", value: "95" }, b: { name: "B", value: "80" }, f: { name: "F", value: "" } })
        raw_api_call(
          :put,
          "/api/v1/courses/#{c2.id}/assignments/#{assignment2.id}.json",
          {
            controller: "assignments_api",
            action: "update",
            format: "json",
            course_id: c2.id.to_s,
            id: assignment2.id.to_s
          },
          { assignment: { grading_standard_id: sub_account_standard.id } }
        )
        assignment2.reload
        expect(assignment2.grading_standard).to be_nil
      end

      it "does not delete grading standard if invalid standard provided" do
        @assignment.grading_standard = @account_standard
        @assignment.save!
        sub_account = @course.account.sub_accounts.create!
        sub_account_standard = sub_account.grading_standards.create!(title: "sub account standard", standard_data: { a: { name: "A", value: "95" }, b: { name: "B", value: "80" }, f: { name: "F", value: "" } })
        raw_api_call(
          :put,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}.json",
          {
            controller: "assignments_api",
            action: "update",
            format: "json",
            course_id: @course.id.to_s,
            id: @assignment.id.to_s
          },
          { assignment: { grading_standard_id: sub_account_standard.id } }
        )
        @assignment.reload
        expect(@assignment.grading_standard).to eq @account_standard
      end

      it "removes a standard if empty value passed" do
        @assignment.grading_standard = @account_standard
        @assignment.save!
        sub_account = @course.account.sub_accounts.create!
        sub_account.grading_standards.create!(title: "sub account standard", standard_data: { a: { name: "A", value: "95" }, b: { name: "B", value: "80" }, f: { name: "F", value: "" } })
        raw_api_call(
          :put,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}.json",
          {
            controller: "assignments_api",
            action: "update",
            format: "json",
            course_id: @course.id.to_s,
            id: @assignment.id.to_s
          },
          { assignment: { grading_standard_id: nil } }
        )
        @assignment.reload
        expect(@assignment.grading_standard).to be_nil
      end
    end

    context "discussion topic assignments" do
      it "prevents setting group category ID on assignments with discussions" do
        course_with_teacher(active_all: true)
        group_category = @course.group_categories.create!(name: "foo")
        @assignment = @course.assignments.create!(title: "assignment1")
        @topic = @course.discussion_topics.build(assignment: @assignment, title: "asdf")
        @topic.save
        raw_api_update_assignment(@course, @assignment, {
                                    group_category_id: group_category.id
                                  })
        @assignment.reload
        expect(@assignment.group_category).to be_nil
        expect(response).to have_http_status :bad_request
      end
    end

    context "with grading periods" do
      def create_assignment(attr)
        @course.assignments.create!({ name: "Example Assignment", submission_types: "points" }.merge(attr))
      end

      def override_for_date(date)
        override = @assignment.assignment_overrides.build
        override.set_type = "CourseSection"
        override.due_at = date
        override.due_at_overridden = true
        override.set_id = @course.course_sections.first
        override.save!
        override
      end

      def call_update(params, expected_status)
        api_call_as_user(
          @current_user,
          :put,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}",
          {
            controller: "assignments_api",
            action: "update",
            format: "json",
            course_id: @course.id.to_s,
            id: @assignment.to_param
          },
          { assignment: params },
          {},
          { expected_status: }
        )
      end

      before :once do
        grading_period_group = Factories::GradingPeriodGroupHelper.new.create_for_account(@course.root_account)
        term = @course.enrollment_term
        term.grading_period_group = grading_period_group
        term.save!
        Factories::GradingPeriodHelper.new.create_for_group(grading_period_group, {
                                                              start_date: 2.weeks.ago, end_date: 2.days.ago, close_date: 1.day.ago
                                                            })
        course_with_student(course: @course)
        account_admin_user(account: @course.root_account)
      end

      context "when the user is a teacher" do
        before do
          @current_user = @teacher
        end

        it "allows changing the due date to another date in an open grading period" do
          due_date = 7.days.from_now.iso8601
          @assignment = create_assignment(due_at: 3.days.from_now)
          call_update({ due_at: due_date }, 200)
          expect(@assignment.reload.due_at).to eq due_date
        end

        it "allows changing the due date when the assignment is only visible to overrides" do
          due_date = 3.days.from_now.iso8601
          @assignment = create_assignment(due_at: 3.days.ago, only_visible_to_overrides: true)
          call_update({ due_at: due_date }, 200)
          expect(@assignment.reload.due_at).to eq due_date
        end

        it "allows disabling only_visible_to_overrides when due in an open grading period" do
          @assignment = create_assignment(due_at: 3.days.from_now, only_visible_to_overrides: true)
          call_update({ only_visible_to_overrides: false }, 200)
          expect(@assignment.reload.only_visible_to_overrides).to be false
        end

        it "allows enabling only_visible_to_overrides when due in an open grading period" do
          @assignment = create_assignment(due_at: 3.days.from_now, only_visible_to_overrides: false)
          call_update({ only_visible_to_overrides: true }, 200)
          expect(@assignment.reload.only_visible_to_overrides).to be true
        end

        it "allows disabling post_to_sis when due in a closed grading period" do
          @assignment = create_assignment(due_at: 3.days.ago, post_to_sis: true)
          call_update({ post_to_sis: false }, 200)
          expect(@assignment.reload.post_to_sis).to be(false)
        end

        it "allows enabling post_to_sis when due in a closed grading period" do
          @assignment = create_assignment(due_at: 3.days.ago, post_to_sis: false)
          call_update({ post_to_sis: true }, 200)
          expect(@assignment.reload.post_to_sis).to be(true)
        end

        it "does not allow disabling only_visible_to_overrides when due in a closed grading period" do
          @assignment = create_assignment(due_at: 3.days.ago, only_visible_to_overrides: true)
          call_update({ only_visible_to_overrides: false }, 403)
          expect(@assignment.reload.only_visible_to_overrides).to be true
          json = JSON.parse response.body
          expect(json["errors"].keys).to include "due_at"
        end

        it "does not allow enabling only_visible_to_overrides when due in a closed grading period" do
          @assignment = create_assignment(due_at: 3.days.ago, only_visible_to_overrides: false)
          call_update({ only_visible_to_overrides: true }, 403)
          expect(@assignment.reload.only_visible_to_overrides).to be false
          json = JSON.parse response.body
          expect(json["errors"].keys).to include "only_visible_to_overrides"
        end

        it "allows disabling only_visible_to_overrides when changing due date to an open grading period" do
          due_date = 3.days.from_now.iso8601
          @assignment = create_assignment(due_at: 3.days.ago, only_visible_to_overrides: true)
          call_update({ due_at: due_date, only_visible_to_overrides: false }, 200)
          expect(@assignment.reload.only_visible_to_overrides).to be false
          expect(@assignment.due_at).to eq due_date
        end

        it "does not allow changing the due date on an assignment due in a closed grading period" do
          due_date = 3.days.ago
          @assignment = create_assignment(due_at: due_date)
          call_update({ due_at: 3.days.from_now.iso8601 }, 403)
          expect(@assignment.reload.due_at).to eq due_date
          json = JSON.parse response.body
          expect(json["errors"].keys).to include "due_at"
        end

        it "does not allow changing the due date to a date within a closed grading period" do
          due_date = 3.days.from_now
          @assignment = create_assignment(due_at: due_date)
          call_update({ due_at: 3.days.ago.iso8601 }, 403)
          expect(@assignment.reload.due_at).to eq due_date
          json = JSON.parse response.body
          expect(json["errors"].keys).to include "due_at"
        end

        it "does not allow unsetting the due date when the last grading period is closed" do
          due_date = 3.days.from_now
          @assignment = create_assignment(due_at: due_date)
          call_update({ due_at: nil }, 403)
          expect(@assignment.reload.due_at).to eq due_date
          json = JSON.parse response.body
          expect(json["errors"].keys).to include "due_at"
        end

        it "succeeds when the assignment due date is set to the same value" do
          due_date = 3.days.ago
          @assignment = create_assignment(due_at: due_date.iso8601, time_zone_edited: due_date.zone)
          call_update({ due_at: due_date.iso8601 }, 200)
          expect(@assignment.reload.due_at).to eq due_date.iso8601
        end

        it "succeeds when the assignment due date is not changed" do
          due_date = 3.days.ago.iso8601
          @assignment = create_assignment(due_at: due_date)
          call_update({ description: "Updated Description" }, 200)
          expect(@assignment.reload.due_at).to eq due_date
        end

        it "allows changing the due date when the assignment is not graded" do
          due_date = 3.days.ago.iso8601
          @assignment = create_assignment(due_at: 7.days.from_now, submission_types: "not_graded")
          call_update({ due_at: due_date }, 200)
          expect(@assignment.reload.due_at).to eq due_date
        end

        it "allows unsetting the due date when not graded and the last grading period is closed" do
          @assignment = create_assignment(due_at: 7.days.from_now, submission_types: "not_graded")
          call_update({ due_at: nil }, 200)
          expect(@assignment.reload.due_at).to be_nil
        end

        it "allows changing the due date on an assignment with an override due in a closed grading period" do
          due_date = 7.days.from_now
          @assignment = create_assignment(due_at: 3.days.from_now.iso8601, time_zone_edited: due_date.zone)
          override_for_date(3.days.ago)
          call_update({ due_at: due_date.iso8601 }, 200)
          expect(@assignment.reload.due_at).to eq due_date.iso8601
        end

        it "allows adding an override with a due date in an open grading period" do
          # Known Issue: This should not be permitted when creating an override
          # would cause a student to assume a due date in an open grading period
          # when previous in a closed grading period.
          override_due_date = 3.days.from_now.iso8601
          @assignment = create_assignment(due_at: 7.days.from_now, only_visible_to_overrides: true)
          override_params = [{ student_ids: [@student.id], due_at: override_due_date }]
          call_update({ assignment_overrides: override_params }, 200)
          overrides = @assignment.reload.assignment_overrides
          expect(overrides.count).to eq 1
          expect(overrides.first.due_at).to eq override_due_date
        end

        it "does not allow adding an override with a due date in a closed grading period" do
          @assignment = create_assignment(due_at: 7.days.from_now)
          override_params = [{ student_ids: [@student.id], due_at: 3.days.ago.iso8601 }]
          call_update({ assignment_overrides: override_params }, 403)
          json = JSON.parse response.body
          expect(json["errors"].keys).to include "due_at"
        end

        it "does not allow changing the due date of an override due in a closed grading period" do
          override_due_date = 3.days.ago
          @assignment = create_assignment(due_at: 7.days.from_now)
          override = override_for_date(override_due_date)
          override_params = [{ id: override.id, due_at: 3.days.from_now.iso8601 }]
          call_update({ assignment_overrides: override_params }, 403)
          expect(override.reload.due_at).to eq override_due_date
          json = JSON.parse response.body
          expect(json["errors"].keys).to include "due_at"
        end

        it "succeeds when the override due date is set to the same value" do
          override_due_date = 3.days.ago
          @assignment = create_assignment(due_at: 7.days.from_now)
          override = override_for_date(override_due_date)
          override_params = [{ id: override.id, due_at: override_due_date.iso8601 }]
          call_update({ assignment_overrides: override_params }, 200)
          expect(override.reload.due_at).to eq override_due_date.iso8601
        end

        it "does not allow changing the due date of an override to a date within a closed grading period" do
          override_due_date = 3.days.from_now
          @assignment = create_assignment(due_at: 7.days.from_now)
          override = override_for_date(override_due_date)
          override_params = [{ id: override.id, due_at: 3.days.ago.iso8601 }]
          call_update({ assignment_overrides: override_params }, 403)
          expect(override.reload.due_at).to eq override_due_date
          json = JSON.parse response.body
          expect(json["errors"].keys).to include "due_at"
        end

        it "does not allow unsetting the due date of an override when the last grading period is closed" do
          override_due_date = 3.days.from_now
          @assignment = create_assignment(due_at: 7.days.from_now)
          override = override_for_date(override_due_date)
          override_params = [{ id: override.id, due_at: nil }]
          call_update({ assignment_overrides: override_params }, 403)
          expect(override.reload.due_at).to eq override_due_date
          json = JSON.parse response.body
          expect(json["errors"].keys).to include "due_at"
        end

        it "does not allow deleting by omission an override due in a closed grading period" do
          @assignment = create_assignment(due_at: 7.days.from_now)
          override = override_for_date(3.days.ago)
          override_params = [{ student_ids: [@student.id], due_at: 3.days.from_now.iso8601 }]
          call_update({ assignment_overrides: override_params }, 403)
          expect(override.reload).not_to be_deleted
        end
      end

      context "when the user is an admin" do
        before do
          @current_user = @admin
        end

        it "allows disabling only_visible_to_overrides when due in a closed grading period" do
          @assignment = create_assignment(due_at: 3.days.ago, only_visible_to_overrides: true)
          call_update({ only_visible_to_overrides: false }, 200)
          expect(@assignment.reload.only_visible_to_overrides).to be false
        end

        it "allows enabling only_visible_to_overrides when due in a closed grading period" do
          @assignment = create_assignment(due_at: 3.days.ago, only_visible_to_overrides: false)
          call_update({ only_visible_to_overrides: true }, 200)
          expect(@assignment.reload.only_visible_to_overrides).to be true
        end

        it "allows changing the due date on an assignment due in a closed grading period" do
          due_date = 3.days.from_now
          @assignment = create_assignment(due_at: 3.days.ago.iso8601, time_zone_edited: due_date.zone)
          call_update({ due_at: due_date.iso8601 }, 200)
          expect(@assignment.reload.due_at).to eq due_date.iso8601
        end

        it "allows changing the due date to a date within a closed grading period" do
          due_date = 3.days.ago.iso8601
          @assignment = create_assignment(due_at: 3.days.from_now)
          call_update({ due_at: due_date }, 200)
          expect(@assignment.reload.due_at).to eq due_date
        end

        it "allows unsetting the due date when the last grading period is closed" do
          @assignment = create_assignment(due_at: 3.days.from_now)
          call_update({ due_at: nil }, 200)
          expect(@assignment.reload.due_at).to be_nil
        end

        it "allows changing the due date on an assignment with an override due in a closed grading period" do
          due_date = 3.days.from_now
          @assignment = create_assignment(due_at: 7.days.from_now.iso8601, time_zone_edited: due_date.zone)
          override_for_date(3.days.ago)
          call_update({ due_at: due_date.iso8601 }, 200)
          expect(@assignment.reload.due_at).to eq due_date.iso8601
        end

        it "allows adding an override with a due date in a closed grading period" do
          override_due_date = 3.days.ago.iso8601
          @assignment = create_assignment(due_at: 7.days.from_now, only_visible_to_overrides: true)
          override_params = [{ student_ids: [@student.id], due_at: override_due_date }]
          call_update({ assignment_overrides: override_params }, 200)
          overrides = @assignment.reload.assignment_overrides
          expect(overrides.count).to eq 1
          expect(overrides.first.due_at).to eq override_due_date
        end

        it "allows changing the due date of an override due in a closed grading period" do
          override_due_date = 3.days.from_now.iso8601
          @assignment = create_assignment(due_at: 7.days.from_now)
          override = override_for_date(3.days.ago)
          override_params = [{ id: override.id, due_at: override_due_date }]
          call_update({ assignment_overrides: override_params }, 200)
          expect(override.reload.due_at).to eq override_due_date
        end

        it "allows changing the due date of an override to a date within a closed grading period" do
          override_due_date = 3.days.ago.iso8601
          @assignment = create_assignment(due_at: 7.days.from_now)
          override = override_for_date(3.days.from_now)
          override_params = [{ id: override.id, due_at: override_due_date }]
          call_update({ assignment_overrides: override_params }, 200)
          expect(override.reload.due_at).to eq override_due_date
        end

        it "allows unsetting the due date of an override when the last grading period is closed" do
          @assignment = create_assignment(due_at: 7.days.from_now)
          override = override_for_date(3.days.from_now)
          override_params = [{ id: override.id, due_at: nil }]
          call_update({ assignment_overrides: override_params }, 200)
          expect(override.reload.due_at).to be_nil
        end

        it "allows deleting by omission an override due in a closed grading period" do
          @assignment = create_assignment(due_at: 7.days.from_now)
          override = override_for_date(3.days.ago)
          override_params = [{ student_ids: [@student.id], due_at: 3.days.from_now.iso8601 }]
          call_update({ assignment_overrides: override_params }, 200)
          expect(override.reload).to be_deleted
        end
      end
    end

    context "assignment that uses LTI 1.3" do
      let(:course) do
        course = course_factory
        course_with_teacher_logged_in({ user: user_factory, course: })
        course
      end
      let(:assignment) do
        course.assignments.create!(title: "custom",
                                   submission_types: "external_tool",
                                   points_possible: 10,
                                   external_tool_tag: content_tag,
                                   workflow_state: "published")
      end
      let(:tool) do
        course.context_external_tools.create!(
          name: "LTI Test Tool",
          consumer_key: "key",
          shared_secret: "secret",
          use_1_3: true,
          developer_key: DeveloperKey.create!,
          tool_id: "LTI Test Tool",
          url: "http://lti13testtool.docker/launch"
        )
      end
      let(:content_tag) { ContentTag.new(url: tool.url, content: tool) }
      let(:external_tool_tag_attributes) do
        {
          content_id: course.context_external_tools.last.id,
          content_type: "context_external_tool",
          external_data: "",
          new_tab: "0",
          url: "http://lti13testtool.docker/launch"
        }
      end
      let(:assignment_params) do
        {
          submission_types: ["external_tool"],
          external_tool_tag_attributes:
        }
      end

      context "that uses custom parameters" do
        let(:external_tool_tag_attributes) { super().merge({ custom_params: }) }
        let(:custom_params) { { "hello" => "there" } }

        it "saves the new custom params" do
          response = api_call(
            :put,
            "/api/v1/courses/#{course.id}/assignments/#{assignment.id}",
            {
              controller: "assignments_api",
              action: "update",
              format: "json",
              course_id: course.id.to_s,
              id: assignment.to_param
            },
            { assignment: assignment_params },
            {},
            { expected_status: 200 }
          )
          expect(response["external_tool_tag_attributes"]["custom_params"]).to eq custom_params
          expect(assignment.reload.primary_resource_link.custom).to eq custom_params
        end

        context "custom params already exist" do
          let(:assignment) do
            a = super()
            a.update!(lti_resource_link_custom_params: saved_custom_params)
            a
          end
          let(:saved_custom_params) do
            {
              "already" => "saved"
            }
          end

          context "passing no custom params" do
            let(:external_tool_tag_attributes) do
              prev = super()
              prev.delete(:custom_params)
              prev
            end

            it "doesn't delete the existing custom params" do
              response = api_call(
                :put,
                "/api/v1/courses/#{course.id}/assignments/#{assignment.id}",
                {
                  controller: "assignments_api",
                  action: "update",
                  format: "json",
                  course_id: course.id.to_s,
                  id: assignment.to_param
                },
                { assignment: assignment_params },
                {},
                { expected_status: 200 }
              )
              expect(response["external_tool_tag_attributes"]["custom_params"]).to eq saved_custom_params
              expect(assignment.reload.primary_resource_link.custom).to eq saved_custom_params
            end
          end

          context "passing a falsey value for custom params" do
            let(:custom_params) { nil }

            it "deletes the existing custom params" do
              response = api_call(
                :put,
                "/api/v1/courses/#{course.id}/assignments/#{assignment.id}",
                {
                  controller: "assignments_api",
                  action: "update",
                  format: "json",
                  course_id: course.id.to_s,
                  id: assignment.to_param
                },
                { assignment: assignment_params },
                {},
                { expected_status: 200 }
              )

              expect(response["external_tool_tag_attributes"]["custom_params"]).to eq({})
              expect(assignment.reload.primary_resource_link.reload.custom).to eq({})
            end
          end

          context "passing a new value for custom params" do
            let(:custom_params) { { "general" => "kenobi" } }

            it "updates the custom params on the Lti::ResourceLink" do
              response = api_call(
                :put,
                "/api/v1/courses/#{course.id}/assignments/#{assignment.id}",
                {
                  controller: "assignments_api",
                  action: "update",
                  format: "json",
                  course_id: course.id.to_s,
                  id: assignment.to_param
                },
                { assignment: assignment_params },
                {},
                { expected_status: 200 }
              )

              expect(response["external_tool_tag_attributes"]["custom_params"]).to eq custom_params
              expect(assignment.reload.primary_resource_link.reload.custom).to eq custom_params
            end
          end
        end

        context "invalid custom params" do
          shared_examples_for "an invalid custom params request" do
            it "returns a 400 and doesn't save the custom params" do
              response = api_call(
                :put,
                "/api/v1/courses/#{course.id}/assignments/#{assignment.id}",
                {
                  controller: "assignments_api",
                  action: "update",
                  format: "json",
                  course_id: course.id.to_s,
                  id: assignment.to_param
                },
                { assignment: assignment_params },
                {},
                { expected_status: 400 }
              )
              expect(response.include?("external_tool_tag_attributes")).to be_falsey
              expect(response["errors"].length).to be 1
              expect(assignment.reload.primary_resource_link.reload.custom).to be_nil
            end
          end

          context "because it's a nested object" do
            let(:custom_params) do
              {
                "hello" => {
                  "there" => "general kenobi"
                },
                "I'm" => "invalid"
              }
            end

            it_behaves_like "an invalid custom params request"
          end

          context "because it's not an object at all" do
            let(:custom_params) { "Lies, deception!" }

            it_behaves_like "an invalid custom params request"
          end
        end
      end
    end

    describe "skipping downstream changes" do
      it "skips the mark downstream changes callback when the skip_downstream_changes param is passed and true" do
        other_course = Account.default.courses.create!
        template = MasterCourses::MasterTemplate.set_as_master_course(other_course)
        original_assmt = other_course.assignments.create!(title: "blah", description: "bloo")
        tag = template.create_content_tag_for!(original_assmt)

        course_with_teacher(active_all: true)
        subscription = MasterCourses::ChildSubscription.create!(master_template: template, child_course: @course)
        @assignment = @course.assignments.create!(
          name: "something",
          migration_id: tag.migration_id
        )
        child_content_tag = MasterCourses::ChildContentTag.create!(
          child_subscription: subscription,
          content: @assignment
        )

        api_call(:put,
                 "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}.json",
                 {
                   controller: "assignments_api",
                   action: "update",
                   format: "json",
                   course_id: @course.id.to_s,
                   id: @assignment.id.to_s
                 },
                 { assignment: { points_possible: 50 }, skip_downstream_changes: true },
                 {},
                 { expected_status: 200 })

        expect(@assignment.reload.points_possible).to eq 50
        expect(child_content_tag.reload.downstream_changes).to be_empty
      end

      it "marks downstream changes when the skip_downstream_changes is not passed" do
        other_course = Account.default.courses.create!
        template = MasterCourses::MasterTemplate.set_as_master_course(other_course)
        original_assmt = other_course.assignments.create!(title: "blah", description: "bloo")
        tag = template.create_content_tag_for!(original_assmt)

        course_with_teacher(active_all: true)
        subscription = MasterCourses::ChildSubscription.create!(master_template: template, child_course: @course)
        @assignment = @course.assignments.create!(
          name: "something",
          migration_id: tag.migration_id
        )
        child_content_tag = MasterCourses::ChildContentTag.create!(
          child_subscription: subscription,
          content: @assignment
        )

        api_call(:put,
                 "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}.json",
                 {
                   controller: "assignments_api",
                   action: "update",
                   format: "json",
                   course_id: @course.id.to_s,
                   id: @assignment.id.to_s
                 },
                 { assignment: { points_possible: 50 } },
                 {},
                 { expected_status: 200 })

        expect(@assignment.reload.points_possible).to eq 50
        expect(child_content_tag.reload.downstream_changes).not_to be_empty
      end
    end
  end

  describe "DELETE /courses/:course_id/assignments/:id (#delete)" do
    before :once do
      course_with_student(active_all: true)
      @assignment = @course.assignments.create!(
        title: "Test Assignment",
        description: "public stuff"
      )
    end

    context "user does not have the permission to delete the assignment" do
      it "does not delete the assignment" do
        api_call(:delete,
                 "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}",
                 {
                   controller: "assignments",
                   action: "destroy",
                   format: "json",
                   course_id: @course.id.to_s,
                   id: @assignment.to_param
                 },
                 {},
                 {},
                 { expected_status: 403 })
        expect(@assignment.reload).not_to be_deleted
      end
    end

    context "when user requesting the deletion has permission to delete" do
      it "deletes the assignment" do
        teacher_in_course(course: @course, active_all: true)
        api_call(:delete,
                 "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}",
                 {
                   controller: "assignments",
                   action: "destroy",
                   format: "json",
                   course_id: @course.id.to_s,
                   id: @assignment.to_param
                 },
                 {},
                 {},
                 { expected_status: 200 })
        expect(@assignment.reload).to be_deleted
      end

      it "deletes by lti_context_id" do
        teacher_in_course(course: @course, active_all: true)
        api_call(:delete,
                 "/api/v1/courses/#{@course.id}/assignments/lti_context_id:#{@assignment.lti_context_id}",
                 {
                   controller: "assignments",
                   action: "destroy",
                   format: "json",
                   course_id: @course.id.to_s,
                   id: "lti_context_id:#{@assignment.lti_context_id}"
                 },
                 {},
                 {},
                 { expected_status: 200 })
        expect(@assignment.reload).to be_deleted
      end
    end
  end

  describe "GET /courses/:course_id/assignments/:id (#show)" do
    before :once do
      course_with_student(active_all: true)
    end

    describe "checkpoints in-place" do
      before do
        @course.account.enable_feature!(:discussion_checkpoints)

        @assignment = @course.assignments.create!(title: "Assignment 1", has_sub_assignments: true)
        @c1 = @assignment.sub_assignments.create!(context: @assignment.context, sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC, points_possible: 5, due_at: 3.days.from_now)
        @c2 = @assignment.sub_assignments.create!(context: @assignment.context, sub_assignment_tag: CheckpointLabels::REPLY_TO_ENTRY, points_possible: 10, due_at: 5.days.from_now)
      end

      it "returns the assignment with API-formatted Checkpoint data" do
        assignment = api_get_assignment_in_course(@assignment, @course, include: ["checkpoints"])
        checkpoints = assignment["checkpoints"]

        expect(assignment["has_sub_assignments"]).to be_truthy

        expect(checkpoints.length).to eq 2
        expect(checkpoints.pluck("name")).to match_array [@c1.name, @c2.name]
        expect(checkpoints.pluck("tag")).to match_array [@c1.sub_assignment_tag, @c2.sub_assignment_tag]
        expect(checkpoints.pluck("points_possible")).to match_array [@c1.points_possible, @c2.points_possible]
        expect(checkpoints.pluck("due_at")).to match_array [@c1.due_at.iso8601, @c2.due_at.iso8601]
        expect(checkpoints.pluck("only_visible_to_overrides")).to match_array [@c1.only_visible_to_overrides, @c2.only_visible_to_overrides]
      end
    end

    describe "with a normal assignment" do
      before :once do
        @assignment = @course.assignments.create!(
          title: "Locked Assignment",
          description: "secret stuff"
        )
      end

      before do
        allow_any_instantiation_of(@assignment).to receive(:overridden_for)
          .and_return @assignment
        allow_any_instantiation_of(@assignment).to receive(:locked_for?).and_return(
          { asset_string: "", unlock_at: 1.hour.from_now }
        )
      end

      it "looks up an assignment by lti_context_id" do
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/assignments/lti_context_id:#{@assignment.lti_context_id}.json",
                        { controller: "assignments_api",
                          action: "show",
                          format: "json",
                          course_id: @course.id.to_s,
                          id: "lti_context_id:#{@assignment.lti_context_id}" })
        expect(json["id"]).to eq @assignment.id
      end

      it "does not return the assignment's description if locked for user" do
        @json = api_get_assignment_in_course(@assignment, @course)
        expect(@json["description"]).to be_nil
      end

      it "translates assignment descriptions" do
        course_with_teacher(active_all: true)
        should_translate_user_content(@course) do |content|
          assignment = @course.assignments.create!(description: content)
          json = api_get_assignment_in_course(assignment, @course)
          json["description"]
        end
      end

      it "translates assignment descriptions without verifiers" do
        course_with_teacher(active_all: true)
        should_translate_user_content(@course, false) do |content|
          assignment = @course.assignments.create!(description: content)
          json = api_get_assignment_in_course(assignment, @course, no_verifiers: true)
          json["description"]
        end
      end

      it "returns the discussion topic url" do
        @user = @teacher
        @context = @course
        @assignment = @course.assignments.create!(title: "assignment1", submission_types: "discussion_topic")
        @topic = @assignment.discussion_topic
        json = api_get_assignment_in_course(@assignment, @course)
        expect(json["discussion_topic"]).to eq({
                                                 "author" => {},
                                                 "id" => @topic.id,
                                                 "is_section_specific" => @topic.is_section_specific,
                                                 "summary_enabled" => @topic.summary_enabled,
                                                 "title" => "assignment1",
                                                 "message" => nil,
                                                 "posted_at" => @topic.posted_at.as_json,
                                                 "last_reply_at" => @topic.last_reply_at.as_json,
                                                 "require_initial_post" => nil,
                                                 "discussion_subentry_count" => 0,
                                                 "assignment_id" => @assignment.id,
                                                 "delayed_post_at" => nil,
                                                 "lock_at" => nil,
                                                 "created_at" => @topic.created_at.iso8601,
                                                 "user_name" => @topic.user_name,
                                                 "pinned" => !!@topic.pinned,
                                                 "position" => @topic.position,
                                                 "topic_children" => [],
                                                 "group_topic_children" => [],
                                                 "locked" => false,
                                                 "can_lock" => true,
                                                 "comments_disabled" => false,
                                                 "locked_for_user" => false,
                                                 "is_announcement" => false,
                                                 "root_topic_id" => @topic.root_topic_id,
                                                 "podcast_url" => nil,
                                                 "podcast_has_student_posts" => false,
                                                 "read_state" => "unread",
                                                 "unread_count" => 0,
                                                 "user_can_see_posts" => @topic.user_can_see_posts?(@user),
                                                 "subscribed" => @topic.subscribed?(@user),
                                                 "published" => @topic.published?,
                                                 "can_unpublish" => @topic.can_unpublish?,
                                                 "url" =>
            "http://www.example.com/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                                                 "html_url" =>
            "http://www.example.com/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                                                 "attachments" => [],
                                                 "permissions" => { "attach" => true, "update" => true, "reply" => true, "delete" => true, "manage_assign_to" => true },
                                                 "discussion_type" => "not_threaded",
                                                 "group_category_id" => nil,
                                                 "can_group" => true,
                                                 "allow_rating" => false,
                                                 "only_graders_can_rate" => false,
                                                 "sort_by_rating" => false,
                                                 "todo_date" => nil,
                                                 "anonymous_state" => nil
                                               })
      end

      it "fulfills module progression requirements" do
        @assignment = @course.assignments.create!(
          title: "Test Assignment",
          description: "public stuff"
        )
        mod = @course.context_modules.create!(name: "some module")
        tag = mod.add_item(id: @assignment.id, type: "assignment")
        mod.completion_requirements = { tag.id => { type: "must_view" } }
        mod.save!

        # index should not affect anything
        api_call(:get,
                 "/api/v1/courses/#{@course.id}/assignments.json",
                 {
                   controller: "assignments_api",
                   action: "index",
                   format: "json",
                   course_id: @course.id.to_s
                 })
        expect(mod.evaluate_for(@user)).to be_unlocked

        # show should count as a view
        json = api_get_assignment_in_course(@assignment, @course)
        expect(json["description"]).not_to be_nil
        expect(mod.evaluate_for(@user)).to be_completed
      end

      it "returns the dates for assignment as they apply to the user" do
        Score.where(enrollment_id: @student.enrollments).each(&:destroy_permanently!)
        @student.enrollments.each(&:destroy_permanently!)
        @assignment = @course.assignments.create!(
          title: "Test Assignment",
          description: "public stuff"
        )
        @section = @course.course_sections.create! name: "afternoon delight"
        @course.enroll_user(@student,
                            "StudentEnrollment",
                            section: @section,
                            enrollment_state: :active)
        override = create_override_for_assignment
        json = api_get_assignment_in_course(@assignment, @course)
        expect(json["due_at"]).to eq override.due_at.iso8601
        expect(json["unlock_at"]).to eq override.unlock_at.iso8601
        expect(json["lock_at"]).to eq override.lock_at.iso8601
      end

      it "returns original assignment due dates" do
        Score.where(enrollment_id: @student.enrollments).each(&:destroy_permanently!)
        @student.enrollments.each(&:destroy_permanently!)
        @assignment = @course.assignments.create!(
          title: "Test Assignment",
          description: "public stuff",
          due_at: 1.day.from_now,
          unlock_at: Time.zone.now,
          lock_at: 2.days.from_now
        )
        @section = @course.course_sections.create! name: "afternoon delight"
        @course.enroll_user(@student,
                            "StudentEnrollment",
                            section: @section,
                            enrollment_state: :active)
        create_override_for_assignment
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}.json",
                        { controller: "assignments_api",
                          action: "show",
                          format: "json",
                          course_id: @course.id.to_s,
                          id: @assignment.id.to_s },
                        { override_assignment_dates: "false" })
        expect(json["due_at"]).to eq @assignment.due_at.iso8601
        expect(json["unlock_at"]).to eq @assignment.unlock_at.iso8601
        expect(json["lock_at"]).to eq @assignment.lock_at.iso8601
      end

      it "returns has_overrides correctly" do
        @user = @teacher
        @assignment = @course.assignments.create!(title: "Test Assignment", description: "foo")
        json = api_get_assignment_in_course(@assignment, @course)
        expect(json["has_overrides"]).to be false

        @section = @course.course_sections.create! name: "afternoon delight"
        create_override_for_assignment
        json = api_get_assignment_in_course(@assignment, @course)
        expect(json["has_overrides"]).to be true

        @user = @student # don't show has_overrides to students
        json = api_get_assignment_in_course(@assignment, @course)
        expect(json["has_overrides"]).to be_nil
      end

      it "returns all_dates when requested" do
        @assignment = @course.assignments.create!(title: "Test Assignment", description: "foo")
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}.json",
                        { controller: "assignments_api",
                          action: "show",
                          format: "json",
                          course_id: @course.id.to_s,
                          id: @assignment.id.to_s,
                          all_dates: true },
                        { override_assignment_dates: "false" })
        expect(json["all_dates"]).not_to be_nil
      end

      it "does not fulfill requirements when description isn't returned" do
        @assignment = @course.assignments.create!(
          title: "Locked Assignment",
          description: "locked!"
        )
        expect_any_instantiation_of(@assignment).to receive(:overridden_for)
          .and_return @assignment
        expect_any_instantiation_of(@assignment).to receive(:locked_for?).and_return({
                                                                                       asset_string: "",
                                                                                       unlock_at: 1.hour.from_now
                                                                                     }).at_least(1)

        mod = @course.context_modules.create!(name: "some module")
        tag = mod.add_item(id: @assignment.id, type: "assignment")
        mod.completion_requirements = { tag.id => { type: "must_view" } }
        mod.save!
        json = api_get_assignment_in_course(@assignment, @course)
        expect(json["description"]).to be_nil
        expect(mod.evaluate_for(@user)).to be_unlocked
      end

      it "still includes a description when a locked assignment is viewable" do
        @assignment = @course.assignments.create!(
          title: "Locked but Viewable Assignment",
          description: "locked but viewable!"
        )
        expect_any_instantiation_of(@assignment).to receive(:overridden_for)
          .and_return @assignment
        expect_any_instantiation_of(@assignment).to receive(:locked_for?).and_return({
                                                                                       asset_string: "",
                                                                                       unlock_at: 1.hour.ago,
                                                                                       can_view: true
                                                                                     }).at_least(1)

        mod = @course.context_modules.create!(name: "some module")
        tag = mod.add_item(id: @assignment.id, type: "assignment")
        mod.completion_requirements = { tag.id => { type: "must_view" } }
        mod.save!
        json = api_get_assignment_in_course(@assignment, @course)
        expect(json["description"]).not_to be_nil
        expect(mod.evaluate_for(@user)).to be_completed
      end

      it "includes submission info when requested with include flag" do
        assignment, submission = create_submitted_assignment_with_user(@user)
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/assignments/#{assignment.id}.json",
                        { controller: "assignments_api",
                          action: "show",
                          format: "json",
                          course_id: @course.id.to_s,
                          id: assignment.id.to_s },
                        { include: ["submission"] })
        s_json = controller.submission_json(
          submission,
          assignment,
          @user,
          session,
          assignment.context,
          { include: ["submission"] }
        ).to_json
        expect(json["submission"]).to eq(json_parse(s_json))
      end

      context "AssignmentFreezer plugin disabled" do
        before do
          @user = @teacher
          @assignment = create_frozen_assignment_in_course(@course)
          allow(PluginSetting).to receive(:settings_for_plugin).and_return(nil)
          @json = api_get_assignment_in_course(@assignment, @course)
        end

        it "excludes frozen and frozen_attributes fields" do
          expect(@json).not_to have_key("frozen")
          expect(@json).not_to have_key("frozen_attributes")
        end
      end

      context "AssignmentFreezer plugin enabled" do
        context "assignment frozen" do
          before :once do
            @user = @teacher
            @assignment = create_frozen_assignment_in_course(@course)
          end

          before do
            allow(PluginSetting).to receive(:settings_for_plugin).and_return({ "title" => "yes" })
            @json = api_get_assignment_in_course(@assignment, @course)
          end

          it "tells the consumer that the assignment is frozen" do
            expect(@json["frozen"]).to be true
          end

          it "returns an list of frozen attributes" do
            expect(@json["frozen_attributes"]).to eq ["title"]
          end

          it "tells the consumer that the assignment will be frozen when copied" do
            expect(@json["freeze_on_copy"]).to be_truthy
          end

          it "returns an empty list when no frozen attributes" do
            allow(PluginSetting).to receive(:settings_for_plugin).and_return({})
            json = api_get_assignment_in_course(@assignment, @course)
            expect(json["frozen_attributes"]).to eq []
          end
        end

        context "assignment not frozen" do
          before :once do
            @user = @teacher
            @assignment = @course.assignments.create!({
                                                        title: "Frozen",
                                                        description: "frozen!"
                                                      })
          end

          before do
            allow(PluginSetting).to receive(:settings_for_plugin).and_return({ "title" => "yes" }) # enable plugin
            expect_any_instantiation_of(@assignment).to receive(:overridden_for).and_return @assignment
            expect_any_instantiation_of(@assignment).to receive(:frozen?).at_least(:once).and_return false
            @json = api_get_assignment_in_course(@assignment, @course)
          end

          it "tells the consumer that the assignment is not frozen" do
            expect(@json["frozen"]).to be false
          end

          it "gives the consumer an empty list for frozen attributes" do
            expect(@json["frozen_attributes"]).to eq []
          end

          it "tells the consumer that the assignment will not be frozen when copied" do
            expect(@json["freeze_on_copy"]).to be false
          end
        end

        context "assignment with quiz" do
          before do
            @user = @teacher
            @quiz = Quizzes::Quiz.create!(title: "Quiz Name", context: @course)
            @quiz.did_edit!
            @quiz.offer!
            assignment = @quiz.assignment
            @json = api_get_assignment_in_course(assignment, @course)
          end

          it "has quiz information" do
            expect(@json["quiz_id"]).to eq @quiz.id
            expect(@json["anonymous_submissions"]).to be false
            expect(@json["name"]).to eq @quiz.title
            expect(@json["submission_types"]).to include "online_quiz"
          end
        end
      end

      context "external tool assignment" do
        let(:course) { course_model }
        let(:assignment) do
          course.assignments.create!(external_tool_tag: content_tag,
                                     submission_types: "external_tool",
                                     points_possible: 10)
        end
        let(:content_tag) { ContentTag.new(content: tool, url: tool.url, new_tab: false) }
        let(:tool) do
          course.context_external_tools.create!(
            name: "LTI Test Tool",
            consumer_key: "key",
            shared_secret: "secret",
            developer_key: DeveloperKey.create!,
            tool_id: "LTI Test Tool",
            url: "http://lti13testtool.docker/launch"
          )
        end
        let(:json) { api_get_assignment_in_course(assignment, course) }

        it "has the external tool submission type" do
          expect(json["submission_types"]).to eq ["external_tool"]
        end

        it "includes the external tool attributes" do
          expect(json["external_tool_tag_attributes"]).to eq({
                                                               "url" => tool.url,
                                                               "new_tab" => false,
                                                               "resource_link_id" => ContextExternalTool.opaque_identifier_for(content_tag, content_tag.context.shard),
                                                               "resource_link_title" => nil,
                                                               "external_data" => nil,
                                                               "custom_params" => nil,
                                                               "content_id" => tool.id,
                                                               "content_type" => "ContextExternalTool"
                                                             })
        end

        it "includes the assignment_id attribute" do
          expect(json).to include("url")
          uri = URI(json["url"])
          expect(uri.path).to eq "/api/v1/courses/#{course.id}/external_tools/sessionless_launch"
          expect(uri.query).to include("assignment_id=")
        end

        context "that uses LTI 1.3" do
          let(:tool) do
            a = super()
            a.update!(use_1_3: true)
            a
          end

          context "with custom_params" do
            let(:assignment) do
              a = super()
              a.update(lti_resource_link_custom_params: custom_params)
              a
            end
            let(:custom_params) { { "hello" => "world" } }

            it "includes the custom_params" do
              expect(json["external_tool_tag_attributes"]["custom_params"]).to eq custom_params
            end
          end
        end
      end

      context "when result_type is specified (Quizzes.Next serialization)" do
        before do
          @course.root_account.enable_feature!(:newquizzes_on_quiz_page)
        end

        it "outputs quiz shell json using quizzes.next serializer" do
          @assignment = @course.assignments.create!(title: "Test Assignment", description: "foo")
          json = api_call(:get,
                          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}.json",
                          { controller: "assignments_api",
                            action: "show",
                            format: "json",
                            course_id: @course.id.to_s,
                            id: @assignment.id.to_s,
                            all_dates: true,
                            result_type: "Quiz" },
                          { override_assignment_dates: "false" })
          expect(json["quiz_type"]).to eq("quizzes.next")
        end
      end
    end

    context "draft state" do
      before :once do
        @assignment = @course.assignments.create!({
                                                    name: "unpublished assignment",
                                                    points_possible: 15
                                                  })
        @assignment.workflow_state = "unpublished"
        @assignment.save!
      end

      it "returns an authorization error to students if an assignment is unpublished" do
        raw_api_call(:get,
                     "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}",
                     {
                       controller: "assignments_api",
                       action: "show",
                       format: "json",
                       course_id: @course.id.to_s,
                       id: @assignment.id.to_s
                     })

        # should be authorization error
        expect(response).to have_http_status :forbidden
      end

      it "shows an unpublished assignment to teachers" do
        course_with_teacher_logged_in(course: @course, active_all: true)

        json = api_get_assignment_in_course(@assignment, @course)
        expect(response).to be_successful
        expect(json["id"]).to eq @assignment.id
        expect(json["unpublishable"]).to be true

        # Returns "unpublishable => false" when student submissions
        student_in_course(active_all: true, course: @course)
        @assignment.submit_homework(@student, submission_type: "online_text_entry")
        @user = @teacher
        json = api_get_assignment_in_course(@assignment, @course)
        expect(response).to be_successful
        expect(json["unpublishable"]).to be false
      end
    end

    context "differentiated assignments" do
      before :once do
        @user = @teacher
        @assignment1 = @course.assignments.create! only_visible_to_overrides: true
        @assignment2 = @course.assignments.create! only_visible_to_overrides: true
        section1 = @course.course_sections.create!
        section2 = @course.course_sections.create!
        @student1 = User.create!(name: "Test Student")
        @student2 = User.create!(name: "Test Student2")
        @student3 = User.create!(name: "Test Student3")
        student_in_section(section1, user: @student1)
        student_in_section(section2, user: @student2)
        student_in_section(section2, user: @student3)
        create_section_override_for_assignment(@assignment1, { course_section: section1 })
        create_section_override_for_assignment(@assignment2, { course_section: section2 })
        assignment_override_model(assignment: @assignment1, set_type: "Noop", title: "Just a Tag")
      end

      def visibility_api_request(assignment)
        api_call(:get,
                 "/api/v1/courses/#{@course.id}/assignments/#{assignment.id}.json",
                 {
                   controller: "assignments_api",
                   action: "show",
                   format: "json",
                   course_id: @course.id.to_s,
                   id: assignment.id.to_s
                 },
                 include: ["assignment_visibility"])
      end

      it "includes overrides if overrides flag is included in the params" do
        allow(ConditionalRelease::Service).to receive(:enabled_in_context?).and_return(true)
        assignments_json = api_call(:get,
                                    "/api/v1/courses/#{@course.id}/assignments/#{@assignment1.id}.json",
                                    {
                                      controller: "assignments_api",
                                      action: "show",
                                      format: "json",
                                      course_id: @course.id.to_s,
                                      id: @assignment1.id.to_s
                                    },
                                    include: ["overrides"])
        expect(assignments_json.keys).to include("overrides")
        expect(assignments_json["overrides"].length).to eq 2
      end

      it "returns any assignment" do
        json1 = api_get_assignment_in_course @assignment1, @course
        expect(json1["id"]).to eq @assignment1.id
        json2 = api_get_assignment_in_course @assignment2, @course
        expect(json2["id"]).to eq @assignment2.id
      end

      it "includes assignment_visibility" do
        json = visibility_api_request @assignment1
        expect(json).to have_key("assignment_visibility")
      end

      it "assignment_visibility includes the correct user_ids" do
        json = visibility_api_request @assignment1
        expect(json["assignment_visibility"].include?(@student1.id.to_s)).to be true
        json = visibility_api_request @assignment2
        expect(json["assignment_visibility"].include?(@student2.id.to_s)).to be true
        expect(json["assignment_visibility"].include?(@student3.id.to_s)).to be true
      end

      context "as a student" do
        it "returns a visible assignment" do
          user_session @student1
          @user = @student1
          json = api_get_assignment_in_course @assignment1, @course
          expect(json["id"]).to eq @assignment1.id
        end

        it "returns an error for a non-visible assignment" do
          user_session @student2
          @user = @student2
          api_call(:get,
                   "/api/v1/courses/#{@course.id}/assignments/#{@assignment1.id}.json",
                   { controller: "assignments_api",
                     action: "show",
                     format: "json",
                     course_id: @course.id.to_s,
                     id: @assignment1.id.to_s },
                   {},
                   {},
                   { expected_status: 403 })
        end

        it "does not include assignment_visibility data when requested" do
          user_session @student1
          @user = @student1
          json = visibility_api_request @assignment1
          expect(json).not_to have_key("assignment_visibility")
        end
      end
    end
  end

  describe "assignment_json" do
    let(:result) { assignment_json(@assignment, @user, {}) }

    before :once do
      course_with_teacher(active_all: true)
      @assignment = @course.assignments.create!(title: "some assignment")
    end

    context "when turnitin_enabled is true on the context" do
      before(:once) do
        account = @course.account
        account.turnitin_account_id = 1234
        account.turnitin_shared_secret = "foo"
        account.turnitin_host = "example.com"
        account.settings[:enable_turnitin] = true
        account.save!
        @assignment.reload
      end

      it "contains a turnitin_enabled key" do
        expect(result).to have_key("turnitin_enabled")
      end
    end

    context "when turnitin_enabled is false on the context" do
      it "does not contain a turnitin_enabled key" do
        expect(result).not_to have_key("turnitin_enabled")
      end
    end

    it "contains false for anonymous_grading when the assignment has anonymous grading disabled" do
      @assignment.anonymous_grading = false
      expect(result["anonymous_grading"]).to be false
    end

    it "contains true for anonymous_grading when the assignment has anonymous grading enabled" do
      @assignment.anonymous_grading = true
      expect(result["anonymous_grading"]).to be true
    end

    it "contains true for anonymize_students when the assignment is anonymized for students" do
      @assignment.update!(anonymous_grading: true)
      @assignment.ensure_post_policy(post_manually: true)
      student_in_course(course: @course, active_all: true)
      @assignment.grade_student(@student, grader: @teacher, score: 5)
      expect(result["anonymous_grading"]).to be true
    end

    it "contains false for anonymize_students when the assignment is not anonymized for students" do
      @assignment.anonymous_grading = false
      expect(result["anonymize_students"]).to be false
    end

    it "includes the assignment's annotatable_attachment_id for existing assignments" do
      attachment = attachment_model(context: @course)
      @assignment.update(
        annotatable_attachment: attachment,
        submission_types: "student_annotation"
      )
      expect(result["annotatable_attachment_id"]).to eq attachment.id
    end

    it "includes the assignment's annotatable_attachment_id for new assignments" do
      attachment = attachment_model(context: @course)
      assignment = @course.assignments.build(
        annotatable_attachment: attachment,
        submission_types: "student_annotation"
      )
      result = assignment_json(assignment, @user, {})
      expect(result["annotatable_attachment_id"]).to eq attachment.id
    end

    context "can_submit value" do
      before do
        course_with_student_logged_in(course_name: "Course 1", active_all: 1)
        @course.start_at = 14.days.ago
        @course.save!
        @assignment = @course.assignments.create!(title: "Assignment 1",
                                                  points_possible: 10,
                                                  submission_types: "online_text_entry")
      end

      def get_assignment
        api_call(:get,
                 "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}?include[]=can_submit",
                 { controller: "assignments_api",
                   action: "show",
                   format: "json",
                   course_id: @course.id.to_s,
                   id: @assignment.id,
                   include: ["can_submit"] })
      end

      it "is true for assignment" do
        @course.conclude_at = 7.days.from_now
        @course.save!
        json = get_assignment
        expect(json).to have_key("can_submit")
        expect(json["can_submit"]).to be_truthy
      end

      it "is true for assignment in course that is soft-concluded but not restricted" do
        @course.conclude_at = 3.days.ago
        @course.restrict_enrollments_to_course_dates = false
        @course.save!
        json = get_assignment
        expect(json).to have_key("can_submit")
        expect(json["can_submit"]).to be_truthy
      end

      it "is false for assignment in course that is soft-concluded and restricted" do
        @course.conclude_at = 3.days.ago
        @course.restrict_enrollments_to_course_dates = true
        @course.save!
        json = get_assignment
        expect(json).to have_key("can_submit")
        expect(json["can_submit"]).to be_falsey
      end

      it "is false if the assignment has no submission types" do
        @assignment.submission_types = "none"
        @assignment.save!
        json = get_assignment
        expect(json).to have_key("can_submit")
        expect(json["can_submit"]).to be_falsey
      end

      it "is false if the assignment is submitted on paper" do
        @assignment.submission_types = "on_paper"
        @assignment.save!
        json = get_assignment
        expect(json).to have_key("can_submit")
        expect(json["can_submit"]).to be_falsey
      end

      it "is false if the assignment is locked" do
        @assignment.unlock_at = 2.days.from_now
        @assignment.save!
        json = get_assignment
        expect(json).to have_key("can_submit")
        expect(json["can_submit"]).to be_falsey
      end

      it "is false if the allowed_attempts are used" do
        @assignment.allowed_attempts = 1
        @assignment.submit_homework(@student, submission_type: "online_text_entry", body: "Assignment submitted")
        @assignment.save!
        json = get_assignment
        expect(json).to have_key("can_submit")
        expect(json["can_submit"]).to be_falsey
      end

      it "does not show when getting all assignments" do
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/assignments/?include[]=can_submit",
                        { controller: "assignments_api",
                          action: "index",
                          format: "json",
                          course_id: @course.id.to_s,
                          include: ["can_submit"] })
        expect(json.first).to have_key("description")
        expect(json.first).not_to have_key("can_submit")
      end

      it "does not show when can_submit param is not included" do
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}",
                        { controller: "assignments_api",
                          action: "show",
                          format: "json",
                          course_id: @course.id.to_s,
                          id: @assignment.id })
        expect(json).to have_key("description")
        expect(json).not_to have_key("can_submit")
      end
    end

    context "ab_guid" do
      before do
        course_with_student_logged_in(course_name: "Course 1", active_all: 1)
        @course.start_at = 14.days.ago
        @course.save!
        @assignment = @course.assignments.create!(title: "Assignment 1",
                                                  points_possible: 10,
                                                  submission_types: "online_text_entry",
                                                  ab_guid: ["1234"])
        account = Account.default
        outcome = account.created_learning_outcomes.create!(
          title: "My Outcome",
          description: "Description of my outcome",
          vendor_guid: "vendorguid9000"
        )
        rating = [{ id: "rat1",
                    description: "Full Marks",
                    long_description: "Student did a great job.",
                    points: 5.0 }]
        criteria = [{ id: 1, points: 9000, learning_outcome_id: outcome.id, description: "description", long_description: "long description", ratings: rating }]

        @assignment2 = @course.assignments.create!(title: "Assignment 2")
        @rubric = @course.rubrics.create!(title: "My Rubric", context: @course, data: criteria)
        @assignment2.rubric = @rubric
        @assignment2.save!
        @assignment2.rubric_association.context = @course
        @assignment2.rubric_association.save!

        @assignment3 = @course.assignments.create!(title: "Assignment 3")
      end

      def get_assignment_with_guid(assignment_id)
        api_call(:get,
                 "/api/v1/courses/#{@course.id}/assignments/#{assignment_id}?include[]=ab_guid",
                 { controller: "assignments_api",
                   action: "show",
                   format: "json",
                   course_id: @course.id.to_s,
                   id: assignment_id,
                   include: ["ab_guid"] })
      end

      it "returns ab_guid when it is included in include param" do
        json = get_assignment_with_guid(@assignment.id)
        expect(json).to have_key("ab_guid")
        expect(json["ab_guid"]).to eq(["1234"])
      end

      it "returns vendor_id through rubrics if no ab_guid is present" do
        json = get_assignment_with_guid(@assignment2.id)
        expect(json).to have_key("ab_guid")
        expect(json["ab_guid"]).to eq(["vendorguid9000"])
      end

      it "returns an empty array if ab_guid is requested and none exists on assignment or through rubric" do
        json = get_assignment_with_guid(@assignment3.id)
        expect(json).to have_key("ab_guid")
        expect(json["ab_guid"]).to eq([])
      end
    end
  end

  context "update_from_params" do
    before :once do
      course_with_teacher(active_all: true)
      student_in_course(active_all: true)
      @assignment = @course.assignments.create!(title: "some assignment")
    end

    def strong_anything
      ArbitraryStrongishParams::ANYTHING
    end

    it "updates the external tool content_id" do
      mh = create_message_handler(create_resource_handler(create_tool_proxy))
      tool_tag = ContentTag.new(url: "http://www.example.com", new_tab: false, tag_type: "context_module")
      tool_tag.context = @assignment
      tool_tag.save!
      params = ActionController::Parameters.new({
                                                  "submission_types" => ["external_tool"],
                                                  "external_tool_tag_attributes" => {
                                                    "url" => "https://testvmserver.test.com/canvas/test/",
                                                    "content_type" => "lti/message_handler",
                                                    "content_id" => mh.id,
                                                    "new_tab" => "0"
                                                  }
                                                })
      assignment = update_from_params(@assignment, params, @user)
      tag = assignment.external_tool_tag
      expect(tag.content_id).to eq mh.id
      expect(tag.content_type).to eq "Lti::MessageHandler"
    end

    it "sets the context external tool type" do
      tool = ContextExternalTool.new(name: "test tool",
                                     consumer_key: "test",
                                     shared_secret: "shh",
                                     url: "http://www.example.com")
      tool.context = @course
      tool.save!
      tool_tag = ContentTag.new(url: "http://www.example.com", new_tab: false, tag_type: "context_module")
      tool_tag.context = @assignment
      tool_tag.save!
      params = ActionController::Parameters.new({
                                                  "submission_types" => ["external_tool"],
                                                  "external_tool_tag_attributes" => {
                                                    "url" => "https://testvmserver.test.com/canvas/test/",
                                                    "content_type" => "context_external_tool",
                                                    "content_id" => tool.id,
                                                    "new_tab" => "0"
                                                  }
                                                })
      assignment = update_from_params(@assignment, params, @user)
      tag = assignment.external_tool_tag
      expect(tag.content_id).to eq tool.id
      expect(tag.content_type).to eq "ContextExternalTool"
    end

    it "does not update integration_data when lacking permission" do
      json = %({"key": "value"})
      params = ActionController::Parameters.new({ "integration_data" => json })

      update_from_params(@assignment, params, @user)
      expect(@assignment.integration_data).to eq({})
    end

    it "updates integration_data with permission" do
      json = %({"key": "value"})
      params = ActionController::Parameters.new({ "integration_data" => json })
      account_admin_user_with_role_changes(
        role_changes: { manage_sis: true }
      )
      update_from_params(@assignment, params, @admin)
      expect(@assignment.integration_data).to eq({ "key" => "value" })
    end

    it "does not update sis_source_id when lacking permission" do
      params = ActionController::Parameters.new({ "sis_assignment_id" => "BLAH" })
      update_from_params(@assignment, params, @user)
      expect(@assignment.sis_source_id).to be_nil
    end

    it "updates sis_source_id with permission" do
      params = ActionController::Parameters.new({ "sis_assignment_id" => "BLAH" })
      account_admin_user_with_role_changes(
        role_changes: { manage_sis: true }
      )
      update_from_params(@assignment, params, @admin)
      expect(@assignment.sis_source_id).to eq "BLAH"
    end

    it "sets sis_source_id to nil when provided an empty string" do
      params = ActionController::Parameters.new({ "sis_assignment_id" => "" })
      account_admin_user_with_role_changes(role_changes: { manage_sis: true })
      update_from_params(@assignment, params, @admin)
      expect(@assignment.sis_source_id).to be_nil
    end

    it "does not update anonymous grading if the anonymous marking feature flag is not set" do
      params = ActionController::Parameters.new({ "anonymous_grading" => "true" })
      update_from_params(@assignment, params, @teacher)
      expect(@assignment.anonymous_grading).to be_falsey
    end

    context "when the assignment has peer reviews" do
      before do
        student2 = @course.enroll_user(User.create!, "StudentEnrollment", active_all: true).user
        @assignment.update!(peer_reviews: true)
        @assessment_request = AssessmentRequest.create!(
          asset: @assignment.submission_for_student(@student),
          user: @student,
          assessor: student2,
          assessor_asset: @assignment.submission_for_student(student2)
        )
      end

      it "updates the updated_at of related AssessmentRequests when anonymous_peer_reviews changes" do
        params = ActionController::Parameters.new({ "anonymous_peer_reviews" => "1" })
        expect do
          update_from_params(@assignment, params, @teacher)
        end.to change {
          @assessment_request.reload.updated_at
        }
      end

      it "does not update the updated_at of related AssessmentRequests when anonymous_peer_reviews does not change" do
        @assignment.update!(anonymous_peer_reviews: true)
        params = ActionController::Parameters.new({ "anonymous_peer_reviews" => "1" })
        expect do
          update_from_params(@assignment, params, @teacher)
        end.not_to change {
          @assessment_request.reload.updated_at
        }
      end
    end

    context "when the anonymous marking feature flag is set" do
      before(:once) do
        @course.enable_feature!(:anonymous_marking)
      end

      it "enables anonymous grading if anonymous_grading is true" do
        params = ActionController::Parameters.new({ "anonymous_grading" => "true" })
        update_from_params(@assignment, params, @teacher)
        expect(@assignment).to be_anonymous_grading
      end

      it "disables anonymous grading if anonymous_grading is false" do
        params = ActionController::Parameters.new({ "anonymous_grading" => "false" })
        update_from_params(@assignment, params, @teacher)
        expect(@assignment).not_to be_anonymous_grading
      end

      it "does not update anonymous grading status if anonymous_grading is not present" do
        @assignment.anonymous_grading = true

        params = ActionController::Parameters.new({})
        update_from_params(@assignment, params, @teacher)

        expect(@assignment).to be_anonymous_grading
      end

      it "does not set final_grader_id if the assignment is not moderated" do
        options = { final_grader_id: @teacher.id }
        params = ActionController::Parameters.new(options.as_json)
        update_from_params(@assignment, params, @teacher)
        expect(@assignment.final_grader).to be_nil
      end

      context "when the assignment is moderated" do
        before(:once) do
          @assignment.update!(moderated_grading: true, grader_count: 2)
        end

        it 'nils out the final_grader_id when passed final_grader_id: ""' do
          @assignment.update!(final_grader: @teacher)
          options = { final_grader_id: "" }
          params = ActionController::Parameters.new(options.as_json)
          update_from_params(@assignment, params, @teacher)
          expect(@assignment.final_grader).to be_nil
        end

        it "nils out the final_grader_id when passed final_grader_id: nil" do
          @assignment.update!(final_grader: @teacher)
          options = { final_grader_id: nil }
          params = ActionController::Parameters.new(options.as_json)
          update_from_params(@assignment, params, @teacher)
          expect(@assignment.final_grader).to be_nil
        end

        it "sets the final_grader_id if the user exists" do
          options = { final_grader_id: @teacher.id }
          params = ActionController::Parameters.new(options.as_json)
          update_from_params(@assignment, params, @teacher)
          expect(@assignment.final_grader).to eq @teacher
        end
      end
    end

    context "with the duplicated_successfully parameter" do
      subject { @assignment }

      let(:params) do
        ActionController::Parameters.new(duplicated_successfully:)
      end

      before do
        allow(@assignment).to receive(:finish_duplicating)
        allow(@assignment).to receive(:fail_to_duplicate)
        update_from_params(@assignment, params, @teacher)
      end

      context "when duplicated_successfully is true" do
        let(:duplicated_successfully) { true }

        it { is_expected.to have_received(:finish_duplicating) }
      end

      context "when duplicated_successfully is false" do
        let(:duplicated_successfully) { false }

        it { is_expected.to have_received(:fail_to_duplicate) }
      end

      context "when duplicated_successfully is true after timeout" do
        before do
          @assignment.update(workflow_state: "failed_to_duplicate")
        end

        let(:duplicated_successfully) { true }

        it { is_expected.to have_received(:finish_duplicating) }
      end
    end

    context "with the cc_imported_successfully parameter" do
      subject { @assignment }

      let(:params) do
        ActionController::Parameters.new(cc_imported_successfully:)
      end

      before do
        allow(@assignment).to receive(:finish_importing)
        allow(@assignment).to receive(:fail_to_import)
        update_from_params(@assignment, params, @teacher)
      end

      context "when cc_imported_successfully is true" do
        let(:cc_imported_successfully) { true }

        it { is_expected.to have_received(:finish_importing) }
      end

      context "when cc_imported_successfully is false" do
        let(:cc_imported_successfully) { false }

        it { is_expected.to have_received(:fail_to_import) }
      end
    end
  end

  context "as an observer viewing assignments" do
    before :once do
      @observer_enrollment = course_with_observer(active_all: true)
      @observer = @user
      @observer_course = @course
      @observed_student = create_users(1, return_type: :record).first
      @student_enrollment =
        @observer_course.enroll_student(@observed_student,
                                        enrollment_state: "active")
      @assigned_observer_enrollment =
        @observer_course.enroll_user(@observer,
                                     "ObserverEnrollment",
                                     associated_user_id: @observed_student.id)
      @assigned_observer_enrollment.accept

      @assignment, @submission = create_submitted_assignment_with_user(@observed_student)
    end

    it "includes submissions for observed users when requested with all assignments" do
      @assignment.unmute!
      @submission.reload
      json = api_call_as_user(@observer,
                              :get,
                              "/api/v1/courses/#{@observer_course.id}/assignments?include[]=observed_users&include[]=submission",
                              { controller: "assignments_api",
                                action: "index",
                                format: "json",
                                course_id: @observer_course.id,
                                include: ["observed_users", "submission"] })

      expect(json.first["submission"]).to eql [{
        "assignment_id" => @assignment.id,
        "attempt" => nil,
        "body" => nil,
        "cached_due_date" => nil,
        "excused" => nil,
        "grade" => "99",
        "entered_grade" => "99",
        "grading_period_id" => @submission.grading_period_id,
        "grade_matches_current_submission" => true,
        "graded_at" => nil,
        "posted_at" => @submission.posted_at.as_json,
        "grader_id" => @teacher.id,
        "id" => @submission.id,
        "redo_request" => false,
        "score" => 99.0,
        "entered_score" => 99.0,
        "submission_type" => nil,
        "submitted_at" => nil,
        "url" => nil,
        "user_id" => @observed_student.id,
        "workflow_state" => "submitted",
        "late" => false,
        "missing" => false,
        "late_policy_status" => nil,
        "points_deducted" => nil,
        "seconds_late" => 0,
        "sticker" => nil,
        "preview_url" =>
         "http://www.example.com/courses/#{@observer_course.id}/assignments/#{@assignment.id}/submissions/#{@observed_student.global_id}?preview=1&version=0",
        "extra_attempts" => nil,
        "custom_grade_status_id" => nil
      }]
    end

    it "includes submissions for observed users when requested with a single assignment" do
      @assignment.unmute!
      @submission.reload
      json = api_call_as_user(@observer,
                              :get,
                              "/api/v1/courses/#{@observer_course.id}/assignments/#{@assignment.id}?include[]=observed_users&include[]=submission",
                              { controller: "assignments_api",
                                action: "show",
                                format: "json",
                                id: @assignment.id,
                                course_id: @observer_course.id,
                                include: ["observed_users", "submission"] })
      expect(json["submission"]).to eql [{
        "assignment_id" => @assignment.id,
        "attempt" => nil,
        "body" => nil,
        "cached_due_date" => nil,
        "excused" => nil,
        "grade" => "99",
        "entered_grade" => "99",
        "grading_period_id" => @submission.grading_period_id,
        "grade_matches_current_submission" => true,
        "graded_at" => nil,
        "posted_at" => @submission.posted_at.as_json,
        "grader_id" => @teacher.id,
        "id" => @submission.id,
        "redo_request" => false,
        "score" => 99.0,
        "entered_score" => 99.0,
        "submission_type" => nil,
        "submitted_at" => nil,
        "url" => nil,
        "user_id" => @observed_student.id,
        "workflow_state" => "submitted",
        "late" => false,
        "missing" => false,
        "late_policy_status" => nil,
        "points_deducted" => nil,
        "seconds_late" => 0,
        "sticker" => nil,
        "preview_url" =>
         "http://www.example.com/courses/#{@observer_course.id}/assignments/#{@assignment.id}/submissions/#{@observed_student.global_id}?preview=1&version=0",
        "extra_attempts" => nil,
        "custom_grade_status_id" => nil
      }]
    end
  end

  context "assignment override preloading" do
    before :once do
      course_with_teacher(active_all: true)

      student_in_course(course: @course, active_all: true)
      @override = assignment_override_model(course: @course)
      @override_student = @override.assignment_override_students.build
      @override_student.user = @student
      @override_student.save!

      @assignment.only_visible_to_overrides = true
      @assignment.save!
    end

    it "preloads student_ids when including adhoc overrides" do
      expect_any_instantiation_of(@override).not_to receive(:assignment_override_students)
      json = api_call_as_user(@teacher,
                              :get,
                              "/api/v1/courses/#{@course.id}/assignments?include[]=overrides",
                              { controller: "assignments_api",
                                action: "index",
                                format: "json",
                                course_id: @course.id,
                                include: ["overrides"] })
      expect(json.first["overrides"].first["student_ids"]).to eq [@student.id]
    end

    it "preloads student_ids when including adhoc overrides on assignment groups api as well" do
      # yeah i know this is a separate api; sue me

      expect_any_instantiation_of(@override).not_to receive(:assignment_override_students)
      json = api_call_as_user(@teacher,
                              :get,
                              "/api/v1/courses/#{@course.id}/assignment_groups?include[]=assignments&include[]=overrides",
                              { controller: "assignment_groups",
                                action: "index",
                                format: "json",
                                course_id: @course.id,
                                include: ["assignments", "overrides"] })
      expect(json.first["assignments"].first["overrides"].first["student_ids"]).to eq [@student.id]
    end
  end

  context "when called with parameter calculate_grades" do
    let(:course) { Account.default.courses.create!(workflow_state: "available") }
    let(:teacher) { course_with_teacher(course:, active_all: true).user }

    it "calls SubmissionLifecycleManager with update_grades: false when passed calculate_grades: false" do
      update_grade_value = nil
      expect(SubmissionLifecycleManager).to receive(:recompute).once do |update_grades:, **|
        update_grade_value = update_grades
      end

      api_call_as_user(teacher,
                       :post,
                       "/api/v1/courses/#{course.id}/assignments.json",
                       {
                         controller: "assignments_api",
                         action: "create",
                         format: "json",
                         course_id: course.id.to_s,
                       },
                       {
                         assignment: {
                           name: "Some title",
                           points_possible: 10,
                           published: true
                         },
                         calculate_grades: false
                       })

      expect(update_grade_value).to be false
    end

    it "calls SubmissionLifecycleManager with update_grades: true when passed calculate_grades: true" do
      update_grade_value = nil
      expect(SubmissionLifecycleManager).to receive(:recompute).once do |update_grades:, **|
        update_grade_value = update_grades
      end

      api_call_as_user(teacher,
                       :post,
                       "/api/v1/courses/#{course.id}/assignments.json",
                       {
                         controller: "assignments_api",
                         action: "create",
                         format: "json",
                         course_id: course.id.to_s,
                       },
                       {
                         assignment: {
                           name: "Some title",
                           points_possible: 10,
                           published: true
                         },
                         calculate_grades: true
                       })

      expect(update_grade_value).to be true
    end

    it "calls SubmissionLifecycleManager with update_grades: true when not passed calculate_grades" do
      update_grade_value = nil
      expect(SubmissionLifecycleManager).to receive(:recompute).once do |update_grades:, **|
        update_grade_value = update_grades
      end

      api_call_as_user(teacher,
                       :post,
                       "/api/v1/courses/#{course.id}/assignments.json",
                       {
                         controller: "assignments_api",
                         action: "create",
                         format: "json",
                         course_id: course.id.to_s,
                       },
                       {
                         assignment: {
                           name: "Some title",
                           points_possible: 10,
                           published: true
                         }
                       })

      expect(update_grade_value).to be true
    end
  end

  context "points possible defaulting" do
    it "assumes 0 for a new assignment" do
      course_with_teacher(active_all: true)
      json = api_create_assignment_in_course(@course, { "name" => "some name" })
      a = Assignment.find(json["id"])
      expect(a.points_possible).to eq 0
    end

    it "assumes 0 for a new assignment even if set to blank" do
      course_with_teacher(active_all: true)
      json = api_create_assignment_in_course(@course, { "name" => "some name", "points_possible" => "" })
      a = Assignment.find(json["id"])
      expect(a.points_possible).to eq 0
    end

    it "does not set to 0 if not included in params for update" do
      course_with_teacher(active_all: true)
      a = @course.assignments.create!(points_possible: 5)
      api_update_assignment_call(@course, a, { "name" => "some new name" })
      expect(a.points_possible).to eq 5
      expect(a.name).to eq "some new name"
    end

    it "sets to 0 if included in params for update and blank" do
      course_with_teacher(active_all: true)
      a = @course.assignments.create!(points_possible: 5)
      api_update_assignment_call(@course, a, { "points_possible" => "" })
      expect(a.points_possible).to eq 0
    end
  end

  describe "PUT bulk_update" do
    before :once do
      course_with_teacher(active_all: true)
      @s1 = @course.course_sections.create! name: "other section"
      @a0 = @course.assignments.create! title: "no dates"
      @a1 = @course.assignments.create! title: "basic", unlock_at: 5.days.ago, due_at: 4.days.ago, lock_at: 2.days.from_now
      @a2 = @course.assignments.create! title: "with overrides", unlock_at: 1.day.ago, due_at: 3.days.from_now, lock_at: 4.days.from_now
      @ao0 = assignment_override_model assignment: @a2, set: @course.default_section, unlock_at: 4.days.ago, due_at: 3.days.ago, lock_at: 4.days.from_now
      @ao1 = assignment_override_model assignment: @a2, set: @s1, due_at: 5.days.from_now, lock_at: 6.days.from_now
      @q0 = @course.quizzes.create!(title: "a quiz", quiz_type: "assignment")
      @new_dates = (7..9).map { |x| x.days.from_now }
    end

    it "requires manage_assignments_edit rights" do
      student_in_course(active_all: true)
      api_bulk_update(@course, [], expected_status: 403)
    end

    it "expects an array of assignments" do
      api_bulk_update(@course, {}, expected_status: 400)
    end

    it "rejects an invalid assignment id" do
      api_bulk_update(@course, [{ "id" => 0, "all_dates" => [{ "id" => 0, "all_dates" => [] }] }], expected_status: 404)
    end

    it "updates assignment dates" do
      api_bulk_update(@course, [{
                        "id" => @a0.id,
                        "all_dates" => [
                          {
                            "base" => true,
                            "due_at" => @new_dates[1].iso8601
                          }
                        ]
                      },
                                {
                                  "id" => @a1.id,
                                  "all_dates" => [
                                    {
                                      "base" => true,
                                      "unlock_at" => @new_dates[0].iso8601,
                                      "due_at" => @new_dates[1].iso8601,
                                      "lock_at" => @new_dates[2].iso8601
                                    }
                                  ]
                                }])
      expect(@a0.reload.due_at.to_i).to eq @new_dates[1].to_i
      expect(@a0.unlock_at).to be_nil
      expect(@a0.lock_at).to be_nil

      expect(@a1.reload.due_at.to_i).to eq @new_dates[1].to_i
      expect(@a1.unlock_at.to_i).to eq @new_dates[0].to_i
      expect(@a1.lock_at.to_i).to eq @new_dates[2].to_i
    end

    context "cache register" do
      specs_require_cache(:redis_cache_store)

      it "clears the cache register values correctly" do
        old_key = Timecop.freeze(1.minute.ago) { @a0.cache_key(:availability) }
        api_bulk_update(@course, [{
                          "id" => @a0.id,
                          "all_dates" => [{ "base" => true, "due_at" => @new_dates[1].iso8601 }]
                        }])
        expect(@a0.cache_key(:availability)).to_not eq old_key
      end

      it "clears cache register values for quizzes" do
        old_key = Timecop.freeze(1.minute.ago) { @q0.cache_key(:availability) }
        api_bulk_update(@course, [{
                          "id" => @q0.assignment.id,
                          "all_dates" => [{ "base" => true, "due_at" => @new_dates[1].iso8601 }]
                        }])
        expect(@q0.cache_key(:availability)).to_not eq old_key
      end
    end

    it "validates assignment dates" do
      json = api_bulk_update(@course,
                             [{
                               "id" => @a0.id,
                               "all_dates" => [
                                 {
                                   "base" => true,
                                   "due_at" => @new_dates[1].iso8601
                                 }
                               ]
                             },
                              {
                                "id" => @a1.id,
                                "all_dates" => [
                                  {
                                    "base" => true,
                                    "unlock_at" => @new_dates[1].iso8601,
                                    "due_at" => @new_dates[0].iso8601, # out of range
                                    "lock_at" => @new_dates[2].iso8601
                                  }
                                ]
                              }],
                             expected_result: "failed")
      expect(json[0]["assignment_id"]).to eq @a1.id
      expect(json[0]["errors"]["due_at"][0]["message"]).to eq "must be between availability dates"

      # ensure the partial update didn't happen
      expect(@a0.due_at.to_i).not_to eq @new_dates[1].to_i
    end

    it "updates override dates" do
      api_bulk_update(@course, [{
                        "id" => @a2.id,
                        "all_dates" => [
                          {
                            "id" => nil,
                            "base" => true,
                            "due_at" => @new_dates[2].iso8601
                          },
                          {
                            "id" => @ao0.id,
                            "due_at" => @new_dates[1].iso8601,
                            "lock_at" => @new_dates[2].iso8601
                          },
                          {
                            "id" => @ao1.id,
                            "unlock_at" => @new_dates[0].iso8601,
                            "due_at" => @new_dates[1].iso8601,
                            "lock_at" => @new_dates[2].iso8601
                          }
                        ]
                      }])
      @a2.reload
      expect(@a2.due_at.to_i).to eq(@new_dates[2].to_i)

      @ao0.reload
      expect(@ao0).not_to be_unlock_at_overridden
      expect(@ao0).to be_due_at_overridden
      expect(@ao0.due_at.to_i).to eq @new_dates[1].to_i
      expect(@ao0).to be_lock_at_overridden
      expect(@ao0.lock_at.to_i).to eq @new_dates[2].to_i

      @ao1.reload
      expect(@ao1).to be_unlock_at_overridden
      expect(@ao1.unlock_at.to_i).to eq @new_dates[0].to_i
      expect(@ao1.due_at.to_i).to eq @new_dates[1].to_i
      expect(@ao1).to be_lock_at_overridden
      expect(@ao1.lock_at.to_i).to eq @new_dates[2].to_i
    end

    describe "with grading periods" do
      before :once do
        grading_period_group = Factories::GradingPeriodGroupHelper.new.create_for_account(@course.root_account)
        term = @course.enrollment_term
        term.grading_period_group = grading_period_group
        term.save!
        Factories::GradingPeriodHelper.new.create_for_group(grading_period_group, {
                                                              start_date: 2.weeks.ago, end_date: 2.days.ago, close_date: 1.day.ago
                                                            })
        Factories::GradingPeriodHelper.new.create_for_group(grading_period_group, {
                                                              start_date: 1.day.ago, end_date: 1.month.from_now, close_date: 2.months.from_now
                                                            })
        Factories::GradingPeriodHelper.new.create_for_group(grading_period_group, {
                                                              start_date: 2.months.from_now, end_date: 4.months.from_now, close_date: 5.months.from_now
                                                            })
        student_in_course(active_all: true)
        @user = @teacher
      end

      it "prohibits moving due/override dates into or out of a closed grading period" do
        data = [
          {
            "id" => @a1.id, # in a closed grading period
            "all_dates" => [
              {
                "base" => true,
                "due_at" => 5.days.from_now
              }
            ]
          },
          {
            "id" => @a2.id,
            "all_dates" => [
              {
                "id" => @ao0.id, # in a closed grading period
                "due_at" => 5.days.from_now
              },
              {
                "id" => @ao1.id, # not in a closed grading period
                "due_at" => 5.days.ago
              }
            ]
          }
        ]
        json = api_bulk_update(@course, data, expected_result: "failed")

        a1_json = json.detect { |r| r["assignment_id"] == @a1.id }
        expect(a1_json["errors"]["due_at"][0]["message"]).to eq "Cannot change the due date when due in a closed grading period"

        ao0_json = json.detect { |r| r["assignment_override_id"] == @ao0.id }
        expect(ao0_json["assignment_id"]).to eq @a2.id
        expect(ao0_json["errors"]["due_at"][0]["message"]).to eq "Cannot change the due date of an override in a closed grading period"

        ao1_json = json.detect { |r| r["assignment_override_id"] == @ao1.id }
        expect(ao1_json["assignment_id"]).to eq @a2.id
        expect(ao1_json["errors"]["due_at"][0]["message"]).to eq "Cannot change an override due date to a date within a closed grading period"
      end

      it "recomputes scores once when assignments get moved to new grading periods" do
        data = [
          {
            "id" => @a0.id,
            "all_dates" => [
              {
                "base" => true,
                "due_at" => 5.days.from_now # third grading period to second
              }
            ]
          },
          {
            "id" => @a2.id,
            "all_dates" => [
              {
                "id" => @ao1.id,
                "due_at" => 3.months.from_now # second grading period to third
              }
            ]
          }
        ]
        expect_any_instance_of(Course).to receive(:recompute_student_scores_without_send_later).once
        api_bulk_update(@course, data)
      end

      it "sets can_edit on each date if requested" do
        json = api_get_assignments_index_from_course(@course, include: %w[all_dates can_edit])
        a0_json = json.detect { |a| a["id"] == @a0.id }
        expect(a0_json["can_edit"]).to be true
        expect(a0_json["all_dates"].pluck("can_edit")).to eq [true]
        expect(a0_json["all_dates"].pluck("in_closed_grading_period")).to eq [false]

        a1_json = json.detect { |a| a["id"] == @a1.id }
        expect(a1_json["can_edit"]).to be true
        expect(a1_json["all_dates"].pluck("can_edit")).to eq [false]
        expect(a1_json["all_dates"].pluck("in_closed_grading_period")).to eq [true]

        a2_json = json.detect { |a| a["id"] == @a2.id }
        expect(a2_json["can_edit"]).to be true

        ao0_json = a2_json["all_dates"].detect { |ao| ao["id"] == @ao0.id }
        expect(ao0_json["can_edit"]).to be false
        expect(ao0_json["in_closed_grading_period"]).to be true

        ao1_json = a2_json["all_dates"].detect { |ao| ao["id"] == @ao1.id }
        expect(ao1_json["can_edit"]).to be true
        expect(ao1_json["in_closed_grading_period"]).to be false
      end

      it "allows account admins to edit whatever they want" do
        account_admin_user
        json = api_get_assignments_index_from_course(@course, include: %w[all_dates can_edit])
        a0_json = json.detect { |a| a["id"] == @a0.id }
        expect(a0_json["can_edit"]).to be true
        expect(a0_json["all_dates"].pluck("can_edit")).to eq [true]
        expect(a0_json["all_dates"].pluck("in_closed_grading_period")).to eq [false]

        a1_json = json.detect { |a| a["id"] == @a1.id }
        expect(a1_json["can_edit"]).to be true
        expect(a1_json["all_dates"].pluck("can_edit")).to eq [true]
        expect(a1_json["all_dates"].pluck("in_closed_grading_period")).to eq [true]

        a2_json = json.detect { |a| a["id"] == @a2.id }
        expect(a2_json["can_edit"]).to be true

        ao0_json = a2_json["all_dates"].detect { |ao| ao["id"] == @ao0.id }
        expect(ao0_json["can_edit"]).to be true
        expect(ao0_json["in_closed_grading_period"]).to be true

        ao1_json = a2_json["all_dates"].detect { |ao| ao["id"] == @ao1.id }
        expect(ao1_json["can_edit"]).to be true
        expect(ao1_json["in_closed_grading_period"]).to be false
      end
    end

    context "with moderated grading" do
      before :once do
        @course.account.role_overrides.create!(permission: :select_final_grade, enabled: false, role: ta_role)
        ta_in_course(active_all: true)

        @a0.moderated_grading = true
        @a0.final_grader_id = @teacher
        @a0.grader_count = 1
        @a0.save!
      end

      it "disallows editing moderated assignments if you're not the moderator" do
        api_bulk_update(@course, [{ "id" => @a0.id, "all_dates" => [] }], expected_status: 403)
        api_bulk_update(@course, [{ "id" => @a1.id, "all_dates" => [] }])
      end

      it "sets can_edit on each date if requested" do
        json = api_get_assignments_index_from_course(@course, include: %w[all_dates can_edit])

        a0_json = json.detect { |a| a["id"] == @a0.id }
        expect(a0_json["can_edit"]).to be false
        expect(a0_json["all_dates"].pluck("can_edit")).to eq [false]

        a1_json = json.detect { |a| a["id"] == @a1.id }
        expect(a1_json["can_edit"]).to be true
        expect(a1_json["all_dates"].pluck("can_edit")).to eq [true]
      end
    end
  end
end

def api_get_assignments_index_from_course_as_user(course, user, params = {})
  options = {
    controller: "assignments_api",
    action: "index",
    format: "json",
    course_id: course.id.to_s
  }
  options = options.merge(params)
  api_call_as_user(user, :get, "/api/v1/courses/#{course.id}/assignments.json", options)
end

def api_get_assignments_index_from_course(course, params = {})
  options = {
    controller: "assignments_api",
    action: "index",
    format: "json",
    course_id: course.id.to_s
  }
  options = options.merge(params)
  api_call(:get, "/api/v1/courses/#{course.id}/assignments.json", options)
end

def api_get_assignments_user_index(user, course, api_user = @user, params = {})
  api_call_as_user(api_user,
                   :get,
                   "/api/v1/users/#{user.id}/courses/#{course.id}/assignments.json",
                   {
                     controller: "assignments_api",
                     action: "user_index",
                     format: "json",
                     course_id: course.id.to_s,
                     user_id: user.id.to_s
                   }.merge(params))
end

def create_frozen_assignment_in_course(_course)
  assignment = @course.assignments.create!({
                                             title: "some assignment",
                                             freeze_on_copy: true
                                           })
  assignment.copied = true
  assignment.save!
  assignment
end

def raw_api_update_assignment(course, assignment, assignment_params)
  raw_api_call(:put,
               "/api/v1/courses/#{course.id}/assignments/#{assignment.id}.json",
               { controller: "assignments_api",
                 action: "update",
                 format: "json",
                 course_id: course.id.to_s,
                 id: assignment.id.to_s },
               {
                 "assignment" => assignment_params
               })
  course.reload
  assignment.reload
end

def api_get_assignment_in_course(assignment, course, params = {})
  options = { controller: "assignments_api",
              action: "show",
              format: "json",
              course_id: course.id.to_s,
              id: assignment.id.to_s }.merge(params)
  json = api_call(:get,
                  "/api/v1/courses/#{course.id}/assignments/#{assignment.id}.json",
                  options)
  assignment.reload
  course.reload
  json
end

def api_update_assignment_call(course, assignment, assignment_params)
  json = api_call(
    :put,
    "/api/v1/courses/#{course.id}/assignments/#{assignment.id}.json",
    {
      controller: "assignments_api",
      action: "update",
      format: "json",
      course_id: course.id.to_s,
      id: assignment.id.to_s
    },
    { assignment: assignment_params }
  )
  assignment.reload
  course.reload
  json
end

def fully_frozen_settings
  {
    "title" => "true",
    "description" => "true",
    "lock_at" => "true",
    "points_possible" => "true",
    "grading_type" => "true",
    "submission_types" => "true",
    "assignment_group_id" => "true",
    "allowed_extensions" => "true",
    "group_category_id" => "true",
    "notify_of_update" => "true",
    "peer_reviews" => "true",
    "workflow_state" => "true"
  }
end

def api_create_assignment_in_course(course, assignment_params)
  api_call(:post,
           "/api/v1/courses/#{course.id}/assignments.json",
           {
             controller: "assignments_api",
             action: "create",
             format: "json",
             course_id: course.id.to_s
           },
           { assignment: assignment_params })
end

def api_bulk_update(course, data, expected_status: 200, expected_result: "completed")
  json = api_call(:put,
                  "/api/v1/courses/#{course.id}/assignments/bulk_update",
                  { controller: "assignments_api",
                    action: "bulk_update",
                    format: "json",
                    course_id: course.to_param },
                  { _json: data },
                  {},
                  { expected_status: })
  return json unless response.status == 200

  progress = Progress.find(json["id"])
  expect(progress["workflow_state"]).to eq "queued"
  run_jobs

  progress.reload
  expect(progress["workflow_state"]).to eq expected_result
  progress.results
end
