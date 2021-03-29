# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

class CleanupInvalidObserverAlerts < ActiveRecord::Migration[5.2]
  tag :postdeploy
  disable_ddl_transaction!

  def up
    # in production there are not a ton of ObserverAlerts, so doing a sub query
    # for each batch to delete is fine.
    valid_ids = ObserverAlert.where(context_type: 'Submission').
      joins("INNER JOIN #{Submission.quoted_table_name} ON submissions.id=observer_alerts.context_id AND context_type='Submission'").
      select(:context_id)
    scope = ObserverAlert.where(context_type: 'Submission').where.not(context_id: valid_ids)
    # There are not many invalid ObserverAlerts either and this could go in one
    # delete instead of batches, but it will end up being the same.
    until scope.limit(1_000).delete_all < 1_000; end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
