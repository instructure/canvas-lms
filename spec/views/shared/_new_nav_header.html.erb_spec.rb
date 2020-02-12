#
# Copyright (C) 2020 - present Instructure, Inc.
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

describe "/shared/_new_nav_header" do
  it "should render courses with logged in user" do
    assign(:domain_root_account, Account.default)
    assign(:current_user, user_factory)
    render "shared/_new_nav_header"
    doc = Nokogiri::HTML(response.body)

    expect(doc.at_css("#global_nav_courses_link")['href']).to eq '/courses'
  end

  it "should not render courses when not logged in" do
    render "shared/_new_nav_header"
    doc = Nokogiri::HTML(response.body)

    expect(doc.at_css("#global_nav_courses_link")).to be_nil
  end
end
