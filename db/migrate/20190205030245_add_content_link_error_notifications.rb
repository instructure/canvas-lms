# frozen_string_literal: true

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


class AddContentLinkErrorNotifications < ActiveRecord::Migration[5.1]
  tag :predeploy

  def up
    return unless Shard.current == Shard.default
    Canvas::MessageHelper.create_notification({
      name: 'Content Link Error',
      delay_for: 120,
      category: 'Content Link Error'
    })
  end

  def down
    return unless Shard.current == Shard.default
    Notification.where(name: 'Content Link Error').delete_all
  end
end