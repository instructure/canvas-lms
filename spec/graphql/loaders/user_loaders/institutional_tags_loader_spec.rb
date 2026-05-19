# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

describe Loaders::UserLoaders::InstitutionalTagsLoader do
  let_once(:root_account) do
    Account.default.tap { |a| a.enable_feature!(:institutional_tags) }
  end
  let_once(:admin) { account_admin_user(account: root_account) }
  let_once(:non_admin) { user_model }
  let_once(:user1) { user_model }
  let_once(:user2) { user_model }
  let_once(:user3) { user_model }

  let_once(:category) { institutional_tag_category_model(account: root_account) }
  let_once(:tag1) { institutional_tag_model(account: root_account, category:, name: "Alumni") }
  let_once(:tag2) { institutional_tag_model(account: root_account, category:, name: "Faculty") }
  let_once(:tag3) { institutional_tag_model(account: root_account, category:, name: "Staff") }

  before(:once) do
    institutional_tag_association_model(account: root_account, institutional_tag: tag1, user: user1)
    institutional_tag_association_model(account: root_account, institutional_tag: tag2, user: user1)
    institutional_tag_association_model(account: root_account, institutional_tag: tag3, user: user2)
  end

  def batch_load(user_id, account_id: root_account.id, current_user: admin, session: nil)
    result = nil
    GraphQL::Batch.batch do
      Loaders::UserLoaders::InstitutionalTagsLoader
        .for(current_user, session, account_id)
        .load(user_id)
        .then { |tags| result = tags }
    end
    result
  end

  describe "#perform" do
    context "when prerequisites are not met" do
      it "returns nil when account is not found" do
        expect(batch_load(user1.id, account_id: 0)).to be_nil
      end

      it "returns nil when account is not a root account" do
        sub_account = Account.create!(parent_account: root_account)
        expect(batch_load(user1.id, account_id: sub_account.id)).to be_nil
      end

      it "returns nil when institutional_tags feature is disabled" do
        root_account.disable_feature!(:institutional_tags)
        expect(batch_load(user1.id)).to be_nil
      ensure
        root_account.enable_feature!(:institutional_tags)
      end

      it "returns nil when current_user lacks manage_institutional_tags_view permission" do
        expect(batch_load(user1.id, current_user: non_admin)).to be_nil
      end
    end

    context "when prerequisites are met" do
      it "returns active institutional tags for a user" do
        tags = batch_load(user1.id)
        expect(tags).to be_an(Array)
        expect(tags).to match_array([tag1, tag2])
      end

      it "returns tags in alphabetical order by name" do
        tags = batch_load(user1.id)
        expect(tags.map(&:name)).to eql %w[Alumni Faculty]
      end

      it "returns tags for a different user independently" do
        tags = batch_load(user2.id)
        expect(tags).to eql [tag3]
      end

      it "returns empty array for a user with no tags" do
        expect(batch_load(user3.id)).to eql []
      end

      it "returns empty array for a non-existent user id" do
        expect(batch_load(0)).to eql []
      end

      it "batches multiple users in a single query" do
        results = {}
        GraphQL::Batch.batch do
          loader = Loaders::UserLoaders::InstitutionalTagsLoader.for(admin, nil, root_account.id)
          loader.load(user1.id).then { |tags| results[user1.id] = tags }
          loader.load(user2.id).then { |tags| results[user2.id] = tags }
          loader.load(user3.id).then { |tags| results[user3.id] = tags }
        end

        expect(results[user1.id]).to match_array([tag1, tag2])
        expect(results[user2.id]).to eql [tag3]
        expect(results[user3.id]).to eql []
      end

      it "excludes deleted tags" do
        tag1.update!(workflow_state: "deleted")
        tags = batch_load(user1.id)
        expect(tags.map(&:id)).not_to include(tag1.id)
        expect(tags).to eql [tag2]
      ensure
        tag1.update!(workflow_state: "active")
      end

      it "excludes associations with deleted workflow_state" do
        assoc = InstitutionalTagAssociation.find_by(
          institutional_tag: tag2,
          user_id: user1.id
        )
        assoc.update!(workflow_state: "deleted")
        tags = batch_load(user1.id)
        expect(tags.map(&:id)).not_to include(tag2.id)
        expect(tags).to eql [tag1]
      ensure
        assoc.update!(workflow_state: "active")
      end
    end
  end
end
