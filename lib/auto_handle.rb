#
# Copyright (C) 2011 Instructure, Inc.
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

# Slug.generate

class AutoHandle
  class << self
    CHARS = ('0'..'9').to_a + ('a'..'z').to_a + ('A'..'Z').to_a
    def generate_securish_uuid(length = 40)
      Array.new(length) { CHARS[SecureRandom.random_number(CHARS.length)] }.join
    end
    
    def generate(purpose = nil, length = 4)
      slug = ''
      slug << purpose << '-' if purpose
      slug << generate_securish_uuid(length)
      slug
    end
  end
end
