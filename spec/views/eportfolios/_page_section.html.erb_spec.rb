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

describe "eportfolios/_page_section" do
  it "renders" do
    eportfolio_with_user
    view_portfolio
    category = assign(:category, @portfolio.eportfolio_categories.create!(name: "some category"))
    assign(:page, @portfolio.eportfolio_entries.create!(name: "some entry", eportfolio_category: category))
    render partial: "eportfolios/page_section", object: { "section_type" => "rich_text", "content" => "some text" }, locals: { idx: 0 }
    expect(response).to have_tag("div.section")
  end

  context "sharding" do
    specs_require_sharding

    it "renders cross-shard attachments" do
      @shard2.activate do
        eportfolio_with_user
        category = assign(:category, @portfolio.eportfolio_categories.create!(name: "some category"))
        @page = @portfolio.eportfolio_entries.create!(name: "some entry", eportfolio_category: category)
        attachment = @user.attachments.create! display_name: "my cross-shard attachment", uploaded_data: default_uploaded_data
        @page.update content: [{ section_type: "attachment", attachment_id: attachment.id }]
      end
      view_portfolio
      assign(:page, @page)
      render partial: "eportfolios/page_section", object: @page.content_sections.first, locals: { idx: 0 }
      expect(response).to match(/my cross-shard attachment/)
    end
  end
end
