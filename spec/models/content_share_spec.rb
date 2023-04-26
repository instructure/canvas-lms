# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

describe ContentShare do
  describe "record create" do
    it "correctly sets the root_account_id from context" do
      course_factory active_all: true
      user_model
      export = factory_with_protected_attributes(@course.content_exports, user: @user, export_type: "common_cartridge")
      share = ContentShare.create!(content_export: export, name: "Share01", user: @user, read_state: "unread", type: "SentContentShare")
      expect(share.root_account_id).to eq(export.context.root_account_id)
    end

    context "sharding" do
      specs_require_sharding

      it "works when sharing from a course on different shard" do
        @shard1.activate do
          acc = Account.create!
          user_factory(account: acc)
        end
        course_factory active_all: true
        export = factory_with_protected_attributes(@course.content_exports, user: @user, export_type: "common_cartridge")
        share = @user.content_shares.create!(content_export: export, name: "Share01", read_state: "unread", type: "SentContentShare")
        expect(share.root_account_id).to eq(@course.root_account_id)
      end

      it "works when sharing to a user on different shard" do
        user_model
        @sending_user = @user
        course_factory active_all: true
        export = factory_with_protected_attributes(@course.content_exports, user: @sending_user, export_type: "common_cartridge")
        share = @sending_user.content_shares.create!(content_export: export, name: "Share01", read_state: "unread", type: "SentContentShare")

        @shard1.activate do
          acc = Account.create!
          user_factory(account: acc)
          @receiving_user = @user
        end
        received_share = share.clone_for(@receiving_user)
        expect(received_share.root_account_id).to eq(@course.root_account_id)
        expect(export.grants_right?(@receiving_user, :read)).to be true
      end
    end
  end
end
