# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

class SetDefaultValuesForAssignments < ActiveRecord::Migration[4.2]
  tag :predeploy
  disable_ddl_transaction!

  def up
    fields = [
      :all_day, :could_be_locked, :grade_group_students_individually,
      :anonymous_peer_reviews, :turnitin_enabled, :vericite_enabled,
      :moderated_grading, :omit_from_final_grade, :freeze_on_copy,
      :copied, :only_visible_to_overrides, :post_to_sis
    ]
    fields.each { |field| change_column_default(:assignments, field, false) }
    fields += [:peer_reviews_assigned, :peer_reviews, :automatic_peer_reviews, :muted, :intra_group_peer_reviews]
    DataFixup::BackfillNulls.run(Assignment, fields, default_value: false)
    fields.each { |field| change_column_null(:assignments, field, false) }
  end

  def down
    fields_with_defaults = [
      :all_day, :could_be_locked, :grade_group_students_individually,
      :anonymous_peer_reviews, :turnitin_enabled, :vericite_enabled,
      :moderated_grading, :omit_from_final_grade, :freeze_on_copy,
      :copied, :only_visible_to_overrides, :post_to_sis
    ]
    fields_with_null_constraints = fields_with_defaults +
      [:peer_reviews_assigned, :peer_reviews, :automatic_peer_reviews, :muted, :intra_group_peer_reviews]
    fields_with_null_constraints.each { |field| change_column_null(:assignments, field, true) }
    fields_with_defaults.each { |field| change_column_default(:assignments, field, nil) }
  end
end
