# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

require "singleton"

module AdheresToPolicy
  class Success
    include Singleton

    def success?
      true
    end
  end

  class Failure
    include Singleton

    def justifications
      []
    end

    def success?
      false
    end
  end

  JustifiedFailure = Struct.new(:justification, :context) do
    def success?
      false
    end

    def justifications
      [self]
    end
  end

  JustifiedFailures = Struct.new(:justifications) do
    def success?
      false
    end
  end
end
