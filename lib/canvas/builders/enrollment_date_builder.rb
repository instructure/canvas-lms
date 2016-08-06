#
# Copyright (C) 2011 - 2013 Instructure, Inc.
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

module Canvas::Builders
class EnrollmentDateBuilder
  attr_reader :enrollment_dates

  def initialize(enrollment)
    @enrollment = enrollment
    @course = @enrollment.course
    @section = @enrollment.course_section
    @term = @course ? @course.enrollment_term : nil
    @enrollment_dates = []
  end

  def self.preload(enrollments, use_cache=true)
    raise "call #to_a first before preloading enrollment scope" if enrollments.is_a?(ActiveRecord::Relation)
    # if enrollments is still a relation, we'll be unnecessarily calling the query multiple times
    # below with `enrollments.empty?` and `enrollments.first`
    return if enrollments.empty?
    preload_state(enrollments)

    courses_loaded = enrollments.first.association(:course).loaded?
    ActiveRecord::Associations::Preloader.new.preload(enrollments, :course) unless courses_loaded

    to_preload = use_cache ? enrollments.reject { |e| fetch(e) } : enrollments
    return if to_preload.empty?
    ActiveRecord::Associations::Preloader.new.preload(to_preload, :course_section)
    ActiveRecord::Associations::Preloader.new.preload(to_preload.map(&:course).uniq, :enrollment_term)
    to_preload.each { |e| build(e) }
  end

  # TODO: other places where we use #preload should be replaced with #preload_state after all the states are created
  def self.preload_state(enrollments)
    return if enrollments.empty?

    unless enrollments.first.association(:enrollment_state).loaded?
      ActiveRecord::Associations::Preloader.new.preload(enrollments, :enrollment_state)
    end
  end

  def self.cache_key(enrollment)
    [enrollment, enrollment.course, 'enrollment_date_ranges'].cache_key
  end

  def self.fetch(enrollment)
    result = RequestCache.cache('enrollment_dates', enrollment) do
      Rails.cache.read(cache_key(enrollment))
    end
    enrollment.instance_variable_set(:@enrollment_dates, result)
  end

  def self.build(enrollment)
    EnrollmentDateBuilder.new(enrollment).build
  end

  def cache_key
    @cache_key ||= self.class.cache_key(@enrollment)
  end

  def build
    if enrollment_is_restricted?
      add_enrollment_dates(@enrollment)
    elsif section_is_restricted?
      add_enrollment_dates(@section)
      add_term_dates if @enrollment.admin?
    elsif course_is_restricted?
      add_enrollment_dates(@course)
      add_term_dates if @enrollment.admin?
    elsif @term
      add_term_dates
    else
      @enrollment_dates << default_dates
    end

    RequestCache.cache('enrollment_dates', self) do
      @enrollment_dates
    end

    Rails.cache.write(cache_key, @enrollment_dates)
    @enrollment.instance_variable_set(:@enrollment_dates, @enrollment_dates)
  end

  private

  def default_dates
    [nil, nil]
  end

  def add_enrollment_dates(context)
    @enrollment_dates << [context.start_at, context.end_at]
  end

  def add_term_dates
    if @term
      @enrollment_dates << @term.enrollment_dates_for(@enrollment)
    end
  end

  def course_is_restricted?
    @course && @course.restrict_enrollments_to_course_dates
  end

  def section_is_restricted?
    @section && @section.restrict_enrollments_to_section_dates
  end

  def enrollment_is_restricted?
    @enrollment.start_at && @enrollment.end_at
  end
end
end