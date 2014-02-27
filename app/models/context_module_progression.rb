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
  
  before_save :infer_defaults
  after_save :touch_user
  after_save :trigger_completion_events
  
  serialize :requirements_met

  def completion_requirements
    context_module.try(:completion_requirements) || []
  end
  private :completion_requirements
  
  def infer_defaults
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

    def other_requirement_met?(req)
      met = requirements_met.any? {|r| r[:id] == req[:id] }
      @started = true if met
      met
    end

    def view_requirement(req)
      view_requirements << req
    end

    def check_view_requirements
      view_requirements.each do |req|
        requirement_met(req, other_requirement_met?(req))
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
      # create the hash inside the loop in case the completion_requirements is empty (performance)
      tags_hash ||= context_module.cached_active_tags.index_by(&:id)

      tag = tags_hash[req[:id]]
      next unless tag

      next if calc.requirement_met?(req)

      if req[:type] == 'must_view'
        calc.view_requirement(req)
      elsif req[:type] == 'must_contribute'
        calc.requirement_met(req, false)
      elsif req[:type] == 'must_submit'
        calc.requirement_met(req, !!get_submission_or_quiz_submission(tag))
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
      Quizzes::QuizSubmission.find_by_quiz_id_and_user_id(tag.content_id, user.id)
    elsif tag.content_type_discussion?
      if tag.content
        Submission.find_by_assignment_id_and_user_id(tag.content.assignment_id, user.id)
      end
    else
      Submission.find_by_assignment_id_and_user_id(tag.content_id, user.id)
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
      !!score && score <= requirement[:max_score].to_f
    else
      !!score && score >= requirement[:min_score].to_f
    end
  end
  private :evaluate_score_requirement_met

  def mark_as_dirty
    self.workflow_state = 'locked'
    nil
  end

  def mark_as_dirty!
    mark_as_dirty
    Shackles.activate(:master) do
      self.save if self.workflow_state_changed?
    end
    nil
  end

  def self.prerequisites_satisfied?(user, context_module)
    unlocked = (context_module.active_prerequisites || []).all? do |pre|
      if pre[:type] == 'context_module'
        prog = user.module_progression_for(pre[:id])
        if prog
          prog.completed?
        elsif pre[:id].present?
          if prereq = context_module.context.context_modules.active.find_by_id(pre[:id])
            prog = prereq.evaluate_for(user, true)
            prog.completed?
          else
            true
          end
        else
          true
        end
      else
        true
      end
    end
    unlocked
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

    context_module.cached_active_tags.each do |tag|
      self.current_position = tag.position if tag.position
      all_met = completion_requirements.select{|r| r[:id] == tag.id }.all? do |req|
        requirements_met.any?{|r| r[:id] == req[:id] && r[:type] == req[:type] }
      end
      break unless all_met
    end
  end
  private :evaluate_current_position

  def evaluate(force_evaluate_requirements)
    # there is no valid progression state for unpublished modules
    return mark_as_dirty! if context_module.unpublished?

    if force_evaluate_requirements || self.new_record? || self.updated_at < context_module.updated_at || User.module_progression_jobs_queued?(user.id)
      self.requirements_met ||= []
      self.workflow_state = 'locked'
      if check_prerequisites
        evaluate_requirements_met
      end
    end

    evaluate_current_position

    Shackles.activate(:master) do
      self.save if self.changed?
    end
  end

  def trigger_completion_events
    if workflow_state_changed? && completed?
      context_module.completion_event_callbacks.each do |event|
        event.call(user)
      end
    end
  end

  scope :for_user, lambda { |user| where(:user_id => user) }
  scope :for_modules, lambda { |mods| where(:context_module_id => mods) }

  workflow do
    state :locked
    state :unlocked
    state :started
    state :completed
  end
end
