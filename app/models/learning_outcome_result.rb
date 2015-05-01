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

class LearningOutcomeResult < ActiveRecord::Base
  include PolymorphicTypeOverride
  override_polymorphic_types association_type: {'Quiz' => 'Quizzes::Quiz'},
                             associated_asset_type: {'Quiz' => 'Quizzes::Quiz'},
                             artifact_type: {'QuizSubmission' => 'Quizzes::QuizSubmission'}

  belongs_to :user
  belongs_to :learning_outcome
  belongs_to :alignment, :class_name => 'ContentTag', :foreign_key => :content_tag_id
  belongs_to :association_object, :polymorphic => true, :foreign_type => :association_type, :foreign_key => :association_id
  validates_inclusion_of :association_type, :allow_nil => true, :in => ['Quizzes::Quiz', 'RubricAssociation', 'Assignment', 'LiveAssessments::Assessment']
  belongs_to :artifact, :polymorphic => true
  validates_inclusion_of :artifact_type, :allow_nil => true, :in => ['Quizzes::QuizSubmission', 'RubricAssessment', 'Submission', 'LiveAssessments::Submission']
  belongs_to :associated_asset, :polymorphic => true
  validates_inclusion_of :associated_asset_type, :allow_nil => true, :in => ['AssessmentQuestion', 'Quizzes::Quiz', 'LiveAssessments::Assessment']
  belongs_to :context, :polymorphic => true
  validates_inclusion_of :context_type, :allow_nil => true, :in => ['Course']
  simply_versioned

  EXPORTABLE_ATTRIBUTES = [
    :id, :context_id, :context_type, :context_code, :association_id, :association_type, :content_tag_id, :learning_outcome_id, :mastery, :user_id, :score, :created_at, :updated_at,
    :attempt, :possible, :comments, :original_score, :original_possible, :original_mastery, :artifact_id, :artifact_type, :assessed_at, :title, :percent, :associated_asset_id, :associated_asset_type
  ]

  EXPORTABLE_ASSOCIATIONS = [:user, :learning_outcome, :association_object, :artifact, :associated_asset, :context]
  before_save :infer_defaults

  attr_accessible :learning_outcome, :user, :association_object, :alignment, :associated_asset

  def infer_defaults
    self.learning_outcome_id = self.alignment.learning_outcome_id
    self.context_code = "#{self.context_type.underscore}_#{self.context_id}" rescue nil
    self.original_score ||= self.score
    self.original_possible ||= self.possible
    self.original_mastery = self.mastery if self.original_mastery == nil
    self.percent = self.score.to_f / self.possible.to_f rescue nil
    self.percent = nil if self.percent && !self.percent.to_f.finite?
    true
  end

  def assignment
    if self.association_object.is_a?(Assignment)
      self.association_object
    elsif self.artifact.is_a?(RubricAssessment)
      self.artifact.rubric_association.association_object
    else
      nil
    end
  end

  def save_to_version(attempt)
    current_version = self.versions.current.try(:model)
    if current_version.try(:attempt) && attempt < current_version.attempt
      versions = self.versions.sort_by(&:created_at).reverse.select{|v| v.model.attempt == attempt}
      if !versions.empty?
        versions.each do |version|
          version_data = YAML::load(version.yaml)
          version_data["score"] = self.score
          version_data["mastery"] = self.mastery
          version_data["possible"] = self.possible
          version_data["attempt"] = self.attempt
          version_data["title"] = self.title
          version.yaml = version_data.to_yaml
          version.save
        end
      else
        save
      end
    else
      save
    end
  end

  def submitted_or_assessed_at
    submitted_at || assessed_at
  end

  scope :for_context_codes, lambda { |codes|
    if codes == 'all'
      scoped
    else
      where(:context_code => codes)
    end
  }
  scope :for_user, lambda { |user| where(:user_id => user) }
  scope :custom_ordering, lambda { |param|
    orders = {
      'recent' => "assessed_at DESC",
      'highest' => "score DESC",
      'oldest' => "score ASC",
      'default' => "assessed_at DESC"
    }
    order_clause = orders[param] || orders['default']
    order(order_clause)
  }
  scope :for_outcome_ids, lambda { |ids| where(:learning_outcome_id => ids) }
  scope :for_association, lambda { |association| where(:association_type => association.class.to_s, :association_id => association.id) }
  scope :for_associated_asset, lambda { |associated_asset| where(:associated_asset_type => associated_asset.class.to_s, :associated_asset_id => associated_asset.id) }
end
