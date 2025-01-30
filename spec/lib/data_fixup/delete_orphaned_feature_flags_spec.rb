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

require "spec_helper"

describe DataFixup::DeleteOrphanedFeatureFlags do
  before :once do
    @account_feature = Feature.definitions.values.find { |f| f.applies_to == "Account" }.feature
    @course_feature = Feature.definitions.values.find { |f| f.applies_to == "Course" }.feature
    @user_feature = Feature.definitions.values.find { |f| f.applies_to == "User" }.feature

    account = account_model(root_account: Account.default)
    @account_flag = account.feature_flags.create!(feature: @account_feature, state: "on")
    course = course_factory
    @course_flag = course.feature_flags.create!(feature: @course_feature, state: "on")
    user = user_factory
    @user_flag = user.feature_flags.create!(feature: @user_feature, state: "on")
  end

  def check_existing_flags
    expect(@account_flag.reload).to be_present
    expect(@course_flag.reload).to be_present
    expect(@user_flag.reload).to be_present
  end

  it "deletes orphaned User feature flags" do
    user = user_factory
    ff = user.feature_flags.create!(feature: @user_feature, state: "on")
    FeatureFlag.where(id: ff).update_all(context_id: -1) # easier than hard-deleting and dealing with FK constraints
    described_class.run
    expect { ff.reload }.to raise_error(ActiveRecord::RecordNotFound)
    check_existing_flags
  end

  it "deletes orphaned Course feature flags" do
    course = course_factory
    ff = course.feature_flags.create!(feature: @course_feature, state: "on")
    FeatureFlag.where(id: ff).update_all(context_id: -1)
    described_class.run
    expect { ff.reload }.to raise_error(ActiveRecord::RecordNotFound)
    check_existing_flags
  end

  it "deletes orphaned Account feature flags" do
    account = account_model(root_account: Account.default)
    ff = account.feature_flags.create!(feature: @account_feature, state: "on")
    FeatureFlag.where(id: ff).update_all(context_id: -1)
    described_class.run
    expect { ff.reload }.to raise_error(ActiveRecord::RecordNotFound)
    check_existing_flags
  end
end
