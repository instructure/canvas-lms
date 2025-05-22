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
    @sub1_account = Account.create!(name: "sub1", parent_account: Account.default)
    @sub2_account = Account.create!(name: "sub2", parent_account: Account.default)
    @course_with_tags_disabled = course_with_teacher(active_user: true, active_course: true, active_enrollment: true, name: "Teacher Example").course
    @course_with_tags_disabled.update!(account: @sub1_account)
    @course_with_tags_enabled = course_with_teacher(user: @teacher, active_course: true).course
    @course_with_tags_enabled.update!(account: @sub2_account)
    @other_student ||= student_in_course(active_all: true, name: "other_student@test.com").user
    @third_student = student_in_course(active_all: true, name: "student@test.com").user
    ta_in_course(active_all: true)

    # Enable FF
    Account.default.enable_feature! :assign_to_differentiation_tags
    # Set account setting to true but not locked
    @sub2_account.settings[:allow_assign_to_differentiation_tags] = { value: true }
    @sub2_account.save!

    @sub1_account.settings[:allow_assign_to_differentiation_tags] = { value: false }
    @sub1_account.save!

    @single_tag = @course.group_categories.create!(name: "single tag", non_collaborative: true)
    @single_tag_1 = @course.groups.create!(name: "single tag", group_category: @single_tag)
    @single_tag_1.add_user(@third_student)

    @multiple_tags = @course.group_categories.create!(name: "Multiple Tags", non_collaborative: true)
    @multiple_tags_1 = @course.groups.create!(name: "tag variant 1", group_category: @multiple_tags)
    @multiple_tags_2 = @course.groups.create!(name: "tag variant 2", group_category: @multiple_tags)
    @multiple_tags_3 = @course.groups.create!(name: "tag variant 2", group_category: @multiple_tags)

    @single_tag_with_long_name = @course.group_categories.create!(name: "tag with a really long truncated name", non_collaborative: true)
    @single_tag_with_long_name_1 = @course.groups.create!(name: "tag with a really long truncated name variant", group_category: @single_tag_with_long_name)
    @single_tag_with_long_name_2 = @course.groups.create!(name: "tag with a really long truncated name variant", group_category: @single_tag_with_long_name)
  end

  describe "in the people page" do
    context "with permissions" do
      before do
        user_session @teacher
        get "/courses/#{@course.id}/users"
      end

      context "checkbox behavior" do
        context "master checkbox behavior" do
          it "checks all checkboxes when the master checkbox is checked and tags all users" do
            master_checkbox = f("input.select-all-users-checkbox")
            master_checkbox.click
            wait_for_ajaximations

            # Verify that every checkbox in the user list is now checked.
            ff("input[type='checkbox'][aria-label^='Select ']").each do |checkbox|
              expect(checkbox.attribute("checked")).to be_truthy
            end

            # Now, open the tag menu and assign a tag to all selected users.
            f("button[data-testid='user-diff-tag-manager-tag-as-button']").click
            wait_for_ajaximations
            force_click("span:contains('#{@single_tag_1.name}')")
            wait_for_ajaximations

            # Verify that each selected student is now tagged.
            # Assuming @student and @other_student are the users expected to be tagged.
            expect(@student.current_differentiation_tag_memberships.pluck(:group_id)).to include(@single_tag_1.id)
            expect(@other_student.current_differentiation_tag_memberships.pluck(:group_id)).to include(@single_tag_1.id)
          end

          it "unchecks all checkboxes when the master checkbox is unchecked and does not tag any users" do
            master_checkbox = f("input.select-all-users-checkbox")
            master_checkbox.click
            wait_for_ajaximations
            # Uncheck the master checkbox.
            master_checkbox.click
            wait_for_ajaximations

            # Verify that every checkbox in the user list is now unchecked.
            ff("input[type='checkbox'][aria-label^='Select ']").each do |checkbox|
              expect(checkbox.attribute("checked")).to be_falsey
            end
            # Attempt to assign a tag (this should not tag any users since none are selected).
            f("button[data-testid='user-diff-tag-manager-tag-as-button']").click
            wait_for_ajaximations
            force_click("span:contains('#{@multiple_tags_1.name}')")
            wait_for_ajaximations
            # Verify that no user has been tagged.
            expect(@student.current_differentiation_tag_memberships.pluck(:group_id)).not_to include(@multiple_tags_1.id)
            expect(@other_student.current_differentiation_tag_memberships.pluck(:group_id)).not_to include(@multiple_tags_1.id)
          end

          it "allows you to unselect individual users while master checkbox is checked and only tags the selected ones" do
            master_checkbox = f("input.select-all-users-checkbox")
            master_checkbox.click
            wait_for_ajaximations

            # Unselect a specific student (assuming @student exists).
            student_checkbox = f("input[type='checkbox'][aria-label='Select #{@student.name}']")
            student_checkbox.click
            wait_for_ajaximations

            # That student's checkbox should now be unchecked.
            expect(student_checkbox.attribute("checked")).to be_falsey

            # All other checkboxes should remain checked.
            ff("input[type='checkbox'][aria-label^='Select ']").each do |checkbox|
              next if checkbox == master_checkbox || checkbox == student_checkbox

              expect(checkbox.attribute("checked")).to be_truthy
            end
            # Open the tag menu and assign a tag to the selected users.
            f("button[data-testid='user-diff-tag-manager-tag-as-button']").click
            wait_for_ajaximations
            force_click("span:contains('#{@multiple_tags_1.name}')")
            wait_for_ajaximations

            # Verify that the unselected user (@student) does not get tagged.
            expect(@student.current_differentiation_tag_memberships.pluck(:group_id)).not_to include(@multiple_tags_1.id)
            # Verify that the remaining selected user(s), for example @other_student, are tagged.
            expect(@other_student.current_differentiation_tag_memberships.pluck(:group_id)).to include(@multiple_tags_1.id)
          end

          it "Stops displaying differentiation tag UI if the setting is turned off" do
            expect(f("body")).to contain_jqcss("input[type='checkbox'][aria-label^='Select']")
            expect(f("body")).to contain_jqcss("button[data-testid='user-diff-tag-manager-tag-as-button']")
            expect(f("body")).to contain_jqcss("a[aria-label^='View '][aria-label$=' user tags']")
            @course.account.settings[:allow_assign_to_differentiation_tags] = { value: false }
            @course.account.save!
            refresh_page
            expect(f("body")).not_to contain_jqcss("input[type='checkbox'][aria-label^='Select']")
            expect(f("body")).not_to contain_jqcss("button[data-testid='user-diff-tag-manager-tag-as-button']")
            expect(f("body")).not_to contain_jqcss("a[aria-label^='View '][aria-label$=' user tags']")
          end

          it "properly handles paginated users" do
            students = Array.new(60) do |i|
              student_in_course(active_all: true, name: "pagination_student_#{i}@example.com").user
            end

            refresh_page
            wait_for_ajaximations

            # Select “all”
            find("input.select-all-users-checkbox").click
            wait_for_ajaximations
            expect(find("[data-testid='user-diff-tag-manager-user-count']")).to include_text("#{@course.students.count} Selected")

            # Deselect the first two
            deselected = students.first(2)
            deselected.each do |student|
              find("input[type='checkbox'][aria-label='Select #{student.name}']").click
              wait_for_ajaximations
            end

            expect(find("[data-testid='user-diff-tag-manager-user-count']")).to include_text("#{@course.students.count - 2} Selected")

            # Tag the remaining students
            f("button[data-testid='user-diff-tag-manager-tag-as-button']").click
            wait_for_ajaximations
            force_click("span:contains('#{@single_tag_1.name}')")
            wait_for_ajaximations

            # Verify only the still-selected students got tagged
            selected = students - deselected
            selected.each do |student|
              expect(student.current_differentiation_tag_memberships.pluck(:group_id))
                .to include(@single_tag_1.id)
            end

            # And the two deselected never got the tag
            deselected.each do |student|
              expect(student.current_differentiation_tag_memberships.pluck(:group_id))
                .not_to include(@single_tag_1.id)
            end
          end
        end

        it "renders the checkbox header" do
          expect(fj("span:contains('Select All Users')")).to be_truthy
        end

        context "checkbox visibility" do
          it "renders differentiation checkbox only for student rows" do
            # Ensure the checkbox is displayed for the student
            expect(f("input[type='checkbox'][aria-label='Select #{@student.name}']")).to be_displayed
            # Ensure the checkbox is not displayed for non-student rows (e.g. teacher)
            expect(f("body")).not_to contain_jqcss("input[type='checkbox'][aria-label='Select #{@teacher.name}']")
          end
        end
      end

      context "differentiation tag tray" do
        before do
          fj("button:contains('Manage Tags')").click
          wait_for_ajaximations
        end

        it "opens the tray when the 'Manage Tags' button is clicked" do
          expect(fj("h2:contains('Manage Tags')")).to be_displayed
        end

        it "displays a tooltip when name is too large" do
          expect(ff("[data-testid='full-tag-name']").last.text).to eq ""
          hover(f("[data-testid='tooltip-container']"))
          wait_for_ajaximations
          expect(ff("[data-testid='full-tag-name']").last.text).to eq @single_tag_with_long_name.name
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

        it "updates the name of a single tag" do
          f("button[aria-label='Edit tag set: #{@single_tag.name}']").click
          wait_for_ajaximations

          # Update the tag name in the input field
          tag_input = f("[data-testid='tag-name-input']")
          tag_input.send_keys("update")
          # Submit the form
          fj("button:contains('Save')").click
          wait_for_ajaximations

          expect(f("body")).not_to contain_jqcss("h2:contains('Edit Tag')")
          expect(fj("span:contains('#{@single_tag.name}update')")).to be_displayed

          # Verify that the Group Category and Group name is the same
          expect(@single_tag.reload.name).to eq @single_tag.groups.first.name
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
          expect(@course.differentiation_tag_categories.count).to eq 2
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
          f("a[aria-label='View #{@student.name} user tags']").click
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

        it "shows accessibility information for tag pills in users tag modal" do
          @multiple_tags_2.add_user(@third_student)
          refresh_page
          wait_for_ajaximations
          f("#tag-icon-id-#{@third_student.id}").click
          wait_for_ajaximations
          expect(f("body")).to contain_jqcss("span:contains('Remove #{@multiple_tags.name} | #{@multiple_tags_2.name}')")
          expect(f("body")).to contain_jqcss("span:contains('Remove #{@single_tag_1.name}')")
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

          it "Displays an error message in the modal", :ignore_js_errors do
            allow_any_instance_of(GroupCategoriesController)
              .to receive(:bulk_manage_differentiation_tag)
              .and_raise(ActiveRecord::RecordInvalid.new)

            fj("button:contains('+ Tag')").click
            wait_for_ajaximations

            expect(fj("h2:contains('Create Tag')")).to be_displayed

            tag_input = f("[data-testid='tag-name-input']")
            tag_input.send_keys("New Single Tag")
            fj("button:contains('Save')").click
            wait_for_ajaximations

            expect(fj("h2:contains('Create Tag')")).to be_displayed
            expect(f(".flashalert-message")).to be_displayed
          end
        end
      end

      context "user selection persistence" do
        it "retains checked users across a search and applies a single tag to both" do
          # Check first student on the initial people page
          f("input[type='checkbox'][aria-label='Select #{@student.name}']").click
          expect(f("input[type='checkbox'][aria-label='Select #{@student.name}']").attribute("checked")).to be_truthy

          # Perform a search that brings in the second student (@other_student)
          search_box = f("input[placeholder='Search people']")
          search_box.send_keys("other")
          wait_for_ajaximations

          # Check the second student from the search results
          f("input[type='checkbox'][aria-label='Select #{@other_student.name}']").click
          expect(f("input[type='checkbox'][aria-label='Select #{@other_student.name}']").attribute("checked")).to be_truthy

          # Clear the search to display the full people list
          search_box.clear
          search_box.send_keys(" ")
          search_box.send_keys(:backspace)

          wait_for_ajaximations

          # Verify that both students remain checked
          expect(f("input[type='checkbox'][aria-label='Select #{@student.name}']").attribute("checked")).to be_truthy
          expect(f("input[type='checkbox'][aria-label='Select #{@other_student.name}']").attribute("checked")).to be_truthy

          # Open the 'Tag As' menu and tag both with a single tag variant
          f("button[data-testid='user-diff-tag-manager-tag-as-button']").click
          wait_for_ajaximations
          force_click("span:contains('#{@single_tag_1.name}')")
          wait_for_ajaximations

          # Verify that both users have been tagged with the single tag
          expect(@student.current_differentiation_tag_memberships.pluck(:group_id)).to include(@single_tag_1.id)
          expect(@other_student.current_differentiation_tag_memberships.pluck(:group_id)).to include(@single_tag_1.id)
        end

        it "retains checked users across a role filter search and applies a multiple tag variant to both" do
          # Check first student on the initial people page
          f("input[type='checkbox'][aria-label='Select #{@student.name}']").click
          expect(f("input[type='checkbox'][aria-label='Select #{@student.name}']").attribute("checked")).to be_truthy
          # Use the role filter dropdown (assumed to have id 'role-filter') to filter by "Student"
          student_role_id = Role.where(name: "StudentEnrollment", root_account_id: @course.account.root_account.id).first.id
          click_option("select[name=enrollment_role_id]", student_role_id.to_s, :value)
          wait_for_ajaximations

          # Check the second student from the filtered results
          f("input[type='checkbox'][aria-label='Select #{@other_student.name}']").click
          expect(f("input[type='checkbox'][aria-label='Select #{@other_student.name}']").attribute("checked")).to be_truthy

          # Clear the role filter by selecting "All"
          click_option("select[name=enrollment_role_id]", "All Roles")
          wait_for_ajaximations

          # Verify that both checkboxes remain checked
          expect(f("input[type='checkbox'][aria-label='Select #{@student.name}']").attribute("checked")).to be_truthy
          expect(f("input[type='checkbox'][aria-label='Select #{@other_student.name}']").attribute("checked")).to be_truthy

          # Open the 'Tag As' menu and tag both with a multiple tag variant
          f("button[data-testid='user-diff-tag-manager-tag-as-button']").click
          wait_for_ajaximations
          force_click("span:contains('#{@multiple_tags_1.name}')")
          wait_for_ajaximations

          # Verify that both users have been tagged with the multiple tag variant
          expect(@student.current_differentiation_tag_memberships.pluck(:group_id)).to include(@multiple_tags_1.id)
          expect(@other_student.current_differentiation_tag_memberships.pluck(:group_id)).to include(@multiple_tags_1.id)
        end
      end

      it "keeps all users selected when scrolling to load more users" do
        # Create a bunch of users (enough to trigger pagination)
        students = []
        50.times do |i|
          students << student_in_course(active_all: true, name: "pagination_student_#{i}@example.com").user
        end

        # Refresh the page to show all the new users
        refresh_page
        wait_for_ajaximations

        # Check the master checkbox
        master_checkbox = f("input.select-all-users-checkbox")
        master_checkbox.click
        wait_for_ajaximations

        # Verify the initial set of checkboxes are checked
        initial_checkboxes = ff("input[type='checkbox'][aria-label^='Select ']")
        initial_checkboxes.each do |checkbox|
          expect(checkbox.attribute("checked")).to be_truthy
        end

        # Scroll to the bottom to trigger loading more users
        scroll_into_view(ff("tr.rosterUser").last)
        wait_for_ajaximations

        # Verify that all checkboxes, including newly loaded ones, are checked
        all_checkboxes = ff("input[type='checkbox'][aria-label^='Select ']")
        all_checkboxes.each do |checkbox|
          expect(checkbox.attribute("checked")).to be_truthy
        end

        # Test tagging functionality with all users selected
        wait_for_ajaximations
        force_click("button[data-testid='user-diff-tag-manager-tag-as-button']")
        wait_for_ajaximations
        force_click("span:contains('#{@single_tag_1.name}')")
        wait_for_ajaximations

        # Verify that all users have been tagged
        students.each do |student|
          expect(student.current_differentiation_tag_memberships.pluck(:group_id)).to include(@single_tag_1.id)
        end
      end
    end

    context "without permissions" do
      it "does not display the 'Manage Tags' button when user does not have permissions" do
        user_session @student
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

    context "sub account setting and feature flag conditions" do
      it "does not display 'Manage Tags' if the feature flag is off" do
        Account.default.disable_feature!(:assign_to_differentiation_tags)

        user_session @teacher
        get "/courses/#{@course.id}/users"
        expect(f("body")).not_to contain_jqcss("button:contains('Manage Tags')")
      end

      context "when the parent account differentiation tags setting is on and locked" do
        before do
          Account.default.settings[:allow_assign_to_differentiation_tags] = { value: true, locked: true }
          Account.default.save!
        end

        it "shows the 'Manage Tags' button" do
          user_session @teacher
          get "/courses/#{@course_with_tags_disabled.id}/users"
          expect(f("body")).to contain_jqcss("button:contains('Manage Tags')")
        end
      end

      context "when the parent account setting is on and not locked" do
        before do
          Account.default.set_feature_flag! :assign_to_differentiation_tags, Feature::STATE_DEFAULT_ON
          Account.default.settings[:allow_assign_to_differentiation_tags] = { value: true }
          Account.default.save!
        end

        it "shows the 'Manage Tags' button when sub account setting is on" do
          user_session @teacher
          get "/courses/#{@course_with_tags_enabled.id}/users"
          expect(f("body")).to contain_jqcss("button:contains('Manage Tags')")
        end

        it "does not show the 'Manage Tags' button when sub account setting is off" do
          @sub1_account.disable_feature! :assign_to_differentiation_tags
          @sub1_account.settings[:allow_assign_to_differentiation_tags] = { value: false }
          @sub1_account.save!
          @teacher.clear_caches
          user_session @teacher
          get "/courses/#{@course_with_tags_disabled.id}/users"
          expect(f("body")).not_to contain_jqcss("button:contains('Manage Tags')")
        end
      end

      context "when the parent account setting is off and not locked" do
        before do
          Account.default.set_feature_flag! :assign_to_differentiation_tags, Feature::STATE_DEFAULT_ON
          Account.default.settings[:allow_assign_to_differentiation_tags] = { value: false }
          Account.default.save!
        end

        it "shows the 'Manage Tags' button when sub account setting is on" do
          user_session @teacher
          get "/courses/#{@course_with_tags_enabled.id}/users"
          expect(f("body")).to contain_jqcss("button:contains('Manage Tags')")
        end

        it "does not show the 'Manage Tags' button when sub account setting is off" do
          @sub1_account.disable_feature! :assign_to_differentiation_tags
          user_session @teacher
          get "/courses/#{@course_with_tags_disabled.id}/users"
          expect(f("body")).not_to contain_jqcss("button:contains('Manage Tags')")
        end

        it "does show 'Manage Tags' button when parent ff is off and unlocked" do
          Account.default.set_feature_flag! :assign_to_differentiation_tags, Feature::STATE_DEFAULT_OFF
          @sub1_account.set_feature_flag! :assign_to_differentiation_tags, Feature::STATE_DEFAULT_ON
          @sub1_account.settings[:allow_assign_to_differentiation_tags] = { value: true }
          @sub1_account.save!
          @sub1_account.reload
          user_session @teacher
          get "/courses/#{@course_with_tags_disabled.id}/users"
          expect(f("body")).to contain_jqcss("button:contains('Manage Tags')")
        end

        it "does not show 'Manage Tags' button when parent ff is off and locked" do
          Account.default.disable_feature! :assign_to_differentiation_tags
          # when you disable parent FF and lock it sub accounts FF and settings won't work even if
          # enabled by code without using the ui
          @sub1_account.set_feature_flag! :assign_to_differentiation_tags, Feature::STATE_DEFAULT_ON
          @sub1_account.settings[:allow_assign_to_differentiation_tags] = { value: true }
          @sub1_account.save!
          @sub1_account.reload
          user_session @teacher
          get "/courses/#{@course_with_tags_disabled.id}/users"
          expect(f("body")).not_to contain_jqcss("button:contains('Manage Tags')")
        end
      end
    end
  end
end
