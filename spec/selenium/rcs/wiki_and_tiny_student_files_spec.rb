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

describe "Wiki pages and Tiny WYSIWYG editor Files" do
  include_context "in-process server selenium tests"
  include WikiAndTinyCommon
  include RCSSidebarPage

  context "wiki and tiny files as a student" do
    before(:each) do
      stub_rcs_config
      course_factory(active_all: true, :name => 'wiki course')
      @student = user_with_pseudonym(:active_user => true, :username => 'student@example.com', :name => 'student@example.com', :password => 'asdfasdf')
      @teacher = user_with_pseudonym(:active_user => true, :username => 'teacher@example.com', :name => 'teacher@example.com', :password => 'asdfasdf')
      @course.enroll_student(@student).accept
      @course.enroll_teacher(@teacher).accept
    end

    it "should add a file to the page and validate a student can see it" do
      create_session(@teacher.pseudonym)

      add_file_to_rce
      @course.wiki_pages.first.publish!
      create_session(@student.pseudonym)
      get "/courses/#{@course.id}/pages/front-page"
      expect(f('a[title="text_file.txt"]')).to be_displayed
      # check_file would be good to do here but the src on the file in the wiki body is messed up
    end
  end

  context "wiki sidebar files and locking/hiding" do
    before(:each) do
      stub_rcs_config
      course_with_teacher(:active_all => true, :name => 'wiki course')
      @student = user_with_pseudonym(:active_user => true, :username => 'student@example.com', :name => 'student@example.com', :password => 'asdfasdf')
      @course.enroll_student(@student).accept
      user_session(@student)
      @root_folder = Folder.root_folders(@course).first
      @sub_folder = @root_folder.sub_folders.create!(:name => "visible subfolder", :context => @course)
    end

    it "should not show files tab if root folder is locked", ignore_js_errors: true do
      @root_folder.locked = true
      @root_folder.save!

      get "/courses/#{@course.id}/discussion_topics/new"
      expect(f('#editor_tabs')).not_to contain_jqcss('[role="presentation"]:contains("Files")')
    end
  end
end
