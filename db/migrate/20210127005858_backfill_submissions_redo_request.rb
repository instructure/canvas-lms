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
#
class BackfillSubmissionsRedoRequest < ActiveRecord::Migration[5.2]
  tag :postdeploy
  disable_ddl_transaction!

  def self.runnable?
    connection.postgresql_version < 110000
  end

  def up
    if Submission.columns.detect{|c| c.name == "redo_request"}&.null
      DataFixup::BackfillNulls.run(Submission, :redo_request, default_value: false)
      change_column_null(:submissions, :redo_request, false)
    end
  end

  def down
    change_column_null(:submissions, :redo_request, true)
  end
end
