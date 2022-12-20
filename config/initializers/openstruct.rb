# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

if RUBY_VERSION >= "3.0.0"
  module OpenStructOverrides
    # Ruby 3.0 changed the format of serializing OpenStruct, and tried to introduce
    # support for importing the legacy format. Unfortunately, this has a bug.
    #
    # Ruby 2.7 Example
    # require "ostruct"
    # require "yaml"
    # os = OpenStruct.new
    # os.a = 'b'
    # YAML.dump(os)
    # => "--- !ruby/object:OpenStruct\ntable:\n  :a: b\nmodifiable: true\n"
    #
    # The serialized OpenStruct has 2 keys - table and modifiable, but the actual
    # implementation expects only 1.
    # https://github.com/ruby/ruby/blob/b36a45c05cafc227ade3b59349482953321d6a89/lib/ostruct.rb#L419
    #
    # To test that this fix is no longer needed in future versions of Ruby, ensure
    # that the string above is correctly unserialized.

    def encode_with(coder) # :nodoc:
      super

      if @table.size == 2 && [:modifiable, :table].all? { |x| @table.key?(x) }
        # Add a bogus key so that the size is no longer 2
        coder["legacy_support!"] = true
      end
    end

    def init_with(coder)
      super

      h = coder.map

      if h.size == 2 && %w[modifiable table].all? { |x| h.key?(x) }
        update_to_values!(h["table"])
      end
    end
  end

  OpenStruct.prepend(OpenStructOverrides)
end
