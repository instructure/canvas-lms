#
# Copyright (C) 2017 - present Instructure, Inc.
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
require File.expand_path(File.dirname(__FILE__) + '/../../lti2_spec_helper.rb')
module Lti
  RSpec.describe Link, type: :model do
    include_context 'lti2_spec_helper'

    describe "validations" do
      let(:params) do
        {
          vendor_code: 'vendor_code',
          product_code: 'product_code',
          resource_type_code: 'resource_type_code',
          resource_link_id: 'resource_link_id'
        }
      end
      it "requires vendor_code" do
        params.delete :vendor_code
        link = Lti::Link.new(params)
        expect(link.valid?).to eq false
      end

      it "requires product_code" do
        params.delete :product_code
        link = Lti::Link.new(params)
        expect(link.valid?).to eq false
      end

      it "requires resource_type_code" do
        params.delete :resource_type_code
        link = Lti::Link.new(params)
        expect(link.valid?).to eq false
      end

      it "populates resource_link_id if not present" do
        params.delete :resource_link_id
        link = Lti::Link.new(params)
        expect(link.valid?).to eq true
      end

      it "requires resource_link_id to be unique" do
        Lti::Link.create!(params)
        link = Lti::Link.new(params)
        expect(link.valid?).to eq false
      end
    end

    describe '#message_handler' do
      let(:lti_link) { subject }

      before do
        message_handler.update_attributes(message_type: MessageHandler::BASIC_LTI_LAUNCH_REQUEST)
        resource_handler.message_handlers = [message_handler]
        resource_handler.save!

        lti_link.update_attributes(resource_type_code: resource_handler.resource_type_code,
                                   product_code: product_family.product_code,
                                   vendor_code: product_family.vendor_code)
      end

      it 'looks up the message handler identified by the codes' do
        expect(lti_link.message_handler(account)).to eq message_handler
      end
    end

    describe '#originality_report' do
      it 'returns an originality_report if linkable is an OriginalityReport' do
        report = OriginalityReport.new
        lti_link = Lti::Link.new(linkable: report)
        expect(lti_link.originality_report).to eq report
      end

      it 'returns nil if linkable is not an OriginalityReport ' do
        lti_link = Lti::Link.new
        expect(lti_link.originality_report).to be_nil
      end
    end

    describe '#generate_resource_link_id' do
      it 'sets the resource_link_id' do
        lti_link = Lti::Link.new
        expect(lti_link.resource_link_id).to be_nil
        lti_link.generate_resource_link_id
        expect(lti_link.resource_link_id).not_to be_nil
      end
    end
  end
end
