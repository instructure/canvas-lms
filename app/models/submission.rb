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

require "anonymity"

class Submission < ActiveRecord::Base
  include Canvas::GradeValidations
  include CustomValidations
  include SendToStream
  include Workflow

  GRADE_STATUS_MESSAGES_MAP = {
    success: {
      status: true
    }.freeze,
    account_admin: {
      status: true
    }.freeze,
    unpublished: {
      status: false,
      message: I18n.t("This assignment is still unpublished")
    }.freeze,
    not_autograded: {
      status: false,
      message: I18n.t("This submission is not being autograded")
    }.freeze,
    cant_manage_grades: {
      status: false,
      message: I18n.t("You don't have permission to manage grades for this course")
    }.freeze,
    assignment_in_closed_grading_period: {
      status: false,
      message: I18n.t("This assignment is in a closed grading period for this student")
    }.freeze,
    not_applicable: {
      status: false,
      message: I18n.t("This assignment is not applicable to this student")
    }.freeze,
    moderation_in_progress: {
      status: false,
      message: I18n.t("This assignment is currently being moderated")
    }.freeze
  }.freeze

  SUBMISSION_TYPES_GOVERNED_BY_ALLOWED_ATTEMPTS = %w[online_upload online_url online_text_entry].freeze
  VALID_STICKERS = %w[
    apple
    basketball
    bell
    book
    bookbag
    briefcase
    bus
    calendar
    chem
    design
    pencil
    beaker
    paintbrush
    computer
    column
    pen
    tablet
    telescope
    calculator
    paperclip
    composite_notebook
    scissors
    ruler
    clock
    globe
    grad
    gym
    mail
    microscope
    mouse
    music
    notebook
    page
    panda1
    panda2
    panda3
    panda4
    panda5
    panda6
    panda7
    panda8
    panda9
    presentation
    science
    science2
    star
    tag
    tape
    target
    trophy
  ].freeze

  attr_readonly :assignment_id
  attr_accessor :assignment_changed_not_sub,
                :grade_change_event_author_id,
                :grade_posting_in_progress,
                :grading_error_message,
                :override_lti_id_lock,
                :require_submission_type_is_valid,
                :saved_by,
                :score_unchanged,
                :skip_grade_calc,
                :skip_grader_check,
                :visible_to_user

  # This can be set to true to force late policy behaviour that would
  # be skipped otherwise. See #late_policy_relevant_changes? and
  # #score_late_or_none. It is reset to false in an after save so late
  # policy deductions don't happen again if the submission object is
  # saved again.
  attr_writer :regraded
  attr_writer :audit_grade_changes
  attr_writer :versioned_originality_reports

  belongs_to :attachment # this refers to the screenshot of the submission if it is a url submission
  belongs_to :assignment, inverse_of: :submissions, class_name: "AbstractAssignment"
  belongs_to :course, inverse_of: :submissions
  belongs_to :custom_grade_status, inverse_of: :submissions
  has_many :observer_alerts, as: :context, inverse_of: :context, dependent: :destroy
  has_many :lti_assets, class_name: "Lti::Asset", inverse_of: :submission, dependent: :nullify
  belongs_to :user
  alias_method :student, :user
  belongs_to :grader, class_name: "User"
  belongs_to :proxy_submitter, class_name: "User", optional: true
  belongs_to :grading_period, inverse_of: :submissions
  belongs_to :group
  belongs_to :media_object
  belongs_to :root_account, class_name: "Account"

  belongs_to :quiz_submission, class_name: "Quizzes::QuizSubmission"
  has_many :all_submission_comments, -> { order(:created_at) }, class_name: "SubmissionComment", dependent: :destroy
  has_many :all_submission_comments_for_groups, -> { for_groups.order(:created_at) }, class_name: "SubmissionComment"
  has_many :group_memberships, through: :assignment
  has_many :submission_comments, -> { order(:created_at).where(provisional_grade_id: nil) }
  has_many :visible_submission_comments,
           -> { published.visible.for_final_grade.order(:created_at, :id) },
           class_name: "SubmissionComment"
  has_many :hidden_submission_comments, -> { order("created_at, id").where(provisional_grade_id: nil, hidden: true) }, class_name: "SubmissionComment"
  has_many :assessment_requests, as: :asset
  has_many :assigned_assessments, class_name: "AssessmentRequest", as: :assessor_asset
  has_many :rubric_assessments, as: :artifact
  has_many :attachment_associations, as: :context, inverse_of: :context
  has_many :provisional_grades, class_name: "ModeratedGrading::ProvisionalGrade"
  has_many :originality_reports
  has_one :rubric_assessment,
          lambda {
            joins(:rubric_association)
              .where(assessment_type: "grading")
              .where(rubric_associations: { workflow_state: "active" })
          },
          as: :artifact,
          inverse_of: :artifact
  has_one :lti_result, inverse_of: :submission, class_name: "Lti::Result", dependent: :destroy
  has_many :submission_drafts, inverse_of: :submission, dependent: :destroy

  # we no longer link submission comments and conversations, but we haven't fixed up existing
  # linked conversations so this relation might be useful
  # TODO: remove this when removing the conversationmessage asset columns
  has_many :conversation_messages, as: :asset # one message per private conversation

  has_many :content_participations, as: :content

  has_many :canvadocs_annotation_contexts, inverse_of: :submission, dependent: :destroy
  has_many :canvadocs_submissions

  has_many :auditor_grade_change_records,
           class_name: "Auditors::ActiveRecord::GradeChangeRecord",
           dependent: :destroy,
           inverse_of: :submission

  serialize :turnitin_data, type: Hash

  validates :assignment_id, :user_id, presence: true
  validates :body, length: { maximum: maximum_long_text_length, allow_blank: true }
  validates :published_grade, length: { maximum: maximum_string_length, allow_blank: true }
  validates_as_url :url
  validates :points_deducted, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :seconds_late_override, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :extra_attempts, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :late_policy_status, inclusion: %w[none missing late extended], allow_nil: true
  validates :cached_tardiness, inclusion: ["missing", "late"], allow_nil: true
  validates :sticker, inclusion: { in: VALID_STICKERS }, allow_nil: true
  validate :ensure_grader_can_grade
  validate :extra_attempts_can_only_be_set_on_online_uploads
  validate :ensure_attempts_are_in_range, unless: :proxy_submission?
  validate :submission_type_is_valid, if: :require_submission_type_is_valid
  validate :preserve_lti_id, on: :update

  scope :active, -> { where("submissions.workflow_state <> 'deleted'") }
  scope :deleted, -> { where("submissions.workflow_state = 'deleted'") }
  scope :for_enrollments, ->(enrollments) { where(user_id: enrollments.select(:user_id)) }
  scope :with_comments, -> { preload(:submission_comments) }
  scope :unread_for, lambda { |user_id|
    joins(:content_participations)
      .where(user_id:, content_participations: { workflow_state: "unread", user_id: })
  }
  scope :after, ->(date) { where("submissions.created_at>?", date) }
  scope :before, ->(date) { where("submissions.created_at<?", date) }
  scope :submitted_before, ->(date) { where("submitted_at<?", date) }
  scope :submitted_after, ->(date) { where("submitted_at>?", date) }
  scope :with_point_data, -> { where("submissions.score IS NOT NULL OR submissions.grade IS NOT NULL") }

  scope :postable, lambda {
    all.primary_shard.activate do
      graded.union(with_hidden_comments)
    end
  }
  scope :with_hidden_comments, lambda {
    where(SubmissionComment.where("submission_id = submissions.id AND hidden = true").arel.exists)
  }

  # This should only be used in the course drop down to show assignments recently graded.
  scope :recently_graded_assignments, lambda { |user_id, date, limit|
    select("assignments.id, assignments.title, assignments.points_possible, assignments.due_at,
            submissions.grade, submissions.score, submissions.graded_at, assignments.grading_type,
            assignments.context_id, assignments.context_type, courses.name AS context_name")
      .joins(:assignment)
      .joins("JOIN #{Course.quoted_table_name} ON courses.id=assignments.context_id")
      .where("graded_at>? AND user_id=? AND muted=?", date, user_id, false)
      .order("graded_at DESC")
      .limit(limit)
  }

  scope :for_course, ->(course) { where(course_id: course) }
  scope :for_assignment, ->(assignment) { where(assignment:) }

  scope :excused, -> { where(excused: true) }

  scope :missing, lambda {
    joins(:assignment)
      .where(<<~SQL.squish)
        /* excused submissions cannot be missing */
        excused IS NOT TRUE
        AND custom_grade_status_id IS NULL
        AND (late_policy_status IS DISTINCT FROM 'extended')
        AND NOT (
          /* teacher said it's missing, 'nuff said. */
          /* we're doing a double 'NOT' here to avoid 'ORs' that could slow down the query */
          late_policy_status IS DISTINCT FROM 'missing' AND NOT
          (
            cached_due_date IS NOT NULL
            /* submission is past due and */
            AND CURRENT_TIMESTAMP >= cached_due_date +
              CASE assignments.submission_types WHEN 'online_quiz' THEN interval '1 minute' ELSE interval '0 minutes' END
            /* submission is not submitted and */
            AND submission_type IS NULL
            /* we expect a digital submission */
            AND NOT (
              cached_quiz_lti IS NOT TRUE AND
              assignments.submission_types IN ('', 'none', 'not_graded', 'on_paper', 'wiki_page', 'external_tool')
            )
            AND assignments.submission_types IS NOT NULL
            AND NOT (
              late_policy_status IS NULL
              AND grader_id IS NOT NULL
            )
          )
        )
      SQL
  }

  scope :late, lambda {
    left_joins(:quiz_submission).where(<<~SQL.squish)
      submissions.excused IS NOT TRUE
      AND submissions.custom_grade_status_id IS NULL
      AND (
        submissions.late_policy_status = 'late' OR
        (submissions.late_policy_status IS NULL AND submissions.submitted_at >= submissions.cached_due_date +
           CASE submissions.submission_type WHEN 'online_quiz' THEN interval '1 minute' ELSE interval '0 minutes' END
           AND (submissions.quiz_submission_id IS NULL OR quiz_submissions.workflow_state = 'complete'))
      )
    SQL
  }

  scope :not_late, lambda {
    left_joins(:quiz_submission).where(<<~SQL.squish)
      submissions.excused IS TRUE
      OR submissions.custom_grade_status_id IS NOT NULL
      OR (late_policy_status IS NOT DISTINCT FROM 'extended')
      OR (
        submissions.late_policy_status is distinct from 'late' AND
        (submissions.submitted_at IS NULL OR submissions.cached_due_date IS NULL OR
          submissions.submitted_at < submissions.cached_due_date +
            CASE submissions.submission_type WHEN 'online_quiz' THEN interval '1 minute' ELSE interval '0 minutes' END
          OR quiz_submissions.workflow_state <> 'complete')
      )
    SQL
  }

  GradedAtBookmarker = BookmarkedCollection::SimpleBookmarker.new(Submission, :graded_at)
  IdBookmarker = BookmarkedCollection::SimpleBookmarker.new(Submission, :id)

  scope :anonymized, -> { where.not(anonymous_id: nil) }
  scope :due_in_past, -> { where(cached_due_date: ..Time.now.utc) }

  scope :posted, -> { where.not(posted_at: nil) }
  scope :unposted, -> { where(posted_at: nil) }

  scope :in_current_grading_period_for_courses, lambda { |course_ids|
    current_period_clause = ""
    course_ids.uniq.each_with_index do |course_id, i|
      grading_period_id = GradingPeriod.current_period_for(Course.find(course_id))&.id
      current_period_clause += grading_period_id.nil? ? sanitize_sql(["course_id = ?", course_id]) : sanitize_sql(["(course_id = ? AND grading_period_id = ?)", course_id, grading_period_id])
      current_period_clause += " OR " if i < course_ids.length - 1
    end
    where(current_period_clause)
  }

  workflow do
    state :submitted do
      event :grade_it, transitions_to: :graded
    end
    state :unsubmitted
    state :pending_review
    state :graded
    state :deleted
  end
  alias_method :needs_review?, :pending_review?

  delegate :auditable?, to: :assignment, prefix: true
  delegate :can_be_moderated_grader?, to: :assignment, prefix: true

  def self.anonymous_ids_for(assignment)
    anonymized.for_assignment(assignment).pluck(:anonymous_id)
  end

  # see #needs_grading?
  # When changing these conditions, update index_submissions_needs_grading to
  # maintain performance.
  def self.needs_grading_conditions
    <<~SQL.squish
      submissions.submission_type IS NOT NULL
      AND (submissions.excused=false OR submissions.excused IS NULL)
      AND (submissions.workflow_state = 'pending_review'
        OR (submissions.workflow_state IN ('submitted', 'graded')
          AND (submissions.score IS NULL OR submissions.grade_matches_current_submission =  'f')
        )
      )
    SQL
  end

  # see .needs_grading_conditions
  def needs_grading?(was = false)
    suffix = was ? "_before_last_save" : ""

    !send(:"submission_type#{suffix}").nil? &&
      (send(:"workflow_state#{suffix}") == "pending_review" ||
       (["submitted", "graded"].include?(send(:"workflow_state#{suffix}")) &&
        (send(:"score#{suffix}").nil? || !send(:"grade_matches_current_submission#{suffix}"))
       )
      )
  end

  def checkpoints_needs_grading?
    return false if assignment.nil?
    return false unless assignment.checkpoints_parent?

    Submission.active.having_submission.where(user_id:)
              .where(assignment_id: SubAssignment.select(:id).where(parent_assignment_id: assignment_id))
              .find_each do |sub_assignment_submission|
      return true if sub_assignment_submission.needs_grading?
    end
    false
  end

  def proxy_submission?
    proxy_submitter.present?
  end

  def resubmitted?
    needs_grading? && grade_matches_current_submission == false
  end

  def needs_grading_changed?
    needs_grading? != needs_grading?(:was)
  end

  def submitted_changed?
    submitted? != %w[submitted pending_review graded].include?(send(:workflow_state_before_last_save))
  end

  def graded_changed?
    graded? != (send(:workflow_state_before_last_save) == "graded")
  end

  scope :needs_grading, lambda {
    all.primary_shard.activate do
      joins(:assignment)
        .joins("INNER JOIN #{Enrollment.quoted_table_name} ON submissions.user_id=enrollments.user_id
                                                         AND assignments.context_id = enrollments.course_id")
        .where(needs_grading_conditions)
        .where(Enrollment.active_student_conditions)
        .distinct
    end
  }

  scope :needs_grading_count, lambda {
    select("COUNT(submissions.id)")
      .needs_grading
  }

  sanitize_field :body, CanvasSanitize::SANITIZE

  # Because set_anonymous_id makes database calls, delay it until just before
  # validation. Otherwise if we place it in any earlier (e.g.
  # before/after_initialize), every Submission.new will make database calls.
  before_validation :set_anonymous_id, if: :new_record?
  before_save :set_status_attributes
  before_save :apply_late_policy, if: :late_policy_relevant_changes?
  before_save :update_if_pending
  before_save :validate_single_submission, :infer_values
  before_save :prep_for_submitting_to_plagiarism
  before_save :check_is_new_attempt
  before_save :check_reset_graded_anonymously
  before_save :set_root_account_id
  before_save :reset_redo_request
  before_save :remove_sticker, if: :will_save_change_to_attempt?
  before_save :clear_body_word_count, if: -> { body.nil? }
  before_save :set_lti_id
  after_save :update_body_word_count_later, if: -> { saved_change_to_body? && get_word_count_from_body? }
  after_save :touch_user
  after_save :clear_user_submissions_cache
  after_save :touch_graders
  after_save :update_assignment
  after_save :update_attachment_associations
  after_save :submit_attachments_to_canvadocs
  after_save :queue_websnap
  after_save :aggregate_checkpoint_submissions, if: :checkpoint_changes?
  after_save :update_final_score
  after_save :submit_to_plagiarism_later
  after_save :update_admins_if_just_submitted
  after_save :check_for_media_object
  after_save :update_quiz_submission
  after_save :update_participation
  after_save :update_line_item_result
  after_save :delete_ignores
  after_save :create_alert
  after_save :reset_regraded
  after_save :create_audit_event!
  after_save :handle_posted_at_changed, if: :saved_change_to_posted_at?
  after_save :delete_submission_drafts!, if: :saved_change_to_attempt?
  after_save :send_timing_data_if_needed

  def reset_regraded
    @regraded = false
  end

  def autograded?
    # AutoGrader == (quiz_id * -1)
    !!(grader_id && grader_id < 0)
  end

  after_create :needs_grading_count_updated, if: :needs_grading?
  after_update :needs_grading_count_updated, if: :needs_grading_changed?
  after_update :update_planner_override
  def needs_grading_count_updated
    self.class.connection.after_transaction_commit do
      assignment.clear_cache_key(:needs_grading)
    end
  end

  after_create :assignment_submission_count_updated, if: :submitted?
  after_update :assignment_submission_count_updated, if: :submitted_changed?
  def assignment_submission_count_updated
    self.class.connection.after_transaction_commit do
      Rails.cache.delete(["submitted_count", assignment].cache_key)
    end
  end

  after_create :assignment_graded_count_updated, if: :graded?
  after_update :assignment_graded_count_updated, if: :graded_changed?
  def assignment_graded_count_updated
    self.class.connection.after_transaction_commit do
      Rails.cache.delete(["graded_count", assignment].cache_key)
    end
  end

  def update_planner_override
    return unless saved_change_to_workflow_state?

    if submission_type == "online_quiz" && workflow_state == "graded"
      # unless it's an auto-graded quiz
      return unless workflow_state_before_last_save == "unsubmitted"
    else
      return unless workflow_state == "submitted"
    end
    PlannerHelper.complete_planner_override_for_submission(self)
  end

  attr_reader :group_broadcast_submission

  has_a_broadcast_policy

  simply_versioned explicit: true,
                   when: ->(model) { model.new_version_needed? },
                   on_create: ->(_model, version) { SubmissionVersion.index_version(version) },
                   on_load: ->(model, version) { model&.cached_due_date = version.versionable&.cached_due_date }

  # This needs to be after simply_versioned because the grade change audit uses
  # versioning to grab the previous grade.
  after_save :grade_change_audit

  def new_version_needed?
    turnitin_data_changed? || vericite_data_changed? || (changes.keys - %w[
      updated_at
      posted_at
      processed
      grade_matches_current_submission
      published_score
      published_grade
      lti_id
    ]).present?
  end

  set_policy do
    given do |user|
      user &&
        user.id == user_id &&
        assignment.published?
    end
    can :read and can :make_group_comment and can :submit and can :mark_item_read and can :read_comments

    # non-deleted students in accounts with limited access setting enabled should not be able to comment on submissions
    given do |user|
      user &&
        user.id == user_id &&
        assignment.published? &&
        !course.account.limited_access_for_user?(user)
    end
    can :comment

    # see user_can_read_grade? before editing :read_grade permissions
    given do |user|
      user &&
        user.id == user_id &&
        !hide_grade_from_student?
    end
    can :read_grade

    given do |user, session|
      assignment.published? &&
        assignment.context.grants_right?(user, session, :manage_grades)
    end
    can :read and can :comment and can :make_group_comment and can :read_grade and can :read_comments

    given do |user, _session|
      can_grade?(user)
    end
    can :grade

    given do |user, session|
      assignment.user_can_read_grades?(user, session)
    end
    can :read and can :read_grade

    given do |user|
      assignment&.context &&
        user &&
        self.user &&
        assignment.context.observer_enrollments.where(
          user_id: user,
          associated_user_id: self.user,
          workflow_state: "active"
        ).exists?
    end
    can :read and can :read_comments

    given do |user|
      assignment &&
        posted? &&
        assignment.context &&
        user &&
        self.user &&
        assignment.context.observer_enrollments.where(
          user_id: user,
          associated_user_id: self.user,
          workflow_state: "active"
        ).first.try(:grants_right?, user, :read_grades)
    end
    can :read_grade

    given { |user| peer_reviewer?(user) && !!assignment&.submitted?(user:) }
    can :read and can :comment and can :make_group_comment

    given { |user, session| can_view_plagiarism_report("turnitin", user, session) }
    can :view_turnitin_report

    given { |user, session| can_view_plagiarism_report("vericite", user, session) }
    can :view_vericite_report
  end

  def observer?(user)
    assignment.context.observer_enrollments.where(
      user_id: user.id,
      associated_user_id: user_id,
      workflow_state: "active"
    ).exists?
  end

  def peer_reviewer?(user)
    assignment.published? &&
      assignment.peer_reviews &&
      assignment.context.participating_students.where(id: self.user).exists? &&
      user &&
      assessment_requests.map(&:assessor_id).include?(user.id)
  end

  def can_view_details?(user)
    return false unless grants_right?(user, :read)
    return true unless assignment.anonymize_students?

    user == self.user || peer_reviewer?(user) || observer?(user) || Account.site_admin.grants_right?(user, :update)
  end

  def can_view_plagiarism_report(type, user, session)
    if type == "vericite"
      return false unless vericite_data_hash[:provider].to_s == "vericite"

      plagData = vericite_data_hash
      @submit_to_vericite = false
      settings = assignment.vericite_settings
      type_can_peer_review = true
    else
      unless vericite_data_hash[:provider].to_s != "vericite" ||
             AssignmentConfigurationToolLookup.where(assignment_id:).where.not(tool_product_code: "vericite").exists?
        return false
      end

      plagData = turnitin_data
      @submit_to_turnitin = false
      settings = assignment.turnitin_settings
      type_can_peer_review = false
    end
    plagData &&
      (user_can_read_grade?(user, session, for_plagiarism: true) || (type_can_peer_review && user_can_peer_review_plagiarism?(user))) &&
      (assignment.context.grants_any_right?(user, session, :manage_grades, :view_all_grades) ||
        case settings[:originality_report_visibility]
        when "immediate" then true
        when "after_grading" then current_submission_graded?
        when "after_due_date"
          assignment.due_at && assignment.due_at < Time.now.utc
        when "never" then false
        end
      )
  end

  def user_can_peer_review_plagiarism?(user)
    assignment.peer_reviews &&
      assignment.current_submissions_and_assessors[:submissions].select do |submission|
        # first filter by submissions for the requested reviewer
        user.id == submission.user_id &&
          submission.assigned_assessments
      end.any? do |submission|
        # next filter the assigned assessments by the submission user_id being reviewed
        submission.assigned_assessments.any? { |review| user_id == review.user_id }
      end
  end

  def user_can_read_grade?(user, session = nil, for_plagiarism: false)
    # improves performance by checking permissions on the assignment before the submission
    return true if assignment.user_can_read_grades?(user, session)
    return false if hide_grade_from_student?(for_plagiarism:)
    return true if user && user.id == user_id # this is fast, so skip the policy cache check if possible

    grants_right?(user, session, :read_grade)
  end

  on_update_send_to_streams do
    if graded_at && graded_at > 5.minutes.ago && !@already_sent_to_stream
      @already_sent_to_stream = true
      user_id
    end
  end

  def can_read_submission_user_name?(user, session)
    return false if user_id != user.id && assignment.anonymize_students?

    !assignment.anonymous_peer_reviews? ||
      user_id == user.id ||
      assignment.context.grants_right?(user, session, :view_all_grades)
  end

  def update_final_score
    if saved_change_to_score? || saved_change_to_excused? ||
       (workflow_state_before_last_save == "pending_review" && workflow_state == "graded")
      unless skip_grade_calc
        self.class.connection.after_transaction_commit do
          Enrollment.recompute_final_score_in_singleton(
            user_id,
            context.id,
            grading_period_id:
          )
        end
      end

      unless ConditionalRelease::Rule.is_trigger_assignment?(assignment)
        # trigger assignments have to wait for ConditionalRelease::OverrideHandler#handle_grade_change
        assignment&.delay_if_production&.multiple_module_actions([user_id], :scored, score)
      end
    end
    true
  end

  def create_alert
    return unless saved_change_to_score? && grader_id && !autograded? &&
                  assignment.points_possible && assignment.points_possible > 0

    thresholds = ObserverAlertThreshold.active.where(student: user,
                                                     alert_type: ["assignment_grade_high", "assignment_grade_low"])

    thresholds.each do |threshold|
      prev_score = saved_changes["score"][0]
      prev_percentage = prev_score.present? ? prev_score.to_f / assignment.points_possible * 100 : nil
      percentage = score.present? ? score.to_f / assignment.points_possible * 100 : nil
      next unless threshold.did_pass_threshold(prev_percentage, percentage)

      observer = threshold.observer
      next unless observer
      next unless observer.observer_enrollments.active
                          .where(course_id: assignment.context_id, associated_user: user).any?

      begin
        ObserverAlert.create!(
          observer:,
          student: user,
          observer_alert_threshold: threshold,
          context: assignment,
          alert_type: threshold.alert_type,
          action_date: graded_at,
          title: I18n.t("Assignment graded: %{grade} on %{assignment_name} in %{course_code}",
                        {
                          grade:,
                          assignment_name: assignment.title,
                          course_code: assignment.course.course_code
                        })
        )
      rescue ActiveRecord::RecordInvalid
        Rails.logger.error(
          "Couldn't create ObserverAlert for submission #{id} observer #{threshold.observer_id}"
        )
      end
    end
  end

  def update_quiz_submission
    return true if @saved_by == :quiz_submission || !quiz_submission_id || entered_score == quiz_submission.kept_score

    quiz_submission.set_final_score(score)
    true
  end

  def url
    read_body = body && CGI.unescapeHTML(body)
    @full_url = if read_body && (url = super) && read_body[0..250] == url[0..250]
                  body
                else
                  super
                end
  end

  def plaintext_body
    extend HtmlTextHelper
    strip_tags((body || "").gsub(%r{<\s*br\s*/>}, "\n<br/>").gsub(%r{</p>}, "</p>\n"))
  end

  TURNITIN_STATUS_RETRY = 11
  def check_turnitin_status(attempt = 1)
    self.turnitin_data ||= {}
    turnitin = nil
    needs_retry = false

    # check all assets in the turnitin_data (self.turnitin_assets is only the
    # current assets) so that we get the status for assets of previous versions
    # of the submission as well
    self.turnitin_data.each_key do |asset_string|
      data = self.turnitin_data[asset_string]
      next unless data.is_a?(Hash) && data[:object_id]

      if data[:similarity_score].blank?
        if attempt < TURNITIN_STATUS_RETRY
          turnitin ||= Turnitin::Client.new(*context.turnitin_settings)
          res = turnitin.generateReport(self, asset_string)
          if res[:similarity_score]
            data[:similarity_score] = res[:similarity_score].to_f
            data[:web_overlap] = res[:web_overlap].to_f
            data[:publication_overlap] = res[:publication_overlap].to_f
            data[:student_overlap] = res[:student_overlap].to_f
            data[:state] = Turnitin.state_from_similarity_score data[:similarity_score]
            data[:status] = "scored"
          else
            needs_retry ||= true
          end
        else
          data[:status] = "error"
          data[:public_error_message] = I18n.t("turnitin.no_score_after_retries", "Turnitin has not returned a score after %{max_tries} attempts to retrieve one.", max_tries: TURNITIN_RETRY)
        end
      else
        data[:status] = "scored"
      end
      self.turnitin_data[asset_string] = data
    end

    delay(run_at: (2**attempt).minutes.from_now).check_turnitin_status(attempt + 1) if needs_retry
    turnitin_data_changed!
    save
  end

  def turnitin_report_url(asset_string, user)
    if self.turnitin_data && self.turnitin_data[asset_string] && self.turnitin_data[asset_string][:similarity_score]
      turnitin = Turnitin::Client.new(*context.turnitin_settings)
      delay.check_turnitin_status
      if grants_right?(user, :grade)
        turnitin.submissionReportUrl(self, asset_string)
      elsif grants_right?(user, :view_turnitin_report)
        turnitin.submissionStudentReportUrl(self, asset_string)
      end
    else
      nil
    end
  end

  TURNITIN_JOB_OPTS = { n_strand: "turnitin", priority: Delayed::LOW_PRIORITY, max_attempts: 2 }.freeze

  TURNITIN_RETRY = 5
  def submit_to_turnitin(attempt = 0)
    return unless turnitinable? && context.turnitin_settings

    turnitin = Turnitin::Client.new(*context.turnitin_settings)
    reset_turnitin_assets

    # Make sure the assignment exists and user is enrolled
    assignment_created = assignment.create_in_turnitin
    turnitin_enrollment = turnitin.enrollStudent(context, user)
    if assignment_created && turnitin_enrollment.success?
      delete_turnitin_errors
    else
      if attempt < TURNITIN_RETRY
        delay(run_at: 5.minutes.from_now, **TURNITIN_JOB_OPTS).submit_to_turnitin(attempt + 1)
      else
        assignment_error = assignment.turnitin_settings[:error]
        self.turnitin_data[:status] = "error"
        self.turnitin_data[:assignment_error] = assignment_error if assignment_error.present?
        self.turnitin_data[:student_error] = turnitin_enrollment.error_hash if turnitin_enrollment.error?
        turnitin_data_changed!
        save
      end
      return false
    end

    # Submit the file(s)
    submission_response = turnitin.submitPaper(self)
    submission_response.each do |res_asset_string, response|
      self.turnitin_data[res_asset_string].merge!(response)
      turnitin_data_changed!
      if !response[:object_id] && attempt >= TURNITIN_RETRY
        self.turnitin_data[res_asset_string][:status] = "error"
      end
    end

    delay(run_at: 5.minutes.from_now, **TURNITIN_JOB_OPTS).check_turnitin_status
    save

    # Schedule retry if there were failures
    submit_status = submission_response.present? && submission_response.values.all? { |v| v[:object_id] }
    unless submit_status
      delay(run_at: 5.minutes.from_now, **TURNITIN_JOB_OPTS).submit_to_turnitin(attempt + 1) if attempt < TURNITIN_RETRY
      return false
    end

    true
  end

  # This method pulls data from the OriginalityReport table
  # Preload OriginalityReport before using this method in a collection of submissions
  def originality_data
    data = originality_reports_for_display.each_with_object({}) do |originality_report, hash|
      hash[originality_report.asset_key] = {
        similarity_score: originality_report.originality_score&.round(2),
        state: originality_report.state,
        attachment_id: originality_report.attachment_id,
        report_url: originality_report.report_launch_path(assignment),
        status: originality_report.workflow_state,
        error_message: originality_report.error_message,
        created_at: originality_report.created_at,
        updated_at: originality_report.updated_at,
      }
    end
    turnitin_data.except(:webhook_info, :provider, :last_processed_attempt).merge(data)
  end

  # Returns an array of the versioned originality reports in a sorted order. The ordering goes
  # from least preferred report to most preferred reports, assuming there are reports that share
  # the same submission and attachment combination. Otherwise, the ordering can be safely ignored.
  #
  # @return [Array<OriginalityReport>]
  def originality_reports_for_display
    versioned_originality_reports.uniq.sort_by do |report|
      [OriginalityReport::ORDERED_VALID_WORKFLOW_STATES.index(report.workflow_state) || -1, report.updated_at]
    end
  end

  def turnitin_assets
    case submission_type
    when "online_upload"
      attachments.select(&:turnitinable?)
    when "online_text_entry"
      [self]
    else
      []
    end
  end

  # Preload OriginalityReport before using this method
  def originality_report_url(asset_string, user, attempt = nil)
    return unless grants_right?(user, :view_turnitin_report)

    version_sub = if attempt.present?
                    (attempt.to_i == self.attempt) ? self : versions.find { |v| v.model&.attempt == attempt.to_i }&.model
                  end
    requested_attachment = all_versioned_attachments.find_by_asset_string(asset_string) unless asset_string == self.asset_string
    scope = association(:originality_reports).loaded? ? versioned_originality_reports : originality_reports
    scope = scope.where(submission_time: version_sub.submitted_at) if version_sub
    # This ordering ensures that if multiple reports exist for this submission and attachment combo,
    # we grab the desired report. This is the reversed ordering of
    # OriginalityReport::PREFERRED_STATE_ORDER
    report = scope.where(attachment: requested_attachment).order(Arel.sql("CASE
      WHEN workflow_state = 'scored' THEN 0
      WHEN workflow_state = 'error' THEN 1
      WHEN workflow_state = 'pending' THEN 2
      END"),
                                                                 updated_at: :desc).first
    report&.report_launch_path(assignment)
  end

  def has_originality_report?
    versioned_originality_reports.present?
  end

  def audit_events
    AuditEventService.new(self).call
  end

  def enriched_audit_events
    AuditEventService.new(self).enrich(audit_events)
  end

  def all_versioned_attachments
    attachment_ids = submission_history.map(&:attachment_ids_for_version).flatten.uniq
    Attachment.where(id: attachment_ids)
  end
  private :all_versioned_attachments

  def attachment_ids_for_version
    ids = (attachment_ids || "").split(",").map(&:to_i)
    ids << attachment_id if attachment_id
    ids
  end

  def delete_turnitin_errors
    self.turnitin_data.delete(:status)
    self.turnitin_data.delete(:assignment_error)
    self.turnitin_data.delete(:student_error)
  end
  private :delete_turnitin_errors

  def reset_turnitin_assets
    self.turnitin_data ||= {}
    delete_turnitin_errors
    turnitin_assets.each do |a|
      asset_data = self.turnitin_data[a.asset_string] || {}
      asset_data[:status] = "pending"
      %i[error_code error_message public_error_message].each do |key|
        asset_data.delete(key)
      end
      self.turnitin_data[a.asset_string] = asset_data
      turnitin_data_changed!
    end
  end

  def resubmit_to_turnitin
    reset_turnitin_assets
    save

    @submit_to_turnitin = true
    turnitinable_by_lti? ? retrieve_lti_tii_score : submit_to_plagiarism_later
  end

  def retrieve_lti_tii_score
    if (tool = Lti::ToolFinder.from_assignment(assignment))
      turnitin_data.select { |_, v| v.try(:key?, :outcome_response) }.each do |k, v|
        Turnitin::OutcomeResponseProcessor.new(tool, assignment, user, v[:outcome_response].as_json).resubmit(self, k)
      end
    end
  end

  def turnitinable?
    %w[online_upload online_text_entry].include?(submission_type) &&
      assignment.turnitin_enabled?
  end

  def turnitinable_by_lti?
    turnitin_data.any? { |_, v| v.is_a?(Hash) && v.key?(:outcome_response) }
  end

  # VeriCite

  # this function will check if the score needs to be updated and update/save the new score if so,
  # otherwise, it just returns the vericite_data_hash
  def vericite_data(lookup_data = false)
    self.vericite_data_hash ||= {}
    # check to see if the score is stale, if so, fetch it again
    update_scores = false
    if Canvas::Plugin.find(:vericite).try(:enabled?) && !readonly? && lookup_data
      self.vericite_data_hash.each_value do |data|
        next unless data.is_a?(Hash) && data[:object_id]

        update_scores ||= vericite_recheck_score(data)
      end
      # we have found at least one score that is stale, call VeriCite and save the results
      if update_scores
        check_vericite_status(0)
      end
    end
    unless self.vericite_data_hash.empty?
      # only set vericite provider flag if the hash isn't empty
      self.vericite_data_hash[:provider] = :vericite
    end
    self.vericite_data_hash
  end

  def vericite_data_hash
    # use the same backend structure to store "content review" data
    self.turnitin_data
  end

  # this function looks at a vericite data object and determines whether the score needs to be rechecked (i.e. cache for 20 mins)
  def vericite_recheck_score(data)
    update_scores = false
    # only recheck scores if an old score exists
    unless data[:similarity_score_time].blank?
      now = Time.now.to_i
      score_age = Time.now.to_i - data[:similarity_score_time]
      score_cache_time = 1200 # by default cache scores for 20 mins
      # change the cache based on how long it has been since the paper was submitted
      # if !data[:submit_time].blank? && (now - data[:submit_time]) > 86400
      # # it has been more than 24 hours since this was submitted, increase cache time
      #   score_cache_time = 86400
      # end
      # only cache the score for 20 minutes or 24 hours based on when the paper was submitted
      if score_age > score_cache_time
        # check if we just recently requested this score
        last_checked = 1000 # default to a high number so that if it is not set, it won't effect the outcome
        unless data[:similarity_score_check_time].blank?
          last_checked = now - data[:similarity_score_check_time]
        end
        # only update if we didn't just ask VeriCite for the scores 20 seconds again (this is in the case of an error, we don't want to keep asking immediately)
        if last_checked > 20
          update_scores = true
        end
      end
    end
    update_scores
  end

  VERICITE_STATUS_RETRY = 16 # this caps the retries off at 36 hours (checking once every 4 hours)

  def check_vericite_status(attempt = 1)
    self.vericite_data_hash ||= {}
    vericite = nil
    needs_retry = false
    # check all assets in the vericite_data (self.vericite_assets is only the
    # current assets) so that we get the status for assets of previous versions
    # of the submission as well

    # flag to make sure that all scores are just updates and not new
    recheck_score_all = true
    data_changed = false
    self.vericite_data_hash.each do |asset_string, data|
      # keep track whether the score state changed
      data_orig = data.dup
      next unless data.is_a?(Hash) && data[:object_id]

      # check to see if the score is stale, if so, delete it and fetch again
      recheck_score = vericite_recheck_score(data)
      # keep track whether all scores are updates or if any are new
      recheck_score_all &&= recheck_score
      # look up scores if:
      if recheck_score || data[:similarity_score].blank?
        if attempt < VERICITE_STATUS_RETRY
          data[:similarity_score_check_time] = Time.now.to_i
          vericite ||= VeriCite::Client.new
          res = vericite.generateReport(self, asset_string)
          if res[:similarity_score]
            # keep track of when we updated the score so that we can ask VC again once it is stale (i.e. cache for 20 mins)
            data[:similarity_score_time] = Time.now.to_i
            data[:similarity_score] = res[:similarity_score].to_i
            data[:state] = VeriCite.state_from_similarity_score data[:similarity_score]
            data[:status] = "scored"
            # since we have a score, we know this report shouldn't have any errors, clear them out
            data = clear_vericite_errors(data)
          else
            needs_retry ||= true
          end
        elsif !recheck_score # if we already have a score, continue to use it and do not set an error
          data[:status] = "error"
          data[:public_error_message] = I18n.t("vericite.no_score_after_retries", "VeriCite has not returned a score after %{max_tries} attempts to retrieve one.", max_tries: VERICITE_RETRY)
        end
      else
        data[:status] = "scored"
      end
      self.vericite_data_hash[asset_string] = data
      data_changed = data_changed ||
                     data_orig[:similarity_score] != data[:similarity_score] ||
                     data_orig[:state] != data[:state] ||
                     data_orig[:status] != data[:status] ||
                     data_orig[:public_error_message] != data[:public_error_message]
    end

    if !self.vericite_data_hash.empty? && self.vericite_data_hash[:provider].nil?
      # only set vericite provider flag if the hash isn't empty
      self.vericite_data_hash[:provider] = :vericite
      data_changed = true
    end
    retry_mins = 2**attempt
    if retry_mins > 240
      # cap the retry max wait to 4 hours
      retry_mins = 240
    end
    # if attempt <= 0, then that means no retries should be attempted
    delay(run_at: retry_mins.minutes.from_now).check_vericite_status(attempt + 1) if attempt > 0 && needs_retry
    # if all we did was recheck scores, do not version this save (i.e. increase the attempt number)
    if data_changed
      vericite_data_changed!
      if recheck_score_all
        with_versioning(false, &:save!)
      else
        save
      end
    end
  end

  def vericite_report_url(asset_string, user, session)
    if self.vericite_data_hash && self.vericite_data_hash[asset_string] && self.vericite_data_hash[asset_string][:similarity_score]
      vericite = VeriCite::Client.new
      if grants_right?(user, :grade)
        vericite.submissionReportUrl(self, user, asset_string)
      elsif can_view_plagiarism_report("vericite", user, session)
        vericite.submissionStudentReportUrl(self, user, asset_string)
      end
    else
      nil
    end
  end

  VERICITE_JOB_OPTS = { n_strand: "vericite", priority: Delayed::LOW_PRIORITY, max_attempts: 2 }.freeze

  VERICITE_RETRY = 5
  def submit_to_vericite(attempt = 0)
    Rails.logger.info("VERICITE #submit_to_vericite submission ID: #{id}, vericiteable? #{vericiteable?}")
    if vericiteable?
      Rails.logger.info("VERICITE #submit_to_vericite submission ID: #{id}, plugin: #{Canvas::Plugin.find(:vericite)}, vericite plugin enabled? #{Canvas::Plugin.find(:vericite).try(:enabled?)}")
    end
    return unless vericiteable? && Canvas::Plugin.find(:vericite).try(:enabled?)

    vericite = VeriCite::Client.new
    reset_vericite_assets

    # Make sure the assignment exists and user is enrolled
    assignment_created = assignment.create_in_vericite
    # vericite_enrollment = vericite.enrollStudent(self.context, self.user)
    if assignment_created
      delete_vericite_errors
    else
      assignment_error = assignment.vericite_settings[:error]
      self.vericite_data_hash[:assignment_error] = assignment_error if assignment_error.present?
      # self.vericite_data_hash[:student_error] = vericite_enrollment.error_hash if vericite_enrollment.error?
      vericite_data_changed!
      unless self.vericite_data_hash.empty?
        # only set vericite provider flag if the hash isn't empty
        self.vericite_data_hash[:provider] = :vericite
      end
      save
    end
    # even if the assignment didn't save, VeriCite will still allow this file to be submitted
    # Submit the file(s)
    submission_response = vericite.submitPaper(self)
    # VeriCite will not resubmit a file if it already has a similarity_score (i.e. success)
    update = false
    submission_response.each do |res_asset_string, response|
      update = true
      self.vericite_data_hash[res_asset_string].merge!(response)
      # keep track of when we first submitted
      self.vericite_data_hash[res_asset_string][:submit_time] = Time.now.to_i if self.vericite_data_hash[res_asset_string][:submit_time].blank?
      vericite_data_changed!
      if !response[:object_id] && attempt >= VERICITE_RETRY
        self.vericite_data_hash[res_asset_string][:status] = "error"
      elsif response[:object_id]
        # success, make sure any error messages are cleared
        self.vericite_data_hash[res_asset_string] = clear_vericite_errors(self.vericite_data_hash[res_asset_string])
      end
    end
    # only save if there were newly submitted attachments
    if update
      delay(run_at: 5.minutes.from_now, **VERICITE_JOB_OPTS).check_vericite_status
      unless self.vericite_data_hash.empty?
        # only set vericite provider flag if the hash isn't empty
        self.vericite_data_hash[:provider] = :vericite
      end
      save

      # Schedule retry if there were failures
      submit_status = submission_response.present? && submission_response.values.all? { |v| v[:object_id] }
      unless submit_status
        delay(run_at: 5.minutes.from_now, **VERICITE_JOB_OPTS).submit_to_vericite(attempt + 1) if attempt < VERICITE_RETRY
        return false
      end
    end

    true
  end

  def vericite_assets
    case submission_type
    when "online_upload"
      attachments.select(&:vericiteable?)
    when "online_text_entry"
      [self]
    else
      []
    end
  end

  def delete_vericite_errors
    self.vericite_data_hash.delete(:status)
    self.vericite_data_hash.delete(:assignment_error)
    self.vericite_data_hash.delete(:student_error)
  end
  private :delete_vericite_errors

  def reset_vericite_assets
    self.vericite_data_hash ||= {}
    delete_vericite_errors
    vericite_assets.each do |a|
      asset_data = self.vericite_data_hash[a.asset_string] || {}
      asset_data[:status] = "pending"
      asset_data = clear_vericite_errors(asset_data)
      self.vericite_data_hash[a.asset_string] = asset_data
      vericite_data_changed!
    end
  end

  def clear_vericite_errors(asset_data)
    %i[error_code error_message public_error_message].each do |key|
      asset_data.delete(key)
    end
    asset_data
  end

  def submission_type_is_valid
    case submission_type
    when "online_text_entry"
      if body.blank?
        errors.add(:body, "Text entry submission cannot be empty")
      end
    when "online_url"
      if url.blank?
        errors.add(:url, "URL entry submission cannot be empty")
      end
    end
  end

  def resubmit_to_vericite
    reset_vericite_assets
    unless self.vericite_data_hash.empty?
      # only set vericite provider flag if the hash isn't empty
      self.vericite_data_hash[:provider] = :vericite
    end

    @submit_to_vericite = true
    save
  end

  def vericiteable?
    %w[online_upload online_text_entry].include?(submission_type) &&
      assignment.vericite_enabled?
  end

  def vericite_data_changed!
    @vericite_data_changed = true
  end

  def vericite_data_changed?
    @vericite_data_changed
  end

  # End VeriCite

  # Plagiarism functions:

  def plagiarism_service_to_use
    return @plagiarism_service_to_use if defined? @plagiarism_service_to_use

    # Because vericite is new and people are moving to vericite, not
    # moving from vericite to turnitin, we'll give vericite precedence
    # for now.
    @plagiarism_service_to_use = if Canvas::Plugin.find(:vericite).try(:enabled?)
                                   :vericite
                                 elsif !context.turnitin_settings.nil?
                                   :turnitin
                                 end
  end

  def prep_for_submitting_to_plagiarism
    return unless plagiarism_service_to_use

    if plagiarism_service_to_use == :vericite
      plagData = self.vericite_data_hash
      @submit_to_vericite = false
      canSubmit = vericiteable?
    else
      plagData = self.turnitin_data
      @submit_to_turnitin = false
      canSubmit = turnitinable?
    end
    last_attempt = plagData && plagData[:last_processed_attempt]
    Rails.logger.info("#prep_for_submitting_to_plagiarism submission ID: #{id}, type: #{plagiarism_service_to_use}, canSubmit? #{canSubmit}")
    Rails.logger.info("#prep_for_submitting_to_plagiarism submission ID: #{id}, last_attempt: #{last_attempt}, self.attempt: #{attempt}, @group_broadcast_submission: #{@group_broadcast_submission}, self.group: #{group}")
    if canSubmit && (!last_attempt || last_attempt < attempt) && (@group_broadcast_submission || !group)
      if plagData[:last_processed_attempt] != attempt
        plagData[:last_processed_attempt] = attempt
      end
      if plagiarism_service_to_use == :vericite
        @submit_to_vericite = true
      else
        @submit_to_turnitin = true
      end
    end
  end

  def submit_to_plagiarism_later
    return unless plagiarism_service_to_use

    if plagiarism_service_to_use == :vericite
      submitPlag = @submit_to_vericite
      canSubmit = vericiteable?
      delayName = "vericite_submission_delay_seconds"
      delayFunction = :submit_to_vericite
      delayOpts = VERICITE_JOB_OPTS
    else
      submitPlag = @submit_to_turnitin
      canSubmit = turnitinable?
      delayName = "turnitin_submission_delay_seconds"
      delayFunction = :submit_to_turnitin
      delayOpts = TURNITIN_JOB_OPTS
    end
    Rails.logger.info("#submit_to_plagiarism_later submission ID: #{id}, type: #{plagiarism_service_to_use}, canSubmit? #{canSubmit}, submitPlag? #{submitPlag}")
    if canSubmit && submitPlag
      delay = Setting.get(delayName, 60.to_s).to_i
      delay(run_at: delay.seconds.from_now, **delayOpts).__send__(delayFunction)
    end
  end
  # End Plagiarism functions

  def tool_default_query_params(current_user)
    return {} unless cached_quiz_lti?

    grade_by_question_enabled = current_user.preferences.fetch(:enable_speedgrader_grade_by_question, false)
    { grade_by_question_enabled: }
  end

  def external_tool_url(query_params: {})
    return unless submission_type == "basic_lti_launch"

    external_url = url
    return unless external_url

    external_url = UrlHelper.add_query_params(external_url, query_params) if query_params.any?
    URI::DEFAULT_PARSER.escape(external_url)
  end

  def clear_user_submissions_cache
    self.class.connection.after_transaction_commit do
      User.clear_cache_keys([user_id], :submissions)
    end
  end

  def touch_graders
    self.class.connection.after_transaction_commit do
      if assignment && user && assignment.context.is_a?(Course)
        assignment.context.clear_todo_list_cache_later(:admins)
      end
    end
  end

  def update_assignment
    unless @assignment_changed_not_sub
      delay(singleton: "submission_context_module_action_#{global_id}",
            on_conflict: :loose).context_module_action
    end
    true
  end
  protected :update_assignment

  def context_module_action
    if assignment && user
      if score
        assignment.context_module_action(user, :scored, score)
      elsif submitted_at
        assignment.context_module_action(user, :submitted)
      end
    end
  end

  # If an object is pulled from a simply_versioned yaml it may not have a submitted at.
  # submitted_at is needed by SpeedGrader, so it is set to the updated_at value
  def submitted_at
    if submission_type
      self.submitted_at = updated_at unless super
      super&.in_time_zone
    else
      nil
    end
  end

  # A student that has not submitted but has been graded will have a workflow_state of "graded".
  # In that case, we can check the submission_type to see if the student has submitted or not.
  def not_submitted?
    unsubmitted? || submission_type.nil?
  end

  def update_attachment_associations
    return if @assignment_changed_not_sub

    association_ids = attachment_associations.pluck(:attachment_id)
    ids = (attachment_ids || "").split(",").map(&:to_i)
    ids << attachment_id if attachment_id
    ids.uniq!
    associations_to_delete = association_ids - ids
    attachment_associations.where(attachment_id: associations_to_delete).delete_all unless associations_to_delete.empty?
    unassociated_ids = ids - association_ids
    return if unassociated_ids.empty?

    attachments = Attachment.where(id: unassociated_ids)
    attachments.each do |a|
      next unless (a.context_type == "User" && a.context_id == user_id) ||
                  (a.context_type == "Group" && (a.context_id == group_id || user.membership_for_group_id?(a.context_id))) ||
                  (a.context_type == "Assignment" && a.context_id == assignment_id && a.available?) ||
                  attachment_fake_belongs_to_group(a)

      attachment_associations.where(attachment: a).first_or_create
    end
  end

  def attachment_fake_belongs_to_group(attachment)
    return false if submission_type == "discussion_topic"
    return false unless attachment.context_type == "User" &&
                        assignment.has_group_category?

    gc = assignment.group_category
    gc.group_for(user) == gc.group_for(attachment.context)
  end
  private :attachment_fake_belongs_to_group

  def submit_attachments_to_canvadocs
    if saved_change_to_attachment_ids? && submission_type != "discussion_topic"
      attachments.preload(:crocodoc_document, :canvadoc).each do |a|
        # associate previewable-document and submission for permission checks
        if a.canvadocable? && Canvadocs.annotations_supported?
          submit_to_canvadocs = true
          a.create_canvadoc! unless a.canvadoc
          a.shard.activate do
            CanvadocsSubmission.find_or_create_by(submission_id: id, canvadoc_id: a.canvadoc.id)
          end
        elsif a.crocodocable?
          submit_to_canvadocs = true
          a.create_crocodoc_document! unless a.crocodoc_document
          a.shard.activate do
            CanvadocsSubmission.find_or_create_by(submission_id: id, crocodoc_document_id: a.crocodoc_document.id)
          end
        end

        next unless submit_to_canvadocs

        opts = {
          preferred_plugins: [Canvadocs::RENDER_PDFJS, Canvadocs::RENDER_BOX, Canvadocs::RENDER_CROCODOC],
          wants_annotation: true,
        }

        if context.root_account.settings[:canvadocs_prefer_office_online]
          # Office 365 should take priority over pdfjs
          opts[:preferred_plugins].unshift Canvadocs::RENDER_O365
        end

        a.delay(
          n_strand: "canvadocs",
          priority: Delayed::LOW_PRIORITY
        )
         .submit_to_canvadocs(1, **opts)
      end
    end
  end

  def annotation_context(attempt: nil, in_progress: false, draft: false)
    if draft
      canvadocs_annotation_contexts.find_or_create_by(
        attachment_id: assignment.annotatable_attachment_id,
        submission_attempt: nil
      )
    elsif in_progress
      canvadocs_annotation_contexts.find_by(
        attachment_id: assignment.annotatable_attachment_id,
        submission_attempt: nil
      )
    else
      canvadocs_annotation_contexts.find_by(submission_attempt: attempt)
    end
  end

  def infer_review_needed?
    (submission_type == "online_quiz" && quiz_submission.try(:latest_submitted_attempt).try(:pending_review?)) || lti_result&.reload&.needs_review?
  end

  def inferred_workflow_state
    inferred_state = workflow_state

    # New Quizzes returned a partial grade, but manual review is needed from a human
    return workflow_state if pending_review? && cached_quiz_lti

    inferred_state = "submitted" if unsubmitted? && submitted_at
    inferred_state = "unsubmitted" if submitted? && !has_submission?
    inferred_state = "graded" if grade && score && grade_matches_current_submission
    inferred_state = "pending_review" if infer_review_needed?

    inferred_state
  end

  def infer_values
    if assignment
      if assignment.association(:context).loaded?
        self.course = assignment.context # may as well not reload it
      else
        self.course_id = assignment.context_id
      end
    end

    self.submitted_at ||= Time.zone.now if has_submission?
    quiz_submission.reload if quiz_submission_id
    self.workflow_state = inferred_workflow_state
    if (workflow_state_changed? && graded?) || late_policy_status_changed?
      self.graded_at = Time.zone.now
    end
    self.media_comment_id = nil if media_comment_id && media_comment_id.strip.empty?
    if media_comment_id && (media_comment_id_changed? || !media_object_id)
      mo = MediaObject.by_media_id(media_comment_id).first
      self.media_object_id = mo && mo.id
    end
    self.media_comment_type = nil unless media_comment_id
    if self.submitted_at
      self.attempt ||= 0
      self.attempt += 1 if submitted_at_changed?
      self.attempt = 1 if self.attempt < 1
    end
    if submission_type == "media_recording" && !media_comment_id
      raise "Can't create media submission without media object"
    end

    if submission_type == "online_quiz"
      self.quiz_submission ||= Quizzes::QuizSubmission.where(submission_id: self).first
      self.quiz_submission ||= Quizzes::QuizSubmission.where(user_id:, quiz_id: assignment.quiz).first if assignment
    end
    @just_submitted = (submitted? || pending_review?) && submission_type && (new_record? || workflow_state_changed? || attempt_changed?)
    if score_changed? || grade_changed?
      self.grade = if assignment
                     assignment.score_to_grade(score, grade)
                   else
                     score.to_s
                   end
    end

    self.grade = nil unless score
    # I think the idea of having unpublished scores is unnecessarily confusing.
    # It may be that we want to have that functionality later on, but for now
    # I say it's just confusing.
    # if self.assignment && self.assignment.published?
    begin
      self.published_score = score
      self.published_grade = grade
    end
    true
  end

  def just_submitted?
    @just_submitted || false
  end

  def update_admins_if_just_submitted
    if @just_submitted
      context.delay_if_production.resubmission_for(assignment)
    end
    true
  end

  def check_for_media_object
    if media_comment_id.present? && saved_change_to_media_comment_id?
      MediaObject.ensure_media_object(media_comment_id,
                                      user:,
                                      context: user)
    end
  end

  def type_for_attempt(attempt)
    return submission_type if attempt == self.attempt

    submission = submission_history.find { |sub| sub.attempt == attempt }
    submission&.submission_type
  end

  def submission_history(include_version: false)
    @submission_histories ||= {}
    key = include_version ? :with_version : :without_version
    @submission_histories[key] ||= begin
      res = []
      last_submitted_at = nil
      versions.sort_by(&:created_at).reverse_each do |version|
        model = version.model
        # since vericite_data is a function, make sure you are cloning the most recent vericite_data_hash
        if vericiteable?
          model.turnitin_data = vericite_data(true)
        # only use originality data if it's loaded, we want to avoid making N+1 queries
        elsif association(:originality_reports).loaded?
          model.turnitin_data = originality_data
        end

        if model.submitted_at && last_submitted_at.to_i != model.submitted_at.to_i
          res << (include_version ? { model:, version: } : model)
          last_submitted_at = model.submitted_at
        end
      end

      if res.empty?
        res = versions.to_a[0, 1].map do |version|
          include_version ? { version:, model: version.model } : version.model
        end
      end

      if res.empty?
        res = include_version ? [{ model: self, version: nil }] : [self]
      end

      res.sort_by do |entry|
        sub = include_version ? entry.fetch(:model) : entry
        sub.submitted_at || CanvasSort::First
      end
    end
  end

  def check_is_new_attempt
    @attempt_changed = attempt_changed?
    true
  end

  def graded_anonymously=(value)
    @graded_anonymously_set = true
    super
  end

  def check_reset_graded_anonymously
    if grade_changed? && !@graded_anonymously_set
      self["graded_anonymously"] = false
    end
    true
  end

  def late_policy_status_manually_applied?
    cleared_late = late_policy_status_was == "late" && ["none", nil].include?(late_policy_status)
    cleared_none = late_policy_status_was == "none" && late_policy_status.nil?
    late_policy_status == "missing" || late_policy_status == "late" || late_policy_status == "extended" || cleared_late || cleared_none
  end
  private :late_policy_status_manually_applied?

  def apply_late_policy(late_policy = nil, incoming_assignment = nil)
    return if points_deducted_changed? || grading_period&.closed?

    incoming_assignment ||= assignment
    return unless late_policy_status_manually_applied? || incoming_assignment.expects_submission? || for_new_quiz?(incoming_assignment) || submitted_to_lti_assignment?(incoming_assignment)

    late_policy ||= incoming_assignment.course.late_policy
    return score_missing(late_policy, incoming_assignment.points_possible, incoming_assignment.grading_type) if missing?

    score_late_or_none(late_policy, incoming_assignment.points_possible, incoming_assignment.grading_type)
  end

  def submitted_to_lti_assignment?(assignment_submitted_to)
    submitted_at.present? && assignment_submitted_to.external_tool?
  end
  private :submitted_to_lti_assignment?

  def score_missing(late_policy, points_possible, grading_type)
    if points_deducted.present?
      self.score = entered_score unless score_changed?
      self.points_deducted = nil
    end

    if late_policy&.missing_submission_deduction_enabled?
      if score.nil?
        self.grade_matches_current_submission = true
        self.score = late_policy.points_for_missing(points_possible, grading_type)
        self.workflow_state = "graded"
      end
      self.posted_at ||= Time.zone.now unless assignment.post_manually?
    end
  end
  private :score_missing

  def score_late_or_none(late_policy, points_possible, grading_type)
    raw_score = (score_changed? || @regraded) ? score : entered_score
    deducted = late_points_deducted(raw_score, late_policy, points_possible, grading_type)
    new_score = raw_score && ((deducted > raw_score) ? [0.0, raw_score].min : raw_score - deducted)
    self.points_deducted = late? ? deducted : nil
    self.score = new_score
  end
  private :score_late_or_none

  def entered_score
    score + (points_deducted || 0) if score
  end

  def entered_grade
    return grade if score == entered_score
    return grade unless LatePolicy::POINT_DEDUCTIBLE_GRADING_TYPES.include?(grading_type)

    assignment.score_to_grade(entered_score) if entered_score
  end

  def late_points_deducted(raw_score, late_policy, points_possible, grading_type)
    return 0 unless raw_score && late_policy && late?

    late_policy.points_deducted(
      score: raw_score, possible: points_possible, late_for: seconds_late, grading_type:
    ).round(2)
  end
  private :late_points_deducted

  def late_policy_relevant_changes?
    return true if @regraded
    return false if grade_matches_current_submission == false # nil is treated as true
    return false if assignment.has_sub_assignments?

    changes.slice(:score, :submitted_at, :seconds_late_override, :late_policy_status, :custom_grade_status_id).any?
  end
  private :late_policy_relevant_changes?

  def ensure_grader_can_grade
    return true if grader_can_grade? || skip_grader_check

    error_msg = I18n.t(
      "cannot be changed at this time: %{grading_error}",
      { grading_error: grading_error_message }
    )
    errors.add(:grade, error_msg)
    false
  end

  def grader_can_grade?
    return true unless grade_changed?
    return true if autograded? && can_autograde?
    # the grade permission is cached, which seems to be OK as the user's cache_key changes when
    # an assignment is published. can_autograde? does not depend on a user so cannot be made
    # into permission that would be cached.
    return true if grants_right?(grader, :grade)

    false
  end

  def extra_attempts_can_only_be_set_on_online_uploads
    return true unless changes.key?("extra_attempts") && assignment
    return true if assignment.submission_types.split(",").intersect?(SUBMISSION_TYPES_GOVERNED_BY_ALLOWED_ATTEMPTS)

    error_msg = "can only be set on submissions for an assignment with a type of online_upload, online_url, or online_text_entry"
    errors.add(:extra_attempts, error_msg)
    false
  end

  def attempts_left
    return nil if assignment.allowed_attempts.nil? || assignment.allowed_attempts < 0

    [0, assignment.allowed_attempts + (extra_attempts || 0) - (self.attempt || 0)].max
  end

  def ensure_attempts_are_in_range
    return true unless changes.key?("submitted_at") && assignment
    return true unless assignment.submission_types.split(",").intersect?(SUBMISSION_TYPES_GOVERNED_BY_ALLOWED_ATTEMPTS)
    return true if attempts_left.nil? || attempts_left > 0

    errors.add(:attempt, "you have reached the maximum number of allowed attempts for this assignment")
    false
  end

  def can_autograde?
    result = GRADE_STATUS_MESSAGES_MAP[can_autograde_symbolic_status]
    result ||= { status: false, message: I18n.t("Cannot autograde at this time") }

    can_autograde_status, @grading_error_message = result[:status], result[:message]

    can_autograde_status
  end

  def can_autograde_symbolic_status
    return :not_applicable if deleted?
    return :unpublished unless assignment.published?
    return :not_autograded if grader_id >= 0

    if grading_period&.closed?
      :assignment_in_closed_grading_period
    else
      :success
    end
  end
  private :can_autograde_symbolic_status

  def can_grade?(user = nil)
    user ||= grader
    result = GRADE_STATUS_MESSAGES_MAP[can_grade_symbolic_status(user)]
    result ||= { status: false, message: I18n.t("Cannot grade at this time") }

    can_grade_status, @grading_error_message = result[:status], result[:message]

    can_grade_status
  end
  private :can_grade?

  def can_grade_symbolic_status(user = nil)
    user ||= grader

    return :moderation_in_progress unless assignment.grades_published? || grade_posting_in_progress || assignment.permits_moderation?(user)

    return :not_applicable if deleted?
    return :unpublished unless assignment.published?
    return :cant_manage_grades unless context.grants_right?(user, nil, :manage_grades)
    return :account_admin if context.account_membership_allows(user)

    if grading_period&.closed?
      :assignment_in_closed_grading_period
    else
      :success
    end
  end
  private :can_grade_symbolic_status

  def queue_websnap
    if !attachment_id && @attempt_changed && url && submission_type == "online_url"
      delay(priority: Delayed::LOW_PRIORITY).get_web_snapshot
    end
  end

  def versioned_originality_reports
    # Turns out the database stores timestamps with 9 decimal places, but Ruby/Rails only serves
    # up 6 (plus three zeros). However, submission versions (when deserialized into a Submission
    # model) like to show 9.
    # This logic is duplicated in the bulk_load_versioned_originality_reports method
    @versioned_originality_reports ||=
      if submitted_at.nil?
        []
      else
        originality_reports.select do |o|
          o.submission_time&.iso8601(6) == submitted_at&.iso8601(6) ||
            # ...and sometimes originality reports don't have submission times, so we're doing our
            # best to guess based on attachment_id (or the lack) and creation times
            (o.attachment_id.present? && attachment_ids&.split(",")&.include?(o.attachment_id.to_s)) ||
            (o.submission_time.nil? && o.created_at > submitted_at &&
              (attachment_ids&.split(",").presence || [""]).include?(o.attachment_id.to_s))
        end
      end
  end

  def versioned_attachments
    return @versioned_attachments if @versioned_attachments

    attachment_ids = attachment_ids_for_version
    self.versioned_attachments = (attachment_ids.empty? ? [] : Attachment.where(id: attachment_ids))
    @versioned_attachments
  end

  def versioned_attachments=(attachments)
    @versioned_attachments = Array(attachments).compact.select do |a|
      (a.context_type == "User" && (a.context_id == user_id || a.user_id == user_id)) ||
        (a.context_type == "Group" && (a.context_id == group_id || user.membership_for_group_id?(a.context_id))) ||
        (a.context_type == "Assignment" && a.context_id == assignment_id && a.available?) ||
        attachment_fake_belongs_to_group(a)
    end
  end

  # This helper method is used by the bulk_load_versioned_* methods
  def self.group_attachment_ids_by_submission_and_index(submissions)
    # The index of the submission is considered part of the key for
    # the hash that is built. This is needed for bulk loading
    # submission_histories where multiple submission histories will
    # look equal to the Hash key and the attachments for the last one
    # will cancel out the former ones.
    submissions_with_index_and_attachment_ids = submissions.each_with_index.map do |s, index|
      attachment_ids = (s.attachment_ids || "").split(",").map(&:to_i)
      attachment_ids << s.attachment_id if s.attachment_id
      [[s, index], attachment_ids]
    end
    submissions_with_index_and_attachment_ids.to_h
  end
  private_class_method :group_attachment_ids_by_submission_and_index

  # use this method to pre-load the versioned_attachments for a bunch of
  # submissions (avoids having O(N) attachment queries)
  # NOTE: all submissions must belong to the same shard
  def self.bulk_load_versioned_attachments(submissions, preloads: %i[thumbnail media_object folder attachment_upload_statuses context])
    attachment_ids_by_submission_and_index = group_attachment_ids_by_submission_and_index(submissions)
    bulk_attachment_ids = attachment_ids_by_submission_and_index.values.flatten

    attachments_by_id = if bulk_attachment_ids.empty? || submissions.none?
                          {}
                        else
                          submissions.first.shard.activate do
                            Attachment.where(id: bulk_attachment_ids).preload(preloads).group_by(&:id)
                          end
                        end

    submissions.each_with_index do |s, index|
      s.versioned_attachments =
        attachments_by_id.values_at(*attachment_ids_by_submission_and_index[[s, index]]).flatten
    end
  end

  def self.bulk_load_attachments_and_previews(submissions)
    bulk_load_versioned_attachments(submissions)
    attachments = submissions.flat_map(&:versioned_attachments)
    ActiveRecord::Associations.preload(attachments,
                                       [:canvadoc, :crocodoc_document])
    Version.preload_version_number(submissions)
  end

  # use this method to pre-load the versioned_originality_reports for a bunch of
  # submissions (avoids having O(N) originality report queries)
  # NOTE: all submissions must belong to the same shard
  def self.bulk_load_versioned_originality_reports(submissions)
    reports = originality_reports_by_submission_id_submission_time_attachment_id(submissions)
    submissions.each do |s|
      unless s.submitted_at
        s.versioned_originality_reports = []
        next
      end
      reports_for_sub = reports.dig(s.id, :by_time, s.submitted_at.iso8601(6)) || []

      # nil for originality reports with no submission time
      reports.dig(s.id, :by_attachment)&.each do |attach_id, reports_for_attach_id|
        # Handles the following cases:
        # 1) student submits same attachment multiple times. There will only be
        #    one originality report for each unique attachment. The originality
        #    report has a submission_time but it will be submission time of the
        #    first submission, so we need to match up by attachment ids.
        # 2) The originality report does not have a submission time. We link up
        #    via attachment id or lack of attachment id. That isn't particularly
        #    specific to the submission version. We don't have a good way of
        #    matching them (though at least in the case of using the same Canvas
        #    attachment id, it should be the same document) In submission
        #    histories, we're just giving all of the originality reports we can't
        #    rule out, but we can at least rule out any report that was created
        #    before a new submission as belonging to that submission

        if attach_id.present? && s.attachment_ids&.split(",")&.include?(attach_id.to_s)
          reports_for_sub += reports_for_attach_id
        elsif attach_id.blank? && s.attachment_ids.blank?
          # Sub and originality report both missing attachment ids -- add
          # just originality reports with submission_time is nil
          reports_for_sub += reports_for_attach_id.select { |r| r.submission_time.blank? && r.created_at > s.submitted_at }
        end
      end
      s.versioned_originality_reports = reports_for_sub.uniq
    end
  end

  def self.originality_reports_by_submission_id_submission_time_attachment_id(submissions)
    unique_ids = submissions.map(&:id).uniq
    reports = OriginalityReport.where(submission_id: unique_ids)
    reports.each_with_object({}) do |report, hash|
      report_submission_time = report.submission_time&.iso8601(6)
      hash[report.submission_id] ||= { by_time: {}, by_attachment: {} }
      if report_submission_time
        (hash[report.submission_id][:by_time][report_submission_time] ||= []) << report
      end
      (hash[report.submission_id][:by_attachment][report.attachment_id] ||= []) << report
    end
  end

  # Avoids having O(N) attachment queries.  Returns a hash of
  # submission to attachments.
  def self.bulk_load_attachments_for_submissions(submissions, preloads: nil)
    submissions = Array(submissions)
    attachment_ids_by_submission =
      submissions.index_with { |s| s.attachment_associations.map(&:attachment_id) }
    bulk_attachment_ids = attachment_ids_by_submission.values.flatten.uniq
    if bulk_attachment_ids.empty?
      attachments_by_id = {}
    else
      attachments_by_id = Attachment.where(id: bulk_attachment_ids)
      attachments_by_id = attachments_by_id.preload(*preloads) unless preloads.nil?
      attachments_by_id = attachments_by_id.group_by(&:id)
    end

    attachments_by_submission = submissions.map do |s|
      [s, attachments_by_id.values_at(*attachment_ids_by_submission[s]).flatten.compact.uniq]
    end
    attachments_by_submission.to_h
  end

  def includes_attachment?(attachment)
    versions.map(&:model).any? { |v| (v.attachment_ids || "").split(",").map(&:to_i).include?(attachment.id) }
  end

  def <=>(other)
    updated_at <=> other.updated_at
  end

  def course_broadcast_data
    context&.broadcast_data
  end

  # Submission:
  #   Online submission submitted AFTER the due date (notify the teacher) - "Grade Changes"
  #   Submission graded (or published) - "Grade Changes"
  #   Grade changed - "Grade Changes"
  set_broadcast_policy do |p|
    p.dispatch :assignment_submitted_late
    p.to { assignment.context.instructors_in_charge_of(user_id) }
    p.whenever do |submission|
      BroadcastPolicies::SubmissionPolicy.new(submission)
                                         .should_dispatch_assignment_submitted_late?
    end
    p.data { course_broadcast_data }

    p.dispatch :assignment_submitted
    p.to { assignment.context.instructors_in_charge_of(user_id) }
    p.whenever do |submission|
      BroadcastPolicies::SubmissionPolicy.new(submission)
                                         .should_dispatch_assignment_submitted?
    end
    p.data { course_broadcast_data }

    p.dispatch :assignment_resubmitted
    p.to { assignment.context.instructors_in_charge_of(user_id) }
    p.whenever do |submission|
      BroadcastPolicies::SubmissionPolicy.new(submission)
                                         .should_dispatch_assignment_resubmitted?
    end
    p.data { course_broadcast_data }

    p.dispatch :group_assignment_submitted_late
    p.to { assignment.context.instructors_in_charge_of(user_id) }
    p.whenever do |submission|
      BroadcastPolicies::SubmissionPolicy.new(submission)
                                         .should_dispatch_group_assignment_submitted_late?
    end
    p.data { course_broadcast_data }

    p.dispatch :submission_graded
    p.to { [student] + User.observing_students_in_course(student, assignment.context) }
    p.whenever do |submission|
      BroadcastPolicies::SubmissionPolicy.new(submission)
                                         .should_dispatch_submission_graded?
    end
    p.data { course_broadcast_data }

    p.dispatch :submission_grade_changed
    p.to { [student] + User.observing_students_in_course(student, assignment.context) }
    p.whenever do |submission|
      BroadcastPolicies::SubmissionPolicy.new(submission)
                                         .should_dispatch_submission_grade_changed?
    end
    p.data { course_broadcast_data }

    p.dispatch :submission_posted
    p.to { [student] + User.observing_students_in_course(student, assignment.context) }
    p.whenever do |submission|
      BroadcastPolicies::SubmissionPolicy.new(submission)
                                         .should_dispatch_submission_posted?
    end
    p.data { course_broadcast_data }
  end

  def assignment_graded_in_the_last_hour?
    graded_at_before_last_save && graded_at_before_last_save > 1.hour.ago
  end

  def teacher
    @teacher ||= assignment.teacher_enrollment.user
  end

  def update_if_pending
    @attachments = nil
    if submission_type == "online_quiz" && quiz_submission_id && score && score == self.quiz_submission.score
      self.workflow_state = self.quiz_submission.complete? ? "graded" : "pending_review"
    end
    true
  end

  def attachments
    Attachment.where(id: attachment_associations.pluck(:attachment_id))
  end

  def attachments=(attachments)
    # Accept attachments that were already approved, those that were just created
    # or those that were part of some outside context.  This is all to prevent
    # one student from sneakily getting access to files in another user's comments,
    # since they're all being held on the assignment for now.
    attachments ||= []
    old_ids = Array(attachment_ids || "").join(",").split(",").map(&:to_i)
    self.attachment_ids = attachments.select { |a| (a && a.id && old_ids.include?(a.id)) || (a.recently_created? && a.context == assignment) || a.context != assignment }.map(&:id).join(",")
  end

  # someday code-archaeologists will wonder how this method came to be named
  # validate_single_submission.  their guess is as good as mine
  def validate_single_submission
    @full_url = nil

    if (url = self["url"]) && url.length > 250
      self.body = url
      self.url = url[0..250]
    end
    unless submission_type
      self.submission_type ||= "online_url" if url
      self.submission_type ||= "online_text_entry" if body
      self.submission_type ||= "online_upload" unless attachment_ids.blank?
    end
    true
  end
  private :validate_single_submission

  def grade_change_audit(force_audit: false)
    # grade or graded status changed
    grade_changed = saved_changes.keys.intersect?(%w[grade score excused]) || (saved_change_to_workflow_state? && workflow_state == "graded")
    # any auditable conditions
    perform_audit = force_audit || grade_changed || assignment_changed_not_sub || saved_change_to_posted_at?

    if perform_audit
      if grade_change_event_author_id.present?
        self.grader_id = grade_change_event_author_id
      end
      self.class.connection.after_transaction_commit do
        Auditors::GradeChange.record(submission: self, skip_insert: !grade_changed)
        maybe_queue_conditional_release_grade_change_handler if grade_changed || (force_audit && posted_at.present?)
      end
    end
  end

  def queue_conditional_release_grade_change_handler
    strand = "conditional_release_grade_change:#{global_assignment_id}"

    progress = Progress.create!(context: self, tag: "conditional_release_handler")
    progress.process_job(ConditionalRelease::OverrideHandler,
                         :handle_grade_change,
                         { priority: Delayed::LOW_PRIORITY, strand: },
                         self)

    assignment&.delay_if_production(strand:)&.multiple_module_actions([user_id], :scored, score)
  end

  def maybe_queue_conditional_release_grade_change_handler
    shard.activate do
      if Account.site_admin.feature_enabled? :mastery_path_submission_trigger_reloaded_evaluation
        reloaded = Submission.find(id)
        return unless reloaded.graded? && reloaded.posted?
      else
        return unless graded? && posted?
      end

      if assignment.present? && assignment.queue_conditional_release_grade_change_handler?
        queue_conditional_release_grade_change_handler
      elsif assignment.blank?
        logger.warn("No assignment present for submission #{id}; skipping conditional release handler")
      end
    end
  end

  scope :with_assignment, -> { joins(:assignment).merge(Assignment.active) }

  scope :graded, -> { where("(submissions.score IS NOT NULL AND submissions.workflow_state = 'graded') or submissions.excused = true") }
  scope :not_submitted_or_graded, -> { where(submission_type: nil).where("(submissions.score IS NULL OR submissions.workflow_state <> 'graded') AND submissions.excused IS NOT TRUE") }

  scope :ungraded, -> { where(grade: nil).preload(:assignment) }

  scope :in_workflow_state, ->(provided_state) { where(workflow_state: provided_state) }

  scope :having_submission, -> { where.not(submissions: { submission_type: nil }) }
  scope :without_submission, -> { where(submission_type: nil, workflow_state: "unsubmitted") }
  scope :not_placeholder, lambda {
    active.where("submissions.submission_type IS NOT NULL or submissions.excused or submissions.score IS NOT NULL or submissions.workflow_state = 'graded'")
  }

  scope :include_user, -> { preload(:user) }

  scope :include_assessment_requests, -> { preload(:assessment_requests, :assigned_assessments) }
  scope :include_versions, -> { preload(:versions) }
  scope :include_submission_comments, -> { preload(:submission_comments) }
  scope :speed_grader_includes, -> { preload(:versions, :submission_comments, :attachments, :rubric_assessment) }
  scope :for_user, ->(user) { where(user_id: user) }
  scope :needing_screenshot, -> { where("submissions.submission_type='online_url' AND submissions.attachment_id IS NULL").order(:updated_at) }

  def assignment_visible_to_user?(user)
    return visible_to_user unless visible_to_user.nil?

    assignment.visible_to_user?(user)
  end

  def needs_regrading?
    graded? && !grade_matches_current_submission?
  end

  def readable_state
    case workflow_state
    when "submitted", "pending_review"
      t "state.submitted", "submitted"
    when "unsubmitted"
      t "state.unsubmitted", "unsubmitted"
    when "graded"
      t "state.graded", "graded"
    end
  end

  def grading_type
    return nil unless assignment

    assignment.grading_type
  end

  def last_teacher_comment
    if association(:submission_comments).loaded?
      submission_comments.reverse.detect { |com| !com.draft && com.author_id != user_id }
    elsif association(:visible_submission_comments).loaded?
      visible_submission_comments.reverse.detect { |com| com.author_id != user_id }
    else
      submission_comments.published.where.not(author_id: user_id).reorder(created_at: :desc).first
    end
  end

  def has_submission?
    !!self.submission_type
  end

  def quiz_submission_version
    return nil unless self.quiz_submission

    self.quiz_submission.versions.each do |version|
      return version.number if version.model.finished_at
    end
    nil
  end

  scope :for, lambda { |obj|
    case obj
    when User
      where(user_id: obj)
    else
      all
    end
  }

  def processed?
    if submission_type == "online_url"
      return attachment&.content_type&.include?("image")
    end

    false
  end

  def provisional_grade(scorer, final: false, preloaded_grades: nil, default_to_null_grade: true)
    pg = if preloaded_grades
           pgs = preloaded_grades[id] || []
           if final
             pgs.detect(&:final)
           else
             pgs.detect { |pg2| !pg2.final && pg2.scorer_id == scorer.id }
           end
         elsif final
           provisional_grades.final.first
         else
           provisional_grades.not_final.where(scorer_id: scorer).first
         end

    if default_to_null_grade && pg.nil?
      ModeratedGrading::NullProvisionalGrade.new(self, scorer.id, final)
    else
      pg
    end
  end

  def find_or_create_provisional_grade!(scorer, attrs = {})
    ModeratedGrading::ProvisionalGrade.unique_constraint_retry do
      if attrs[:final] && !assignment.permits_moderation?(scorer)
        raise Assignment::GradeError, "User not authorized to give final provisional grades"
      end

      pg = find_existing_provisional_grade(scorer, attrs[:final]) || provisional_grades.build
      pg = update_provisional_grade(pg, scorer, attrs)
      pg.save! if attrs[:force_save] || pg.new_record? || pg.changed?
      pg
    end
  end

  def find_existing_provisional_grade(scorer, final)
    final ? provisional_grades.final.first : provisional_grades.not_final.find_by(scorer:)
  end

  def moderated_grading_allow_list(current_user = user, loaded_attachments: nil)
    return nil unless assignment.moderated_grading? && current_user.present?

    has_crocodoc = (loaded_attachments || attachments).any?(&:crocodoc_available?)
    moderation_allow_list_for_user(current_user).map do |user|
      user.moderated_grading_ids(has_crocodoc)
    end
  end

  def moderation_allow_list_for_user(current_user)
    allow_list = []
    return allow_list unless current_user.present? && assignment.moderated_grading?

    if assignment.annotated_document?
      # The student's annotations are what make up the submission in this case.
      allow_list.push(user)
    end

    if posted?
      allow_list.push(grader, user, current_user)
    elsif user == current_user
      # Requesting user is the student.
      allow_list << current_user
    elsif assignment.permits_moderation?(current_user)
      # Requesting user is the final grader or an administrator.
      allow_list.push(*assignment.moderation_grader_users_with_slot_taken, user, current_user)
    elsif assignment.can_be_moderated_grader?(current_user)
      # Requesting user is a provisional grader, or eligible to be one.
      if assignment.grader_comments_visible_to_graders
        allow_list.push(*assignment.moderation_grader_users_with_slot_taken, user, current_user)
      else
        allow_list.push(current_user, user)
      end
    end
    allow_list.compact.uniq
  end

  def anonymous_identities
    @anonymous_identities ||= assignment.anonymous_grader_identities_by_user_id.merge({
                                                                                        user_id => { name: I18n.t("Student"), id: anonymous_id }
                                                                                      })
  end

  def add_comment(opts = {})
    opts = opts.symbolize_keys
    opts[:author] ||= opts[:commenter] || opts[:author] || opts[:user] || user unless opts[:skip_author]
    opts[:comment] = opts[:comment].try(:strip) || ""
    opts[:attachments] ||= opts[:comment_attachments]
    opts[:draft] = !!opts[:draft_comment]
    opts[:attempt] = (!unsubmitted? && !opts.key?(:attempt)) ? self.attempt : opts[:attempt]
    if opts[:comment].empty?
      if opts[:media_comment_id]
        opts[:comment] = ""
      elsif opts[:attachments].try(:length)
        opts[:comment] = t("attached_files_comment", "Please see attached files.")
      end
    end
    if opts[:provisional]
      pg = find_or_create_provisional_grade!(opts[:author], final: opts[:final])
      opts[:provisional_grade_id] = pg.id
    end

    if new_record?
      save!
    elsif comment_causes_posting?(author: opts[:author], draft: opts[:draft], provisional: opts[:provisional])
      opts[:hidden] = false
      update!(posted_at: Time.zone.now)
    else
      touch
    end
    valid_keys = %i[comment
                    author
                    media_comment_id
                    media_comment_type
                    group_comment_id
                    assessment_request
                    attachments
                    anonymous
                    hidden
                    provisional_grade_id
                    draft
                    attempt]
    if opts[:comment].present? || opts[:media_comment_id]
      comment = submission_comments.create!(opts.slice(*valid_keys))
    end
    opts[:assessment_request].comment_added if opts[:assessment_request] && comment

    comment
  end

  def comment_authors
    visible_submission_comments.preload(:author).map(&:author)
  end

  def commenting_instructors
    @commenting_instructors ||= comment_authors & context.instructors
  end

  def participating_instructors
    commenting_instructors.presence || context.participating_instructors.to_a.uniq
  end

  def possible_participants_ids
    [user_id] + context.participating_instructors.uniq.map(&:id)
  end

  def limit_comments(user, session = nil)
    @comment_limiting_user = user
    @comment_limiting_session = session
  end

  def apply_provisional_grade_filter!(provisional_grade)
    @provisional_grade_filter = provisional_grade
    self.grade = provisional_grade.grade
    self.score = provisional_grade.score
    self.graded_at = provisional_grade.graded_at
    self.grade_matches_current_submission = provisional_grade.grade_matches_current_submission
    readonly!
  end

  def provisional_grade_id
    @provisional_grade_filter&.id
  end

  def submission_comments(*args)
    comments = if @provisional_grade_filter
                 @provisional_grade_filter.submission_comments
               else
                 super
               end
    comments.preload(submission: :assignment)

    if @comment_limiting_user
      comments.select { |comment| comment.grants_right?(@comment_limiting_user, @comment_limiting_session, :read) }
    else
      comments
    end
  end

  def visible_submission_comments(*args)
    comments = if @provisional_grade_filter
                 @provisional_grade_filter.submission_comments.where(hidden: false)
               else
                 super
               end

    if @comment_limiting_user
      comments.select { |comment| comment.grants_right?(@comment_limiting_user, @comment_limiting_session, :read) }
    else
      comments
    end
  end

  def visible_submission_comments_for(current_user)
    displayable_comments = if assignment.grade_as_group?
                             all_submission_comments_for_groups
                           elsif assignment.moderated_grading? && assignment.grades_published?
                             # When grades are published for a moderated assignment, provisional
                             # comments made by the chosen grader are duplicated as non-provisional
                             # comments. Ignore the provisional copies of that grader's comments.
                             if association(:all_submission_comments).loaded?
                               all_submission_comments.reject { |comment| comment.provisional_grade_id.present? && comment.author_id == grader_id }
                             else
                               all_submission_comments.where.not("author_id = ? AND provisional_grade_id IS NOT NULL", grader_id)
                             end
                           else
                             all_submission_comments
                           end

    displayable_comments.select do |submission_comment|
      submission_comment.grants_right?(current_user, :read)
    end
  end

  # true if there is a comment by user other than submitter on the current attempt
  # comments prior to first attempt will count as current until a second attempt is started
  def feedback_for_current_attempt?
    visible_submission_comments.any? do |comment|
      comment.author_id != user_id &&
        ((comment.attempt&.nonzero? ? comment.attempt : 1) == (self.attempt || 1))
    end
  end

  def assessment_request_count
    @assessment_requests_count ||= assessment_requests.size
  end

  def assigned_assessment_count
    @assigned_assessment_count ||= assigned_assessments.size
  end

  def assign_assessment(obj)
    @assigned_assessment_count ||= 0
    @assigned_assessment_count += 1
    assigned_assessments << obj
    touch
  end
  protected :assign_assessment

  def assign_assessor(obj)
    @assessment_request_count ||= 0
    @assessment_request_count += 1
    user = obj.try(:user)
    association = AbstractAssignment.find(assignment_id).active_rubric_association? ? assignment.rubric_association : nil
    res = assessment_requests.where(assessor_asset_id: obj.id, assessor_asset_type: obj.class.to_s, assessor_id: user.id, rubric_association_id: association.try(:id))
                             .first_or_initialize
    res.user_id = user_id
    res.workflow_state = "assigned" if res.new_record?
    res.send_reminder! # this method also saves the assessment_request
    obj.assign_assessment(res) if obj.is_a?(Submission) && res.previously_new_record?
    res
  end

  def students
    group ? group.users : [user]
  end

  def broadcast_group_submission
    Submission.unique_constraint_retry do
      @group_broadcast_submission = true
      save!
      @group_broadcast_submission = false
    end
  end

  # in a module so they can be included in other Submission-like objects. the
  # contract is that the including class must have the following attributes:
  #
  #  * assignment (Assignment)
  #  * submission_type (String)
  #  * workflow_state (String)
  #  * cached_due_date (Time)
  #  * submitted_at (Time)
  #  * score (Integer)
  #  * excused (Boolean)
  #  * late_policy_status (String)
  #  * seconds_late_override (Integer)
  #
  module Tardiness
    def past_due?
      seconds_late > 0
    end
    alias_method :past_due, :past_due?

    def late?
      return false if excused?
      return false if custom_grade_status_id
      return late_policy_status == "late" if late_policy_status.present?

      submitted_at.present? && past_due?
    end
    alias_method :late, :late?

    def missing?
      return false if excused?
      return false if custom_grade_status_id
      return false if grader_id && late_policy_status.nil?
      return late_policy_status == "missing" if late_policy_status.present?
      return false if submitted_at.present?
      return false unless past_due?

      for_new_quiz? || assignment.expects_submission?
    end
    alias_method :missing, :missing?

    def for_new_quiz?(quiz_assignment = assignment)
      cached_quiz_lti? || !!quiz_assignment&.quiz_lti?
    end

    def extended?
      return false if excused?
      return false if custom_grade_status_id
      return late_policy_status == "extended" if late_policy_status.present?

      false
    end
    alias_method :extended, :extended?

    def graded?
      excused || (!!score && workflow_state == "graded")
    end

    def seconds_late
      return seconds_late_override || 0 if late_policy_status == "late"
      return 0 if cached_due_date.nil? || time_of_submission <= cached_due_date

      (time_of_submission - cached_due_date).to_i
    end

    def time_of_submission
      time = submitted_at || Time.zone.now
      time -= 60.seconds if submission_type == "online_quiz" || cached_quiz_lti?
      time
    end
    private :time_of_submission
  end
  include Tardiness

  def current_submission_graded?
    graded? && (!self.submitted_at || (graded_at && graded_at >= self.submitted_at))
  end

  def context
    self.course ||= assignment&.context
  end

  def to_atom(opts = {})
    author_name = (assignment.present? && assignment.context.present?) ? assignment.context.name : t("atom_no_author", "No Author")

    {
      title: "#{user.name} -- #{assignment.title}#{", " + assignment.context.name if opts[:include_context]}",
      updated: updated_at,
      published: created_at,
      id: "tag:#{HostUrl.default_host},#{created_at.strftime("%Y-%m-%d")}:/submissions/#{feed_code}_#{updated_at.strftime("%Y-%m-%d")}",
      content: body || "",
      link: "#{assignment.direct_link}/submissions/#{id}",
      author: author_name
    }
  end

  # include the versioned_attachments in as_json if this was loaded from a
  # specific version
  def serialization_methods
    if !@without_versioned_attachments && simply_versioned_version_model
      [:versioned_attachments]
    else
      []
    end
  end

  # mechanism to turn off the above behavior for the duration of a
  # block
  def without_versioned_attachments
    original, @without_versioned_attachments = @without_versioned_attachments, true
    yield
  ensure
    @exclude_versioned_attachments = original
  end

  def self.json_serialization_full_parameters(additional_parameters = {})
    includes = { quiz_submission: {} }
    methods = %i[submission_history attachments entered_score entered_grade word_count]
    methods << (additional_parameters.delete(:comments) || :submission_comments)
    if additional_parameters[:methods]
      methods.concat(Array(additional_parameters.delete(:methods)))
    end
    excepts = additional_parameters.delete :except

    res = { methods:, include: includes }.merge(additional_parameters)
    excepts&.each do |key|
      res[:methods].delete key
      res[:include].delete key
    end
    res
  end

  def to_param
    user_id
  end

  def turnitin_data_changed!
    @turnitin_data_changed = true
  end

  def turnitin_data_changed?
    @turnitin_data_changed
  end

  def get_web_snapshot
    # This should always be called in the context of a delayed job
    return unless CutyCapt.enabled?

    if (attachment = CutyCapt.snapshot_attachment_for_url(url, context: self))
      attach_screenshot(attachment)
    else
      logger.error("Error capturing web snapshot for submission #{global_id}")
    end
  end

  def attach_screenshot(attachment)
    self.attachment = attachment
    self.processed = true
    save!
  end

  def excused=(excused)
    if excused
      self[:excused] = true
      self.grade = nil
      self.score = nil
    else
      self[:excused] = false
    end
  end

  # Note that this will return an Array (not an ActiveRecord::Relation) if comments are preloaded
  def comments_excluding_drafts_for(user)
    comments =
      if user_can_read_grade?(user) && course.present? && !self.course.user_is_student?(user)
        submission_comments
      else
        visible_submission_comments
      end
    comments.loaded? ? comments.reject(&:draft?) : comments.published
  end

  def comments_including_drafts_for(user)
    comments = user_can_read_grade?(user) ? submission_comments : visible_submission_comments
    if comments.loaded?
      comments.select { |comment| comment.non_draft_or_authored_by(user) }
    else
      comments.authored_by(user.id)
    end
  end

  def filter_attributes_for_user(hash, user, session)
    unless user_can_read_grade?(user, session)
      %w[score grade published_score published_grade entered_score entered_grade].each do |secret_attr|
        hash.delete secret_attr
      end
    end
    hash
  end

  def update_participation
    # TODO: can we do this in bulk?
    return if assignment.deleted?

    return unless user_id

    return unless saved_change_to_score? || saved_change_to_grade? || saved_change_to_excused?

    return unless context.grants_right?(user, :participate_as_student)

    mark_item_unread("grade")
  end

  def update_line_item_result
    return unless saved_change_to_score?
    return if autograded? # Submission changed by LTI Tool, it will set result score directly

    unless lti_result
      assignment.line_items.first&.results&.create!(
        submission: self, user:, created_at: Time.zone.now, updated_at: Time.zone.now
      )
    end
    Lti::Result.update_score_for_submission(self, score)
  end

  def delete_ignores
    if !submission_type.nil? || excused
      Ignore.where(asset_type: "Assignment", asset_id: assignment_id, user_id:, purpose: "submitting").delete_all

      unless Submission.where(assignment_id:).where(Submission.needs_grading_conditions).exists?
        Ignore.where(asset_type: "Assignment", asset_id: assignment_id, purpose: "grading", permanent: false).delete_all
      end
    end
    true
  end

  def delete_submission_drafts!
    submission_drafts.destroy_all
  end

  def point_data?
    !!(score || grade)
  end

  def read_state(current_user)
    return "read" unless current_user # default for logged out user

    state = ContentParticipation.submission_read_state(self, current_user)
    return state if state.present?

    return "read" if assignment.deleted? || !posted? || !user_id
    return "unread" if grade || score

    has_comments = if visible_submission_comments.loaded?
                     visible_submission_comments.detect { |c| c.author_id != user_id }
                   else
                     visible_submission_comments.where("author_id<>?", user_id).first
                   end
    return "unread" if has_comments

    "read"
  end

  def read?(current_user)
    read_state(current_user) == "read"
  end

  def unread?(current_user)
    !read?(current_user)
  end

  def read_item?(current_user, content_item)
    ContentParticipation.submission_item_read?(
      content: self,
      user: current_user,
      content_item:
    )
  end

  def unread_item?(current_user, content_item)
    !read_item?(current_user, content_item)
  end

  def mark_read(current_user)
    change_read_state("read", current_user)
  end

  def mark_unread(current_user)
    change_read_state("unread", current_user)
  end

  def mark_item_read(content_item)
    change_item_read_state("read", content_item)
  end

  def mark_item_unread(content_item)
    change_item_read_state("unread", content_item)
  end

  def refresh_comment_read_state
    unread_comments = visible_submission_comments.where.missing(:viewed_submission_comments).where.not(author: user).exists?

    if unread_comments
      mark_item_unread("comment")
    else
      mark_item_read("comment")
    end
  end

  def mark_submission_comments_read(current_user)
    timestamp = Time.now.utc
    viewed_comments = visible_submission_comments.pluck(:id).map do |id|
      {
        user_id: current_user.id,
        submission_comment_id: id,
        viewed_at: timestamp
      }
    end

    ViewedSubmissionComment.insert_all(viewed_comments)
  end

  def change_item_read_state(new_state, content_item)
    participant = ContentParticipation.participate(
      content: self,
      user:,
      content_item:,
      workflow_state: new_state
    )

    new_state = read_state(user)

    StreamItem.update_read_state_for_asset(self, new_state, user.id)
    PlannerHelper.clear_planner_cache(user)

    participant
  end

  def change_read_state(new_state, current_user)
    return nil unless current_user
    return true if new_state == read_state(current_user)

    StreamItem.update_read_state_for_asset(self, new_state, current_user.id)
    PlannerHelper.clear_planner_cache(current_user)

    ContentParticipation.create_or_update({
                                            content: self,
                                            user: current_user,
                                            workflow_state: new_state,
                                          })
  end

  def mute
    self.published_score =
      self.published_grade =
        self.graded_at =
          self.grade =
            self.score = nil
  end

  def muted_assignment?
    assignment.muted?
  end

  def hide_grade_from_student?(for_plagiarism: false)
    return false if for_plagiarism

    if assignment.post_manually?
      posted_at.blank?
    else
      # Only indicate that the grade is hidden if there's an actual grade.
      # Similarly, hide the grade if the student resubmits (which will keep
      # the old grade but bump the workflow back to "submitted").
      (graded? || resubmitted?) && !posted?
    end
  end

  # You must also check the assignment.can_view_score_statistics
  def eligible_for_showing_score_statistics?
    # This checks whether this submission meets the requirements in order
    # for the submitter to be able to see score statistics for the assignment
    score.present? && !hide_grade_from_student?
  end

  def posted?
    posted_at.present?
  end

  def assignment_muted_changed
    grade_change_audit(force_audit: true)
  end

  def without_graded_submission?
    !has_submission? && !graded?
  end

  def visible_rubric_assessments_for(viewing_user, attempt: nil)
    return [] unless assignment.active_rubric_association?

    unless posted? || grants_right?(viewing_user, :read_grade)
      # If this submission is unposted and the viewer can't view the grade,
      # show only that viewer's assessments
      return rubric_assessments_for_attempt(attempt:).select do |assessment|
        assessment.assessor_id == viewing_user.id
      end
    end

    filtered_assessments = rubric_assessments_for_attempt(attempt:).select do |a|
      a.grants_right?(viewing_user, :read) &&
        a.rubric_association == assignment.rubric_association
    end

    if assignment.anonymous_peer_reviews? && !grants_right?(viewing_user, :grade)
      filtered_assessments.each do |a|
        if a.assessment_type == "peer_review" && viewing_user&.id != a.assessor&.id
          a.assessor = nil # hide peer reviewer's identity
        end
      end
    end

    filtered_assessments.sort_by do |a|
      [
        (a.assessment_type == "grading") ? CanvasSort::First : CanvasSort::Last,
        Canvas::ICU.collation_key(a.assessor_name)
      ]
    end
  end

  def rubric_assessments_for_attempt(attempt: nil)
    return rubric_assessments.to_a if attempt.blank?

    # If the requested attempt is 0, no attempt has actually been submitted.
    # The submission's attempt will be nil (not 0), so we do actually want to
    # find assessments with a nil artifact_attempt.
    effective_attempt = (attempt == 0) ? nil : attempt

    rubric_assessments.each_with_object([]) do |assessment, assessments_for_attempt|
      # Always return self-assessments and assessments for the effective attempt
      if assessment.artifact_attempt == effective_attempt || assessment.assessment_type == "self_assessment"
        assessments_for_attempt << assessment
      else
        version = assessment.versions.find { |v| v.model.artifact_attempt == effective_attempt }
        assessments_for_attempt << version.model if version
      end
    end
  end
  private :rubric_assessments_for_attempt

  def self.queue_bulk_update(context, section, grader, grade_data)
    progress = Progress.create!(context:, tag: "submissions_update")
    progress.process_job(self, :process_bulk_update, { n_strand: ["submissions_bulk_update", context.global_id] }, context, section, grader, grade_data)
    progress
  end

  def self.process_bulk_update(progress, context, section, grader, grade_data)
    missing_ids = []
    unpublished_assignment_ids = []
    graded_user_ids = Set.new
    preloaded_assignments = AbstractAssignment.find(grade_data.keys).index_by(&:id)

    Submission.suspend_callbacks(:touch_graders) do
      grade_data.each do |assignment_id, user_grades|
        assignment = preloaded_assignments[assignment_id.to_i]
        unless assignment.published?
          # if we don't bail here, the submissions will throw
          # errors deeper in the update because you can't change grades
          # on submissions that belong to deleted assignments
          unpublished_assignment_ids << assignment.id
          next
        end

        user_ids = user_grades.keys
        uids_for_visiblity = Api.map_ids(user_ids, User, context.root_account, grader)

        scope = assignment.students_with_visibility(context.students_visible_to(grader, include: :inactive),
                                                    uids_for_visiblity)
        if section
          scope = scope.where(enrollments: { course_section_id: section })
        end

        preloaded_users = scope.where(id: user_ids)
        preloaded_submissions = assignment.submissions.where(user_id: user_ids).group_by(&:user_id)

        Delayed::Batch.serial_batch(priority: Delayed::LOW_PRIORITY, n_strand: ["bulk_update_submissions", context.root_account.global_id]) do
          user_grades.each do |user_id, user_data|
            user = preloaded_users.detect { |u| u.global_id == Shard.global_id_for(user_id) }
            user ||= Api.sis_relation_for_collection(scope, [user_id], context.root_account).first
            unless user
              missing_ids << user_id
              next
            end

            submission = preloaded_submissions[user_id.to_i].first if preloaded_submissions[user_id.to_i]
            if !submission || user_data.key?(:posted_grade) || user_data.key?(:excuse)
              submissions =
                assignment.grade_student(user,
                                         grader:,
                                         grade: user_data[:posted_grade],
                                         excuse: Canvas::Plugin.value_to_boolean(user_data[:excuse]),
                                         skip_grade_calc: true,
                                         return_if_score_unchanged: true)
              submissions.each { |s| graded_user_ids << s.user_id unless s.score_unchanged }
              submission = submissions.first
            end
            submission.user = user

            assessment = user_data[:rubric_assessment]
            if assessment.is_a?(Hash) && assignment.active_rubric_association?
              # prepend each key with "criterion_", which is required by
              # the current RubricAssociation#assess code.
              assessment.transform_keys! do |crit_name|
                "criterion_#{crit_name}"
              end
              assignment.rubric_association.assess(
                assessor: grader,
                user:,
                artifact: submission,
                assessment: assessment.merge(assessment_type: "grading")
              )
            end

            comment = user_data.slice(:text_comment, :file_ids, :media_comment_id, :media_comment_type, :group_comment)
            next unless comment.present?

            comment = {
              comment: comment[:text_comment],
              author: grader,
              hidden: assignment.post_manually? && !submission.posted?
            }.merge(
              comment
            ).with_indifferent_access

            if (file_ids = user_data[:file_ids])
              attachments = Attachment.where(id: file_ids).to_a.select do |a|
                a.grants_right?(grader, :attach_to_submission_comment)
              end
              attachments.each { |a| a.ok_for_submission_comment = true }
              comment[:attachments] = attachments if attachments.any?
            end
            assignment.update_submission(user, comment)
          end
        end
      end
    end

    # make sure we don't pretend everything was fine if there were missing or
    # bad-state records that we couldn't handle.  We don't need to throw an exception,
    # but we do need to make the reason for lack of command compliance
    # visible.
    if missing_ids.any?
      progress.message = "Couldn't find User(s) with API ids #{missing_ids.map { |id| "'#{id}'" }.join(", ")}"
      progress.save
      progress.fail
    elsif unpublished_assignment_ids.any?
      progress.message = "Some assignments are either not published or deleted and can not be graded #{unpublished_assignment_ids.map { |id| "'#{id}'" }.join(", ")}"
      progress.save
      progress.fail
    end
  ensure
    context.clear_todo_list_cache_later(:admins)
    user_ids = graded_user_ids.to_a
    if user_ids.any?
      context.recompute_student_scores(user_ids)
    end
  end

  def status_tag
    return :excused if excused?
    return :custom if custom_grade_status_id
    return :late if late?
    return :extended if extended?
    return :missing if missing?

    :none
  end

  def status
    case status_tag
    when :custom
      custom_grade_status.name
    when :excused
      I18n.t("Excused")
    when :missing
      I18n.t("Missing")
    when :late
      I18n.t("Late")
    when :extended
      I18n.t("Extended")
    when :none
      I18n.t("None")
    end
  end

  def submission_status
    if resubmitted?
      :resubmitted
    elsif missing?
      :missing
    elsif late?
      :late
    elsif submitted? ||
          (submission_type.present? && submission_type != "online_quiz") ||
          (submission_type == "online_quiz" && quiz_submission.completed?)
      :submitted
    else
      :unsubmitted
    end
  end

  def grading_status
    if excused?
      :excused
    elsif needs_review?
      :needs_review
    elsif needs_grading?
      :needs_grading
    elsif graded?
      :graded
    else
      nil
    end
  end

  def postable_comments?
    # This logic is also implemented in SQL in
    # app/graphql/loaders/has_postable_comments_loader.rb
    # to determine if a submission has any postable comments.
    # Any changes made here should also be reflected in the loader.
    submission_comments.any?(&:allows_posting_submission?)
  end

  def word_count
    if get_word_count_from_body?
      read_or_calc_body_word_count
    elsif versioned_attachments.present?
      Attachment.where(id: versioned_attachments.pluck(:id)).sum(:word_count)
    end
  end

  def read_or_calc_body_word_count
    if body_word_count.present? && Account.site_admin.feature_enabled?(:use_body_word_count)
      body_word_count
    else
      calc_body_word_count
    end
  end

  def effective_checkpoint_submission(sub_assignment_tag)
    return self unless sub_assignment_tag.present?
    return self unless assignment.checkpoints_parent?

    sub_assignment = assignment.find_checkpoint(sub_assignment_tag)

    return self if sub_assignment.nil?

    # TODO: see if we should be throwing an error here instead of defaulting to `submission`
    sub_assignment.all_submissions.find_by(user:) || self
  end

  def aggregate_checkpoint_submissions
    Checkpoints::SubmissionAggregatorService.call(
      assignment: assignment.parent_assignment,
      student: user
    )
  end

  def partially_submitted?
    return false if assignment.nil?
    return false unless assignment.has_sub_assignments?

    assignment.sub_assignments.each do |sub_assignment|
      return true if sub_assignment.submissions.where(user_id:, submission_type: "discussion_topic").where.not(submitted_at: nil).exists?
    end

    false
  end

  # For large body text, this can be SLOW. Call this method in a delayed job.
  def calc_body_word_count
    return 0 if body.nil?

    tinymce_wordcount_count_regex = /(?:[\w\u2019\x27\-\u00C0-\u1FFF]+|(?<=<br>)([^<]+)|([^<]+)(?=<br>))/
    segments = body.split(%r{<br\s*/?>})
    segments.sum do |segment|
      ActionController::Base.helpers.strip_tags(segment).scan(tinymce_wordcount_count_regex).size
    end
  end

  def lti_attempt_id(attempt = nil)
    "#{lti_id}:#{attempt || self.attempt}"
  end

  private

  def checkpoint_changes?
    checkpoint_submission? && checkpoint_attributes_changed?
  end

  def checkpoint_submission?
    assignment.present? && assignment.checkpoint? && !!assignment.context.discussion_checkpoints_enabled?
  end

  def checkpoint_attributes_changed?
    tracked_attributes = Checkpoints::SubmissionAggregatorService::AggregateSubmission.members.map(&:to_s) - ["updated_at"]
    relevant_changes = tracked_attributes & saved_changes.keys
    relevant_changes.any?
  end

  def clear_body_word_count
    self.body_word_count = nil
  end

  def get_word_count_from_body?
    !body.nil? && submission_type != "online_quiz"
  end

  def update_body_word_count_later
    return unless Account.site_admin.feature_enabled?(:use_body_word_count)

    delay(
      n_strand: ["Submission#update_body_word_count", global_root_account_id],
      singleton: "update_body_word_count#{global_id}",
      on_permanent_failure: :set_body_word_count_to_zero
    ).update_body_word_count
  end

  def set_body_word_count_to_zero(_error)
    update(body_word_count: 0)
  end

  def update_body_word_count
    update(body_word_count: calc_body_word_count)
  end

  def remove_sticker
    self.sticker = nil
  end

  def set_status_attributes
    if will_save_change_to_excused?(to: true)
      self.late_policy_status = nil
      self.custom_grade_status_id = nil
    elsif will_save_change_to_custom_grade_status_id? && custom_grade_status_id.present?
      self.excused = false
      self.late_policy_status = nil
    elsif will_save_change_to_late_policy_status? && late_policy_status.present?
      self.excused = false
      self.custom_grade_status_id = nil
    end

    self.seconds_late_override = nil unless late_policy_status == "late"
  end

  def reset_redo_request
    self.redo_request = false if redo_request && attempt_changed?
  end

  def set_root_account_id
    self.root_account_id ||= assignment&.course&.root_account_id
  end

  def preserve_lti_id
    errors.add(:lti_id, "Cannot change lti_id!") if lti_id_changed? && !lti_id_was.nil? && !override_lti_id_lock
  end

  def set_lti_id
    # Old records may not have an lti_id, so we need to set one
    self.lti_id ||= SecureRandom.uuid
  end

  # For internal use only.
  # The lti_id field on its own is not enough to uniquely identify a submission; use lti_attempt_id instead.
  def lti_id
    read_attribute(:lti_id)
  end

  def set_anonymous_id
    self.anonymous_id = Anonymity.generate_id(existing_ids: Submission.anonymous_ids_for(assignment))
  end

  def update_provisional_grade(pg, scorer, attrs = {})
    # Adding a comment calls update_provisional_grade, but will not have the
    # grade or score keys included.
    if (attrs.key?(:grade) || attrs.key?(:score)) && pg.selection.present? && pg.scorer_id != assignment.final_grader_id
      raise Assignment::GradeError.new(error_code: Assignment::GradeError::PROVISIONAL_GRADE_MODIFY_SELECTED)
    end

    pg.scorer = pg.current_user = scorer
    pg.final = !!attrs[:final]
    if attrs.key?(:score)
      pg.score = attrs[:score]
      pg.grade = attrs[:grade].presence
    elsif attrs.key?(:grade)
      pg.grade = attrs[:grade]
    end
    pg.source_provisional_grade = attrs[:source_provisional_grade] if attrs.key?(:source_provisional_grade)
    pg.graded_anonymously = attrs[:graded_anonymously] unless attrs[:graded_anonymously].nil?
    pg.force_save = !!attrs[:force_save]
    pg
  end

  def create_audit_event!
    return unless assignment&.auditable? && @audit_grade_changes

    auditable_attributes = %w[score grade excused]
    auditable_changes = saved_changes.slice(*auditable_attributes)
    return if auditable_changes.empty?

    event =
      {
        assignment:,
        submission: self,
        event_type: "submission_updated",
        payload: auditable_changes
      }

    if !autograded?
      event[:user] = grader
    elsif quiz_submission_id
      event[:quiz_id] = -grader_id
    else
      event[:context_external_tool_id] = -grader_id
    end

    AnonymousOrModerationEvent.create!(event)
  end

  def comment_causes_posting?(author:, draft:, provisional:)
    return false if posted? || assignment.post_manually?
    return false if draft || provisional
    return false if author.blank?

    assignment.context.instructor_ids.include?(author.id) || assignment.context.account_membership_allows(author)
  end

  def handle_posted_at_changed
    previously_posted = posted_at_before_last_save.present?

    # Outdated
    # If this submission is part of an assignment associated with a quiz, the
    # quiz object might be in a modified/readonly state (due to trying to load
    # a copy with override dates for this particular student) depending on what
    # path we took to get here. To avoid a ReadOnlyRecord error, do the actual
    # posting/hiding on a separate copy of the assignment, then reload our copy
    # of the assignment to make sure we pick up any changes to the muted status.
    if posted? && !previously_posted
      AbstractAssignment.find(assignment_id).post_submissions(submission_ids: [id], skip_updating_timestamp: true, skip_muted_changed: true)
      # This rescue is because of an error in the production environment where
      # the when a student that is also an admin creates a submission of an assignment
      # it throws a undefined method `owner' for nil:NilClass error when trying to
      # reload the assignment. This is fix to prevent the error from
      # crashing the server.
      begin
        assignment.reload
      rescue
        nil
      end
    elsif !posted? && previously_posted
      AbstractAssignment.find(assignment_id).hide_submissions(submission_ids: [id], skip_updating_timestamp: true, skip_muted_changed: true)
      begin
        assignment.reload
      rescue
        nil
      end
    end
  end

  def send_timing_data_if_needed
    return unless saved_change_to_workflow_state? &&
                  state == :graded &&
                  workflow_state_before_last_save == "pending_review" &&
                  (submission_type == "online_quiz" || (submission_type == "basic_lti_launch" && url.include?("quiz-lti")))

    time = graded_at - submitted_at
    return if time < 30

    InstStatsd::Statsd.gauge("submission.manually_graded.grading_time",
                             time,
                             Setting.get("submission_grading_timing_sample_rate", "1.0").to_f,
                             tags: { quiz_type: (submission_type == "online_quiz") ? "classic_quiz" : "new_quiz" })
  end
end
