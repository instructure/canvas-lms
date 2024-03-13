# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

class RemoveGuardTriggersFromInternalMetadataTables < ActiveRecord::Migration[7.0]
  tag :postdeploy

  def up
    # these triggers may have been accidentally added due to using constant
    # table names instead of `ActiveRecord::Base.internal_metadata_table_name`
    operations = ["UPDATE", "DELETE"]
    [ActiveRecord::Base.internal_metadata_table_name,
     ActiveRecord::Base.schema_migrations_table_name].each do |t|
      operations.each do |operation|
        trigger_name = "guard_excessive_#{operation.downcase}s"

        execute("DROP TRIGGER IF EXISTS #{trigger_name} ON #{connection.quote_table_name(t)}")
      end
    end
  end
end
