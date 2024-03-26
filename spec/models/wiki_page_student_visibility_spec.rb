# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

require_relative "student_visibility/student_visibility_common"

describe "WikiPageStudentVisibility" do
  include StudentVisibilityCommon

  def assignment_ids_visible_to_user(user)
    AssignmentStudentVisibility.where(course_id: @course.id, user_id: user.id).pluck(:assignment_id)
  end

  before :once do
    Account.site_admin.enable_feature!(:differentiated_modules)
    Setting.set("differentiated_modules_setting", Account.site_admin.feature_enabled?(:differentiated_modules) ? "true" : "false")
    AssignmentStudentVisibility.reset_table_name

    course_factory(active_all: true)
    @section1 = @course.default_section
    @section2 = @course.course_sections.create!(name: "Section 2")
    @student1 = student_in_course(active_all: true, section: @section1).user
    @student2 = student_in_course(active_all: true, section: @section2).user
    @page1 = WikiPage.create!(context: @course, title: "Page 1")
    @page2 = WikiPage.create!(context: @course, title: "Page 2")
  end

  context "table" do
    let(:visibility_object) { WikiPageStudentVisibility.first }

    it_behaves_like "student visibility models"
  end

  context "wiki page visibility" do
    let(:learning_object1) { @page1 }
    let(:learning_object2) { @page2 }
    let(:learning_object_type) { "wiki_page" }

    it_behaves_like "learning object visiblities"
    it_behaves_like "learning object visiblities with modules"

    it "does not include unpublished wiki pages" do
      @page1.workflow_state = "unpublished"
      @page1.save!
      expect(ids_visible_to_user(@student1, "wiki_page")).to contain_exactly(@page2.id)
    end
  end

  context "wiki page with assignment visibility" do
    before :once do
      @module1 = @course.context_modules.create!(name: "Module 1")
      @module2 = @course.context_modules.create!(name: "Module 2")
      @page1.context_module_tags.create! context_module: @module1, context: @course, tag_type: "context_module"
    end

    it "gives the same visibilities for a wiki page's assignment" do
      page1_assignment = @course.assignments.create!
      page2_assignment = @course.assignments.create!
      @page1.update!(assignment: page1_assignment)
      @page2.update!(assignment: page2_assignment)

      override = @module1.assignment_overrides.create!
      override.assignment_override_students.create!(user: @student1)
      expect(ids_visible_to_user(@student1, "wiki_page")).to contain_exactly(@page1.id, @page2.id)
      expect(ids_visible_to_user(@student2, "wiki_page")).to contain_exactly(@page2.id)

      expect(assignment_ids_visible_to_user(@student1)).to contain_exactly(@page1.assignment.id, @page2.assignment.id)
      expect(assignment_ids_visible_to_user(@student2)).to contain_exactly(@page2.assignment.id)
    end
  end
end
