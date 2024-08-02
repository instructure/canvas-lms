# frozen_string_literal: true

# Copyright (C) 2024 - present Instructure, Inc.
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

module DataFixup::RenameLtiScope
  def self.run(old_scope, new_scope)
    return unless old_scope && new_scope

    DeveloperKey.where("scopes like ?", "%#{old_scope}%").in_batches do |batch|
      Lti::ToolConfiguration.where(developer_key: batch.pluck(:id)).update_all(["settings['scopes'] = replace(settings->>'scopes', ?, ?)::json", old_scope, new_scope])
      batch.update_all(["scopes = replace(scopes, ?, ?)", old_scope, new_scope])
    end
  end
end
