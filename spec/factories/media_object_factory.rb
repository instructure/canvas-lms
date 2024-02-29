# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

module Factories
  def media_object(opts = {})
    mo = MediaObject.new
    mo.context = opts[:context] || @course
    mo.media_id = opts[:media_id] || "1234"
    mo.media_type = opts[:media_type] || "video"
    mo.title = opts[:title] || "media_title"
    mo.user = opts[:user] || @user
    mo.save!
    mo
  end

  def media_object_model(opts = {})
    mo = MediaObject.new
    mo.context = opts[:context] || @course
    mo.media_id = opts[:media_id] || "1234"
    mo.media_type = opts[:media_type] || "video/mp4"
    mo.title = opts[:title] || "my_media_title"
    mo.user = opts[:user] || @user
    mo.save!
    mo
  end
end
