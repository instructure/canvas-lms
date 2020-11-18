# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

module EpubExports
  class CourseEpubExportsPresenter
    def initialize(current_user)
      @current_user = current_user
    end
    attr_reader :current_user

    def courses
      @_courses ||= courses_with_feature_enabled.map do |course|
        course.latest_epub_export = epub_exports.find do |epub_export|
          epub_export.course_id == course.id
        end

        course
      end
    end

    private
    def courses_not_including_epub_exports

      @_courses_not_including_epub_exports ||= Course.joins(:enrollments).
        where(Enrollment::QueryBuilder.new(:current_and_concluded).conditions).
        where(
        'enrollments.type IN (?) AND enrollments.user_id = ?',
        [StudentEnrollment, TeacherEnrollment, TaEnrollment],
        current_user
      ).to_a
    end

    def courses_with_feature_enabled
      @_courses_with_feature_enabled ||= courses_not_including_epub_exports.delete_if do |course|
        !course.feature_enabled?(:epub_export)
      end
    end

    def epub_exports
      @_epub_exports ||=
        begin
          exports = EpubExport.where({
            course_id: courses_with_feature_enabled,
            user_id: current_user,
            type: nil
            }).select("DISTINCT ON (epub_exports.course_id) epub_exports.*").
            order("course_id, created_at DESC").
            preload(:epub_attachment, :job_progress, :zip_attachment).to_a
          EpubExport.fail_stuck_epub_exports(exports)
          exports
        end
    end
  end
end
