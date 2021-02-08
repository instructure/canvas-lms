# frozen_string_literal: true

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

describe "Wiki pages and Tiny WYSIWYG editor Images" do
  include_context "in-process server selenium tests"
  include WikiAndTinyCommon
  include RCSSidebarPage

  context "wiki and tiny images as a student" do

    before(:each) do
      stub_rcs_config
      course_factory(active_course: true, :name => 'wiki course')
      @student = user_with_pseudonym(:active_user => true, :username => 'student@example.com', :name => 'student@example.com', :password => 'asdfasdf')
      @teacher = user_with_pseudonym(:active_user => true, :username => 'teacher@example.com', :name => 'teacher@example.com', :password => 'asdfasdf')
      @course.enroll_student(@student).accept
      @course.enroll_teacher(@teacher).accept
    end

    it "should add an image to the page and validate a student can see it" do
      skip('LA-365')
      create_session(@teacher.pseudonym)
      add_image_to_rce

      @course.wiki_pages.first.publish!

      create_session(@student.pseudonym)
      get "/courses/#{@course.id}/pages/front-page"
      expect(f("#wiki_page_show img")['src']).to include("/courses/#{@course.id}/files/#{@course.attachments.last.id}/download")
    end
  end
end
