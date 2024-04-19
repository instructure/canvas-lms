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

require "ostruct"

class OpenStruct
  def as_json(*)
    table
  end
end

class OpenObject < OpenStruct # rubocop:disable Style/OpenStructUse
  def initialize(*args, in_specs: false)
    unless in_specs
      raise "Do not use OpenObject except for testing backwards compatibility with prior OpenObject usage"
    end

    super(*args)
  end
end
