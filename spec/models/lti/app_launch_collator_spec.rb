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

      it "does not cause N+1 queries when include_context_name is true" do
        account.update!(name: "Root Account")
        subaccount = account.sub_accounts.create!(name: "Sub Account")
        course = subaccount.courses.create!(name: "Test Course")

        new_valid_external_tool(account)
        new_valid_external_tool(subaccount)
        new_valid_external_tool(course)

        placements = %w[assignment_selection link_selection resource_selection]
        tools_collection = described_class.bookmarked_collection(course, placements).paginate(per_page: 100).to_a

        cnt = 0
        subscription = ActiveSupport::Notifications.subscribe("sql.active_record") do |_name, _start, _finish, _id, _payload|
          cnt += 1
        end

        definitions = described_class.launch_definitions(tools_collection, placements, include_context_name: true)

        ActiveSupport::Notifications.unsubscribe(subscription)

        expect(definitions.count).to eq 3
        context_names = definitions.pluck(:context_name)
        expect(context_names).to contain_exactly("Root Account", "Sub Account", "Test Course")
        # Batch loading does 2 queries total (one for accounts, one for courses)
        # regardless of the number of tools, which avoids N+1
        expect(cnt).to eq 2
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

      context "with assignment_view and assignment_edit placements" do
        let(:tool) { new_valid_external_tool(account) }

        shared_examples_for "a placement that uses target_link_uri when enabled" do |placement_type|
          context "with lti_target_link_uri_for_assignment_edit_view feature disabled" do
            before do
              Account.site_admin.disable_feature!(:lti_target_link_uri_for_assignment_edit_view)
            end

            it "uses the placement specific url for the url property" do
              tool.public_send(:"#{placement_type}=", {
                                 enabled: true,
                                 url: "https://www.test.tool.com",
                                 target_link_uri: "https://target_link.test.tool.com",
                               })
              tool.save!
              expect(subject.dig(:placements, placement_type, :url)).to eq "https://www.test.tool.com"
            end
          end

          context "with lti_target_link_uri_for_assignment_edit_view feature enabled" do
            before do
              Account.site_admin.enable_feature!(:lti_target_link_uri_for_assignment_edit_view)
            end

            it "uses the placement specific target_link_uri for the url property" do
              tool.public_send(:"#{placement_type}=", {
                                 enabled: true,
                                 url: "https://www.test.tool.com",
                                 target_link_uri: "https://target_link.test.tool.com",
                               })
              tool.save!
              expect(subject.dig(:placements, placement_type, :url)).to eq "https://target_link.test.tool.com"
            end
          end
        end

        context "with assignment_view placement" do
          let(:placement) { :assignment_view }

          it_behaves_like "a placement that uses target_link_uri when enabled", :assignment_view
        end

        context "with assignment_edit placement" do
          let(:placement) { :assignment_edit }

          it_behaves_like "a placement that uses target_link_uri when enabled", :assignment_edit
        end
      end
    end

    describe "#message_handlers_for with lti_asset_processor_tii_migration feature" do
      include LtiSpecHelper

      let(:course) { course_model(account:) }
      let(:placement) { ResourcePlacement::SIMILARITY_DETECTION }

      before do
        @tp1 = create_tool_proxy(context: account)
        @tp1.bindings.create!(context: course)
        @rh1 = ResourceHandler.create!(resource_type_code: "code1", name: "resource1", tool_proxy: @tp1)
        @mh1 = MessageHandler.create!(message_type: "basic-lti-launch-request", launch_path: "https://launch1/blti", resource_handler: @rh1)
        @mh1.placements.create!(placement:)

        @tp2 = create_tool_proxy(context: account)
        @tp2.bindings.create!(context: course)
        @rh2 = ResourceHandler.create!(resource_type_code: "code2", name: "resource2", tool_proxy: @tp2)
        @mh2 = MessageHandler.create!(message_type: "basic-lti-launch-request", launch_path: "https://launch2/blti", resource_handler: @rh2)
        @mh2.placements.create!(placement:)
      end

      context "when feature flag is disabled" do
        before do
          account.root_account.disable_feature!(:lti_asset_processor_tii_migration)
        end

        it "returns all message handlers including migrated ones" do
          migrated_tool = external_tool_1_3_model(context: course, opts: { name: "migrated tool" })
          @tp1.update!(migrated_to_context_external_tool: migrated_tool)

          collection = described_class.bookmarked_collection(course, [placement])
          tools = collection.paginate(per_page: 100).to_a
          message_handlers = tools.select { |t| t.is_a?(Lti::MessageHandler) }
          expect(message_handlers.count).to eq 2
          expect(message_handlers).to include(@mh1, @mh2)
        end
      end

      context "when feature flag is enabled" do
        before do
          account.root_account.enable_feature!(:lti_asset_processor_tii_migration)
        end

        it "returns all message handlers when none are migrated" do
          collection = described_class.bookmarked_collection(course, [placement])
          tools = collection.paginate(per_page: 100).to_a
          message_handlers = tools.select { |t| t.is_a?(Lti::MessageHandler) }
          expect(message_handlers.count).to eq 2
          expect(message_handlers).to include(@mh1, @mh2)
        end

        it "excludes message handlers for migrated tool proxies" do
          migrated_tool = external_tool_1_3_model(context: course, opts: { name: "migrated tool" })
          @tp1.update!(migrated_to_context_external_tool: migrated_tool)

          collection = described_class.bookmarked_collection(course, [placement])
          tools = collection.paginate(per_page: 100).to_a
          message_handlers = tools.select { |t| t.is_a?(Lti::MessageHandler) }
          expect(message_handlers.count).to eq 1
          expect(message_handlers).to include(@mh2)
          expect(message_handlers).not_to include(@mh1)
        end

        it "excludes all message handlers when all are migrated" do
          migrated_tool1 = external_tool_1_3_model(context: course, opts: { name: "migrated tool 1" })
          migrated_tool2 = external_tool_1_3_model(context: course, opts: { name: "migrated tool 2" })
          @tp1.update!(migrated_to_context_external_tool: migrated_tool1)
          @tp2.update!(migrated_to_context_external_tool: migrated_tool2)

          collection = described_class.bookmarked_collection(course, [placement])
          tools = collection.paginate(per_page: 100).to_a
          message_handlers = tools.select { |t| t.is_a?(Lti::MessageHandler) }
          expect(message_handlers.count).to eq 0
        end
      end
    end
  end
end
