#
# Copyright (C) 2013 - present Instructure, Inc.
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

require 'hash_view'
require 'formatted_type'

class ObjectPartView < HashView
  attr_reader :name, :part

  # 'part' is a hash of name/example pairs, e.g.
  # { "name": "Sheldon Cooper", "email": "sheldon@caltech.example.com" }
  def initialize(name, part)
    @name = name
    @part = part
  end

  def guess_type(example)
    FormattedType.new(example).to_hash
  end

  def property_pairs
    @property_pairs ||=
      @part.map do |name, example|
        [
          name,
          guess_type(example)
        ]
      end
  end

  def properties
    Hash[property_pairs]
  end
end