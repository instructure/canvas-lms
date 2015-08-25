require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')
require 'db/migrate/20150713165815_add_lti_message_handler_id_to_lti_resource_placements.rb'

module Lti
  describe ToolProxyService do
    describe 'AddLtiMessageHandlerIdToLtiResourcePlacements' do
      describe "up" do

        let(:tool_proxy_fixture) { File.read(File.join(Rails.root, 'spec', 'fixtures', 'lti', 'tool_proxy.json')) }
        let(:tool_proxy_guid) { 'guid' }
        let(:account) { Account.new }

        it "should copy the first message_handler id that is a basic lti launch request to message_hanlder_id" do
          tool_proxy = subject.process_tool_proxy_json(tool_proxy_fixture, account, tool_proxy_guid)
          rh = Lti::ResourceHandler.create!(resource_type_code: "1", name: "rh_test", tool_proxy: tool_proxy)
          mh = Lti::MessageHandler.create!(message_type: "basic-lti-launch-request",
                                           resource_handler: rh,
                                           launch_path: "/test")
          mh_two = Lti::MessageHandler.create!(message_type: "some-type",
                                               resource_handler: rh,
                                               launch_path: "/test")
          rh.message_handlers << mh_two << mh
          rh.save!
          placement = Lti::ResourcePlacement.new(placement: "assignment_selection", resource_handler: rh, message_handler: nil)
          placement.save(validate: false)

          expect(placement.message_handler).to be_nil
          expect(placement.resource_handler).not_to be_nil

          DataFixup::AddLtiMessageHandlerIdToLtiResourcePlacements.run

          expect(Lti::ResourcePlacement.find(placement.id).message_handler.id).to eq mh.id
        end
      end
    end
  end
end
