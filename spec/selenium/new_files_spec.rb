#
# Copyright (C) 2015 - present Instructure, Inc.
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
#

require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/files_common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/public_courses_context')

describe "better_file_browsing" do
  include_context "in-process server selenium tests"
  include FilesCommon

  context "As a teacher" do
    before(:once) do
      course_with_teacher(active_all: true)
      add_file(fixture_file_upload('files/example.pdf', 'application/pdf'),
               @course, "example.pdf")
    end

    before(:each) do
      user_session @teacher
    end

    it "should display new files UI", priority: "1", test_id: 133092 do
      get "/courses/#{@course.id}/files"
      expect(f('.btn-upload')).to be_displayed
      expect(all_files_folders.count).to eq 1
    end

    it "should load correct column values on uploaded file", priority: "1", test_id: 133129 do
      get "/courses/#{@course.id}/files"
      time_current = @course.attachments.first.updated_at.strftime("%l:%M%P").strip
      expect(ff('.ef-name-col__text')[0]).to include_text 'example.pdf'
      expect(ff('.ef-date-created-col')[1]).to include_text time_current
      expect(ff('.ef-date-modified-col')[1]).to include_text time_current
      expect(ff('.ef-size-col')[1]).to include_text '194 KB'
    end

    context "from cog icon" do
      before :each do
        get "/courses/#{@course.id}/files"
      end

      it "should edit file name", priority: "1", test_id: 133127 do
        expect(fln("example.pdf")).to be_present
        file_rename_to = "Example_edited.pdf"
        edit_name_from_cog_icon(file_rename_to)
        expect(f("#content")).not_to contain_link("example.pdf")
        expect(fln(file_rename_to)).to be_present
      end

      it "should delete file", priority: "1", test_id: 133128 do
        skip_if_safari(:alert)
        delete(0, :cog_icon)
        expect(f("body")).not_to contain_css('.ef-item-row')
      end
    end

    context "from cloud icon" do
      before :each do
        get "/courses/#{@course.id}/files"
      end

      it "should unpublish and publish a file", priority: "1", test_id: 133096 do
        set_item_permissions(:unpublish, :cloud_icon)
        expect(f('.btn-link.published-status.unpublished')).to be_displayed
        set_item_permissions(:publish, :cloud_icon)
        expect(f('.btn-link.published-status.published')).to be_displayed
      end

      it "should make file available to student with link", priority: "1", test_id: 223504 do
        set_item_permissions(:restricted_access, :available_with_link, :cloud_icon)
        expect(f('.btn-link.published-status.hiddenState')).to be_displayed
      end

      it "should make file available to student within given timeframe", priority: "1", test_id: 223505 do
        set_item_permissions(:restricted_access, :available_with_timeline, :cloud_icon)
        expect(f('.btn-link.published-status.restricted')).to be_displayed
      end
    end

    context "from toolbar menu" do
      it "should delete file from toolbar", priority: "1", test_id: 133105 do
        skip_if_safari(:alert)
        get "/courses/#{@course.id}/files"
        delete(0, :toolbar_menu)
        expect(f("body")).not_to contain_css('.ef-item-row')
      end

      it "should unpublish and publish a file", priority: "1", test_id: 223503 do
        get "/courses/#{@course.id}/files"
        set_item_permissions(:unpublish, :toolbar_menu)
        expect(f('.btn-link.published-status.unpublished')).to be_displayed
        set_item_permissions(:publish, :toolbar_menu)
        expect(f('.btn-link.published-status.published')).to be_displayed
      end

      it "should make file available to student with link from toolbar", priority: "1", test_id: 193158 do
        get "/courses/#{@course.id}/files"
        set_item_permissions(:restricted_access, :available_with_link, :toolbar_menu)
        expect(f('.btn-link.published-status.hiddenState')).to be_displayed
      end

      it "should make file available to student within given timeframe from toolbar", priority: "1", test_id: 193159 do
        get "/courses/#{@course.id}/files"
        set_item_permissions(:restricted_access, :available_with_timeline, :toolbar_menu)
        expect(f('.btn-link.published-status.restricted')).to be_displayed
      end

      it "should disable the file preview button when a folder is selected" do
        folder_model(name: 'Testing')
        get "/courses/#{@course.id}/files"
        fj('.ef-item-row:contains("Testing")').click
        expect(f('.Toolbar__ViewBtn--onlyfolders')).to be_displayed
      end
    end

    context "accessibility tests for preview" do
      before do
        get "/courses/#{@course.id}/files"
        fln("example.pdf").click
      end

      it "tabs through all buttons in the header button bar", priority: "1", test_id: 193816 do
        buttons = ff('.ef-file-preview-header-buttons > *')
        driver.execute_script("$('.ef-file-preview-header-buttons').children().first().focus()")
        buttons.each do |button|
          check_element_has_focus(button)
          button.send_keys("\t")
        end
      end

      it "returns focus to the link that was clicked when closing with the esc key", priority: "1", test_id: 193817 do
        driver.switch_to.active_element.send_keys :escape
        check_element_has_focus(fln("example.pdf"))
      end

      it "returns focus to the link when the close button is clicked", priority: "1", test_id: 193818 do
        f('.ef-file-preview-header-close').click
        check_element_has_focus(fln("example.pdf"))
      end
    end

    context "accessibility tests for Toolbar Previews" do
      it "returns focus to the preview toolbar button when closed", priority: "1", test_id: 193819 do
        get "/courses/#{@course.id}/files"
        ff('.ef-item-row')[0].click
        f('.btn-view').click
        f('.ef-file-preview-header-close').click
        check_element_has_focus(f('.btn-view'))
      end
    end
  end

  context "when a public course is accessed" do
    include_context "public course as a logged out user"

    it "should display course files", priority: "1", test_id: 270032 do
      get "/courses/#{public_course.id}/files"
      expect(f('.ef-main')).to be_displayed
    end
  end

  context "Search textbox" do
    before(:each) do
      course_with_teacher_logged_in
      txt_files = ["a_file.txt", "b_file.txt", "c_file.txt"]
      txt_files.map do |text_file|
        add_file(fixture_file_upload("files/#{text_file}", 'text/plain'), @course, text_file)
      end
      get "/courses/#{@course.id}/files"
    end

    it "should search for a file", priority: "2", test_id: 220355 do
      expect(all_files_folders).to have_size 3
      f("input[type='search']").send_keys "b_fi", :return
      expect(all_files_folders).to have_size 1
    end
  end

  context "Move dialog" do
    before(:once) do
      course_with_teacher(active_all: true)
      txt_files = ["a_file.txt", "b_file.txt", "c_file.txt"]
      txt_files.map { |text_file| add_file(fixture_file_upload("files/#{text_file}", 'text/plain'), @course, text_file) }
    end

    before(:each) do
      user_session(@teacher)
    end

    it "should set focus to the folder tree when opening the dialog", priority: "1", test_id: 220356 do
      get "/courses/#{@course.id}/files"
      ff('.al-trigger')[0].click
      fln("Move").click
      wait_for_ajaximations
      check_element_has_focus(ff('.tree')[1])
    end

    it "should move a file using cog icon", priority: "1", test_id: 133103 do
      file_name = "a_file.txt"
      folder_model(name: "destination_folder")
      get "/courses/#{@course.id}/files"
      move(file_name, 0, :cog_icon)
      expect(f("#flash_message_holder")).to include_text "#{file_name} moved to destination_folder"
      expect(ff('.ef-name-col__text')[0]).not_to include_text file_name
      ff('.ef-name-col__text')[2].click
      expect(fln(file_name)).to be_displayed
    end

    it "should move a file using toolbar menu", priority: "1", test_id: 217603 do
      file_name = "a_file.txt"
      folder_model(name: "destination_folder")
      get "/courses/#{@course.id}/files"
      move(file_name, 0, :toolbar_menu)
      expect(f("#flash_message_holder")).to include_text "#{file_name} moved to destination_folder"
      expect(ff('.ef-name-col__text')[0]).not_to include_text file_name
      ff('.ef-name-col__text')[2].click
      expect(fln(file_name)).to be_displayed
    end

    it "should move multiple files", priority: "1", test_id: 220357 do
      files = ["a_file.txt", "b_file.txt", "c_file.txt"]
      folder_model(name: "destination_folder")
      get "/courses/#{@course.id}/files"
      move_multiple_using_toolbar(files)
      expect(f("#flash_message_holder")).to include_text "#{files.count} items moved to destination_folder"
      expect(ff('.ef-name-col__text')[0]).not_to include_text files[0]
      ff('.ef-name-col__text')[0].click
      files.each do |file|
        expect(fln(file)).to be_displayed
      end
    end

    context "Search Results" do
      def search_and_move(file_name: "", destination: "My Files")
        f("input[type='search']").send_keys file_name, :return
        expect(f('.ef-item-row')).to include_text file_name
        move(file_name, 0, :cog_icon, destination)
        final_destination = destination.split('/').pop
        expect(f("#flash_message_holder")).to include_text "#{file_name} moved to #{final_destination}"
        fj("a.treeLabel span:contains('#{final_destination}')").click
        expect(fln(file_name)).to be_displayed
      end

      before(:once) do
        user_files = ["a_file.txt", "b_file.txt"]
        user_files.map { |text_file| add_file(fixture_file_upload("files/#{text_file}", 'text/plain'), @teacher, text_file) }
        # Course file
        add_file(fixture_file_upload("files/c_file.txt", 'text/plain'), @course, "c_file.txt")
      end

      let(:folder_name) { "destination_folder" }

      it "should move a file to a destination if contexts are different" do
        skip_if_chrome('research')
        folder_model(name: folder_name)
        get "/files"
        search_and_move(file_name: "a_file.txt", destination: "#{@course.name}/#{folder_name}")
      end

      it "should move a file to a destination if the contexts are the same" do
        skip_if_chrome('research')
        folder_model(name: folder_name, context: @user)
        get "/files"
        search_and_move(file_name: "a_file.txt", destination: folder_name)
      end
    end
  end

  context "Publish Cloud Dialog" do
    before(:once) do
      course_with_teacher(active_all: true)
      add_file(fixture_file_upload('files/a_file.txt', 'text/plain'),
               @course, "a_file.txt")
    end

    before(:each) do
      user_session(@teacher)
      get "/courses/#{@course.id}/files"
    end

    it "should validate that file is published by default", priority: "1", test_id: 193820 do
      expect(f('.btn-link.published-status.published')).to be_displayed
    end

    it "should set focus to the close button when opening the dialog", priority: "1", test_id: 194243 do
      f('.btn-link.published-status').click
      wait_for_ajaximations
      shouldFocus = f('.ui-dialog-titlebar-close')
      element = driver.switch_to.active_element
      expect(element).to eq(shouldFocus)
    end
  end

  context "File Preview" do
    before(:each) do
      course_with_teacher_logged_in
      add_file(fixture_file_upload('files/a_file.txt', 'text/plain'),
               @course, "a_file.txt")
      add_file(fixture_file_upload('files/b_file.txt', 'text/plain'),
               @course, "b_file.txt")
      get "/courses/#{@course.id}/files"
    end

    it "should switch files in preview when clicking the arrows" do
      fln("a_file.txt").click
      ff('.ef-file-preview-container-arrow-link')[0].click
      expect(f('.ef-file-preview-header-filename')).to include_text('b_file.txt')
      ff('.ef-file-preview-container-arrow-link')[1].click
      expect(f('.ef-file-preview-header-filename')).to include_text('a_file.txt')
    end
  end

  context "Usage Rights Dialog" do
    def set_usage_rights_in_modal(rights = 'creative_commons')
      set_value f('.UsageRightsSelectBox__select'), rights
      if rights == 'creative_commons'
        set_value f('.UsageRightsSelectBox__creativeCommons'), 'cc_by'
      end
      set_value f('#copyrightHolder'), 'Test User'
      f('.ReactModal__Footer-Actions .btn-primary').click
      expect(f("body")).not_to contain_css('.ReactModal__Content')
    end

    def verify_usage_rights_ui_updates(iconClass = 'icon-files-creative-commons')
      expect(f(".UsageRightsIndicator__openModal i.#{iconClass}")).to be_displayed
    end

    before :once do
      course_with_teacher(active_all: true)
      Account.default.enable_feature!(:usage_rights_required)
      add_file(fixture_file_upload('files/a_file.txt', 'text/plan'),
               @course, "a_file.txt")
      add_file(fixture_file_upload('files/amazing_file.txt', 'text/plan'),
               @user, "amazing_file.txt")
      add_file(fixture_file_upload('files/a_file.txt', 'text/plan'),
               @user, "a_file.txt")
    end

    before :each do
      user_session @teacher
    end

    context "course files" do
      it "should set usage rights on a file via the modal by clicking the indicator", priority: "1", test_id: 194244 do
        get "/courses/#{@course.id}/files"
        f('.UsageRightsIndicator__openModal').click
        set_usage_rights_in_modal
        # a11y: focus should go back to the element that was clicked.
        check_element_has_focus(f('.UsageRightsIndicator__openModal'))
        verify_usage_rights_ui_updates
      end

      it "should set usage rights on a file via the cog menu", priority: "1", test_id: 194245 do
        get "/courses/#{@course.id}/files"
        f('.ef-links-col .al-trigger').click
        f('.ItemCog__OpenUsageRights a').click
        set_usage_rights_in_modal
        # a11y: focus should go back to the element that was clicked.
        check_element_has_focus(f('.ef-links-col .al-trigger'))
        verify_usage_rights_ui_updates
      end

      it "should set usage rights on a file via the toolbar", priority: "1", test_id: 132584 do
        get "/courses/#{@course.id}/files"
        f('.ef-item-row').click
        f('.Toolbar__ManageUsageRights').click
        set_usage_rights_in_modal
        # a11y: focus should go back to the element that was clicked.
        check_element_has_focus(f('.Toolbar__ManageUsageRights'))
        verify_usage_rights_ui_updates
      end

      it "should set usage rights on a file inside a folder via the toolbar", priority: "1", test_id: 132585 do
        folder_model name: "new folder"
        get "/courses/#{@course.id}/files"
        move("a_file.txt", 0, :cog_icon)
        wait_for_ajaximations
        f('.ef-item-row').click
        f('.Toolbar__ManageUsageRights').click
        expect(f('.UsageRightsDialog__fileName')).to include_text "new folder"
        expect(f(".UsageRightsSelectBox__select")).to be_displayed
        set_usage_rights_in_modal
        # a11y: focus should go back to the element that was clicked.
        check_element_has_focus(f('.Toolbar__ManageUsageRights'))
        ff('.ef-name-col__text')[0].click
        verify_usage_rights_ui_updates
      end

      it "should not show the creative commons selection if creative commons isn't selected", priority: "1", test_id: 194247 do
        get "/courses/#{@course.id}/files"
        f('.UsageRightsIndicator__openModal').click
        set_value f('.UsageRightsSelectBox__select'), 'fair_use'
        expect(f('.UsageRightsSelectBox__container')).not_to contain_css('.UsageRightsSelectBox__creativeCommons')
      end

      it "should publish warning when usage rights is not selected", priority: "2", test_id: 133135 do
        get "/courses/#{@course.id}/files"
        expect(f('.icon-warning')).to be_present
        f('.icon-publish').click
        f('.form-controls .btn-primary').click
        expect(f('.errorBox')).to be_present
      end
    end

    context "user files" do
      it "should update course files from user files page", priority: "1", test_id: 194248 do
        get "/files/folder/courses_#{@course.id}/"
        f('.UsageRightsIndicator__openModal').click
        set_usage_rights_in_modal
        # a11y: focus should go back to the element that was clicked.
        check_element_has_focus(f('.UsageRightsIndicator__openModal'))
        verify_usage_rights_ui_updates
      end

      it "should copy a file to a different context", priority: "1", test_id: 194249 do
        get "/files/"
        file_name = "amazing_file.txt"
        move(file_name, 1, :cog_icon)
        expect(f("#flash_message_holder")).to include_text "#{file_name} moved to course files"
        expect(ff('.ef-name-col__text')[1]).to include_text file_name
      end

      it "should show modal on how to handle duplicates when copying files", priority: "1", test_id: 194250 do
        get "/files/"
        file_name = "a_file.txt"
        move(file_name, 0, :cog_icon)
        expect(f("#renameFileMessage")).to include_text "An item named \"#{file_name}\" already exists in this location. Do you want to replace the existing file?"
        ff(".btn-primary")[2].click
        expect(f("#flash_message_holder")).to include_text "#{file_name} moved to course files"
        expect(ff('.ef-name-col__text')[0]).to include_text file_name
      end
    end
  end

  context "When Require Usage Rights is turned-off" do
    it "sets files to published by default", priority: "1", test_id: 133136 do
      course_with_teacher_logged_in
      Account.default.disable_feature!(:usage_rights_required)
      add_file(fixture_file_upload("files/b_file.txt", 'text/plain'), @course, 'b_file.txt')

      get "/courses/#{@course.id}/files"
      expect(f('.btn-link.published-status.published')).to be_displayed
    end
  end

  context "Directory Header" do
    it "should sort the files properly", priority: 2, test_id: 1664875 do
      # this test performs 2 sample sort combinations
      course_with_teacher_logged_in

      add_file(fixture_file_upload('files/example.pdf', 'application/pdf'), @course, "a_example.pdf")
      add_file(fixture_file_upload("files/b_file.txt", 'text/plain'), @course, 'b_file.txt')

      get "/courses/#{@course.id}/files"

      # click name once to make it sort descending
      fj('.ef-plain-link span:contains("Name")').click
      expect(ff('.ef-name-col__text')[0]).to include_text 'example.pdf'
      expect(ff('.ef-name-col__text')[1]).to include_text 'b_file.txt'

      # click size twice to make it sort ascending
      2.times { fj('.ef-plain-link span:contains("Size")').click }
      expect(ff('.ef-name-col__text')[0]).to include_text 'b_file.txt'
      expect(ff('.ef-name-col__text')[1]).to include_text 'example.pdf'
    end

    it "url-encodes sort header links" do
      course_with_teacher_logged_in
      folder = Folder.root_folders(@course).first.sub_folders.create!(name: 'eh?', context: @course)
      get "/courses/#{@course.id}/files/folder/eh%3F"
      expect(ff('.ef-plain-link').first.attribute('href')).to include '/files/folder/eh%3F?sort'
    end
  end
end
