#
# Copyright (C) 2016 Instructure, Inc.
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

module OutcomeImporter
  private

  def migration_clause(value)
    if AcademicBenchmark.use_new_guid_columns?
      ["migration_id_2 = ? OR (migration_id_2 IS NULL AND migration_id = ?)", value, value]
    else
      ["migration_id = ? OR (migration_id IS NULL AND migration_id_2 = ?)", value, value]
    end
  end

  def vendor_clause(value)
    if AcademicBenchmark.use_new_guid_columns?
      ["vendor_guid_2 = ? OR (vendor_guid_2 IS NULL AND vendor_guid = ?)", value, value]
    else
      ["vendor_guid = ? OR (vendor_guid IS NULL AND vendor_guid_2 = ?)", value, value]
    end
  end
end
