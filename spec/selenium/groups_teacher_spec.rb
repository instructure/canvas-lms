require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/groups_common')

describe "new groups" do
  include_examples "in-process server selenium tests"

  context "as a teacher" do
    before (:each) do
      course_with_teacher_logged_in
    end

    it "should allow teachers to add a group set", :priority => "1", :test_id => 94152 do
      get "/courses/#{@course.id}/groups"
      f('#add-group-set').click
      wait_for_ajaximations
      f('#new_category_name').send_keys("Test Group Set")
      f('.btn-primary[type=submit]').click
      wait_for_ajaximations
      # Looks in the group tab list for the last item, which should be the group set
      expect(fj('.collectionViewItems[role=tablist]>li:last-child').text).to match "Test Group Set"
    end

    it "should allow teachers to create groups within group sets", :priority => "1", :test_id => 94153 do
      seed_groups(1,0)

      get "/courses/#{@course.id}/groups"

      expect(f('.btn.add-group')).to be_displayed
      f('.btn.add-group').click
      wait_for_ajaximations
      f('#group_name').send_keys("Test Group")
      f('.btn-primary[type=submit]').click
      wait_for_ajaximations
      expect(fj('.collectionViewItems.unstyled.groups-list>li:last-child')).to include_text("Test Group")
    end

    it "should allow teachers to add a student to a group", :priority => "1", :test_id => 94155 do
      # Creates one user
      seed_users(1)
      # Creates one group set with one group inside it
      seed_groups(1,1)

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
      expect(f('.group-user-name')).to include_text(@student.name)
    end
  end
end
