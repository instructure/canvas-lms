# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

module ConditionalRelease
  class ServiceError < StandardError; end

  class Service
    private_class_method :new

    def self.env_for(context, user = nil, session: nil, assignment: nil, includes: [])
      enabled = enabled_in_context?(context)
      env = {
        CONDITIONAL_RELEASE_SERVICE_ENABLED: enabled
      }
      return env unless enabled && user

      cyoe_env = {}
      assignment_unlocked = !assignment&.locked_for?(user, check_policies: true, deep_check_if_needed: true)
      cyoe_env[:assignment] = assignment_attributes(assignment) if assignment && assignment_unlocked
      if context.is_a?(Course)
        cyoe_env[:course_id] = context.id
        cyoe_env[:stats_url] = "/api/v1/courses/#{context.id}/mastery_paths/stats"
      end

      includes = Array.wrap(includes)
      cyoe_env[:rule] = rule_triggered_by(assignment, user, session) if includes.include? :rule
      cyoe_env[:active_rules] = active_rules(context, user, session) if includes.include? :active_rules

      env.merge(CONDITIONAL_RELEASE_ENV: cyoe_env)
    end

    def self.rules_for(context, student, session)
      return unless enabled_in_context?(context)

      rules_data(context, student, session)
    end

    def self.enabled_in_context?(context)
      context.is_a?(Course) && context.conditional_release?
    end

    def self.triggers_mastery_paths?(assignment, current_user, session = nil)
      rule_triggered_by(assignment, current_user, session).present?
    end

    def self.rule_triggered_by(assignment, current_user, session = nil)
      return unless assignment.present?
      return unless enabled_in_context?(assignment.context)

      rules = active_rules(assignment.context, current_user, session)
      return nil unless rules

      rules.find { |r| r["trigger_assignment"] == assignment.id.to_s || r["trigger_assignment_id"] == assignment.id }
    end

    def self.active_rules(course, current_user, session)
      return unless enabled_in_context?(course)
      return unless course.grants_any_right?(current_user, session, :read, *RoleOverride::GRANULAR_MANAGE_ASSIGNMENT_PERMISSIONS)

      rules_data = Rails.cache.fetch_with_batched_keys("conditional_release_active_rules", batch_object: course, batched_keys: :conditional_release) do
        rules = course.conditional_release_rules.active.with_assignments.to_a
        rules.as_json(include: Rule.includes_for_json, include_root: false, except: [:root_account_id, :deleted_at])
      end
      trigger_ids = rules_data.pluck("trigger_assignment_id")
      trigger_assgs = course.assignments.preload(:grading_standard).where(id: trigger_ids).each_with_object({}) do |a, assgs|
        assgs[a.id] = {
          points_possible: a.points_possible,
          grading_type: a.grading_type,
          grading_scheme: a.uses_grading_standard ? a.grading_scheme : nil,
        }
      end
      rules_data.each do |rule|
        rule["trigger_assignment_model"] = trigger_assgs[rule["trigger_assignment_id"]]
      end
      rules_data
    end

    def self.release_mastery_paths_content_in_course(course)
      overrides_scope = AssignmentOverride.where(set_type: AssignmentOverride::SET_TYPE_NOOP, set_id: AssignmentOverride::NOOP_MASTERY_PATHS).active
      assignment_ids = overrides_scope.where.not(assignment_id: nil).pluck(:assignment_id)
      assignment_ids.sort.each_slice(100) do |sliced_ids|
        course.assignments.active.where(id: sliced_ids).where(only_visible_to_overrides: true).where.not(submission_types: "wiki_page").to_a.each do |assignment|
          assignment.update_attribute(:only_visible_to_overrides, false)
        end
      end
      wp_assignment_ids = course.wiki_pages.not_deleted.where.not(assignment_id: nil).pluck(:assignment_id)
      wp_assignment_ids.sort.each_slice(100) do |sliced_ids|
        course.assignments.active.where(id: sliced_ids).where(only_visible_to_overrides: true, submission_types: "wiki_page").each do |wp_assignment|
          wp_assignment.update_attribute(:only_visible_to_overrides, false)
        end
      end
      quiz_ids = overrides_scope.where(assignment_id: nil).where.not(quiz_id: nil).pluck(:quiz_id)
      quiz_ids.sort.each_slice(100) do |sliced_ids|
        course.quizzes.active.where(id: sliced_ids).where(only_visible_to_overrides: true).to_a.each do |quiz|
          quiz.update_attribute(:only_visible_to_overrides, false)
        end
      end
    end

    class << self
      private

      def assignment_attributes(assignment)
        return nil unless assignment.present?

        {
          id: assignment.id,
          title: assignment.title,
          description: assignment.description,
          points_possible: assignment.points_possible,
          grading_type: assignment.grading_type,
          submission_types: assignment.submission_types,
          grading_scheme: assignment.grading_scheme
        }
      end

      def rules_data(course, student, _session = nil)
        return [] if course.blank? || student.blank?

        rules_data =
          ::Rails.cache.fetch(["conditional_release_rules_for_student2", student.cache_key(:submissions), course.cache_key(:conditional_release)].cache_key) do
            rules = course.conditional_release_rules.active.preload(Rule.preload_associations).to_a

            # ignore functionally empty rules
            rules.reject! { |r| r.scoring_ranges.all? { |sr| sr.assignment_sets.all? { |s| s.assignment_set_associations.empty? } } }

            trigger_assignments = course.assignments.where(id: rules.map(&:trigger_assignment_id)).to_a.index_by(&:id)
            trigger_submissions = course.submissions.where(assignment_id: trigger_assignments.keys)
                                        .for_user(student).in_workflow_state(:graded).posted.to_a.index_by(&:assignment_id)

            assigned_set_ids = ConditionalRelease::AssignmentSetAction.current_assignments(
              student, rules.flat_map(&:scoring_ranges).flat_map(&:assignment_sets)
            ).pluck(:assignment_set_id)
            rules.map do |rule|
              trigger_assignment = trigger_assignments[rule.trigger_assignment_id]
              trigger_sub = trigger_submissions[trigger_assignment.id]
              if trigger_sub&.score
                relative_score = ConditionalRelease::Stats.percent_from_points(trigger_sub.score, trigger_assignment.points_possible)
                assignment_sets = rule.scoring_ranges.select { |sr| sr.contains_score(relative_score) }.flat_map(&:assignment_sets)
                selected_set_id =
                  if assignment_sets.length == 1
                    assignment_sets.first.id
                  else
                    (assignment_sets.map(&:id) & assigned_set_ids).first
                  end
              end
              assignment_sets_data = (assignment_sets || []).as_json(
                include_root: false,
                except: [:root_account_id, :deleted_at],
                include: { assignment_set_associations: { except: [:root_account_id, :deleted_at] } }
              ).map(&:deep_symbolize_keys)
              rule.as_json(include_root: false, except: [:root_account_id, :deleted_at]).merge(
                locked: relative_score.blank?,
                selected_set_id:,
                assignment_sets: assignment_sets_data
              )
            end
          end
        # TODO: do something less weird than mixing AR records into json
        # to get the assignment data in when we're not maintaining back compat
        referenced_assignment_ids = rules_data.map do |rule_hash|
          rule_hash[:assignment_sets].map do |set_hash|
            set_hash[:assignment_set_associations].pluck(:assignment_id)
          end
        end.flatten
        referenced_assignments = course.assignments.where(id: referenced_assignment_ids).to_a.index_by(&:id)
        rules_data.each do |rule_hash|
          rule_hash[:assignment_sets].each do |set_hash|
            set_hash[:assignment_set_associations].each do |assoc_hash|
              assoc_hash[:model] = referenced_assignments[assoc_hash[:assignment_id]]
            end
          end
        end
        rules_data
      end

      def assignments_for(response)
        rules = response.map(&:deep_symbolize_keys)

        # Fetch all the nested assignment_ids for the associated
        # CYOE content from the Rules provided
        ids = rules.flat_map do |rule|
          rule[:assignment_sets].flat_map do |a|
            a[:assignments].flat_map do |asg|
              asg[:assignment_id]
            end
          end
        end

        # Get all the related Assignment models in Canvas
        Assignment.active.where(id: ids)
      end

      def merge_assignment_data(response, assignments = nil)
        return response if response.blank? || (response.is_a?(Hash) && response.key?(:error))

        assignments = assignments_for(response) if assignments.blank?

        # Merge the Assignment models into the response for the given module item
        rules = response.map(&:deep_symbolize_keys)
        rules.map! do |rule|
          rule[:assignment_sets].map! do |set|
            set[:assignments].map! do |asg|
              assignment = assignments.find { |a| a[:id].to_s == asg[:assignment_id].to_s }
              asg[:model] = assignment
              asg if asg[:model].present?
            end.compact!
            set if set[:assignments].present?
          end.compact!
          rule
        end.compact!
        rules.compact
      end

      def assignment_keys
        %i[id
           title
           name
           description
           due_at
           unlock_at
           lock_at
           points_possible
           min_score
           max_score
           grading_type
           submission_types
           workflow_state
           context_id
           context_type
           updated_at
           context_code]
      end
    end
  end
end
