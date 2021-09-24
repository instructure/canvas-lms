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

# 100% shorthand
module CodepointTestHelper
  def assert_equal_encoded(expected, encode_mes)
    # Killing a duck because Ruby 1.9 doesn't mix Enumerable into String
    encode_mes = [encode_mes] if encode_mes.is_a?(String)
    encode_mes.each do |encode_me|
      encoded = LuckySneaks::Unidecoder.encode(encode_me)
      actual = encoded.to_ascii
      if expected != actual
        message = "<#{expected.inspect}> expected but was <#{actual.inspect}>\n"
        message << "  defined in #{LuckySneaks::Unidecoder.in_json_file(encoded)}"
        fail message
        #raise Test::Unit::AssertionFailedError.new(message)
      end
    end
  end
end
