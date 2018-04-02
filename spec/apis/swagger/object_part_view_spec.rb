#
# Copyright (C) 2013 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/swagger_helper')
require 'object_part_view'

describe ObjectPartView do
  let(:name) { "Tag" }
  let(:part) { {"id" => 1, "name" => "Jimmy Wales"} }
  let(:view) { ObjectPartView.new(name, part) }

  it "guesses types" do
    expect(view.guess_type("hey")).to eq({"type" => "string"})
  end

  it "renders properties" do
    expect(view.properties["id"]).to eq(
      {
        "type" => "integer",
        "format" => "int64"
      }
    )
    expect(view.properties["name"]).to eq(
      {
        "type" => "string"
      }
    )
  end
end
