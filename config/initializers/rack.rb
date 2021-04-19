# frozen_string_literal: true

#encoding:ASCII-8BIT
#
# Copyright (C) 2012 - present Instructure, Inc.
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

Rack::Utils.key_space_limit = 128.kilobytes # default is 64KB
Rack::Utils.multipart_part_limit = 256 # default is 128

module EnableRackChunking
  def chunkable_version?(*)
    if defined?(PactConfig)
      false
    elsif ::Rails.env.test? || ::Canvas::DynamicSettings.find(tree: :private)["enable_rack_chunking"]
      super
    else
      false
    end
  end
end
Rack::Chunked.prepend(EnableRackChunking)
