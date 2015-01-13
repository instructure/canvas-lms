module Api::V1
  class CourseJson

    BASE_ATTRIBUTES = %w(id name course_code account_id start_at default_view enrollment_term_id is_public)

    INCLUDE_CHECKERS = { :grading => 'needs_grading_count', :syllabus => 'syllabus_body',
                         :url => 'html_url', :description => 'public_description', :permissions => "permissions" }

    OPTIONAL_FIELDS = %w(needs_grading_count public_description enrollments)

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
      methods = ['end_at', 'public_syllabus', 'storage_quota_mb']
      methods << 'hide_final_grades' if @includes.include?(:hide_final_grades)
      methods << 'storage_quota_used_mb' if @includes.include?(:storage_quota_used_mb)
      methods
    end

    def to_hash
      set_sis_course_id(@hash, @course, @user)
      set_integration_id(@hash, @course, @user)
      @hash['enrollments'] = extract_enrollments( @enrollments )
      @hash['needs_grading_count'] = needs_grading_count(@enrollments, @course)
      @hash['public_description'] = description(@course)
      @hash['hide_final_grades'] = @course.hide_final_grades?
      @hash['workflow_state'] = @course.api_state
      @hash['course_format'] = @course.course_format if @course.course_format.present?
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
      if course.root_account.grants_any_right?(user, :read_sis, :manage_sis)
        hash['sis_course_id'] = course.sis_source_id
      end
    end

    def set_integration_id(hash, course, user)
      if course.root_account.grants_any_right?(user, :read_sis, :manage_sis)
        hash['integration_id'] = course.integration_id
      end
    end

    def needs_grading_count(enrollments, course)
      if include_grading && enrollments && enrollments.any? { |e| e.participating_instructor? }
        course.assignments.active.to_a.sum{|a| Assignments::NeedsGradingCountQuery.new(a, user).count }
      end
    end

    def permissions_to_include
      [ :create_discussion_topic ] if include_permissions
    end

    def extract_enrollments( enrollments )
      if enrollments
        enrollments.map do |e|
          h = {
            :type => e.sis_type,
            :role => e.role.name,
            :role_id => e.role.id,
            :enrollment_state => e.workflow_state
          }
          if include_total_scores && e.student?
            h.merge!(
              :computed_current_score => e.computed_current_score,
              :computed_final_score => e.computed_final_score,
              :computed_current_grade => e.computed_current_grade,
              :computed_final_grade => e.computed_final_grade)
          end
          h
        end
      end
    end

    INCLUDE_CHECKERS.each do |key, val|
      define_method("include_#{key}".to_sym) do
        @includes.include?( val.to_sym )
      end
    end

    def include_total_scores
      @includes.include?(:total_scores) && !@course.hide_final_grades?
    end
  end
end
