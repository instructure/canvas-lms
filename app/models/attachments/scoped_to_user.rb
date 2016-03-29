#
# Copyright (C) 2011 - 2015 Instructure, Inc.
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

module Attachments
  class ScopedToUser < ScopeFilter
    include Api::V1::Attachment

    def scope
      context.is_a_context? ? scope_from_context : scope_from_folder
    end

    private
    def scope_from_context
      if can_view_hidden_files?(context, user)
        context.attachments.not_deleted
      else
        context.attachments.visible.not_hidden.not_locked.where({
          folder_id: Folder.all_visible_folder_ids(context)
        })
      end
    end

    def scope_from_folder
      if can_view_hidden_files?(context, user)
        context.active_file_attachments
      else
        context.visible_file_attachments.not_hidden.not_locked
      end
    end
  end
end
