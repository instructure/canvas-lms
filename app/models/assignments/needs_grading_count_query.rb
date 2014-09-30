module Assignments
  class NeedsGradingCountQuery
    attr_reader :assignment, :user

    def initialize(_assignment, _user)
      @assignment = _assignment
      @user = _user
    end

    def count
      assignment.shard.activate do
        # the needs_grading_count trigger should change assignment.updated_at, invalidating the cache
        Rails.cache.fetch(['assignment_user_grading_count', assignment, user].cache_key) do
          case visibility_level
          when :full, :limited
            assignment.needs_grading_count
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

    private
    def section_filtered_submissions
      all_submissions.where('e.course_section_id in (?)', visible_section_ids)
    end

    def all_submissions
      joined_submissions.where(<<-SQL, assignment, course)
        submissions.assignment_id = ?
          AND e.course_id = ?
          AND e.type IN ('StudentEnrollment', 'StudentViewEnrollment')
          AND e.workflow_state = 'active'
          AND submissions.submission_type IS NOT NULL
          AND (submissions.workflow_state = 'pending_review'
            OR (submissions.workflow_state = 'submitted'
              AND (submissions.score IS NULL OR NOT submissions.grade_matches_current_submission)))
        SQL
    end

    def joined_submissions
      assignment.submissions.joins("INNER JOIN enrollments e ON e.user_id = submissions.user_id")
    end

    def visible_section_ids
      section_visibilities.map{|v| v[:course_section_id]}
    end

    def visibility_level
      course.enrollment_visibility_level_for(user, section_visibilities)
    end

    def section_visibilities
      course.section_visibilities_for(user)
    end

    def course
      assignment.context
    end
  end
end
