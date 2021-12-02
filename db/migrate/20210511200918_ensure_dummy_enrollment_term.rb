# frozen_string_literal: true

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

class EnsureDummyEnrollmentTerm < ActiveRecord::Migration[6.0]
  tag :predeploy

  def up
    # if a dummy course already exists, it will reference an enrollment term
    # belonging to a dummy root account, whose id is _not_ 0. we're going to change
    # that ID, but we don't want postgres to whine about the broken FK. we'll also
    # fix the FK, but it doesn't happen in the same statement
    fk_name = connection.foreign_key_for(:courses, to_table: :enrollment_terms).name
    table = connection.quote_table_name('courses')

    execute("ALTER TABLE #{table} ALTER CONSTRAINT #{connection.quote_column_name(fk_name)} DEFERRABLE")
    defer_constraints(fk_name) do
      # find a pre-existing one referencing the dummy root account, and make it the dummy
      EnrollmentTerm.where(root_account_id: 0).update_all(id: 0)
      EnrollmentTerm.ensure_dummy_enrollment_term
      # fix any dummy courses already created
      Course.where(id: 0).update_all(enrollment_term_id: 0)
    end
  end
end
