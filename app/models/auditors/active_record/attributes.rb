# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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
module Auditors::ActiveRecord
  module Attributes
    def fetch(key)
      self[key]
    end

    def [](key)
      if key.to_s == 'attributes'
        self
      else
        # this works because we expect this module to be included
        # in AR models, which allow you to use the square bracket
        # interface for attribute access
        super
      end
    end
  end
end
