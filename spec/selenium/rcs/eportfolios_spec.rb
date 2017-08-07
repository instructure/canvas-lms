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

require File.expand_path(File.dirname(__FILE__) + '/../common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/eportfolios_common')

describe "eportfolios" do
  include_context "in-process server selenium tests"
  include EportfoliosCommon

  before(:each) do
    course_with_student_logged_in
    enable_all_rcs @course.account
    stub_rcs_config
  end

  context "eportfolio created with user" do
    before(:each) do
      eportfolio_model({:user => @user, :name => "student content"})
    end

    it "should have a working flickr search dialog" do
      skip_if_chrome('fragile in chrome')
      get "/eportfolios/#{@eportfolio.id}"
      f("#page_list a.page_url").click
      expect(f("#page_list a.page_url")).to be_displayed
      f("#page_sidebar .edit_content_link").click
      expect(f('.add_content_link.add_rich_content_link')).to be_displayed
      f('.add_content_link.add_rich_content_link').click
      expect(f('.mce-container')).to be_displayed
      f(".mce-container div[aria-label='Embed Image']").click
      expect(f('a[href="#tabFlickr"]')).to be_displayed
      f('a[href="#tabFlickr"]').click
      expect(f('form.FindFlickrImageView')).to be_displayed
    end
  end
end
