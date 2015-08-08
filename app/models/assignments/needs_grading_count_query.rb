module Assignments
  class NeedsGradingCountQuery

    # holds values so we don't have to recompute them over and over again
    class CourseProxy
      attr_reader :course, :user

      def initialize(_course, _user)
        @course = _course
        @user = _user
      end

      def da_enabled?
        @da_enabled ||= course.feature_enabled?(:differentiated_assignments)
      end

      def section_visibilities
        @section_visibilities ||= course.section_visibilities_for(user)
      end

      def visibility_level
        @visibility_level ||= course.enrollment_visibility_level_for(user, section_visibilities)
      end

      def visible_section_ids
        @visible_section_ids ||= section_visibilities.map{|v| v[:course_section_id]}
      end
    end

    attr_reader :assignment, :user, :course_proxy

    delegate :course, :da_enabled?, :section_visibilities, :visibility_level, :visible_section_ids, :to => :course_proxy

    def initialize(_assignment, _user, _course_proxy=nil)
      @assignment = _assignment
      @user = _user
      @course_proxy = _course_proxy || CourseProxy.new(@assignment.context, @user)
    end

    def count
      assignment.shard.activate do
        # the needs_grading_count trigger should change assignment.updated_at, invalidating the cache
        Rails.cache.fetch(['assignment_user_grading_count', assignment, user].cache_key) do
          case visibility_level
          when :full, :limited
            da_enabled? ? manual_count : assignment.needs_grading_count
          when :sections
            section_filtered_submissions.count(:id, distinct: true)
          else
            0
          end
        end
      end
    end

    def count_by_section
      assignment.shard.activate do
        Rails.cache.fetch(['assignment_user_grading_count_by_section', assignment, user].cache_key) do
          if visibility_level == :sections
            submissions = section_filtered_submissions
          else
            submissions = all_submissions
          end

          submissions.
            group("e.course_section_id").
            count.
            map{|k,v| {section_id: k.to_i, needs_grading_count: v}}
        end
      end
    end

    def manual_count
      assignment.shard.activate do
        Rails.cache.fetch(['assignment_user_grading_manual_count', assignment, user].cache_key) do
          all_submissions.count(:id, distinct: true)
        end
      end
    end

    private
    def section_filtered_submissions
      all_submissions.where('e.course_section_id in (?)', visible_section_ids)
    end

    def all_submissions
      string = <<-SQL
        submissions.assignment_id = ?
          AND e.course_id = ?
          AND e.type IN ('StudentEnrollment', 'StudentViewEnrollment')
          AND e.workflow_state = 'active'
          AND submissions.submission_type IS NOT NULL
          AND (submissions.workflow_state = 'pending_review'
            OR (submissions.workflow_state = 'submitted'
              AND (submissions.score IS NULL OR NOT submissions.grade_matches_current_submission)))
        SQL

      if da_enabled?
        string += <<-SQL
          AND EXISTS (SELECT * FROM #{AssignmentStudentVisibility.quoted_table_name} asv WHERE asv.user_id = submissions.user_id AND asv.assignment_id = submissions.assignment_id)
        SQL
      end
      joined_submissions.where(string, assignment, course)
    end

    def joined_submissions
      assignment.submissions.joins("INNER JOIN #{Enrollment.quoted_table_name} e ON e.user_id = submissions.user_id")
    end
  end
end
