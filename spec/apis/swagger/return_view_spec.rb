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
require 'return_view'

describe ReturnView do
  context "with no type" do
    it "raises an exception" do
      expect { ReturnView.new nil }.to raise_error("@return type required")
    end
  end

  context "with type" do
    let(:view) { ReturnView.new "Type" }

    it "tells its type" do
      expect(view.type).to eq "Type"
    end

    it "is not an array" do
      expect(view.array?).not_to be_truthy
    end

    it "converts to swagger hash" do
      expect(view.to_swagger).to eq({ "type" => "Type" })
    end
  end

  context "with array" do
    let(:view) { ReturnView.new "[Type]" }

    it "tells its type" do
      expect(view.type).to eq "Type"
    end

    it "is an array" do
      expect(view.array?).to be_truthy
    end

    it "converts to swagger hash" do
      expect(view.to_swagger).to eq({ "type" => "array", "items" => { "$ref" => "Type" } })
    end
  end
end
