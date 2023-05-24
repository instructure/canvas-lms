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

module CollaborationsSpecsCommon
  def ensure_plugin(type)
    type = "google_drive" if type == "google_docs"
    PluginSetting.create!(name: type, settings: {})
  end

  def new_collaborations_form(type)
    ensure_plugin(type)
    validate_collaborations
  end

  def be_editable(type, title)
    create_collaboration!(type, title)
    validate_collaborations(%W[/courses/#{@course.id}/collaborations], false)

    new_title = "Edited collaboration"
    move_to_click(".edit_collaboration_link")
    wait_for_ajaximations
    replace_content(fj('input[name="collaboration[title]"]:visible'), new_title)
    expect_new_page_load do
      submit_form(".edit_collaboration")
    end

    expect(f(".collaboration .title").text).to eq new_title
    expect(Collaboration.order("id DESC").last.title).to eq new_title
  end

  def no_edit_if_no_access(type, title)
    create_collaboration!(type, title)
    validate_collaborations(%W[/courses/#{@course.id}/collaborations], false)

    # Negative check
    expect(f("#content")).not_to contain_css(".edit_collaboration_link")
  end

  def be_deletable(type, title)
    create_collaboration!(type, title)
    validate_collaborations(%W[/courses/#{@course.id}/collaborations], false)

    move_to_click(".delete_collaboration_link")

    if type == "google_docs"
      f("#delete_collaboration_dialog .delete_button").click
    else
      driver.switch_to.alert.accept
    end
    wait_for_ajaximations

    expect(f("#no_collaborations_message")).to be_displayed
    expect(Collaboration.order("id DESC").last).to be_deleted
  end

  def display_available_collaborators(type)
    ensure_plugin(type)

    student_in_course(course: @course)
    @student.update_attribute(:name, "Don Draper")

    get "/courses/#{@course.id}/collaborations"

    expect(ffj(".available-users:visible li")).to have_size(2)
  end

  def select_collaborators(type)
    ensure_plugin(type)

    student_in_course(course: @course)
    @student.update_attribute(:name, "Don Draper")

    get "/courses/#{@course.id}/collaborations"
    wait_for_ajaximations
    f(".available-users a[data-id=\"#{@student.id}\"]").click
    expect(ff(".members-list li")).to have_size(1)
    expect(f(".members-list")).to contain_css("a[data-id=\"user_#{@student.id}\"]")
    expect(f(".members-list")).to contain_css("input[value=\"#{@student.id}\"]")
  end

  def select_from_all_course_groups(type, title)
    group_model(context: @course, name: "grup grup")

    create_collaboration!(type, title)
    validate_collaborations(%W[/courses/#{@course.id}/collaborations], false)

    f(".edit_collaboration_link").click
    wait_for_ajaximations
    move_to_click("label[for=groups-filter-btn-#{@collaboration.id}]")
    wait_for_ajaximations

    expect(ffj("ul[aria-label='Available groups']:visible a")).to have_size 1
    f(".available-groups a[data-id=\"#{@group.id}\"]").click
    wait_for_ajaximations
    expect(ff(".members-list li")).to have_size 2
    expect(f(".members-list")).to contain_css("a[data-id=\"group_#{@group.id}\"]")
    expect(f(".members-list")).to contain_css("input[value=\"#{@group.id}\"]")
    expect_new_page_load do
      submit_form(".edit_collaboration")
    end
    @collaboration.reload
    collaborator = @collaboration.collaborators.where(group_id: @group).first
    expect(collaborator).to_not be_blank
  end

  def deselect_collaborators(type)
    ensure_plugin(type)

    student_in_course(course: @course)
    @student.update_attribute(:name, "Don Draper")

    get "/courses/#{@course.id}/collaborations"
    wait_for_ajaximations
    fj(".available-users:visible a").click
    wait_for_ajaximations
    f(".members-list a").click
    expect(f(".members-list")).not_to contain_css("li")
    expect(f(".available-users")).to contain_css("a[data-id=\"#{@student.id}\"]")
  end

  def select_collaborators_and_look_for_start(type)
    ensure_plugin(type)

    collaboration_name = "StreetsOfRage"
    manually_create_collaboration(collaboration_name)

    get "/courses/#{@course.id}/collaborations"
    expect(f(".title")).to include_text(collaboration_name)
  end

  def no_edit_with_no_access
    create_collaboration!("google_docs", "Google Docs")
    validate_collaborations(%W[/courses/#{@course.id}/collaborations], false)

    # Negative check
    expect(f("#content")).not_to contain_css(".edit_collaboration_link")
  end

  def no_delete_with_no_access
    create_collaboration!("google_docs", "Google Docs")
    validate_collaborations(%W[/courses/#{@course.id}/collaborations], false)

    # Negative check
    expect(f("#content")).not_to contain_css(".delete_collaboration_link")
  end

  def not_display_new_form_if_none_exist(type, title)
    create_collaboration!(type, title)
    validate_collaborations(%W[/courses/#{@course.id}/collaborations], false)
  end

  def display_new_form_if_none_exist(type)
    ensure_plugin(type)
    validate_collaborations(%W[/courses/#{@course.id}/collaborations
                               /courses/#{@course.id}/collaborations#add_collaboration],
                            true)
  end

  def hide_new_form_if_exists(type, title)
    create_collaboration!(type, title)
    validate_collaborations(%W[/courses/#{@course.id}/collaborations
                               /courses/#{@course.id}/collaborations#add_collaboration],
                            false)
  end

  def open_form_if_last_was_deleted(type, title)
    create_collaboration!(type, title)
    validate_collaborations("/courses/#{@course.id}/collaborations/", false, true)
    delete_collaboration(@collaboration, type)
    expect_form_to_be_visible
  end

  def not_display_new_form_when_penultimate_collaboration_is_deleted(type, title)
    ensure_plugin(type)

    @collaboration1 = Collaboration.typed_collaboration_instance(title)
    @collaboration1.context = @course
    @collaboration1.attributes = { title: "My Collab 1" }
    @collaboration1.user = @user
    @collaboration1.save!
    @collaboration2 = Collaboration.typed_collaboration_instance(title)
    @collaboration2.context = @course
    @collaboration2.attributes = { title: "My Collab 2" }
    @collaboration2.user = @user
    @collaboration2.save!

    validate_collaborations("/courses/#{@course.id}/collaborations/", false, true)
    delete_collaboration(@collaboration1, type)
    expect_form_not_to_be_visible
    delete_collaboration(@collaboration2, type)
    expect_form_to_be_visible
  end

  def leave_new_form_open_when_last_is_deleted(type, title)
    create_collaboration!(type, title)
    validate_collaborations(%W[/courses/#{@course.id}/collaborations
                               /courses/#{@course.id}/collaborations#add_collaboration],
                            false,
                            true)
    f(".add_collaboration_link").click
    delete_collaboration(@collaboration, type)
    expect_form_to_be_visible
  end
end
