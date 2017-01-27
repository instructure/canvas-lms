require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require_dependency "lti/capabilities_helper"

module Lti
  describe CapabilitiesHelper do
    let(:test_lti_guid){ 'test-lti-guid-1234' }
    let(:root_account){ Account.new }
    let(:account){ Account.new(root_account: root_account) }
    let(:capabilities_helper){ CapabilitiesHelper.new(account) }
    let(:recommended_params){ %w(launch_presentation_document_target tool_consumer_instance_guid) }
    let(:optional_params){ %w(launch_presentation_locale) }

    describe "#recommended_params" do
      it "contains all supported recommended params" do
        expect(capabilities_helper.recommended_params.keys).to match_array(recommended_params)
      end

      it "gives correct value for launch_presentation_document_target"

      it "gives correct value for tool_consumer_instance_guid" do
        root_account.update_attributes(lti_guid: test_lti_guid)
        instance_guid = capabilities_helper.recommended_params['tool_consumer_instance_guid']
        expect(instance_guid).to eq root_account.lti_guid
      end

      it "gives nil for tool_consumer_instance_guid if context does not have root_account" do
        a = Account.new
        c_helper = CapabilitiesHelper.new(a)
        instance_guid = c_helper.recommended_params[:tool_consumer_instance_guid]
        expect(instance_guid).to be_nil
      end
    end

    describe "#optional_params" do
      it "contains all supported optional params" do
        expect(capabilities_helper.optional_params.keys).to match_array(optional_params)
      end

      it "gives correct value for launch_presentation_locale with locale set" do
        allow_any_instance_of(I18n).to receive(:locale) { :en }
        launch_locale = capabilities_helper.optional_params['launch_presentation_locale']
        expect(launch_locale).to eq I18n.locale
      end

      it "gives correct value for launch_presentation_locale with locale not set" do
        allow_any_instance_of(I18n).to receive(:locale) { nil }
        allow_any_instance_of(I18n).to receive(:default_locale) { :da }
        launch_locale = capabilities_helper.optional_params['launch_presentation_locale']
        expect(launch_locale).to eq I18n.default_locale
      end
    end

    describe "#parameter_capabilities" do
      it "returns keys of all optional and recommended params" do
        expect(capabilities_helper.parameter_capabilities).to match_array(recommended_params + optional_params)
      end
    end

    describe "#paramter_capabilities_hash" do
      it "returns all recommended and optional params" do
        expect(capabilities_helper.parameter_capabilities_hash.keys).to match_array(recommended_params + optional_params)
      end
    end
  end
end
