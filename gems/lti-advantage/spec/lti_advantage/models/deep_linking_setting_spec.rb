# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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
  RSpec.describe DeepLinkingSetting do
    let(:setting) { DeepLinkingSetting.new }

    describe "initialize" do
      it "allows initializing with attributes" do
        new_setting = DeepLinkingSetting.new(accept_types: ["foo"])
        expect(new_setting.accept_types).to match_array [
          "foo"
        ]
      end
    end

    describe "validations" do
      it "is valid of all required attributes are present" do
        expect(
          DeepLinkingSetting.new(
            accept_types: ["foo"],
            accept_presentation_document_targets: ["bar"],
            deep_link_return_url: "http://test.com/return"
          )
        ).to be_valid
      end

      it 'is not valid if "accept_types" is blank' do
        expect(
          DeepLinkingSetting.new(
            accept_types: [],
            accept_presentation_document_targets: ["bar"]
          )
        ).not_to be_valid
      end

      it 'is not valid if "accept_presentation_document_targets" is blank' do
        expect(
          DeepLinkingSetting.new(
            accept_types: ["foo"],
            accept_presentation_document_targets: []
          )
        ).not_to be_valid
      end

      it 'verifies "accept_types" is an array' do
        setting.accept_types = "foo"
        setting.validate
        expect(setting.errors[:accept_types]).to match_array [
          "accept_types must be an instance of Array"
        ]
      end

      it 'verifies "accept_media_types" is an array' do
        setting.accept_media_types = ["foo"]
        setting.validate
        expect(setting.errors[:accept_media_types]).to match_array [
          "accept_media_types must be an instance of String"
        ]
      end

      it 'verifies "accept_presentation_document_targets" is an array' do
        setting.accept_presentation_document_targets = "foo"
        setting.validate
        expect(setting.errors[:accept_presentation_document_targets]).to match_array [
          "accept_presentation_document_targets must be an instance of Array"
        ]
      end
    end
  end
end
