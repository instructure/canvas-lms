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

describe "/shared/_select_content_dialog" do
  it "should alphabetize the file list" do
    course_with_teacher
    folder = @course.folders.create!(:name => 'test')
    folder.attachments.create!(:context => @course, :uploaded_data => default_uploaded_data, :display_name => "b")
    folder.attachments.create!(:context => @course, :uploaded_data => default_uploaded_data, :display_name => "a")
    view_context
    render :partial => "shared/select_content_dialog"
    response.should_not be_nil
    page = Nokogiri(response.body)
    options = page.css("#attachments_select .module_item_select option")
    options[0].text.should == "a"
    options[1].text.should == "b"
  end

  it "should include unpublished wiki pages" do
    Account.default.enable_feature!(:draft_state)
    course_with_teacher
    published_page = @course.wiki.wiki_pages.build title: 'published_page'
    published_page.workflow_state = 'active'
    published_page.save!
    unpublished_page = @course.wiki.wiki_pages.build title: 'unpublished_page'
    unpublished_page.workflow_state = 'unpublished'
    unpublished_page.save!
    view_context
    render partial: 'shared/select_content_dialog'
    page = Nokogiri(response.body)
    options = page.css("#wiki_pages_select .module_item_select option")
    (%w(unpublished_page published_page) - options.map(&:text)).should be_empty
  end
end

