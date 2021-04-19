# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

class AddPostPoliciesToAssignments < ActiveRecord::Migration[5.1]
  tag :postdeploy

  disable_ddl_transaction!

  def change
    Submission.find_ids_in_ranges(batch_size: 100_000, loose: true) do |start_at, end_at|
      DataFixup::AddPostPoliciesToAssignments.delay_if_production(priority: Delayed::LOW_PRIORITY,
          n_strand: ["DataFixup::AddPostPoliciesToAssignments", Shard.current.database_server.id]).
        set_submission_posted_at_dates(start_at, end_at)
    end

    Course.find_ids_in_ranges(loose: true) do |start_at, end_at|
      DataFixup::AddPostPoliciesToAssignments.delay_if_production(priority: Delayed::LOW_PRIORITY,
          n_strand: ["DataFixup::AddPostPoliciesToAssignments", Shard.current.database_server.id]).
        create_post_policies(start_at, end_at)
    end
  end
end
