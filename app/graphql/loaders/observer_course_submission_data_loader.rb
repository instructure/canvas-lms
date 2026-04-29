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

##
# Loader for retrieving course submission data.
# For observers: returns submission data from observed students.
# For non-observers: returns their own submission data.
#
class Loaders::ObserverCourseSubmissionDataLoader < GraphQL::Batch::Loader
  include ObserverEnrollmentsHelper

  def initialize(current_user:, request: nil, observed_user_id: nil)
    super()
    @current_user = current_user
    @request = request
    @observed_user_id = observed_user_id
  end

  def perform(courses)
    unless @current_user
      courses.each { |course| fulfill(course, []) }
      return
    end

    courses.each do |course|
      observed_students = ObserverEnrollment.observed_students(course, @current_user, include_restricted_access: false).keys

      # Check if user has any observer enrollments in this course
      is_observer = course.observer_enrollments.for_user(@current_user).active_or_pending.exists?

      submissions = if observed_students.empty?
                      if is_observer
                        # Observer with no observed students - return empty array
                        []
                      else
                        # Non-observer - return their own submissions
                        @current_user.submissions
                                     .joins(:assignment)
                                     .merge(AbstractAssignment.published)
                                     .where(assignments: { context: course, has_sub_assignments: false })
                      end
                    else
                      # Determine which student to get submissions for
                      selected_student = if @observed_user_id
                                           # Use the explicitly provided observed_user_id
                                           observed_students.find { |s| s.id.to_s == @observed_user_id.to_s }
                                         else
                                           # Fall back to cookie-based selection
                                           selected_observed_student_from_cookie(@current_user, observed_students, @request)
                                         end

                      # If observed_user_id was provided but student not found in observed list, return empty
                      if selected_student.nil?
                        []
                      else
                        # Get submissions from the selected observed student
                        Submission
                          .active
                          .joins(:assignment, :user)
                          .merge(AbstractAssignment.published)
                          .where(
                            assignments: { context: course, has_sub_assignments: false },
                            user_id: selected_student.id
                          )
                      end
                    end

      fulfill(course, submissions.is_a?(Array) ? submissions : submissions.to_a)
    end
  end
end
