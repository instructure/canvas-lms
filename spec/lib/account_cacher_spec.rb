# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

describe "AccountCacher" do
  before :once do
    @account = Account.default
  end

  it "clears the association cache when the account is updated" do
    enable_cache do
      sub = @account.sub_accounts.create!
      Account.find(sub.id).root_account # prime the association cache

      @account.update! name: "blah"
      expect(Account.find(sub.id).root_account.name).to eq "blah"
    end
  end

  it "clears the polymorphic association cache when the account is updated" do
    enable_cache do
      account_admin_user
      cm = Conversation.build_message(@admin, "hi all")
      cm.context = @account
      cm.save!
      ConversationMessage.find(cm.id).context # prime the association cache

      @account.update! name: "blah"
      expect(ConversationMessage.find(cm.id).context.name).to eq "blah"
    end
  end
end
