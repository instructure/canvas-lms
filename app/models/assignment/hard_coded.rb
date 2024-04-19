# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

class Assignment
  # Used by GradebooksController to represent a Group or Period as an assignment
  class HardCoded < AbstractAssignment
    # Rails removes the :id method, so we have to trick it
    module Id
      attr_reader :id
    end
    prepend Id

    attr_accessor :rules, :group_weight, :asset_string, :special_class

    def initialize(attributes)
      super

      @id = attributes[:id]
    end

    def hard_coded
      true
    end

    private

    def _create_record
      raise "Hard coded assignments should not be saved"
    end
  end
end
