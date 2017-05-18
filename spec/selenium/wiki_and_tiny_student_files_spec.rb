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

require File.expand_path(File.dirname(__FILE__) + '/helpers/wiki_and_tiny_common')

describe "Wiki pages and Tiny WYSIWYG editor Files" do
  include_context "in-process server selenium tests"
  include WikiAndTinyCommon

  context "wiki and tiny files as a student" do
    before(:each) do
      course_factory(active_all: true, :name => 'wiki course')
      @student = user_with_pseudonym(:active_user => true, :username => 'student@example.com', :name => 'student@example.com', :password => 'asdfasdf')
      @teacher = user_with_pseudonym(:active_user => true, :username => 'teacher@example.com', :name => 'teacher@example.com', :password => 'asdfasdf')
      @course.enroll_student(@student).accept
      @course.enroll_teacher(@teacher).accept
    end

    it "should add a file to the page and validate a student can see it" do
      create_session(@teacher.pseudonym)

      add_file_to_rce
      @course.wiki.wiki_pages.first.publish!
      create_session(@student.pseudonym)
      get "/courses/#{@course.id}/pages/front-page"
      expect(fj('a[title="text_file.txt"]')).to be_displayed
      #check_file would be good to do here but the src on the file in the wiki body is messed up
    end
  end

  context "wiki sidebar files and locking/hiding" do
    before(:each) do
      course_with_teacher(:active_all => true, :name => 'wiki course')
      @student = user_with_pseudonym(:active_user => true, :username => 'student@example.com', :name => 'student@example.com', :password => 'asdfasdf')
      @course.enroll_student(@student).accept
      user_session(@student)
      @root_folder = Folder.root_folders(@course).first
      @sub_folder = @root_folder.sub_folders.create!(:name => "visible subfolder", :context => @course)
    end

    it "should not show root folder in the sidebar if it is locked" do
      @root_folder.locked = true
      @root_folder.save!

      get "/courses/#{@course.id}/discussion_topics/new"
      expect(f('#editor_tabs')).to be_displayed
      f('#editor_tabs .ui-tabs-nav li:nth-child(2) a').click
      expect(f("#content")).not_to contain_css('li.folder')
    end

    it "should not show root folder in the sidebar if it is hidden" do
      @root_folder.workflow_state = 'hidden'
      @root_folder.save!

      get "/courses/#{@course.id}/discussion_topics/new"
      expect(f('#editor_tabs')).to be_displayed
      f('#editor_tabs .ui-tabs-nav li:nth-child(2) a').click
      expect(f("#content")).not_to contain_css('li.folder')
    end

    it "should not show root folder in the sidebar if the files navigation tab is hidden" do
      @course.tab_configuration = [{:id => Course::TAB_FILES, :hidden => true}]
      @course.save!

      get "/courses/#{@course.id}/discussion_topics/new"
      expect(f('#editor_tabs')).to be_displayed
      f('#editor_tabs .ui-tabs-nav li:nth-child(2) a').click
      expect(f("#content")).not_to contain_css('li.folder')
    end

    it "should not show sub-folder in the sidebar if it is locked" do
      @root_folder.sub_folders.create!(:name => "subfolder", :context => @course, :locked => true)

      get "/courses/#{@course.id}/discussion_topics/new"
      expect(f('#editor_tabs')).to be_displayed
      f('#editor_tabs .ui-tabs-nav li:nth-child(2) a').click
      expect(f('li.folder')).not_to be_nil
      f('li.folder span.plus').click
      wait_for_ajaximations
      expect(ff('li.folder li.folder').count).to eq 1
      expect(f('li.folder li.folder .name')).to include_text("visible subfolder")
    end

    it "should not show sub-folder in the sidebar if it is hidden" do
      @root_folder.sub_folders.create!(:name => "subfolder", :context => @course, :workflow_state => 'hidden')

      get "/courses/#{@course.id}/discussion_topics/new"
      expect(f('#editor_tabs')).to be_displayed
      f('#editor_tabs .ui-tabs-nav li:nth-child(2) a').click
      expect(f('li.folder')).not_to be_nil
      f('li.folder span.plus').click
      wait_for_ajaximations
      expect(ff('li.folder li.folder').count).to eq 1
      expect(f('li.folder li.folder .name')).to include_text("visible subfolder")
    end

    it "should not show file in the sidebar if it is hidden" do
      visible_attachment = attachment_model(:uploaded_data => stub_file_data('foo.txt', nil, 'text/html'), :content_type => 'text/html')
      attachment = attachment_model(:uploaded_data => stub_file_data('foo2.txt', nil, 'text/html'), :content_type => 'text/html')

      attachment.file_state = 'hidden'
      attachment.save!

      get "/courses/#{@course.id}/discussion_topics/new"
      expect(f('#editor_tabs')).to be_displayed
      f('#editor_tabs .ui-tabs-nav li:nth-child(2) a').click
      f('li.folder span.plus').click
      wait_for_ajaximations
      expect(ff('li.folder li.file').count).to eq 1
      expect(f('li.folder li.file .name')).to include_text("foo.txt")
    end

    it "should not show file in the sidebar if it is locked" do
      visible_attachment = attachment_model(:uploaded_data => stub_file_data('foo.txt', nil, 'text/html'), :content_type => 'text/html')
      attachment = attachment_model(:uploaded_data => stub_file_data('foo2.txt', nil, 'text/html'), :content_type => 'text/html')

      attachment.locked = true
      attachment.save!

      get "/courses/#{@course.id}/discussion_topics/new"
      expect(f('#editor_tabs')).to be_displayed
      f('#editor_tabs .ui-tabs-nav li:nth-child(2) a').click
      f('li.folder span.plus').click
      expect(ff('li.folder li.file')).to have_size(1)
      expect(f('li.folder li.file .name')).to include_text("foo.txt")
    end
  end

  context "wiki sidebar images and locking/hiding" do
    before(:each) do
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
    end

    it "should not show image files if their containing folder is locked" do
      @sub_folder.locked = true
      @sub_folder.save!

      get "/courses/#{@course.id}/discussion_topics/new"
      expect(f('#editor_tabs')).to be_displayed
      f('#editor_tabs .ui-tabs-nav li:nth-child(3) a').click
      wait_for_ajaximations
      expect(ff('.image_list img.img').count).to eq 1
      expect(f('.image_list img.img')['alt']).to eq "foo.png"
    end

    it "should not show image files if their containing folder is hidden" do
      @sub_folder.workflow_state = 'hidden'
      @sub_folder.save!

      get "/courses/#{@course.id}/discussion_topics/new"
      expect(f('#editor_tabs')).to be_displayed
      f('#editor_tabs .ui-tabs-nav li:nth-child(3) a').click
      wait_for_ajaximations
      expect(ff('.image_list img.img').count).to eq 1
      expect(f('.image_list img.img')['alt']).to eq "foo.png"
    end

    it "should not show any image files if the files navigation tab is hidden" do

      @course.tab_configuration = [{:id => Course::TAB_FILES, :hidden => true}]
      @course.save!

      get "/courses/#{@course.id}/discussion_topics/new"
      expect(f('#editor_tabs')).to be_displayed
      images_link = f('#editor_tabs .ui-tabs-nav li:nth-child(2) a')
      expect(images_link.text).to match(/Images/i) #files tab should be missingp
      images_link.click
      wait_for_ajaximations
      expect(f('.image_list')).not_to contain_css('img.img')
    end

    it "should not show image files if they are hidden" do
      @attachment.file_state = 'hidden'
      @attachment.save!

      get "/courses/#{@course.id}/discussion_topics/new"
      expect(f('#editor_tabs')).to be_displayed
      f('#editor_tabs .ui-tabs-nav li:nth-child(3) a').click
      wait_for_ajaximations
      expect(ff('.image_list img.img').count).to eq 1
      expect(f('.image_list img.img')['alt']).to eq "foo.png"
    end

    it "should not show image files if they are locked" do
      @attachment.locked = true
      @attachment.save!

      get "/courses/#{@course.id}/discussion_topics/new"
      expect(f('#editor_tabs')).to be_displayed
      f('#editor_tabs .ui-tabs-nav li:nth-child(3) a').click
      wait_for_ajaximations
      expect(ff('.image_list img.img').count).to eq 1
      expect(f('.image_list img.img')['alt']).to eq "foo.png"
    end
  end
end
