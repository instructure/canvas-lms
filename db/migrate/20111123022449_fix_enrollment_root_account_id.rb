#
# Copyright (C) 2011 - present Instructure, Inc.
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

class FixEnrollmentRootAccountId < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    case adapter_name
    when "PostgreSQL"
      update "UPDATE #{Enrollment.quoted_table_name} SET root_account_id = c.root_account_id FROM #{Course.quoted_table_name} As c WHERE course_id = c.id AND enrollments.root_account_id != c.root_account_id"
    else
      Course.find_each do |c|
        bad_enrollments = c.enrollments.where("enrollments.root_account_id<>courses.root_account_id").pluck(:id)
        Enrollment.where(:id => bad_enrollments).update_all(:root_account_id => c.root_account_id)
      end
    end
  end

  def self.down
  end
end
