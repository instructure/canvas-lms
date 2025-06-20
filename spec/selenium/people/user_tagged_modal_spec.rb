# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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
require_relative "pages/course_people_modal"

describe "User Tagged Modal" do
  include_context "in-process server selenium tests"

  before :once do
    course_with_teacher(active_all: true)
    @student = student_in_course(active_all: true, name: "Test Student").user

    Account.default.enable_feature!(:assign_to_differentiation_tags)
    @course.account.settings[:allow_assign_to_differentiation_tags] = { value: true }
    @course.account.save!

    @tags = []
    20.times do |i|
      tag_category = @course.group_categories.create!(name: "Tag #{i + 1}", non_collaborative: true)
      tag = @course.groups.create!(name: "Tag #{i + 1}", group_category: tag_category)
      tag.add_user(@student)
      @tags << { category: tag_category, group: tag }
    end
  end

  context "as a teacher" do
    before do
      user_session(@teacher)
      get "/courses/#{@course.id}/users"
    end

    it "displays all tags in the modal with scrolling" do
      wait_for_ajaximations
      student_row = ff("tr").find { |row| row.text.include?(@student.name) }
      expect(student_row).to be_present
      tag_icon = student_row.find_elements(:css, ".user-tags-icon").first
      expect(tag_icon).to be_present
      tag_icon.click
      wait_for_ajaximations
      modal = f("[data-testid='user-tag-modal']")
      expect(modal).to be_displayed
      expect(modal.text).to include("#{@student.name} is tagged as")
      wait_for_ajaximations

      scrollable_container = f("[data-testid^='user-tags-scrollable-container']")
      expect(scrollable_container).to be_present

      # Verify that all tags are rendered in the DOM
      tag_elements = ff("[data-testid^='user-tag-']:not([data-testid='user-tag-modal'])")
      expect(tag_elements.length).to eq 20

      # Verify the first few tags are visible
      expect(tag_elements[0].displayed?).to be_truthy
      expect(tag_elements[1].displayed?).to be_truthy
      expect(tag_elements[2].displayed?).to be_truthy

      # Simulate scrolling to see tags at the bottom (only if container is scrollable)
      # rubocop:disable Specs/NoExecuteScript
      scroll_height = driver.execute_script("return arguments[0].scrollHeight", scrollable_container)
      client_height = driver.execute_script("return arguments[0].clientHeight", scrollable_container)
      if scroll_height > client_height
        driver.execute_script("arguments[0].scrollTop = arguments[0].scrollHeight", scrollable_container)
        wait_for_ajaximations
      end
      # rubocop:enable Specs/NoExecuteScript

      # Verify the last few tags are now visible after scrolling
      expect(tag_elements[-3].displayed?).to be_truthy
      expect(tag_elements[-2].displayed?).to be_truthy
      expect(tag_elements[-1].displayed?).to be_truthy

      # Test clicking the last tag
      tag_elements[-1].click
      wait_for_ajaximations

      # Warning modal should appear
      warning_modal = f("[role='dialog']:not([data-testid='user-tag-modal'])")
      expect(warning_modal).to be_present
      expect(warning_modal.text).to include("Removing the tag from a student")
    end
  end
end
