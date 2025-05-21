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

class Loaders::CourseSubmissionDataLoader < GraphQL::Batch::Loader
  def initialize(data_type, options = {})
    @data_type = data_type
    @options = options
    @current_user = options[:current_user]
    super()
  end

  def self.for(data_type, options = {})
    new(data_type, options)
  end

  def perform(objects)
    # Assume most objects are course IDs (common case)
    course_ids = []
    course_objects = {}

    # Separate course objects from IDs
    objects.each do |object|
      if object.is_a?(Course)
        course_objects[object.id.to_s] = object
      elsif object.is_a?(Integer) || object.is_a?(String)
        course_ids << object.to_s
      end
    end

    # Fetch all courses by ID that weren't already provided as objects
    remaining_ids = course_ids - course_objects.keys
    unless remaining_ids.empty?
      Course.where(id: remaining_ids).find_each do |course|
        course_objects[course.id.to_s] = course
      end
    end

    # Process all objects
    objects.each do |object|
      object_id = object.is_a?(Course) ? object.id.to_s : object.to_s
      course = object.is_a?(Course) ? object : course_objects[object_id]

      next if course.nil?

      # Use current_user since we're not expecting User objects
      result = get_data(course, @current_user)
      fulfill(object, result)
    end
  end

  def get_data(course, user)
    return 0 if user.nil?

    case @data_type
    when :missing_submissions_count
      # Count missing submissions for a user in a specific course
      # A submission is considered missing when it:
      # - Has been marked as "missing" via late_policy_status, OR
      # - Has not been submitted, is past due, and has not been excused
      user.submissions
          .where(course_id: course.id)
          .except(:order)
          .missing
          .merge(Assignment.published)
          .distinct
          .count
    when :submissions_due_this_week_count
      start_date = @options[:start_date] || Time.zone.now
      end_date = @options[:end_date] || start_date.advance(days: 7)

      # Count submissions with due dates in the provided date range for this course
      # Use submissions with cached_due_date within the specified range
      # This matches the test setup which sets cached_due_date on submissions
      user.submissions
          .where(course_id: course.id)
          .where(cached_due_date: start_date..end_date)
          .except(:order)
          .joins(:assignment)
          .merge(Assignment.published)
          .distinct
          .count
    else
      raise ArgumentError, "Unknown data type: #{@data_type}"
    end
  end
end
