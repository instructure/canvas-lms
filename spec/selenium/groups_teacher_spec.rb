require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/groups_common')

describe "new groups" do
  include_examples "in-process server selenium tests"

  context "as a teacher" do
    before (:each) do
      course_with_teacher_logged_in
    end

    it "should allow teachers to add a group set", priority: "1", test_id: 94152 do
      get "/courses/#{@course.id}/groups"
      f('#add-group-set').click
      wait_for_ajaximations
      f('#new_category_name').send_keys("Test Group Set")
      f('#newGroupSubmitButton').click
      wait_for_ajaximations
      # Looks in the group tab list for the last item, which should be the group set
      expect(fj('.collectionViewItems[role=tablist]>li:last-child').text).to match "Test Group Set"
    end

    it "should allow teachers to create groups within group sets", priority: "1", test_id: 94153 do
      seed_groups(1,0)

      get "/courses/#{@course.id}/groups"

      expect(f('.btn.add-group')).to be_displayed
      f('.btn.add-group').click
      wait_for_ajaximations
      f('#group_name').send_keys("Test Group")
      f('#groupEditSaveButton').click
      wait_for_ajaximations
      expect(fj('.collectionViewItems.unstyled.groups-list>li:last-child')).to include_text("Test Group")
    end

    it "should allow teachers to add a student to a group", priority: "1", test_id: 94155 do
      # Creates one user, and one groupset with a group inside it
      group_test_setup(1,1,1)

      get "/courses/#{@course.id}/groups"

      # Tests the list of groups in the + button menu popup to see if it has the correct groups
      f('.assign-to-group').click
      wait_for_ajaximations
      setgroup = f('.set-group')
      expect(setgroup).to include_text(@testgroup[0].name)
      setgroup.click
      wait_for_ajaximations

      # Adds student to test group and then expands the group display to the right to verify he is in the group
      f('.toggle-group').click
      wait_for_ajaximations
      expect(f('.group-summary')).to include_text("1 student")
      expect(f('.group-user-name')).to include_text(@students.first.name)
    end

    it "should allow teachers to move a student to a different group", priority: "1", test_id: 94157 do
      # Creates 1 user, 1 groupset, and 2 groups within the groupset
      group_test_setup(1,1,2)
      # Add seeded student to first seeded group
      add_user_to_group(@students.first,@testgroup[0])

      get "/courses/#{@course.id}/groups"

      # Toggles the first group collapse arrow to see the student
      fj('.toggle-group :contains("Test Group 1")').click
      wait_for_ajaximations

      # Verifies the student is in their group
      expect(f('.group-user')).to include_text(@students[0].name)

      # Moves the student
      f('.group-user-actions').click
      wait_for_ajaximations
      f('.edit-group-assignment').click
      wait_for_ajaximations
      click_option('.single-select', "#{@testgroup[1].name}")
      f('.set-group').click
      wait_for_ajaximations

      # Verifies the student count updates
      expect(ff('.group-summary')[1]).to include_text("1 student")

      # Verifies student is within new group
      fj('.toggle-group :contains("Test Group 2")').click
      wait_for_ajaximations
      expect(f('.group-user')).to include_text(@students.first.name)
    end

    it "should allow teachers to remove a student from a group", priority: "1", test_id: 94158 do
      group_test_setup
      add_user_to_group(@students.first,@testgroup[0])

      get "/courses/#{@course.id}/groups"

      f('.toggle-group').click
      wait_for_ajaximations

      # Deletes the user
      f('.group-user-actions').click
      wait_for_ajaximations
      f('.remove-from-group').click
      wait_for_ajaximations

      expect(f('.ui-cnvs-scrollable')).to include_text(@students.first.name)
      expect(f('.unassigned-users-heading')).to include_text("Unassigned Students (1)")
      expect(f('.group-summary')).to include_text("0 students")
    end

    it "should allow teachers to make a student a group leader", priority: "1", test_id: 96021 do
      group_test_setup
      add_user_to_group(@students.first,@testgroup[0])

      get "/courses/#{@course.id}/groups"

      fj('.toggle-group :contains("Test Group 1")').click
      wait_for_ajaximations

      # Sets user as group leader
      f('.group-user-actions').click
      wait_for_ajaximations
      f('.set-as-leader').click
      wait_for_ajaximations

      # Looks for student to have a group leader icon
      expect(f('.icon-user.group-leader')).to be_displayed
      # Verifies group leader silhouette and leader's name appear in the group header
      expect(f('.span3.ellipsis.group-leader')).to be_displayed
      expect(f('.span3.ellipsis.group-leader')).to include_text(@students.first.name)
    end

    it "should allow a teacher to set up a group set with member limits", priority: "1", test_id: 94160 do
      group_test_setup(3,0,0)
      get "/courses/#{@course.id}/groups"

      f('#add-group-set').click
      wait_for_ajaximations
      f('#new_category_name').send_keys("Test Group Set")
      f('.self-signup-toggle').click
      manually_set_groupset_limit("2")
      expect(f('.group-category-summary')).to include_text("Groups are limited to 2 members.")

      # Creates a group and checks to see if group set's limit is inherited by its groups
      manually_create_group
      expect(f('.group-summary')).to include_text("0 / 2 students")
    end

    it "should update student count when they're added to groups limited by group set", priority: "1", test_id: 94162 do
      seed_students(3)
      @category = create_category(has_max_membership:true, member_limit:3)
      @group = @course.groups.create!(name:"test group", group_category:@category)

      get "/courses/#{@course.id}/groups"

      expect(f('.group-summary')).to include_text("0 / 3 students")
      f('.al-trigger.btn').click
      f('.icon-edit.edit-category').click

      manually_set_groupset_limit("2")
      expect(f('.group-summary')).to include_text("0 / 2 students")
      manually_fill_limited_group("2",2)
    end

    it "should allow a teacher to set up a group with member limits", priority: "1", test_id: 94161 do
      group_test_setup(3,1,0)
      get "/courses/#{@course.id}/groups"

      manually_create_group(has_max_membership:true, member_limit:2)
      expect(f('.group-summary')).to include_text("0 / 2 students")
    end

    it "should update student count when they're added to groups limited by group", priority: "1", test_id: 94167 do
      group_test_setup(3,1,0)
      create_group(group_category:@group_category.first,has_max_membership:true,member_limit:2)
      get "/courses/#{@course.id}/groups"

      expect(f('.group-summary')).to include_text("0 / 2 students")
      manually_fill_limited_group("2",2)
    end

    it "should show the FULL icon moving from one group to the next", priority: "1", test_id: 94163 do
      group_test_setup(4,1,2)
      @group_category.first.update_attribute(:group_limit,2)

      2.times do |n|
        add_user_to_group(@students[n],@testgroup.first,false)
      end

      add_user_to_group(@students.last,@testgroup[1],false)
      get "/courses/#{@course.id}/groups"

      expect(f(".group[data-id=\"#{@testgroup[0].id}\"] span.show-group-full")).to be_displayed
      expect(f(".group[data-id=\"#{@testgroup[1].id}\"] span.show-group-full")).not_to be_displayed

      f(".group[data-id=\"#{@testgroup[0].id}\"] .toggle-group").click
      wait_for_ajaximations

      f(".group-user-actions[data-user-id=\"#{@students[0].id}\"]").click
      wait_for_ajaximations

      f('.ui-menu-item .edit-group-assignment').click
      wait_for_ajaximations

      f('.single-select option').click
      wait_for_ajaximations

      f('.set-group').click
      wait_for_ajaximations

      expect(f(".group[data-id=\"#{@testgroup[0].id}\"] span.show-group-full")).not_to be_displayed
      expect(f(".group[data-id=\"#{@testgroup[1].id}\"] span.show-group-full")).to be_displayed
    end
  end
end

