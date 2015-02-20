require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/files_common')

describe "better_file_browsing, folders" do
   include_examples "in-process server selenium tests"

  context "Folders", :priority => "1" do
    before (:each) do
      course_with_teacher_logged_in
      Account.default.enable_feature!(:better_file_browsing)
      get "/courses/#{@course.id}/files"
    end

    it "should display the new folder form" do
      click_new_folder_button
      expect(f("form.ef-edit-name-form")).to be_displayed
    end

    it "should create a new folder" do
      folder_name = "new test folder"
      add_folder(folder_name)
      expect(fln(folder_name)).to be_present
    end

    it "should delete a folder from cog menu" do
      folder_name = "folder to be deleted"
      add_folder(folder_name)
      delete_from_cog
      expect(fln(folder_name)).not_to be_present
    end
  end

  context "Folder Tree", priority: "3" do
     before (:each) do
       course_with_teacher_logged_in
       Account.default.enable_feature!(:better_file_browsing)
       get "/courses/#{@course.id}/files"
     end

     it "should create a new folder" do
       new_folder = create_new_folder
       expect(get_all_files_folders.count).to eq 1
       expect(new_folder.text).to match /New Folder/
     end

     it "should create 15 new child folders and show them in the FolderTree when expanded" do
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