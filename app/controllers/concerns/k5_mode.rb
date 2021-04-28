# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

module K5Mode
  extend ActiveSupport::Concern

  included do
    before_action :set_k5_mode
  end

  private

  def set_k5_mode
    @k5_mode = @context.try(:elementary_subject_course?)
    # Only students should see the details view
    @k5_details_view = @k5_mode && @context.try(:students)&.include?(@current_user)
    @show_left_side = !@k5_details_view
  end
end
