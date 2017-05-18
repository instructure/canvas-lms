#
# Copyright (C) 2012 - present Instructure, Inc.
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

module Api::V1
  class CourseJson

    BASE_ATTRIBUTES = %w(id name course_code account_id start_at default_view enrollment_term_id is_public
                         grading_standard_id root_account_id).freeze

    INCLUDE_CHECKERS = {grading: 'needs_grading_count', syllabus: 'syllabus_body',
                        url: 'html_url', description: 'public_description', permissions: 'permissions'}.freeze

    OPTIONAL_FIELDS = %w(needs_grading_count public_description enrollments).freeze

    attr_reader :course, :user, :includes, :enrollments, :hash

    def initialize(course, user, includes, enrollments)
      @course = course
      @user = user
      @includes = includes.map{ |include_key| include_key.to_sym }
      @enrollments = enrollments
      if block_given?
        @hash = yield(self, self.allowed_attributes, self.methods_to_send, self.permissions_to_include)
      else
        @hash = {}
      end
    end

    def allowed_attributes
      @allowed_attributes ||= @includes.is_a?(Array) ? BASE_ATTRIBUTES + @includes : BASE_ATTRIBUTES
    end

    def methods_to_send
      methods = ['end_at', 'public_syllabus', 'public_syllabus_to_auth', 'storage_quota_mb', 'is_public_to_auth_users']
      methods << 'hide_final_grades' if @includes.include?(:hide_final_grades)
      methods << 'storage_quota_used_mb' if @includes.include?(:storage_quota_used_mb)
      methods
    end

    def to_hash
      set_sis_course_id(@hash, @course, @user)
      set_integration_id(@hash, @course, @user)
      @hash['enrollments'] = extract_enrollments(@enrollments)
      @hash['needs_grading_count'] = needs_grading_count(@enrollments, @course)
      @hash['public_description'] = description(@course)
      @hash['hide_final_grades'] = @course.hide_final_grades?
      @hash['workflow_state'] = @course.api_state
      @hash['course_format'] = @course.course_format if @course.course_format.present?
      @hash['restrict_enrollments_to_course_dates'] = !!@course.restrict_enrollments_to_course_dates
      if @includes.include?(:current_grading_period_scores)
        @hash['has_grading_periods'] = @course.grading_periods?
        @hash['multiple_grading_periods_enabled'] = @hash['has_grading_periods'] # for backwards compatibility
        @hash['has_weighted_grading_periods'] = @course.weighted_grading_periods?
      end
      clear_unneeded_fields(@hash)
    end

    def self.to_hash(course, user, includes, enrollments, &block)
      self.new(course, user, includes, enrollments, &block).to_hash
    end

    def clear_unneeded_fields(hash)
      hash.reject{|k, v| (OPTIONAL_FIELDS.include?(k) && v.nil?) }
    end

    def description(course)
      course.public_description if include_description
    end

    def set_sis_course_id(hash, course, user)
      if course.grants_any_right?(user, :read_sis, :manage_sis)
        hash['sis_course_id'] = course.sis_source_id
      end
    end

    def set_integration_id(hash, course, user)
      if course.grants_any_right?(user, :read_sis, :manage_sis)
        hash['integration_id'] = course.integration_id
      end
    end

    def needs_grading_count(enrollments, course)
      if include_grading && enrollments && enrollments.any? { |e| e.participating_instructor? }
        proxy = Assignments::NeedsGradingCountQuery::CourseProxy.new(course, user)
        course.assignments.active.to_a.sum{|a| Assignments::NeedsGradingCountQuery.new(a, user, proxy).count }
      end
    end

    def permissions_to_include
      [ :create_discussion_topic, :create_announcement ] if include_permissions
    end

    def extract_enrollments(enrollments)
      return unless enrollments
      if include_total_scores?
        ActiveRecord::Associations::Preloader.new.preload(enrollments, :scores)
      end
      enrollments.map { |e| enrollment_hash(e) }
    end

    INCLUDE_CHECKERS.each do |key, val|
      define_method("include_#{key}".to_sym) do
        @includes.include?( val.to_sym )
      end
    end

    def include_total_scores?
      return @include_total_scores unless @include_total_scores.nil?
      @include_total_scores = @includes.include?(:total_scores) && !@course.hide_final_grades?
    end

    private

    def enrollment_hash(enrollment)
      enrollment_hash = default_enrollment_attributes(enrollment)
      enrollment_hash[:associated_user_id] = enrollment.associated_user_id if enrollment.assigned_observer?
      enrollment_hash.merge!(total_scores(enrollment)) if include_total_scores? && enrollment.student?
      enrollment_hash
    end

    def default_enrollment_attributes(enrollment)
      {
        :type => enrollment.sis_type,
        :role => enrollment.role.name,
        :role_id => enrollment.role.id,
        :user_id => enrollment.user_id,
        :enrollment_state => enrollment.workflow_state
      }
    end

    def total_scores(student_enrollment)
      scores = {
        :computed_current_score => student_enrollment.computed_current_score,
        :computed_final_score => student_enrollment.computed_final_score,
        :computed_current_grade => student_enrollment.computed_current_grade,
        :computed_final_grade => student_enrollment.computed_final_grade
      }
      if include_current_grading_period_scores?
        scores.merge!(current_grading_period_scores(student_enrollment))
      end
      scores
    end

    def current_grading_period_scores(student_enrollment)
      {
        has_grading_periods: @course.grading_periods?,
        multiple_grading_periods_enabled: @course.grading_periods?, # for backwards compatibility
        totals_for_all_grading_periods_option: @course.display_totals_for_all_grading_periods?,
        current_grading_period_title: current_grading_period&.title,
        current_grading_period_id: current_grading_period&.id,
        current_period_computed_current_score: grading_period_score(student_enrollment, :current),
        current_period_computed_final_score: grading_period_score(student_enrollment, :final),
        current_period_computed_current_grade: grading_period_grade(student_enrollment, :current),
        current_period_computed_final_grade: grading_period_grade(student_enrollment, :final)
      }
    end

    def grading_period_score(enrollment, current_or_final)
      grading_period_score_or_grade(enrollment, current_or_final, :score)
    end

    def grading_period_grade(enrollment, current_or_final)
      grading_period_score_or_grade(enrollment, current_or_final, :grade)
    end

    def grading_period_score_or_grade(enrollment, current_or_final, score_or_grade)
      return nil unless current_grading_period
      enrollment.send("computed_#{current_or_final}_#{score_or_grade}", grading_period_id: current_grading_period.id)
    end

    def current_grading_period
      return @current_grading_period if defined?(@current_grading_period)
      @current_grading_period = GradingPeriod.current_period_for(@course)
    end

    def include_current_grading_period_scores?
      return @include_current_grading_period_scores unless @include_current_grading_period_scores.nil?
      @include_current_grading_period_scores =
        include_total_scores? && @includes.include?(:current_grading_period_scores)
    end
  end
end
