#
# Copyright (C) 2012 Instructure, Inc.
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

module Api::V1::Folders
  include Api::V1::Json

  def folders_json(folders, user, session, opts={})
    folders.map do |f|
      folder_json(f, user, session, opts)
    end
  end

  def folder_json(folder, user, session, opts={})
    can_view_hidden_files = opts.has_key?(:can_view_hidden_files) ? opts[:can_view_hidden_files] : folder.grants_right?(user, :update)
    json = api_json(folder, user, session,
            :only => %w(id name full_name position parent_folder_id context_type context_id unlock_at lock_at created_at updated_at))
    if folder
      if opts[:master_course_restricted_folder_ids]&.include?(folder.id)
        json['is_master_course_content'] = true
        json['restricted_by_master_course'] = true
      end
      json['locked'] = !!folder.locked
      json['folders_url'] = api_v1_list_folders_url(folder)
      json['files_url'] = api_v1_list_files_url(folder)
      json['files_count'] = can_view_hidden_files ? folder.attachments.not_deleted.count : folder.attachments.active.count
      json['folders_count'] = can_view_hidden_files ? folder.sub_folders.active.count : folder.sub_folders.active.not_hidden.count
      json['hidden'] = folder.hidden?
      json['locked_for_user'] = can_view_hidden_files ? false : !!folder.currently_locked
      json['hidden_for_user'] = can_view_hidden_files ? false : !!folder.hidden?
      json['for_submissions'] = folder.for_submissions?
    end
    json
  end
end
