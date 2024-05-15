# frozen_string_literal: true

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
#

require "securerandom"
require "swearjar"

class CanvasSlug
  class << self
    # omit easily-confused characters in user-visible slugs
    CHARS = %w[2 3 4 6 7 8 9 a c e f h k m n r t u v w x y z A B C D E F G H J K L M N P Q R T U V W X Y Z].freeze
    SJ = Swearjar.default

    def generate_securish_uuid(length = 40)
      SecureRandom.alphanumeric(length)
    end

    def generate_user_friendly_code(length = 4)
      # Ensure we don't get naughties by looping until we get something
      # "clean". Loop count is arbitrary, we use length as shorter strings
      # are less likely to result in problematic strings.
      uuid = ""
      length.times do
        uuid = Array.new(length) { CHARS[SecureRandom.random_number(CHARS.length)] }.join
        return uuid unless SJ.profane?(uuid)
      end

      # TODO: raise exception to allow consumer to handle
      # raise "CanvasSlug couldn't find valid uuid after #{length} attempts"
      uuid
    end

    def generate(purpose = nil, length = 4)
      slug = +""
      slug << purpose << "-" if purpose
      slug << generate_user_friendly_code(length)
      slug
    end
  end
end

# TODO: stub until other references to CanvasUuid outside core canvas-lms
# are replaced with CanvasSlug. remove when those are updated.
module CanvasUuid
  Uuid = CanvasSlug
end
