# encoding: UTF-8
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

require 'iconv'

module Utf8Cleaner
  # This doesn't make any attempt to convert other encodings to utf-8, it just
  # removes invalid bytes from otherwise valid utf-8 strings.
  # Basically, this is a last ditch effort, you probably don't want to use it
  # as part of normal request processing.
  # It's used for things like filtering out ErrorReport data so that we can
  # make sure we won't get an invalid utf-8 error trying to save the error
  # report to the db.
  def self.strip_invalid_utf8(string)
    return string if string.nil?
    # add four spaces to the end of the string, because iconv with the //IGNORE
    # option will still fail on incomplete byte sequences at the end of the input
    # we force_encoding on the returned string because Iconv.conv returns binary.
    string = Iconv.conv('UTF-8//IGNORE', 'UTF-8', string + '    ')[0...-4]
    if string.respond_to?(:force_encoding)
      string.force_encoding(Encoding::UTF_8)
    end
    # Strip ASCII backspace and delete characters
    string.tr("\b\x7F", '')
  end

  def self.recursively_strip_invalid_utf8!(object, force_utf8 = false)
    case object
      when Hash
        object.each_value { |o| self.recursively_strip_invalid_utf8!(o, force_utf8) }
      when Array
        object.each { |o| self.recursively_strip_invalid_utf8!(o, force_utf8) }
      when String
        if object.encoding == Encoding::ASCII_8BIT && force_utf8
          object.force_encoding(Encoding::UTF_8)
        end
        if !object.valid_encoding?
          object.replace(self.strip_invalid_utf8(object))
        end
    end
  end
end
