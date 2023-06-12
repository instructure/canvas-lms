# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

class TruncateLongAttachmentDisplayNames < ActiveRecord::Migration[7.0]
  tag :predeploy
  disable_ddl_transaction!

  def up
    # columns much larger than this can't be indexed with PG12 collations
    Attachment.where("pg_column_size(display_name) > 2000").find_each(strategy: :pluck_ids) do |attachment|
      attachment.update_attribute :display_name, Attachment.truncate_filename(attachment.display_name, 1000)
    end
  end

  def down; end
end
