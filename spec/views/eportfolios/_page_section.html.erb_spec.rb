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

describe "/eportfolios/_page_section" do
  it "should render" do
    eportfolio_with_user
    view_portfolio
    assigns[:category] = category = @portfolio.eportfolio_categories.create!(:name => "some category")
    assigns[:page] = @portfolio.eportfolio_entries.create!(:name => "some entry", :eportfolio_category => category)
    render :partial => "eportfolios/page_section", :object => {"section_type" => "rich_text", "content" => "some text"}, :locals => {:idx => 0}
    expect(response).to have_tag("div.section")
  end
end

