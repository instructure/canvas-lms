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

# Associates an artifact with a rubric while offering an assessment and 
# scoring using the rubric.  Assessments are grouped together in one
# RubricAssociation, which may or may not have an association model.
class RubricAssessment < ActiveRecord::Base
  include TextHelper
  include HtmlTextHelper

  attr_accessible :rubric, :rubric_association, :user, :score, :data, :comments, :assessor, :artifact, :assessment_type
  belongs_to :rubric
  belongs_to :rubric_association
  belongs_to :user
  belongs_to :assessor, :class_name => 'User'
  belongs_to :artifact, :polymorphic => true, :touch => true
  validates_inclusion_of :artifact_type, :allow_nil => true, :in => ['Submission', 'Assignment']
  has_many :assessment_requests, :dependent => :destroy
  serialize :data

  simply_versioned

  EXPORTABLE_ATTRIBUTES = [:id, :user_id, :rubric_id, :rubric_association_id, :score, :data, :comments, :created_at, :updated_at, :artifact_id, :artifact_type, :assessment_type, :assessor_id, :artifact_attempt]
  EXPORTABLE_ASSOCIATIONS = [:rubric, :rubric_association, :user, :assessor, :artifact, :assessment_requests]

  validates_presence_of :assessment_type, :rubric_id, :artifact_id, :artifact_type, :assessor_id
  validates_length_of :comments, :maximum => maximum_text_length, :allow_nil => true, :allow_blank => true
  
  before_save :update_artifact_parameters
  before_save :htmlify_rating_comments
  after_save :update_assessment_requests, :update_artifact
  after_save :track_outcomes
  
  def track_outcomes
    outcome_ids = (self.data || []).map{|r| r[:learning_outcome_id] }.compact.uniq
    send_later_if_production(:update_outcomes_for_assessment, outcome_ids) unless outcome_ids.empty?
  end
  
  def update_outcomes_for_assessment(outcome_ids=[])
    return if outcome_ids.empty?
    alignments = self.rubric_association.association_object.learning_outcome_alignments.find_all_by_learning_outcome_id(outcome_ids)
    (self.data || []).each do |rating|
      if rating[:learning_outcome_id]
        alignments.each do |alignment|
          if alignment.learning_outcome_id == rating[:learning_outcome_id]
            create_outcome_result(alignment)
          end
        end
      end
    end
  end

  def create_outcome_result(alignment)
    # find or create the user's unique LearningOutcomeResult for this alignment
    # of the assessment's associated object.
    result = alignment.learning_outcome_results.
      for_association(rubric_association).
      find_or_initialize_by_user_id(user.id)

    # force the context and artifact
    result.artifact = self
    result.context = alignment.context

    # mastery
    criterion = rubric_association.rubric.data.find{|c| c[:learning_outcome_id] == alignment.learning_outcome_id }
    criterion_result = self.data.find{|c| c[:criterion_id] == criterion[:id] }
    if criterion
      result.possible = criterion[:points]
      result.score = criterion_result && criterion_result[:points]
      result.mastery = result.score && (criterion[:mastery_points] || result.possible) && result.score >= (criterion[:mastery_points] || result.possible)
    else
      result.possible = nil
      result.score = nil
      result.mastery = nil
    end

    # attempt
    if self.artifact && self.artifact.is_a?(Submission)
      result.attempt = self.artifact.attempt || 1
    else
      result.attempt = self.version_number
    end

    # title
    result.title = "#{user.name}, #{rubric_association.title}"

    result.assessed_at = Time.now
    result.save_to_version(result.attempt)
    result
  end

  def update_artifact_parameters
    if self.artifact_type == 'Submission' && self.artifact
      self.artifact_attempt = self.artifact.attempt
    end
  end

  def htmlify_rating_comments
    if self.data_changed? && self.data.present?
      self.data.each do |rating|
        if rating.is_a?(Hash) && rating[:comments].present?
          rating[:comments_html] = format_message(rating[:comments]).first
        end
      end
    end
    true
  end

  def update_assessment_requests
    requests = self.assessment_requests
    requests += self.rubric_association.assessment_requests.find_all_by_assessor_id_and_asset_id_and_asset_type(self.assessor_id, self.artifact_id, self.artifact_type)
    requests.each { |a|
      a.attributes = {:rubric_assessment => self, :assessor => self.assessor}
      a.complete
    }
  end
  protected :update_assessment_requests

  def attempt
    self.artifact_type == 'Submission' ? self.artifact.attempt : nil
  end

  def update_artifact
    if self.artifact_type == 'Submission' && self.artifact
      Submission.where(:id => self.artifact).update_all(:has_rubric_assessment => true)
      if self.rubric_association && self.rubric_association.use_for_grading && self.artifact.score != self.score
        if self.rubric_association.association_object.grants_right?(self.assessor, nil, :grade)
          # TODO: this should go through assignment.grade_student to 
          # handle group assignments.
          self.artifact.workflow_state = 'graded'
          self.artifact.update_attributes(:score => self.score, :graded_at => Time.now, :grade_matches_current_submission => true, :grader => self.assessor)
        end
      end
    end
  end
  protected :update_artifact
  
  set_policy do
    given {|user, session| session && session[:rubric_assessment_ids] && session[:rubric_assessment_ids].include?(self.id) }
    can :create and can :read and can :update
  
    given {|user| user && self.assessor_id == user.id }
    can :create and can :read and can :update
    
    given {|user| user && self.user_id == user.id }
    can :read
    
    given {|user, session| self.rubric_association && self.rubric_association.grants_rights?(user, session, :manage)[:manage] }
    can :create and can :read and can :delete

    given {|user, session| 
      self.rubric_association && 
      self.rubric_association.grants_rights?(user, session, :manage)[:manage] &&
      (self.rubric_association.association_object.context.grants_right?(self.assessor, nil, :manage_rubrics) rescue false)
    }
    can :update
  end
  
  scope :of_type, lambda { |type| where(:assessment_type => type.to_s) }

  def methods_for_serialization(*methods)
    @serialization_methods = methods
  end

  def serialization_methods
    @serialization_methods || []
  end
  
  def assessor_name
    self.assessor.short_name rescue t('unknown_user', "Unknown User")
  end
  
  def assessment_url
    self.artifact.url rescue nil
  end
  
  def ratings
    self.data
  end
  
  def related_group_submissions_and_assessments
    if self.rubric_association && self.rubric_association.association_object.is_a?(Assignment) && !self.rubric_association.association_object.grade_group_students_individually
      students = self.rubric_association.association_object.group_students(self.user).last
      submissions = students.map do |student|
        submission = self.rubric_association.association_object.find_asset_for_assessment(self.rubric_association, student.id).first
        {:submission => submission, :rubric_assessments => submission.rubric_assessments.map{|ra| ra.as_json(:methods => :assessor_name)}}
      end
    else
      []
    end
  end
  
end
