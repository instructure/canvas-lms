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

module Types
  class CourseSettingsType < ApplicationObjectType
    graphql_name "CourseSettings"
    description "Settings for a course"

    alias_method :course, :object

    field :allow_final_grade_override, Boolean, "Whether the course allows final grade override", null: true
    def allow_final_grade_override
      course.allow_final_grade_override?
    end

    field :allow_student_discussion_topics, Boolean, "Whether the course allows students to create discussion topics", null: true
    def allow_student_discussion_topics
      course.allow_student_discussion_topics?
    end

    field :allow_student_forum_attachments, Boolean, "Whether the course allows students to attach files to discussion posts", null: true
    def allow_student_forum_attachments
      course.allow_student_forum_attachments?
    end

    field :allow_student_discussion_editing, Boolean, "Whether the course allows students to edit their discussion posts", null: true
    def allow_student_discussion_editing
      course.allow_student_discussion_editing?
    end

    field :allow_student_discussion_reporting, Boolean, "Whether the course allows students to report discussion posts", null: true
    def allow_student_discussion_reporting
      course.allow_student_discussion_reporting?
    end

    field :allow_student_anonymous_discussion_topics, Boolean, "Whether the course allows students to create anonymous discussion topics", null: true
    def allow_student_anonymous_discussion_topics
      course.allow_student_anonymous_discussion_topics?
    end

    field :filter_speed_grader_by_student_group, Boolean, "Whether the course filters SpeedGrader by student group", null: true
    def filter_speed_grader_by_student_group
      course.filter_speed_grader_by_student_group?
    end

    field :grading_standard_enabled, Boolean, "Whether the course has a grading standard enabled", null: true
    def grading_standard_enabled
      course.grading_standard_enabled?
    end

    field :grading_standard_id, ID, "ID of the grading standard, if enabled", null: true
    delegate :grading_standard_id, to: :course

    field :grade_passback_setting, String, "Grade passback setting for the course", null: true
    delegate :grade_passback_setting, to: :course

    field :allow_student_organized_groups, Boolean, "Whether the course allows student organized groups", null: true
    def allow_student_organized_groups
      course.allow_student_organized_groups?
    end

    field :hide_final_grades, Boolean, "Whether the course hides final grades from students", null: true
    def hide_final_grades
      course.hide_final_grades?
    end

    field :hide_distribution_graphs, Boolean, "Whether the course hides grade distribution graphs from students", null: true
    def hide_distribution_graphs
      course.hide_distribution_graphs?
    end

    field :hide_sections_on_course_users_page, Boolean, "Whether the course hides sections on the course users page", null: true
    def hide_sections_on_course_users_page
      course.hide_sections_on_course_users_page?
    end

    field :lock_all_announcements, Boolean, "Whether the course locks all announcements", null: true
    def lock_all_announcements
      course.lock_all_announcements?
    end

    field :usage_rights_required, Boolean, "Whether the course requires usage rights for uploaded files", null: true
    def usage_rights_required
      course.usage_rights_required?
    end

    field :restrict_student_past_view, Boolean, "Whether the course restricts students from viewing past courses", null: true
    def restrict_student_past_view
      course.restrict_student_past_view?
    end

    field :restrict_student_future_view, Boolean, "Whether the course restricts students from viewing future courses", null: true
    def restrict_student_future_view
      course.restrict_student_future_view?
    end

    field :restrict_quantitative_data, Boolean, "How the course restricts quantitative data for students", null: true
    def restrict_quantitative_data
      # Convert string to boolean if needed
      val = course.restrict_quantitative_data
      if val == "true"
        true
      elsif val == "false"
        false
      else
        val
      end
    end

    field :show_announcements_on_home_page, Boolean, "Whether the course shows announcements on the home page", null: true
    def show_announcements_on_home_page
      course.show_announcements_on_home_page?
    end

    field :home_page_announcement_limit, Integer, "Maximum number of announcements to show on the home page", null: true
    delegate :home_page_announcement_limit, to: :course

    field :syllabus_course_summary, Boolean, "Whether the course shows the syllabus course summary", null: true
    def syllabus_course_summary
      course.syllabus_course_summary?
    end

    field :homeroom_course, Boolean, "Whether the course is a homeroom course", null: true
    def homeroom_course
      course.homeroom_course?
    end

    field :image_url, String, "URL to the course image", null: true
    delegate :image_url, to: :course

    field :image_id, ID, "ID of the course image", null: true
    delegate :image_id, to: :course

    field :banner_image_url, String, "URL to the course banner image", null: true
    delegate :banner_image_url, to: :course

    field :banner_image_id, ID, "ID of the course banner image", null: true
    delegate :banner_image_id, to: :course

    field :course_color, String, "Color for the course", null: true
    delegate :course_color, to: :course

    field :friendly_name, String, "Friendly name for the course", null: true
    def friendly_name
      # In Course model, friendly_name returns alt_name.presence if elementary_enabled?
      course.alt_name
    end

    field :default_due_time, String, "Default due time for the course", null: true
    def default_due_time
      course.default_due_time || "23:59:59"
    end

    field :conditional_release, Boolean, "Whether the course has conditional release enabled", null: true
    def conditional_release
      course.conditional_release?
    end

    field :show_teacher_only_module_id, ID, "ID of the module that should only be shown to teachers", null: true
    def show_teacher_only_module_id
      course.settings[:show_teacher_only_module_id]
    end

    field :show_student_only_module_id, ID, "ID of the module that should only be shown to students", null: true
    def show_student_only_module_id
      course.settings[:show_student_only_module_id]
    end
  end
end
