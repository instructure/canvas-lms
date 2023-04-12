# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

describe SharedBrandConfig do
  describe "policy" do
    subject { Account.default.shared_brand_configs.new }

    it "does NOT allow unauthorized users to delete/modify" do
      expect(subject.check_policy(User.new)).to be_empty
    end

    it "DOES allow authorized users to delete/modify" do
      expect(subject.check_policy(account_admin_user)).to eq(%i[create update delete])
    end
  end
end
