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

# Associates an artifact with a rubric while offering an assessment and
# scoring using the rubric.  Assessments are grouped together in one
# RubricAssociation, which may or may not have an association model.
class RubricAssessment < ActiveRecord::Base
  include TextHelper
  include HtmlTextHelper

  belongs_to :rubric
  belongs_to :rubric_association
  belongs_to :user
  belongs_to :assessor, :class_name => 'User'
  belongs_to :artifact, touch: true,
             polymorphic: [:submission, :assignment, { provisional_grade: 'ModeratedGrading::ProvisionalGrade' }]
  has_many :assessment_requests, :dependent => :destroy
  has_many :learning_outcome_results, as: :artifact, :dependent => :destroy
  serialize :data

  simply_versioned

  validates_presence_of :assessment_type, :rubric_id, :artifact_id, :artifact_type, :assessor_id

  before_save :update_artifact_parameters
  before_save :htmlify_rating_comments
  before_create :set_root_account_id
  after_save :update_assessment_requests, :update_artifact
  after_save :track_outcomes

  def track_outcomes
    outcome_ids = (self.data || []).map{|r| r[:learning_outcome_id] }.compact.uniq
    peer_review = self.assessment_type == "peer_review"
    provisional_grade = self.artifact_type == "ModeratedGrading::ProvisionalGrade"
    update_outcomes = outcome_ids.present? && !peer_review && !provisional_grade
    delay_if_production.update_outcomes_for_assessment(outcome_ids) if update_outcomes
  end

  def update_outcomes_for_assessment(outcome_ids=[])
    return if outcome_ids.empty?

    alignments = if active_rubric_association?
      self.rubric_association.association_object.learning_outcome_alignments.where({
        learning_outcome_id: outcome_ids
      })
    else
      []
    end

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
      where(user_id: user.id).
      first_or_initialize

    result.workflow_state = :active
    result.user_uuid = user.uuid

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
      result.submitted_at = self.artifact.submitted_at
    else
      result.attempt = self.version_number
    end

    # title
    result.title = CanvasTextHelper.truncate_text(
      "#{user.name}, #{rubric_association.title}",
      {max_length: 250}
    )

    # non-scoring rubrics
    result.hide_points = self.hide_points
    result.hidden = self.rubric_association.hide_outcome_results

    result.assessed_at = Time.zone.now
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
    if active_rubric_association?
      requests += self.rubric_association.assessment_requests.where({
        assessor_id: self.assessor_id,
        asset_id: self.artifact_id,
        asset_type: self.artifact_type
      })
    end
    requests.each { |a|
      a.attributes = {:rubric_assessment => self, :assessor => self.assessor}
      a.complete
    }
  end
  protected :update_assessment_requests

  def attempt
    self.artifact_type == 'Submission' ? self.artifact.attempt : nil
  end

  def set_graded_anonymously
    @graded_anonymously_set = true
  end

  def update_artifact
    return if artifact.blank? || !rubric_association&.use_for_grading? || artifact.score == score

    case artifact_type
    when "Submission"
      assignment = rubric_association.association_object
      return unless assignment.grants_right?(assessor, :grade)

      assignment.grade_student(
        artifact.student,
        score: score,
        grader: assessor,
        graded_anonymously: @graded_anonymously_set,
        grade_posting_in_progress: artifact.grade_posting_in_progress
      )
      artifact.reload
    when "ModeratedGrading::ProvisionalGrade"
      artifact.update!(score: score)
    end
  end
  protected :update_artifact

  set_policy do
    given {|user| user && self.assessor_id == user.id }
    can :create and can :read and can :update

    given {|user| user && self.user_id == user.id }
    can :read

    given { |user|
      user &&
      self.user &&
      self.rubric_association &&
      self.rubric_association.context.is_a?(Course) &&
      self.rubric_association.context.observer_enrollments.where(user_id: user, associated_user: self.user, workflow_state: 'active').exists?
    }
    can :read

    given {|user, session| self.rubric_association && self.rubric_association.grants_right?(user, session, :manage) }
    can :create and can :read and can :delete

    given {|user, session| self.rubric_association && self.rubric_association.grants_right?(user, session, :view_rubric_assessments) }
    can :read

    given {|user, session|
      self.rubric_association &&
      self.rubric_association.grants_right?(user, session, :manage) &&
      (self.rubric_association.association_object.context.grants_right?(self.assessor, :manage_rubrics) rescue false)
    }
    can :update

    given {|user, session|
      self.can_read_assessor_name?(user, session)
    }
    can :read_assessor

  end

  scope :of_type, lambda { |type| where(:assessment_type => type.to_s) }

  scope :for_submissions, -> { where(:artifact_type => "Submission")}
  scope :for_provisional_grades, -> { where(:artifact_type => "ModeratedGrading::ProvisionalGrade")}

  scope :for_course_context, lambda { |course_id|
    joins(:rubric_association).where(rubric_associations: {context_id: course_id, context_type: "Course"})
  }

  def methods_for_serialization(*methods)
    @serialization_methods = methods
  end

  def serialization_methods
    @serialization_methods || []
  end

  def score
    self[:score]&.round(Rubric::POINTS_POSSIBLE_PRECISION)
  end

  def assessor_name
    self.assessor.short_name rescue t('unknown_user', "Unknown User")
  end

  def assessment_url
    self.artifact.url rescue nil
  end

  def can_read_assessor_name?(user, session)
    self.assessment_type == 'grading' ||
    !self.considered_anonymous? ||
    self.assessor_id == user.id ||
    self.rubric_association.association_object.context.grants_right?(
      user, session, :view_all_grades
    )
  end

  def considered_anonymous?
    return false unless active_rubric_association?

    self.rubric_association.association_type == 'Assignment' &&
    self.rubric_association.association_object.anonymous_peer_reviews?
  end

  def ratings
    self.data
  end

  def related_group_submissions_and_assessments
    if active_rubric_association? && self.rubric_association.association_object.is_a?(Assignment) && !self.artifact.is_a?(ModeratedGrading::ProvisionalGrade) && !self.rubric_association.association_object.grade_group_students_individually
      students = self.rubric_association.association_object.group_students(self.user).last
      submissions = students.map do |student|
        submission = self.rubric_association.association_object.find_asset_for_assessment(self.rubric_association, student).first
        {:submission => submission, :rubric_assessments => submission.rubric_assessments.map{|ra| ra.as_json(:methods => :assessor_name)}}
      end
    else
      []
    end
  end

  def set_root_account_id
    self.root_account_id ||= self.rubric&.root_account_id
  end

  def active_rubric_association?
    !!self.rubric_association&.active?
  end
end
