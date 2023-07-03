# frozen_string_literal: true

#
# Copyright (C) 2017 Instructure, Inc.
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

require_relative "graphql_spec_helper"

describe "legacyNode" do
  before(:once) do
    course_with_student(active_all: true)
    @teacher = @course.enroll_user(User.create!, "TeacherEnrollment", enrollment_state: "active").user
  end

  def run_query(query, user)
    CanvasSchema.execute(query, context: { current_user: user })
  end

  context "OutcomeCalculationMethod" do
    before(:once) do
      @calc_method = outcome_calculation_method_model(@course)

      @query = <<~GQL
        query {
          outcomeCalculationMethod: legacyNode(type: OutcomeCalculationMethod, _id: "#{@calc_method.id}") {
            ... on OutcomeCalculationMethod {
              _id
            }
          }
        }
      GQL
    end

    it "works" do
      expect(
        run_query(@query, @teacher)["data"]["outcomeCalculationMethod"]["_id"]
      ).to eq @calc_method.id.to_s
    end

    it "requires read permission on the course" do
      original_student = @student
      student_in_course(course: course_factory)
      @other_class_student = @student
      @student = original_student
      expect(
        run_query(@query, @other_class_student)["data"]["outcomeCalculationMethod"]
      ).to be_nil
    end
  end

  context "OutcomeProficiency" do
    before(:once) do
      @proficiency = outcome_proficiency_model(@course.account)

      @query = <<~GQL
        query {
          outcomeProficiency: legacyNode(type: OutcomeProficiency, _id: "#{@proficiency.id}") {
            ... on OutcomeProficiency {
              _id
            }
          }
        }
      GQL
    end

    it "works" do
      @admin = account_admin_user(account: @course.account)
      expect(
        run_query(@query, @admin)["data"]["outcomeProficiency"]["_id"]
      ).to eq @proficiency.id.to_s
    end

    it "requires read permission on the account" do
      original_account = @account
      @other_account = account_model
      @admin = account_admin_user(account: @other_account)
      @account = original_account
      expect(
        run_query(@query, @admin)["data"]["outcomeProficiency"]
      ).to be_nil
    end
  end

  context "enrollments" do
    before(:once) do
      @enrollment = @student.enrollments.first

      @query = <<~GQL
        query {
          enrollment: legacyNode(type: Enrollment, _id: "#{@enrollment.id}") {
            ... on Enrollment {
              _id
            }
          }
        }
      GQL
    end

    it "works" do
      expect(
        run_query(@query, @student)["data"]["enrollment"]["_id"]
      ).to eq @enrollment.id.to_s
    end

    it "requires read_roster permission on the course" do
      original_student = @student
      student_in_course(course: course_factory)
      @other_class_student = @student
      @student = original_student
      expect(
        run_query(@query, @other_class_student)["data"]["enrollment"]
      ).to be_nil
    end
  end

  context "modules" do
    before(:once) do
      @module = @course.context_modules.create! name: "asdf"
      @query = <<~GQL
        query {
          module: legacyNode(type: Module, _id: "#{@module.id}") {
            ... on Module {
              _id
            }
          }
        }
      GQL
    end

    it "works" do
      expect(
        run_query(@query, @student)["data"]["module"]["_id"]
      ).to eq @module.id.to_s
    end

    it "requires read permission" do
      @module.unpublish
      expect(
        run_query(@query, @student)["data"]["module"]
      ).to be_nil
    end
  end

  context "page" do
    before(:once) do
      @course.create_wiki! has_no_front_page: false, title: "asdf"
      @page = @course.wiki.front_page
      @page.save!
      @query = <<~GQL
        query {
          page: legacyNode(type: Page, _id: "#{@page.id}") {
            ... on Page {
              _id
            }
          }
        }
      GQL
    end

    it "works" do
      expect(
        run_query(@query, @student)["data"]["page"]["_id"]
      ).to eq @page.id.to_s
    end

    it "requires read permission" do
      @page.unpublish
      expect(
        run_query(@query, @student)["data"]["page"]
      ).to be_nil
    end
  end

  context "PostPolicy" do
    before(:once) do
      @course.default_post_policy.update!(post_manually: true)
      @query = <<~GQL
        query {
          postPolicy: legacyNode(type: PostPolicy, _id: "#{@course.default_post_policy.id}") {
            ... on PostPolicy {
              _id
            }
          }
        }
      GQL
    end

    it "returns a PostPolicy for users with manage_grades permission" do
      expect(
        run_query(@query, @teacher)["data"]["postPolicy"]["_id"].to_i
      ).to eql @course.default_post_policy.id
    end

    it "returns null for users without manage_grades permission" do
      expect(
        run_query(@query, @student)["data"]["postPolicy"]
      ).to be_nil
    end
  end
end
