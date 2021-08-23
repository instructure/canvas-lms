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

class AddNStrandIndex < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!
  tag :predeploy

  def connection
    Delayed::Job.connection
  end

  def change
    add_index :delayed_jobs, [:strand, :next_in_strand, :id],
              name: 'n_strand_index',
              where: 'strand IS NOT NULL',
              algorithm: :concurrently,
              if_not_exists: true
  end
end
