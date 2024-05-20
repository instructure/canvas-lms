# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

class AttachmentSerializer < Canvas::APISerializer
  include Api::V1::Attachment

  root :attachment

  def_delegators :@controller,
                 :lock_explanation,
                 :thumbnail_image_url,
                 :file_download_url

  def initialize(object, options)
    super(object, options)

    %w[current_user current_pseudonym quota quota_used].each do |ivar|
      instance_variable_set :"@#{ivar}", @controller.instance_variable_get(:"@#{ivar}")
    end
  end

  def serializable_object(...)
    attachment_json(object, current_user)
  end
end
