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

describe WikiPageRevisionsController do
  describe "PUT 'update'" do
    it "should redirect to the right course wiki page" do
      course_with_teacher_logged_in(:active_all => true)
      @page = @course.wiki.wiki_pages.create!(:title => "a page")
      @page.title = "a better page title"
      @page.save!

      @version = @page.reload.versions.first
      put 'update', :course_id => @course.id, :wiki_page_id => @page.id, :id => @version.id
      response.should be_redirect
      response.location.should match(%r{/courses/#{@course.id}/wiki})
    end

    it "should redirect to the right group wiki page" do
      course_with_teacher_logged_in(:active_all => true)
      gcs = @course.group_categories.create!
      @group = gcs.groups.create(:context => @course)
      @page = @group.wiki.wiki_pages.create!(:title => "a page")
      @page.title = "a better page title"
      @page.save!

      @version = @page.reload.versions.first
      put 'update', :group_id => @group.id, :wiki_page_id => @page.id, :id => @version.id
      response.should be_redirect
      response.location.should match(%r{/groups/#{@group.id}/wiki})
    end
  end
end
