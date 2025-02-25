# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

class CoursePacing::CoursePaceService < CoursePacing::PaceService
  class << self
    def paces_in_course(course)
      course.course_paces.primary
    end

    def pace_in_context(course)
      paces_in_course(course).first
    end

    def template_pace_for(_)
      nil
    end

    def course_for(course)
      course
    end

    def off_pace_counts_by_user(contexts)
      return {} if contexts.empty? || !contexts.first.is_a?(StudentEnrollment) || !contexts.first.course

      users = contexts.map(&:user)
      course = contexts.first.course

      submissions = course.submissions.where(user: users)
      missing_submission_ids = submissions.missing.pluck(:id)
      Submission.where(id: missing_submission_ids).group(:user_id).count
    end
  end
end
