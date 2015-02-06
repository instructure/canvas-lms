require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/files_common')

 describe "better_file_browsing" do
   include_examples "in-process server selenium tests"

   context "As a teacher", :priority => "1" do
      before (:each) do
        course_with_teacher_logged_in
        Account.default.enable_feature!(:better_file_browsing)
        get "/courses/#{@course.id}/files"
      end

      it "should display new files UI" do
        keep_trying_until { expect(f('.btn-upload')).to be_displayed }
      end

      it "should edit file name" do
        add_file(fixture_file_upload('files/example.pdf', 'application/pdf'),
               @course, "example.pdf")
        get "/courses/#{@course.id}/files"
        expect(fln("example.pdf")).to be_present
        file_rename_to = "Example_edited.pdf"
        edit_name_from_cog(file_rename_to)
        wait_for_ajaximations
        expect(fln("example.pdf")).not_to be_present
        expect(fln(file_rename_to)).to be_present
      end

      it "should delete file from cog menu" do
        file_name = "example.pdf"
        add_file(fixture_file_upload('files/example.pdf', 'application/pdf'),
               @course, file_name)
        get "/courses/#{@course.id}/files"
        delete_from_cog
        expect(get_all_files_folders.count).to eq 0
      end

      it "should delete file from toolbar" do
        file_name = "example.pdf"
        add_file(fixture_file_upload('files/example.pdf', 'application/pdf'),
               @course, file_name)
        get "/courses/#{@course.id}/files"
        delete_from_toolbar
        expect(get_all_files_folders.count).to eq 0
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

   context "File Downloads", :priority => "2" do
      it "should download a file from top toolbar successfully" do
        skip("Skipped until issue with firefox on OSX is resolved")
        download_from_toolbar
      end

      it "should download a file from cog" do
        skip("Skipped until issue with firefox on OSX is resolved")
        download_from_cog
      end

      it "should download a file from file preview successfully" do
        skip("Skipped until issue with firefox on OSX is resolved")
        download_from_preview
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
