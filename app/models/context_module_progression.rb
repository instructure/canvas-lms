# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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
#
class ContextModuleProgression < ActiveRecord::Base
  include Workflow

  belongs_to :context_module
  belongs_to :user
  belongs_to :root_account, class_name: "Account"

  before_save :set_completed_at
  before_create :set_root_account_id

  after_save :touch_user

  serialize :requirements_met, type: Array
  serialize :incomplete_requirements, type: Array

  validates :user_id, :context_module_id, presence: true

  def completion_requirements
    context_module.try(:completion_requirements) || []
  end
  private :completion_requirements

  def set_completed_at
    if completed?
      self.completed_at ||= Time.now
    else
      self.completed_at = nil
    end
  end

  def set_root_account_id
    self.root_account_id = context_module.root_account_id
  end

  def finished_item?(item)
    (requirements_met || []).any? { |r| r[:id] == item.id }
  end

  def collapse!(skip_save: false)
    update_collapse_state(true, skip_save:)
  end

  def uncollapse!(skip_save: false)
    update_collapse_state(false, skip_save:)
  end

  def update_collapse_state(collapsed_target_state, skip_save: false)
    retry_count = 0
    begin
      return if collapsed == collapsed_target_state

      self.collapsed = collapsed_target_state
      save unless skip_save
    rescue ActiveRecord::StaleObjectError => e
      Canvas::Errors.capture_exception(:context_modules, e, :info)
      retry_count += 1
      if retry_count < 5
        reload
        retry
      else
        raise
      end
    end
  end
  private :update_collapse_state

  def uncomplete_requirement(id)
    requirement = requirements_met.find { |r| r[:id] == id }
    requirements_met.delete(requirement)
    remove_incomplete_requirement(id)

    mark_as_outdated
  end

  class CompletedRequirementCalculator
    attr_accessor :actions_done, :view_requirements, :met_requirement_count

    def all_met?
      !@any_unmet
    end

    def changed?
      @orig_keys != sorted_action_keys
    end

    def initialize(actions_done)
      self.actions_done = actions_done
      self.met_requirement_count = 0

      @orig_keys = sorted_action_keys

      self.view_requirements = []
      self.actions_done.reject! { |r| r[:type] == "min_score" }
    end

    def sorted_action_keys
      actions_done.map { |r| "#{r[:id]}_#{r[:type]}" }.sort
    end

    def increment_met_requirement_count!
      self.met_requirement_count += 1
    end

    def requirement_met?(req, include_type = true)
      actions_done.any? { |r| r[:id] == req[:id] && (include_type ? r[:type] == req[:type] : true) }
    end

    def check_action!(action, is_met)
      if is_met
        add_done_action!(action)
      else
        @any_unmet = true
      end
    end

    def add_done_action!(action)
      increment_met_requirement_count!
      actions_done << action
    end

    def add_view_requirement(req)
      view_requirements << req
    end

    def check_view_requirements
      view_requirements.each do |req|
        # should mark a must_view as true if a completed must_submit/min_score action already exists
        check_action!(req, requirement_met?(req, false))
      end
    end
  end

  def evaluate_requirements_met
    result = evaluate_uncompleted_requirements

    count_needed = context_module.requirement_count.to_i
    # if no requirement_count is specified, assume all are needed
    self.workflow_state = if (count_needed && count_needed > 0 && result.met_requirement_count >= count_needed) || result.all_met?
                            "completed"
                          elsif result.met_requirement_count >= 1 || incomplete_requirements.count >= 1 # submitting to a min_score requirement should move it to started
                            "started"
                          else
                            "unlocked"
                          end

    if result.changed?
      self.requirements_met = result.actions_done
    end
  end
  private :evaluate_requirements_met

  def evaluate_uncompleted_requirements
    tags_hash = nil
    calc = CompletedRequirementCalculator.new(requirements_met || [])
    self.incomplete_requirements = [] # start from a clean slate
    completion_requirements.each do |req|
      # for an observer/student user we don't want to filter based on the normal observer logic,
      # instead return vis for student enrollment only -> hence ignore_observer_logic below

      # create the hash inside the loop in case the completion_requirements is empty (performance)
      tags_hash ||= context_module.content_tags_visible_to(user, is_teacher: false, ignore_observer_logic: true).index_by(&:id)

      tag = tags_hash[req[:id]]
      next unless tag

      if calc.requirement_met?(req)
        calc.increment_met_requirement_count!
        next
      end

      subs = get_submissions(tag) if tag.scoreable?
      if subs&.any? { |sub| sub.respond_to?(:excused?) && sub.excused? }
        calc.check_action!(req, true)
        next
      end

      if req[:type] == "must_view"
        calc.add_view_requirement(req)
      elsif %w[must_contribute must_mark_done].include? req[:type]
        # must_contribute is handled by ContextModule#update_for
        calc.check_action!(req, false)
      elsif req[:type] == "must_submit"
        req_met = !!(subs && subs.any? do |sub|
          if sub.workflow_state == "graded" && sub.attempt.nil?
            # is a manual grade - doesn't count for submission
            false
          elsif %w[submitted graded complete pending_review].include?(sub.workflow_state)
            true
          end
        end)

        calc.check_action!(req, req_met)
      elsif req[:type] == "min_score"
        calc.check_action!(req, evaluate_score_requirement_met(req, subs))
      end
    end
    calc.check_view_requirements
    calc
  end
  private :evaluate_uncompleted_requirements

  def get_submissions(tag)
    subs = []
    if tag.content_type_quiz?
      subs = Quizzes::QuizSubmission.where(quiz_id: tag.content_id, user_id: user).to_a +
             Submission.active.where(assignment_id: tag.content.assignment_id, user_id: user).to_a
    elsif tag.content_type_discussion?
      if tag.content
        subs = Submission.active.where(assignment_id: tag.content.assignment_id, user_id: user).to_a
      end
    else
      subs = Submission.active.where(assignment_id: tag.content_id, user_id: user).to_a
    end
    subs
  end
  private :get_submissions

  def get_submission_score(submission)
    if submission.is_a?(Quizzes::QuizSubmission)
      submission.try(:kept_score)
    else
      submission.try(:score)
    end
  end
  private :get_submission_score

  def remove_incomplete_requirement(requirement_id)
    incomplete_requirements.delete_if { |r| r[:id] == requirement_id }
  end

  # hold onto the status of the incomplete min_score requirement
  def update_incomplete_requirement!(requirement, score)
    return unless requirement[:type] == "min_score"

    incomplete_req = incomplete_requirements.detect { |r| r[:id] == requirement[:id] }
    unless incomplete_req
      incomplete_req = requirement.dup
      incomplete_requirements << incomplete_req
    end
    if incomplete_req[:score].nil?
      incomplete_req[:score] = score
    elsif score
      incomplete_req[:score] = score if score > incomplete_req[:score] # keep highest score so far
    end
  end

  def evaluate_score_requirement_met(requirement, subs)
    return unless requirement[:type] == "min_score"

    remove_incomplete_requirement(requirement[:id]) # start from a fresh slate so we don't hold onto a max score that doesn't exist anymore
    return if subs.blank?

    if (unposted_sub = subs.detect { |sub| sub.is_a?(Submission) && !sub.posted? })
      # don't mark the progress as in-progress if they haven't submitted
      update_incomplete_requirement!(requirement, nil) unless unposted_sub.unsubmitted?
      return
    end

    subs.any? do |sub|
      score = get_submission_score(sub)

      new_score = near_enough?(score, score.round) ? score.round : score if score.present?
      requirement_met = score.present? && new_score.to_f >= requirement[:min_score].to_f
      if requirement_met
        remove_incomplete_requirement(requirement[:id])
      else
        unless sub.is_a?(Submission) && sub.unsubmitted?
          update_incomplete_requirement!(requirement, score) # hold onto the score if requirement not met
        end
      end
      requirement_met
    end
  end
  private :evaluate_score_requirement_met

  def update_requirement_met(action, tag, points = nil)
    requirement = context_module.completion_requirement_for(action, tag)
    return nil unless requirement

    requirement_met = true
    requirement_met = points && points >= requirement[:min_score].to_f && !(tag.assignment && tag.assignment.muted?) if requirement[:type] == "min_score"
    requirement_met = false if requirement[:type] == "must_submit" # calculate later; requires the submission

    if !requirement_met
      requirements_met.delete(requirement)
      mark_as_outdated
      true
    elsif !requirements_met.include?(requirement)
      requirements_met.push(requirement)
      mark_as_outdated
      true
    else
      false
    end
  end

  def update_requirement_met!(*args)
    retry_count = 0
    begin
      if update_requirement_met(*args)
        save!
        delay_if_production.evaluate!
      end
    rescue ActiveRecord::StaleObjectError
      # retry up to five times, otherwise return current (stale) data
      reload
      retry_count += 1
      if retry_count < 5
        retry
      else
        raise
      end
    end
  end

  def mark_as_outdated
    self.current = false
  end

  def mark_as_outdated!
    if new_record?
      mark_as_outdated
      GuardRail.activate(:primary) do
        save!
      end
    else
      self.class.where(id: self).update_all(current: false)
      touch_user
    end
  end

  def near_enough?(test_number, other, epsilon = 1e-6)
    (test_number.to_f - other.to_f).abs < epsilon.to_f
  end
  private :near_enough?

  def outdated?
    if current && evaluated_at.present?
      return true if evaluated_at < context_module.updated_at

      # context module not locked or still to be unlocked
      return false if context_module.unlock_at.blank? || context_module.to_be_unlocked

      # evaluated before unlock time
      return evaluated_at < context_module.unlock_at
    end

    true
  end

  def self.prerequisites_satisfied?(user, context_module)
    related_progressions = nil
    (context_module.active_prerequisites || []).all? do |pre|
      related_progressions ||= context_module.context.find_or_create_progressions_for_user(user).index_by(&:context_module_id)
      if pre[:type] == "context_module" && (progression = related_progressions[pre[:id]])
        progression.evaluate!(context_module)
        progression.completed?
      else
        true
      end
    end
  end

  def prerequisites_satisfied?
    ContextModuleProgression.prerequisites_satisfied?(user, context_module)
  end

  def check_prerequisites
    return false if context_module.to_be_unlocked

    if locked? && prerequisites_satisfied?
      self.workflow_state = "unlocked"
    end
    !locked?
  end
  private :check_prerequisites

  def evaluate_current_position
    self.current_position = nil
    return unless context_module.require_sequential_progress

    completion_requirements = context_module.completion_requirements || []
    requirements_met = self.requirements_met || []

    # for an observer/student combo user we don't want to filter based on the
    # normal observer logic, instead return vis for student enrollment only
    context_module.content_tags_visible_to(user, is_teacher: false, ignore_observer_logic: true).each do |tag|
      self.current_position = tag.position if tag.position
      all_met = completion_requirements.select { |r| r[:id] == tag.id }.all? do |req|
        requirements_met.any? { |r| r[:id] == req[:id] && r[:type] == req[:type] }
      end
      break unless all_met
    end
  end
  private :evaluate_current_position

  # attempts to calculate and save the progression state
  # will not raise a StaleObjectError if there is a conflict
  # may reload the object and may return stale data (if there is a conflict)
  def evaluate!(as_prerequisite_for = nil)
    retry_count = 0
    begin
      evaluate(as_prerequisite_for)
    rescue ActiveRecord::StaleObjectError
      # retry up to five times, otherwise return current (stale) data
      reload
      retry_count += 1
      retry if retry_count < 10

      logger.error { "Failed to evaluate stale progression: #{inspect}" }
    end

    self
  end

  # calculates and saves the progression state
  # raises a StaleObjectError if there is a conflict
  def evaluate(as_prerequisite_for = nil)
    shard.activate do
      return self unless outdated?

      # there is no valid progression state for unpublished modules
      return self if context_module.unpublished?

      self.evaluated_at = Time.now.utc
      self.current = true
      self.requirements_met ||= []

      if check_prerequisites
        evaluate_requirements_met
      end
      completion_changed = workflow_state_changed? && workflow_state_change.include?("completed")

      evaluate_current_position

      GuardRail.activate(:primary) do
        save
      end

      if completion_changed
        trigger_reevaluation_of_dependent_progressions(as_prerequisite_for)
        trigger_completion_events if completed?
      end

      self
    end
  end

  def trigger_reevaluation_of_dependent_progressions(dependent_module_to_skip = nil)
    progressions = context_module.context.find_or_create_progressions_for_user(user)

    # only recalculate progressions related to this module as a prerequisite
    progressions = progressions.select do |progression|
      # re-evaluating progressions that have requested our progression's evaluation can cause cyclic evaluation
      next false if dependent_module_to_skip && progression.context_module_id == dependent_module_to_skip.id

      context_module.is_prerequisite_for?(progression.context_module)
    end

    # invalidate all, then re-evaluate each
    GuardRail.activate(:primary) do
      ContextModuleProgression.where(id: progressions, current: true).update_all(current: false)
      User.where(id: progressions.map(&:user_id)).touch_all

      progressions.each do |progression|
        progression.delay_if_production(n_strand: ["dependent_progression_reevaluation", context_module.global_context_id])
                   .evaluate!(self)
      end
    end
  end
  private :trigger_reevaluation_of_dependent_progressions

  def trigger_completion_events
    context_module.completion_event_callbacks.each do |event|
      event.call(user)
    end
  end
  private :trigger_completion_events

  scope :for_user, ->(user) { where(user_id: user) }
  scope :for_modules, ->(mods) { where(context_module_id: mods) }
  scope :for_course, lambda { |course_id|
    joins(:context_module)
      .readonly(false)
      .where(context_modules: { context_type: "Course", context_id: course_id })
  }

  workflow do
    state :locked
    state :unlocked
    state :started
    state :completed
  end
end
