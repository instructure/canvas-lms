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

describe "/eportfolios/show" do
  before do
    eportfolio_with_user
    view_portfolio
    assigns[:category] = @portfolio.eportfolio_categories.create!(:name => "some category")
    assigns[:categories] = [assigns[:category]]
    assigns[:recent_submissions] = []
    assigns[:folders] = []
    assigns[:files] = []
    assigns[:page] = @portfolio.eportfolio_entries.create!(:name => "some entry", :eportfolio_category => assigns[:category])
  end

  it "should render" do
    render "eportfolios/show"
    response.should_not be_nil
  end

  it "should not link the user name if @owner_url is not set" do
    render "eportfolios/show"
    view.content_for(:left_side)[/<a [^>]*id="section-tabs-header-subtitle"/].should be_nil
    view.content_for(:left_side)[/<span [^>]*id="section-tabs-header-subtitle"/].should_not be_nil
  end

  it "should link the user name if @owner_url is set" do
    assigns[:owner_url] = user_url(@portfolio.user)
    render "eportfolios/show"
    view.content_for(:left_side)[assigns[:owner_url]].should_not be_nil
    view.content_for(:left_side)[/<a [^>]*id="section-tabs-header-subtitle"/].should_not be_nil
    view.content_for(:left_side)[/<span [^>]*id="section-tabs-header-subtitle"/].should be_nil
  end
end

