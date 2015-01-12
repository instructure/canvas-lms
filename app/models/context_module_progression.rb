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

  class CompletedRequirementCalculator
    attr_accessor :requirements_met, :view_requirements

    def started?
      @started
    end

    def completed?
      @completed
    end

    def changed?
      @orig_keys != sorted_requirement_keys
    end

    def initialize(requirements_met)
      @requirements_met = requirements_met
      @orig_keys = sorted_requirement_keys
      @view_requirements = []
      @started = false
      @completed = true

      @requirements_met = @requirements_met.reject{ |r| %w(min_score max_score).include?(r[:type]) }
    end

    def sorted_requirement_keys
      requirements_met.map{ |r| "#{r[:id]}_#{r[:type]}" }.sort
    end

    def requirement_met?(req)
      met = requirements_met.any? {|r| r[:id] == req[:id] && r[:type] == req[:type] }
      @started = true if met
      met
    end

    def requirement_met(req, is_met)
      unless is_met
        @completed = false
        return
      end

      @started = true
      requirements_met << req
    end

    def any_requirement_met?(req)
      met = requirements_met.any? {|r| r[:id] == req[:id] }
      @started = true if met
      met
    end

    def view_requirement(req)
      view_requirements << req
    end

    def check_view_requirements
      view_requirements.each do |req|
        requirement_met(req, any_requirement_met?(req))
      end
    end
  end
  
  def evaluate_requirements_met
    result = evaluate_uncompleted_requirements
    if result.completed?
      self.workflow_state = 'completed'
    elsif result.started?
      self.workflow_state = 'started'
    end

    if result.changed?
      self.requirements_met = result.requirements_met
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

      next if calc.requirement_met?(req)

      if req[:type] == 'must_view'
        calc.view_requirement(req)
      elsif req[:type] == 'must_contribute'
        calc.requirement_met(req, false)
      elsif req[:type] == 'must_submit'
        sub = get_submission_or_quiz_submission(tag)
        calc.requirement_met(req, sub && %w(submitted graded complete pending_review).include?(sub.workflow_state))
      elsif req[:type] == 'min_score' || req[:type] == 'max_score'
        calc.requirement_met(req, evaluate_score_requirement_met(req, tag)) if tag.scoreable?
      end
      # must_contribute is handled by ContextModule#update_for
    end
    calc.check_view_requirements
    calc
  end
  private :evaluate_uncompleted_requirements

  def get_submission_or_quiz_submission(tag)
    if tag.content_type_quiz?
      Quizzes::QuizSubmission.where(quiz_id: tag.content_id, user_id: user).first
    elsif tag.content_type_discussion?
      if tag.content
        Submission.where(assignment_id: tag.content.assignment_id, user_id: user).first
      end
    else
      Submission.where(assignment_id: tag.content_id, user_id: user).first
    end
  end
  private :get_submission_or_quiz_submission

  def get_submission_score(tag)
    submission = get_submission_or_quiz_submission(tag)
    if tag.content_type_quiz?
      submission.try(:kept_score)
    else
      submission.try(:score)
    end
  end
  private :get_submission_score

  def evaluate_score_requirement_met(requirement, tag)
    score = get_submission_score(tag)
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
    if !requirement_met
      self.requirements_met.delete(requirement)
      self.mark_as_outdated
    elsif !self.requirements_met.include?(requirement)
      self.requirements_met.push(requirement)
      self.mark_as_outdated
    end
    requirement
  end

  def mark_as_outdated
    self.current = false
  end

  def mark_as_outdated!
    self.mark_as_outdated
    Shackles.activate(:master) do
      self.save
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
    if self.unlocked?
      self.workflow_state = 'locked' if !prerequisites_satisfied?
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
      retry if retry_count < 5

      logger.error { "Failed to evaluate stale progression: #{self.inspect}" }
    end

    self
  end

  # calculates and saves the progression state
  # raises a StaleObjectError if there is a conflict
  def evaluate(as_prerequisite_for=nil)
    return self unless outdated?

    # there is no valid progression state for unpublished modules
    return self if context_module.unpublished?

    self.evaluated_at = Time.now.utc
    self.current = true
    self.requirements_met ||= []
    self.workflow_state = 'locked'

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

  def trigger_reevaluation_of_dependent_progressions(dependent_module_to_skip=nil)
    progressions = ContextModuleProgressions::Finder.find_or_create_for_module_and_user(context_module, user)

    # only recalculate progressions related to this module as a prerequisite
    progressions = progressions.select do |progression|
      # re-evaluating progressions that have requested our progression's evaluation can cause cyclic evaluation
      next false if dependent_module_to_skip && progression.context_module_id == dependent_module_to_skip.id

      self.context_module.is_prerequisite_for?(progression.context_module)
    end

    # invalidate all, then re-evaluate each
    progressions.each(&:mark_as_outdated!)
    progressions.each do |progression|
      progression.send_later_if_production(:evaluate!, self)
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
