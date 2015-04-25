require File.expand_path(File.dirname(__FILE__) + '/common')

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
      #Looks in the group tab list for the last item, which should be the group set
      expect(fj('.collectionViewItems[role=tablist]>li:last-child').text).to match "Test Group Set"
    end

    it "should allow teachers to create groups within group sets", :priority => "1", :test_id => 94153 do
      group_category = @course.group_categories.create!(:name => "Test Group Set")

      get "/courses/#{@course.id}/groups"

      expect(f('.btn.add-group')).to be_displayed
      f('.btn.add-group').click
      wait_for_ajaximations
      f('#group_name').send_keys("Test Group")
      f('.btn-primary[type=submit]').click
      wait_for_ajaximations
      expect(fj('.collectionViewItems.unstyled.groups-list>li:last-child')).to include_text("Test Group")
    end
  end
end
