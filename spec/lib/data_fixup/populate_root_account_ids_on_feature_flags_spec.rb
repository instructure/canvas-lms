# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

describe DataFixup::PopulateRootAccountIdsOnFeatureFlags do
  before do
    allow(Feature).to receive(:definitions).and_return(
      {
        "root_account_feature" => Feature.new(feature: "root_account_feature", applies_to: "RootAccount"),
        "account_feature" => Feature.new(feature: "account_feature", applies_to: "Account"),
        "course_feature" => Feature.new(feature: "course_feature", applies_to: "Course"),
        "user_feature" => Feature.new(feature: "user_feature", applies_to: "User")
      }
    )
  end

  before :once do
    @subaccount = Account.default.sub_accounts.create! name: "sub"
    course_with_teacher(active_all: true, account: @subaccount)
    @teacher.update_root_account_ids
  end

  def create_feature_flags
    Account.default.enable_feature!(:root_account_feature)
    @subaccount.enable_feature!(:account_feature)
    @course.enable_feature!(:course_feature)
    @teacher.enable_feature!(:user_feature)
    @ffs = FeatureFlag.where(feature: %w[root_account_feature account_feature course_feature user_feature])
  end

  it "populates root_account_ids for new records" do
    create_feature_flags

    expect(@ffs.pluck(:root_account_ids)).to eq([[Account.default.id]] * 4)
  end

  it "backfills root_account_ids for existing records" do
    create_feature_flags

    FeatureFlag.update_all(root_account_ids: [])
    DataFixup::PopulateRootAccountIdsOnFeatureFlags.run
    expect(@ffs.pluck(:root_account_ids)).to eq([[Account.default.id]] * 4)
  end
end
