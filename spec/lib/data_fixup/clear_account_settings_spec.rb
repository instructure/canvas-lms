# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

require "spec_helper"

describe DataFixup::ClearAccountSettings do
  let(:account) { account_model }

  before do
    account.settings[:foo] = "bar"
    account.settings[:bar] = "baz"
    account.save!
  end

  context "when clearing a single setting" do
    it "clears the specified setting" do
      expect do
        described_class.run(%w[foo])
      end.to change {
        account.reload.settings[:foo]
      }.from("bar").to(nil)

      expect(account.reload.settings[:bar]).to eq "baz"
    end
  end

  context "when clearing multiple settings" do
    it "clears all provided settings" do
      expect do
        described_class.run(%w[foo bar])
      end.to change {
        account.reload.settings[:foo]
      }.from("bar").to(nil).and change {
        account.reload.settings[:bar]
      }.from("baz").to(nil)
    end
  end

  context "when dealing with multiple accounts" do
    let(:account2) { account_model }

    before do
      account2.settings[:baz] = "foo"
      account2.save!
    end

    it "clears the settings that apply to each account" do
      expect do
        described_class.run(%w[foo baz])
      end.to change {
        account.reload.settings[:foo]
      }.from("bar").to(nil).and change {
        account2.reload.settings[:baz]
      }.from("foo").to(nil)

      expect(account.reload.settings[:bar]).to eq "baz"
    end
  end

  describe "subaccounts" do
    let(:subaccount) { account_model(parent_account: account) }

    before do
      subaccount.settings[:foo] = "bar"
      subaccount.save!
    end

    it "ignores subaccounts" do
      expect do
        described_class.run(%w[foo])
      end.to change {
        account.reload.settings[:foo]
      }.from("bar").to(nil).and not_change {
        subaccount.reload.settings[:foo]
      }
    end

    context "include_subaccounts is true" do
      it "clears subaccount settings" do
        expect do
          described_class.run(%w[foo], include_subaccounts: true)
        end.to change {
          account.reload.settings[:foo]
        }.from("bar").to(nil).and change {
          subaccount.reload.settings[:foo]
        }.from("bar").to(nil)
      end
    end
  end
end
