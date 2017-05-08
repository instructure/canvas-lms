#
# Copyright (C) 2011 - present Instructure, Inc.
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
require File.expand_path(File.dirname(__FILE__) + '/../../lti2_spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')
require_dependency "lti/resource_handler"

module Lti
  describe ResourceHandler do
    include_context 'lti2_spec_helper'

    describe 'validations' do
      before(:each) do
        resource_handler.resource_type_code = 'code'
        resource_handler.name = 'name'
        resource_handler.tool_proxy = ToolProxy.new
      end

      it 'requires the name' do
        resource_handler.name = nil
        resource_handler.save
        expect(resource_handler.errors.first).to eq [:name, "can't be blank"]
      end

      it 'requires a tool proxy' do
        resource_handler.tool_proxy = nil
        resource_handler.save
        expect(resource_handler.errors.first).to eq [:tool_proxy, "can't be blank"]
      end

    end

    describe 'set_lookup_id' do
      before do
        resource_handler.update_attributes(lookup_id: nil)
      end

      it 'sets the lookup_id if it is not set' do
        expect(resource_handler.lookup_id).to eq ResourceHandler.generate_lookup_id_for(resource_handler)
      end

      it "uses the 'product_code'" do
        pc = resource_handler.lookup_id.split('-').first
        expect(pc).to eq product_family.product_code
      end

      it "uses the 'vendor_code'" do
        vc = resource_handler.lookup_id.split('-').second
        expect(vc).to eq product_family.vendor_code
      end

      it "uses the 'resource_type_code'" do
        rtc = resource_handler.lookup_id.split('-').third
        expect(rtc).to eq resource_handler.resource_type_code
      end

      it "adds a signature to the lookup_id" do
        signature = resource_handler.lookup_id.split('-').last
        components = [product_family.product_code,
                      product_family.vendor_code,
                      resource_handler.resource_type_code].join('-')
        verified = Canvas::Security.verify_hmac_sha1(signature,
                                                     components)
        expect(verified).to eq true
      end
    end

  end
end
