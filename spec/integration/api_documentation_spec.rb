# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

require "rake"
load File.expand_path("../../lib/tasks/docs.rake", __dir__)

describe "API Documentation" do
  before :once do
    Rake::Task["doc:api"].invoke
  end

  it "renders scopes for accounts#index" do
    get "/doc/api/accounts.html#method.accounts.index"

    expect(response).to be_successful
    doc = Nokogiri::XML(response.body)
    account_index_html = doc.at_css("h2[name='method.accounts.index']").parent
    scopes = account_index_html.css("h3")
    expect(scopes.length).to eq 1
    expect(scopes.first.text.strip).to eq "GET /api/v1/accounts"
  end
end
