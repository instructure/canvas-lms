#
# Copyright (C) 2019 - present Instructure, Inc.
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

module DataFixup::PopulateFinalGradeOverrideCourseSetting
  def self.run
    # We only need to do work if this feature has been enabled for a course
    # or forced on for an account in this shard
    return unless FeatureFlag.exists?(feature: 'final_grades_override', state: 'on')

    User.find_ids_in_ranges do |start_at, end_at|
      users_with_preference = User.where(id: start_at..end_at).
        where("preferences LIKE '%show_final_grade_overrides%'").
        where("EXISTS (?)", Enrollment.of_instructor_type.where("enrollments.user_id = users.id")).
        preload(:all_courses)

      users_with_preference.find_each do |user|
        convert_user_settings!(user)
      end
    end
  end

  def self.convert_user_settings!(user)
    # The GB settings hash includes keys for specific courses and other
    # non-specific keys (like :colors); we only want the former
    course_ids_with_settings = user.preferences[:gradebook_settings].keys.select { |key| key.is_a?(Integer) }

    user.all_courses.select { |course| course_ids_with_settings.include?(course.id) }.each do |course|
      user_settings_for_course = user.preferences.dig(:gradebook_settings, course.id)
      next unless user_settings_for_course&.key?("show_final_grade_overrides")

      # Always remove the user setting if it's present
      user_override_setting = user_settings_for_course.delete("show_final_grade_overrides")

      # ...but, since we iterate by individual user and the course setting
      # should be true if *any* instructor has enabled the feature for the
      # course, don't ever clobber an existing course value of true. Setting
      # the value to false is okay if it hasn't been set yet.
      course_override_setting = course.allow_final_grade_override
      if course_override_setting != "true" && course_override_setting != user_override_setting
        course.update!(allow_final_grade_override: user_override_setting)
      end
    end

    user.save! if user.changed?
  end
end
