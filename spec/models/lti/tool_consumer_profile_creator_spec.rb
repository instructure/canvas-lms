require 'spec_helper'
require_dependency "lti/tool_consumer_profile_creator"

module Lti
  describe ToolConsumerProfileCreator do

    let(:root_account) do
      mock('root account') do
        stubs(:lti_guid).returns('my_guid')
        stubs(:name).returns('root_account_name')
        stubs(:feature_enabled?).returns(false)
      end
    end
    let(:account) { mock('account', id: 3, root_account: root_account) }
    let(:tcp_url) { 'http://example.instructure.com/tcp/uuid' }
    subject { ToolConsumerProfileCreator.new(account, tcp_url) }

    describe '#create' do

      it 'creates the tool consumer profile' do
        profile = subject.create
        expect(profile.lti_version).to eq 'LTI-2p1'
        expect(profile.product_instance).to be_an_instance_of IMS::LTI::Models::ProductInstance
        expect(profile.guid).to eq '339b6700-e4cb-47c5-a54f-3ee0064921a9' #Hard coded until we start persisting the tcp
      end

      it 'creates the product instance' do
        product_instance = subject.create.product_instance
        expect(product_instance.guid).to eq 'my_guid'
        expect(product_instance.product_info).to be_an IMS::LTI::Models::ProductInfo
      end

      it 'creates the service owner' do
        service_owner = subject.create.product_instance.service_owner
        expect(service_owner.service_owner_name.default_value).to eq 'root_account_name'
        expect(service_owner.description.default_value).to eq 'root_account_name'
      end

      it 'creates the product info' do
        product_info = subject.create.product_instance.product_info
        expect(product_info.product_name.default_value).to eq 'Canvas by Instructure'
        expect(product_info.product_version).to eq 'none'
        expect(product_info.product_family).to be_a IMS::LTI::Models::ProductFamily
      end

      it 'creates the product family' do
        product_family = subject.create.product_instance.product_info.product_family
        expect(product_family.code).to eq 'canvas'
        expect(product_family.vendor).to be_a IMS::LTI::Models::Vendor

      end

      it 'creates the vendor' do
        vendor = subject.create.product_instance.product_info.product_family.vendor
        expect(vendor.code).to eq 'https://instructure.com'
        expect(vendor.vendor_name.default_value).to eq 'Instructure'
        expect(vendor.vendor_name.key).to eq 'vendor.name'
        expect(vendor.timestamp.to_i).to eq Time.parse('2008-03-27 00:00:00 -0600').to_i
      end

      it 'creates the registration service' do
        profile = subject.create
        reg_srv = profile.service_offered.find { |srv| srv.id.include? 'ToolProxy.collection' }
        expect(reg_srv.id).to eq "#{tcp_url}#ToolProxy.collection"
        expect(reg_srv.endpoint).to include('3/tool_proxy')
        expect(reg_srv.type).to eq 'RestService'
        expect(reg_srv.format).to eq ["application/vnd.ims.lti.v2.toolproxy+json"]
        expect(reg_srv.action).to include('POST')
      end

      describe '#capabilities' do
        it 'add the basic_launch capability' do
          expect(subject.create.capability_offered).to include('basic-lti-launch-request')
        end

        it 'adds the Canvas.api.domain capability' do
          expect(subject.create.capability_offered).to include('Canvas.api.domain')
        end

        it 'adds the LtiLink.custom.url capability' do
          expect(subject.create.capability_offered).to include('LtiLink.custom.url')
        end

        it 'adds the ToolProxyBinding.custom.url capability' do
          expect(subject.create.capability_offered).to include('ToolProxyBinding.custom.url')
        end

        it 'adds the ToolProxy.custom.url capability' do
          expect(subject.create.capability_offered).to include('ToolProxy.custom.url')
        end

        it 'adds the Canvas.placements.accountNavigation capability' do
          expect(subject.create.capability_offered).to include 'Canvas.placements.accountNavigation'
        end

        it 'adds the Canvas.placements.courseNavigation capability' do
          expect(subject.create.capability_offered).to include 'Canvas.placements.courseNavigation'
        end

        it 'adds the Canvas.placements.assignmentConfiguration capability' do
          expect(subject.create.capability_offered).to include 'Canvas.placements.assignmentConfiguration'
        end


        it 'adds the ToolConsumerProfile.url capability' do
          expect(subject.create.capability_offered).to include 'ToolConsumerProfile.url'
        end

        it 'adds the OAuth.splitSecret capability' do
          expect(subject.create.capability_offered).to include 'OAuth.splitSecret'
        end

        it 'adds the Context.id capability' do
          expect(subject.create.capability_offered).to include 'Context.id'
        end

        it 'adds the ToolProxyReregistrationRequest capability if the feature flag is on' do
          root_account.stubs(:feature_enabled?).returns(true)

          expected_capability = IMS::LTI::Models::Messages::ToolProxyReregistrationRequest::MESSAGE_TYPE
          expect(subject.create.capability_offered).to include expected_capability
        end

      end


    end
  end
end
