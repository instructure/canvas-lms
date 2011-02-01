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
    def chars
      return @chars if @chars
      @chars = (65..90).map { |x| x.chr }
      @chars << (48..57).map { |x| x.chr }
      @chars << (97..122).map { |x| x.chr }
      @chars.flatten!
    end
  
    def rand_char
      chars[rand(chars.size)]
    end

    def generate(purpose=nil, n=4)
      slug = purpose + '-' if purpose
      slug ||= ''
      n.times { slug << rand_char }
      slug
    end
  end
end
