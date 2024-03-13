# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

describe Lti::ToolDefaultIconController do
  describe "#show" do
    render_views

    it "generates an SVG icon" do
      get :show, params: { name: "test", id: 1 }
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq("image/svg+xml; charset=utf-8")
    end

    it 'uses the first number/"letter-like" character in the name, capitalized, or none' do
      expectations = {
        "abc" => "A",
        "  def" => "D",
        "...1a" => "1",
        "...我a" => "我",
        "!!!..." => "",
        "😅" => ""
      }

      expectations.each do |name, expected_glyph|
        get :show, params: { name:, id: 1 }
        expect(response.body).to include(">#{expected_glyph}</text>")
      end
    end

    it "uses a color based on the hash of the developer key / tool (global) ID" do
      id = 1
      hash = id.to_s.hash
      color = Lti::ToolDefaultIconController::COLORS[hash % Lti::ToolDefaultIconController::COLORS.length]

      get :show, params: { name: "test", id: }
      expect(response.body).to include("fill=\"#{color}\"")
    end
  end
end
