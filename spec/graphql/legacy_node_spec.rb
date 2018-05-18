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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe "legacyNode" do
  before(:once) do
    course_with_student(active_all: true)
  end

  def run_query(query, user)
    CanvasSchema.execute(query, context: {current_user: user})
  end

  context "courses" do
    before(:once) do
      @query = <<-GQL
      query {
        course: legacyNode(type: Course, _id: "#{@course.id}") {
          ... on Course {
            _id,
            name
          }
        }
      }
      GQL
    end

    it "works" do
      expect(
        run_query(@query, @student)["data"]["course"]["_id"]
      ).to eq @course.id.to_s
    end

    it "needs read permission" do
      @course1, @student1 = @course, @student
      course_with_student
      @course2, @student2 = @course, @student

      expect(run_query(@query, @student2)["data"]["course"]).to be_nil
    end
  end

  context "assignments" do
    before(:once) do
      @assignment = @course.assignments.create! name: "Some Assignment"
      @query = <<-GQL
      query {
        assignment: legacyNode(type: Assignment, _id: "#{@assignment.id}") {
          ... on Assignment {
            _id
            name
          }
        }
      }
      GQL
    end

    it "works" do
      expect(
        run_query(@query, @student)["data"]["assignment"]["_id"]
      ).to eq @assignment.id.to_s
    end

    it "needs read permission" do
      @assignment.unpublish
      expect(run_query(@query, @student)["data"]["assignment"]).to be_nil
    end
  end

  context "sections" do
    before(:once) do
      @section = @course.course_sections.create! name: "Section 1"
      @query = <<-GQL
      query {
        section: legacyNode(type: Section, _id: "#{@section.id}") {
          ... on Section {
            _id
          }
        }
      }
      GQL
    end

    it "works" do
      @course.enroll_student(@student,
                             enrollment_state: 'active',
                             section: @section,
                             allow_multiple_enrollments: true)
      expect(
        run_query(@query, @student)["data"]["section"]["_id"]
      ).to eq @section.id.to_s
    end

    it "requires read permission" do
      @student.enrollments.update_all limit_privileges_to_course_section: true
      expect(
        run_query(@query, @student)["data"]["section"]
      ).to be_nil
    end
  end

  context "users" do
    before(:once) do
      @query = <<-GQL
      query {
        user: legacyNode(type: User, _id: "#{@student.id}") {
          ... on User {
            _id
          }
        }
      }
      GQL
    end

    it "works" do
      expect(
        run_query(@query, @student)["data"]["user"]["_id"]
      ).to eq @student.id.to_s
    end

    it "requires read_full_profile permission" do
      orig_student = @student
      student_in_course
      expect(run_query(@query, @student)["data"]["user"]).to be_nil
    end
  end

  context "enrollments" do
    before(:once) do
      @enrollment = @student.enrollments.first

      @query = <<-GQL
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
end
