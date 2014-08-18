#
# Copyright (C) 2014 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

module Lti
  describe ToolProxy do
    let (:account) {Account.new}
    let (:product_family) {ProductFamily.create(vendor_code: '123', product_code:'abc', vendor_name:'acme', root_account:account)}
    let (:resource_handler) {ResourceHandler.new}

    describe 'validations' do

      before(:each) do
        subject.shared_secret = 'shared_secret'
        subject.guid = 'guid'
        subject.product_version = '1.0beta'
        subject.lti_version = 'LTI-2p0'
        subject.product_family = product_family
        subject.root_account = account
        subject.workflow_state = 'active'
        subject.raw_data = 'some raw data'
      end

      it 'requires a shared_secret' do
        subject.shared_secret = nil
        subject.save
        error = subject.errors.find {|e| e == [:shared_secret, "can't be blank"]}
        error.should_not == nil
      end

      it 'requires a guid' do
        subject.guid = nil
        subject.save
        error = subject.errors.find {|e| e == [:guid, "can't be blank"]}
        error.should_not == nil
      end

      it 'must have a unique guid' do
        tool_proxy = described_class.new
        tool_proxy.shared_secret = 'foo'
        tool_proxy.guid = 'guid'
        tool_proxy.product_version = '2.0_beta'
        tool_proxy.lti_version = 'LTI-2p0'
        tool_proxy.product_family = product_family
        tool_proxy.root_account = account
        tool_proxy.workflow_state = 'active'
        tool_proxy.raw_data = 'raw_data'
        tool_proxy.save
        subject.save
        subject.errors[:guid].should include("has already been taken")
      end

      it 'requires a product_version' do
        subject.product_version = nil
        subject.save
        subject.errors[:product_version].should include("can't be blank")
      end

      it 'requires a lti_version' do
        subject.lti_version = nil
        subject.save
        subject.errors[:lti_version].should include("can't be blank")
      end

      it 'requires a product_family' do
        subject.product_family = nil
        subject.save
        error = subject.errors.find {|e| e == [:product_family, "can't be blank"]}
      end

      it 'requires a root_account' do
        subject.root_account = nil
        subject.save
        subject.errors[:root_account_id].should include("can't be blank")
      end

      it 'require a workflow_state' do
        subject.workflow_state = nil
        subject.save
        subject.errors[:workflow_state].should include("can't be blank")
      end

      it 'requires raw_data' do
        subject.raw_data = nil
        subject.save
        subject.errors[:raw_data].should include("can't be blank")
      end

    end

  end
end