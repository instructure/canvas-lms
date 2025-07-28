# frozen_string_literal: true

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

require_relative "../common"
require_relative "../helpers/blueprint_common"
require_relative "../../apis/api_spec_helper"

shared_context "blueprint lock context" do
  def blueprint_lock_icon_label
    f(".bpc-lock-toggle__label")
  end

  def blueprint_lock_icon_button
    blueprint_lock_icon_label.find_element(:xpath, "../../../parent::button")
  end

  def associated_index_lock_icon
    f("#content-wrapper.ic-Layout-contentWrapper")
  end

  def blueprint_index_assignment_icon
    f("#assignment_#{@assignment.id}.ig-row.ig-published")
  end

  def blueprint_index_discussions_icon
    f(".discussion-content")
  end

  def blueprint_index_pages_icon
    f(".master-content-lock-cell")
  end

  def blueprint_index_quizzes_icon
    f("#summary_quiz_#{@quiz.id}.ig-row")
  end

  def blueprint_index_quizzes_search_bar
    f("input#searchTerm")
  end

  def verify_index_locked
    element = associated_index_lock_icon
    expect(element).to contain_css(@locked_button_css) # if this is present, and item is showing as locked.
  end

  def verify_index_unlocked
    element = associated_index_lock_icon
    expect(element).not_to contain_css(@locked_button_css) # the item is now unlocked.
  end

  def verify_show_page_locked
    element = blueprint_lock_icon_label
    expect(element).to include_text("Locked") # verify item is locked
  end

  def verify_show_page_unlocked
    element = blueprint_lock_icon_label
    expect(element).to include_text("Blueprint") # verify the item is unlocked
  end

  def lock_index_tag
    @tag.update(restrictions: { content: true }) # lock the item. Does not require a migration.
  end

  def unlock_index_tag
    @tag.update(restrictions: { content: false }) # unlock the item.
  end

  def verify_unlocked(element)
    expect(element).not_to contain_css(@unlocked_button_css) # verify that the button is unlocked
  end
end

describe "master courses - locked items" do
  include_context "in-process server selenium tests"
  include_context "blueprint lock context"
  include BlueprintCourseCommon

  before :once do
    @unlocked_button_css = ".lock-icon.btn-unlocked"
    @locked_button_css = ".lock-icon.lock-icon-locked"

    @master = course_factory(active_all: true)
    @master_teacher = @teacher
    @template = MasterCourses::MasterTemplate.set_as_master_course(@master)
    @minion = @template.add_child_course!(course_factory(name: "Minion", active_all: true)).child_course

    # setup some stuff
    @assignment = @master.assignments.create!(title: "Blah", points_possible: 10)
    @ag1 = @master.assignment_groups.create!(name: "Assignment Group 1")
    @assignment2 = @master.assignments.create!(title: "Blah2", points_possible: 10, assignment_group: @ag1)
    @page = @master.wiki_pages.create!(title: "Unicorn")
    @quiz = @master.quizzes.create!(title: "TestQuiz")
    @discussion = @master.discussion_topics.create!(title: "My discussion")

    run_master_course_migration(@master)
    @quiz_copy = @minion.quizzes.last
  end

  context "on the index page," do
    before :once do
      account_admin_user(active_all: true)
    end

    before do
      user_session(@admin)
    end

    context "in the minion course" do
      it "assignments show a lock icon on the index page", priority: "2" do
        @tag = @template.create_content_tag_for!(@assignment)
        lock_index_tag

        get "/courses/#{@minion.id}/assignments"
        verify_index_locked
        unlock_index_tag

        refresh_page
        verify_index_unlocked
      end

      it "pages show a lock icon on the index page", priority: "2" do
        @tag = @template.create_content_tag_for!(@page)
        lock_index_tag

        get "/courses/#{@minion.id}/pages"
        verify_index_locked
        unlock_index_tag

        refresh_page
        verify_index_unlocked
      end

      it "quizzes show a lock icon on the index page", priority: "2" do
        @tag = @template.create_content_tag_for!(@quiz)
        lock_index_tag

        get "/courses/#{@minion.id}/quizzes"
        verify_index_locked
        unlock_index_tag

        refresh_page
        verify_index_unlocked
      end

      it "does not show wiki sidebar for locked quizzes", priority: "2" do
        @tag = @template.create_content_tag_for!(@quiz)
        lock_index_tag

        get "/courses/#{@minion.id}/quizzes/#{@quiz_copy.id}/edit"
        expect(f("#right-side")).not_to contain_css("#editor_tabs")
      end
    end

    context "in the master course" do
      it "assignments show a working lock button on the index page", priority: "2" do
        get "/courses/#{@master.id}/assignments"
        element = blueprint_index_assignment_icon
        escape = f("[data-testid='assignment-search-input']")

        element.find_element(:css, @unlocked_button_css).click
        escape.click # click away from the button due to firefox functionality
        refresh_page # refresh the page to retrieve info from backend

        element = blueprint_index_assignment_icon
        escape = f("[data-testid='assignment-search-input']")

        verify_unlocked(element)
        element.find_element(:css, @locked_button_css).click
        escape.click # click away from the button due to firefox functionality
        refresh_page

        element = blueprint_index_assignment_icon
        expect(element).not_to contain_css(@locked_button_css) # verify that the state has changed.
      end

      it "pages show a working lock button on the index page", priority: "2" do
        get "/courses/#{@master.id}/pages"
        element = blueprint_index_pages_icon
        escape = f(".header-bar-outer-container")

        element.find_element(:css, @unlocked_button_css).click
        escape.click # click away from the button due to firefox functionality
        refresh_page # refresh the page to retrieve info from backend

        element = blueprint_index_pages_icon
        escape = f(".header-bar-outer-container")

        verify_unlocked(element)
        element.find_element(:css, @locked_button_css).click
        escape.click # click away from the button due to firefox functionality
        refresh_page

        element = blueprint_index_pages_icon
        expect(element).not_to contain_css(@locked_button_css) # verify that the state has changed.
      end

      it "quizzes show a working lock button on the index page", priority: "2" do
        get "/courses/#{@master.id}/quizzes"
        element = blueprint_index_quizzes_icon
        escape = blueprint_index_quizzes_search_bar

        element.find_element(:css, @unlocked_button_css).click
        escape.click # click away from the button due to firefox functionality
        refresh_page # refresh the page to retrieve info from backend

        element = blueprint_index_quizzes_icon
        escape = blueprint_index_quizzes_search_bar

        verify_unlocked(element)
        element.find_element(:css, @locked_button_css).click
        escape.click # click away from the button due to firefox functionality
        refresh_page

        element = blueprint_index_quizzes_icon
        expect(element).not_to contain_css(@locked_button_css) # verify that the state has changed.
      end

      it "keeps the assignment that gets locked in its assignments group" do
        @tag = @template.create_content_tag_for!(@assignment2)
        lock_index_tag

        run_master_course_migration(@master)

        get "/courses/#{@minion.id}/assignments"
        assignment_group = AssignmentGroup.where(name: "Assignment Group 1", context: @minion.id).last
        minion_assignment2 = Assignment.where(title: "Blah2", context: @minion.id).last
        expect(minion_assignment2.assignment_group_id).to eq(assignment_group.id)
      end
    end
  end

  context "on the show page," do
    before :once do
      account_admin_user(active_all: true)
    end

    before do
      user_session(@admin)
    end

    it "assignments show a lock icon on the show page", priority: "2" do
      @tag = @template.create_content_tag_for!(@assignment)
      @tag.update(restrictions: { content: true }) # lock the item. Does not require a migration.
      get "/courses/#{@master.id}/assignments/#{@assignment.id}"

      verify_show_page_locked
      blueprint_lock_icon_button.click
      refresh_page

      verify_show_page_unlocked
      blueprint_lock_icon_button.click
      refresh_page

      verify_show_page_locked
    end

    it "discussions show a lock icon on the show page", priority: "2" do
      skip "Will be fixed in VICE-5431"
      @tag = @template.create_content_tag_for!(@discussion)
      @tag.update(restrictions: { content: true }) # lock the item. Does not require a migration.
      get "/courses/#{@master.id}/discussion_topics/#{@discussion.id}"

      verify_show_page_locked
      blueprint_lock_icon_button.click
      refresh_page

      verify_show_page_unlocked
      blueprint_lock_icon_button.click
      refresh_page

      verify_show_page_locked
    end

    it "pages show a lock icon on the show page", priority: "2" do
      @tag = @template.create_content_tag_for!(@page)
      @tag.update(restrictions: { content: true }) # lock the item. Does not require a migration.
      get "/courses/#{@master.id}/pages/#{@page.id}"

      verify_show_page_locked
      blueprint_lock_icon_button.click
      refresh_page

      verify_show_page_unlocked
      blueprint_lock_icon_button.click
      refresh_page

      verify_show_page_locked
    end

    it "quizzes show a lock icon on the show page", priority: "2" do
      @tag = @template.create_content_tag_for!(@quiz)
      @tag.update(restrictions: { content: true }) # lock the item. Does not require a migration.
      get "/courses/#{@master.id}/quizzes/#{@quiz.id}"

      verify_show_page_locked
      blueprint_lock_icon_button.click
      refresh_page

      verify_show_page_unlocked
      blueprint_lock_icon_button.click
      refresh_page

      verify_show_page_locked
    end
  end
end
