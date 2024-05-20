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

class CoursePacing::PaceContextsService
  attr_reader :course

  def initialize(course)
    @course = course
  end

  def contexts_of_type(type, params: {})
    case type
    when "course"
      [course]
    when "section"
      sections = course.active_course_sections
      sections = sections.where("name ILIKE ?", "%#{params[:search_term]}%") if params[:search_term].present?
      sections = sections.where("id in ( ? )", JSON.parse(params[:contexts])) if params[:contexts].present?
      sections = sections.order(params[:sort]) if params[:sort] == "name"
      sections = sections.reverse_order if params[:order] == "desc"
      sections
    when "student_enrollment"
      student_enrollments = course.all_real_student_enrollments.order(:user_id, created_at: :desc).select("DISTINCT ON(enrollments.user_id) enrollments.*")
      student_enrollments = student_enrollments.where("enrollments.workflow_state in ('active', 'creation_pending', 'invited')")
      student_enrollments = student_enrollments.where("enrollments.id in ( ? )", JSON.parse(params[:contexts])) if params[:contexts].present?
      student_enrollments = student_enrollments.joins(:user).where("users.name ILIKE ?", "%#{params[:search_term]}%") if params[:search_term].present?
      student_enrollments = student_enrollments.joins(:user).order("users.sortable_name") if params[:sort] == "name"
      student_enrollments = student_enrollments.reverse_order if params[:order] == "desc"
      student_enrollments.to_a
    else
      raise ArgumentError, "Expected a value of 'course', 'section', or 'student_enrollment', got '#{type}'"
    end
  end
end
