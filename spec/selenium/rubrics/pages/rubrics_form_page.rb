# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

require_relative "../../common"

class RubricsForm
  class << self
    include SeleniumDependencies

    def rubric_title_input
      f("[data-testid='rubric-form-title']")
    end

    def save_rubric_button
      f("[data-testid='save-rubric-button']")
    end

    def add_criterion_button
      f("[data-testid='add-criterion-button']")
    end

    def save_criterion_button
      f("[data-testid='rubric-criterion-save']")
    end

    def rubric_criterion_modal
      f("[data-testid='rubric-criterion-modal']")
    end

    def criterion_name_input
      f("[data-testid='rubric-criterion-description']")
    end
  end
end
