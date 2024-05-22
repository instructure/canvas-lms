# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

module Lti
  describe ResourcePlacement do
    describe "validations" do
      it "requires a resource_handler" do
        subject.save
        expect(subject.errors.first).to eq [:message_handler, "can't be blank"]
      end

      it "accepts types in PLACEMENT_LOOKUP" do
        subject.placement = ResourcePlacement::PLACEMENT_LOOKUP.values.first
        subject.save
        expect(subject.errors).to_not include(:placement)
      end
    end

    describe ".valid_placements" do
      it "does not include conference_selection when FF disabled" do
        expect(described_class.valid_placements(Account.default)).not_to include(:conference_selection)
      end

      it "includes conference_selection when FF enabled" do
        Account.site_admin.enable_feature! :conference_selection_lti_placement
        expect(described_class.valid_placements(Account.default)).to include(:conference_selection)
      end

      it "includes submission_type_selection when FF enabled" do
        expect(described_class.valid_placements(Account.default)).to include(:submission_type_selection)
      end
    end

    describe ".public_placements" do
      it "does not include submission_type_selection" do
        expect(described_class.public_placements(Account.default)).not_to include(:submission_type_selection)
      end

      it "contains common placements" do
        expect(described_class.public_placements(Account.default)).to include(:assignment_selection, :course_navigation, :link_selection)
      end

      context "when the feature remove_submission_type_selection_from_dev_keys_edit_page flag is disabled" do
        it "includes submission_type_selection" do
          Account.default.disable_feature! :remove_submission_type_selection_from_dev_keys_edit_page
          expect(described_class.public_placements(Account.default)).to include(:submission_type_selection)
        end
      end
    end

    describe ".supported_message_type?" do
      subject do
        described_class.method(:supported_message_type?)
      end

      it "returns false when no placement is passed in" do
        expect(subject.call(nil, "message_type")).to be false
      end

      it "returns true when no message_type is passed in" do
        expect(subject.call(Lti::ResourcePlacement::PLACEMENTS.first, nil)).to be true
      end

      it "returns false if an invalid placement is passed in" do
        expect(subject.call("invalid_placement", LtiAdvantage::Messages::DeepLinkingRequest::MESSAGE_TYPE)).to be false
      end

      it "returns false if a valid placement but unsupported message_type is passed in" do
        expect(subject.call(:course_navigation, LtiAdvantage::Messages::DeepLinkingRequest::MESSAGE_TYPE)).to be false
      end

      it "returns true if a valid placement is passed in" do
        expect(subject.call(:assignment_selection, LtiAdvantage::Messages::DeepLinkingRequest::MESSAGE_TYPE)).to be true
      end

      it "works with strings and symbols for the placement" do
        expect(subject.call("assignment_selection", LtiAdvantage::Messages::DeepLinkingRequest::MESSAGE_TYPE)).to be true
        expect(subject.call(:assignment_selection, LtiAdvantage::Messages::DeepLinkingRequest::MESSAGE_TYPE)).to be true
      end

      it "works with strings and symbols for the message_type" do
        expect(subject.call(:assignment_selection, LtiAdvantage::Messages::DeepLinkingRequest::MESSAGE_TYPE)).to be true
        expect(subject.call(:assignment_selection, LtiAdvantage::Messages::DeepLinkingRequest::MESSAGE_TYPE.to_sym)).to be true
      end

      Lti::ResourcePlacement::PLACEMENTS_BY_MESSAGE_TYPE.each do |message_type, placements|
        placements.each do |placement|
          it "returns true for #{placement} and #{message_type}" do
            expect(subject.call(placement, message_type)).to be true
          end
        end
      end
    end

    describe "update_tabs_and_return_item_banks_tab" do
      let(:tabs_with_item_banks) do
        [
          {
            id: "context_external_tool_1",
            label: "Item Banks",
            css_class: "context_external_tool_1",
            visibility: nil,
            href: :course_external_tool_path,
            external: true,
            hidden: false,
            args: [2, 1]
          }
        ]
      end

      let(:tabs_without_item_banks) do
        [
          {
            id: "context_external_tool_1",
            label: "Another",
            css_class: "context_external_tool_1",
            visibility: nil,
            href: :course_external_tool_path,
            external: true,
            hidden: false,
            args: [2, 1]
          }
        ]
      end

      it "updates item banks tab label" do
        tabs = tabs_with_item_banks
        described_class.update_tabs_and_return_item_banks_tab(tabs, :new_label)
        expect(tabs[0][:label]).to eq :new_label
      end

      it "let tabs as the same" do
        tabs = tabs_without_item_banks
        described_class.update_tabs_and_return_item_banks_tab(tabs)
        expect(tabs).to eq tabs_without_item_banks
      end
    end
  end
end
