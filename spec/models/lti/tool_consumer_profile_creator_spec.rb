require 'spec_helper'

module Lti
  describe ToolConsumerProfileCreator do

    let(:root_account) { mock('root account', lti_guid: 'my_guid') }
    let(:account) { mock('account', root_account: root_account) }
    # let(:root_account) {mock('root account').stubs(:lti_guid).returns('my_guid')}
    # let(:account) {mock('account').stubs(:root_account).returns(root_account)}
    subject { ToolConsumerProfileCreator.new(account, 'http://tool-consumer.com/tp/reg') }

    describe '#create' do

      it 'creates the tool consumer profile' do
        profile = subject.create
        profile.lti_version.should == 'LTI-2p0'
        profile.product_instance.should be_an_instance_of IMS::LTI::Models::ProductInstance
      end

      it 'creates the product instance' do
        product_instance = subject.create.product_instance
        product_instance.guid.should == 'my_guid'
        product_instance.product_info.should be_an IMS::LTI::Models::ProductInfo

      end

      it 'creates the product info' do
        product_info = subject.create.product_instance.product_info
        product_info.product_name.default_value.should == 'Canvas by Instructure'
        product_info.product_version.should == 'none'
        product_info.product_family.should be_a IMS::LTI::Models::ProductFamily
      end

      it 'creates the product family' do
        product_family = subject.create.product_instance.product_info.product_family
        product_family.code.should == 'canvas'
        product_family.vendor.should be_a IMS::LTI::Models::Vendor

      end

      it 'creates the vendor' do
        vendor = subject.create.product_instance.product_info.product_family.vendor
        vendor.code.should == 'https://instructure.com'
        vendor.vendor_name.default_value.should == 'Instructure'
        vendor.vendor_name.key.should == 'vendor.name'
        vendor.timestamp.to_i.should == Time.parse('2008-03-27 00:00:00 -0600').to_i
      end

      it 'creates the registration service' do
        profile = subject.create
        reg_srv = profile.service_offered.find {|srv| srv.id == 'tcp:ToolProxy.collection'}
        reg_srv.endpoint.should == 'http://tool-consumer.com/tp/reg'
        reg_srv.type.should == 'RestService'
        reg_srv.format.should == ["application/vnd.ims.lti.v2.toolproxy+json"]
        reg_srv.action.should include 'POST'

      end

      it 'add the basic_launch capability' do
        subject.create.capability_offered.should include 'basic-lti-launch-request'
      end

    end
  end
end