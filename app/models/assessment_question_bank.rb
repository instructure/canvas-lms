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

class AssessmentQuestionBank < ActiveRecord::Base
  include Workflow
  attr_accessible :context, :title, :user, :alignments
  EXPORTABLE_ATTRIBUTES = [:id, :context_id, :context_type, :title, :workflow_state, :deleted_at, :created_at, :updated_at]

  EXPORTABLE_ASSOCIATIONS = [:context, :assessment_questions, :assessment_question_bank_users, :learning_outcome_alignments, :quiz_groups]

  belongs_to :context, :polymorphic => true
  validates_inclusion_of :context_type, :allow_nil => true, :in => ['Account', 'Course']
  has_many :assessment_questions, :order => 'name, position, created_at'
  has_many :assessment_question_bank_users
  has_many :learning_outcome_alignments, :as => :content, :class_name => 'ContentTag', :conditions => ['content_tags.tag_type = ? AND content_tags.workflow_state != ?', 'learning_outcome', 'deleted'], :include => :learning_outcome
  has_many :quiz_groups, class_name: 'Quizzes::QuizGroup'
  before_save :infer_defaults
  after_save :update_alignments
  validates_length_of :title, :maximum => maximum_string_length, :allow_nil => true

  workflow do
    state :active
    state :deleted
  end

  set_policy do
    given{|user, session| self.context.grants_right?(user, session, :manage_assignments) }
    can :read and can :create and can :update and can :delete and can :manage

    given{|user| user && self.assessment_question_bank_users.where(:user_id => user).exists? }
    can :read
  end

  def self.default_imported_title
    t :default_imported_title, 'Imported Questions'
  end

  def self.default_unfiled_title
    t :default_unfiled_title, 'Unfiled Questions'
  end

  def self.unfiled_for_context(context)
    context.assessment_question_banks.find_by_title_and_workflow_state(default_unfiled_title, 'active') || context.assessment_question_banks.create(:title => default_unfiled_title) rescue nil
  end

  def cached_context_short_name
    @cached_context_name ||= Rails.cache.fetch(['short_name_lookup', self.context_code].cache_key) do
      self.context.short_name rescue ""
    end
  end

  def assessment_question_count
    self.assessment_questions.active.count
  end

  def context_code
    "#{self.context_type.underscore}_#{self.context_id}"
  end

  def infer_defaults
    self.title = t(:default_title, "No Name - %{course}", :course => self.context.name) if self.title.blank?
  end

  def alignments=(alignments)
    # empty string from controller or empty hash
    if alignments.empty?
      outcomes = []
    else
      outcomes = context.linked_learning_outcomes.find_all_by_id(alignments.keys.map(&:to_i))
    end

    # delete alignments that aren't in the list anymore
    if outcomes.empty?
      learning_outcome_alignments.update_all(:workflow_state => 'deleted')
    else
      learning_outcome_alignments.
        where("learning_outcome_id NOT IN (?)", outcomes).
        update_all(:workflow_state => 'deleted')
    end

    # add/update current alignments
    unless outcomes.empty?
      alignments.each do |outcome_id, mastery_score|
        outcome = outcomes.detect{ |outcome| outcome.id == outcome_id.to_i }
        next unless outcome
        outcome.align(self, context, :mastery_score => mastery_score)
      end
    end
  end

  def update_alignments
    return unless workflow_state_changed? && deleted?
    LearningOutcome.update_alignments(self, context, [])
  end

  def bookmark_for(user, do_bookmark=true)
    if do_bookmark
      question_bank_user = self.assessment_question_bank_users.find_by_user_id(user.id)
      question_bank_user ||= self.assessment_question_bank_users.create(:user => user)
    else
      AssessmentQuestionBankUser.where(:user_id => user, :assessment_question_bank_id => self).delete_all
    end
  end

  def bookmarked_for?(user)
    user && self.assessment_question_bank_users.map(&:user_id).include?(user.id)
  end

  def select_for_submission(count, exclude_ids=[])
    ids = self.assessment_questions.active.pluck(:id)
    ids = (ids - exclude_ids).shuffle[0...count]
    ids.empty? ? [] : AssessmentQuestion.find_all_by_id(ids).shuffle
  end

  alias_method :destroy!, :destroy
  def destroy
    self.workflow_state = 'deleted'
    self.save
  end

  # clear out all questions so that the bank can be replaced. this is currently
  # used by the respondus API.
  def clear_for_replacement
    assessment_questions.destroy_all
    quiz_groups.destroy_all
  end

  scope :active, where("assessment_question_banks.workflow_state<>'deleted'")
end
