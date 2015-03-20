require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/files_common')

describe "better_file_browsing, folders" do
   include_examples "in-process server selenium tests"

  context "Folders" do
    before (:each) do
      course_with_teacher_logged_in
      Account.default.enable_feature!(:better_file_browsing)
      get "/courses/#{@course.id}/files"
      folder_name = "new test folder"
      add_folder(folder_name)
    end

    it "should display the new folder form", :priority => "1", :test_id => 121884 do
      click_new_folder_button
      expect(f("form.ef-edit-name-form")).to be_displayed
    end

    it "should create a new folder", :priority => "1", :test_id => 126905 do
      expect(fln("new test folder")).to be_present
    end

    it "should edit folder name", :priority => "1", :test_id => 129444 do
      folder_rename_to = "test folder"
      edit_name_from_cog(folder_rename_to)
      wait_for_ajaximations
      expect(fln("new test folder")).not_to be_present
      expect(fln("test folder")).to be_present
    end

    it "should delete a folder from cog menu", :priority => "1", :test_id => 129445 do
      delete_from_cog
      expect(fln("new test folder")).not_to be_present
    end

    it "should unpublish and publish a folder from cog menu", :priority => "1", :test_id => 121931 do
      set_item_permissions(:unpublish)
      expect(f('.btn-link.published-status.unpublished')).to be_displayed
      expect(driver.find_element(:class => 'unpublished')).to be_displayed
      set_item_permissions(:publish)
      expect(f('.btn-link.published-status.published')).to be_displayed
      expect(driver.find_element(:class => 'published')).to be_displayed
    end

    it "should make folder available to student with link", :priority => "1", :test_id => 129452 do
      set_item_permissions(:restricted_access, :available_with_link)
      expect(f('.btn-link.published-status.hiddenState')).to be_displayed
      expect(driver.find_element(:class => 'hiddenState')).to be_displayed
    end

    it "should make folder available to student within given timeframe", :priority => "1", :test_id => 129452 do
      set_item_permissions(:restricted_access, :available_with_timeline)
      expect(f('.btn-link.published-status.restricted')).to be_displayed
      expect(driver.find_element(:class => 'restricted')).to be_displayed
    end

    it "should delete folder from toolbar", :priority => "1", :test_id => 129451 do
      delete_from_toolbar
      expect(get_all_files_folders.count).to eq 0
    end
  end

  context "Folder Tree" do
     before (:each) do
       course_with_teacher_logged_in
       Account.default.enable_feature!(:better_file_browsing)
       get "/courses/#{@course.id}/files"
     end

     it "should create a new folder", :priority => "2", :test_id => 126905 do
       new_folder = create_new_folder
       expect(get_all_files_folders.count).to eq 1
       expect(new_folder.text).to match /New Folder/
     end

     it "should create 15 new child folders and show them in the FolderTree when expanded", :priority => "2", :test_id => 121886 do
       create_new_folder
       f('.ef-name-col > a.media').click
       wait_for_ajaximations

       1.upto(15) do |number_of_folders|
        folder_regex = number_of_folders > 1 ? Regexp.new("New Folder\\s#{number_of_folders}") : "New Folder"
        create_new_folder
        expect(get_all_files_folders.count).to eq number_of_folders
        expect(get_all_files_folders.last.text).to match folder_regex
       end

       get "/courses/#{@course.id}/files"
       f('ul.collectionViewItems > li > a > i.icon-mini-arrow-right').click
       wait_for_ajaximations
       keep_trying_until { expect(driver.find_elements(:css, 'ul.collectionViewItems > li > ul.treeContents > li.subtrees > ul.collectionViewItems li').count).to eq 15 }
     end
  end
end