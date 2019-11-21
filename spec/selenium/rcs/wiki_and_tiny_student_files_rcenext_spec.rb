#
# Copyright (C) 2012 - present Instructure, Inc.
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
require_relative 'pages/rce_next_page'

describe "Wiki pages and Tiny WYSIWYG editor Files" do
  include_context "in-process server selenium tests"
  include WikiAndTinyCommon
  include RCSSidebarPage
  include RCENextPage

  context "wiki and tiny files as a student" do
    before(:each) do
      Account.default.enable_feature!(:rce_enhancements)
      stub_rcs_config
      course_factory(active_all: true, :name => 'wiki course')
      @student = user_with_pseudonym(:active_user => true, :username => 'student@example.com', :name => 'student@example.com', :password => 'asdfasdf')
      @teacher = user_with_pseudonym(:active_user => true, :username => 'teacher@example.com', :name => 'teacher@example.com', :password => 'asdfasdf')
      @course.enroll_student(@student).accept
      @course.enroll_teacher(@teacher).accept
    end

    it "should add a file to the page and validate a student can see it" do
      create_session(@teacher.pseudonym)

      add_file_to_rce_next
      @course.wiki_pages.first.publish!
      create_session(@student.pseudonym)
      get "/courses/#{@course.id}/pages/front-page"
      expect(f('a[title="Link"]')).to include_text("text_file.txt")
    end
  end

  context "wiki sidebar images and locking/hiding" do
    before(:each) do
      Account.default.enable_feature!(:rce_enhancements)
      stub_rcs_config
      course_with_teacher(:active_all => true, :name => 'wiki course')
      @student = user_with_pseudonym(:active_user => true, :username => 'student@example.com', :name => 'student@example.com', :password => 'asdfasdf')
      @course.enroll_student(@student).accept
      user_session(@student)
      @root_folder = Folder.root_folders(@course).first
      @sub_folder = @root_folder.sub_folders.create!(:name => "subfolder", :context => @course)

      @visible_attachment = @course.attachments.build(:filename => 'foo.png', :folder => @root_folder)
      @visible_attachment.content_type = 'image/png'
      @visible_attachment.save!

      @attachment = @course.attachments.build(:filename => 'foo2.png', :folder => @sub_folder)
      @attachment.content_type = 'image/png'
      @attachment.save!

      @user_attachment = @user.attachments.build(:filename => 'bar.png', :context => @student)
      @user_attachment.content_type = 'image/png'
      @user_attachment.save!
    end

    it "should show one image in student image sidebar" do
      get "/courses/#{@course.id}/discussion_topics/new"
      click_images_toolbar_button
      click_user_images
      expect(user_image_links.count).to eq 1
      expect(tray_container).to include_text("bar.png")
    end

    it "should only show one image for student after saving additional to course" do
      @new_attachment = @course.attachments.build(:filename => 'new_course.png', :folder => @root_folder)
      @new_attachment.content_type = 'image/png'
      @new_attachment.save!
      get "/courses/#{@course.id}/discussion_topics/new"
      click_images_toolbar_button
      click_user_images
      expect(user_image_links.count).to eq 1
      expect(tray_container).to include_text("bar.png")
    end
  end
end
