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
      current_period_scores = grading_period_scores_hash(enrollments)
      enrollments.map { |e| enrollment_hash(e, current_period_scores) }
    end

    INCLUDE_CHECKERS.each do |key, val|
      define_method("include_#{key}".to_sym) do
        @includes.include?( val.to_sym )
      end
    end

    def include_total_scores?
      @includes.include?(:total_scores) && !@course.hide_final_grades?
    end

    private

    def enrollment_hash(enrollment, grading_period_scores)
      enrollment_hash = default_enrollment_attributes(enrollment)
      enrollment_hash[:associated_user_id] = enrollment.associated_user_id if enrollment.assigned_observer?

      if include_total_scores? && enrollment.student?
        enrollment_hash.merge!(total_scores(enrollment))
        enrollment_hash.merge!(grading_period_scores[enrollment.id]) if include_current_grading_period_scores?
      end
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
      {
        :computed_current_score => student_enrollment.computed_current_score,
        :computed_final_score => student_enrollment.computed_final_score,
        :computed_current_grade => student_enrollment.computed_current_grade,
        :computed_final_grade => student_enrollment.computed_final_grade
      }
    end

    def grading_period_scores(student_enrollments)
      current_period = @course.grading_periods? && GradingPeriod.current_period_for(@course)
      if current_period
        calculated_grading_period_scores(
          student_enrollments,
          current_period,
          @course.display_totals_for_all_grading_periods?
        )
      else
        nil_grading_period_scores(student_enrollments, false, false)
      end
    end

    def grading_period_scores_hash(enrollments)
      include_current_grading_period_scores? ? grading_period_scores(enrollments.select(&:student?)) : {}
    end

    def calculated_grading_period_scores(student_enrollments, current_period, totals_for_all_grading_periods_option)
      calculator = GradeCalculator.new(
        student_enrollments.map(&:user_id), @course, grading_period: current_period
      )
      current_period_scores = mgp_scores_from_calculator(calculator)
      scores = {}
      student_enrollments.each_with_index do |enrollment, index|
        scores[enrollment.id] = current_period_scores[index].merge({
          has_grading_periods: true,
          multiple_grading_periods_enabled: true, # for backwards compatibility
          totals_for_all_grading_periods_option: totals_for_all_grading_periods_option,
          current_grading_period_title: current_period.title,
          current_grading_period_id: current_period.id
        })
      end
      scores
    end


    def nil_grading_period_scores(student_enrollments, has_grading_periods, totals_for_all_grading_periods_option)
      scores = {}
      student_enrollments.each do |enrollment|
        scores[enrollment.id] = {
          has_grading_periods: has_grading_periods,
          multiple_grading_periods_enabled: has_grading_periods, # for backwards compatibility
          totals_for_all_grading_periods_option: totals_for_all_grading_periods_option,
          current_grading_period_title: nil,
          current_grading_period_id: nil,
          current_period_computed_current_score: nil,
          current_period_computed_final_score: nil,
          current_period_computed_current_grade: nil,
          current_period_computed_final_grade: nil
        }
      end
      scores
    end

    def mgp_scores_from_calculator(grade_calculator)
      grade_calculator.compute_scores.map do |scores|
        current_score = scores[:current][:grade]
        final_score = scores[:final][:grade]
        {
          current_period_computed_current_score: current_score,
          current_period_computed_final_score: final_score,
          current_period_computed_current_grade: @course.score_to_grade(current_score),
          current_period_computed_final_grade: @course.score_to_grade(final_score)
        }
      end
    end

    def include_current_grading_period_scores?
      include_total_scores? && @includes.include?(:current_grading_period_scores)
    end
  end
end
