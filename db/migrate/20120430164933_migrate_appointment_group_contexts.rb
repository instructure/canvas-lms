#
# Copyright (C) 2012 - present Instructure, Inc.
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

class MigrateAppointmentGroupContexts < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    records = AppointmentGroup.all.map { |ag|
      {
        :appointment_group_id => ag.id,
        :context_code         => ag.context_code,
        :context_type         => ag.context_type,
        :context_id           => ag.context_id,
        :updated_at           => ag.updated_at,
        :created_at           => ag.created_at
      }
    }

    AppointmentGroupContext.bulk_insert records
  end

  def self.down
  end
end
