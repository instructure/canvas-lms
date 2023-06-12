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
#

require_relative "../api_spec_helper"

describe SisApiController, type: :request do
  def install_post_grades_tool
    context.context_external_tools.create!(
      name: "test post grades tool",
      domain: "http://example.com/lti",
      consumer_key: "key",
      shared_secret: "secret",
      settings: { post_grades: { url: "http://example.com/lti/post_grades" } }
    )
  end

  describe "#sis_assignments" do
    context "for an account" do
      before :once do
        account_model(root_account: Account.default)
        account_admin_user(account: @account, active_all: true)
      end

      # courses
      let_once(:course1) { course_factory(account: @account) } # unpublished
      let_once(:course2) { course_factory(account: @account, active_all: true) }
      let_once(:course3) { course_factory(account: @account, active_all: true) }

      # non-postable assignments
      let_once(:assignment1)  { course1.assignments.create!(post_to_sis: true) } # unpublished course
      let_once(:assignment2)  { course1.assignments.create!(post_to_sis: false) } # unpublished course
      let_once(:assignment3)  { course2.assignments.create!(post_to_sis: false) } # post_to_sis: false
      let_once(:assignment4)  { course3.assignments.create!(post_to_sis: false) } # post_to_sis: false
      let_once(:assignment5)  { course1.assignments.create!(post_to_sis: true).tap(&:unpublish!) } # unpublished
      let_once(:assignment6)  { course2.assignments.create!(post_to_sis: true).tap(&:unpublish!) } # unpublished
      let_once(:assignment7)  { course3.assignments.create!(post_to_sis: true).tap(&:unpublish!) } # unpublished

      # postable assignments
      let_once(:assignment8)  { course2.assignments.create!(post_to_sis: true) }
      let_once(:assignment9)  { course2.assignments.create!(post_to_sis: true) }
      let_once(:assignment10) { course3.assignments.create!(post_to_sis: true) }
      let_once(:assignment11) { course3.assignments.create!(post_to_sis: true) }

      let(:context) { @account }

      before do
        course1.enable_feature!(:post_grades)
        course2.enable_feature!(:post_grades)
        course3.enable_feature!(:post_grades)
        user_session(@user)
      end

      it "requires :bulk_sis_grade_export feature to be enabled or post_grades tool to be installed" do
        get "/api/sis/accounts/#{context.id}/assignments", params: { account_id: context.id }
        expect(response).to have_http_status :bad_request
        expect(json_parse).to include("code" => "not_enabled")
      end

      context "with a post_grades tool installed" do
        before do
          install_post_grades_tool
        end

        it "requires :view_all_grades permission" do
          context.role_overrides.create!(permission: :view_all_grades, enabled: false, role: admin_role)
          get "/api/sis/accounts/#{context.id}/assignments", params: { account_id: context.id }
          assert_unauthorized
        end

        it "returns paginated assignment list" do
          # first page
          get "/api/sis/accounts/#{context.id}/assignments", params: { account_id: context.id, per_page: 2 }
          expect(response).to be_successful
          result_json = json_parse
          expect(result_json.length).to eq(2)
          expect(result_json[0]).to include("id" => assignment8.id)
          expect(result_json[1]).to include("id" => assignment9.id)

          # second page
          get "/api/sis/accounts/#{context.id}/assignments", params: { account_id: context.id, per_page: 2, page: 2 }
          expect(response).to be_successful
          result_json = json_parse
          expect(result_json.length).to eq(2)
          expect(result_json[0]).to include("id" => assignment10.id)
          expect(result_json[1]).to include("id" => assignment11.id)

          # third page
          get "/api/sis/accounts/#{context.id}/assignments", params: { account_id: context.id, per_page: 2, page: 3 }
          expect(json_parse.length).to eq(0)
        end

        it "returns courses starting before starts_before" do
          context.courses.each(&:destroy)
          start_at = 1.week.ago
          course1 = context.courses.create!
          course2 = context.courses.create!(start_at: start_at - 1.day)
          context.courses.create!(start_at: start_at + 1.day)

          term1 = context.root_account.enrollment_terms.create!(start_at: start_at - 1.day)
          term2 = context.root_account.enrollment_terms.create!(start_at: start_at + 1.day)
          course4 = context.courses.create!(enrollment_term: term1)
          context.courses.create!(enrollment_term: term2)

          context.courses.not_deleted.each do |c|
            c.update_attribute(:workflow_state, "available")
            c.assignments.create!(post_to_sis: true)
          end

          get "/api/sis/accounts/#{context.id}/assignments?starts_before=#{start_at.iso8601}", params: { account_id: context.id }
          expect(response).to be_successful

          result = json_parse
          expect(result.pluck("course_id")).to match_array [course1.id, course2.id, course4.id]
        end

        it "returns courses concluding after ends_after" do
          context.courses.each(&:destroy)
          end_at = 1.week.from_now
          course1 = context.courses.create!
          course2 = context.courses.create!(conclude_at: end_at + 1.day)
          context.courses.create!(conclude_at: end_at - 1.day)

          term1 = context.root_account.enrollment_terms.create!(end_at: end_at + 1.day)
          term2 = context.root_account.enrollment_terms.create!(end_at: end_at - 1.day)
          course4 = context.courses.create!(enrollment_term: term1)
          context.courses.create!(enrollment_term: term2)

          context.courses.not_deleted.each do |c|
            c.update_attribute(:workflow_state, "available")
            c.assignments.create!(post_to_sis: true)
          end

          get "/api/sis/accounts/#{context.id}/assignments?ends_after=#{end_at.iso8601}", params: { account_id: context.id }
          expect(response).to be_successful

          result = json_parse
          expect(result.pluck("course_id")).to match_array [course1.id, course2.id, course4.id]
        end

        it "accepts a sis_id as the account id" do
          @account.sis_source_id = "abc"
          @account.save!

          get "/api/sis/accounts/sis_account_id:#{@account.sis_source_id}/assignments"
          expect(response).to be_successful

          result = json_parse
          assignment_ids = result.pluck("id")

          expect(result.size).to eq(4)
          expect(assignment_ids).to include assignment8.id
          expect(assignment_ids).to include assignment9.id
          expect(assignment_ids).to include assignment10.id
          expect(assignment_ids).to include assignment11.id
        end
      end
    end

    context "for an unpublished course with a post_grades tool installed" do
      before :once do
        course_factory
        @course.enable_feature!(:post_grades)
        account_admin_user(account: @course.root_account, active_all: true)
      end

      let(:context) { @course }

      before do
        user_session(@user)
        install_post_grades_tool
      end

      it "requires the course to be published" do
        get "/api/sis/courses/#{@course.id}/assignments", params: { course_id: @course.id }
        expect(response).to have_http_status :bad_request
        expect(json_parse).to include("code" => "unpublished_course")
      end
    end

    context "for a published course" do
      before :once do
        course_factory(active_all: true)
        @course.enable_feature!(:post_grades)
        account_admin_user(account: @course.root_account, active_all: true)
      end

      # non-postable assignments
      let_once(:assignment1) { @course.assignments.create!(post_to_sis: false) } # post_to_sis: false
      let_once(:assignment2) { @course.assignments.create!(post_to_sis: false) } # post_to_sis: false
      let_once(:assignment3) { @course.assignments.create!(post_to_sis: true).tap(&:unpublish!) } # unpublished

      # postable assignments
      let_once(:assignment4) { @course.assignments.create!(post_to_sis: true) }
      let_once(:assignment5) { @course.assignments.create!(post_to_sis: true) }
      let_once(:assignment6) { @course.assignments.create!(post_to_sis: true) }
      let_once(:assignment7) { @course.assignments.create!(post_to_sis: true) }
      let_once(:assignment8) { @course.assignments.create!(post_to_sis: true) }

      let_once(:active_override7) do
        assignment7.assignment_overrides.build.tap do |override|
          override.title = "Active Override"
          override.override_due_at(3.days.from_now)
          override.set_type = "CourseSection"
          override.set_id = assignment7.context.course_sections.first.id
          override.save!
        end
      end
      let_once(:inactive_override8) do
        assignment8.assignment_overrides.build.tap do |override|
          override.title = "Inactive Override"
          override.override_due_at(3.days.from_now)
          override.set_type = "CourseSection"
          override.set_id = assignment8.context.course_sections.first.id
          override.save!
          override.destroy
        end
      end

      let_once(:inactive_section8) do
        @course.course_sections.create!(name: "Inactive Section").tap(&:destroy)
      end

      let(:context) { @course }

      before do
        user_session(@user)
        @course.enable_feature!(:post_grades)
      end

      context "with a post_grades tool installed" do
        before do
          install_post_grades_tool
        end

        it "requires :view_all_grades permission" do
          @course.root_account.role_overrides.create!(permission: :view_all_grades, enabled: false, role: admin_role)
          get "/api/sis/courses/#{@course.id}/assignments", params: { course_id: @course.id }
          assert_unauthorized
        end

        it "returns paginated assignment list" do
          # first page
          get "/api/sis/courses/#{@course.id}/assignments", params: { course_id: @course.id, per_page: 2 }
          expect(response).to be_successful
          result_json = json_parse
          expect(result_json.length).to eq(2)
          expect(result_json[0]).to include("id" => assignment4.id)
          expect(result_json[1]).to include("id" => assignment5.id)

          # second page
          get "/api/sis/courses/#{@course.id}/assignments", params: { course_id: @course.id, per_page: 2, page: 2 }
          expect(response).to be_successful
          result_json = json_parse
          expect(result_json.length).to eq(2)
          expect(result_json[0]).to include("id" => assignment6.id)
          expect(result_json[1]).to include("id" => assignment7.id)

          # third page
          get "/api/sis/courses/#{@course.id}/assignments", params: { course_id: @course.id, per_page: 2, page: 3 }
          expect(response).to be_successful
          result_json = json_parse
          expect(result_json.length).to eq(1)
          expect(result_json[0]).to include("id" => assignment8.id)
        end

        it "returns an assignment with an override" do
          get "/api/sis/courses/#{@course.id}/assignments", params: { course_id: @course.id, per_page: 2, page: 2 }
          result_json = json_parse
          assignment = result_json.detect { |a| a["id"] == assignment7.id }
          override = assignment["sections"].first["override"]
          expect(override).to include("override_title" => active_override7.title)
        end

        it "does not return assignments with inactive overrides" do
          get "/api/sis/courses/#{@course.id}/assignments", params: { course_id: @course.id, per_page: 2, page: 3 }
          result_json = json_parse
          expect(result_json[0]["sections"].first).not_to include("override")
        end

        it "does not return inactive sections" do
          get "/api/sis/courses/#{@course.id}/assignments", params: { course_id: @course.id, per_page: 2, page: 3 }
          result_json = json_parse
          section_ids = result_json[0]["sections"].pluck("id")
          expect(section_ids).not_to include(inactive_section8.id)
        end

        it "accepts a sis_id as the course id" do
          context.sis_source_id = "abc"
          context.save!

          get "/api/sis/courses/sis_course_id:#{context.sis_source_id}/assignments"
          expect(response).to be_successful

          result = json_parse
          assignment_ids = result.pluck("id")

          expect(result.size).to eq(5)
          expect(assignment_ids).to include assignment4.id
          expect(assignment_ids).to include assignment5.id
          expect(assignment_ids).to include assignment6.id
          expect(assignment_ids).to include assignment7.id
          expect(assignment_ids).to include assignment8.id
        end
      end
    end
  end
end
