# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

describe DataFixup::MigrateHomeroomSettingsToColumns do
  before :once do
    @c1 = course_factory
    @c1.settings_frd[:homeroom_course] = true
    @c1.save!

    @c2 = course_factory
    @c2.settings_frd[:sync_enrollments_from_homeroom] = true
    @c2.settings_frd[:homeroom_course_id] = @c1.id
    @c2.save!

    @c3 = course_factory
    @c3.settings_frd[:homeroom_course_id] = "null"
    @c3.save!
  end

  it "migrates settings to columns" do
    DataFixup::MigrateHomeroomSettingsToColumns.run
    expect(Course.homeroom).to eq([@c1])
    expect(Course.where(sync_enrollments_from_homeroom: true)).to eq([@c2])
    expect(@c2.reload.linked_homeroom_course).to eq @c1
  end

  it "cleans strings that aren't ints" do
    DataFixup::MigrateHomeroomSettingsToColumns.run
    expect(@c3.reload.linked_homeroom_course).to be_nil
  end
end
