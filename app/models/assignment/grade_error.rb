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
  class GradeError < StandardError
    attr_accessor :status_code, :error_code

    PROVISIONAL_GRADE_INVALID_SCORE = "PROVISIONAL_GRADE_INVALID_SCORE".freeze
    PROVISIONAL_GRADE_MODIFY_SELECTED = "PROVISIONAL_GRADE_MODIFY_SELECTED".freeze

    # The following parameters are all optional, and allow for different behavior
    # depending on the type of error.
    #
    # message: A human-readable message. May not be passed to the client.
    # status_code: A symbol corresponding to one of the Rails HTTP status codes.
    # error_code: A custom string (such as MAX_GRADERS_REACHED) for when status_code
    #   is not specific enough. Supply a value here if you want the client to
    #   behave specially or show a specific message for different error types.
    #   (Currently SpeedGrader pays attention to this parameter.)
    def initialize(message = nil, status_code = nil, error_code: nil)
      super(message)
      self.status_code = status_code
      self.error_code = error_code
    end
  end
end
