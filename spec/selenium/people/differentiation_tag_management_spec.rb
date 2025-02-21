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

describe "Differentiation Tag Management" do
  include_context "in-process server selenium tests"

  before :once do
    course_with_teacher active_user: true, active_course: true, active_enrollment: true, name: "Teacher Example"
    student_in_course(active_all: true, name: "student@test.com")
    ta_in_course(active_all: true)

    Account.default.enable_feature!(:differentiation_tags)

    @single_tag = @course.group_categories.create!(name: "single tag", non_collaborative: true)
    @single_tag_1 = @course.groups.create!(name: "single tag", group_category: @single_tag)

    @multiple_tags = @course.group_categories.create!(name: "Multiple Tags", non_collaborative: true)
    @multiple_tags_1 = @course.groups.create!(name: "tag variant 1", group_category: @multiple_tags)
    @multiple_tags_2 = @course.groups.create!(name: "tag variant 2", group_category: @multiple_tags)
  end

  describe "in the people page" do
    context "with permissions" do
      before do
        user_session @teacher
        get "/courses/#{@course.id}/users"
      end

      context "differentiation tag tray" do
        before do
          fj("button:contains('Manage Tags')").click
          wait_for_ajaximations
        end

        it "opens the tray when the 'Manage Tags' button is clicked" do
          expect(fj("h2:contains('Manage Tags')")).to be_displayed
        end

        it "closes the tray when the close button is clicked and returns focus to the 'Manage Tags' button" do
          expect(fj("h2:contains('Manage Tags')")).to be_displayed
          fj("button:contains('Close Differentiation Tag Tray')").click
          wait_for_ajaximations
          expect(f("body")).not_to contain_jqcss("h2:contains('Manage Tags')")
          check_element_has_focus(fj("button:contains('Manage Tags')"))
        end

        it "displays a search input in the tray" do
          expect(f("input[placeholder='Search for Tag']")).to be_displayed
        end

        it "shows 'No matching tags found' when the search returns no results" do
          search_box = f("input[placeholder='Search for Tag']")
          search_box.send_keys("some random string that does not match anything")
          wait_for_ajaximations

          expect(f("body")).to contain_jqcss("span:contains('No matching tags found.')")
        end

        it "filters the tags by category name" do
          search_box = f("input[placeholder='Search for Tag']")
          search_box.send_keys("single")
          wait_for_ajaximations

          expect(fj("span:contains('single tag')")).to be_displayed
          expect(f("body")).not_to contain_jqcss("span:contains('Multiple Tags')")
        end

        it "filters the tags by tag name" do
          search_box = f("input[placeholder='Search for Tag']")
          search_box.send_keys("variant 2")
          wait_for_ajaximations

          expect(fj("span:contains('Multiple Tags')")).to be_displayed
          expect(f("body")).not_to contain_jqcss("span:contains('single tag')")
        end

        it "opens the create edit modal when + tag is pressed" do
          fj("button:contains('+ Tag')").click
          wait_for_ajaximations

          expect(fj("h2:contains('Create Tag')")).to be_displayed
        end

        it "displays correct modal data when editing single tag" do
          f("button[aria-label='Edit tag set: #{@single_tag.name}']").click
          wait_for_ajaximations

          expect(fj("span:contains('Edit Tag')")).to be_displayed
          expect(fj("span:contains('Tag Name')")).to be_displayed

          expect(f("body")).not_to contain_jqcss("span:contains('Tag Set Name')")

          expect(f("[data-testid='tag-name-input']")).to have_value(@single_tag.name)
        end

        it "displays correct modal data when editing a multiple tag" do
          f("button[aria-label='Edit tag set: #{@multiple_tags.name}']").click
          wait_for_ajaximations

          expect(fj("span:contains('Edit Tag')")).to be_displayed
          expect(fj("span:contains('Tag Set Name')")).to be_displayed

          expect(fj("span:contains('Tag Name')")).to be_displayed
          expect(fj("span:contains('Tag Name (Variant 1)')")).to be_displayed
          expect(fj("span:contains('Tag Name (Variant 2)')")).to be_displayed

          expect(ff("[data-testid='tag-name-input']")[0]).to have_value(@multiple_tags_1.name)
          expect(ff("[data-testid='tag-name-input']")[1]).to have_value(@multiple_tags_2.name)
        end

        it "displays correct tray cards when opening the tray" do
          expect(fj("span:contains('single tag')")).to be_displayed
          expect(fj("span:contains('Multiple Tags')")).to be_displayed
        end

        it "paginates when there are more than 4 differentiation tags" do
          4.times do |i|
            cat = @course.group_categories.create!(name: "Extra Cat #{i}", non_collaborative: true)
            @course.groups.create!(name: "Extra Tag #{i}", group_category: cat)
          end

          refresh_page
          fj("button:contains('Manage Tags')").click
          wait_for_ajaximations

          # Expect the pagination control to appear
          expect(f("body")).to contain_jqcss("[data-testid='differentiation-tag-pagination']")
        end

        it "opens the edit modal when the + tag variant button is pressed" do
          fj("button:contains('+ Add a variant')").click
          wait_for_ajaximations

          expect(fj("span:contains('Edit Tag')")).to be_displayed
        end

        it "shows an empty state if there are no categories" do
          @course.differentiation_tag_categories.destroy_all
          refresh_page
          wait_for_ajaximations
          fj("button:contains('Manage Tags')").click

          expect(fj("h3:contains('Differentiation Tags')")).to be_displayed
          expect(fj("button:contains('Get Started')")).to be_displayed
        end
      end

      context "user differentiation tag manager" do
        it "shows the number of selected users in the header" do
          expect(f("input[type='checkbox'][aria-label='Select #{@student.name}']").attribute("checked")).to be_falsey
          f("input[type='checkbox'][aria-label='Select #{@student.name}']").click
          expect(f("input[type='checkbox'][aria-label='Select #{@student.name}']").attribute("checked")).to be_truthy

          expect(f("[data-testid='user-diff-tag-manager-user-count']")).to include_text("1 Selected")
        end

        it "displays the 'Tag As' menu button" do
          expect(f("button[data-testid='user-diff-tag-manager-tag-as-button']")).to be_displayed
        end

        it "opens the 'Tag As' menu and shows categories when clicked" do
          f("button[data-testid='user-diff-tag-manager-tag-as-button']").click
          wait_for_ajaximations

          expect(fj("span:contains('#{@single_tag_1.name}')")).to be_displayed
          expect(fj("span:contains('#{@multiple_tags_1.name}')")).to be_displayed
          expect(fj("span:contains('#{@multiple_tags_2.name}')")).to be_displayed
        end
      end
    end

    context "without permissions" do
      it "does not display the 'Manage Tags' button when user does not have permissions" do
        user_session @student
        get "/courses/#{@course.id}/users"
        expect(f("body")).not_to contain_jqcss("button:contains('Manage Tags')")
      end

      it "does not display 'Manage Tags' if the feature flag is off" do
        Account.default.disable_feature!(:differentiation_tags)

        user_session @teacher
        get "/courses/#{@course.id}/users"
        expect(f("body")).not_to contain_jqcss("button:contains('Manage Tags')")
      end

      it "does not show selection checkboxes or 'Tag As' for TAs by default" do
        user_session @ta
        get "/courses/#{@course.id}/users"

        expect(f("body")).not_to contain_jqcss("input[type='checkbox'][aria-label^='Select']")
        expect(f("body")).not_to contain_jqcss("button[data-testid='user-diff-tag-manager-tag-as-button']")
      end
    end
  end
end
