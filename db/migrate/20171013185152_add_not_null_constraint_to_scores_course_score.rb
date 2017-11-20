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
#

class AddNotNullConstraintToScoresCourseScore < ActiveRecord::Migration[5.0]
  tag :postdeploy
  disable_ddl_transaction!

  def up
    self.connection.execute(<<SQL)
      ALTER TABLE #{Score.quoted_table_name}
       ADD CONSTRAINT course_score_not_null CHECK (course_score IS NOT NULL) NOT VALID;
SQL

    self.connection.execute(<<SQL)
      ALTER TABLE #{Score.quoted_table_name} VALIDATE CONSTRAINT course_score_not_null;
SQL
  end

  def down
    self.connection.execute(<<SQL)
      ALTER TABLE #{Score.quoted_table_name} DROP CONSTRAINT course_score_not_null;
SQL
  end
end
