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

class ContentTagsDueDateCacherIndex < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!
  tag :postdeploy

  def change
    add_index :content_tags,
              %i[content_type context_type context_id],
              where: "workflow_state<>'deleted'",
              name: "index_content_tags_for_due_date_cacher",
              algorithm: :concurrently,
              if_not_exists: true
  end
end
