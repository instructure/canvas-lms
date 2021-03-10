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

class AddNullIndexForCanvadocsAnnotationContexts < ActiveRecord::Migration[6.0]
  tag :predeploy

  def change
    change_table :canvadocs_annotation_contexts do |t|
      t.remove_index :attachment_id

      t.index(
        [:attachment_id, :submission_id],
        where: "submission_attempt IS NULL",
        name: "index_attachment_submission",
        unique: true
      )
    end
  end
end
