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
    let(:tcp_url) { "http://example.instructure.com/tcp/#{ToolConsumerProfile::DEFAULT_TCP_UUID}" }
    let(:tcp_creator) { ToolConsumerProfileCreator.new(account, tcp_url) }

    describe '#create' do

      it 'creates the tool consumer profile' do
        profile = tcp_creator.create
        expect(profile.lti_version).to eq 'LTI-2p0'
        expect(profile.product_instance).to be_an_instance_of IMS::LTI::Models::ProductInstance
        expect(profile.guid).to eq Lti::ToolConsumerProfile::DEFAULT_TCP_UUID
      end

      it 'creates the product instance' do
        product_instance = tcp_creator.create.product_instance
        expect(product_instance.guid).to eq 'my_guid'
        expect(product_instance.product_info).to be_an IMS::LTI::Models::ProductInfo
      end

      it 'creates the service owner' do
        service_owner = tcp_creator.create.product_instance.service_owner
        expect(service_owner.service_owner_name.default_value).to eq 'root_account_name'
        expect(service_owner.description.default_value).to eq 'root_account_name'
      end

      it 'creates the product info' do
        product_info = tcp_creator.create.product_instance.product_info
        expect(product_info.product_name.default_value).to eq 'Canvas by Instructure'
        expect(product_info.product_version).to eq 'none'
        expect(product_info.product_family).to be_a IMS::LTI::Models::ProductFamily
      end

      it 'creates the product family' do
        product_family = tcp_creator.create.product_instance.product_info.product_family
        expect(product_family.code).to eq 'canvas'
        expect(product_family.vendor).to be_a IMS::LTI::Models::Vendor

      end

      it 'creates the vendor' do
        vendor = tcp_creator.create.product_instance.product_info.product_family.vendor
        expect(vendor.code).to eq 'https://instructure.com'
        expect(vendor.vendor_name.default_value).to eq 'Instructure'
        expect(vendor.vendor_name.key).to eq 'vendor.name'
        expect(vendor.timestamp.to_i).to eq Time.zone.parse('2008-03-27 00:00:00 -0600').to_i
      end

      it 'creates the registration service' do
        profile = tcp_creator.create
        reg_srv = profile.service_offered.find { |srv| srv.id.include? 'ToolProxy.collection' }
        expect(reg_srv.id).to eq "#{tcp_url}#ToolProxy.collection"
        expect(reg_srv.endpoint).to include('3/tool_proxy')
        expect(reg_srv.type).to eq 'RestService'
        expect(reg_srv.format).to eq ["application/vnd.ims.lti.v2.toolproxy+json"]
        expect(reg_srv.action).to include('POST')
      end

      it 'creates the authorization service' do
        profile = tcp_creator.create
        reg_srv = profile.service_offered.find { |srv| srv.id.include? 'vnd.Canvas.authorization' }
        expect(reg_srv.id).to eq "#{tcp_url}#vnd.Canvas.authorization"
        expect(reg_srv.endpoint).to include('api/lti/authorize')
        expect(reg_srv.type).to eq 'RestService'
        expect(reg_srv.format).to eq ["application/json"]
        expect(reg_srv.action).to include('POST')
      end

      it 'does not include restricted services when developer_credentials is set to false' do
        restricted_service_id = 'vnd.Canvas.OriginalityReport'
        profile = tcp_creator.create
        reg_srv = profile.service_offered.find { |srv| srv.id.include? restricted_service_id }
        expect(reg_srv).to be_nil
      end

      describe '#capabilities' do
        it 'add the basic_launch capability' do
          expect(tcp_creator.create.capability_offered).to include('basic-lti-launch-request')
        end

        it 'adds the Canvas.api.domain capability' do
          expect(tcp_creator.create.capability_offered).to include('Canvas.api.domain')
        end

        it 'adds the LtiLink.custom.url capability' do
          expect(tcp_creator.create.capability_offered).to include('LtiLink.custom.url')
        end

        it 'adds the ToolProxyBinding.custom.url capability' do
          expect(tcp_creator.create.capability_offered).to include('ToolProxyBinding.custom.url')
        end

        it 'adds the ToolProxy.custom.url capability' do
          expect(tcp_creator.create.capability_offered).to include('ToolProxy.custom.url')
        end

        it 'adds the Canvas.placements.accountNavigation capability' do
          expect(tcp_creator.create.capability_offered).to include 'Canvas.placements.accountNavigation'
        end

        it 'adds the Canvas.placements.courseNavigation capability' do
          expect(tcp_creator.create.capability_offered).to include 'Canvas.placements.courseNavigation'
        end

        it 'adds the ToolConsumerProfile.url capability' do
          expect(tcp_creator.create.capability_offered).to include 'ToolConsumerProfile.url'
        end

        it 'adds the Security.splitSecret capability' do
          expect(tcp_creator.create.capability_offered).to include 'Security.splitSecret'
        end

        it 'adds the Person.sourcedId capability' do
          expect(tcp_creator.create.capability_offered).to include 'Person.sourcedId'
        end

        it 'adds the CourseSection.sourcedId capability' do
          expect(tcp_creator.create.capability_offered).to include 'CourseSection.sourcedId'
        end

        it 'adds the Context.id capability' do
          expect(tcp_creator.create.capability_offered).to include 'Context.id'
        end

        it 'adds the Message.documentTarget capability' do
          expect(tcp_creator.create.capability_offered).to include 'Message.documentTarget'
        end

        it 'adds the ToolConsumerInstance.guid capability' do
          expect(tcp_creator.create.capability_offered).to include 'ToolConsumerInstance.guid'
        end

        it 'adds the Message.locale capability' do
          expect(tcp_creator.create.capability_offered).to include 'Message.locale'
        end

        it 'adds the Membership.role capability' do
          expect(tcp_creator.create.capability_offered).to include 'Membership.role'
        end

        it 'does not add the OriginalityReport capability if developer_key is false' do
          expect(tcp_creator.create.capability_offered).not_to include 'vnd.Canvas.OriginalityReport.url'
        end

        it 'does not add the Canvas.placements.similarityDetection if developer key is false' do
          expect(tcp_creator.create.capability_offered).not_to include 'Canvas.placements.similarityDetection'
        end

        it 'adds the ToolProxyReregistrationRequest capability if the feature flag is on' do
          root_account.stubs(:feature_enabled?).returns(true)

          expected_capability = IMS::LTI::Models::Messages::ToolProxyReregistrationRequest::MESSAGE_TYPE
          expect(tcp_creator.create.capability_offered).to include expected_capability
        end

        context "custom Tool Consumer Profile" do

          let(:account) { Account.create! }

          let(:dev_key) do
            dev_key = DeveloperKey.create(api_key: 'test-api-key')
            DeveloperKey.stubs(:find_cached).returns(dev_key)
            dev_key
          end

          let(:tcp) do
            dev_key.create_tool_consumer_profile!(
              services: Lti::ToolConsumerProfile::RESTRICTED_SERVICES,
              capabilities: Lti::ToolConsumerProfile::RESTRICTED_CAPABILITIES,
              uuid: SecureRandom.uuid,
              developer_key: dev_key
            )
          end

          let(:tcp_creator) do
            ToolConsumerProfileCreator.new(account, tcp_url, tcp_uuid: tcp.uuid, developer_key: dev_key)
          end

          it 'includes services from a custom TCP' do
            tcp_creator
            restricted_service_id = 'vnd.Canvas.OriginalityReport'
            profile = tcp_creator.create
            reg_srv = profile.service_offered.find { |srv| srv.id.include? restricted_service_id }
            expect(reg_srv.id).to eq "#{tcp_url}##{restricted_service_id}"
          end

          it 'includes capabilities from a custom TCP' do
            expect(tcp_creator.create.capability_offered).to include 'vnd.Canvas.OriginalityReport.url'
            expect(tcp_creator.create.capability_offered).to include 'Canvas.placements.similarityDetection'
          end

          it 'looks up the custom TCP from the TCP url' do
            expect(tcp_creator.create.guid).to eq tcp.uuid
          end


          it 'looks up the default TCP from the TCP url' do
            tcp_creator = ToolConsumerProfileCreator.new(
              account,
              tcp_url,
              tcp_uuid: ToolConsumerProfile::DEFAULT_TCP_UUID,
              developer_key: dev_key
            )
            expect(tcp_creator.create.guid).to eq ToolConsumerProfile::DEFAULT_TCP_UUID
          end

          it 'defaults to the default TCP if it can not find a match' do
            tcp_creator = ToolConsumerProfileCreator.new(
              account,
              tcp_url,
              tcp_uuid: SecureRandom.uuid,
              developer_key: dev_key
            )
            expect(tcp_creator.create.guid).to eq ToolConsumerProfile::DEFAULT_TCP_UUID
          end

          it 'defaults to the default TCP if the developer key is not associated to the TCP' do
             dev_key2 = DeveloperKey.create(api_key: 'test-api-key')
             tcp_creator = ToolConsumerProfileCreator.new(
               account,
               tcp_url,
               tcp_uuid: tcp.uuid,
               developer_key: dev_key2
             )
             expect(tcp_creator.create.guid).to eq ToolConsumerProfile::DEFAULT_TCP_UUID
          end
        end
      end
    end
  end
end
