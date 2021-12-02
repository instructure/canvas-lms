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
#

class Loaders::MediaObjectLoader < GraphQL::Batch::Loader
  def perform(media_object_ids)
    hashed_media = MediaObject.where(:media_id => media_object_ids.compact).to_a.index_by(&:media_id)

    media_object_ids.each do |media_id|
      fulfill(media_id, hashed_media[media_id])
    end
  end
end
