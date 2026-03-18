# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

module Assignments
  module CourseProxyCache
    # holds values so we don't have to recompute them over and over again
    class CourseProxy
      attr_reader :course, :user

      def initialize(course, user)
        @course = course
        @user = user
      end

      def section_visibilities
        @section_visibilities ||= course.section_visibilities_for(user)
      end

      def visibility_level
        @visibility_level ||= course.enrollment_visibility_level_for(user, section_visibilities)
      end

      def visible_section_ids
        @visible_section_ids ||= section_visibilities.pluck(:course_section_id)
      end
    end

    private

    def course_proxy_for(assignment)
      @course_proxies ||= {}
      global_course_id = assignment.context.global_id
      @course_proxies[global_course_id] ||= CourseProxy.new(assignment.context, @user)
    end
  end

  class NeedsGradingCountQuery
    include CourseProxyCache

    def initialize(assignments, user = nil)
      @assignments = Array(assignments)
      @user = user
    end

    # Returns { assignment.global_id => Integer }, defaults to 0 for unknown keys
    def count
      fetch_or_compute(:count, default: 0) do |assignments|
        if optimized?
          NeedsGradingCountQueryOptimized.new(assignments, @user).count
        else
          map_results(assignments, &:count)
        end
      end
    end

    # Returns { assignment.global_id => Integer }, defaults to 0 for unknown keys
    def manual_count
      fetch_or_compute(:manual_count, default: 0) do |assignments|
        if optimized?
          NeedsGradingCountQueryOptimized.new(assignments, @user).manual_count
        else
          map_results(assignments, &:manual_count)
        end
      end
    end

    # Returns { assignment.global_id => Array<Hash> }, defaults to [] for unknown keys
    # Each hash is { section_id: <local Integer>, needs_grading_count: Integer }
    # (section_id is the local shard ID, not a global ID)
    def count_by_section
      fetch_or_compute(:count_by_section, default: []) do |assignments|
        if optimized?
          NeedsGradingCountQueryOptimized.new(assignments, @user).count_by_section
        else
          map_results(assignments, &:count_by_section)
        end
      end
    end

    private

    # Checks the request cache for each assignment, computes only for missing ones,
    # writes the new values back, and returns the complete hash keyed by global_id.
    # When the optimized implementation lands, only the block passed by the public
    # methods needs to change — this layer stays untouched.
    def fetch_or_compute(method_key, default: nil)
      missing = @assignments.reject { |a| RequestCache.exist?("ngcq_#{method_key}", a.global_id, @user&.global_id) }

      new_values = {}
      if missing.any?
        new_values = yield(missing)
        # Populate the request cache so subsequent single-assignment lookups
        # within the same request are free in-memory hash reads.
        new_values.each do |gid, val|
          RequestCache.cache("ngcq_#{method_key}", gid, @user&.global_id) { val }
        end
      end

      result = Hash.new(default)
      @assignments.each do |a|
        # Every assignment must be in either new_values (just computed) or the
        # request cache (warmed by a prior call). The 0 fallback is a safety
        # net that should never be reached in normal operation.
        result[a.global_id] = new_values.fetch(a.global_id) do
          RequestCache.cache("ngcq_#{method_key}", a.global_id, @user&.global_id) do
            default
          end
        end
      end
      result
    end

    def map_results(assignments)
      assignments.each_with_object({}) do |assignment, h|
        proxy = course_proxy_for(assignment)
        legacy = NeedsGradingCountQueryLegacy.new(assignment, @user, proxy)
        h[assignment.global_id] = yield legacy
      end
    end

    def optimized?
      return @optimized unless @optimized.nil?

      @optimized = Account.site_admin.feature_enabled?(:optimized_needs_grading_count)
    end
  end

  class NeedsGradingCountQueryLegacy
    attr_reader :assignment, :user, :course_proxy

    delegate :course, :section_visibilities, :visibility_level, :visible_section_ids, to: :course_proxy

    def initialize(assignment, user = nil, course_proxy = nil)
      @assignment = assignment
      @user = user
      @course_proxy = course_proxy || CourseProxyCache::CourseProxy.new(@assignment.context, @user)
    end

    def count
      assignment.shard.activate do
        # the needs_grading_count trigger should clear the assignment's needs_grading cache
        Rails.cache.fetch_with_batched_keys(["assignment_user_grading_count", assignment.cache_key(:needs_grading), user].cache_key,
                                            batch_object: user,
                                            batched_keys: :todo_list) do
          if assignment.moderated_grading? && !assignment.grades_published?
            needs_moderated_grading_count
          else
            case visibility_level
            when :full, :limited
              manual_count
            when :sections, :sections_limited
              count_submissions(section_filtered_submissions)
            else
              0
            end
          end
        end
      end
    end

    def needs_moderated_grading_count
      level = visibility_level
      return 0 unless %i[full limited sections sections_limited].include?(level)

      # ignore submissions this user has graded
      graded_sub_ids = assignment.submissions.joins(:provisional_grades)
                                 .where(moderated_grading_provisional_grades: { final: false, scorer_id: user.id })
                                 .where.not(moderated_grading_provisional_grades: { score: nil }).pluck(:id)

      moderation_set_student_ids = assignment.moderated_grading_selections.pluck(:student_id)

      # ignore submissions that don't need any more provisional grades
      pg_scope = assignment.submissions.joins(:provisional_grades)
                           .where(moderated_grading_provisional_grades: { final: false })
                           .where.not(moderated_grading_provisional_grades: { scorer_id: user.id })
                           .group("submissions.id", "submissions.user_id")
      pg_scope = pg_scope.where.not(submissions: { id: graded_sub_ids }) if graded_sub_ids.any?
      pg_scope.count.each do |key, count|
        sub_id, user_id = key
        graded_sub_ids << sub_id if count >= (moderation_set_student_ids.include?(user_id) ? 2 : 1)
      end

      scope = (level == :sections) ? section_filtered_submissions : all_submissions
      scope = scope.where.not(submissions: { id: graded_sub_ids }) if graded_sub_ids.any?
      count_submissions(scope)
    end

    # Returns Array<Hash> — { section_id: <local Integer>, needs_grading_count: Integer }
    # (section_id is the local shard ID, not a global ID)
    def count_by_section
      assignment.shard.activate do
        Rails.cache.fetch(["assignment_user_grading_count_by_section", assignment.cache_key(:needs_grading), user].cache_key,
                          batch_object: user,
                          batched_keys: :todo_list) do
          submissions = if visibility_level == :sections
                          section_filtered_submissions
                        else
                          all_submissions
                        end

          submissions
            .group("e.course_section_id")
            .distinct
            .count("submissions.user_id")
            .map { |k, v| { section_id: k.to_i, needs_grading_count: v } }
        end
      end
    end

    def manual_count
      assignment.shard.activate do
        count_submissions(all_submissions)
      end
    end

    private

    def count_submissions(scope)
      scope.distinct.count(:user_id)
    end

    def all_submissions
      if assignment.has_sub_assignments
        sub_assignment_submissions
      else
        all_outer_submissions
      end
    end

    def section_filtered_submissions
      all_submissions.where(e: { course_section_id: visible_section_ids })
    end

    def all_outer_submissions
      string = <<~SQL.squish
        submissions.assignment_id = ?
          AND e.course_id = ?
          AND e.type IN ('StudentEnrollment', 'StudentViewEnrollment')
          AND e.workflow_state = 'active'
          AND #{Submission.needs_grading_conditions}
      SQL
      joined_submissions.where(string, assignment, course)
    end

    def sub_assignment_submissions
      # a better solution would be to fix the logic in submission_aggregator_service.rb
      # to apply a proper workflow_state to the parent submission based on the states of the child submissions
      # but this is a quick fix to make the needs_grading_count work correctly for sub-assignments

      sub_assignment_ids = assignment.sub_assignments.pluck(:id)
      return Submission.none if sub_assignment_ids.empty?

      string = <<~SQL.squish
        submissions.assignment_id IN (?)
          AND e.course_id = ?
          AND e.type IN ('StudentEnrollment', 'StudentViewEnrollment')
          AND e.workflow_state = 'active'
          AND #{Submission.needs_grading_conditions}
      SQL
      Submission.joins("INNER JOIN #{Enrollment.quoted_table_name} e ON e.user_id = submissions.user_id")
                .where(string, sub_assignment_ids, course)
    end

    def joined_submissions
      assignment.submissions.joins("INNER JOIN #{Enrollment.quoted_table_name} e ON e.user_id = submissions.user_id")
    end
  end

  class NeedsGradingCountQueryOptimized
    include CourseProxyCache

    def initialize(assignments, user = nil)
      @assignments = assignments
      @user = user
    end

    # Returns { assignment.global_id => Integer }
    def count
      results = @assignments.to_h { |a| [a.global_id, 0] }

      Shard.partition_by_shard(@assignments) do |shard_assignments|
        moderated, non_moderated = shard_assignments.partition do |a|
          a.moderated_grading? && !a.grades_published?
        end

        results.merge!(needs_moderated_grading_count(moderated)) if moderated.any?
        results.merge!(needs_grading_count(non_moderated)) if non_moderated.any?
      end

      results
    end

    # Returns { assignment.global_id => Integer }
    def manual_count
      results = @assignments.to_h { |a| [a.global_id, 0] }

      partition_by_course(@assignments) do |course_id, course_assignments|
        results.merge!(count_by_assignment(all_submissions_scope(course_assignments, course_id)))
      end

      results
    end

    # Returns { assignment.global_id => Array<Hash> }
    # Each hash is { section_id: <local Integer>, needs_grading_count: Integer }
    # (section_id is the local shard ID, not a global ID)
    def count_by_section
      results = @assignments.to_h { |a| [a.global_id, []] }

      partition_by_course(@assignments) do |course_id, course_assignments|
        proxy = course_proxy_for(course_assignments.first)

        scope = all_submissions_scope(course_assignments, course_id)
        scope = scope.where(e: { course_section_id: proxy.visible_section_ids }) if proxy.visibility_level == :sections

        scope
          .group("assignment_mapping.to_id", "e.course_section_id")
          .distinct
          .count("submissions.user_id")
          .each do |(assignment_id, section_id), cnt|
            results[assignment_id.to_i] << { section_id: section_id.to_i, needs_grading_count: cnt }
          end
      end

      results
    end

    private

    def needs_moderated_grading_count(assignments)
      results = assignments.to_h { |a| [a.global_id, 0] }
      assignment_ids = assignments.map(&:id)

      # Step 1: submission IDs this user has already provisionally graded (bulk)
      # Default proc stores a new Set on first access, so missing assignment IDs
      # are handled automatically without a separate initialisation loop.
      graded_sub_ids_by_assignment = Hash.new { |h, k| h[k] = Set.new }
      Submission
        .joins(:provisional_grades)
        .where(
          assignment_id: assignment_ids,
          moderated_grading_provisional_grades: { final: false, scorer_id: @user.id }
        )
        .where.not(moderated_grading_provisional_grades: { score: nil })
        .group(:assignment_id)
        .pluck(:assignment_id, Arel.sql("ARRAY_AGG(DISTINCT submissions.id)"))
        .each { |a_id, ids| graded_sub_ids_by_assignment[a_id] = ids.to_set }

      # Step 2: moderation sets per assignment (bulk)
      moderation_sets = ModeratedGrading::Selection
                        .where(assignment_id: assignment_ids)
                        .group(:assignment_id)
                        .pluck(:assignment_id, Arel.sql("ARRAY_AGG(student_id)"))
                        .to_h { |a_id, ids| [a_id, ids.to_set] }

      # Step 3: find submissions that already have enough provisional grades (bulk).
      # The threshold is 2 if the student is in the assignment's moderation set, 1 otherwise.
      Submission
        .joins(:provisional_grades)
        .where(assignment_id: assignment_ids)
        .where(moderated_grading_provisional_grades: { final: false })
        .where.not(moderated_grading_provisional_grades: { scorer_id: @user.id })
        .group("submissions.assignment_id", "submissions.id", "submissions.user_id")
        .count
        .each do |(a_id, sub_id, user_id), pg_count|
          next if graded_sub_ids_by_assignment[a_id].include?(sub_id)

          threshold = moderation_sets[a_id].include?(user_id) ? 2 : 1
          graded_sub_ids_by_assignment[a_id] << sub_id if pg_count >= threshold
        end

      # Step 4: count remaining submissions per assignment grouped by course for visibility.
      # Submission IDs are globally unique so flattening exclusions across assignments is safe.
      assignments.group_by(&:context_id).each do |course_id, course_assignments|
        proxy = course_proxy_for(course_assignments.first)
        level = proxy.visibility_level

        # leaves results at the 0 default
        next unless %i[full limited sections sections_limited].include?(level)

        all_graded_sub_ids = course_assignments.each_with_object(Set.new) { |a, s| s.merge(graded_sub_ids_by_assignment[a.id]) }

        scope = all_submissions_scope(course_assignments, course_id)
        scope = scope.where(e: { course_section_id: proxy.visible_section_ids }) if level == :sections
        scope = scope.where.not(submissions: { id: all_graded_sub_ids }) if all_graded_sub_ids.any?

        results.merge!(count_by_assignment(scope))
      end

      results
    end

    def partition_by_course(assignments, &)
      Shard.partition_by_shard(assignments) do |shard_assignments|
        shard_assignments.group_by(&:context_id).each(&)
      end
    end

    def count_by_assignment(scope)
      scope
        .group("assignment_mapping.to_id")
        .distinct
        .count("submissions.user_id")
        .transform_keys(&:to_i)
    end

    def needs_grading_count(assignments)
      results = assignments.to_h { |a| [a.global_id, 0] }

      assignments.group_by(&:context_id).each do |course_id, course_assignments|
        proxy = course_proxy_for(course_assignments.first)
        level = proxy.visibility_level
        next unless %i[full limited sections sections_limited].include?(level)

        scope = all_submissions_scope(course_assignments, course_id)
        scope = scope.where(e: { course_section_id: proxy.visible_section_ids }) if %i[sections sections_limited].include?(level)

        results.merge!(count_by_assignment(scope))
      end

      results
    end

    # Builds a scope with an INNER JOIN to a VALUES mapping table
    # (assignment_mapping.from_id, assignment_mapping.to_id) so that
    # count_by_assignment can group by assignment_mapping.to_id.
    #
    # Each assignment produces one or more mapping rows:
    #   - Standard / direct query (including SubAssignment queried directly):
    #       (assignment.id → assignment.id)
    #   - Parent with sub-assignments (roll-up):
    #       (sub_assignment.id → parent.id)
    #
    # A single sub-assignment that is both directly queried AND a child of a
    # queried parent gets both rows, so its submissions are counted under both
    # the sub-assignment's own ID and the parent's ID.
    def all_submissions_scope(course_assignments, course_id)
      sub_assignment_parents, standard = course_assignments.partition(&:has_sub_assignments)

      mapping_rows = standard.map { |a| [a.id, a.global_id] }

      if sub_assignment_parents.any?
        parent_global_id = sub_assignment_parents.to_h { |a| [a.id, a.global_id] }
        SubAssignment
          .where(parent_assignment_id: sub_assignment_parents.map(&:id))
          .pluck(:parent_assignment_id, :id)
          .each { |parent_id, sub_id| mapping_rows << [sub_id, parent_global_id[parent_id]] }
      end

      return Submission.none if mapping_rows.empty?

      all_ids = mapping_rows.map(&:first).uniq
      values_sql = mapping_rows.map { |from_id, to_id| "(#{from_id.to_i}, #{to_id.to_i})" }.join(", ")

      submissions_scope(all_ids, course_id)
        .joins("INNER JOIN (VALUES #{values_sql}) AS assignment_mapping(from_id, to_id) " \
               "ON assignment_mapping.from_id = submissions.assignment_id")
    end

    # Base submission scope filtered to the given assignment_ids and course.
    def submissions_scope(assignment_ids, course_id)
      Submission
        .joins("INNER JOIN #{Enrollment.quoted_table_name} e ON e.user_id = submissions.user_id")
        .where(
          "submissions.assignment_id IN (?) " \
          "AND e.course_id = ? " \
          "AND e.type IN ('StudentEnrollment', 'StudentViewEnrollment') " \
          "AND e.workflow_state = 'active' " \
          "AND #{Submission.needs_grading_conditions}",
          assignment_ids,
          course_id
        )
    end
  end
end
