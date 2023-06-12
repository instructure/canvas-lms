# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

class MicrosoftSync::PartialSyncChange < ApplicationRecord
  extend RootAccountResolver

  belongs_to :course
  belongs_to :user

  validates :user, :course, :enrollment_type, presence: true
  validates :user_id, uniqueness: { scope: %i[course_id enrollment_type] }

  resolves_root_account through: :course

  # NOTE: "enrollment_type" in a PartialSyncChange is not the type of Enrollment,
  # but rather "owner" or "member", also referred to as "MSFT role type"
  OWNER_ENROLLMENT_TYPE = MicrosoftSync::PartialMembershipDiff::OWNER_MSFT_ROLE_TYPE
  MEMBER_ENROLLMENT_TYPE = MicrosoftSync::PartialMembershipDiff::MEMBER_MSFT_ROLE_TYPE

  # filter to rows where all values match
  # e.g. with_values_in([:a,:b], [[1,2],[3,4]) -> WHERE (a=1 AND b=2) OR (a=3 AND b=4)
  scope :with_values_in, lambda { |columns, values_arrays|
    if values_arrays.empty?
      none
    else
      quoted_columns = columns.map { |col| connection.quote_column_name(col) }
      quoted_values_arrays = values_arrays.map do |arr|
        "(" + arr.map { |val| connection.quote(val) }.join(",") + ")"
      end
      where("(#{quoted_columns.join(",")}) IN (#{quoted_values_arrays.join(",")})")
    end
  }

  def self.upsert_for_enrollment(enrollment)
    e_type =
      if MicrosoftSync::MembershipDiff::OWNER_ENROLLMENT_TYPES.include?(enrollment.type)
        OWNER_ENROLLMENT_TYPE
      else
        MEMBER_ENROLLMENT_TYPE
      end

    connection.execute sanitize_sql [
      %(
        INSERT INTO #{quoted_table_name}
        (user_id, course_id, enrollment_type, root_account_id, created_at, updated_at)
        VALUES (?, ?, ?, ?, NOW(), NOW())
        ON CONFLICT (user_id, course_id, enrollment_type) DO UPDATE
        SET updated_at=NOW()
      ),
      enrollment.user_id,
      enrollment.course_id,
      e_type,
      enrollment.root_account_id
    ]
  end

  # Deletes all records for a course which have been replicated to the secondary.
  # Assumes insertions and updates have all used `upsert_for_enrollment` above,
  # which uses the postgres server time (NOW())
  def self.delete_all_replicated_to_secondary_for_course(course_id, batch_size = 1000)
    last_replicated_updated_at = GuardRail.activate(:secondary) do
      where(course_id:).order(updated_at: :desc).limit(1).pluck(:updated_at).first
    end

    while where(course_id:)
          .where("updated_at <= ?", last_replicated_updated_at)
          .limit(batch_size).delete_all == batch_size
    end
  end
end
