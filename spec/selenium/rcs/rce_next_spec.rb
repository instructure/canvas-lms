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
require_relative 'pages/rce_next_page'

describe "RCE next tests" do
  include_context "in-process server selenium tests"
  include WikiAndTinyCommon
  include RCENextPage

  context "WYSIWYG generic as a teacher" do

    before(:each) do
      course_with_teacher_logged_in
      Account.default.enable_feature!(:rce_enhancements)
      stub_rcs_config
    end

    it "should click on sidebar wiki page to create link in body", ignore_js_errors: true do
      title = "test_page"
      unpublished = false
      edit_roles = "public"

      create_wiki_page(title, unpublished, edit_roles)

      visit_front_page_edit(@course)
      wait_for_tiny(edit_wiki_css)

      click_links_toolbar_button
      click_course_links

      click_pages_accordion
      click_course_item_link(title)

      in_frame rce_page_body_ifr_id do
        expect(wiki_body_anchor.attribute('title')).to include title
      end
    end

    it "should click on sidebar assignment page to create link in body" do
      title = "Assignment-Title"
      @assignment = @course.assignments.create!(:name => title)

      visit_front_page_edit(@course)

      click_links_toolbar_button
      click_course_links

      click_assignments_accordion
      click_course_item_link(title)

      in_frame rce_page_body_ifr_id do
        expect(wiki_body_anchor.attribute('href')).to include assignment_id_path(@course, @assignment)
      end
    end

    it "should click on sidebar quizzes page to create link in body" do
      title = "Quiz-Title"
      @quiz = @course.quizzes.create!(:workflow_state => "available", :title => title)

      visit_front_page_edit(@course)

      click_links_toolbar_button
      click_course_links

      click_quizzes_accordion
      click_course_item_link(title)

      in_frame rce_page_body_ifr_id do
        expect(wiki_body_anchor.attribute('href')).to include quiz_id_path(@course, @quiz)
      end
    end

    it "should click on sidebar announcements page to create link in body" do
      title = "Announcement-Title"
      message = "Announcement 1 detail"
      @announcement = @course.announcements.create!(:title => title, :message => message)

      visit_front_page_edit(@course)

      click_links_toolbar_button
      click_course_links

      click_announcements_accordion
      click_course_item_link(title)

      in_frame rce_page_body_ifr_id do
        expect(wiki_body_anchor.attribute('href')).to include announcement_id_path(@course, @announcement)
      end
    end

    it "should click on sidebar discussions page to create link in body" do
      title = "Discussion-Title"
      @discussion = @course.discussion_topics.create!(:title => title)

      visit_front_page_edit(@course)

      click_links_toolbar_button
      click_course_links

      click_discussions_accordion
      click_course_item_link(title)

      in_frame rce_page_body_ifr_id do
        expect(wiki_body_anchor.attribute('href')).to include discussion_id_path(@course, @discussion)
      end
    end

    it "should click on sidebar modules page to create link in body" do
      title = "Module-Title"
      @module = @course.context_modules.create!(:name => title)

      visit_front_page_edit(@course)

      click_links_toolbar_button
      click_course_links

      click_modules_accordion
      click_course_item_link(title)

      in_frame rce_page_body_ifr_id do
        expect(wiki_body_anchor.attribute('href')).to include module_id_path(@course, @module)
      end
    end

    it "should click on sidebar course navigation page to create link in body", ignore_js_errors: true do
      title = "Files"
      visit_front_page_edit(@course)

      click_links_toolbar_button
      click_course_links

      click_navigation_accordion
      click_course_item_link(title)

      in_frame rce_page_body_ifr_id do
        expect(wiki_body_anchor.attribute('href')).to include course_file_path(@course)
      end
    end

    it "should click on assignment in sidebar to create link to it in announcement page", ignore_js_errors: true do
      title = "Assignment-Title"
      @assignment = @course.assignments.create!(:name => title)

      visit_new_announcement_page(@course)

      click_links_toolbar_button
      click_course_links

      click_assignments_accordion
      click_course_item_link(title)

      in_frame rce_page_body_ifr_id do
        expect(wiki_body_anchor.attribute('href')).to include assignment_id_path(@course, @assignment)
      end
    end

    it "should click on module in sidebar to create link to it in assignment page", ignore_js_errors: true do
      title = "Module-Title"
      @module = @course.context_modules.create!(:name => title)

      visit_new_assignment_page(@course)

      click_links_toolbar_button
      click_course_links

      click_modules_accordion
      click_course_item_link(title)

      in_frame rce_page_body_ifr_id do
        expect(wiki_body_anchor.attribute('href')).to include module_id_path(@course, @module)
      end
    end

    it "should click on assignment in sidebar to create link to it in discussion page" do
      title = "Assignment-Title"
      @assignment = @course.assignments.create!(:name => title)

      visit_new_discussion_page(@course)

      click_links_toolbar_button
      click_course_links

      click_assignments_accordion
      click_course_item_link(title)

      in_frame rce_page_body_ifr_id do
        expect(wiki_body_anchor.attribute('href')).to include assignment_id_path(@course, @assignment)
      end
    end

    it "should click on assignment in sidebar to create link to it in quiz page" do
      title = "Assignment-Title"
      @assignment = @course.assignments.create!(:name => title)
      @quiz = @course.quizzes.create!

      visit_new_quiz_page(@course, @quiz)

      click_links_toolbar_button
      click_course_links

      click_assignments_accordion
      click_course_item_link(title)

      in_frame rce_page_body_ifr_id do
        expect(wiki_body_anchor.attribute('href')).to include assignment_id_path(@course, @assignment)
      end
    end

    it "should click on assignment in sidebar to create link to it in syllabus page" do
      title = "Assignment-Title"
      @assignment = @course.assignments.create!(:name => title)

      visit_syllabus(@course)
      click_edit_syllabus

      click_links_toolbar_button
      click_course_links

      click_assignments_accordion
      click_course_item_link(title)

      in_frame rce_page_body_ifr_id do
        expect(wiki_body_anchor.attribute('href')).to include assignment_id_path(@course, @assignment)
      end
    end

    it "should click on sidebar images tab" do
      skip('Unskip in CORE-2629')
      visit_front_page_edit(@course)

      click_images_toolbar_button
      click_course_images

      expect(upload_new_image).to be_displayed
    end

    it "should click on an image in sidebar to display in body" do
      title = "email.png"
      @root_folder = Folder.root_folders(@course).first
      @image = @root_folder.attachments.build(:context => @course)
      path = File.expand_path(File.dirname(__FILE__) + '/../../../public/images/email.png')
      @image.uploaded_data = Rack::Test::UploadedFile.new(path, Attachment.mimetype(path))
      @image.save!

      visit_front_page_edit(@course)

      click_more_toolbar_button
      click_images_toolbar_button
      click_course_images

      click_image_link(title)

      in_frame tiny_rce_ifr_id do
        expect(wiki_body_image.attribute('src')).to include course_file_id_path(@image)
      end
    end

    it "should display assignment publish status in links accordion" do
      skip('Unskip in CORE-2619')
      title = "Assignment-Title"
      @assignment = @course.assignments.create!(:name => title, :status => published)

      visit_new_announcement_page(@course)

      click_links_toolbar_button
      click_course_links
      click_assignments_accordion

      expect(assignment_published_status).to be_displayed

      @assignment.save!(:status => unpublished)
      visit_new_announcement_page(@course)

      click_links_toolbar_button
      click_course_links
      click_assignments_accordion

      expect(assignment_unpublished_status).to be_displayed
    end

    it "should display assignment due date in links accordion" do
      skip('Unskip in CORE-2619')
      title = "Assignment-Title"
      due_at = 3.days.from_now
      @assignment = @course.assignments.create!(:name => title, :status => published, due_at: @due_at)

      visit_new_announcement_page

      click_links_toolbar_button
      click_course_links
      click_assignments_accordion

      expect(assignment_due_date).to eq date_string(due_at, :no_words)
    end
  end
end
