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
  
  def evaluate_requirements_met
    met = self.requirements_met || []
    orig_reqs = met.map{|r| "#{r[:id]}_#{r[:type]}"}.sort

    met = evaluate_uncompleted_requirements(met)
    new_reqs = met.map{|r| "#{r[:id]}_#{r[:type]}"}.sort

    if orig_reqs != new_reqs
      self.requirements_met = met
      self.save
    end
  end

  def evaluate_uncompleted_requirements(met)
    met = met.dup
    uncompleted_view_reqs = []
    context_module.completion_requirements.each do |req|
      next if requirement_met?(req, met)

      req_met = nil
      tag = context_module.content_tags_hash[req[:id]]
      if !tag
        req_met = req
      elsif req[:type] == "must_view"
        uncompleted_view_reqs << req
      elsif req[:type] == "must_contribute"
        
      elsif req[:type] == "must_submit"
        req_met = evaluate_submit_requirement_met(req, tag)
      elsif req[:type] == "max_score" || req[:type] == "min_score"
        req_met = evaluate_score_requirement_met(req, tag)
      end

      met << req_met if req_met
    end 

    uncompleted_view_reqs.each do |req|
      met << req if other_requirement_met?(req, met)
    end

    met
  end
  private :evaluate_uncompleted_requirements

  def requirement_met?(req, met_reqs)
    met_reqs.any? {|r| r[:id] == req[:id] && r[:type] == req[:type] }
  end

  def other_requirement_met?(req, met_reqs)
    met_reqs.any? {|r| r[:id] == req[:id] }
  end

  def get_submission_score(tag_content)
    if tag_content.is_a?(Assignment)
      submission = self.user.submitted_submission_for(tag_content.id)
      submission.try(:score)
    elsif tag_content.is_a?(Quizzes::Quiz)
      submission = self.user.attempted_quiz_submission_for(tag_content.id)
      submission.try(:kept_score)
    end
  end
  private :get_submission_score

  def evaluate_score_requirement_met(requirement, tag)
    score = get_submission_score(tag.content)
    if requirement[:type] == "max_score"
      requirement if score && score <= requirement[:max_score].to_f
    else
      requirement if score && score >= requirement[:min_score].to_f
    end
  end
  private :evaluate_score_requirement_met

  def evaluate_submit_requirement_met(requirement, tag)
    content = tag.content
    content = content.assignment if content.is_a?(DiscussionTopic)
    if content.is_a?(Assignment)
      requirement if self.user.submitted_submission_for(content.id)
    elsif content.is_a?(Quizzes::Quiz)
      requirement if self.user.attempted_quiz_submission_for(content.id)
    end
  end
  private :evaluate_submit_requirement_met

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

  def mark_as_complete
    self.workflow_state = 'completed'
    nil
  end

  def mark_as_complete!
    mark_as_complete
    Shackles.activate(:master) do
      self.save if self.workflow_state_changed?
    end
    nil
  end

  def evaluate(recursive_check=false, deep_check=false)
    # there is no valid progression state for unpublished modules
    return mark_as_dirty! if context_module.unpublished?

    requirements_met_changed = false
    if User.module_progression_jobs_queued?(user.id)
      mark_as_dirty
    end
    if deep_check
      context_module.confirm_valid_requirements(true) rescue nil
    end
    tags = context_module.cached_tags
    if recursive_check || self.new_record? || self.updated_at < context_module.updated_at || User.module_progression_jobs_queued?(user.id)
      if context_module.completion_requirements.blank? && context_module.active_prerequisites.empty?
        mark_as_complete!
      end
      mark_as_dirty
      if !context_module.to_be_unlocked
        self.requirements_met ||= []
        if self.locked?
          self.workflow_state = 'unlocked' if context_module.prerequisites_satisfied?(user)
        end
        if self.unlocked? || self.started?
          orig_reqs = (self.requirements_met || []).map{|r| "#{r[:id]}_#{r[:type]}" }.sort
          completes = (context_module.completion_requirements || []).map do |req|
            tag = tags.detect{|t| t.id == req[:id].to_i}
            if !tag
              res = true
            elsif ['min_score', 'max_score', 'must_submit'].include?(req[:type]) && !tag.scoreable?
              res = true
            else
              self.evaluate_requirements_met if deep_check
              res = self.requirements_met.any?{|r| r[:id] == req[:id] && r[:type] == req[:type] } #include?(req)
              if req[:type] == 'min_score'
                self.requirements_met = self.requirements_met.select{|r| r[:id] != req[:id] || r[:type] != req[:type]}
                if tag.content_type_quiz?
                  submission = Quizzes::QuizSubmission.find_by_quiz_id_and_user_id(tag.content_id, user.id)
                  score = submission.try(:kept_score)
                elsif tag.content_type == "DiscussionTopic"
                  if tag.content
                    submission = Submission.find_by_assignment_id_and_user_id(tag.content.assignment_id, user.id)
                    score = submission.try(:score)
                  else
                    score = nil
                  end
                else
                  submission = Submission.find_by_assignment_id_and_user_id(tag.content_id, user.id)
                  score = submission.try(:score)
                end
                if score && score >= req[:min_score].to_f
                  self.requirements_met << req
                  res = true
                else
                  res = false
                end
              end
            end
            res
          end
          new_reqs = (self.requirements_met || []).map{|r| "#{r[:id]}_#{r[:type]}" }.sort
          requirements_met_changed = new_reqs != orig_reqs
          self.workflow_state = 'started' if completes.any?
          self.workflow_state = 'completed' if completes.all?
        end
      end
    end
    position = nil
    found_failure = false
    if context_module.require_sequential_progress
      tags.each do |tag|
        requirements_for_tag = (context_module.completion_requirements || []).select{|r| r[:id] == tag.id }.sort_by{|r| r[:id]}
        next if found_failure
        if requirements_for_tag.empty?
          position = tag.position
        else
          all_met = requirements_for_tag.all? do |req|
            (self.requirements_met || []).any?{|r| r[:id] == req[:id] && r[:type] == req[:type] }
          end
          if all_met
            position = tag.position if tag.position && all_met
          else
            position = tag.position
            found_failure = true
          end
        end
      end
    end
    self.current_position = position
    Shackles.activate(:master) do
      self.save if self.workflow_state_changed? || requirements_met_changed
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
