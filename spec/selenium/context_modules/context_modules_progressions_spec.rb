# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

require_relative "../common"
require_relative "../helpers/context_modules_common"
require_relative "../helpers/quizzes_common"

describe "context modules" do
  include_context "in-process server selenium tests"
  include ContextModulesCommon

  let(:quiz_helper) { Class.new { extend QuizzesCommon } }

  context "progressions", priority: "1" do
    before :once do
      course_with_teacher(active_all: true)

      @module1 = @course.context_modules.create!(name: "module1")
      @assignment = @course.assignments.create!(name: "pls submit", submission_types: ["online_text_entry"], points_possible: 42)
      @assignment.publish
      @assignment_tag = @module1.add_item(id: @assignment.id, type: "assignment")
      @external_url_tag = @module1.add_item(type: "external_url",
                                            url: "http://example.com/lolcats",
                                            title: "pls view",
                                            indent: 1)
      @external_url_tag.publish
      @header_tag = @module1.add_item(type: "sub_header", title: "silly tag")

      @module1.completion_requirements = {
        @assignment_tag.id => { type: "must_submit" },
        @external_url_tag.id => { type: "must_view" }
      }
      @module1.save!

      @christmas = Time.zone.local(Time.zone.now.year + 1, 12, 25, 7, 0)
      @module2 = @course.context_modules.create!(name: "do not open until christmas",
                                                 unlock_at: @christmas,
                                                 require_sequential_progress: true)
      @module2.prerequisites = "module_#{@module1.id}"
      @module2.save!

      @module3 = @course.context_modules.create(name: "module3")
      @module3.workflow_state = "unpublished"
      @module3.save!

      @students = create_users_in_course(@course, 4, return_type: :record)

      # complete for student 0
      @assignment.submit_homework(@students[0], body: "done!")
      @external_url_tag.context_module_action(@students[0], :read)
      # in progress for student 1-2
      @assignment.submit_homework(@students[1], body: "done!")
      @external_url_tag.context_module_action(@students[2], :read)
      # unlocked for student 3
    end

    before do
      user_session(@teacher)
    end

    it "shows student progressions to teachers" do
      get "/courses/#{@course.id}/modules/progressions"

      expect(f("#progression_student_#{@students[0].id}_module_#{@module1.id} .status").text).to include("Complete")
      expect(f("#progression_student_#{@students[0].id}_module_#{@module2.id} .status").text).to include("Locked")
      expect(f("#content")).not_to contain_css("#progression_student_#{@students[0].id}_module_#{@module3.id}")

      f("#progression_student_#{@students[1].id}").click
      wait_for_ajaximations
      expect(f("#progression_student_#{@students[1].id}_module_#{@module1.id} .status").text).to include("In Progress")
      expect(f("#progression_student_#{@students[1].id}_module_#{@module1.id} .items").text).to_not include(@header_tag.title)
      expect(f("#progression_student_#{@students[1].id}_module_#{@module1.id} .items").text).not_to include(@assignment_tag.title)
      expect(f("#progression_student_#{@students[1].id}_module_#{@module1.id} .items").text).to include(@external_url_tag.title)
      expect(f("#progression_student_#{@students[1].id}_module_#{@module2.id} .status").text).to include("Locked")

      f("#progression_student_#{@students[2].id}").click
      wait_for_ajaximations
      expect(f("#progression_student_#{@students[2].id}_module_#{@module1.id} .status").text).to include("In Progress")
      expect(f("#progression_student_#{@students[2].id}_module_#{@module1.id} .items").text).to include(@assignment_tag.title)
      expect(f("#progression_student_#{@students[2].id}_module_#{@module1.id} .items").text).not_to include(@external_url_tag.title)
      expect(f("#progression_student_#{@students[2].id}_module_#{@module2.id} .status").text).to include("Locked")

      f("#progression_student_#{@students[3].id}").click
      wait_for_ajaximations
      expect(f("#progression_student_#{@students[3].id}_module_#{@module1.id} .status").text).to include("Unlocked")
      expect(f("#progression_student_#{@students[3].id}_module_#{@module2.id} .status").text).to include("Locked")
    end

    it "shows progression to individual students", priority: "1" do
      user_session(@students[1])
      get "/courses/#{@course.id}/modules/progressions"
      expect(f("#progression_students")).not_to be_displayed
      expect(f("#progression_student_#{@students[1].id}_module_#{@module1.id} .status").text).to include("In Progress")
      expect(f("#progression_student_#{@students[1].id}_module_#{@module1.id} .items").text).not_to include(@assignment_tag.title)
      expect(f("#progression_student_#{@students[1].id}_module_#{@module1.id} .items").text).to include(@external_url_tag.title)
      expect(f("#progression_student_#{@students[1].id}_module_#{@module2.id} .status").text).to include("Locked")
    end

    it "shows multiple student progressions to observers" do
      @observer = user_factory
      @course.enroll_user(@observer, "ObserverEnrollment", { allow_multiple_enrollments: true,
                                                             associated_user_id: @students[0].id })
      @course.enroll_user(@observer, "ObserverEnrollment", { allow_multiple_enrollments: true,
                                                             associated_user_id: @students[2].id })

      user_session(@observer)

      get "/courses/#{@course.id}/modules/progressions"

      expect(f("#content")).not_to contain_css("#progression_student_#{@students[1].id}")
      expect(f("#content")).not_to contain_css("#progression_student_#{@students[3].id}")
      expect(f("#progression_student_#{@students[0].id}_module_#{@module1.id} .status").text).to include("Complete")
      expect(f("#progression_student_#{@students[0].id}_module_#{@module2.id} .status").text).to include("Locked")
      expect(f("#content")).not_to contain_css("#progression_student_#{@students[0].id}_module_#{@module3.id}")
      f("#progression_student_#{@students[2].id}").click
      wait_for_ajaximations
      expect(f("#progression_student_#{@students[2].id}_module_#{@module1.id} .status").text).to include("In Progress")
      expect(f("#progression_student_#{@students[2].id}_module_#{@module1.id} .items").text).to include(@assignment_tag.title)
      expect(f("#progression_student_#{@students[2].id}_module_#{@module1.id} .items").text).not_to include(@external_url_tag.title)
      expect(f("#progression_student_#{@students[2].id}_module_#{@module2.id} .status").text).to include("Locked")
    end
  end

  context "progression link" do
    before(:once) do
      course_with_teacher(active_all: true)
    end

    before do
      user_session(@teacher)
    end

    it "shows progressions link in modules home page", priority: "2" do
      # progression link is the "View Progress" button
      create_modules(1)
      @course.default_view = "modules"
      @course.save!
      get "/courses/#{@course.id}"
      link = f(".module_progressions_link")
      expect(link).to be_displayed
      expect_new_page_load { link.click }
    end

    it "shows student progress page when view progress button is clicked", priority: "1" do
      create_modules(1)
      @course.default_view = "modules"
      @course.save!
      get "/courses/#{@course.id}"
      link = f(".module_progressions_link")
      # module_progressions_link is the "View Progress" button
      expect(link).to be_displayed
      link.click
      wait_for_ajaximations
      expect(f("#breadcrumbs")).to include_text("Student Progress")
    end

    it "does not show progressions link in modules home page for large rosters (MOOCs)", priority: "2" do
      create_modules(1)
      @course.default_view = "modules"
      @course.large_roster = true
      @course.save!
      get "/courses/#{@course.id}"
      expect(f("#content")).not_to contain_css(".module_progressions_link")
    end

    it "shows progressions link if user has grading permission but not content management" do
      RoleOverride.create!(context: Account.default, permission: "manage_content", role: teacher_role, enabled: false)
      get "/courses/#{@course.id}/modules"
      expect(f("#content")).to contain_css(".module_progressions_link")
    end

    it "does not show progressions link in modules page if user lacks grading permission" do
      RoleOverride.create!(context: Account.default, permission: "view_all_grades", role: teacher_role, enabled: false)
      get "/courses/#{@course.id}/modules"
      expect(f("#content")).not_to contain_css(".module_progressions_link")
    end
  end

  context "View Progress button" do
    before(:once) do
      course_with_teacher(active_all: true)
      @module1 = @course.context_modules.create!(name: "module1")
      @module1.save!
      @module2 = @course.context_modules.create!(name: "module2")
      @assignment_2 = @course.assignments.create!(title: "assignment 2")
      @module2.add_item({ id: @assignment_2.id, type: "assignment" })
      @module2.prerequisites = "module_#{@module1.id}"
      @module2.save!
      @student = User.create!(name: "student_1")
      @course.enroll_student(@student).accept!
    end

    before do
      user_session(@teacher)
    end

    def validate_access_to_module
      wait_for_ajaximations
      user_session(@teacher)
      get "/courses/#{@course.id}/modules/progressions"
      expect(f(".completed")).to be_displayed
      expect(fln("student_1")).to be_displayed
    end

    def add_requirement(requirement = nil)
      @module1.completion_requirements = requirement
      @module1.save!
      user_session(@student)
      get "/courses/#{@course.id}/modules"
      expect(ff(".locked_icon")[1]).to be_displayed
    end

    it "shows student progress once assignment-view requirement is met", priority: "1" do
      @assignment_1 = @course.assignments.create!(name: "assignment 1", submission_types: ["online_text_entry"], points_possible: 20)
      tag = @module1.add_item({ id: @assignment_1.id, type: "assignment" })
      add_requirement({ tag.id => { type: "must_view" } })
      fln("assignment 1").click
      validate_access_to_module
    end

    it "shows student progress once assignment-submit requirement is met", priority: "1" do
      @assignment_1 = @course.assignments.create!(name: "assignment 1", submission_types: ["online_text_entry"], points_possible: 20)
      tag = @module1.add_item({ id: @assignment_1.id, type: "assignment" })
      add_requirement({ tag.id => { type: "must_submit" } })
      @assignment_1.submit_homework(@student, body: "done!")
      validate_access_to_module
    end

    it "shows student progress once assignment-score atleast requirement is met", priority: "1" do
      @assignment_1 = @course.assignments.create!(name: "assignment 1", submission_types: ["online_text_entry"], points_possible: 20)
      tag = @module1.add_item({ id: @assignment_1.id, type: "assignment" })
      add_requirement({ tag.id => { type: "min_score", min_score: 10 } })
      @assignment_1.submit_homework(@student, body: "done!")
      @assignment_1.grade_student(@student, grade: 15, grader: @teacher)
      validate_access_to_module
    end

    it "shows student progress once quiz-view requirement is met", priority: "1" do
      @quiz_1 = @course.quizzes.create!(title: "some quiz")
      @quiz_1.publish!
      tag = @module1.add_item({ id: @quiz_1.id, type: "quiz" })
      add_requirement({ tag.id => { type: "must_view" } })
      fln("some quiz").click
      validate_access_to_module
    end

    it "shows student progress once quiz-submit requirement is met", priority: "1" do
      @quiz_1 = @course.quizzes.create!(title: "some quiz")
      @quiz_1.publish!
      tag = @module1.add_item({ id: @quiz_1.id, type: "quiz" })
      add_requirement({ tag.id => { type: "must_submit" } })
      fln("some quiz").click
      wait_for_ajaximations
      f(".btn-primary").click
      f(".btn-secondary").click
      validate_access_to_module
    end

    it "shows student progress once quiz-score atleast requirement is met", priority: "1" do
      @quiz_1 = quiz_helper.quiz_create(course: @course)
      tag = @module1.add_item({ id: @quiz_1.id, type: "quiz" })
      add_requirement({ tag.id => { type: "min_score", min_score: 0.5 } })
      fln("Unnamed Quiz").click
      wait_for_ajaximations
      f(".btn-primary").click
      ff(".question_input")[0].click
      f(".btn-primary").click
      validate_access_to_module
    end

    it "shows student progress once discussion-view requirement is met", priority: "1" do
      @discussion_1 = @course.assignments.create!(name: "Discuss!", points_possible: "5", submission_types: "discussion_topic")
      tag = @module1.add_item({ id: @discussion_1.id, type: "assignment" })
      add_requirement({ tag.id => { type: "must_view" } })
      wait_for_ajaximations
      fln("Discuss!").click
      validate_access_to_module
    end

    it "shows student progress once discussion-contribute requirement is met", priority: "1" do
      @discussion_1 = @course.assignments.create!(name: "Discuss!", points_possible: "5", submission_types: "discussion_topic")
      tag = @module1.add_item({ id: @discussion_1.id, type: "assignment" })
      add_requirement({ tag.id => { type: "must_contribute" } })
      wait_for_ajaximations
      fln("Discuss!").click
      wait_for_ajaximations
      f(".discussion-reply-action").click
      type_in_tiny "textarea", "something to submit"
      f('button[type="submit"]').click
      validate_access_to_module
    end

    it "shows student progress once wiki page-view requirement is met", priority: "1" do
      @wiki_page = @course.wiki_pages.create!(title: "Wiki Page")
      tag = @module1.add_item(id: @wiki_page.id, type: "wiki_page")
      add_requirement({ tag.id => { type: "must_view" } })
      wait_for_ajaximations
      fln("Wiki Page").click
      validate_access_to_module
    end

    it "shows student progress once wiki page-contribute requirement is met", priority: "1" do
      @wiki_page = @course.wiki_pages.create(title: "Wiki_page", editing_roles: "public", notify_of_update: true)
      tag = @module1.add_item(id: @wiki_page.id, type: "wiki_page")
      add_requirement({ tag.id => { type: "must_contribute" } })
      get "/courses/#{@course.id}/pages/#{@wiki_page.title}/edit"
      type_in_tiny "textarea", "something to submit"
      f(".btn-primary").click
      validate_access_to_module
    end

    it "shows student progress once External tool-view requirement is met", priority: "1" do
      @tool = @course.context_external_tools.create! name: "WHAT", consumer_key: "what", shared_secret: "what", url: "http://what.example.org"
      tag = @module1.add_item(title: "External_tool", type: "external_tool", id: @tool.id, url: "http://what.example.org/A")
      get "/courses/#{@course.id}/modules/"
      f(".publish-icon.unpublished.publish-icon-publish").click
      wait_for_ajaximations
      add_requirement({ tag.id => { type: "must_view" } })
      wait_for_ajaximations
      fln("External_tool").click
      validate_access_to_module
    end

    it "shows student progress once External URL-view requirement is met", priority: "1" do
      @external_url_tag = @module1.add_item(type: "external_url",
                                            url: "http://example.com/lolcats",
                                            title: "External_URL",
                                            indent: 1)
      @external_url_tag.publish!
      add_requirement({ @external_url_tag.id => { type: "must_view" } })
      wait_for_ajaximations
      fln("External_URL").click
      validate_access_to_module
    end

    it "shows student progress once File-view requirement is met", priority: "1" do
      @file = @course.attachments.create!(display_name: "file", uploaded_data: fixture_file_upload("a_file.txt", "text/plain"))
      @file.context = @course
      @file.save!
      tag = @module1.add_item({ id: @file.id, type: "attachment" })
      add_requirement({ tag.id => { type: "must_view" } })
      wait_for_ajaximations
      fln("file").click
      validate_access_to_module
    end
  end
end
