# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

describe Auditors::ActiveRecord::Attributes do
  describe "treating a model like it has event stream attributes" do
    before do
      @model_type = Class.new(Hash) do
        include Auditors::ActiveRecord::Attributes
      end
    end

    it "transparently fetches values using parent interface" do
      model = @model_type.new
      model["attr_one"] = "parent_hash_one"
      model["attr_two"] = "parent_hash_two"
      expect(model["attributes"]["attr_one"]).to eq("parent_hash_one")
      expect(model["attributes"].fetch("attr_two")).to eq("parent_hash_two")
    end

    it "sets values through the attributes interface" do
      model = @model_type.new
      model["attributes"]["method_three"] = :four
      expect(model["attributes"].fetch("method_three")).to eq(:four)
    end
  end
end
