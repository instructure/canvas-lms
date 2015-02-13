require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/files_common')

 describe "better_file_browsing" do
   include_examples "in-process server selenium tests"

   context "As a teacher", :priority => "1" do
      before (:each) do
        course_with_teacher_logged_in
        Account.default.enable_feature!(:better_file_browsing)
        add_file(fixture_file_upload('files/example.pdf', 'application/pdf'),
         @course, "example.pdf")
        get "/courses/#{@course.id}/files"
      end

      it "should display new files UI" do
        expect(f('.btn-upload')).to be_displayed
        expect(get_all_files_folders.count).to eq 1
      end

      it "should edit file name" do
        expect(fln("example.pdf")).to be_present
        file_rename_to = "Example_edited.pdf"
        edit_name_from_cog(file_rename_to)
        wait_for_ajaximations
        expect(fln("example.pdf")).not_to be_present
        expect(fln(file_rename_to)).to be_present
      end

      it "should delete file from cog menu" do
        file_name = "example.pdf"
        delete_from_cog
        expect(get_all_files_folders.count).to eq 0
      end

      it "should unpublish and publish a file from cog menu" do
        permissions('rgba(128, 128, 128, 1)', 1, 0)
        expect(f('.btn-link.published-status.unpublished')).to be_displayed
        permissions('rgba(0, 173, 24, 1)', 0, 0)
        expect(f('.btn-link.published-status.published')).to be_displayed
      end

      it "should make file available to student with link" do
        tooltip_text = "Hidden. Available with a link"
        permissions('rgba(196, 133, 6, 1)', 2, 0)
        expect(f('.btn-link.published-status.hiddenState')).to be_displayed
      end

      it "should make file available to student within given timeframe" do
        tooltip_text = "Hidden. Available with a link"
        permissions('rgba(196, 133, 6, 1)', 2, 1)
        expect(f('.btn-link.published-status.restricted')).to be_displayed
      end

      it "should delete file from toolbar" do
        file_name = "example.pdf"
        delete_from_toolbar
        expect(get_all_files_folders.count).to eq 0
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

   context "Publish Cloud Dialog", :priority => '3' do
    before (:each) do
      course_with_teacher_logged_in
      Account.default.enable_feature!(:better_file_browsing)
      add_file(fixture_file_upload('files/a_file.txt', 'text/plain'),
               @course, "a_file.txt")
      get "/courses/#{@course.id}/files"
    end

    it "should validate that file is published by default" do
        publish_background_color = 'rgba(0, 173, 24, 1)'
        icon_publish_color = ff('.icon-publish')[0].css_value('color')
        expect(f('.btn-link.published-status.published')).to be_displayed
        expect(icon_publish_color).to eq publish_background_color
    end

    it "should set focus to the close button when opening the dialog" do
      f('.btn-link.published-status').click
      wait_for_ajaximations
      shouldFocus = f('.ui-dialog-titlebar-close')
      element = driver.execute_script('return document.activeElement')
      expect(element).to eq(shouldFocus)
    end
   end
end
