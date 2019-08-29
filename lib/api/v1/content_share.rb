#
# Copyright (C) 2019 - present Instructure, Inc.
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

module Api::V1::ContentShare
  include Api::V1::Json
  include Api::V1::ContentExport

  def content_share_json(content_share, user, session, opts = {})
    json = api_json(content_share, user, session, opts.merge(only: %w(id name created_at updated_at user_id read_state)))
    json['sender'] = content_share.respond_to?(:sender) ? user_display_json(content_share.sender) : nil
    json['receivers'] = content_share.respond_to?(:receivers) ? content_share.receivers.map {|rec| user_display_json(rec)} : []
    json
  end
end
