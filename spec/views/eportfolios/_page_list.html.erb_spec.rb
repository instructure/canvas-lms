# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

require_relative "../views_helper"

describe "eportfolios/_page_list" do
  before(:once) do
    eportfolio_with_user
  end

  it "renders" do
    view_portfolio
    category = assign(:category, @portfolio.eportfolio_categories.create!(name: "some category"))
    assign(:page, @portfolio.eportfolio_entries.create!(name: "some entry", eportfolio_category: category))
    render partial: "eportfolios/page_list"
    expect(response).not_to be_nil
  end

  it "render,s even if a eportfolio entry name is blank" do
    view_portfolio
    category = assign(:category, @portfolio.eportfolio_categories.create!(name: "some category"))
    assign(:page, @portfolio.eportfolio_entries.create!(name: "", eportfolio_category: category))
    render partial: "eportfolios/page_list"
    expect(response).not_to be_nil
  end

  it "renders even with a blank category slug" do
    view_portfolio
    category = assign(:category, @portfolio.eportfolio_categories.create!(name: "+++"))
    assign(:page, @portfolio.eportfolio_entries.create!(name: "some entry", eportfolio_category: category))
    render partial: "eportfolios/page_list"
    expect(response).not_to be_nil
  end
end
