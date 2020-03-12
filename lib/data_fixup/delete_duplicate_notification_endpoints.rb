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

module DataFixup::DeleteDuplicateNotificationEndpoints
  def self.run
    while (arns = NotificationEndpoint.joins(:access_token).group("arn, access_token_id").having("COUNT(*) > 1").limit(1000).pluck("arn, access_token_id")).any?
      arns.each do |arn, access_token_id|
        NotificationEndpoint.where(arn: arn, access_token_id: access_token_id).order(:id).offset(1).delete_all
      end
    end
  end
end
