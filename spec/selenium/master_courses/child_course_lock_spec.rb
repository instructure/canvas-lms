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


require_relative '../common'
require_relative '../helpers/blueprint_common'
require_relative '../../apis/api_spec_helper'

describe "master courses - locked items" do
  include_context "in-process server selenium tests"
  include BlueprintCourseCommon

  before :once do

    @unlocked_button_css = ".lock-icon.btn-unlocked"
    @locked_button_css = ".lock-icon.lock-icon-locked"

    Account.default.enable_feature!(:master_courses)
    @master = course_factory(active_all: true)
    @master_teacher = @teacher
    @template = MasterCourses::MasterTemplate.set_as_master_course(@master)
    @minion = @template.add_child_course!(course_factory(name: "Minion", active_all: true)).child_course

    # setup some stuff
    @assignment = @master.assignments.create!(title: 'Blah', points_possible: 10)
    @page = @master.wiki.wiki_pages.create!(title: 'Unicorn')
    @quiz = @master.quizzes.create!(title: 'TestQuiz')
    @discussion = @master.discussion_topics.create!(title: 'My discussion')

    run_master_course_migration(@master)
  end

  context "on the index page," do

    before :once do
      account_admin_user(active_all: true)
    end

    before :each do
      user_session(@admin)
    end

    context "in the minion course" do

      it "assignments show a lock icon on the index page", priority: "2", test_id: 3137707 do
        verify_associated_index_lock(@assignment, "assignments")
      end

      it "discussions show a lock icon on the index page", priority: "2", test_id: 3137708 do
        verify_associated_index_lock(@discussion, "discussion_topics")
      end

      it "pages show a lock icon on the index page", priority: "2", test_id: 3137709 do
        verify_associated_index_lock(@page, "pages")
      end

      it "quizzes show a lock icon on the index page", priority: "2", test_id: 3137710 do
        verify_associated_index_lock(@quiz, "quizzes")
      end
    end

    context "in the master course" do

      it "assignments show a working lock button on the index page", priority: "2", test_id: 3137707 do
        get "/courses/#{@master.id}/assignments"
        element = f("#assignment_#{@assignment.id}.ig-row.ig-published")
        escape = f('input#search_term.ic-Input')

        verify_blueprint_index_lock(element, escape)
      end

      it "discussions show a working lock button on the index page", priority: "2", test_id: 3137708 do
        get "/courses/#{@master.id}/discussion_topics"
        element = f('.discussion-content')
        escape = f('input#searchTerm')

        verify_blueprint_index_lock(element, escape)
      end

      it "pages show a working lock button on the index page", priority: "2", test_id: 3137709 do
        get "/courses/#{@master.id}/pages"
        element = f('.master-content-lock-cell')
        escape = f('.header-bar-outer-container')

        verify_blueprint_index_lock(element, escape)
      end

      it "quizzes show a working lock button on the index page", priority: "2", test_id: 3137710 do
        get "/courses/#{@master.id}/quizzes"
        element = f("#summary_quiz_#{@quiz.id}.ig-row")
        escape = f('input#searchTerm')

        verify_blueprint_index_lock(element, escape)
      end
    end
  end

  context "on the show page," do

    before :once do
      account_admin_user(active_all: true)
    end

    before :each do
      user_session(@admin)
    end

    it "assignments show a lock icon on the show page", priority: "2", test_id: 3109490 do
      verify_show_page_lock(@assignment, "assignments")
    end

    it "discussions show a lock icon on the show page", priority: "2", test_id: 3127582 do
      verify_show_page_lock(@discussion, "discussion_topics")
    end

    it "pages show a lock icon on the show page", priority: "2", test_id: 3127583 do
      verify_show_page_lock(@page, "pages")
    end

    it "quizzes show a lock icon on the show page", priority: "2", test_id: 3127584 do
      verify_show_page_lock(@quiz, "quizzes")
    end
  end

  private

  # item is the specific item to lock, unlock.
  # navigation_string is the string to navigate to
  def verify_associated_index_lock(item, navigation_string)
    @tag = @template.create_content_tag_for!(item)
    @tag.update(restrictions: {content: true}) # lock the item. Does not require a migration.
    get "/courses/#{@minion.id}/" + navigation_string
    element = f('#content-wrapper.ic-Layout-contentWrapper')

    expect(element).to contain_css(@locked_button_css) # if this is present, and item is showing as locked.
    @tag.update(restrictions: {content: false}) # unlock the item.

    refresh_page
    expect(element).not_to contain_css(@locked_button_css) # the item is now unlocked.
  end

  # verifies that the lock on the show page changes properly
  def verify_show_page_lock(item, navigation_string)
    @tag = @template.create_content_tag_for!(item)
    @tag.update(restrictions: {content: true}) # lock the item. Does not require a migration.

    get "/courses/#{@master.id}/" + navigation_string + "/#{item.id}"
    element = f('.bpc-lock-toggle__label')

    expect(element).to include_text("Locked") # verify item is locked.
    element.click

    refresh_page
    expect(element).to include_text("Blueprint") # verify the item is unlocked
    element.click # lock the item

    refresh_page
    expect(element).to include_text("Locked") # verify item is locked
  end

  # This function verifies that the state of the lock has changed, and then changes the lock state.
  def verify_unlocked(element)
    expect(element).not_to contain_css(@unlocked_button_css) # verify that the button is unlocked
  end

  # verifies the lock functionality of the blueprint (master) course
  def verify_blueprint_index_lock(element, escape)
    element.find_element(:css, @unlocked_button_css).click
    escape.click # click away from the button due to firefox functionality
    refresh_page # refresh the page to retrieve info from backend

    verify_unlocked(element)
    element.find_element(:css, @locked_button_css).click
    escape.click # click away from the button due to firefox functionality
    refresh_page

    expect(element).not_to contain_css(@locked_button_css) # verify that the state has changed.
  end
end
