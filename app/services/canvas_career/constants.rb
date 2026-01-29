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

module CanvasCareer
  module Constants
    module App
      CAREER_LEARNER = "career_learner"
      CAREER_LEARNING_PROVIDER = "career_learning_provider"
      ACADEMIC = "academic"
    end

    CAREER_APPS = [App::CAREER_LEARNER, App::CAREER_LEARNING_PROVIDER].freeze

    module Experience
      CAREER = "career"
      ACADEMIC = "academic"

      def self.all
        [CAREER, ACADEMIC]
      end

      def self.valid?(value)
        all.include?(value)
      end
    end

    module Role
      LEARNER = "learner"
      LEARNING_PROVIDER = "learning_provider"

      def self.all
        [LEARNER, LEARNING_PROVIDER]
      end

      def self.valid?(value)
        all.include?(value)
      end
    end

    module Overrides
      CAREER_ENROLLMENT_TYPE_OVERRIDES = {
        "StudentEnrollment" => {
          label: -> { I18n.t("#enrollment.roles.learner", default: "Learner") },
          plural_label: -> { I18n.t("#enrollment.roles.learners", default: "Learners") }
        },
        "StudentViewEnrollment" => {
          label: -> { I18n.t("#enrollment.roles.learner", default: "Learner") },
          plural_label: -> { I18n.t("#enrollment.roles.learners", default: "Learners") }
        },
        "TeacherEnrollment" => {
          label: -> { I18n.t("#enrollment.roles.instructor", default: "Instructor") },
          plural_label: -> { I18n.t("#enrollment.roles.instructors", default: "Instructors") }
        },
        "TaEnrollment" => {
          label: -> { I18n.t("#enrollment.roles.facilitator", default: "Facilitator") },
          plural_label: -> { I18n.t("#enrollment.roles.facilitators", default: "Facilitators") }
        }
      }.freeze

      CAREER_PERMISSION_LABEL_OVERRIDES = {
        manage_students: {
          label: -> { I18n.t("permissions.manage_learners_course", default: "Manage learners for the course") },
          group_label: -> { I18n.t("permissions.users_learners", default: "Users - Learners") }
        },
        add_student_to_course: {
          label: -> { I18n.t("permissions.add_learners_courses", default: "Add Learners to courses") },
          group_label: -> { I18n.t("permissions.users_learners", default: "Users - Learners") }
        },
        remove_student_from_course: {
          label: -> { I18n.t("permissions.remove_learners_courses", default: "Remove Learners from courses") },
          group_label: -> { I18n.t("permissions.users_learners", default: "Users - Learners") }
        },
        add_teacher_to_course: {
          label: -> { I18n.t("permissions.add_instructors_courses", default: "Add Instructors to courses") },
          group_label: -> { I18n.t("permissions.users_instructors", default: "Users - Instructors") }
        },
        remove_teacher_from_course: {
          label: -> { I18n.t("permissions.remove_instructors_courses", default: "Remove Instructors from courses") },
          group_label: -> { I18n.t("permissions.users_instructors", default: "Users - Instructors") }
        },
        add_ta_to_course: {
          label: -> { I18n.t("permissions.add_facilitators_courses", default: "Add Facilitators to courses") },
          group_label: -> { I18n.t("permissions.users_facilitators", default: "Users - Facilitators") }
        },
        remove_ta_from_course: {
          label: -> { I18n.t("permissions.remove_facilitators_courses", default: "Remove Facilitators from courses") },
          group_label: -> { I18n.t("permissions.users_facilitators", default: "Users - Facilitators") }
        },
        view_group_pages: {
          label: -> { I18n.t("permissions.view_group_pages_learner", default: "View the group pages of all learner groups") }
        },
        view_students_in_need: {
          label: -> { I18n.t("permissions.learners_in_need", default: "Learners in Need of Attention") }
        },
        view_students_in_need_in_course: {
          label: -> { I18n.t("permissions.intelligent_insights_learners_course", default: "Intelligent Insights - Learners in Need of Attention - Course Level") }
        },
        generate_observer_pairing_code: {
          label: -> { I18n.t("permissions.users_generate_observer_codes", default: "Users - generate observer pairing codes for learners") }
        },
        proxy_assignment_submission: {
          label: -> { I18n.t("permissions.instructors_submit_for_learners", default: "Instructors can submit on behalf of learners") }
        },
        create_collaborations: {
          label: -> { I18n.t("permissions.create_learner_collaborations", default: "Create learner collaborations") }
        }
      }.freeze

      def self.enrollment_type_overrides
        CAREER_ENROLLMENT_TYPE_OVERRIDES
      end

      def self.permission_label_overrides
        CAREER_PERMISSION_LABEL_OVERRIDES
      end
    end

    module QueryParams
      ACADEMIC_CONTENT_ONLY_CAREER_THEME = {
        content_only: "true",
        instui_theme: "career",
        force_classic: "true",
        hide_global_nav: "true"
      }.freeze
    end
  end
end
