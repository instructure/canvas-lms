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

class Bookmarks::Bookmark < ActiveRecord::Base
  acts_as_list scope: :user_id
  def data
    json ? JSON.parse(json) : nil
  end

  def data=(data)
    self.json = data.to_json
  end

  def as_json
    super(include_root: false, except: [:json, :user_id]).merge({ data: })
  end
end
