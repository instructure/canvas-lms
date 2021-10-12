# frozen_string_literal: true

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
class AddExternalToolFieldsToSubmissionDraft < ActiveRecord::Migration[6.0]
  tag :predeploy

  def change
    change_table :submission_drafts, bulk: false do |t|
      t.column :context_external_tool_id, :bigint
      t.column :lti_launch_url, :text
      t.column :resource_link_lookup_uuid, :uuid
    end
  end
end
