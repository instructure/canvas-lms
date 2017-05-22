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

class RemoveAttachmentsWithNoScopeFromList < ActiveRecord::Migration[4.2]
  tag :predeploy

  disable_ddl_transaction!

  def self.up
    if Attachment.maximum(:id)
      i = 0
      # we do one extra loop to avoid race conditions
      while i < Attachment.maximum(:id) + 10000
        Attachment.where("folder_id IS NULL AND id>? AND id <=?", i, i + 10000).update_all(:position => nil)
        sleep 1
        i = i + 10000
      end
    end
  end

  def self.down
  end
end
