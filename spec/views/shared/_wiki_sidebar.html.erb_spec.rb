#
# Copyright (C) 2011 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../views_helper')

describe "/shared/_wiki_sidebar" do
  it "should render" do
    course_with_student
    view_context
    render :partial => "shared/wiki_sidebar"
    expect(response).not_to be_nil
  end
  
  it "should render in user context" do
    user_factory
    view_context(@user, @user)
    render :partial => "shared/wiki_sidebar"
    expect(response).not_to be_nil
  end

  it "correctly checks wiki permissions" do
    course_with_teacher
    view_context
    render :partial => "shared/wiki_sidebar"
    expect(response).not_to be_nil
    expect(response).to match(/new_page_link/)
  end

  it "should differenticate discussions/announcements" do
    course_with_teacher
    view_context
    assigns[:wiki_sidebar_data] = {
      active_assignments: [],
      active_discussion_topics: [
        @course.discussion_topics.create!(title: "please chat", message: "DD"),
        @course.announcements.create!(title: "listen up", message: "HI")
      ],
      active_quizzes: [],
      active_context_modules: [],
      wiki_pages: [],
      wiki: nil,
      root_folders: []
    }
    render :partial => "shared/wiki_sidebar"
    doc = Nokogiri::HTML.parse(response.body)
    expect(doc.at_css("#announcements_panel").text).to match(/listen up/)
    expect(doc.at_css("#announcements_panel").text).not_to match(/please chat/)
    expect(doc.at_css("#discussions_panel").text).not_to match(/listen up/)
    expect(doc.at_css("#discussions_panel").text).to match(/please chat/)
  end
end
