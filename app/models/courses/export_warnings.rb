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

module Courses
  module ExportWarnings
    def export_warnings
      warnings = []

      if grading_standard && !grading_standard.active?
        warnings << I18n.t("The course is associated with an archived or deleted grading scheme and the grading scheme may not be exported.")
      end

      if assignments.active.joins(:grading_standard).where.not(grading_standards: { workflow_state: "active" }).count > 0
        warnings << I18n.t("Some assignments are associated with an archived or deleted grading scheme and the grading scheme may not be exported.")
      end

      warnings
    end
  end
end
