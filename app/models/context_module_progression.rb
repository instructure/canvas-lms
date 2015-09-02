#
# Copyright (C) 2011 Instructure, Inc.
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

class ContextModuleProgression < ActiveRecord::Base
  include Workflow
  attr_accessible :context_module, :user
  belongs_to :context_module
  belongs_to :user
  before_save :set_completed_at

  EXPORTABLE_ATTRIBUTES = [:id, :context_module_id, :user_id, :requirements_met, :workflow_state, :created_at, :updated_at, :collapsed, :current_position, :completed_at]
  EXPORTABLE_ASSOCIATIONS = [:context_module, :user]

  after_save :touch_user

  serialize :requirements_met, Array

  def completion_requirements
    context_module.try(:completion_requirements) || []
  end
  private :completion_requirements

  def set_completed_at
    if self.completed?
      self.completed_at ||= Time.now
    else
      self.completed_at = nil
    end
  end

  def finished_item?(item)
    (self.requirements_met || []).any?{|r| r[:id] == item.id}
  end

  def uncollapse!
    return unless self.collapsed?
    self.collapsed = false
    self.save
  end

  def uncomplete_requirement(id)
    requirement = requirements_met.find {|r| r[:id] == id}
    requirements_met.delete(requirement)
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
      self.actions_done.reject!{ |r| %w(min_score max_score).include?(r[:type]) }
    end

    def sorted_action_keys
      self.actions_done.map{ |r| "#{r[:id]}_#{r[:type]}" }.sort
    end

    def increment_met_requirement_count!
      self.met_requirement_count += 1
    end

    def requirement_met?(req, include_type = true)
      self.actions_done.any? {|r| r[:id] == req[:id] && (include_type ? r[:type] == req[:type] : true)}
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
      self.actions_done << action
    end

    def add_view_requirement(req)
      self.view_requirements << req
    end

    def check_view_requirements
      self.view_requirements.each do |req|
        # should mark a must_view as true if a completed must_submit/min_score action already exists
        check_action!(req, requirement_met?(req, false))
      end
    end
  end

  def evaluate_requirements_met
    result = evaluate_uncompleted_requirements

    count_needed = self.context_module.requirement_count.to_i
    # if no requirement_count is specified, assume all are needed
    if (count_needed && count_needed > 0 && result.met_requirement_count >= count_needed) || result.all_met?
      self.workflow_state = 'completed'
    elsif result.met_requirement_count >= 1
      self.workflow_state = 'started'
    else
      self.workflow_state = 'unlocked'
    end

    if result.changed?
      self.requirements_met = result.actions_done
    end
  end
  private :evaluate_requirements_met

  def evaluate_uncompleted_requirements
    tags_hash = nil
    calc = CompletedRequirementCalculator.new(self.requirements_met || [])
    completion_requirements.each do |req|
      # for an observer/student user we don't want to filter based on the normal observer logic,
      # instead return vis for student enrollment only -> hence ignore_observer_logic below

      # create the hash inside the loop in case the completion_requirements is empty (performance)
      tags_hash ||= context_module.content_tags_visible_to(self.user, is_teacher: false, ignore_observer_logic: true).index_by(&:id)

      tag = tags_hash[req[:id]]
      next unless tag

      if calc.requirement_met?(req)
        calc.increment_met_requirement_count!
        next
      end

      sub = get_submission_or_quiz_submission(tag) if tag.scoreable?
      if sub && (sub.respond_to?(:excused?) && sub.excused?)
        calc.check_action!(req, true)
        next
      end

      if req[:type] == 'must_view'
        calc.add_view_requirement(req)
      elsif %w(must_contribute must_mark_done).include? req[:type]
        # must_contribute is handled by ContextModule#update_for
        calc.check_action!(req, false)
      elsif req[:type] == 'must_submit'
        req_met = false
        if sub
          if sub.graded? && sub.attempt.nil?
            # is a manual grade - doesn't count for submission
            req_met = false
          elsif %w(submitted graded complete pending_review).include?(sub.workflow_state)
            req_met = true
          end
        end

        calc.check_action!(req, req_met)
      elsif req[:type] == 'min_score' || req[:type] == 'max_score'
        calc.check_action!(req, evaluate_score_requirement_met(req, sub))
      end
    end
    calc.check_view_requirements
    calc
  end
  private :evaluate_uncompleted_requirements

  def get_submission_or_quiz_submission(tag)
    if tag.content_type_quiz?
      sub = Quizzes::QuizSubmission.where(quiz_id: tag.content_id, user_id: user).first
      sub ||= Submission.where(assignment_id: tag.content.assignment_id, user_id: user).first
      sub
    elsif tag.content_type_discussion?
      if tag.content
        Submission.where(assignment_id: tag.content.assignment_id, user_id: user).first
      end
    else
      Submission.where(assignment_id: tag.content_id, user_id: user).first
    end
  end
  private :get_submission_or_quiz_submission

  def get_submission_score(submission)
    if submission.is_a?(Quizzes::QuizSubmission)
      submission.try(:kept_score)
    else
      submission.try(:score)
    end
  end
  private :get_submission_score

  def evaluate_score_requirement_met(requirement, sub)
    score = get_submission_score(sub)
    if requirement[:type] == "max_score"
      score.present? && score <= requirement[:max_score].to_f
    else
      score.present? && score >= requirement[:min_score].to_f
    end
  end
  private :evaluate_score_requirement_met

  def update_requirement_met(action, tag, points=nil)
    requirement = context_module.completion_requirement_for(action, tag)
    return nil unless requirement

    requirement_met = true
    requirement_met = points && points >= requirement[:min_score].to_f if requirement[:type] == 'min_score'
    requirement_met = points && points <= requirement[:max_score].to_f if requirement[:type] == 'max_score'
    requirement_met = false if requirement[:type] == 'must_submit' # calculate later; requires the submission

    if !requirement_met
      self.requirements_met.delete(requirement)
      self.mark_as_outdated
      true
    elsif !self.requirements_met.include?(requirement)
      self.requirements_met.push(requirement)
      self.mark_as_outdated
      true
    else
      false
    end
  end

  def update_requirement_met!(*args)
    retry_count = 0
    begin
      if self.update_requirement_met(*args)
        self.save!
        self.send_later_if_production(:evaluate!)
      end
    rescue ActiveRecord::StaleObjectError
      # retry up to five times, otherwise return current (stale) data
      self.reload
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
    if self.new_record?
      mark_as_outdated
      Shackles.activate(:master) do
        self.save!
      end
    else
      self.class.where(:id => self).update_all(:current => false)
      self.touch_user
    end
  end

  def outdated?
    if self.current && evaluated_at.present?
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
      related_progressions ||= ContextModuleProgressions::Finder.find_or_create_for_module_and_user(context_module, user).index_by(&:context_module_id)
      if pre[:type] == 'context_module' && progression = related_progressions[pre[:id]]
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
    if self.locked?
      self.workflow_state = 'unlocked' if prerequisites_satisfied?
    end
    return !self.locked?
  end
  private :check_prerequisites

  def evaluate_current_position
    self.current_position = nil
    return unless context_module.require_sequential_progress

    completion_requirements = context_module.completion_requirements || []
    requirements_met = self.requirements_met || []

    # for an observer/student combo user we don't want to filter based on the
    # normal observer logic, instead return vis for student enrollment only
    context_module.content_tags_visible_to(self.user, is_teacher: false, ignore_observer_logic: true).each do |tag|
      self.current_position = tag.position if tag.position
      all_met = completion_requirements.select{|r| r[:id] == tag.id }.all? do |req|
        requirements_met.any?{|r| r[:id] == req[:id] && r[:type] == req[:type] }
      end
      break unless all_met
    end
  end
  private :evaluate_current_position

  # attempts to calculate and save the progression state
  # will not raise a StaleObjectError if there is a conflict
  # may reload the object and may return stale data (if there is a conflict)
  def evaluate!(as_prerequisite_for=nil)
    retry_count = 0
    begin
      evaluate(as_prerequisite_for)
    rescue ActiveRecord::StaleObjectError
      # retry up to five times, otherwise return current (stale) data
      self.reload
      retry_count += 1
      retry if retry_count < 10

      logger.error { "Failed to evaluate stale progression: #{self.inspect}" }
    end

    self
  end

  # calculates and saves the progression state
  # raises a StaleObjectError if there is a conflict
  def evaluate(as_prerequisite_for=nil)
    self.shard.activate do
      return self unless outdated?

      # there is no valid progression state for unpublished modules
      return self if context_module.unpublished?

      self.evaluated_at = Time.now.utc
      self.current = true
      self.requirements_met ||= []

      if check_prerequisites
        evaluate_requirements_met
      end
      completion_changed = self.workflow_state_changed? && self.workflow_state_change.include?('completed')

      evaluate_current_position

      Shackles.activate(:master) do
        self.save
      end

      if completion_changed
        trigger_reevaluation_of_dependent_progressions(as_prerequisite_for)
        trigger_completion_events if self.completed?
      end

      self
    end
  end

  def trigger_reevaluation_of_dependent_progressions(dependent_module_to_skip=nil)
    progressions = ContextModuleProgressions::Finder.find_or_create_for_module_and_user(context_module, user)

    # only recalculate progressions related to this module as a prerequisite
    progressions = progressions.select do |progression|
      # re-evaluating progressions that have requested our progression's evaluation can cause cyclic evaluation
      next false if dependent_module_to_skip && progression.context_module_id == dependent_module_to_skip.id

      self.context_module.is_prerequisite_for?(progression.context_module)
    end

    # invalidate all, then re-evaluate each
    Shackles.activate(:master) do
      progressions.each(&:mark_as_outdated!)
      progressions.each do |progression|
        progression.send_later_if_production(:evaluate!, self)
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

  scope :for_user, lambda { |user| where(:user_id => user) }
  scope :for_modules, lambda { |mods| where(:context_module_id => mods) }

  workflow do
    state :locked
    state :unlocked
    state :started
    state :completed
  end
end
