# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

require_relative "../app/services/canvas_career/label_overrides"

module EnrollmentTypes
  ENROLLMENT_TYPE_DEFINITIONS = {
    "StudentEnrollment" => {
      base_role_name: "StudentEnrollment",
      name: "StudentEnrollment",
      label: -> { I18n.t("roles.student", "Student") },
      plural_label: -> { I18n.t("roles.students", "Students") }
    },
    "TeacherEnrollment" => {
      base_role_name: "TeacherEnrollment",
      name: "TeacherEnrollment",
      label: -> { I18n.t("roles.teacher", "Teacher") },
      plural_label: -> { I18n.t("roles.teachers", "Teachers") }
    },
    "TaEnrollment" => {
      base_role_name: "TaEnrollment",
      name: "TaEnrollment",
      label: -> { I18n.t("roles.ta", "TA") },
      plural_label: -> { I18n.t("roles.tas", "TAs") }
    },
    "DesignerEnrollment" => {
      base_role_name: "DesignerEnrollment",
      name: "DesignerEnrollment",
      label: -> { I18n.t("roles.designer", "Designer") },
      plural_label: -> { I18n.t("roles.designers", "Designers") }
    },
    "ObserverEnrollment" => {
      base_role_name: "ObserverEnrollment",
      name: "ObserverEnrollment",
      label: -> { I18n.t("roles.observer", "Observer") },
      plural_label: -> { I18n.t("roles.observers", "Observers") }
    }
  }.freeze

  ENROLLMENT_TYPES = ENROLLMENT_TYPE_DEFINITIONS.keys.freeze

  def self.definitions(_context = nil)
    ENROLLMENT_TYPE_DEFINITIONS
  end

  def self.labels(context = nil)
    label_overrides = CanvasCareer::LabelOverrides.enrollment_type_overrides(context)

    ENROLLMENT_TYPES.map do |type|
      enrollment_def = ENROLLMENT_TYPE_DEFINITIONS[type]
      next enrollment_def unless label_overrides[type]

      override = label_overrides[type] || {}

      enrollment_def.merge({
                             label: override[:label] || enrollment_def[:label],
                             plural_label: override[:plural_label] || enrollment_def[:plural_label]
                           })
    end
  end
end
