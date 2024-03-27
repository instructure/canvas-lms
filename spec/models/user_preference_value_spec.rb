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

describe UserPreferenceValue do
  let(:regular_key) { :custom_colors }
  let(:subbed_key) { :course_nicknames }

  let(:migrated_user) do
    u = User.create!
    u.set_preference(regular_key, [:arbitrary_data])
    u.set_preference(subbed_key, :a, 1)
    u.set_preference(subbed_key, :b, [:other_stuff])
    u
  end

  it "creates a new row when setting a new value" do
    u = User.create!
    expect(u.user_preference_values.count).to eq 0
    u.set_preference(regular_key, "data")
    u.set_preference(subbed_key, "subkey", "more data")
    expect(u.user_preference_values.count).to eq 2
    expect(u.get_preference(regular_key)).to eq "data"
    expect(u.get_preference(subbed_key, "subkey")).to eq "more data"
  end

  it "updates an existing row when setting a new value" do
    regular_row = migrated_user.user_preference_values.where(key: regular_key).first
    migrated_user.set_preference(regular_key, "new data")
    expect(regular_row.reload.value).to eq "new data"
    expect(migrated_user.get_preference(regular_key)).to eq "new data"

    sub_row = migrated_user.user_preference_values.where(key: subbed_key, sub_key: :a).first
    migrated_user.set_preference(subbed_key, :a, "more new data")
    expect(sub_row.reload.value).to eq "more new data"
    expect(migrated_user.get_preference(subbed_key, :a)).to eq "more new data"
  end

  it "does not query for preferences when saving an unrelated attribute on an already migrated user" do
    expect(migrated_user).to_not receive(:user_preference_values)
    migrated_user.update_attribute(:name, "name1")
    User.find(migrated_user.id).update_attribute(:name, "name2")
  end

  it "does not have to query to load preferences if the values are empty" do
    migrated_user.set_preference(regular_key, [])
    reloaded_user = User.find(migrated_user.id)
    expect(reloaded_user).to_not receive(:user_preference_values)
    expect(reloaded_user.get_preference(regular_key)).to eq []
  end

  it "does not have to query to load preferences if the values are empty for a sub key" do
    migrated_user.clear_all_preferences_for(subbed_key)
    expect(migrated_user.preference_row_exists?(subbed_key, :a)).to be false
    expect(migrated_user.user_preference_values.where(key: subbed_key)).not_to be_any
    expect(migrated_user.preferences[subbed_key]).to eq({})

    reloaded_user = User.find(migrated_user.id)
    expect(reloaded_user).to_not receive(:user_preference_values)
    expect(reloaded_user.get_preference(subbed_key, :a)).to be_nil
  end

  it "removes an individual preference value" do
    migrated_user.set_preference(subbed_key, :b, nil)
    expect(migrated_user.get_preference(subbed_key, :b)).to be_nil
    expect(migrated_user.preference_row_exists?(subbed_key, :a)).to be true
    expect(migrated_user.preference_row_exists?(subbed_key, :b)).to be false
    expect(migrated_user.user_preference_values.where(key: subbed_key).pluck(:sub_key)).to eq(["a"])
    expect(migrated_user.preferences[subbed_key]).to eq(UserPreferenceValue::EXTERNAL)
  end
end
