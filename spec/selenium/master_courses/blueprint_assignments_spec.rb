# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

require_relative "../helpers/blueprint_common"

shared_context "blueprint courses assignment context" do
  def assignment_options
    f(".assignment")
  end

  def assignment_header
    f("#edit_assignment_header")
  end

  let(:delete_assignment) { "a.delete_assignment" }
end

describe "blueprint courses assignments" do
  include_context "in-process server selenium tests"
  include_context "blueprint courses files context"
  include_context "blueprint courses assignment context"
  include BlueprintCourseCommon

  context "as a blueprint teacher" do
    before :once do
      @master = course_factory(active_all: true)
      @master_teacher = @teacher
      @template = MasterCourses::MasterTemplate.set_as_master_course(@master)
      @minion = @template.add_child_course!(course_factory(name: "Minion", active_all: true)).child_course
      @minion.enroll_teacher(@master_teacher).accept!

      # sets up the assignment that gets blueprinted
      @original_assmt = @master.assignments.create! title: "Blah", points_possible: 10, due_at: 5.days.from_now
      @original_assmt.description = "this is the original content"
      run_master_course_migration(@master)
      @copy_assmt = @minion.assignments.last
    end

    before do
      user_session(@master_teacher)
    end

    it "can lock down associated course's assignment fields", priority: "1" do
      change_blueprint_settings(@master, points: true, due_dates: true, availability_dates: true)
      get "/courses/#{@master.id}/assignments/#{@original_assmt.id}"
      f(".bpc-lock-toggle button").click
      expect(f(".bpc-lock-toggle__label")).to include_text("Locked")
      run_master_course_migration(@master)
      get "/courses/#{@minion.id}/assignments/#{@copy_assmt.id}/edit"
      expect(f("#edit_assignment_form")).to contain_css(".tox-tinymce .tox-editor-container")
      expect(f(".bpc-lock-toggle__label")).to include_text("Locked")
      expect(f("#assignment_points_possible")).to have_attribute("readonly", "true")
      expect(f("#due_at")).to have_attribute("readonly", "true")
      expect(f("#unlock_at")).to have_attribute("readonly", "true")
      expect(f("#lock_at")).to have_attribute("readonly", "true")
    end
  end

  context "in the associated course" do
    before :once do
      due_date = format_date_for_view(1.month.ago)
      @copy_from = course_factory(active_all: true)
      @template = MasterCourses::MasterTemplate.set_as_master_course(@copy_from)
      @original_assmt = @copy_from.assignments.create!(
        title: "blah", description: "bloo", points_possible: 27, due_at: due_date
      )
      @tag = @template.create_content_tag_for!(@original_assmt)

      course_with_teacher(active_all: true)
      @copy_to = @course
      @template.add_child_course!(@copy_to)
      # just create a copy directly instead of doing a real migration
      @assmt_copy = @copy_to.assignments.new(
        title: "blah", description: "bloo", points_possible: 27, due_at: due_date
      )
      @assmt_copy.migration_id = @tag.migration_id
      @assmt_copy.save!
    end

    before do
      user_session(@teacher)
    end

    it "contains the delete cog-menu option on the index when unlocked" do
      get "/courses/#{@copy_to.id}/assignments"

      expect(f("#assignment_#{@assmt_copy.id}")).to contain_css(".icon-blueprint")

      options_button.click
      expect(assignment_options).to contain_css(delete_assignment)
    end

    it "does not contain the delete cog-menu option on the index when locked" do
      @tag.update(restrictions: { content: true })

      get "/courses/#{@copy_to.id}/assignments"

      expect(f("#assignment_#{@assmt_copy.id}")).to contain_css(".icon-blueprint-lock")

      options_button.click
      expect(assignment_options).not_to contain_css(delete_assignment)
    end

    it "shows the delete cog-menu option on the index when not locked" do
      get "/courses/#{@copy_to.id}/assignments"

      expect(f("#assignment_#{@assmt_copy.id}")).to contain_css(".icon-blueprint")

      options_button.click
      expect(assignment_options).not_to contain_css("a.delete_assignment.disabled")
      expect(assignment_options).to contain_css(delete_assignment)
    end

    it "does not allow the delete options on the edit page when locked" do
      @tag.update(restrictions: { content: true })

      get "/courses/#{@copy_to.id}/assignments/#{@assmt_copy.id}/edit"

      expect(assignment_header).not_to contain_css(".assignment-delete-container")
    end

    it "shows the delete cog-menu options on the edit when not locked" do
      get "/courses/#{@copy_to.id}/assignments/#{@assmt_copy.id}/edit"

      options_button.click
      expect(assignment_header).not_to contain_css("a.delete_assignment_link.disabled")
      expect(assignment_header).to contain_css("a.delete_assignment_link")
    end

    it "does not allow editing of restricted items" do
      # restrict everything
      @tag.update(restrictions: { content: true, points: true, due_dates: true, availability_dates: true })

      get "/courses/#{@copy_to.id}/assignments/#{@assmt_copy.id}/edit"

      expect(f("#assignment_name").tag_name).to eq "h1"
      expect(f("#assignment_description").tag_name).to eq "div"
      expect(f("#assignment_points_possible").attribute("readonly")).to eq "true"
      expect(f("#due_at").attribute("readonly")).to eq "true"
      expect(f("#unlock_at").attribute("readonly")).to eq "true"
      expect(f("#lock_at").attribute("readonly")).to eq "true"
      expect(f("#assignment_grading_type")).to contain_css('option[value="points"]')
      expect(f("#assignment_grading_type")).not_to contain_css('option[value="not_graded"]')
    end

    it "does not allow making a non-graded assignment graded when points are locked" do
      not_graded_assignment = @copy_from.assignments.create!(
        title: "eh", description: "meh", submission_types: "not_graded", grading_type: "not_graded"
      )
      nga_tag = @template.create_content_tag_for!(not_graded_assignment)

      # fake the copy instead of doing a full migration
      nga_copy = @copy_to.assignments.create(
        title: "eh", description: "meh", submission_types: "not_graded", grading_type: "not_graded"
      )
      nga_copy.migration_id = nga_tag.migration_id
      nga_copy.save!

      nga_tag.update(restrictions: { content: true, points: true, due_dates: true, availability_dates: true })

      get "/courses/#{@copy_to.id}/assignments/#{nga_copy.id}/edit"

      node = f "#assignment_grading_type"
      expect(node.tag_name).to eq "input"
      expect(node.attribute("readonly")).to eq "true"
      expect(f('input[name="grading_type"][type="hidden"]').attribute("value")).to eq "not_graded"
    end

    it "does not allow popup editing of restricted items" do
      # restrict everything
      @tag.update(restrictions: { content: true, points: true, due_dates: true, availability_dates: true })

      get "/courses/#{@copy_to.id}/assignments"

      hover_and_click(".edit_assignment")
      expect(f(".ui-dialog-titlebar .ui-dialog-title").text).to eq "Edit Assignment"
      expect(f("#assign_#{@assmt_copy.id}_assignment_name").tag_name).to eq "h3"
      expect(f("#assign_#{@assmt_copy.id}_assignment_due_at").attribute("readonly")).to eq "true"
      expect(f("#assign_#{@assmt_copy.id}_assignment_points").attribute("readonly")).to eq "true"
    end
  end

  context "in the blueprint course" do
    before :once do
      @course = course_factory(active_all: true)
      @template = MasterCourses::MasterTemplate.set_as_master_course(@course)
      @assignment = @course.assignments.create!(title: "blah", description: "bloo")
      @tag = @template.create_content_tag_for!(@assignment)
    end

    before do
      user_session(@teacher)
    end

    it "shows unlocked button on index page for unlocked assignment" do
      get "/courses/#{@course.id}/assignments"
      expect(f('[data-view="lock-icon"] i.icon-blueprint')).to be_displayed
    end

    it "shows locked button on index page for locked assignment" do
      # restrict something
      @tag.update(restrictions: { content: true })
      get "/courses/#{@course.id}/assignments"
      expect(f('[data-view="lock-icon"] i.icon-blueprint-lock')).to be_displayed
    end
  end
end
