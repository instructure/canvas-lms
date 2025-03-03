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

      it "renders the checkbox header" do
        expect(fj("span:contains('Select User')")).to be_truthy
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

        it "deletes a tag category when the delete button is pressed" do
          ffj("button:contains('Delete')")[0].click
          wait_for_ajaximations
          fj("button:contains('Confirm')").click
          wait_for_ajaximations

          expect(f("body")).not_to contain_jqcss("span:contains('single tag')")
          expect(@course.differentiation_tag_categories.count).to eq 1
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

        it "shows the create tag modal" do
          f("button[data-testid='user-diff-tag-manager-tag-as-button']").click
          wait_for_ajaximations
          force_click("span:contains('New Tag')")

          expect(fj("h2:contains('Create Tag')")).to be_displayed
        end

        it "Adds a single tag to the selected user" do
          f("input[type='checkbox'][aria-label='Select #{@student.name}']").click
          expect(f("input[type='checkbox'][aria-label='Select #{@student.name}']").attribute("checked")).to be_truthy
          f("button[data-testid='user-diff-tag-manager-tag-as-button']").click
          wait_for_ajaximations

          force_click("span:contains('#{@single_tag_1.name}')")
          wait_for_ajaximations

          expect(@student.current_differentiation_tag_memberships.pluck(:group_id)).to include @single_tag_1.id
        end

        it "Adds a multiple tag variant to the selected user" do
          f("input[type='checkbox'][aria-label='Select #{@student.name}']").click
          expect(f("input[type='checkbox'][aria-label='Select #{@student.name}']").attribute("checked")).to be_truthy
          f("button[data-testid='user-diff-tag-manager-tag-as-button']").click
          wait_for_ajaximations

          force_click("span:contains('#{@multiple_tags_1.name}')")
          wait_for_ajaximations

          expect(@student.current_differentiation_tag_memberships.pluck(:group_id)).to include @multiple_tags_1.id
        end

        it "updates user count in tray when removing a member" do
          fj("button:contains('Manage Tags')").click
          wait_for_ajaximations

          # Verify counts in tray
          expect(fj("[data-testid='tag-info']:contains('#{@multiple_tags_1.name}')").text).to include("0 students")
          expect(fj("[data-testid='tag-info']:contains('#{@multiple_tags_2.name}')").text).to include("0 students")

          # Add a user to a dif tag
          f("input[type='checkbox'][aria-label='Select #{@student.name}']").click
          f("button[data-testid='user-diff-tag-manager-tag-as-button']").click
          wait_for_ajaximations
          force_click("span:contains('#{@multiple_tags_1.name}')")
          wait_for_ajaximations

          # verify new count shows in the component
          expect(fj("[data-testid='tag-info']:contains('#{@multiple_tags_1.name}')").text).to include("1 student")
          expect(fj("[data-testid='tag-info']:contains('#{@multiple_tags_2.name}')").text).to include("0 students")

          # remove the user from the tag
          f("a[aria-label='View user tags']").click
          wait_for_ajaximations
          f("button[data-testid='user-tag-#{@multiple_tags_1.id}']").click
          wait_for_ajaximations
          expect(fj("h2:contains('Remove Tag')")).to be_displayed
          fj("button:contains('Confirm')").click
          wait_for_ajaximations

          # Verify counts in tray
          expect(fj("[data-testid='tag-info']:contains('#{@multiple_tags_1.name}')").text).to include("0 students")
          expect(fj("[data-testid='tag-info']:contains('#{@multiple_tags_2.name}')").text).to include("0 students")
        end
      end

      context "create/edit modal" do
        context "from tray" do
          before do
            fj("button:contains('Manage Tags')").click
            wait_for_ajaximations
          end

          it "Creates a single tag" do
            # Open the create modal from the tray
            fj("button:contains('+ Tag')").click
            wait_for_ajaximations

            # Ensure the modal header is correct
            expect(fj("h2:contains('Create Tag')")).to be_displayed

            # Fill in the single tag input
            tag_input = f("[data-testid='tag-name-input']")
            tag_input.send_keys("New Single Tag")

            # Submit the form
            fj("button:contains('Save')").click
            wait_for_ajaximations

            # Verify that the modal is closed and the new tag is visible in the tray
            expect(f("body")).not_to contain_jqcss("h2:contains('Create Tag')")
            expect(fj("span:contains('New Single Tag')")).to be_displayed
          end

          it "Creates a multiple tag" do
            # Open the create modal from the tray
            fj("button:contains('+ Tag')").click
            wait_for_ajaximations

            # Switch to multiple tag mode by adding a variant
            fj("button:contains('+ Add another tag')").click
            wait_for_ajaximations

            # Fill in both tag inputs
            tag_inputs = ff("[data-testid='tag-name-input']")
            tag_inputs[0].send_keys("Variant 1")
            tag_inputs[1].send_keys("Variant 2")

            # For multiple tags, a Tag Set Name is required – fill it in
            tag_set_input = f("input[name='tag-set-name']")
            tag_set_input.send_keys("New Tag Set")

            # Submit the form
            fj("button:contains('Save')").click
            wait_for_ajaximations

            # Verify that the modal is closed and both tag variants appear in the tray
            expect(f("body")).not_to contain_jqcss("h2:contains('Create Tag')")
            expect(fj("span:contains('Variant 1')")).to be_displayed
            expect(fj("span:contains('Variant 2')")).to be_displayed
          end

          it "Adds a new tag to an existing tag set" do
            # Open the edit modal for an existing multiple tag set
            f("button[aria-label='Edit tag set: #{@multiple_tags.name}']").click
            wait_for_ajaximations

            # Click the button to add a new variant (updated selector)
            fj("button:contains('+ Add another tag')").click
            wait_for_ajaximations

            # Fill in the new tag variant input (assumed to be the last input)
            tag_inputs = ff("[data-testid='tag-name-input']")
            new_variant_input = tag_inputs.last
            new_variant_input.send_keys("Additional Variant")

            # Submit the form
            fj("button:contains('Save')").click
            wait_for_ajaximations

            # Verify that the new variant appears alongside the existing ones
            expect(fj("span:contains('Additional Variant')")).to be_displayed
            expect(fj("span:contains('#{@multiple_tags_1.name}')")).to be_displayed
            expect(fj("span:contains('#{@multiple_tags_2.name}')")).to be_displayed
          end

          it "Displays correct edit data for a single tag" do
            # Open the edit modal for a single tag
            f("button[aria-label='Edit tag set: #{@single_tag.name}']").click
            wait_for_ajaximations

            # Verify that the modal shows the correct header and fields
            expect(fj("span:contains('Edit Tag')")).to be_displayed
            expect(fj("span:contains('Tag Name')")).to be_displayed

            # Ensure that 'Tag Set Name' is not displayed for a single tag
            expect(f("body")).not_to contain_jqcss("span:contains('Tag Set Name')")

            # Check that the input has the correct value
            expect(f("[data-testid='tag-name-input']")).to have_value(@single_tag.name)
          end

          it "Displays correct edit data for a multiple tag" do
            # Open the edit modal for a multiple tag set
            f("button[aria-label='Edit tag set: #{@multiple_tags.name}']").click
            wait_for_ajaximations

            # Verify that the modal shows both Tag Set Name and tag variant fields
            expect(fj("span:contains('Edit Tag')")).to be_displayed
            expect(fj("span:contains('Tag Set Name')")).to be_displayed
            expect(fj("span:contains('Tag Name')")).to be_displayed
            expect(fj("span:contains('Tag Name (Variant 1)')")).to be_displayed
            expect(fj("span:contains('Tag Name (Variant 2)')")).to be_displayed

            # Verify the correct values in each tag input field
            tag_inputs = ff("[data-testid='tag-name-input']")
            expect(tag_inputs[0]).to have_value(@multiple_tags_1.name)
            expect(tag_inputs[1]).to have_value(@multiple_tags_2.name)
          end

          it "Displays correct edit data for a tag set with one tag but different names" do
            # Setup a differentiation tag set with a different tag set name from its single tag name.
            single_diff_set = @course.group_categories.create!(name: "Diff Set", non_collaborative: true)
            diff_set_group = @course.groups.create!(name: "Different Tag", group_category: single_diff_set)

            # Refresh the page and open the differentiation tag tray so the new tag set appears
            refresh_page
            wait_for_ajaximations
            fj("button:contains('Manage Tags')").click
            wait_for_ajaximations

            # Open the edit modal for this tag set (updated selector if needed)
            f("button[aria-label='Edit tag set: #{single_diff_set.name}']").click
            wait_for_ajaximations

            # Verify that both 'Tag Set Name' and 'Tag Name' fields are displayed
            expect(fj("span:contains('Edit Tag')")).to be_displayed
            expect(fj("span:contains('Tag Set Name')")).to be_displayed
            expect(fj("span:contains('Tag Name')")).to be_displayed
            # Check that the inputs have the correct values
            expect(f("[data-testid='tag-set-name']")).to have_value(single_diff_set.name)
            expect(f("[data-testid='tag-name-input']")).to have_value(diff_set_group.name)
          end

          it "updates just the set name" do
            # Open the edit modal for a multiple tag set
            f("button[aria-label='Edit tag set: #{@multiple_tags.name}']").click
            wait_for_ajaximations

            tag_set_name_input = f("[data-testid='tag-set-name']")
            tag_set_name_input.send_keys("updated")

            # Submit the form
            fj("button:contains('Save')").click
            wait_for_ajaximations
            expect(fj("span:contains('Multiple Tagsupdated')")).to be_displayed
          end

          it "updates just one tag name" do
            # Open the edit modal for the tag set
            f("button[aria-label='Edit tag set: #{@multiple_tags.name}']").click
            wait_for_ajaximations

            # Update only the first tag's name
            tag_inputs = ff("[data-testid='tag-name-input']")
            first_input = tag_inputs.first
            first_input.send_keys(" updated")
            wait_for_ajaximations

            # Submit the form
            fj("button:contains('Save')").click
            wait_for_ajaximations

            # Verify that the updated tag displays the new name
            expect(fj("span:contains('tag variant 1 updated')")).to be_displayed
          end

          it "adds just one tag" do
            # Open the edit modal for the tag set
            f("button[aria-label='Edit tag set: #{@multiple_tags.name}']").click
            wait_for_ajaximations

            # Click the button to add a new tag variant
            fj("button:contains('+ Add another tag')").click
            wait_for_ajaximations

            # Locate the new tag input field and fill it in
            tag_inputs = ff("[data-testid='tag-name-input']")
            new_input = tag_inputs.last
            new_input.send_keys("New Tag")
            wait_for_ajaximations

            # Submit the form
            fj("button:contains('Save')").click
            wait_for_ajaximations

            # Verify that the new tag appears on the page
            expect(fj("span:contains('New Tag')")).to be_displayed
          end

          it "deletes one tag" do
            f("button[aria-label='Edit tag set: #{@multiple_tags.name}']").click
            wait_for_ajaximations

            ff("button[data-testid='remove-tag']")[0].click
            wait_for_ajaximations

            fj("button:contains('Save')").click
            wait_for_ajaximations

            expect(f("body")).not_to contain_jqcss("span:contains('tag variant 1')")
          end

          it "deletes, adds, updates tags correctly in one request" do
            # Open the edit modal for a multiple tag set
            f("button[aria-label='Edit tag set: #{@multiple_tags.name}']").click
            original_tag_ids = @multiple_tags.groups.pluck(:id)
            wait_for_ajaximations

            # Update the first tag's name
            tag_inputs = ff("[data-testid='tag-name-input']")
            second_input = tag_inputs[1]
            second_input.send_keys("added text")

            # Delete the second tag variant via its remove button (updated selector)
            ff("button[data-testid='remove-tag']")[0].click
            wait_for_ajaximations

            # Add a new tag variant (updated button text)
            fj("button:contains('+ Add another tag')").click
            wait_for_ajaximations
            tag_inputs = ff("[data-testid='tag-name-input']")
            new_input = tag_inputs.last
            new_input.send_keys("New Variant")

            tag_set_name_input = f("[data-testid='tag-set-name']")
            tag_set_name_input.send_keys("updated")

            # Submit the form
            fj("button:contains('Save')").click
            wait_for_ajaximations
            # Verify that the updated and new tags appear, and the deleted tag is absent
            expect(fj("span:contains('New Variant')")).to be_displayed
            expect(fj("span:contains('tag variant 2added text')")).to be_displayed
            expect(fj("span:contains('Multiple Tagsupdated')")).to be_displayed

            # verify that the group ids are different
            expect(@multiple_tags.reload.groups.active.pluck(:id)).not_to eq(original_tag_ids)
          end
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
