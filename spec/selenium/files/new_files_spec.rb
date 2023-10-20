# frozen_string_literal: true

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

require_relative "../common"
require_relative "../helpers/files_common"
require_relative "../helpers/public_courses_context"

describe "better_file_browsing" do
  include_context "in-process server selenium tests"
  include FilesCommon

  context "On user's root /files page" do
    before(:once) do
      course_with_teacher(active_all: true)
    end

    before do
      user_session @teacher
    end

    it "works in the user's root /files page, not just /courses/x/files" do
      get "/files"
      add_folder("A New Folder")
      created_folder = @teacher.folders.find_by(name: "A New Folder")
      expect(created_folder).to be_present
      add_file(fixture_file_upload("example.pdf", "application/pdf"), @user, "example.pdf", created_folder)
      fj('a.treeLabel:contains("A New Folder")').click
      wait_for_ajaximations
      expect(ff(".ef-name-col__text")[0]).to include_text "example.pdf"
    end
  end

  context "As a teacher" do
    before(:once) do
      course_with_teacher(active_all: true)
      add_file(fixture_file_upload("example.pdf", "application/pdf"),
               @course,
               "example.pdf")
    end

    before do
      user_session @teacher
    end

    it "displays new files UI", priority: "1" do
      get "/courses/#{@course.id}/files"
      expect(f(".btn-upload")).to be_displayed
      expect(all_files_folders.count).to eq 1
    end

    it "loads correct column values on uploaded file", priority: "1" do
      get "/courses/#{@course.id}/files"
      time_current = @course.attachments.first.updated_at.strftime("%l:%M%P").strip
      expect(ff(".ef-name-col__text")[0]).to include_text "example.pdf"
      expect(ff(".ef-date-created-col")[1]).to include_text time_current
      expect(ff(".ef-date-modified-col")[1]).to include_text time_current
      expect(ff(".ef-size-col")[1]).to include_text "194 KB"
    end

    context "from cog icon" do
      before do
        get "/courses/#{@course.id}/files"
      end

      it "edits file name", priority: "1" do
        expect(fln("example.pdf")).to be_present
        file_rename_to = "Example_edited.pdf"
        edit_name_from_cog_icon(file_rename_to)
        expect(f("#content")).not_to contain_link("example.pdf")
        expect(fln(file_rename_to)).to be_present
      end

      it "deletes file", priority: "1" do
        skip_if_safari(:alert)
        delete_file(0, :cog_icon)
        expect(f("body")).not_to contain_css(".ef-item-row")
      end
    end

    context "from cloud icon" do
      before do
        get "/courses/#{@course.id}/files"
      end

      it "unpublishes and publish a file", priority: "1" do
        set_item_permissions(:unpublish, :cloud_icon)
        expect(f(".btn-link.published-status.unpublished")).to be_displayed
        set_item_permissions(:publish, :cloud_icon)
        expect(f(".btn-link.published-status.published")).to be_displayed
      end

      it "makes file available to student with link", priority: "1" do
        set_item_permissions(:restricted_access, :available_with_link, :cloud_icon)
        expect(f(".btn-link.published-status.hiddenState")).to be_displayed
      end

      it "makes file available to student within given timeframe", priority: "1" do
        set_item_permissions(:restricted_access, :available_with_timeline, :cloud_icon)
        expect(f(".btn-link.published-status.restricted")).to be_displayed
      end
    end

    context "from toolbar menu" do
      it "deletes file from toolbar", priority: "1" do
        skip_if_safari(:alert)
        get "/courses/#{@course.id}/files"
        delete_file(0, :toolbar_menu)
        expect(f("body")).not_to contain_css(".ef-item-row")
      end

      it "unpublishes and publish a file", priority: "1" do
        get "/courses/#{@course.id}/files"
        set_item_permissions(:unpublish, :toolbar_menu)
        expect(f(".btn-link.published-status.unpublished")).to be_displayed
        set_item_permissions(:publish, :toolbar_menu)
        expect(f(".btn-link.published-status.published")).to be_displayed
      end

      it "makes file available to student with link from toolbar", priority: "1" do
        get "/courses/#{@course.id}/files"
        set_item_permissions(:restricted_access, :available_with_link, :toolbar_menu)
        expect(f(".btn-link.published-status.hiddenState")).to be_displayed
      end

      it "makes file available to student within given timeframe from toolbar", priority: "1" do
        get "/courses/#{@course.id}/files"
        set_item_permissions(:restricted_access, :available_with_timeline, :toolbar_menu)
        expect(f(".btn-link.published-status.restricted")).to be_displayed
      end

      it "disables the file preview button when a folder is selected" do
        folder_model(name: "Testing")
        get "/courses/#{@course.id}/files"
        fj('.ef-item-row:contains("Testing")').click
        expect(f(".Toolbar__ViewBtn--onlyfolders")).to be_displayed
      end
    end

    context "accessibility tests for preview" do
      before do
        get "/courses/#{@course.id}/files"
        fln("example.pdf").click
      end

      it "tabs through all buttons in the header button bar", priority: "1" do
        buttons = ff(".ef-file-preview-header-buttons > *")
        buttons.first.send_keys "" # focuses on the first button

        buttons.each do |button|
          check_element_has_focus(button)
          button.send_keys("\t")
        end
      end

      it "returns focus to the link that was clicked when closing with the esc key", priority: "1" do
        driver.switch_to.active_element.send_keys :escape
        check_element_has_focus(fln("example.pdf"))
      end

      it "returns focus to the link when the close button is clicked", priority: "1" do
        f(".ef-file-preview-header-close").click
        check_element_has_focus(fln("example.pdf"))
      end
    end

    context "accessibility tests for Toolbar Previews" do
      it "returns focus to the preview toolbar button when closed", priority: "1" do
        get "/courses/#{@course.id}/files"
        ff(".ef-item-row")[0].click
        f(".btn-view").click
        f(".ef-file-preview-header-close").click
        check_element_has_focus(f(".btn-view"))
      end
    end
  end

  context "when a public course is accessed" do
    include_context "public course as a logged out user"

    it "displays course files", priority: "1" do
      public_course.attachments.create!(filename: "somefile.doc", uploaded_data: StringIO.new("test"))
      get "/courses/#{public_course.id}/files"
      expect(f(".ef-main")).to be_displayed
    end
  end

  context "Search textbox" do
    before do
      course_with_teacher_logged_in
      txt_files = ["a_file.txt", "b_file.txt", "c_file.txt"]
      txt_files.map do |text_file|
        add_file(fixture_file_upload(text_file.to_s, "text/plain"), @course, text_file)
      end
      get "/courses/#{@course.id}/files"
    end

    it "searches for a file", priority: "2" do
      expect(all_files_folders).to have_size 3
      f("input[type='search']").send_keys "b_fi", :return
      expect(all_files_folders).to have_size 1
    end
  end

  context "Move dialog" do
    before(:once) do
      course_with_teacher(active_all: true)
      txt_files = ["a_file.txt", "b_file.txt", "c_file.txt"]
      txt_files.map { |text_file| add_file(fixture_file_upload(text_file.to_s, "text/plain"), @course, text_file) }
    end

    before do
      user_session(@teacher)
    end

    it "sets focus to the folder tree when opening the dialog", priority: "1" do
      get "/courses/#{@course.id}/files"
      ff(".al-trigger")[0].click
      fln("Move To...").click
      wait_for_ajaximations
      check_element_has_focus(ff(".tree")[1])
    end

    it "moves a file using cog icon", priority: "1" do
      file_name = "a_file.txt"
      folder_model(name: "destination_folder")
      get "/courses/#{@course.id}/files"
      move(file_name, 0, :cog_icon)
      expect(f("#flash_message_holder")).to include_text "#{file_name} moved to destination_folder"
      expect(ff(".ef-name-col__text")[0]).not_to include_text file_name
      ff(".ef-name-col__text")[2].click
      expect(fln(file_name)).to be_displayed
    end

    it "moves a file using toolbar menu", priority: "1" do
      file_name = "a_file.txt"
      folder_model(name: "destination_folder")
      get "/courses/#{@course.id}/files"
      move(file_name, 0, :toolbar_menu)
      expect(f("#flash_message_holder")).to include_text "#{file_name} moved to destination_folder"
      expect(ff(".ef-name-col__text")[0]).not_to include_text file_name
      ff(".ef-name-col__text")[2].click
      expect(fln(file_name)).to be_displayed
    end

    it "moves multiple files", priority: "1" do
      files = ["a_file.txt", "b_file.txt", "c_file.txt"]
      folder_model(name: "destination_folder")
      get "/courses/#{@course.id}/files"
      move_multiple_using_toolbar(files)
      expect(f("#flash_message_holder")).to include_text "#{files.count} items moved to destination_folder"
      expect(ff(".ef-name-col__text")[0]).not_to include_text files[0]
      ff(".ef-name-col__text")[0].click
      files.each do |file|
        expect(fln(file)).to be_displayed
      end
    end

    context "Search Results" do
      def search_and_move(file_name: "", destination: "My Files")
        f("input[type='search']").send_keys file_name, :return
        expect(f(".ef-item-row")).to include_text file_name
        move(file_name, 0, :cog_icon, destination)
        final_destination = destination.split("/").pop
        expect(f("#flash_message_holder")).to include_text "#{file_name} moved to #{final_destination}"
        fj("a.treeLabel span:contains('#{final_destination}')").click
        expect(fln(file_name)).to be_displayed
      end

      before(:once) do
        user_files = ["a_file.txt", "b_file.txt"]
        user_files.map { |text_file| add_file(fixture_file_upload(text_file.to_s, "text/plain"), @teacher, text_file) }
        # Course file
        add_file(fixture_file_upload("c_file.txt", "text/plain"), @course, "c_file.txt")
      end

      let(:folder_name) { "destination_folder" }

      it "moves a file to a destination if contexts are different" do
        skip_if_chrome("research")
        folder_model(name: folder_name)
        get "/files"
        search_and_move(file_name: "a_file.txt", destination: "#{@course.name}/#{folder_name}")
      end

      it "moves a file to a destination if the contexts are the same" do
        skip_if_chrome("research")
        folder_model(name: folder_name, context: @user)
        get "/files"
        search_and_move(file_name: "a_file.txt", destination: folder_name)
      end
    end
  end

  context "Publish Cloud Dialog" do
    before(:once) do
      course_with_teacher(active_all: true)
      add_file(fixture_file_upload("a_file.txt", "text/plain"),
               @course,
               "a_file.txt")
    end

    before do
      user_session(@teacher)
      get "/courses/#{@course.id}/files"
    end

    it "validates that file is published by default", priority: "1" do
      expect(f(".btn-link.published-status.published")).to be_displayed
    end

    it "sets focus to the close button when opening the dialog", priority: "1" do
      f(".btn-link.published-status").click
      wait_for_ajaximations
      should_focus = f(".ui-dialog-titlebar-close")
      element = driver.switch_to.active_element
      expect(element).to eq(should_focus)
    end
  end

  context "Preview Media Attachments" do
    before do
      course_with_teacher_logged_in
      allow_any_instance_of(MediaObject).to receive(:grants_right?).with(anything, anything, :add_captions).and_return(true)

      Account.site_admin.enable_feature!(:media_links_use_attachment_id)
      @att = Attachment.create! filename: "file.mp4", context: @course, media_entry_id: "mediaentryid", uploaded_data: stub_file_data("test.m4v", "asdf", "video/mp4")
      @mo = MediaObject.create! media_id: "mediaentryid", attachment: @att

      @bp_course = Course.create!
      @bogus_parent_att = Attachment.create! filename: "file.mp4", context: @bp_course, uploaded_data: stub_file_data("test.m4v", "asdf", "video/mp4")

      @kaltura = stub_kaltura
      expect(@kaltura).to receive(:media_sources).and_return([{ attachment_id: @att.id, content_type: "video/mp4", url: "/a.mp4" }])
    end

    it "will show CC options normally" do
      get "/courses/#{@course.id}/files/#{@att.id}/file_preview"
      wait_for_ajaximations
      expect(f('[title="Captions/Subtitles"]')).to be_present
    end

    it "shows caption inheritance tooltip" do
      @mo.media_tracks.create!(kind: "subtitles", locale: "en", content: "subs")
      @another_att = Attachment.create! filename: "file.mp4", context: @course, media_entry_id: "mediaentryid", uploaded_data: stub_file_data("test.m4v", "asdf", "video/mp4")
      get "/courses/#{@course.id}/files/#{@another_att.id}/file_preview"
      wait_for_ajaximations
      expect(f(".mejs-captions-selector .track-tip-container")).to be_present
    end

    it "will hide CC options for locked attachments" do
      mt = MasterCourses::MasterTemplate.set_as_master_course(@bp_course)
      cs = MasterCourses::ChildSubscription.create! child_course: @course, master_template: mt
      MasterCourses::ChildContentTag.create! content_type: "Attachment", content_id: @att.id, migration_id: "matchedmigid", child_subscription: cs
      mct = MasterCourses::MasterContentTag.create! master_template: mt, content: @bogus_parent_att, restrictions: { content: true }
      mct.update! migration_id: "matchedmigid"
      get "/courses/#{@course.id}/files/#{@att.id}/file_preview"
      wait_for_ajaximations
      expect(f(".mejs-controls")).not_to contain_jqcss('[title="Captions/Subtitles"]')
    end
  end

  context "File Preview" do
    before do
      course_with_teacher_logged_in
      add_file(fixture_file_upload("a_file.txt", "text/plain"),
               @course,
               "a_file.txt")
      add_file(fixture_file_upload("b_file.txt", "text/plain"),
               @course,
               "b_file.txt")
      get "/courses/#{@course.id}/files"
    end

    it "switches files in preview when clicking the arrows" do
      fln("a_file.txt").click
      ff(".ef-file-preview-container-arrow-link")[0].click
      expect(f(".ef-file-preview-header-filename")).to include_text("b_file.txt")
      ff(".ef-file-preview-container-arrow-link")[1].click
      expect(f(".ef-file-preview-header-filename")).to include_text("a_file.txt")
    end

    context "with media file" do
      before do
        stub_kaltura
      end

      it "works in the user's files page" do
        file = add_file(fixture_file_upload("292.mp3", "audio/mpeg"), @teacher, "292.mp3")
        get "/files?preview=#{file.id}"
        wait_for_ajaximations
        driver.switch_to.frame(ff(".ef-file-preview-frame")[0])
        expect(ff("#media_preview")[0]).to include_text("Media has been queued for conversion, please try again in a little bit.")
      end

      it "works in the course's files page" do
        file = add_file(fixture_file_upload("292.mp3", "audio/mpeg"), @course, "292.mp3")
        get "/courses/#{@course.id}/files?preview=#{file.id}"
        wait_for_ajaximations
        driver.switch_to.frame(ff(".ef-file-preview-frame")[0])
        expect(ff("#media_preview")[0]).to include_text("Media has been queued for conversion, please try again in a little bit.")
      end
    end
  end

  context "Usage Rights Dialog" do
    def set_usage_rights_in_modal(rights = "creative_commons")
      set_value f(".UsageRightsSelectBox__select"), rights
      if rights == "creative_commons"
        set_value f(".UsageRightsSelectBox__creativeCommons"), "cc_by"
      end
      set_value f("#copyrightHolder"), "Test User"
      f('.UsageRightsDialog__Footer-Actions button[type="submit"]').click
      expect(f("body")).not_to contain_css(".UsageRightsDialog__Content")
    end

    def verify_usage_rights_ui_updates(iconClass = "icon-files-creative-commons")
      expect(f(".UsageRightsIndicator__openModal i.#{iconClass}")).to be_displayed
    end

    before :once do
      course_with_teacher(active_all: true)
      @course.usage_rights_required = true
      @course.save!
      add_file(fixture_file_upload("a_file.txt", "text/plan"),
               @course,
               "a_file.txt")
      add_file(fixture_file_upload("amazing_file.txt", "text/plan"),
               @user,
               "amazing_file.txt")
      add_file(fixture_file_upload("a_file.txt", "text/plan"),
               @user,
               "a_file.txt")
    end

    before do
      user_session @teacher
    end

    context "course files" do
      it "sets usage rights on a file via the modal by clicking the indicator", priority: "1" do
        get "/courses/#{@course.id}/files"
        f(".UsageRightsIndicator__openModal").click
        set_usage_rights_in_modal
        # a11y: focus should go back to the element that was clicked.
        check_element_has_focus(f(".UsageRightsIndicator__openModal"))
        verify_usage_rights_ui_updates
      end

      it "sets usage rights on a file via the cog menu", priority: "1" do
        get "/courses/#{@course.id}/files"
        f(".ef-links-col .al-trigger").click
        f(".ItemCog__OpenUsageRights a").click
        set_usage_rights_in_modal
        # a11y: focus should go back to the element that was clicked.
        check_element_has_focus(f(".ef-links-col .al-trigger"))
        verify_usage_rights_ui_updates
      end

      it "sets usage rights on a file via the toolbar", priority: "1" do
        get "/courses/#{@course.id}/files"
        f(".ef-item-row").click
        f(".Toolbar__ManageUsageRights").click
        set_usage_rights_in_modal
        # a11y: focus should go back to the element that was clicked.
        check_element_has_focus(f(".Toolbar__ManageUsageRights"))
        verify_usage_rights_ui_updates
      end

      it "sets usage rights on a file inside a folder via the toolbar", priority: "1" do
        folder_model name: "new folder"
        get "/courses/#{@course.id}/files"
        move("a_file.txt", 0, :cog_icon)
        wait_for_ajaximations
        f(".ef-item-row").click
        f(".Toolbar__ManageUsageRights").click
        expect(f(".UsageRightsDialog__fileName")).to include_text "new folder"
        expect(f(".UsageRightsSelectBox__select")).to be_displayed
        set_usage_rights_in_modal
        # a11y: focus should go back to the element that was clicked.
        check_element_has_focus(f(".Toolbar__ManageUsageRights"))
        ff(".ef-name-col__text")[0].click
        verify_usage_rights_ui_updates
      end

      it "does not show the creative commons selection if creative commons isn't selected", priority: "1" do
        get "/courses/#{@course.id}/files"
        f(".UsageRightsIndicator__openModal").click
        set_value f(".UsageRightsSelectBox__select"), "fair_use"
        expect(f(".UsageRightsSelectBox__container")).not_to contain_css(".UsageRightsSelectBox__creativeCommons")
      end

      it "publishes warning when usage rights is not selected", priority: "2" do
        get "/courses/#{@course.id}/files"
        expect(f(".icon-warning")).to be_present
        f(".icon-publish").click
        f(".form-controls .btn-primary").click
        expect(f(".errorBox")).to be_present
      end
    end

    context "user files" do
      it "updates course files from user files page", priority: "1" do
        get "/files/folder/courses_#{@course.id}/"
        f(".UsageRightsIndicator__openModal").click
        set_usage_rights_in_modal
        # a11y: focus should go back to the element that was clicked.
        check_element_has_focus(f(".UsageRightsIndicator__openModal"))
        verify_usage_rights_ui_updates
      end

      it "copies a file to a different context", priority: "1" do
        get "/files/"
        file_name = "amazing_file.txt"
        move(file_name, 1, :cog_icon)
        expect(f("#flash_message_holder")).to include_text "#{file_name} moved to course files"
        expect(ff(".ef-name-col__text")[1]).to include_text file_name
      end

      it "shows modal on how to handle duplicates when copying files", priority: "1" do
        get "/files/"
        file_name = "a_file.txt"
        move(file_name, 0, :cog_icon)
        expect(f("#renameFileMessage")).to include_text "An item named \"#{file_name}\" already exists in this location. Do you want to replace the existing file?"
        ff(".btn-primary")[2].click
        expect(f("#flash_message_holder")).to include_text "#{file_name} moved to course files"
        expect(ff(".ef-name-col__text")[0]).to include_text file_name
      end
    end
  end

  context "When Require Usage Rights is turned-off" do
    it "sets files to published by default", priority: "1" do
      course_with_teacher_logged_in
      @course.usage_rights_required = true
      @course.save!
      add_file(fixture_file_upload("b_file.txt", "text/plain"), @course, "b_file.txt")

      get "/courses/#{@course.id}/files"
      expect(f(".btn-link.published-status.published")).to be_displayed
    end
  end

  context "Directory Header" do
    it "sorts the files properly", priority: 2 do
      # this test performs 2 sample sort combinations
      course_with_teacher_logged_in

      add_file(fixture_file_upload("example.pdf", "application/pdf"), @course, "a_example.pdf")
      add_file(fixture_file_upload("b_file.txt", "text/plain"), @course, "b_file.txt")

      get "/courses/#{@course.id}/files"

      # click name once to make it sort descending
      fj('.ef-plain-link span:contains("Name")').click
      expect(ff(".ef-name-col__text")[0]).to include_text "example.pdf"
      expect(ff(".ef-name-col__text")[1]).to include_text "b_file.txt"

      # click size twice to make it sort ascending
      2.times { fj('.ef-plain-link span:contains("Size")').click }
      expect(ff(".ef-name-col__text")[0]).to include_text "b_file.txt"
      expect(ff(".ef-name-col__text")[1]).to include_text "example.pdf"
    end

    it "url-encodes sort header links" do
      course_with_teacher_logged_in
      Folder.root_folders(@course).first.sub_folders.create!(name: "eh?", context: @course)
      get "/courses/#{@course.id}/files/folder/eh%3F"
      expect(ff(".ef-plain-link").first.attribute("href")).to include "/files/folder/eh%3F?sort"
    end
  end
end
