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
require 'model_view'

describe ModelView do
  let(:text) { "Example\n{ \"properties\": [] }" }
  let(:model) { double('Model', :text => text) }

  it "is created from model" do
    view = ModelView.new_from_model(model)
    expect(view.name).to eq "Example"
    expect(view.properties).to eq []
  end

  it "generates a schema" do
    view = ModelView.new("Example", {"name" => {"type" => "string"}})
    expect(view.json_schema).to eq({
      "Example" => {
        "id" => "Example",
        "properties" => {
          "name" => {
            "type" => "string"
          }
        },
        "description" => "",
        "required" => []
      }
    })
  end
end
