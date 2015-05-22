#
# Copyright (C) 2012 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')
require 'lib/data_fixup/set_account_lti_opaque_ids.rb'

describe 'DataFixup::SetAccountLtiOpaqueIds' do
  describe "up" do
    it "should work" do
      root_account = Account.create!
      original_guid = root_account.lti_guid
      expect(original_guid).not_to be_empty

      DataFixup::SetAccountLtiOpaqueIds.run

      root_account.reload
      expect(root_account.lti_guid).not_to eq original_guid
    end
  end
end
