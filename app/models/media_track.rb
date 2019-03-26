#
# Copyright (C) 2011 - present Instructure, Inc.
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

class MediaTrack < ActiveRecord::Base
  belongs_to :user
  belongs_to :media_object, :touch => true
  validates_presence_of :media_object_id, :content

  RE_LOOKS_LIKE_TTMl = /<tt\s+xml/i
  validates :content, format: {
    without: RE_LOOKS_LIKE_TTMl,
    message: "TTML tracks are not allowed because they are susceptible to xss attacks"
  }

end
