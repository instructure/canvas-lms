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

require "lti_advantage"

module LtiAdvantage::Models
  RSpec.describe PnsNoticeClaim do
    let(:valid_attributes) do
      {
        id: "12345",
        timestamp: "2024-01-01T00:00:00Z",
        type: "example_type"
      }
    end

    let(:invalid_attributes) do
      {
        id: nil,
        timestamp: nil,
        type: nil
      }
    end

    let(:attributes_with_invalid_types) do
      {
        id: "id",
        timestamp: "timestamp",
        type: 123
      }
    end

    describe "validations" do
      it "is valid with valid attributes" do
        claim = PnsNoticeClaim.new(valid_attributes)
        expect(claim).to be_valid
      end

      it "is not valid with invalid attribute types" do
        claim = PnsNoticeClaim.new(attributes_with_invalid_types)
        expect(claim).not_to be_valid
      end

      it "is not valid without required attributes" do
        claim = PnsNoticeClaim.new(invalid_attributes)
        expect(claim).not_to be_valid
      end
    end

    describe "#attributes" do
      it "returns a hash of the instance values" do
        claim = PnsNoticeClaim.new(valid_attributes)
        expect(claim.attributes).to eq(valid_attributes.stringify_keys)
      end
    end
  end
end
