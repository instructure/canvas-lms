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
require_relative '../spec_helper'

describe DataFixup::SplitUpUserPreferences do
  it "should work" do
    u = User.create!
    original_prefs = {:selected_calendar_contexts => ["course_1000"], :course_nicknames => {2 => "Why am i taking this course"}, :some_other_thing => true}
    User.where(:id => u).update_all(:preferences => original_prefs)
    DataFixup::SplitUpUserPreferences.run(nil, nil)
    u.reload
    expect(u.reload.needs_preference_migration?).to eq false
    rows = u.user_preference_values.to_a.index_by{|v| [v.key, v.sub_key]}
    expect(rows.count).to eq 2
    expect(rows[["selected_calendar_contexts", nil]].value).to eq ["course_1000"]
    expect(rows[["course_nicknames", 2]].value).to eq "Why am i taking this course"

    expect(u.preferences).to eq(
      {
        :selected_calendar_contexts => UserPreferenceValue::EXTERNAL,
        :course_nicknames => UserPreferenceValue::EXTERNAL,
        :some_other_thing => true
      }
    )
    expect(u.get_preference(:selected_calendar_contexts)).to eq ["course_1000"]
    expect(u.get_preference(:course_nicknames, 2)).to eq "Why am i taking this course"
  end
end
