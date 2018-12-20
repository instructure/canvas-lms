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

require_relative '../helpers/wiki_and_tiny_common'
require_relative 'pages/rcs_sidebar_page'

describe "RCS sidebar tests" do
  include_context "in-process server selenium tests"
  include WikiAndTinyCommon
  include RCSSidebarPage

  context "WYSIWYG generic as a teacher" do

    before(:each) do
      course_with_teacher_logged_in
      enable_all_rcs @course.account
      stub_rcs_config
    end

    it "should add and remove links using RCS sidebar", ignore_js_errors: true do
      title = "test_page"
      unpublished = false
      edit_roles = "public"

      create_wiki_page(title, unpublished, edit_roles)

      visit_front_page(@course)
      wait_for_tiny(edit_wiki_css)

      click_pages_accordion
      click_new_page_link
      expect(new_page_name_input).to be_displayed
      new_page_name_input.send_keys(title)
      click_new_page_submit

      in_frame wiki_page_body_ifr_id do
        expect(wiki_body_anchor.attribute('href')).to include title
      end
    end

    it "should click on sidebar wiki page to create link in body" do
      title = "wiki-page-1"
      unpublished = false
      edit_roles = "public"

      create_wiki_page(title, unpublished, edit_roles)
      visit_front_page(@course)
      click_pages_accordion
      click_sidebar_link(title)

      in_frame wiki_page_body_ifr_id do
        expect(wiki_body_anchor.attribute('href')).to include title
      end
    end

    it "should click on sidebar assignment page to create link in body" do
      title = "Assignment-Title"
      @assignment = @course.assignments.create!(:name => title)

      visit_front_page(@course)
      click_assignments_accordion
      click_sidebar_link(title)

      in_frame wiki_page_body_ifr_id do
        expect(wiki_body_anchor.attribute('href')).to include "/courses/#{@course.id}/assignments/#{@assignment.id}"
      end
    end

    it "should click on sidebar quizzes page to create link in body" do
      title = "Quiz-Title"
      @quiz = @course.quizzes.create!(:workflow_state => "available", :title => title)

      visit_front_page(@course)
      click_quizzes_accordion
      click_sidebar_link(title)

      in_frame wiki_page_body_ifr_id do
        expect(wiki_body_anchor.attribute('href')).to include "/courses/#{@course.id}/quizzes/#{@quiz.id}"
      end
    end

    it "should click on sidebar announcements page to create link in body" do
      title = "Announcement-Title"
      message = "Announcement 1 detail"
      @announcement = @course.announcements.create!(:title => title, :message => message)

      visit_front_page(@course)
      click_announcements_accordion
      click_sidebar_link(title)

      in_frame wiki_page_body_ifr_id do
        expect(wiki_body_anchor.attribute('href')).to include "/courses/#{@course.id}/discussion_topics/#{@announcement.id}"
      end
    end

    it "should click on sidebar discussions page to create link in body" do
      title = "Discussion-Title"
      @discussion = @course.discussion_topics.create!(:title => title)

      visit_front_page(@course)
      click_discussions_accordion
      click_sidebar_link(title)

      in_frame wiki_page_body_ifr_id do
        expect(wiki_body_anchor.attribute('href')).to include "/courses/#{@course.id}/discussion_topics/#{@discussion.id}"
      end
    end

    it "should click on sidebar modules page to create link in body" do
      title = "Module-Title"
      @module = @course.context_modules.create!(:name => title)

      visit_front_page(@course)
      click_modules_accordion
      click_sidebar_link(title)

      in_frame wiki_page_body_ifr_id do
        expect(wiki_body_anchor.attribute('href')).to include "/courses/#{@course.id}/modules/#{@module.id}"
      end
    end

    it "should click on sidebar course navigation page to create link in body", ignore_js_errors: true do
      title = "Files"
      visit_front_page(@course)
      click_navigation_accordion
      click_sidebar_link(title)

      in_frame wiki_page_body_ifr_id do
        expect(wiki_body_anchor.attribute('href')).to include "/courses/#{@course.id}/files"
      end
    end

    it "should click on sidebar files tab", ignore_js_errors: true do
      wiki_page_tools_file_tree_setup(true, true)

      click_files_tab
      expect(upload_new_file).to be_displayed
    end

    it "should click on a file in sidebar to create link in body" do
      title = "text_file.txt"
      @root_folder = Folder.root_folders(@course).first
      @text_file = @root_folder.attachments.create!(:filename => title, :context => @course) { |a| a.content_type = 'text/plain' }

      visit_front_page(@course)
      click_files_tab
      click_sidebar_link(title)

      in_frame wiki_page_body_ifr_id do
        expect(wiki_body_anchor.attribute('href')).to include "/files/#{@text_file.id}"
      end
    end

    it "should click on sidebar images tab" do
      visit_front_page(@course)

      click_images_tab
      expect(upload_new_image).to be_displayed
    end

    it "should click on an image in sidebar to display in body" do
      title = "email.png"
      @root_folder = Folder.root_folders(@course).first
      @image = @root_folder.attachments.build(:context => @course)
      path = File.expand_path(File.dirname(__FILE__) + '/../../../public/images/email.png')
      @image.uploaded_data = Rack::Test::UploadedFile.new(path, Attachment.mimetype(path))
      @image.save!

      visit_front_page(@course)
      click_images_tab
      click_image_link(title)

      in_frame wiki_page_body_ifr_id do
        expect(wiki_body_image.attribute('src')).to include "/files/#{@image.id}"
      end
    end
  end
end
