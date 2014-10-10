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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe WikiPagesController do
  describe "GET 'front_page'" do
    it "should redirect with draft state enabled" do
      course_with_teacher_logged_in(:active_all => true)
      @course.enable_feature!(:draft_state)
      get 'front_page', :course_id => @course.id
      expect(response).to be_redirect
      expect(response.location).to match(%r{/courses/#{@course.id}/pages})
    end
  end

  describe "GET 'show_redirect'" do
    it "should redirect with draft state enabled" do
      course_with_teacher_logged_in(:active_all => true)
      @course.enable_feature!(:draft_state)
      page = @course.wiki.wiki_pages.create!(:title => "blah", :body => "")
      get 'show_redirect', :course_id => @course.id, :id => page.url
      expect(response).to be_redirect
      expect(response.location).to match(%r{/courses/#{@course.id}/pages/#{page.url}})
    end
  end

end
