# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

require_relative "../../spec_helper"
require_relative "../../lti_spec_helper"

module Lti
  describe AppLaunchCollator do
    include LtiSpecHelper

    let(:account) { Account.create }
    let(:resource_handler) do
      ResourceHandler.create(resource_type_code: "code", name: "resource name", tool_proxy:)
    end

    describe "#launch_definitions" do
      describe "selection properties" do
        subject do
          Lti::AppLaunchCollator.launch_definitions(
            [tool],
            [placement]
          ).first
        end

        let(:placement) { :assignment_selection }
        let(:settings) { {} }
        let(:tool) do
          ContextExternalTool.new(
            name: "Selection Test Tool",
            url: "https://www.test.tool.com",
            consumer_key: "key",
            shared_secret: "secret",
            settings:
          )
        end

        context "with a message type that allows content selection" do
          let(:settings) do
            {
              assignment_selection: {
                message_type: "LtiDeepLinkingRequest",
                selection_width: 1000
              },
              resource_selection: {
                message_type: "LtiDeepLinkingRequest",
                selection_width: 500
              }
            }
          end

          it 'returns the property from the "resource_selection" placement' do
            expect(subject.dig(:placements, :assignment_selection, :selection_width)).to eq 500
          end

          context 'when "resource_selection" is not set' do
            let(:settings) do
              {
                assignment_selection: {
                  message_type: "LtiDeepLinkingRequest",
                  selection_width: 1000
                }
              }
            end

            it 'returns the placement property if "resource_selection" is not set' do
              expect(subject.dig(:placements, :assignment_selection, :selection_width)).to eq 1000
            end
          end
        end

        context "with a message type that does not allow content selection" do
          it "does not set selection properties" do
            expect(subject.dig(:placements, :assignment_selection, :selection_width)).to be_nil
          end
        end
      end

      it "returns lti2 launch definitions" do
        tp = create_tool_proxy
        tp.bindings.create(context: account)
        rh = create_resource_handler(tp)
        mh = create_message_handler(rh)

        placements = ResourcePlacement::LEGACY_DEFAULT_PLACEMENTS
        placements.each { |p| mh.placements.create!(placement: p) }

        tools_collection = described_class.bookmarked_collection(account, placements).paginate(per_page: 100).to_a

        definitions = described_class.launch_definitions(tools_collection, placements)
        expect(definitions.count).to eq 1
        definition = definitions.first
        expect(definition).to eq({
                                   definition_type: mh.class.name,
                                   definition_id: mh.id,
                                   name: rh.name,
                                   description: rh.description,
                                   domain: "samplelaunch",
                                   placements: {
                                     link_selection: {
                                       message_type: "basic-lti-launch-request",
                                       url: "https://samplelaunch/blti",
                                       title: rh.name
                                     },
                                     assignment_selection: {
                                       message_type: "basic-lti-launch-request",
                                       url: "https://samplelaunch/blti",
                                       title: rh.name
                                     }
                                   }
                                 })
      end

      it "returns an external tool definition" do
        tool = new_valid_external_tool(account)
        placements = %w[assignment_selection link_selection resource_selection]
        tools_collection = described_class.bookmarked_collection(account, placements).paginate(per_page: 100).to_a

        definitions = described_class.launch_definitions(tools_collection, placements)
        expect(definitions.count).to eq 1
        definition = definitions.first
        expect(definition).to eq({
                                   definition_type: tool.class.name,
                                   definition_id: tool.id,
                                   name: tool.label_for(placements.first, I18n.locale),
                                   description: tool.description,
                                   domain: nil,
                                   url: "http://www.example.com/basic_lti",
                                   placements: {
                                     link_selection: {
                                       message_type: "basic-lti-launch-request",
                                       url: "http://www.example.com/basic_lti",
                                       title: tool.name
                                     },
                                     assignment_selection: {
                                       message_type: "basic-lti-launch-request",
                                       url: "http://www.example.com/basic_lti",
                                       title: tool.name
                                     }
                                   }
                                 })
      end

      it "uses localized labels" do
        tool = account.context_external_tools.new(name: "bob",
                                                  consumer_key: "test",
                                                  shared_secret: "secret",
                                                  url: "http://example.com")

        assignment_selection = {
          text: "this should not be the title",
          url: "http://www.example.com",
          labels: {
            "en" => "English Label",
            "sp" => "Spanish Label"
          }
        }

        tool.settings[:assignment_selection] = assignment_selection

        tool.save!

        placements = [:assignment_selection]
        tools_collection = described_class.bookmarked_collection(account, placements).paginate(per_page: 100).to_a

        definitions = described_class.launch_definitions(tools_collection, placements)
        expect(definitions[0][:name]).to eq "English Label"
      end

      it "returns resource_selection tools" do
        tool = new_valid_external_tool(account, true)
        placements = %w[assignment_selection link_selection resource_selection]
        tools_collection = described_class.bookmarked_collection(account, placements).paginate(per_page: 100).to_a

        definitions = described_class.launch_definitions(tools_collection, placements)
        expect(definitions.count).to eq 1
        definition = definitions.first
        expect(definition).to eq({
                                   definition_type: tool.class.name,
                                   definition_id: tool.id,
                                   name: tool.name,
                                   description: tool.description,
                                   domain: nil,
                                   url: "http://www.example.com/basic_lti",
                                   placements: {
                                     assignment_selection: {
                                       message_type: "basic-lti-launch-request",
                                       url: "http://www.example.com/basic_lti",
                                       title: tool.name
                                     },
                                     link_selection: {
                                       message_type: "basic-lti-launch-request",
                                       url: "http://www.example.com/basic_lti",
                                       title: tool.name
                                     },
                                     resource_selection: {
                                       message_type: "resource_selection",
                                       url: "http://example.com/selection_test",
                                       title: tool.name,
                                       selection_width: 400,
                                       selection_height: 400
                                     }
                                   }
                                 })
      end

      it "returns an external tool and a message handler" do
        tp = create_tool_proxy
        tp.bindings.create(context: account)
        rh = create_resource_handler(tp)
        mh = create_message_handler(rh)
        ResourcePlacement::LEGACY_DEFAULT_PLACEMENTS.each { |p| mh.placements.create(placement: p) }
        new_valid_external_tool(account)

        placements = %w[assignment_selection link_selection resource_selection]
        tools_collection = described_class.bookmarked_collection(account, placements).paginate(per_page: 100).to_a

        definitions = described_class.launch_definitions(tools_collection, placements)
        expect(definitions.count).to eq 2
        external_tool = definitions.find { |d| d[:definition_type] == "ContextExternalTool" }
        message_handler = definitions.find { |d| d[:definition_type] == "Lti::MessageHandler" }
        expect(message_handler).to_not be_nil
        expect(external_tool).to_not be_nil
      end

      context "pagination" do
        it "paginates correctly" do
          3.times do |_|
            tp = create_tool_proxy
            tp.bindings.create(context: account)
            rh = create_resource_handler(tp)
            mh = create_message_handler(rh)
            ResourcePlacement::LEGACY_DEFAULT_PLACEMENTS.each { |p| mh.placements.create(placement: p) }
          end
          3.times { |_| new_valid_external_tool(account) }

          placements = %w[assignment_selection link_selection resource_selection]
          collection = described_class.bookmarked_collection(account, placements)
          per_page = 3
          page1 = collection.paginate(per_page:)
          page2 = collection.paginate(page: page1.next_page, per_page:)
          expect(page1.count).to eq 3
          expect(page2.count).to eq 3
          expect(page1.first).to_not eq page2.first
        end
      end
    end

    describe "#launch definitions with a launch placement type" do
      subject do
        Lti::AppLaunchCollator.launch_definitions(
          [tool],
          [placement]
        ).first
      end

      context "with assignment_edit placement" do
        let(:placement) { :assignment_edit }
        let(:tool) do
          new_valid_external_tool(account)
        end

        it "retains the launch_height property" do
          tool.assignment_edit = {
            enabled: true,
            url: "https://www.test.tool.com",
            message_type: "LtiResourceLinkRequest",
            launch_width: 300,
            launch_height: 300
          }
          tool.save!
          expect(subject.dig(:placements, :assignment_edit, :launch_height)).to eq 300
        end
      end
    end
  end
end
