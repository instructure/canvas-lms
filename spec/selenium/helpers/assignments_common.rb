# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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
require_relative "groups_common"

module AssignmentsCommon
  include GroupsCommon

  def clear_input_field(input_el)
    input_el.click
    driver.action
          .key_down(:control)
          .send_keys("a")
          .send_keys(:delete)
          .key_up(:control)
          .perform
  end

  def build_assignment_with_type(type, opts = {})
    if opts[:assignment_group_id]
      assignment_group_id = opts[:assignment_group_id]
    else
      assignment_group = @course.assignment_groups.first!
      assignment_group_id = assignment_group.id
    end

    f("#assignment_group_#{assignment_group_id} .add_assignment").click
    click_option(f("[data-testid='assignment-type-select']"), type)

    if opts[:name]
      name_input = f("[data-testid='assignment-name-input']")
      clear_input_field(name_input)
      name_input.send_keys opts[:name]
    end
    if opts[:points]
      points_input = f("[data-testid='points-input']")
      clear_input_field(points_input)
      f("[data-testid='points-input']").send_keys opts[:points]
    end
    if opts[:due_at]
      date_input = f("#Selectable___1")
      clear_input_field(date_input)
      date_input.send_keys opts[:due_at]
      driver.action.send_keys(:enter).perform

      if opts[:due_time]
        time_input = f("#Select___1")
        clear_input_field(time_input)
        time_input.send_keys opts[:due_time]
        driver.action.send_keys(:enter).perform
      end
    end
    if opts[:submit]
      f("[data-testid='save-button']").click
      wait_for_ajaximations
    end
    if opts[:more_options]
      f("[data-testid='more-options-button']").click
      wait_for_ajaximations
    end
  end

  def edit_assignment(assignment_id, opts = {})
    f("#assignment_#{assignment_id} .al-trigger").click
    f("#assignment_#{assignment_id} .edit_assignment").click

    if opts[:name]
      name_input = f("[data-testid='assignment-name-input']")
      clear_input_field(name_input)
      name_input.send_keys opts[:name]
    end
    if opts[:points]
      points_input = f("[data-testid='points-input']")
      clear_input_field(points_input)
      f("[data-testid='points-input']").send_keys opts[:points]
    end
    if opts[:due_at]
      date_input = f("#Selectable___1")
      clear_input_field(date_input)
      date_input.send_keys opts[:due_at]
      driver.action.send_keys(:enter).perform

      if opts[:due_time]
        time_input = f("#Select___1")
        clear_input_field(time_input)
        time_input.send_keys opts[:due_time]
        driver.action.send_keys(:enter).perform
      end
    end
    if opts[:submit]
      f("[data-testid='save-button']").click
      wait_for_ajaximations
    end
    if opts[:more_options]
      f("[data-testid='more-options-button']").click
      wait_for_ajaximations
    end
  end

  def edit_assignment_group(assignment_group_id)
    f("#assignment_group_#{assignment_group_id} .al-trigger").click
    f("#assignment_group_#{assignment_group_id} .edit_group").click
    wait_for_ajaximations
  end

  def delete_assignment_group(assignment_group_id, opts = {})
    f("#assignment_group_#{assignment_group_id} .al-trigger").click
    f("#assignment_group_#{assignment_group_id} .delete_group").click
    unless opts[:no_accept]
      accept_alert
      wait_for_ajaximations
    end
  end

  def submit_assignment_form
    wait_for_new_page_load { f("#edit_assignment_form .btn-primary[type=submit]").click }
  end

  def stub_freezer_plugin(frozen_atts = nil)
    frozen_atts ||= {
      "assignment_group_id" => "true"
    }
    allow(PluginSetting).to receive(:settings_for_plugin).and_return(frozen_atts)
  end

  def frozen_assignment(group)
    group ||= @course.assignment_groups.first
    assign = @course.assignments.create!(
      name: "frozen",
      due_at: Time.zone.now.utc + 2.days,
      assignment_group: group,
      freeze_on_copy: true
    )
    assign.copied = true
    assign.save!
    assign
  end

  def run_assignment_edit(assignment)
    get "/courses/#{@course.id}/assignments/#{assignment.id}/edit"

    yield

    submit_assignment_form
  end

  def manually_create_assignment(assignment_title = "new assignment")
    # directly navigate via url
    get "/courses/#{@course.id}/assignments/new"
    replace_content(f("#assignment_name"), assignment_title)
  end

  def click_away_accept_alert
    f("#section-tabs .home").click
    driver.switch_to.alert.accept
  end

  def setup_sections_and_overrides_all_future
    # All in the future by default
    @unlock_at = Time.zone.now.utc + 6.days
    @due_at    = Time.zone.now.utc + 10.days
    @lock_at   = Time.zone.now.utc + 11.days

    @assignment.due_at    = @due_at
    @assignment.unlock_at = @unlock_at
    @assignment.lock_at   = @lock_at
    @assignment.save!
    # 2 course sections, student in second section.
    @section1 = @course.course_sections.create!(name: "Section A")
    @section2 = @course.course_sections.create!(name: "Section B")
    @course.student_enrollments.each do |enrollment|
      Score.where(enrollment_id: enrollment).each(&:destroy_permanently!)
      enrollment.destroy_permanently! # get rid of existing student enrollments, mess up section enrollment
    end
    # Overridden lock dates for 2nd section - different dates, but still in future
    @override = assignment_override_model(
      assignment: @assignment,
      set: @section2,
      lock_at: @lock_at + 12.days,
      unlock_at: Time.zone.now.utc + 3.days
    )
  end

  def create_assignment_for_group(submission_type, grade_group_students_individually = false)
    group_test_setup(2, 1, 2)
    add_user_to_group(@students.first, @testgroup[0])
    @assignment = @course.assignments.create!(
      title: "assignment 1",
      name: "assignment 1",
      due_at: Time.zone.now.utc + 2.days,
      points_possible: 50,
      submission_types: submission_type,
      group_category: @group_category[0],
      grade_group_students_individually:
    )
  end

  def create_assignment_with_group_category_preparation
    create_assignment_preparation
    select_assignment_group_category(-2)
  end

  def create_assignment_preparation
    get "/courses/#{@course.id}/assignments/new"
    f("#assignment_name").send_keys("my title")
    type_in_tiny("textarea[name=description]", "text")
    f("#assignment_text_entry").click
  end

  def select_assignment_group_category(id)
    f("#has_group_category").click
    options = ff("#assignment_group_category_id option")
    option_element = id.blank? ? options.first : options[id]
    option_element.click
  end

  def create_file_list
    {
      name: "/",
      folders: [
        {
          name: "TestFolder",
          files: [
            {
              name: "nested.mydoc"
            }
          ]
        }
      ],
      files: [
        {
          name: "test.mydoc"
        }
      ]
    }
  end

  def create_post_grades_tool(opts = {})
    @course.context_external_tools.create!(
      name: opts[:name] || "test tool",
      domain: "example.com",
      url: "http://example.com/lti",
      consumer_key: "key",
      shared_secret: "secret",
      settings: {
        post_grades: {
          url: "http://example.com/lti/post_grades"
        }
      }
    )
  end

  def click_cog_to_edit
    ff(".al-trigger")[2].click
    wait_for_ajaximations
    f(".edit_assignment").click
    wait_for_ajaximations
  end

  def create_assignment_with_type(type, title = "My Title")
    @assignment = @course.assignments.create!(title:, grading_type: type, points_possible: 20)
    @assignment
  end
end
