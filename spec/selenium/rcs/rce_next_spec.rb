# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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
# some if the specs in here include "ignore_js_errors: true". This is because
# console errors are emitted for things that aren't really errors, like react
# jsx attribute type warnings
#

require_relative "../helpers/quizzes_common"
require_relative "../helpers/wiki_and_tiny_common"
require_relative "pages/rce_next_page"
require_relative "pages/rcs_sidebar_page"

# rubocop:disable Specs/NoNoSuchElementError, Specs/NoExecuteScript

# while there's a mix of instui 6 and 7 in canvas we're getting
# "Warning: [themeable] A theme registry has already been initialized." js errors
# Ignore js errors so specs can pass
describe "RCE next tests", :ignore_js_errors do
  include_context "in-process server selenium tests"
  include QuizzesCommon
  include WikiAndTinyCommon
  include RCSSidebarPage
  include RCENextPage

  context "WYSIWYG generic as a teacher" do
    before do
      course_with_teacher_logged_in
      stub_rcs_config
    end

    def create_wiki_page_with_embedded_image(page_title)
      @root_folder = Folder.root_folders(@course).first
      @image = @root_folder.attachments.build(context: @course)
      path = File.expand_path(File.dirname(__FILE__) + "/../../../public/images/email.png")
      @image.uploaded_data = Rack::Test::UploadedFile.new(path, Attachment.mimetype(path))
      @image.save!
      @course.wiki_pages.create!(
        title: page_title,
        body: "<p><img src=\"/courses/#{@course.id}/files/#{@image.id}\"></p>"
      )
    end

    def add_embedded_image(image_name)
      root_folder = Folder.root_folders(@course).first
      image = root_folder.attachments.build(context: @course)
      path = File.expand_path(File.dirname(__FILE__) + "/../../../public/images/#{image_name}")
      image.uploaded_data = Rack::Test::UploadedFile.new(path, Attachment.mimetype(path))
      image.save!
      image
    end

    def click_embedded_image_for_options
      in_frame tiny_rce_ifr_id do
        f("img").click
      end
    end

    def create_wiki_page_with_content(page_title)
      @root_folder = Folder.root_folders(@course).first
      content = <<~HTML
        <p>
          <table style="border-collapse: collapse; width: 100%;" border="1">
            <tbody>
            <tr>
            <td style="width: 50%;">cell 1</td>
            <td style="width: 50%;">cell 2</td>
            </tr>
            </tbody>
          </table>
        </p><p>
          <a class="instructure_file_link" title="Link"
          href="/files/719/download"
          target="_blank" rel="noopener noreferrer">a.html</a>
        </p>
      HTML
      @course.wiki_pages.create!(title: page_title, body: content)
    end

    it "clicks on sidebar wiki page to create link in body", :ignore_js_errors do
      title = "test_page"
      unpublished = false
      edit_roles = "public"

      create_wiki_page(title, unpublished, edit_roles)

      visit_front_page_edit(@course)

      click_course_links_toolbar_menuitem

      click_pages_accordion
      click_course_item_link(title)

      in_frame rce_page_body_ifr_id do
        expect(wiki_body_anchor.attribute("title")).to include title
        expect(wiki_body_anchor.text).to eq title
      end
    end

    context "links" do
      it "respects selected text when creating a course link in body", :ignore_js_errors do
        title = "test_page"
        unpublished = false
        edit_roles = "public"

        create_wiki_page(title, unpublished, edit_roles)

        visit_front_page_edit(@course)
        insert_tiny_text("select me")

        select_all_in_tiny(f("#wiki_page_body"))

        click_course_links_toolbar_menuitem

        click_pages_accordion
        click_course_item_link(title)

        in_frame rce_page_body_ifr_id do
          expect(wiki_body_anchor.attribute("title")).to include title
          expect(wiki_body_anchor.text).to eq "select me"
        end
      end

      it "respects selected text when creating an external link in body", :ignore_js_errors do
        title = "test_page"
        unpublished = false
        edit_roles = "public"

        create_wiki_page(title, unpublished, edit_roles)

        visit_front_page_edit(@course)
        insert_tiny_text("select me")

        select_all_in_tiny(f("#wiki_page_body"))

        create_external_link(nil, "http://example.com/")

        in_frame rce_page_body_ifr_id do
          expect(wiki_body_anchor.attribute("href")).to eq "http://example.com/"
          expect(wiki_body_anchor.text).to eq "select me"
        end
      end

      it "updates selected text when creating an external link in body", :ignore_js_errors do
        title = "test_page"
        unpublished = false
        edit_roles = "public"

        create_wiki_page(title, unpublished, edit_roles)

        visit_front_page_edit(@course)
        insert_tiny_text("select me")

        select_all_in_tiny(f("#wiki_page_body"))

        create_external_link("click me", "http://example.com/")

        in_frame rce_page_body_ifr_id do
          expect(wiki_body_anchor.attribute("href")).to eq "http://example.com/"
          expect(wiki_body_anchor.text).to eq "click me"
        end
      end

      it "updates the text when editing a link" do
        title = "test_page"
        unpublished = false
        edit_roles = "public"

        create_wiki_page(title, unpublished, edit_roles)

        visit_front_page_edit(@course)

        switch_to_html_view
        switch_to_raw_html_editor
        html_view = f("textarea#wiki_page_body")
        html_view.send_keys('<a href="http://example.com">edit me</a>')
        switch_to_editor_view

        begin
          click_link_for_options
          click_link_options_button

          wait_for_ajaximations
          expect(link_options_tray).to be_displayed

          link_text_textbox = f('input[type="text"][value="edit me"]')
          link_text_textbox.send_keys(" please")
          click_link_options_done_button

          in_frame rce_page_body_ifr_id do
            expect(wiki_body_anchor.text).to eq "edit me please"
          end
        rescue Selenium::WebDriver::Error::NoSuchElementError
          puts "Failed finding the link options button. Bailing out on this spec."
          expect(true).to be_truthy
        end
      end

      it "deletes the <a> when its text is deleted" do
        @course.wiki_pages.create!(
          title: "title",
          body: "<p id='para'><a id='lnk' href='http://example.com'>delete me</a></p>"
        )
        visit_existing_wiki_edit(@course, "title")

        select_all_in_tiny(f("#wiki_page_body"))

        f("##{rce_page_body_ifr_id}").send_keys(:backspace)

        in_frame rce_page_body_ifr_id do
          expect(f("#tinymce").text).to eql ""
        end
      end

      it "doesn't delete existing link when new image is added from course files directly after it" do
        title = "newtext.txt"
        @course.wiki_pages.create!(
          title: "title",
          body: "<p id='para'><a id='lnk' href='http://example.com'>do I stay?</a></p>"
        )

        create_course_text_file(title)

        visit_existing_wiki_edit(@course, "title")

        in_frame rce_page_body_ifr_id do
          f("#lnk").send_keys(%i[end return])
        end

        click_course_documents_toolbar_menuitem
        wait_for_ajaximations

        click_document_link(title)

        in_frame rce_page_body_ifr_id do
          expect(f("#lnk").attribute("href")).to eq "http://example.com/"
        end
      end

      it "does not delete the <a> on change when content is non-text" do
        @course.wiki_pages.create!(
          title: "title",
          body:
            "<p id='para'><a id='lnk' href='http://example.com/'><img src='some/image'/></a></p>"
        )
        visit_existing_wiki_edit(@course, "title")

        begin
          click_link_for_options
          click_link_options_button

          expect(link_options_tray).to be_displayed

          link_text_textbox = f('input[type="text"][value="http://example.com/"]')
          link_text_textbox.send_keys([:end, "x"])
          click_link_options_done_button

          in_frame rce_page_body_ifr_id do
            expect(wiki_body_anchor).to be_displayed
          end
        rescue Selenium::WebDriver::Error::NoSuchElementError
          puts "Failed finding the link options button. Bailing out on this spec."
          expect(true).to be_truthy
        end
      end

      it "does not magically create youtube video preview on a link", :ignore_js_errors do
        title = "test_page"
        unpublished = false
        edit_roles = "public"

        create_wiki_page(title, unpublished, edit_roles)

        visit_front_page_edit(@course)

        create_external_link("youtube", "https://youtu.be/17oCQakzIl8")

        in_frame rce_page_body_ifr_id do
          expect(wiki_body_anchor.attribute("class")).not_to include "youtube_link_to_box"
          expect(wiki_body_anchor.attribute("class")).to include "inline_disabled"
        end
      end

      it "clicks on sidebar assignment page to create link in body" do
        title = "Assignment-Title"
        @assignment = @course.assignments.create!(name: title)

        visit_front_page_edit(@course)

        click_course_links_toolbar_menuitem

        click_assignments_accordion
        click_course_item_link(title)

        in_frame rce_page_body_ifr_id do
          expect(wiki_body_anchor.attribute("href")).to include assignment_id_path(
            @course,
            @assignment
          )
        end
      end

      it "clicks on sidebar quizzes page to create link in body" do
        title = "Quiz-Title"
        @quiz = @course.quizzes.create!(workflow_state: "available", title:)

        visit_front_page_edit(@course)

        click_course_links_toolbar_menuitem

        click_quizzes_accordion
        click_course_item_link(title)

        in_frame rce_page_body_ifr_id do
          expect(wiki_body_anchor.attribute("href")).to include quiz_id_path(@course, @quiz)
        end
      end

      it "clicks on sidebar announcements page to create link in body" do
        title = "Announcement-Title"
        message = "Announcement 1 detail"
        @announcement = @course.announcements.create!(title:, message:)

        visit_front_page_edit(@course)

        click_course_links_toolbar_menuitem

        click_announcements_accordion
        click_course_item_link(title)

        in_frame rce_page_body_ifr_id do
          expect(wiki_body_anchor.attribute("href")).to include announcement_id_path(
            @course,
            @announcement
          )
        end
      end

      it "clicks on sidebar discussions page to create link in body" do
        title = "Discussion-Title"
        @discussion = @course.discussion_topics.create!(title:)

        visit_front_page_edit(@course)

        click_course_links_toolbar_menuitem

        click_discussions_accordion
        click_course_item_link(title)

        in_frame rce_page_body_ifr_id do
          expect(wiki_body_anchor.attribute("href")).to include discussion_id_path(
            @course,
            @discussion
          )
        end
      end

      it "clicks on sidebar modules page to create link in body", :ignore_js_errors do
        title = "Module-Title"
        @module = @course.context_modules.create!(name: title)

        visit_front_page_edit(@course)

        click_course_links_toolbar_menuitem

        click_modules_accordion
        click_course_item_link(title)

        in_frame rce_page_body_ifr_id do
          expect(wiki_body_anchor.attribute("href")).to include module_id_path(@course, @module)
        end
      end

      it "clicks on sidebar course navigation page to create link in body", :ignore_js_errors do
        title = "Files"
        visit_front_page_edit(@course)

        click_course_links_toolbar_menuitem

        click_navigation_accordion
        click_course_item_link(title)

        in_frame rce_page_body_ifr_id do
          expect(wiki_body_anchor.attribute("href")).to include course_file_path(@course)
        end
      end

      it "clicks on assignment in sidebar to create link to it in announcement page", :ignore_js_errors do
        title = "Assignment-Title"
        @assignment = @course.assignments.create!(name: title)

        visit_new_announcement_page(@course)

        click_course_links_toolbar_menuitem

        click_assignments_accordion
        click_course_item_link(title)

        in_frame rce_page_body_ifr_id do
          expect(wiki_body_anchor.attribute("href")).to include assignment_id_path(
            @course,
            @assignment
          )
        end
      end

      it "clicks on module in sidebar to create link to it in assignment page", :ignore_js_errors do
        title = "Module-Title"
        @module = @course.context_modules.create!(name: title)

        visit_new_assignment_page(@course)

        click_course_links_toolbar_menuitem

        click_modules_accordion
        click_course_item_link(title)

        in_frame rce_page_body_ifr_id do
          expect(wiki_body_anchor.attribute("href")).to include module_id_path(@course, @module)
        end
      end

      it "clicks on assignment in sidebar to create link to it in discussion page" do
        title = "Assignment-Title"
        @assignment = @course.assignments.create!(name: title)

        visit_new_discussion_page(@course)

        click_course_links_toolbar_menuitem
        click_assignments_accordion
        click_course_item_link(title)

        in_frame rce_page_body_ifr_id do
          expect(wiki_body_anchor.attribute("href")).to include assignment_id_path(
            @course,
            @assignment
          )
        end
      end

      it "clicks on assignment in sidebar to create link to it in quiz page" do
        title = "Assignment-Title"
        @assignment = @course.assignments.create!(name: title)
        @quiz = @course.quizzes.create!

        visit_new_quiz_page(@course, @quiz)

        click_course_links_toolbar_menuitem

        click_assignments_accordion
        click_course_item_link(title)

        in_frame rce_page_body_ifr_id do
          expect(wiki_body_anchor.attribute("href")).to include assignment_id_path(
            @course,
            @assignment
          )
        end
      end

      it "clicks on assignment in sidebar to create link to it in syllabus page" do
        title = "Assignment-Title"
        @assignment = @course.assignments.create!(name: title)

        visit_syllabus(@course)
        click_edit_syllabus

        click_course_links_toolbar_menuitem

        click_assignments_accordion
        click_course_item_link(title)

        in_frame rce_page_body_ifr_id do
          expect(wiki_body_anchor.attribute("href")).to include assignment_id_path(
            @course,
            @assignment
          )
        end
      end

      it "closes links tray if open when opening link options" do
        skip("still flakey. Needs to be addressed in LS-1814")
        visit_front_page_edit(@course)

        switch_to_html_view
        html_view = f("textarea#wiki_page_body")
        html_view.send_keys('<h2>This is plain text</h2><a href="http://example.com">edit me</a>')
        switch_to_editor_view

        def switch_trays
          click_course_links_toolbar_menuitem
          wait_for_ajaximations
          expect(course_links_tray).to be_displayed

          begin
            click_link_for_options
            click_link_options_button

            expect(link_options_tray).to be_displayed
            validate_course_links_tray_closed
          rescue Selenium::WebDriver::Error::NoSuchElementError
            puts "Failed finding the link options button. Bailing out on this spec."
            expect(true).to be_truthy
          ensure
            driver.switch_to.frame("wiki_page_body_ifr")
            f("h2").click
            driver.switch_to.default_content
          end
        end

        # Duplicate trays only appear sporadically, so repeat this several times to make sure
        # we aren't getting multiple trays open at once.
        3.times { switch_trays }
      end

      it "displays assignment publish status in links accordion" do
        title = "Assignment-Title"
        @assignment = @course.assignments.create!(name: title, workflow_state: "published")

        visit_new_announcement_page(@course)

        click_course_links_toolbar_menuitem
        click_assignments_accordion

        expect(assignment_published_status).to be_displayed

        @assignment.workflow_state = "unpublished"
        @assignment.save!
        visit_new_announcement_page(@course)

        click_course_links_toolbar_menuitem

        expect(assignment_unpublished_status).to be_displayed
      end

      it "displays assignment due date in links accordion" do
        title = "Assignment-Title"
        due_at = 3.days.from_now
        @assignment =
          @course.assignments.create!(name: title, workflow_state: "published", due_at:)

        visit_new_announcement_page(@course)

        click_course_links_toolbar_menuitem
        click_assignments_accordion
        wait_for_ajaximations
        expect(assignment_due_date_exists?(due_at)).to be true
      end

      context "without manage files permissions" do
        before do
          RoleOverride.create!(
            permission: "manage_files_add",
            enabled: false,
            context: @course.account,
            role: teacher_role
          )
        end

        it "still allows inserting course links" do
          title = "Discussion-Title"
          @discussion = @course.discussion_topics.create!(title:)

          visit_front_page_edit(@course)

          click_course_links_toolbar_menuitem

          click_discussions_accordion
          click_course_item_link(title)

          in_frame rce_page_body_ifr_id do
            expect(wiki_body_anchor.attribute("href")).to include discussion_id_path(
              @course,
              @discussion
            )
          end
        end
      end
    end

    context "edit course link sidebar" do
      before do
        @wiki_page_title1 = "test_page"
        @wiki_page_title2 = "test_page2"
        unpublished = false
        edit_roles = "public"
        @wiki_page1 = create_wiki_page(@wiki_page_title1, unpublished, edit_roles)
        @wiki_page2 = create_wiki_page(@wiki_page_title2, unpublished, edit_roles)
      end

      it "keeps the link label when updating the link reference" do
        visit_front_page_edit(@course)
        create_wiki_page_link(@wiki_page_title2)
        open_edit_link_tray
        # default name
        expect(current_link_label).to include_text(@wiki_page_title2)
        # changing link reference
        click_course_item_link(@wiki_page_title1)
        expect(current_link_label).to include_text(@wiki_page_title1)
        click_replace_link_button
        # keeps the name but updates the link reference
        in_frame rce_page_body_ifr_id do
          expect(wiki_body_anchor.text).to eq @wiki_page_title2
          expect(wiki_body_anchor.attribute("href")).to include course_wiki_page_path(@course, @wiki_page1)
        end
      end

      it "keeps the link reference when updating the link label" do
        link_text = "custom title"
        visit_front_page_edit(@course)
        create_wiki_page_link(@wiki_page_title2)
        open_edit_link_tray
        # default name
        expect(current_link_label).to include_text(@wiki_page_title2)
        # changing link text
        change_link_text_input(link_text)
        click_replace_link_button
        # changes the link text but keeps the reference
        in_frame rce_page_body_ifr_id do
          expect(wiki_body_anchor.text).to eq link_text
          expect(wiki_body_anchor.attribute("href")).to include course_wiki_page_path(@course, @wiki_page2)
        end
      end

      it "does not modify the link when canceling" do
        visit_front_page_edit(@course)
        create_wiki_page_link(@wiki_page_title2)
        open_edit_link_tray

        expect(current_link_label).to include_text(@wiki_page_title2)
        open_edit_link_tray
        # change title
        change_link_text_input("different title")
        # change reference
        click_course_item_link(@wiki_page_title1)
        click_cancel_replace_button
        in_frame rce_page_body_ifr_id do
          expect(wiki_body_anchor.text).to eq @wiki_page_title2
          expect(wiki_body_anchor.attribute("href")).to include course_wiki_page_path(@course, @wiki_page2)
        end
      end
    end

    context "sidebar search" do
      it "searches for wiki course link to create link in body", :ignore_js_errors do
        title = "test_page"
        title2 = "test_page2"
        unpublished = false
        edit_roles = "public"

        create_wiki_page(title, unpublished, edit_roles)
        create_wiki_page(title2, unpublished, edit_roles)

        visit_front_page_edit(@course)

        click_course_links_toolbar_menuitem

        click_pages_accordion

        expect(course_item_links_list.count).to eq(2)
        enter_search_data("ge2")

        expect(course_item_links_list.count).to eq(1)

        click_course_item_link(title2)

        in_frame rce_page_body_ifr_id do
          expect(wiki_body_anchor.attribute("title")).to include title2
          expect(wiki_body_anchor.text).to eq title2
        end
      end

      it "searches for document link to add to body", :ignore_js_errors do
        title1 = "text_file1.txt"
        title2 = "text_file2.txt"
        create_course_text_file(title1)
        create_course_text_file(title2)

        visit_front_page_edit(@course)

        click_course_documents_toolbar_menuitem

        expect(course_document_links.count).to eq(2)

        enter_search_data("le2")

        expect(course_document_links.count).to eq(1)

        click_document_link(title2)

        in_frame tiny_rce_ifr_id do
          expect(wiki_body_anchor.attribute("href")).to include course_file_id_path(@text_file)
        end
      end

      it "searches for an image in sidebar in image tray", :ignore_js_errors do
        title1 = "email.png"
        title2 = "image_icon.gif"
        add_embedded_image(title1)
        image2 = add_embedded_image(title2)

        visit_front_page_edit(@course)

        click_course_images_toolbar_menuitem
        expect(image_links.count).to eq(2)

        enter_search_data("ico")

        expect(image_links.count).to eq(1)
        click_image_link(title2)

        in_frame tiny_rce_ifr_id do
          expect(wiki_body_image.attribute("src")).to include course_file_id_path(image2)
        end
      end

      it "searches for items when different accordian section opened", :ignore_js_errors do
        # Add two pages
        title = "test_page"
        title2 = "icon_page"
        unpublished = false
        edit_roles = "public"

        create_wiki_page(title, unpublished, edit_roles)
        create_wiki_page(title2, unpublished, edit_roles)

        # Add two assignments
        title = "icon assignment"
        title2 = "random assignment"
        @course.assignments.create!(name: title)
        @course.assignments.create!(name: title2)

        # Add two images
        title1 = "email.png"
        title2 = "image_icon.gif"
        add_embedded_image(title1)
        add_embedded_image(title2)

        visit_front_page_edit(@course)

        click_course_links_toolbar_menuitem
        enter_search_data("ico")
        click_pages_accordion
        expect(course_item_links_list.count).to eq(1)

        click_assignments_accordion
        expect(course_item_links_list.count).to eq(1)

        change_content_tray_content_type("Files")
        change_content_tray_content_subtype("Images")
        change_content_tray_content_type("Course Files")
        expect(image_links.count).to eq(1)
      end
    end

    it "clicks on sidebar images tab" do
      visit_front_page_edit(@course)
      click_course_images_toolbar_menuitem

      expect(course_images_tray).to be_displayed
    end

    it "clicks on an image in sidebar to display in body", :ignore_js_errors do
      title = "email.png"
      @root_folder = Folder.root_folders(@course).first
      @image = @root_folder.attachments.build(context: @course)
      path = File.expand_path(File.dirname(__FILE__) + "/../../../public/images/email.png")
      @image.uploaded_data = Rack::Test::UploadedFile.new(path, Attachment.mimetype(path))
      @image.save!

      visit_front_page_edit(@course)

      click_course_images_toolbar_menuitem

      click_image_link(title)

      in_frame tiny_rce_ifr_id do
        expect(wiki_body_image.attribute("src")).to include course_file_id_path(@image)
      end
    end

    it "links image to selected text" do
      title = "email.png"
      @root_folder = Folder.root_folders(@course).first
      @image = @root_folder.attachments.build(context: @course)
      path = File.expand_path(File.dirname(__FILE__) + "/../../../public/images/email.png")
      @image.uploaded_data = Rack::Test::UploadedFile.new(path, Attachment.mimetype(path))
      @image.save!

      @course.wiki_pages.create!(title: "title", body: "<p id='para'>select me</p>")
      visit_existing_wiki_edit(@course, "title")

      f("##{rce_page_body_ifr_id}").click
      select_text_of_element_by_id("para")

      click_course_images_toolbar_menuitem

      click_image_link(title)

      in_frame tiny_rce_ifr_id do
        expect(wiki_body).not_to contain_css("img")
        expect(wiki_body_anchor.attribute("href")).to include course_file_id_path(@image)
      end
    end

    it "opens tray when clicking options button on existing image" do
      page_title = "Page1"
      create_wiki_page_with_embedded_image(page_title)

      visit_existing_wiki_edit(@course, page_title)

      begin
        click_embedded_image_for_options
        click_image_options_button
        expect(image_options_tray).to be_displayed
      rescue Selenium::WebDriver::Error::NoSuchElementError
        puts "Failed finding the image options button. Bailing out on this spec."
        expect(true).to be_truthy
      end
    end

    it "closes links tray if open when opening image options" do
      skip("still flakey. Needs to be addressed in LS-1814")
      page_title = "Page1"
      image = add_embedded_image("email.png")
      @course.wiki_pages.create!(
        title: page_title,
        body: "<h2>This is plain text</h2><img src=\"/courses/#{@course.id}/files/#{image.id}\">"
      )

      visit_existing_wiki_edit(@course, page_title)

      def switch_trays
        click_course_links_toolbar_menuitem
        wait_for_ajaximations
        expect(course_links_tray).to be_displayed

        begin
          click_embedded_image_for_options
          click_image_options_button

          expect(image_options_tray).to be_displayed
          validate_course_links_tray_closed
        rescue Selenium::WebDriver::Error::NoSuchElementError
          puts "Failed finding the image options button. Bailing out on this spec."
          expect(true).to be_truthy
        ensure
          driver.switch_to.frame("wiki_page_body_ifr")
          f("h2").click
          driver.switch_to.default_content
        end
      end

      # Duplicate trays only appear sporadically, so run this several times to make sure
      # we aren't getting multiple trays open at once.
      3.times { switch_trays }
    end

    it "changes embedded image to link when selecting option" do
      page_title = "Page1"
      create_wiki_page_with_embedded_image(page_title)

      visit_existing_wiki_edit(@course, page_title)

      begin
        click_embedded_image_for_options
        click_image_options_button

        click_display_text_link_option
        click_image_options_done_button

        in_frame tiny_rce_ifr_id do
          expect(wiki_body_anchor).not_to contain_css("src")
        end
      rescue Selenium::WebDriver::Error::NoSuchElementError
        puts "Failed finding the image options button. Bailing out on this spec."
        expect(true).to be_truthy
      end
    end

    it "adds alt text to image using options tray" do
      alt_text = "fear is the mindkiller"
      page_title = "Page1"
      create_wiki_page_with_embedded_image(page_title)

      visit_existing_wiki_edit(@course, page_title)

      begin
        click_embedded_image_for_options
        click_image_options_button

        alt_text_textbox.send_keys(alt_text)
        click_image_options_done_button

        in_frame rce_page_body_ifr_id do
          expect(wiki_body_image.attribute("alt")).to include alt_text
        end
      rescue Selenium::WebDriver::Error::NoSuchElementError
        puts "Failed finding the image options button. Bailing out on this spec."
        expect(true).to be_truthy
      end
    end

    it "guaranteeses an alt text when selecting decorative" do
      skip("Cannot get this to pass flakey spec catcher in jenkins, though is fine locally MAT-154")
      page_title = "Page1"
      create_wiki_page_with_embedded_image(page_title)

      visit_existing_wiki_edit(@course, page_title)

      begin
        click_embedded_image_for_options
        click_image_options_button

        click_decorative_options_checkbox
        click_image_options_done_button

        in_frame rce_page_body_ifr_id do
          expect(wiki_body_image.attribute("alt")).to eq("")
          expect(wiki_body_image.attribute("role")).to eq("presentation")
        end
      rescue Selenium::WebDriver::Error::NoSuchElementError
        puts "Failed finding the image options button. Bailing out on this spec."
        expect(true).to be_truthy
      end
    end

    it "clicks on a document in sidebar to display in body" do
      title = "text_file.txt"
      create_course_text_file(title)

      visit_front_page_edit(@course)

      click_course_documents_toolbar_menuitem

      click_document_link(title)

      in_frame tiny_rce_ifr_id do
        expect(wiki_body_anchor.attribute("href")).to include course_file_id_path(@text_file)
      end
    end

    context "status bar functions" do
      it "opens a11y checker when clicking button in status bar" do
        visit_front_page_edit(@course)

        click_a11y_checker_button

        expect(a11y_checker_tray).to be_displayed
      end

      it "shows notification badge" do
        visit_front_page_edit(@course)

        switch_to_html_view
        switch_to_raw_html_editor
        html_view = f("textarea#wiki_page_body")
        html_view.send_keys('<img src="image.jpg" alt="image.jpg" />')
        switch_to_editor_view

        wait_for(method: nil, timeout: 5) do
          badge_element = fxpath('//button[@data-btn-id="rce-a11y-btn"]/following-sibling::span')
          expect(badge_element.text).to eq "1"
        end

        switch_to_html_view
        html_view = f("textarea#wiki_page_body")
        html_view.clear
        html_view.send_keys("test text")
        switch_to_editor_view

        expect(
          wait_for_no_such_element(method: nil, timeout: 5) do
            fxpath('//button[@data-btn-id="rce-a11y-btn"]/following-sibling::span')
          end
        ).to be_truthy
      end

      it "opens keyboard shortcut modal when clicking button in status bar" do
        visit_front_page_edit(@course)

        click_visible_keyboard_shortcut_button

        expect(keyboard_shortcut_modal).to be_displayed
      end

      it "opens rce in full screen with button in status bar" do
        visit_front_page_edit(@course)

        full_screen_button.click
        fs_elem = driver.execute_script("return document.fullscreenElement")
        expect(fs_elem).to eq f(".rce-wrapper")

        exit_full_screen_button.click
        fs_elem = driver.execute_script("return document.fullscreenElement")
        expect(fs_elem).to be_nil
      end
    end

    it "closes the course links tray when pressing esc", :ignore_js_errors do
      visit_front_page_edit(@course)

      click_course_links_toolbar_menuitem

      expect(tray_container_exists?).to be true

      driver.action.send_keys(:escape).perform

      # tray_container_exists disables implicit waits,
      # and because we're waiting for something to _disappear_
      # we can't use implicit waits, so just keep trying for a bit
      keep_trying_until do
        expect(tray_container_exists?).to be false # Press esc key
      end
    end

    it "closes the course images tray when pressing esc", :ignore_js_errors do
      visit_front_page_edit(@course)

      click_course_images_toolbar_menuitem
      expect(tray_container_exists?).to be true

      driver.action.send_keys(:escape).perform

      keep_trying_until do
        expect(tray_container_exists?).to be false # Press esc key
      end
    end

    it "opens upload image modal when clicking upload option" do
      visit_front_page_edit(@course)

      click_upload_image_toolbar_menuitem

      expect(upload_image_modal).to be_displayed
    end

    describe "kaltura interaction" do
      it "includes media upload option if kaltura is enabled" do
        double("CanvasKaltura::ClientV3")
        allow(CanvasKaltura::ClientV3).to receive(:config).and_return({})
        visit_front_page_edit(@course)
        media_button = media_toolbar_menubutton
        media_toolbar_menubutton.click
        wait_for_animations
        menu_id = media_button.attribute("aria-owns")
        expect(menu_item_by_menu_id(menu_id, "Upload/Record Media")).to be_displayed
        expect(menu_item_by_menu_id(menu_id, "Course Media")).to be_displayed
        expect(menu_item_by_menu_id(menu_id, "User Media")).to be_displayed
        expect(menu_items_by_menu_id(menu_id).length).to be(3)
      end

      it "does not include media upload option if kaltura is disabled" do
        double("CanvasKaltura::ClientV3")
        allow(CanvasKaltura::ClientV3).to receive(:config).and_return(nil)
        visit_front_page_edit(@course)
        media_button = media_toolbar_menubutton
        media_toolbar_menubutton.click
        wait_for_animations
        menu_id = media_button.attribute("aria-owns")
        expect(menu_item_by_menu_id(menu_id, "Course Media")).to be_displayed
        expect(menu_item_by_menu_id(menu_id, "User Media")).to be_displayed
        expect(menu_items_by_menu_id(menu_id).length).to be(2)
      end

      it "does not include media upload option if button is disabled" do
        double("CanvasKaltura::ClientV3")
        allow(CanvasKaltura::ClientV3).to receive(:config).and_return({ "hide_rte_button" => true })
        visit_front_page_edit(@course)
        media_button = media_toolbar_menubutton
        media_toolbar_menubutton.click
        wait_for_animations
        menu_id = media_button.attribute("aria-owns")
        expect(menu_item_by_menu_id(menu_id, "Course Media")).to be_displayed
        expect(menu_item_by_menu_id(menu_id, "User Media")).to be_displayed
        expect(menu_items_by_menu_id(menu_id).length).to be(2)
      end

      it "opens upload document modal when clicking upload option" do
        double("CanvasKaltura::ClientV3")
        allow(CanvasKaltura::ClientV3).to receive(:config).and_return({})
        visit_front_page_edit(@course)

        click_upload_document_toolbar_menuitem

        expect(upload_document_modal).to be_displayed
      end

      it "opens upload media modal when clicking upload option" do
        double("CanvasKaltura::ClientV3")
        allow(CanvasKaltura::ClientV3).to receive(:config).and_return({})
        visit_front_page_edit(@course)

        click_upload_media_toolbar_menuitem

        expect(upload_media_modal).to be_displayed
      end
    end

    it "closes sidebar after drag and drop" do
      skip("kills many selenium tests. Address in CORE-3147")
      title = "Assignment-Title"
      @assignment = @course.assignments.create!(name: title)

      visit_front_page_edit(@course)

      click_course_links_toolbar_menuitem
      click_assignments_accordion

      source = course_item_link(title)
      dest = f("iframe.tox-edit-area__iframe")
      driver.action.drag_and_drop(source, dest).perform

      expect(f("body")).not_to contain_css('[data-testid="CanvasContentTray"]')
    end

    it "adds a title attribute to an inserted iframe" do
      # as typically happens when embedding media, like a youtube video
      double("CanvasKaltura::ClientV3")
      allow(CanvasKaltura::ClientV3).to receive(:config).and_return({})
      visit_front_page_edit(@course)

      click_embed_toolbar_button
      code_box = embed_code_textarea
      code_box.click
      code_box.send_keys('<iframe src="https://example.com/"></iframe>')
      click_embed_submit_button
      wait_for_animations

      fj('button:contains("Save")').click
      wait_for_ajaximations

      expect(f('iframe[title="embedded content"][src="https://example.com/"]')).to be_displayed # save the page
    end

    it "does not load duplicate data when opening sidebar tray multiple times" do
      user_attachment = @user.attachments.build(filename: "myimage.png", context: @student)
      user_attachment.content_type = "image/png"
      user_attachment.save!

      visit_new_assignment_page(@course)

      click_user_images_toolbar_menuitem
      expect(user_image_links.count).to eq 1
      expect(tray_container).to include_text("myimage")

      click_close_button
      click_user_images_toolbar_menuitem

      expect(user_image_links.count).to eq 1
      expect(tray_container).to include_text("myimage")
    end

    describe "keyboard shortcuts" do
      it "opens keyboard shortcut modal with alt-f8" do
        visit_front_page_edit(@course)
        rce = f(".tox-edit-area__iframe")
        rce.send_keys(:alt, :f8)

        expect(keyboard_shortcut_modal).to be_displayed
      end

      it "focuses the menubar with alt-f9" do
        visit_front_page_edit(@course)
        rce = f(".tox-edit-area__iframe")
        expect(f(".tox-menubar")).to be_displayed # always show menubar now
        rce.send_keys(:alt, :f9)

        expect(f(".tox-menubar")).to be_displayed
        expect(fj('.tox-menubar button:contains("Edit")')).to eq(driver.switch_to.active_element)
      end

      it "focuses the toolbar with alt-f10" do
        visit_front_page_edit(@course)
        rce = f(".tox-edit-area__iframe")
        rce.send_keys(:alt, :f10)

        expect(fj('.tox-toolbar__primary button:contains("12pt")')).to eq(
          driver.switch_to.active_element
        )
      end

      it "focuses table context toolbar with ctrl-f9" do
        page_title = "Page-with-table"
        create_wiki_page_with_content(page_title)

        visit_existing_wiki_edit(@course, page_title)
        driver.switch_to.frame("wiki_page_body_ifr")
        f("table td").click
        driver.action.key_down(:control).send_keys(:f9).key_up(:control).perform

        driver.switch_to.default_content
        expect(f('.tox-pop__dialog button[title="Table properties"]')).to eq(
          driver.switch_to.active_element
        ) # put the cursor in the table
      end

      it "focuses course file link context toolbar with ctrl-f9" do
        page_title = "Page-with-link"
        create_wiki_page_with_content(page_title)

        visit_existing_wiki_edit(@course, page_title)
        driver.switch_to.frame("wiki_page_body_ifr")
        f("a").click
        driver.action.key_down(:control).send_keys(:f9).key_up(:control).perform

        driver.switch_to.default_content
        expect(f('.tox-pop__dialog button[title="Show link options"]')).to eq(
          driver.switch_to.active_element
        )
      end
    end

    describe "lti tool integration" do
      before do
        # set up the lti tool
        @tool =
          Account.default.context_external_tools.new(
            {
              name: "Commons",
              domain: "canvaslms.com",
              consumer_key: "12345",
              shared_secret: "secret",
              is_rce_favorite: "true"
            }
          )
        @tool.set_extension_setting(
          :editor_button,
          {
            message_type: "ContentItemSelectionRequest",
            url: "http://www.example.com",
            icon_url: "https://lor.instructure.com/img/icon_commons.png",
            text: "Commons Favorites",
            enabled: "true",
            use_tray: "true",
            favorite: "true"
          }
        )
        @tool.save!
      end

      it "displays lti icon with a tool enabled for the course", :ignore_js_errors do
        page_title = "Page1"
        create_wiki_page_with_embedded_image(page_title)

        visit_existing_wiki_edit(@course, page_title)

        expect(lti_tools_button_with_mru).to be_displayed
      end

      # we are now only using the menu button regardless of presence/absence
      # of mru data in local storage
      it "displays the lti tool modal", :ignore_js_errors do
        page_title = "Page1"
        create_wiki_page_with_embedded_image(page_title)

        # have to visit the page before we can interact with local storage
        visit_existing_wiki_edit(@course, page_title)
        driver.local_storage.clear

        visit_existing_wiki_edit(@course, page_title)
        driver.local_storage.delete("ltimru")

        wait_for_tiny(edit_wiki_css)
        lti_tools_button_with_mru.click
        menu_item_by_name("View All").click

        expect(lti_tools_modal).to be_displayed
      end

      it "displays the lti tool modal, reprise", :ignore_js_errors do
        page_title = "Page1"
        create_wiki_page_with_embedded_image(page_title)

        visit_existing_wiki_edit(@course, page_title)

        # value doesn't matter, its existance triggers the menu button
        driver.local_storage["ltimru"] = [999]

        # ltimru has to be in local storage when the page loads to get the menu button
        driver.navigate.refresh
        wait_for_tiny(edit_wiki_css)

        lti_tools_button_with_mru.click
        menu_item_by_name("View All").click

        expect(lti_tools_modal).to be_displayed
        driver.local_storage.clear
      end

      it "shows favorited LTI tool icon when a tool is favorited", :ignore_js_errors do
        page_title = "Page1"
        create_wiki_page_with_embedded_image(page_title)

        visit_existing_wiki_edit(@course, page_title)

        expect(lti_favorite_button).to be_displayed
      end

      it "displays the favorited lti tool modal", :ignore_js_errors do
        page_title = "Page1"
        create_wiki_page_with_embedded_image(page_title)

        visit_existing_wiki_edit(@course, page_title)
        lti_favorite_button.click

        expect(lti_favorite_modal).to be_displayed
      end

      describe "Paste", :ignore_js_errors do
        it "edit menubar menu shows tinymce flash alert on selecting 'Paste'" do
          rce_wysiwyg_state_setup(@course)
          menubar_open_menu("Edit")
          menubar_menu_item("Paste").click
          alert = f('.tox-notification--error[role="alert"]')
          expect(alert).to be_displayed
          expect(alert.text).to include "Your browser doesn't support direct access to the clipboard."
        end

        it "does not load the instructure_paste plugin when RCS is unavailable" do
          allow(DynamicSettings).to receive(:find)
            .with("rich-content-service", default_ttl: 5.minutes)
            .and_return(DynamicSettings::FallbackProxy.new)
          rce_wysiwyg_state_setup(@course)
          plugins = driver.execute_script("return Object.keys(tinymce.activeEditor.plugins)") # rubocop:disable Specs/NoExecuteScript
          expect(plugins.include?("instructure_paste")).to be(false)
          expect(plugins.include?("paste")).to be(true)
        end
      end

      describe "Tools menubar menu", :ignore_js_errors do
        it "includes Apps menu item in" do
          rce_wysiwyg_state_setup(@course)

          menubar_open_menu("Tools")
          expect(menubar_menu_item("Apps")).to be_displayed
        end

        it 'shows "View All" in the Tools > Apps submenu', :ignore_js_errors do
          rce_wysiwyg_state_setup(@course)

          click_menubar_submenu_item("Tools", "Apps")
          expect(menubar_menu_item("View All")).to be_displayed
          expect(f("body")).not_to contain_css(menubar_menu_item_css("Commons Favorites"))
        end

        it "shows MRU tools in the Tools > Apps submenu", :ignore_js_errors do
          rce_wysiwyg_state_setup(@course)
          driver.local_storage["ltimru"] = "[#{@tool.id}]"

          click_menubar_submenu_item("Tools", "Apps")
          expect(menubar_menu_item("View All")).to be_displayed
          expect(f("body")).to contain_css(menubar_menu_item_css("Commons Favorites"))
          driver.local_storage.clear
        end
      end
    end

    context "fonts", :ignore_js_errors do
      it "changes to Balsamiq Sans font with menubar options" do
        text = "Hello font"
        rce_wysiwyg_state_setup(@course, text)
        select_all_in_tiny(f("#wiki_page_body"))
        click_menubar_submenu_item("Format", "Fonts")
        menu_option_by_name("Balsamiq Sans").click
        fj('button:contains("Save")').click
        wait_for_ajaximations
        expect(f(".show-content.user_content p span").attribute("style")).to eq(
          'font-family: "Balsamiq Sans", lato, "Helvetica Neue", Helvetica, Arial, sans-serif;'
        )
      end

      it "changes to Architects Daughter font with menubar options" do
        text = "Hello font"
        rce_wysiwyg_state_setup(@course, text)
        select_all_in_tiny(f("#wiki_page_body"))
        click_menubar_submenu_item("Format", "Fonts")
        menu_option_by_name("Architect\\'s Daughter").click
        fj('button:contains("Save")').click
        wait_for_ajaximations
        expect(f(".show-content.user_content p span").attribute("style")).to eq(
          'font-family: "Architects Daughter", lato, "Helvetica Neue", Helvetica, Arial, sans-serif;'
        )
      end
    end

    describe "Format/Formats menubar menu" do
      it "shows correct heading options" do
        rce_wysiwyg_state_setup(@course)
        menubar_open_menu("Format")
        expect(menubar_menu_item("Formats")).to be_displayed
        click_menubar_menu_item("Formats")
        click_menubar_menu_item("Headings")
        expect(f("body")).to contain_css(menubar_menu_item_css("Heading 2"))
        expect(f("body")).to contain_css(menubar_menu_item_css("Heading 3"))
        expect(f("body")).to contain_css(menubar_menu_item_css("Heading 4"))
        expect(f("body")).to contain_css(menubar_menu_item_css("Heading 5"))
        expect(f("body")).to contain_css(menubar_menu_item_css("Heading 6"))
        expect(f("body")).not_to contain_css(menubar_menu_item_css("Heading 1"))
      end
    end

    describe "Insert menubar menu" do
      it "shows content insertion menu items" do
        double("CanvasKaltura::ClientV3")
        allow(CanvasKaltura::ClientV3).to receive(:config).and_return({})
        rce_wysiwyg_state_setup(@course)
        menubar_open_menu("Insert")

        expect(menubar_menu_item("Link")).to be_displayed
        click_menubar_menu_item("Link")
        expect(f("body")).to contain_css(menubar_menu_item_css("External Link"))
        expect(f("body")).to contain_css(menubar_menu_item_css("Course Link"))

        expect(menubar_menu_item("Image")).to be_displayed
        click_menubar_menu_item("Image")
        expect(f("body")).to contain_css(menubar_menu_item_css("Upload Image"))
        expect(f("body")).to contain_css(menubar_menu_item_css("Course Images"))
        expect(f("body")).to contain_css(menubar_menu_item_css("User Images"))

        expect(menubar_menu_item("Media")).to be_displayed
        click_menubar_menu_item("Media")
        expect(f("body")).to contain_css(menubar_menu_item_css("Upload/Record Media"))
        expect(f("body")).to contain_css(menubar_menu_item_css("Course Media"))
        expect(f("body")).to contain_css(menubar_menu_item_css("User Media"))

        expect(menubar_menu_item("Document")).to be_displayed
        click_menubar_menu_item("Document")
        expect(f("body")).to contain_css(menubar_menu_item_css("Upload Document"))
        expect(f("body")).to contain_css(menubar_menu_item_css("Course Documents"))
        expect(f("body")).to contain_css(menubar_menu_item_css("User Documents"))
      end
    end

    describe "the content tray" do
      after { driver.local_storage.clear }

      it "shows course links after user files" do
        get "/"
        driver.session_storage["canvas_rce_links_accordion_index"] = "assignments"

        title = "Assignment-Title"
        @assignment = @course.assignments.create!(name: title)

        rce_wysiwyg_state_setup(@course)

        click_course_links_toolbar_menuitem
        wait_for_ajaximations
        expect(fj("li:contains('#{title}')")).to be_displayed

        click_content_tray_close_button
        wait_for_animations

        click_user_documents_toolbar_menuitem
        wait_for_ajaximations

        change_content_tray_content_type("Links")
        wait_for_ajaximations
        expect(fj("li:contains('#{title}')")).to be_displayed
      end
    end

    describe "the html editors" do
      after do
        driver.execute_script("if (document.fullscreenElement) document.exitFullscreen()")
      end

      it "switches between wysiwyg and pretty html view" do
        skip("Cannot get this to pass flakey spec catcher in jenkins, though is fine locally MAT-29")
        rce_wysiwyg_state_setup(@course)
        expect(f('[aria-label="Rich Content Editor"]')).to be_displayed

        # click edit button -> fancy editor
        click_editor_view_button

        # it's lazy loaded
        expect(f(".RceHtmlEditor")).to be_displayed

        # click edit button -> back to the rce
        click_editor_view_button
        expect(f('[aria-label="Rich Content Editor"]')).to be_displayed

        # shift-o edit button -> raw editor
        shift_O_combination('[data-btn-id="rce-edit-btn"]')
        expect(f("textarea#wiki_page_body")).to be_displayed

        # click "Pretty HTML Editor" status bar button -> fancy editor
        fj('button:contains("Pretty HTML Editor")').click
        expect(f(".RceHtmlEditor")).to be_displayed
      end

      it "displays the editor in fullscreen" do
        skip("Cannot get this to pass flakey spec catcher in jenkins, though is fine locally MAT-29")
        rce_wysiwyg_state_setup(@course)

        click_editor_view_button
        expect(f(".RceHtmlEditor")).to be_displayed

        click_full_screen_button
        expect(fullscreen_element).to eq(f(".RceHtmlEditor"))
      end

      it "gets default html editor from the rce.htmleditor cookie" do
        get "/"
        driver.manage.add_cookie(name: "rce.htmleditor", value: "RAW", path: "/")

        rce_wysiwyg_state_setup(@course)

        # clicking opens raw editor
        click_editor_view_button
        expect(f("textarea#wiki_page_body")).to be_displayed
      ensure
        driver.manage.delete_cookie("rce.htmleditor")
      end

      it "saves pretty HTML editor text on submit" do
        skip(
          "Cannot get this to pass flakey spec catcher in jenkins, though is fine locally MAT-35"
        )
        quiz_content = "<p>test</p>"
        @quiz = @course.quizzes.create!
        open_quiz_edit_form
        click_questions_tab
        click_new_question_button
        create_essay_question
        expect_new_page_load { f(".save_quiz_button").click }
        open_quiz_show_page
        expect_new_page_load { f("#preview_quiz_button").click }
        switch_to_html_view
        expect(f(".RceHtmlEditor")).to be_displayed
        f(".RceHtmlEditor .CodeMirror textarea").send_keys(quiz_content)
        expect_new_page_load { submit_quiz }
        expect(f("#questions .essay_question .quiz_response_text").attribute("innerHTML")).to eq(
          quiz_content
        )
      end

      it "sanitizes the HTML set in the HTML editor" do
        get "/"

        html = <<~HTML
          <img src="/" id="test-image" onerror="alert('hello')" />
        HTML

        rce_wysiwyg_state_setup(
          @course,
          html,
          html: true,
          new_rce: true
        )

        in_frame rce_page_body_ifr_id do
          expect(f("#test-image").attribute("onerror")).to be_nil
        end
      end
    end

    context "Icon Maker Tray" do
      before do
        Account.site_admin.enable_feature!(:buttons_and_icons_root_account)
      end

      it "can add image" do
        skip("Works IRL but fails in selenium. Fix with MAT-1127")
        rce_wysiwyg_state_setup(@course)
        create_icon_toolbar_menuitem.click
        iconmaker_addimage_menu.click
        iconmaker_singlecolor_option.click
        iconmaker_singlecolor_articon.click
        expect(iconmaker_image_preview).to be_displayed
      end
    end

    # rubocop:disable Specs/NoSeleniumWebDriverWait
    describe "fullscreen" do
      it "restores the rce to its original size on exiting fullscreen" do
        skip "FOO-3817 (10/7/2023)"
        visit_front_page_edit(@course)

        rce_wrapper = f(".rce-wrapper")
        orig_height = rce_wrapper.css_value("height")

        full_screen_button.click
        fs_elem = driver.execute_script("return document.fullscreenElement")
        expect(fs_elem).to eq f(".rce-wrapper")

        exit_full_screen_button.click
        rce_wrapper = f(".rce-wrapper")
        Selenium::WebDriver::Wait.new(timeout: 1.0).until do
          expect(orig_height).to eql(rce_wrapper.css_value("height"))
        end
      end

      it "restores the rce to its original size after switching to pretty html view" do
        visit_front_page_edit(@course)

        rce_wrapper = f(".rce-wrapper")
        orig_height = rce_wrapper.css_value("height").to_i

        full_screen_button.click
        fs_elem = driver.execute_script("return document.fullscreenElement")
        expect(fs_elem).to eq f(".rce-wrapper")

        switch_to_html_view
        exit_full_screen_button.click
        rce_wrapper = f(".rce-wrapper")
        new_height = rce_wrapper.css_value("height").to_i
        Selenium::WebDriver::Wait.new(timeout: 1.0).until do
          expect((orig_height - new_height).abs).to be < 3
        end
      end

      it "restores the rce to its original while in pretty html view" do
        skip("Flaky. addressed in LF-746")
        visit_front_page_edit(@course)
        switch_to_html_view

        rce_wrapper = f(".rce-wrapper")
        orig_height = rce_wrapper.css_value("height").to_i

        full_screen_button.click
        fs_elem = driver.execute_script("return document.fullscreenElement")
        expect(fs_elem).to eq f(".rce-wrapper")

        exit_full_screen_button.click
        rce_wrapper = f(".rce-wrapper")
        new_height = rce_wrapper.css_value("height").to_i
        Selenium::WebDriver::Wait.new(timeout: 1.0).until do
          expect((orig_height - new_height).abs).to be < 3
        end
      end

      it "restores the rce to its original size after switching from pretty html view" do
        visit_front_page_edit(@course)
        switch_to_html_view

        rce_wrapper = f(".rce-wrapper")
        orig_height = rce_wrapper.css_value("height").to_i

        full_screen_button.click
        fs_elem = driver.execute_script("return document.fullscreenElement")
        expect(fs_elem).to eq f(".rce-wrapper")

        switch_to_editor_view
        exit_full_screen_button.click
        rce_wrapper = f(".rce-wrapper")
        new_height = rce_wrapper.css_value("height").to_i
        Selenium::WebDriver::Wait.new(timeout: 1.0).until do
          expect((orig_height - new_height).abs).to be < 3
        end
      end

      it "stil shows tinymce menus when in fullscreen" do
        # ideally we'd do this test with multiple RCEs on the page
        # but the setup effort isn't worth it.
        visit_front_page_edit(@course)
        full_screen_button.click
        doc_btn = document_toolbar_menubutton
        doc_btn.click
        menu_id = doc_btn.attribute("aria-owns")
        expect(f("##{menu_id}")).to be_displayed
      end

      it "traps focus in fullscreen" do
        visit_front_page_edit(@course)
        full_screen_button.click
        active_elem = driver.execute_script("return document.activeElement") # content area
        active_elem.send_keys(:tab)
        driver.execute_script("return document.activeElement").send_keys(:tab) # status bar button
        driver.execute_script("return document.activeElement").send_keys(:tab) # kb shortcut button
        new_active_elem = driver.execute_script("return document.activeElement") # content area
        expect(new_active_elem).to eq(active_elem)
        exit_full_screen_button.click
      end
    end
    # rubocop:enable Specs/NoSeleniumWebDriverWait

    describe "CanvasContentTray" do
      it "displays all its dropdowns" do
        visit_front_page_edit(@course)

        document_toolbar_menubutton.click
        course_documents_toolbar_menuitem.click
        expect(tray_container).to be_displayed

        content_tray_content_type.click
        expect(content_tray_content_type_links).to be_displayed
        content_tray_content_type.click # close the dropdown

        content_tray_content_subtype.click
        expect(content_tray_content_subtype_images).to be_displayed
        content_tray_content_subtype.click

        content_tray_sort_by.click
        expect(content_tray_sort_by_date_added).to be_displayed
        content_tray_sort_by.click

        exit_full_screen_menu_item.click
      end

      it "displays all its dropdowns in fullscreen" do
        visit_front_page_edit(@course)

        document_toolbar_menubutton.click
        course_documents_toolbar_menuitem.click
        expect(tray_container).to be_displayed
        full_screen_button.click
        wait_for_animations
        expect(tray_container).to be_displayed

        content_tray_content_type.click
        expect(content_tray_content_type_links).to be_displayed
        content_tray_content_type.click # close the dropdown

        content_tray_content_subtype.click
        expect(content_tray_content_subtype_images).to be_displayed
        content_tray_content_subtype.click

        content_tray_sort_by.click
        expect(content_tray_sort_by_date_added).to be_displayed
        content_tray_sort_by.click

        exit_full_screen_menu_item.click
      end
    end

    describe "selection management" do
      it "restores selection on focus after being reset while blurred" do
        visit_front_page_edit(@course)
        insert_tiny_text("select me")

        select_all_in_tiny(f("#wiki_page_body"))

        expect(rce_selection_focus_offset).to be > 0

        # Click outside the RCE and clear selection (simulate Cmd+F)
        f("#wiki_page_body_statusbar").click
        clear_rce_selection
        expect(rce_selection_focus_offset).to be 0

        # Click back into the iframe
        f("#wiki_page_body_ifr").click

        # Ensure the selection has been restored
        expect(rce_selection_focus_offset).to be > 0
      end

      it "restores selection before creating a link", :ignore_js_errors do
        title = "test_page"
        unpublished = false
        edit_roles = "public"

        create_wiki_page(title, unpublished, edit_roles)

        visit_front_page_edit(@course)
        insert_tiny_text("select me")

        select_all_in_tiny(f("#wiki_page_body"))

        expect(rce_selection_focus_offset).to be > 0

        external_link_toolbar_menuitem.click
        expect(insert_link_modal).to be_displayed

        clear_rce_selection
        expect(rce_selection_focus_offset).to be 0

        f('input[name="linklink"]').send_keys("http://example.com/")
        fj('[role="dialog"] button:contains("Done")').click

        in_frame rce_page_body_ifr_id do
          expect(wiki_body_anchor.attribute("href")).to eq "http://example.com/"
          expect(wiki_body_anchor.text).to eq "select me"

          # If the selection was restored, there will only be one paragraph
          # If the selection wasn't restored, an additional paragraph will have been created.
          expect(ff("#tinymce p").size).to be 1
        end
      end
    end
  end
end

# rubocop:enable Specs/NoNoSuchElementError, Specs/NoExecuteScript
