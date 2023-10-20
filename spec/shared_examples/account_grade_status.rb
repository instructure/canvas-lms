# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

shared_examples_for "account grade status permissions" do
  let(:admin) { account_admin_user(account: status.root_account, active_all: true) }
  let(:teacher) { course_with_teacher(account: status.root_account, active_all: true).user }
  let(:other_account_admin) { account_admin_user(account: Account.create!, active_all: true) }

  describe "create" do
    it "is permitted for account admins" do
      expect(status.grants_right?(admin, :create)).to be true
    end

    it "is not permitted for non-account-admins" do
      expect(status.grants_right?(teacher, :create)).to be false
    end

    it "is not permitted for an admin from a different account" do
      expect(status.grants_right?(other_account_admin, :create)).to be false
    end
  end

  describe "read" do
    it "is permitted for account admins" do
      expect(status.grants_right?(admin, :read)).to be true
    end

    it "is not permitted for non-account-admins" do
      expect(status.grants_right?(teacher, :read)).to be false
    end

    it "is not permitted for an admin from a different account" do
      expect(status.grants_right?(other_account_admin, :read)).to be false
    end
  end

  describe "update" do
    it "is permitted for account admins" do
      expect(status.grants_right?(admin, :update)).to be true
    end

    it "is not permitted for non-account-admins" do
      expect(status.grants_right?(teacher, :update)).to be false
    end

    it "is not permitted for an admin from a different account" do
      expect(status.grants_right?(other_account_admin, :update)).to be false
    end
  end
end
