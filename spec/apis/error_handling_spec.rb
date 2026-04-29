# frozen_string_literal: true

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

require_relative "api_spec_helper"

describe "API Error Handling", type: :request do
  before :once do
    user_with_pseudonym(active_all: true)
    enable_default_developer_key!
    @token = @user.access_tokens.create!(purpose: "Test")
  end

  it "responds not_found for 404 errors" do
    get "/api/v1/courses/54321", headers: { "Authorization" => "Bearer #{@token.full_token}" }
    expect(response.response_code).to eq 404
    json = JSON.parse(response.body)
    expect(json["errors"]).to eq [{ "message" => "The specified resource does not exist." }]
  end
end
