# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

require "spec_helper"

describe CanvasSecurity::PageViewJwt do
  describe ".generate" do
    it "generates and decodes a valid jwt token" do
      created_at = DateTime.now
      uid = 1_065_040_302_011
      attributes = {
        request_id: "abcdefg-1234566",
        user_id: uid,
        created_at:
      }
      token = CanvasSecurity::PageViewJwt.generate(attributes)
      expect(token).to be_a(String)
      data = CanvasSecurity::PageViewJwt.decode(token)
      expect(data[:request_id]).to eq("abcdefg-1234566")
      expect(data[:user_id]).to eq(uid)
      expect(data[:created_at]).to eq(created_at.utc.iso8601(2))
    end
  end
end
