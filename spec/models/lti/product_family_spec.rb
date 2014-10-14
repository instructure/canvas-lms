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
  describe ProductFamily do
    let(:account){Account.new}

    describe 'validations' do

      before(:each) do
        subject.vendor_code = 'vendor_code'
        subject.product_code = 'product_code'
        subject.vendor_name = 'vendor_name'
        subject.root_account_id = account
      end

      it 'requires a vendor_code' do
        subject.vendor_code = nil
        subject.save
        expect(subject.errors.first).to eq [:vendor_code, "can't be blank"]
      end

      it 'requires a product_code' do
        subject.product_code = nil
        subject.save
        expect(subject.errors.first).to eq [:product_code, "can't be blank"]
      end

      it 'requires a vendor_name' do
        subject.vendor_name = nil
        subject.save
        expect(subject.errors.first).to eq [:vendor_name, "can't be blank"]
      end

      it 'requires a root_account' do
        subject.root_account = nil
        subject.save
        expect(subject.errors.first).to eq [:root_account, "can't be blank"]
      end

    end

  end
end