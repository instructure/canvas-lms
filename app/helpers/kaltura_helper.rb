#
# Copyright (C) 2013 Instructure, Inc.
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
module KalturaHelper

  def append_sis_data(js_hash)
    if CanvasKaltura::ClientV3.config && CanvasKaltura::ClientV3.config['kaltura_sis'].present? && CanvasKaltura::ClientV3.config['kaltura_sis'] == "1" && @current_user
      pseudonym = @context ? SisPseudonym.for(@current_user, @context) : @current_user.primary_pseudonym
      js_hash[:SIS_SOURCE_ID] = @context.sis_source_id if (@context && @context.sis_source_id)
      js_hash[:SIS_USER_ID] = pseudonym.sis_user_id if (pseudonym && pseudonym.sis_user_id)
    end
  end

end
