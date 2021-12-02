# frozen_string_literal: true

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

class AddProcessingErrorsAttachmentToSisBatch < ActiveRecord::Migration[5.0]
  tag :predeploy

  def change
    add_column :sis_batches, :errors_attachment_id, :integer, :limit => 8
    add_foreign_key :sis_batches, :attachments, column: :errors_attachment_id
    add_index :sis_batches, :errors_attachment_id
  end
end
