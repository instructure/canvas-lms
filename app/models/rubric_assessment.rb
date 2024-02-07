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
  belongs_to :assessor, class_name: "User"
  belongs_to :artifact,
             touch: true,
             polymorphic: [:submission, :assignment, { provisional_grade: "ModeratedGrading::ProvisionalGrade" }]
  has_many :assessment_requests, dependent: :destroy
  has_many :learning_outcome_results, as: :artifact, dependent: :destroy
  serialize :data

  simply_versioned

  validates :assessment_type, :rubric_id, :artifact_id, :artifact_type, :assessor_id, presence: true

  before_save :update_artifact_parameters
  before_save :htmlify_rating_comments
  before_save :mark_unread_assessments
  before_create :set_root_account_id
  after_save :update_assessment_requests, :update_artifact
  after_save :track_outcomes

  def track_outcomes
    outcome_ids = aligned_outcome_ids
    peer_review = assessment_type == "peer_review"
    provisional_grade = artifact_type == "ModeratedGrading::ProvisionalGrade"
    update_outcomes = outcome_ids.present? && !peer_review && !provisional_grade
    delay_if_production.update_outcomes_for_assessment(outcome_ids) if update_outcomes
  end

  def aligned_outcome_ids
    (data || []).filter_map { |r| r[:learning_outcome_id] }.uniq
  end

  def update_outcomes_for_assessment(outcome_ids = [])
    return if outcome_ids.empty?

    alignments = if active_rubric_association?
                   rubric_association.association_object.learning_outcome_alignments.where({
                                                                                             learning_outcome_id: outcome_ids
                                                                                           })
                 else
                   []
                 end

    (data || []).each do |rating|
      next unless rating[:learning_outcome_id]

      alignments.each do |alignment|
        if alignment.learning_outcome_id == rating[:learning_outcome_id]
          create_outcome_result(alignment)
        end
      end
    end
  end

  def create_outcome_result(alignment)
    # find or create the user's unique LearningOutcomeResult for this alignment
    # of the assessment's associated object.
    result = alignment.learning_outcome_results
                      .for_association(rubric_association)
                      .where(user_id: user.id)
                      .first_or_initialize

    result.workflow_state = :active
    result.user_uuid = user.uuid

    # force the context and artifact
    result.artifact = self
    result.context = alignment.context

    # mastery
    criterion = rubric_association.rubric.data.find { |c| c[:learning_outcome_id] == alignment.learning_outcome_id }
    criterion_result = data.find { |c| c[:criterion_id] == criterion[:id] }
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
    if artifact.is_a?(Submission)
      result.attempt = artifact.attempt || 1
      result.submitted_at = artifact.submitted_at
    else
      result.attempt = version_number
    end

    # title
    result.title = CanvasTextHelper.truncate_text(
      "#{user.name}, #{rubric_association.title}",
      { max_length: 250 }
    )

    # non-scoring rubrics
    result.hide_points = hide_points
    result.hidden = rubric_association.hide_outcome_results

    result.assessed_at = Time.zone.now
    result.save_to_version(result.attempt)
    result
  end

  def update_artifact_parameters
    if artifact_type == "Submission" && artifact
      self.artifact_attempt = artifact.attempt
    end
  end

  def htmlify_rating_comments
    if data_changed? && data.present?
      data.each do |rating|
        if rating.is_a?(Hash) && rating[:comments].present?
          rating[:comments_html] = format_message(rating[:comments]).first
        end
      end
    end
    true
  end

  def mark_unread_assessments
    return unless artifact.is_a?(Submission)
    return unless data_changed? && data.present?

    if any_comments_or_points?
      artifact.mark_item_unread("rubric")
    end

    true
  end

  def any_comments_or_points?
    data.any? { |rating| rating.is_a?(Hash) && (rating[:comments].present? || rating[:points].present?) }
  end
  private :any_comments_or_points?

  def any_comments?
    data.any? { |rating| rating.is_a?(Hash) && rating[:comments].present? }
  end
  private :any_comments?

  def update_assessment_requests
    requests = assessment_requests
    if active_rubric_association?
      requests += rubric_association.assessment_requests.where({
                                                                 assessor_id:,
                                                                 asset_id: artifact_id,
                                                                 asset_type: artifact_type
                                                               })
    end
    requests.each do |a|
      a.attributes = { rubric_assessment: self, assessor: }
      a.complete
    end
  end
  protected :update_assessment_requests

  def attempt
    (artifact_type == "Submission") ? artifact.attempt : nil
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
        score:,
        grader: assessor,
        graded_anonymously: @graded_anonymously_set,
        grade_posting_in_progress: artifact.grade_posting_in_progress
      )
      artifact.reload
    when "ModeratedGrading::ProvisionalGrade"
      artifact.update!(score:, grade: nil)
    end
  end
  protected :update_artifact

  set_policy do
    given { |user| user && assessor_id == user.id }
    can :create and can :read and can :update

    given { |user| user && user_id == user.id }
    can :read

    given do |user|
      user &&
        self.user &&
        rubric_association &&
        rubric_association.context.is_a?(Course) &&
        rubric_association.context.observer_enrollments.where(user_id: user, associated_user: self.user, workflow_state: "active").exists?
    end
    can :read

    given { |user, session| rubric_association&.grants_right?(user, session, :manage) }
    can :create and can :read and can :delete

    given { |user, session| rubric_association&.grants_right?(user, session, :view_rubric_assessments) }
    can :read

    given do |user, session|
      rubric_association&.grants_right?(user, session, :manage) &&
        (rubric_association.association_object.context.grants_right?(assessor, :manage_rubrics) rescue false)
    end
    can :update

    given do |user, session|
      can_read_assessor_name?(user, session)
    end
    can :read_assessor
  end

  scope :of_type, ->(type) { where(assessment_type: type.to_s) }

  scope :for_submissions, -> { where(artifact_type: "Submission") }
  scope :for_provisional_grades, -> { where(artifact_type: "ModeratedGrading::ProvisionalGrade") }

  scope :for_course_context, lambda { |course_id|
    joins(:rubric_association).where(rubric_associations: { context_id: course_id, context_type: "Course" })
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
    assessor.short_name rescue t("unknown_user", "Unknown User")
  end

  def assessment_url
    artifact.url rescue nil
  end

  def can_read_assessor_name?(user, session)
    assessment_type == "grading" ||
      !considered_anonymous? ||
      assessor_id == user.id ||
      rubric_association.association_object.context.grants_right?(
        user, session, :view_all_grades
      )
  end

  def considered_anonymous?
    return false unless active_rubric_association?

    rubric_association.association_type == "Assignment" &&
      rubric_association.association_object.anonymous_peer_reviews?
  end

  def ratings
    data
  end

  def related_group_submissions_and_assessments
    if active_rubric_association? && rubric_association.association_object.is_a?(Assignment) && !artifact.is_a?(ModeratedGrading::ProvisionalGrade) && !rubric_association.association_object.grade_group_students_individually
      students = rubric_association.association_object.group_students(user).last
      students.map do |student|
        submission = rubric_association.association_object.find_asset_for_assessment(rubric_association, student).first
        { submission:,
          rubric_assessments: submission.rubric_assessments
                                        .where.not(rubric_association: nil)
                                        .map { |ra| ra.as_json(methods: :assessor_name) } }
      end
    else
      []
    end
  end

  def set_root_account_id
    self.root_account_id ||= rubric&.root_account_id
  end

  def active_rubric_association?
    !!rubric_association&.active?
  end
end
