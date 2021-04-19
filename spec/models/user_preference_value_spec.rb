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

require_relative "../sharding_spec_helper"

describe UserPreferenceValue do
  let (:regular_key) { :custom_colors }
  let (:subbed_key) { :course_nicknames }

  let (:sample_preferences) {
    {regular_key => [:arbitrary_data], subbed_key => {:a => 1, :b => [:other_stuff]}}
  }

  let (:preexisting_user) {
    User.create!(:preferences => sample_preferences)
  }

  let (:migrated_user) {
    u = User.create!(:preferences => sample_preferences)
    u.migrate_preferences_if_needed
    u.save!
    u
  }

  it "should create a new row when setting a new value" do
    u = User.create!
    expect(u.user_preference_values.count).to eq 0
    u.set_preference(regular_key, "data")
    u.set_preference(subbed_key, "subkey", "more data")
    expect(u.user_preference_values.count).to eq 2
    expect(u.get_preference(regular_key)).to eq "data"
    expect(u.get_preference(subbed_key, "subkey")).to eq "more data"
  end

  it "should update an existing row when setting a new value" do
    regular_row = migrated_user.user_preference_values.where(:key => regular_key).first
    migrated_user.set_preference(regular_key, "new data")
    expect(regular_row.reload.value).to eq "new data"
    expect(migrated_user.get_preference(regular_key)).to eq "new data"

    sub_row = migrated_user.user_preference_values.where(:key => subbed_key, :sub_key => :a).first
    migrated_user.set_preference(subbed_key, :a, "more new data")
    expect(sub_row.reload.value).to eq "more new data"
    expect(migrated_user.get_preference(subbed_key, :a)).to eq "more new data"
  end

  it "should use the existing data if the user's preferences hasn't been migrated yet" do
    expect(preexisting_user.preferences[regular_key]).to eq sample_preferences[regular_key]
    expect(preexisting_user.preferences[subbed_key]).to eq sample_preferences[subbed_key]
  end

  it "should not migrate all existing preferences automatically on save unless to a migrated preference" do
    expect(preexisting_user.needs_preference_migration?).to eq true
    preexisting_user.save!

    expect(preexisting_user.reload.needs_preference_migration?).to eq true
    preexisting_user.set_preference(regular_key, "new_value")
    expect(preexisting_user.reload.needs_preference_migration?).to eq false

    rows = preexisting_user.user_preference_values.to_a.index_by{|v| [v.key, v.sub_key]}
    expect(rows.count).to eq 3
    expect(rows[[regular_key.to_s, nil]].value).to eq "new_value"
    expect(rows[[subbed_key.to_s, "a"]].value).to eq sample_preferences[subbed_key][:a]
    expect(rows[[subbed_key.to_s, "b"]].value).to eq sample_preferences[subbed_key][:b]

    expect(preexisting_user.preferences).to eq(
      {regular_key => UserPreferenceValue::EXTERNAL, subbed_key => UserPreferenceValue::EXTERNAL})
  end

  it "should not query for preferences when saving an unrelated attribute on an already migrated user" do
    expect(migrated_user).to_not receive(:user_preference_values)
    migrated_user.update_attribute(:name, "name1")
    User.find(migrated_user.id).update_attribute(:name, "name2")
  end

  it "shouldn't have to query to load preferences if the values are empty" do
    migrated_user.set_preference(regular_key, [])
    reloaded_user = User.find(migrated_user.id)
    expect(reloaded_user).to_not receive(:user_preference_values)
    expect(reloaded_user.get_preference(regular_key)).to eq []
  end

  it "shouldn't have to query to load preferences if the values are empty for a sub key" do
    migrated_user.clear_all_preferences_for(subbed_key)
    expect(migrated_user.user_preference_values.where(:key => subbed_key).distinct.pluck(:value)).to eq [nil]
    expect(migrated_user.preferences[subbed_key]).to eq({})

    reloaded_user = User.find(migrated_user.id)
    expect(reloaded_user).to_not receive(:user_preference_values)
    expect(reloaded_user.get_preference(subbed_key, :a)).to eq nil
  end

  context "gradebook_column_size" do
    specs_require_sharding

    let (:course1) { Course.create! }
    let (:course2) { Course.create! }
    let (:assignment1) { course1.assignments.create! }
    let (:assignment2) { course2.assignments.create! }
    let (:assignment_group1) { course1.assignment_groups.create! }
    let (:assignment_group2) { course2.assignment_groups.create! }
    let (:column1) { course1.custom_gradebook_columns.create!(:title => "1") }
    let (:column2) { course2.custom_gradebook_columns.create!(:title => "2") }

    let (:old_format) {
      {
        "student" => "100",
        "assignment_#{assignment1.id}" => "10",
        "assignment_#{assignment2.id}" => "20",
        "assignment_group_#{assignment_group1.id}" => "30",
        "assignment_group_#{assignment_group2.id}" => "40",
        "custom_col_#{column1.id}" => "50",
        "custom_col_#{column2.id}" => "60"
      }
    }

    it "should split the old gradebook column size preference by course" do
      u = User.create!
      User.where(:id => u).update_all(:preferences => {:gradebook_column_size => old_format})
      u.reload
      u.migrate_preferences_if_needed
      u.save!
      expect(u.get_preference(:gradebook_column_size, "shared")).to eq old_format.slice("student")
      expect(u.get_preference(:gradebook_column_size, course1.global_id)).to eq old_format.slice(
        "assignment_#{assignment1.id}", "assignment_group_#{assignment_group1.id}", "custom_col_#{column1.id}")
      expect(u.get_preference(:gradebook_column_size, course2.global_id)).to eq old_format.slice(
        "assignment_#{assignment2.id}", "assignment_group_#{assignment_group2.id}", "custom_col_#{column2.id}")
    end

    it "should not attempt to re-migrate when a new non-migrated preference value appears" do
      u = User.create!
      User.where(:id => u).update_all(:preferences => {:closed_notifications => [], :gradebook_column_size => old_format})
      u.reload
      u.migrate_preferences_if_needed
      u.save!
      u.preferences[:closed_notifications] << 123
      expect(u.needs_preference_migration?).to be true
      expect { u.migrate_preferences_if_needed }.not_to raise_error
      expect(u.user_preference_values.where(key: 'closed_notifications').take.value).to eq [123]
    end

    it "should work even if the objects are from a different shard than the user" do
      old_format # instantiate on default shard
      @shard1.activate do
        u = User.create!
        u.associate_with_shard(Shard.default)
        User.where(:id => u).update_all(:preferences => {:gradebook_column_size => old_format})
        u.reload
        u.migrate_preferences_if_needed
        u.save!
        expect(u.get_preference(:gradebook_column_size, "shared")).to eq old_format.slice("student")
        # save the subkey as a global but the columns with local ids since we'll only ever access them from their own shard
        expect(u.get_preference(:gradebook_column_size, course1.global_id)).to eq old_format.slice(
          "assignment_#{assignment1.local_id}", "assignment_group_#{assignment_group1.local_id}", "custom_col_#{column1.local_id}")
        expect(u.get_preference(:gradebook_column_size, course2.global_id)).to eq old_format.slice(
          "assignment_#{assignment2.local_id}", "assignment_group_#{assignment_group2.local_id}", "custom_col_#{column2.local_id}")
      end
    end
  end
end
