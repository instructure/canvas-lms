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

   context "Usage Rights Dialog", :priority => '3' do
    before :each do
      course_with_teacher_logged_in
      Account.default.enable_feature!(:better_file_browsing)
      Account.default.enable_feature!(:usage_rights_required)
      add_file(fixture_file_upload('files/a_file.txt', 'text/plan'),
               @course, "a_file.txt")
      get "/courses/#{@course.id}/files"
    end

    def set_usage_rights_in_modal(rights = 'creative_commons')
      set_value f('.UsageRightsSelectBox__select'), rights
      if rights == 'creative_commons'
        set_value f('.UsageRightsSelectBox__creativeCommons'), 'cc_by'
      end
      set_value f('#copyrightHolder'), 'Test User'
      f('.ReactModal__Footer-Actions .btn-primary').click
      wait_for_ajaximations
    end

    def verify_usage_rights_ui_updates(iconClass = 'icon-files-creative-commons')
      expect(f(".UsageRightsIndicator__openModal i.#{iconClass}")).to be_displayed
    end

    def react_modal_hidden
      expect(f('.ReactModal__Content')).to eq(nil)
    end

    def element_has_focus(element)
      active_element = driver.execute_script('return document.activeElement')
      expect(active_element).to eq(element)
    end

    it "should set usage rights on a file via the modal by clicking the indicator" do
      f('.UsageRightsIndicator__openModal').click
      wait_for_ajaximations
      set_usage_rights_in_modal
      react_modal_hidden
      # a11y: focus should go back to the element that was clicked.
      element_has_focus(f('.UsageRightsIndicator__openModal'))
      verify_usage_rights_ui_updates
    end

    it "should set usage rights on a file via the cog menu" do
      f('.ef-links-col button[aria-label="Settings"]').click
      f('.ItemCog__OpenUsageRights a').click
      wait_for_ajaximations
      set_usage_rights_in_modal
      react_modal_hidden
      # a11y: focus should go back to the element that was clicked.
      element_has_focus(f('.ef-links-col button[aria-label="Settings"]'))
      verify_usage_rights_ui_updates
    end

    it "should set usage rights on a file via the toolbar" do
      f('.ef-item-row').click
      f('.Toolbar__ManageUsageRights').click
      wait_for_ajaximations
      set_usage_rights_in_modal
      react_modal_hidden
      # a11y: focus should go back to the element that was clicked.
      element_has_focus(f('.Toolbar__ManageUsageRights'))
      verify_usage_rights_ui_updates
    end

    it "should not show the creative commons selection if creative commons isn't selected" do
      f('.UsageRightsIndicator__openModal').click
      wait_for_ajaximations
      set_value f('.UsageRightsSelectBox__select'), 'fair_use'
      expect(f('.UsageRightsSelectBox__creativeCommons')).to eq(nil)
    end

  end
end
