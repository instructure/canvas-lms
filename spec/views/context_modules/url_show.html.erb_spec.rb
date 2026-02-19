# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

describe "context_modules/url_show" do
  it "renders iframe for non-new-tab external URLs" do
    course_factory
    view_context(@course, @user)
    @module = @course.context_modules.create!(name: "teh module")
    @tag = @module.add_item(type: "external_url",
                            url: "http://example.com/lolcats",
                            title: "pls view")
    assign(:module, @module)
    assign(:tag, @tag)
    render "context_modules/url_show"
    doc = Nokogiri::HTML5(response.body)
    expect(doc.at_css("iframe")["src"]).to eq "http://example.com/lolcats"
    expect(doc.css("a").collect { |a| [a["href"], a.inner_text] }).to include ["http://example.com/lolcats", "pls view"]
  end

  it "renders message and button for new-tab external URLs" do
    course_factory
    view_context(@course, @user)
    @module = @course.context_modules.create!(name: "teh module")
    @tag = @module.add_item(type: "external_url",
                            url: "http://example.com/lolcats",
                            title: "pls view",
                            new_tab: true)
    assign(:module, @module)
    assign(:tag, @tag)
    render "context_modules/url_show"
    doc = Nokogiri::HTML5(response.body)

    expect(doc.text).to include("This site was opened in a new browser window")
    expect(doc.text).to include("If it didn't open automatically, select the button below")
    expect(doc.at_css("#open_url_button")["href"]).to eq "http://example.com/lolcats"
    expect(doc.at_css("#open_url_button").inner_text.strip).to eq "Open pls view in a new window"

    script_content = doc.at_css("script").inner_text
    expect(script_content).to include("click()")
  end
end
