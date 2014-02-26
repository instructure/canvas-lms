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
