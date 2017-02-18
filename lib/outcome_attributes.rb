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

module OutcomeAttributes
  def vendor_guid
    AcademicBenchmark.use_new_guid_columns? ? self.vendor_guid_2 || super : super || self.vendor_guid_2
  end

  def vendor_guid=(value)
    AcademicBenchmark.use_new_guid_columns? ? self.vendor_guid_2 = value : super(value)
  end

  def migration_id
    AcademicBenchmark.use_new_guid_columns? ? self.migration_id_2 || super : super || self.migration_id_2
  end

  def migration_id=(value)
    AcademicBenchmark.use_new_guid_columns? ? self.migration_id_2 = value : super(value)
  end
end
