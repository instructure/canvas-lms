#
# Copyright (C) 2016 Instructure, Inc.
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

module CollaborationsHelper

  def collaboration(collab, user, google_drive_enabled)
    if collab.is_a?(GoogleDocsCollaboration) && !google_drive_enabled
      render 'collaborations/auth_google_drive', collaboration: collab
    else
      render 'collaborations/collaboration', collaboration: collab, user: user
    end
  end

  def collaboration_links(collab, user)
    if can_do(collab, user, :update, :delete)
      render 'collaborations/collaboration_links', collaboration: collab, user: user
    end
  end

  def edit_button(collab, user)
    render 'collaborations/edit_button', collaboration: collab if can_do(collab, user, :update)
  end

  def delete_button(collab, user)
    render 'collaborations/delete_button', collaboration: collab if can_do(collab, user, :delete)
  end


end