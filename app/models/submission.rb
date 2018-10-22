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

require 'atom'
require 'anonymity'

class Submission < ActiveRecord::Base
  include Canvas::GradeValidations
  include CustomValidations
  include SendToStream
  include Workflow
  include PlannerHelper

  GRADE_STATUS_MESSAGES_MAP = {
    success: {
      status: true
    }.freeze,
    account_admin: {
      status: true
    }.freeze,
    unpublished: {
      status: false,
      message: I18n.t('This assignment is still unpublished')
    }.freeze,
    not_autograded: {
      status: false,
      message: I18n.t('This submission is not being autograded')
    }.freeze,
    cant_manage_grades: {
      status: false,
      message: I18n.t("You don't have permission to manage grades for this course")
    }.freeze,
    assignment_in_closed_grading_period: {
      status: false,
      message: I18n.t('This assignment is in a closed grading period for this student')
    }.freeze,
    not_applicable: {
      status: false,
      message: I18n.t('This assignment is not applicable to this student')
    }.freeze,
    moderation_in_progress: {
      status: false,
      message: I18n.t('This assignment is currently being moderated')
    }.freeze
  }.freeze

  attr_readonly :assignment_id
  attr_accessor :visible_to_user,
                :skip_grade_calc,
                :grade_posting_in_progress,
                :score_unchanged
  attr_writer :versioned_originality_reports,
              :text_entry_originality_reports
  # This can be set to true to force late policy behaviour that would
  # be skipped otherwise. See #late_policy_relevant_changes? and
  # #score_late_or_none. It is reset to false in an after save so late
  # policy deductions don't happen again if the submission object is
  # saved again.
  attr_writer :regraded

  belongs_to :attachment # this refers to the screenshot of the submission if it is a url submission
  belongs_to :assignment, inverse_of: :submissions
  belongs_to :user
  alias student user
  belongs_to :grader, :class_name => 'User'
  belongs_to :grading_period
  belongs_to :group
  belongs_to :media_object

  belongs_to :quiz_submission, :class_name => 'Quizzes::QuizSubmission'
  has_many :all_submission_comments, -> { order(:created_at) }, class_name: 'SubmissionComment', dependent: :destroy
  has_many :submission_comments, -> { order(:created_at).where(provisional_grade_id: nil) }
  has_many :visible_submission_comments,
    -> { published.visible.for_final_grade.order(:created_at, :id) },
    class_name: 'SubmissionComment'
  has_many :hidden_submission_comments, -> { order('created_at, id').where(provisional_grade_id: nil, hidden: true) }, class_name: 'SubmissionComment'
  has_many :assessment_requests, :as => :asset
  has_many :assigned_assessments, :class_name => 'AssessmentRequest', :as => :assessor_asset
  has_many :rubric_assessments, :as => :artifact
  has_many :attachment_associations, :as => :context, :inverse_of => :context
  has_many :provisional_grades, class_name: 'ModeratedGrading::ProvisionalGrade'
  has_many :originality_reports
  has_one :rubric_assessment, -> { where(assessment_type: 'grading') }, as: :artifact, inverse_of: :artifact
  has_one :lti_result, inverse_of: :submission, class_name: 'Lti::Result', dependent: :destroy

  # we no longer link submission comments and conversations, but we haven't fixed up existing
  # linked conversations so this relation might be useful
  # TODO: remove this when removing the conversationmessage asset columns
  has_many :conversation_messages, :as => :asset # one message per private conversation

  has_many :content_participations, :as => :content

  has_many :canvadocs_submissions

  serialize :turnitin_data, Hash

  validates_presence_of :assignment_id, :user_id
  validates_length_of :body, :maximum => maximum_long_text_length, :allow_nil => true, :allow_blank => true
  validates_length_of :published_grade, :maximum => maximum_string_length, :allow_nil => true, :allow_blank => true
  validates_as_url :url
  validates :points_deducted, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :seconds_late_override, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :late_policy_status, inclusion: ['none', 'missing', 'late'], allow_nil: true
  validate :ensure_grader_can_grade

  scope :active, -> { where("submissions.workflow_state <> 'deleted'") }
  scope :for_enrollments, -> (enrollments) { where(user_id: enrollments.select(:user_id)) }
  scope :with_comments, -> { preload(:submission_comments) }
  scope :unread_for, -> (user_id) do
    joins(:content_participations).
    where(user_id: user_id, content_participations: {workflow_state: 'unread', user_id: user_id})
  end
  scope :after, lambda { |date| where("submissions.created_at>?", date) }
  scope :before, lambda { |date| where("submissions.created_at<?", date) }
  scope :submitted_before, lambda { |date| where("submitted_at<?", date) }
  scope :submitted_after, lambda { |date| where("submitted_at>?", date) }
  scope :with_point_data, -> { where("submissions.score IS NOT NULL OR submissions.grade IS NOT NULL") }

  scope :for_context_codes, lambda { |context_codes| where(:context_code => context_codes) }

  # This should only be used in the course drop down to show assignments recently graded.
  scope :recently_graded_assignments, lambda { |user_id, date, limit|
    select("assignments.id, assignments.title, assignments.points_possible, assignments.due_at,
            submissions.grade, submissions.score, submissions.graded_at, assignments.grading_type,
            assignments.context_id, assignments.context_type, courses.name AS context_name").
    joins(:assignment).
    joins("JOIN #{Course.quoted_table_name} ON courses.id=assignments.context_id").
    where("graded_at>? AND user_id=? AND muted=?", date, user_id, false).
    order("graded_at DESC").
    limit(limit)
  }

  scope :for_course, -> (course) { where(assignment: course.assignments.except(:order)) }
  scope :for_assignment, -> (assignment) { where(assignment: assignment) }

  scope :missing, -> do
    joins(:assignment).
    where("
      -- if excused is false or null, and...
      excused IS NOT TRUE AND (
        -- teacher said it's missing, 'nuff said.
        late_policy_status = 'missing' OR
        (
          -- Otherwise, submission does not have a late policy applied and
          late_policy_status is null and
          -- submission is past due and
          COALESCE(submitted_at, CURRENT_TIMESTAMP) >= cached_due_date +
            CASE submission_type WHEN 'online_quiz' THEN interval '1 minute' ELSE interval '0 minutes' END and
          -- submission is not submitted and
          NULLIF(submission_type, '') is null and
          -- we expect a digital submission
          COALESCE(NULLIF(assignments.submission_types, ''), 'none') not similar to '%(none|not\_graded|on\_paper|wiki\_page|external\_tool)%'
        )
      )
    ")
  end

  scope :not_missing, -> do
    joins(:assignment).
    where("
      -- excused submissions cannot be missing
      excused IS TRUE OR (
        -- teacher hasn't said it's missing and
        late_policy_status is distinct from 'missing' and
        (
          -- late policy status was overridden but the value is not 'missing', or
          late_policy_status IS NOT NULL OR
          -- submission is not past due or
          cached_due_date is null or
          COALESCE(submitted_at, CURRENT_TIMESTAMP) < cached_due_date +
            CASE submission_type WHEN 'online_quiz' THEN interval '1 minute' ELSE interval '0 minutes' END or
          -- submission is submitted or
          NULLIF(submission_type, '') is not null or
          -- we expect an offline submission
          COALESCE(NULLIF(assignments.submission_types, ''), 'none') similar to
            '%(none|not\_graded|on\_paper|wiki\_page|external\_tool)%'
        )
      )
    ")
  end

  scope :late, -> do
    left_joins(:quiz_submission).
    where("
      submissions.excused IS NOT TRUE AND (
        submissions.late_policy_status = 'late' OR
        (submissions.late_policy_status IS NULL AND submissions.submitted_at >= submissions.cached_due_date +
           CASE submissions.submission_type WHEN 'online_quiz' THEN interval '1 minute' ELSE interval '0 minutes' END
           AND (submissions.quiz_submission_id IS NULL OR quiz_submissions.workflow_state = 'complete'))
      )
    ")
  end

  scope :not_late, -> do
    left_joins(:quiz_submission).
    where("
      submissions.excused IS TRUE OR (
        submissions.late_policy_status is distinct from 'late' AND
        (submissions.submitted_at IS NULL OR submissions.cached_due_date IS NULL OR
          submissions.submitted_at < submissions.cached_due_date +
            CASE submissions.submission_type WHEN 'online_quiz' THEN interval '1 minute' ELSE interval '0 minutes' END
          OR quiz_submissions.workflow_state <> 'complete')
      )
    ")
  end

  GradedAtBookmarker = BookmarkedCollection::SimpleBookmarker.new(Submission, :graded_at)
  IdBookmarker = BookmarkedCollection::SimpleBookmarker.new(Submission, :id)

  scope :anonymized, -> { where.not(anonymous_id: nil) }

  workflow do
    state :submitted do
      event :grade_it, :transitions_to => :graded
    end
    state :unsubmitted
    state :pending_review
    state :graded
    state :deleted
  end
  alias needs_review? pending_review?

  delegate :auditable?, to: :assignment, prefix: true
  delegate :can_be_moderated_grader?, to: :assignment, prefix: true

  def self.anonymous_ids_for(assignment)
    anonymized.for_assignment(assignment).pluck(:anonymous_id)
  end

  # see #needs_grading?
  # When changing these conditions, update index_submissions_needs_grading to
  # maintain performance.
  def self.needs_grading_conditions
    conditions = <<-SQL
      submissions.submission_type IS NOT NULL
      AND (submissions.excused = 'f' OR submissions.excused IS NULL)
      AND (submissions.workflow_state = 'pending_review'
        OR (submissions.workflow_state IN ('submitted', 'graded')
          AND (submissions.score IS NULL OR NOT submissions.grade_matches_current_submission)
        )
      )
    SQL
    conditions.gsub!(/\s+/, ' ')
    conditions
  end

  # see .needs_grading_conditions
  def needs_grading?(was = false)
    suffix = was ? "_before_last_save" : ""

    !send("submission_type#{suffix}").nil? &&
    (send("workflow_state#{suffix}") == 'pending_review' ||
     (['submitted', 'graded'].include?(send("workflow_state#{suffix}")) &&
      (send("score#{suffix}").nil? || !send("grade_matches_current_submission#{suffix}"))
     )
    )
  end

  def resubmitted?
    needs_grading? && grade_matches_current_submission == false
  end

  def needs_grading_changed?
    needs_grading? != needs_grading?(:was)
  end

  scope :needs_grading, -> {
    all.primary_shard.activate do
      joins("INNER JOIN #{Enrollment.quoted_table_name} ON submissions.user_id=enrollments.user_id")
      .where(needs_grading_conditions)
      .where(Enrollment.active_student_conditions)
      .distinct
    end
  }

  scope :needs_grading_count, -> {
    select("COUNT(submissions.id)")
    .needs_grading
  }

  sanitize_field :body, CanvasSanitize::SANITIZE

  attr_accessor :saved_by,
                :assignment_changed_not_sub,
                :grading_error_message,
                :grade_change_event_author_id

  # Because set_anonymous_id makes database calls, delay it until just before
  # validation. Otherwise if we place it in any earlier (e.g.
  # before/after_initialize), every Submission.new will make database calls.
  before_validation :set_anonymous_id, if: :new_record?
  before_save :apply_late_policy, if: :late_policy_relevant_changes?
  before_save :update_if_pending
  before_save :validate_single_submission, :infer_values
  before_save :prep_for_submitting_to_plagiarism
  before_save :check_url_changed
  before_save :check_reset_graded_anonymously
  after_save :touch_user
  after_save :touch_graders
  after_save :update_assignment
  after_save :update_attachment_associations
  after_save :submit_attachments_to_canvadocs
  after_save :queue_websnap
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

  def reset_regraded
    @regraded = false
  end

  def autograded?
    # AutoGrader == (quiz_id * -1)
    !!(self.grader_id && self.grader_id < 0)
  end

  def touch_assignments
    Assignment.
      where(id: assignment_id, context_type: 'Course').
      where("EXISTS (?)",
        Enrollment.where(Enrollment.active_student_conditions).
        where(user_id: user_id).
        where("course_id=assignments.context_id")).
      update_all(["updated_at=?", Time.now.utc])
    # TODO: add this to the SQL above when DA is on for everybody
    # and remove NeedsGradingCountQuery#manual_count
    # AND EXISTS (SELECT assignment_student_visibilities.* WHERE assignment_student_visibilities.user_id = NEW.user_id AND assignment_student_visibilities.assignment_id = NEW.assignment_id);
  end

  after_create :needs_grading_count_updated, if: :needs_grading?
  after_update :needs_grading_count_updated, if: :needs_grading_changed?
  after_update :update_planner_override
  def needs_grading_count_updated
    self.class.connection.after_transaction_commit do
      touch_assignments
    end
  end

  def update_planner_override
    return unless self.saved_change_to_workflow_state?
    if self.submission_type == "online_quiz" && self.workflow_state == "graded"
      # unless it's an auto-graded quiz
      return unless self.workflow_state_before_last_save == "unsubmitted"
      complete_planner_override_for_submission(self)
    else
      return unless self.workflow_state == "submitted"
      complete_planner_override_for_submission(self)
    end
  end

  attr_reader :group_broadcast_submission

  has_a_broadcast_policy

  simply_versioned :explicit => true,
    :when => lambda{ |model| model.new_version_needed? },
    :on_create => lambda{ |model,version| SubmissionVersion.index_version(version) },
    :on_load => lambda{ |model,version| model&.cached_due_date = version.versionable&.cached_due_date }

  # This needs to be after simply_versioned because the grade change audit uses
  # versioning to grab the previous grade.
  after_save :grade_change_audit

  def new_version_needed?
    turnitin_data_changed? || vericite_data_changed? || (changes.keys - [
      "updated_at",
      "processed",
      "process_attempts",
      "grade_matches_current_submission",
      "published_score",
      "published_grade"
    ]).present?
  end

  set_policy do
    given do |user|
      user &&
        user.id == self.user_id &&
        self.assignment.published?
    end
    can :read and can :comment and can :make_group_comment and can :submit

    # see user_can_read_grade? before editing :read_grade permissions
    given do |user|
      user &&
        user.id == self.user_id &&
        !self.assignment.muted?
    end
    can :read_grade

    given do |user, session|
      self.assignment.published? &&
        self.assignment.context.grants_right?(user, session, :manage_grades)
    end
    can :read and can :comment and can :make_group_comment and can :read_grade and can :read_comments

    given do |user, _session|
      can_grade?(user)
    end
    can :grade

    given do
      can_autograde?
    end
    can :autograde

    given do |user, session|
      self.assignment.user_can_read_grades?(user, session)
    end
    can :read and can :read_grade

    given do |user|
      self.assignment &&
        self.assignment.context &&
        user &&
        self.user &&
        self.assignment.context.observer_enrollments.where(
          user_id: user,
          associated_user_id: self.user,
          workflow_state: 'active'
        ).exists?
    end
    can :read and can :read_comments

    given do |user|
      self.assignment &&
        !self.assignment.muted? &&
        self.assignment.context &&
        user &&
        self.user &&
        self.assignment.context.observer_enrollments.where(
          user_id: user,
          associated_user_id: self.user,
          workflow_state: 'active'
        ).first.try(:grants_right?, user, :read_grades)
    end
    can :read_grade

    given do |user|
      self.assignment.published? &&
        self.assignment.peer_reviews &&
        self.assignment.context.participating_students.where(id: self.user).exists? &&
        user &&
        self.assessment_requests.map(&:assessor_id).include?(user.id)
    end
    can :read and can :comment

    given { |user, session|
      can_view_plagiarism_report('turnitin', user, session)
    }

    can :view_turnitin_report

    given { |user, session|
      can_view_plagiarism_report('vericite', user, session)
    }
    can :view_vericite_report
  end

  def can_view_details?(user)
    return false unless grants_right?(user, :read)
    return true unless self.assignment.anonymize_students?
    user == self.user || Account.site_admin.grants_right?(user, :update)
  end

  def can_view_plagiarism_report(type, user, session)
    if type == "vericite"
      return false unless self.vericite_data_hash[:provider].to_s == "vericite"
      plagData = self.vericite_data_hash
      @submit_to_vericite = false
      settings = assignment.vericite_settings
      type_can_peer_review = true
    else
      return false unless self.turnitin_data[:provider].to_s != "vericite"
      plagData = self.turnitin_data
      @submit_to_turnitin = false
      settings = assignment.turnitin_settings
      type_can_peer_review = false
    end
    return plagData &&
    (user_can_read_grade?(user, session) || (type_can_peer_review && user_can_peer_review_plagiarism?(user))) &&
    (assignment.context.grants_right?(user, session, :manage_grades) ||
      case settings[:originality_report_visibility]
       when 'immediate' then true
       when 'after_grading' then current_submission_graded?
       when 'after_due_date'
         then assignment.due_at && assignment.due_at < Time.now.utc
       when 'never' then false
      end
    )
  end

  def user_can_peer_review_plagiarism?(user)
    assignment.peer_reviews &&
    assignment.current_submissions_and_assessors[:submissions].select{ |submission|
      # first filter by submissions for the requested reviewer
      user.id == submission.user_id &&
      submission.assigned_assessments
    }.any? {|submission|
      # next filter the assigned assessments by the submission user_id being reviewed
      submission.assigned_assessments.any? {|review| user_id == review.user_id}
    }
  end

  def user_can_read_grade?(user, session=nil)
    # improves performance by checking permissions on the assignment before the submission
    return true if self.assignment.user_can_read_grades?(user, session)

    return false if self.assignment.muted? # if you don't have manage rights from the assignment you can't read if it's muted
    return true if user && user.id == self.user_id # this is fast, so skip the policy cache check if possible

    self.grants_right?(user, session, :read_grade)
  end

  on_update_send_to_streams do
    if self.graded_at && self.graded_at > 5.minutes.ago && !@already_sent_to_stream
      @already_sent_to_stream = true
      self.user_id
    end
  end

  def can_read_submission_user_name?(user, session)
    !self.assignment.anonymous_peer_reviews? ||
        self.user_id == user.id ||
        self.assignment.context.grants_right?(user, session, :view_all_grades)
  end

  def update_final_score
    if saved_change_to_score? || saved_change_to_excused? ||
        (workflow_state_before_last_save == "pending_review" && workflow_state == "graded")
      if skip_grade_calc
        Rails.logger.debug "GRADES: NOT recomputing scores for submission #{global_id} because skip_grade_calc was set"
      else
        Rails.logger.debug "GRADES: submission #{global_id} score changed. recomputing grade for course #{context.global_id} user #{user_id}."
        self.class.connection.after_transaction_commit do
          Enrollment.recompute_final_score_in_singleton(
            self.user_id,
            self.context.id,
            grading_period_id: grading_period_id
          )
        end
      end
      self.assignment&.send_later_if_production(:multiple_module_actions, [self.user_id], :scored, self.score)
    end
    true
  end

  def create_alert
    return unless saved_change_to_score? && self.grader_id && !self.autograded? &&
      self.assignment.points_possible && self.assignment.points_possible > 0

    thresholds = ObserverAlertThreshold.active.where(student: self.user,
      alert_type: ['assignment_grade_high', 'assignment_grade_low'])

    thresholds.each do |threshold|
      prev_score = saved_changes['score'][0]
      prev_percentage = prev_score.present? ? prev_score.to_f / self.assignment.points_possible * 100 : nil
      percentage = self.score.present? ? self.score.to_f / self.assignment.points_possible * 100 : nil
      next unless threshold.did_pass_threshold(prev_percentage, percentage)

      observer = threshold.observer
      next unless observer
      next unless observer.observer_enrollments.active.
          where(course_id: self.assignment.context_id, associated_user: self.user).any?

      begin
        ObserverAlert.create!(
          observer: observer,
          student: self.user,
          observer_alert_threshold: threshold,
          context: self.assignment,
          alert_type: threshold.alert_type,
          action_date: self.graded_at,
          title: I18n.t("Assignment graded: %{grade} on %{assignment_name} in %{course_code}",
            {
              grade: self.grade,
              assignment_name: self.assignment.title,
              course_code: self.assignment.course.course_code
            })
        )
      rescue ActiveRecord::RecordInvalid
        Rails.logger.error(
          "Couldn't create ObserverAlert for submission #{self.id} observer #{threshold.observer_id}"
        )
      end
    end
  end

  def update_quiz_submission
    return true if @saved_by == :quiz_submission || !self.quiz_submission_id || self.score == self.quiz_submission.kept_score
    self.quiz_submission.set_final_score(self.score)
    true
  end

  def url
    read_body = read_attribute(:body) && CGI::unescapeHTML(read_attribute(:body))
    if read_body && read_attribute(:url) && read_body[0..250] == read_attribute(:url)[0..250]
      @full_url = read_attribute(:body)
    else
      @full_url = read_attribute(:url)
    end
  end

  def plaintext_body
    self.extend HtmlTextHelper
    strip_tags((self.body || "").gsub(/\<\s*br\s*\/\>/, "\n<br/>").gsub(/\<\/p\>/, "</p>\n"))
  end

  TURNITIN_STATUS_RETRY = 11
  def check_turnitin_status(attempt=1)
    self.turnitin_data ||= {}
    turnitin = nil
    needs_retry = false

    # check all assets in the turnitin_data (self.turnitin_assets is only the
    # current assets) so that we get the status for assets of previous versions
    # of the submission as well
    self.turnitin_data.keys.each do |asset_string|
      data = self.turnitin_data[asset_string]
      next unless data && data.is_a?(Hash) && data[:object_id]
      if data[:similarity_score].blank?
        if attempt < TURNITIN_STATUS_RETRY
          turnitin ||= Turnitin::Client.new(*self.context.turnitin_settings)
          res = turnitin.generateReport(self, asset_string)
          if res[:similarity_score]
            data[:similarity_score] = res[:similarity_score].to_f
            data[:web_overlap] = res[:web_overlap].to_f
            data[:publication_overlap] = res[:publication_overlap].to_f
            data[:student_overlap] = res[:student_overlap].to_f
            data[:state] = Turnitin.state_from_similarity_score data[:similarity_score]
            data[:status] = 'scored'
          else
            needs_retry ||= true
          end
        else
          data[:status] = 'error'
          data[:public_error_message] = I18n.t('turnitin.no_score_after_retries', 'Turnitin has not returned a score after %{max_tries} attempts to retrieve one.', max_tries: TURNITIN_RETRY)
        end
      else
        data[:status] = 'scored'
      end
      self.turnitin_data[asset_string] = data
    end

    send_at((2 ** attempt).minutes.from_now, :check_turnitin_status, attempt + 1) if needs_retry
    self.turnitin_data_changed!
    self.save
  end

  def turnitin_report_url(asset_string, user)
    if self.turnitin_data && self.turnitin_data[asset_string] && self.turnitin_data[asset_string][:similarity_score]
      turnitin = Turnitin::Client.new(*self.context.turnitin_settings)
      self.send_later(:check_turnitin_status)
      if self.grants_right?(user, :grade)
        turnitin.submissionReportUrl(self, asset_string)
      elsif self.grants_right?(user, :view_turnitin_report)
        turnitin.submissionStudentReportUrl(self, asset_string)
      end
    else
      nil
    end
  end

  TURNITIN_JOB_OPTS = { :n_strand => 'turnitin', :priority => Delayed::LOW_PRIORITY, :max_attempts => 2 }

  TURNITIN_RETRY = 5
  def submit_to_turnitin(attempt=0)
    return unless turnitinable? && self.context.turnitin_settings
    turnitin = Turnitin::Client.new(*self.context.turnitin_settings)
    reset_turnitin_assets

    # Make sure the assignment exists and user is enrolled
    assignment_created = self.assignment.create_in_turnitin
    turnitin_enrollment = turnitin.enrollStudent(self.context, self.user)
    if assignment_created && turnitin_enrollment.success?
      delete_turnitin_errors
    else
      if attempt < TURNITIN_RETRY
        send_later_enqueue_args(:submit_to_turnitin, { :run_at => 5.minutes.from_now }.merge(TURNITIN_JOB_OPTS), attempt + 1)
      else
        assignment_error = assignment.turnitin_settings[:error]
        self.turnitin_data[:status] = 'error'
        self.turnitin_data[:assignment_error] = assignment_error if assignment_error.present?
        self.turnitin_data[:student_error] = turnitin_enrollment.error_hash if turnitin_enrollment.error?
        self.turnitin_data_changed!
        self.save
      end
      return false
    end

    # Submit the file(s)
    submission_response = turnitin.submitPaper(self)
    submission_response.each do |res_asset_string, response|
      self.turnitin_data[res_asset_string].merge!(response)
      self.turnitin_data_changed!
      if !response[:object_id] && !(attempt < TURNITIN_RETRY)
        self.turnitin_data[res_asset_string][:status] = 'error'
      end
    end

    send_later_enqueue_args(:check_turnitin_status, { :run_at => 5.minutes.from_now }.merge(TURNITIN_JOB_OPTS))
    self.save

    # Schedule retry if there were failures
    submit_status = submission_response.present? && submission_response.values.all?{ |v| v[:object_id] }
    unless submit_status
      send_later_enqueue_args(:submit_to_turnitin, { :run_at => 5.minutes.from_now }.merge(TURNITIN_JOB_OPTS), attempt + 1) if attempt < TURNITIN_RETRY
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
        report_url: originality_report.originality_report_url,
        status: originality_report.workflow_state
      }
    end
    ret_val = turnitin_data.merge(data)
    ret_val.delete(:provider)
    ret_val
  end

  def text_entry_originality_reports
    @text_entry_originality_reports ||= begin
      if self.association(:originality_reports).loaded?
        originality_reports.select { |o| o.attachment_id.blank? }
      else
        originality_reports.where(attachment_id: nil)
      end
    end
  end

  def originality_reports_for_display
    (versioned_originality_reports + text_entry_originality_reports).uniq.sort_by(&:created_at)
  end

  def turnitin_assets
    if self.submission_type == 'online_upload'
      self.attachments.select{ |a| a.turnitinable? }
    elsif self.submission_type == 'online_text_entry'
      [self]
    else
      []
    end
  end

  # Preload OriginalityReport before using this method
  def originality_report_url(asset_string, user)
    if asset_string == self.asset_string
      originality_reports.where(attachment_id: nil).first&.report_launch_path
    elsif self.grants_right?(user, :view_turnitin_report)
      requested_attachment = all_versioned_attachments.find_by_asset_string(asset_string)
      scope = association(:originality_reports).loaded? ? versioned_originality_reports : originality_reports
      report = scope.find_by(attachment: requested_attachment)
      report&.report_launch_path
    end
  end

  def has_originality_report?
    versioned_originality_reports.present? ||
    text_entry_originality_reports.present?
  end

  def all_versioned_attachments
    attachment_ids = submission_history.map(&:attachment_ids_for_version).flatten.uniq
    Attachment.where(id: attachment_ids)
  end
  private :all_versioned_attachments

  def attachment_ids_for_version
    ids = (attachment_ids || '').split(',').map(&:to_i)
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
      asset_data[:status] = 'pending'
      [:error_code, :error_message, :public_error_message].each do |key|
        asset_data.delete(key)
      end
      self.turnitin_data[a.asset_string] = asset_data
      self.turnitin_data_changed!
    end
  end

  def resubmit_to_turnitin
    reset_turnitin_assets
    self.save

    @submit_to_turnitin = true
    turnitinable_by_lti? ? retrieve_lti_tii_score : submit_to_plagiarism_later
  end

  def retrieve_lti_tii_score
    if (tool = ContextExternalTool.tool_for_assignment(self.assignment))
      turnitin_data.select {|_,v| v.try(:key?, :outcome_response) }.each do |k, v|
        Turnitin::OutcomeResponseProcessor.new(tool, self.assignment, self.user, v[:outcome_response].as_json).resubmit(self, k)
      end
    end
  end

  def turnitinable?
    %w(online_upload online_text_entry).include?(submission_type) &&
      assignment.turnitin_enabled?
  end

  def turnitinable_by_lti?
    turnitin_data.select{|_, v| v.is_a?(Hash) && v.key?(:outcome_response)}.any?
  end

  # VeriCite

  # this function will check if the score needs to be updated and update/save the new score if so,
  # otherwise, it just returns the vericite_data_hash
  def vericite_data(lookup_data = false)
    self.vericite_data_hash ||= {}
    # check to see if the score is stale, if so, fetch it again
    update_scores = false
    if Canvas::Plugin.find(:vericite).try(:enabled?) && !self.readonly? && lookup_data
      self.vericite_data_hash.keys.each do |asset_string|
        data = self.vericite_data_hash[asset_string]
        next unless data && data.is_a?(Hash) && data[:object_id]
        update_scores = update_scores || vericite_recheck_score(data)
      end
      # we have found at least one score that is stale, call VeriCite and save the results
      if update_scores
        check_vericite_status(0)
      end
    end
    if !self.vericite_data_hash.empty?
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
    if !data[:similarity_score_time].blank?
      now = Time.now.to_i
      score_age = Time.now.to_i - data[:similarity_score_time]
      score_cache_time = 1200 # by default cache scores for 20 mins
      # change the cache based on how long it has been since the paper was submitted
      # if !data[:submit_time].blank? && (now - data[:submit_time]) > 86400
      # # it has been more than 24 hours since this was submitted, increase cache time
      #   score_cache_time = 86400
      # end
      # only cache the score for 20 minutes or 24 hours based on when the paper was submitted
      if(score_age > score_cache_time)
        #check if we just recently requested this score
        last_checked = 1000 # default to a high number so that if it is not set, it won't effect the outcome
        if !data[:similarity_score_check_time].blank?
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

   VERICITE_STATUS_RETRY = 16 #this caps the retries off at 36 hours (checking once every 4 hours)

  def check_vericite_status(attempt=1)
    self.vericite_data_hash ||= {}
    vericite = nil
    needs_retry = false
    # check all assets in the vericite_data (self.vericite_assets is only the
    # current assets) so that we get the status for assets of previous versions
    # of the submission as well

    # flag to make sure that all scores are just updates and not new
    recheck_score_all = true
    data_changed = false
    self.vericite_data_hash.keys.each do |asset_string|
      data = self.vericite_data_hash[asset_string]
      # keep track whether the score state changed
      data_orig = data.dup
      next unless data && data.is_a?(Hash) && data[:object_id]
      # check to see if the score is stale, if so, delete it and fetch again
      recheck_score = vericite_recheck_score(data)
      # keep track whether all scores are updates or if any are new
      recheck_score_all = recheck_score_all && recheck_score
      # look up scores if:
      if recheck_score || data[:similarity_score].blank?
        if attempt < VERICITE_STATUS_RETRY
          data[:similarity_score_check_time] = Time.now.to_i
          vericite ||= VeriCite::Client.new()
          res = vericite.generateReport(self, asset_string)
          if res[:similarity_score]
            # keep track of when we updated the score so that we can ask VC again once it is stale (i.e. cache for 20 mins)
            data[:similarity_score_time] = Time.now.to_i
            data[:similarity_score] = res[:similarity_score].to_i
            data[:state] = VeriCite.state_from_similarity_score data[:similarity_score]
            data[:status] = 'scored'
            # since we have a score, we know this report shouldn't have any errors, clear them out
            data = clear_vericite_errors(data)
          else
            needs_retry ||= true
          end
        elsif !recheck_score # if we already have a score, continue to use it and do not set an error
          data[:status] = 'error'
          data[:public_error_message] = I18n.t('vericite.no_score_after_retries', 'VeriCite has not returned a score after %{max_tries} attempts to retrieve one.', max_tries: VERICITE_RETRY)
        end
      else
        data[:status] = 'scored'
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
    retry_mins = 2 ** attempt
    if retry_mins > 240
      #cap the retry max wait to 4 hours
      retry_mins = 240;
    end
    # if attempt <= 0, then that means no retries should be attempted
    send_at(retry_mins.minutes.from_now, :check_vericite_status, attempt + 1) if attempt > 0 && needs_retry
    # if all we did was recheck scores, do not version this save (i.e. increase the attempt number)
    if data_changed
      self.vericite_data_changed!
      if recheck_score_all
        self.with_versioning( false ) do |t|
          t.save!
        end
      else
        self.save
      end
    end
  end

  def vericite_report_url(asset_string, user, session)
    if self.vericite_data_hash && self.vericite_data_hash[asset_string] && self.vericite_data_hash[asset_string][:similarity_score]
      vericite = VeriCite::Client.new()
      if self.grants_right?(user, :grade)
        vericite.submissionReportUrl(self, user, asset_string)
      elsif can_view_plagiarism_report('vericite', user, session)
        vericite.submissionStudentReportUrl(self, user, asset_string)
      end
    else
      nil
    end
  end

  VERICITE_JOB_OPTS = { :n_strand => 'vericite', :priority => Delayed::LOW_PRIORITY, :max_attempts => 2 }

  VERICITE_RETRY = 5
  def submit_to_vericite(attempt=0)
    Rails.logger.info("VERICITE #submit_to_vericite submission ID: #{self.id}, vericiteable? #{vericiteable?}")
    if vericiteable?
      Rails.logger.info("VERICITE #submit_to_vericite submission ID: #{self.id}, plugin: #{Canvas::Plugin.find(:vericite)}, vericite plugin enabled? #{Canvas::Plugin.find(:vericite).try(:enabled?)}")
    end
    return unless vericiteable? && Canvas::Plugin.find(:vericite).try(:enabled?)
    vericite = VeriCite::Client.new()
    reset_vericite_assets

    # Make sure the assignment exists and user is enrolled
    assignment_created = self.assignment.create_in_vericite
    #vericite_enrollment = vericite.enrollStudent(self.context, self.user)
    if assignment_created
      delete_vericite_errors
    else
      assignment_error = assignment.vericite_settings[:error]
      self.vericite_data_hash[:assignment_error] = assignment_error if assignment_error.present?
      #self.vericite_data_hash[:student_error] = vericite_enrollment.error_hash if vericite_enrollment.error?
      self.vericite_data_changed!
      if !self.vericite_data_hash.empty?
        # only set vericite provider flag if the hash isn't empty
        self.vericite_data_hash[:provider] = :vericite
      end
      self.save
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
      self.vericite_data_changed!
      if !response[:object_id] && !(attempt < VERICITE_RETRY)
        self.vericite_data_hash[res_asset_string][:status] = 'error'
      elsif response[:object_id]
        # success, make sure any error messages are cleared
        self.vericite_data_hash[res_asset_string] = clear_vericite_errors(self.vericite_data_hash[res_asset_string])
      end
    end
    # only save if there were newly submitted attachments
    if update
      send_later_enqueue_args(:check_vericite_status, { :run_at => 5.minutes.from_now }.merge(VERICITE_JOB_OPTS))
      if !self.vericite_data_hash.empty?
        # only set vericite provider flag if the hash isn't empty
        self.vericite_data_hash[:provider] = :vericite
      end
      self.save

      # Schedule retry if there were failures
      submit_status = submission_response.present? && submission_response.values.all?{ |v| v[:object_id] }
      unless submit_status
        send_later_enqueue_args(:submit_to_vericite, { :run_at => 5.minutes.from_now }.merge(VERICITE_JOB_OPTS), attempt + 1) if attempt < VERICITE_RETRY
        return false
      end
    end

    true
  end

  def vericite_assets
    if self.submission_type == 'online_upload'
      self.attachments.select{ |a| a.vericiteable? }
    elsif self.submission_type == 'online_text_entry'
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
      asset_data[:status] = 'pending'
      asset_data = clear_vericite_errors(asset_data)
      self.vericite_data_hash[a.asset_string] = asset_data
      self.vericite_data_changed!
    end
  end

  def clear_vericite_errors(asset_data)
    [:error_code, :error_message, :public_error_message].each do |key|
      asset_data.delete(key)
    end
    asset_data
  end


  def resubmit_to_vericite
    reset_vericite_assets
    if !self.vericite_data_hash.empty?
      # only set vericite provider flag if the hash isn't empty
      self.vericite_data_hash[:provider] = :vericite
    end

    @submit_to_vericite = true
    self.save
  end

  def vericiteable?
    %w(online_upload online_text_entry).include?(submission_type) &&
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
    elsif !self.context.turnitin_settings.nil?
      :turnitin
    end
  end

  def prep_for_submitting_to_plagiarism
    return unless plagiarism_service_to_use

    if plagiarism_service_to_use == :vericite
      plagData = self.vericite_data_hash
      @submit_to_vericite = false
      canSubmit = self.vericiteable?
    else
      plagData = self.turnitin_data
      @submit_to_turnitin = false
      canSubmit = self.turnitinable?
    end
    last_attempt = plagData && plagData[:last_processed_attempt]
    Rails.logger.info("#prep_for_submitting_to_plagiarism submission ID: #{self.id}, type: #{plagiarism_service_to_use}, canSubmit? #{canSubmit}")
    Rails.logger.info("#prep_for_submitting_to_plagiarism submission ID: #{self.id}, last_attempt: #{last_attempt}, self.attempt: #{self.attempt}, @group_broadcast_submission: #{@group_broadcast_submission}, self.group: #{self.group}")
    if canSubmit && (!last_attempt || last_attempt < self.attempt) && (@group_broadcast_submission || !self.group)
      if plagData[:last_processed_attempt] != self.attempt
        plagData[:last_processed_attempt] = self.attempt
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
      canSubmit = self.vericiteable?
      delayName = 'vericite_submission_delay_seconds'
      delayFunction = :submit_to_vericite
      delayOpts = VERICITE_JOB_OPTS
    else
      submitPlag = @submit_to_turnitin
      canSubmit = self.turnitinable?
      delayName = 'turnitin_submission_delay_seconds'
      delayFunction = :submit_to_turnitin
      delayOpts = TURNITIN_JOB_OPTS
    end
    Rails.logger.info("#submit_to_plagiarism_later submission ID: #{self.id}, type: #{plagiarism_service_to_use}, canSubmit? #{canSubmit}, submitPlag? #{submitPlag}")
    if canSubmit && submitPlag
      delay = Setting.get(delayName, 60.to_s).to_i
      send_later_enqueue_args(delayFunction, { :run_at => delay.seconds.from_now }.merge(delayOpts))
    end
  end
  # End Plagiarism functions

  def external_tool_url
    URI.encode(url) if self.submission_type == 'basic_lti_launch'
  end

  def touch_graders
    self.class.connection.after_transaction_commit do
      if self.assignment && self.user && self.assignment.context.is_a?(Course)
        self.assignment.context.touch_admins_later
      end
    end
  end

  def update_assignment
    self.send_later(:context_module_action) unless @assignment_changed_not_sub
    true
  end
  protected :update_assignment

  def context_module_action
    if self.assignment && self.user
      if self.score
        self.assignment.context_module_action(self.user, :scored, self.score)
      elsif self.submitted_at
        self.assignment.context_module_action(self.user, :submitted)
      end
    end
  end

  # If an object is pulled from a simply_versioned yaml it may not have a submitted at.
  # submitted_at is needed by the SpeedGrader, so it is set to the updated_at value
  def submitted_at
    if submission_type
      if not read_attribute(:submitted_at)
        write_attribute(:submitted_at, read_attribute(:updated_at))
      end
      read_attribute(:submitted_at).in_time_zone rescue nil
    else
      nil
    end
  end

  def update_attachment_associations
    return if @assignment_changed_not_sub
    association_ids = attachment_associations.pluck(:attachment_id)
    ids = (self.attachment_ids || "").split(",").map(&:to_i)
    ids << self.attachment_id if self.attachment_id
    ids.uniq!
    associations_to_delete = association_ids - ids
    attachment_associations.where(attachment_id: associations_to_delete).delete_all unless associations_to_delete.empty?
    unassociated_ids = ids - association_ids
    return if unassociated_ids.empty?
    attachments = Attachment.where(id: unassociated_ids)
    attachments.each do |a|
      if (a.context_type == 'User' && a.context_id == user_id) ||
         (a.context_type == 'Group' && a.context_id == group_id) ||
         (a.context_type == 'Assignment' && a.context_id == assignment_id && a.available?) ||
         attachment_fake_belongs_to_group(a)
        attachment_associations.where(attachment: a).first_or_create
      end
    end
  end

  def attachment_fake_belongs_to_group(attachment)
    return false if submission_type == 'discussion_topic'
    return false unless attachment.context_type == "User" &&
      assignment.has_group_category?
    gc = assignment.group_category
    gc.group_for(user) == gc.group_for(attachment.context)
  end
  private :attachment_fake_belongs_to_group

  def submit_attachments_to_canvadocs
    if saved_change_to_attachment_ids? && submission_type != 'discussion_topic'
      attachments.preload(:crocodoc_document, :canvadoc).each do |a|
        # associate previewable-document and submission for permission checks
        if a.canvadocable? && Canvadocs.annotations_supported?
          submit_to_canvadocs = true
          a.create_canvadoc! unless a.canvadoc
          a.shard.activate do
            CanvadocsSubmission.find_or_create_by(submission: self, canvadoc: a.canvadoc)
          end
        elsif a.crocodocable?
          submit_to_canvadocs = true
          a.create_crocodoc_document! unless a.crocodoc_document
          a.shard.activate do
            CanvadocsSubmission.find_or_create_by(submission: self, crocodoc_document: a.crocodoc_document)
          end
        end

        if submit_to_canvadocs
          opts = {
            preferred_plugins: [Canvadocs::RENDER_PDFJS, Canvadocs::RENDER_BOX, Canvadocs::RENDER_CROCODOC],
            wants_annotation: true,
            # TODO: Remove the next line after the DocViewer Data Migration project RD-4702
            region: a.shard.database_server.config[:region] || "none"
          }

          if context.root_account.settings[:canvadocs_prefer_office_online]
            # Office 365 should take priority over pdfjs
            opts[:preferred_plugins].unshift Canvadocs::RENDER_O365
          end

          a.send_later_enqueue_args :submit_to_canvadocs, {
            :n_strand     => 'canvadocs',
            :max_attempts => 1,
            :priority => Delayed::LOW_PRIORITY
          }, 1, opts
        end
      end
    end
  end

  def infer_values
    if assignment
      self.context_code = assignment.context_code
    end

    self.seconds_late_override = nil unless late_policy_status == 'late'
    if self.excused_changed? && self.excused
      self.late_policy_status = nil
      self.seconds_late_override = nil
    elsif self.late_policy_status_changed? && self.late_policy_status.present?
      self.excused = false
    end
    self.submitted_at ||= Time.now if self.has_submission?
    self.quiz_submission.reload if self.quiz_submission_id
    self.workflow_state = 'submitted' if self.unsubmitted? && self.submitted_at
    self.workflow_state = 'unsubmitted' if self.submitted? && !self.has_submission?
    self.workflow_state = 'graded' if self.grade && self.score && self.grade_matches_current_submission
    self.workflow_state = 'pending_review' if self.submission_type == 'online_quiz' && self.quiz_submission.try(:latest_submitted_attempt).try(:pending_review?)
    if self.workflow_state_changed? && self.graded?
      self.graded_at = Time.now
    end
    self.media_comment_id = nil if self.media_comment_id && self.media_comment_id.strip.empty?
    if self.media_comment_id && (self.media_comment_id_changed? || !self.media_object_id)
      mo = MediaObject.by_media_id(self.media_comment_id).first
      self.media_object_id = mo && mo.id
    end
    self.media_comment_type = nil unless self.media_comment_id
    if self.submitted_at
      self.attempt ||= 0
      self.attempt += 1 if self.submitted_at_changed?
      self.attempt = 1 if self.attempt < 1
    end
    if self.submission_type == 'media_recording' && !self.media_comment_id
      raise "Can't create media submission without media object"
    end
    if self.submission_type == 'online_quiz'
      self.quiz_submission ||= Quizzes::QuizSubmission.where(submission_id: self).first
      self.quiz_submission ||= Quizzes::QuizSubmission.where(user_id: self.user_id, quiz_id: self.assignment.quiz).first rescue nil
    end
    @just_submitted = (self.submitted? || self.pending_review?) && self.submission_type && (self.new_record? || self.workflow_state_changed?)
    if score_changed? || grade_changed?
      self.grade = assignment ?
        assignment.score_to_grade(score, grade) :
        score.to_s
    end

    self.process_attempts ||= 0
    self.grade = nil if !self.score
    # I think the idea of having unpublished scores is unnecessarily confusing.
    # It may be that we want to have that functionality later on, but for now
    # I say it's just confusing.
    if true #self.assignment && self.assignment.published?
      self.published_score = self.score
      self.published_grade = self.grade
    end
    true
  end

  def just_submitted?
    @just_submitted || false
  end

  def update_admins_if_just_submitted
    if @just_submitted
      context.send_later_if_production(:resubmission_for, assignment)
    end
    true
  end

  def check_for_media_object
    if self.media_comment_id.present? && self.saved_change_to_media_comment_id?
      MediaObject.ensure_media_object(self.media_comment_id, {
        :user => self.user,
        :context => self.user,
      })
    end
  end

  def submission_history
    @submission_histories ||= begin
      res = []
      last_submitted_at = nil
      self.versions.sort_by(&:created_at).reverse_each do |version|
        model = version.model
        # since vericite_data is a function, make sure you are cloning the most recent vericite_data_hash
        if self.vericiteable?
          model.turnitin_data = self.vericite_data(true)
        # only use originality data if it's loaded, we want to avoid making N+1 queries
        elsif self.association(:originality_reports).loaded?
          model.turnitin_data = self.originality_data
        end
        if model.submitted_at && last_submitted_at.to_i != model.submitted_at.to_i
          res << model
          last_submitted_at = model.submitted_at
        end
      end
      res = self.versions.to_a[0,1].map(&:model) if res.empty?
      res = [self] if res.empty?
      res.sort_by{ |s| s.submitted_at || CanvasSort::First }
    end
  end

  def check_url_changed
    @url_changed = self.url && self.url_changed?
    true
  end

  def graded_anonymously=(value)
    @graded_anonymously_set = true
    write_attribute :graded_anonymously, value
  end

  def check_reset_graded_anonymously
    if grade_changed? && !@graded_anonymously_set
      write_attribute :graded_anonymously, false
    end
    true
  end

  def late_policy_status_manually_applied?
    cleared_late = late_policy_status_was == 'late' && ['none', nil].include?(late_policy_status)
    cleared_none = late_policy_status_was == 'none' && late_policy_status.nil?
    late_policy_status == 'missing' || late_policy_status == 'late' || cleared_late || cleared_none
  end
  private :late_policy_status_manually_applied?

  def apply_late_policy(late_policy=nil, incoming_assignment=nil)
    return if points_deducted_changed? || grading_period&.closed?
    incoming_assignment ||= assignment
    return unless late_policy_status_manually_applied? || incoming_assignment.expects_submission? || submitted_to_lti_assignment?(incoming_assignment)
    late_policy ||= incoming_assignment.course.late_policy
    return score_missing(late_policy, incoming_assignment.points_possible, incoming_assignment.grading_type) if missing?
    score_late_or_none(late_policy, incoming_assignment.points_possible, incoming_assignment.grading_type)
  end

  def submitted_to_lti_assignment?(assignment_submitted_to)
    submitted_at.present? && assignment_submitted_to.external_tool?
  end
  private :submitted_to_lti_assignment?

  def score_missing(late_policy, points_possible, grading_type)
    if self.points_deducted.present?
      self.score = entered_score unless score_changed?
      self.points_deducted = nil
    end

    if late_policy&.missing_submission_deduction_enabled && self.score.nil?
      self.score = late_policy.points_for_missing(points_possible, grading_type)
      self.workflow_state = "graded"
    end
  end
  private :score_missing

  def score_late_or_none(late_policy, points_possible, grading_type)
    raw_score = score_changed? || @regraded ? score : entered_score
    deducted = late_points_deducted(raw_score, late_policy, points_possible, grading_type)
    new_score = raw_score && raw_score - deducted
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
      score: raw_score, possible: points_possible, late_for: seconds_late, grading_type: grading_type
    )
  end
  private :late_points_deducted

  def late_policy_relevant_changes?
    return true if @regraded
    return false if grade_matches_current_submission == false # nil is treated as true
    changes.slice(:score, :submitted_at, :seconds_late_override, :late_policy_status).any?
  end
  private :late_policy_relevant_changes?

  def ensure_grader_can_grade
    return true if grader_can_grade?

    error_msg = I18n.t(
      'cannot be changed at this time: %{grading_error}',
      { grading_error: grading_error_message }
    )
    errors.add(:grade, error_msg)
    false
  end

  def grader_can_grade?
    return true unless grade_changed?
    return true if autograded? && grants_right?(nil, :autograde)
    return true if grants_right?(grader, :grade)

    false
  end

  def can_autograde?
    result = GRADE_STATUS_MESSAGES_MAP[can_autograde_symbolic_status]
    result ||= { status: false, message: I18n.t('Cannot autograde at this time') }

    can_autograde_status, @grading_error_message = result[:status], result[:message]

    can_autograde_status
  end
  private :can_autograde?

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
    result ||= { status: false, message: I18n.t('Cannot grade at this time') }

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
    if !self.attachment_id && @url_changed && self.url && self.submission_type == 'online_url'
      self.send_later_enqueue_args(:get_web_snapshot, { :priority => Delayed::LOW_PRIORITY })
    end
  end

  def attachment_ids
    read_attribute :attachment_ids
  end

  def attachment_ids=(ids)
    write_attribute :attachment_ids, ids
  end

  def versioned_originality_reports
    @versioned_originality_reports ||= begin
      attachment_ids = attachment_ids_for_version
      return [] if attachment_ids.empty?
      if self.association(:originality_reports).loaded?
        originality_reports.select { |o| attachment_ids.include?(o.attachment_id) }
      else
        originality_reports.where(attachment_id: attachment_ids)
      end
    end
  end

  def versioned_attachments
    return @versioned_attachments if @versioned_attachments
    attachment_ids = attachment_ids_for_version
    self.versioned_attachments = (attachment_ids.empty? ? [] : Attachment.where(:id => attachment_ids))
    @versioned_attachments
  end

  def versioned_attachments=(attachments)
    @versioned_attachments = Array(attachments).compact.select do |a|
      (a.context_type == 'User' && (a.context_id == user_id || a.user_id == user_id)) ||
      (a.context_type == 'Group' && a.context_id == group_id) ||
      (a.context_type == 'Assignment' && a.context_id == assignment_id && a.available?) ||
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
    Hash[submissions_with_index_and_attachment_ids]
  end
  private_class_method :group_attachment_ids_by_submission_and_index

  # use this method to pre-load the versioned_attachments for a bunch of
  # submissions (avoids having O(N) attachment queries)
  # NOTE: all submissions must belong to the same shard
  def self.bulk_load_versioned_attachments(submissions, preloads: [:thumbnail, :media_object])
    attachment_ids_by_submission_and_index = group_attachment_ids_by_submission_and_index(submissions)
    bulk_attachment_ids = attachment_ids_by_submission_and_index.values.flatten

    attachments_by_id = if bulk_attachment_ids.empty?
      {}
    else
      Attachment.where(:id => bulk_attachment_ids).preload(preloads).group_by(&:id)
    end

    submissions.each_with_index do |s, index|
      s.versioned_attachments =
        attachments_by_id.values_at(*attachment_ids_by_submission_and_index[[s, index]]).flatten
    end
  end

  # use this method to pre-load the versioned_originality_reports for a bunch of
  # submissions (avoids having O(N) originality report queries)
  # NOTE: all submissions must belong to the same shard
  def self.bulk_load_versioned_originality_reports(submissions)
    attachment_ids_by_submission_and_index = group_attachment_ids_by_submission_and_index(submissions)
    bulk_attachment_ids = attachment_ids_by_submission_and_index.values.flatten

    reports_by_attachment_id = if bulk_attachment_ids.empty?
      {}
    else
      OriginalityReport.where(
        submission_id: submissions.map(&:id), attachment_id: bulk_attachment_ids
      ).group_by(&:attachment_id)
    end

    submissions.each_with_index do |s, index|
      s.versioned_originality_reports =
        reports_by_attachment_id.values_at(*attachment_ids_by_submission_and_index[[s, index]]).flatten.compact
    end
  end

  def self.bulk_load_text_entry_originality_reports(submissions)
    submissions = Array(submissions)
    submission_ids = submissions.map(&:id)

    reports_by_submission =
      OriginalityReport.where(submission_id: submission_ids, attachment_id: nil).group_by(&:submission_id)

    submissions.each do |s|
      s.text_entry_originality_reports = reports_by_submission[s.id] || []
    end
  end

  # Avoids having O(N) attachment queries.  Returns a hash of
  # submission to attachements.
  def self.bulk_load_attachments_for_submissions(submissions, preloads: nil)
    submissions = Array(submissions)
    attachment_ids_by_submission =
      Hash[submissions.map { |s| [s, s.attachment_associations.map(&:attachment_id)] }]
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
    Hash[attachments_by_submission]
  end

  def includes_attachment?(attachment)
    self.versions.map(&:model).any? { |v| (v.attachment_ids || "").split(',').map(&:to_i).include?(attachment.id) }
  end

  def <=>(other)
    self.updated_at <=> other.updated_at
  end

  # Submission:
  #   Online submission submitted AFTER the due date (notify the teacher) - "Grade Changes"
  #   Submission graded (or published) - "Grade Changes"
  #   Grade changed - "Grade Changes"
  set_broadcast_policy do |p|

    p.dispatch :assignment_submitted_late
    p.to { assignment.context.instructors_in_charge_of(user_id) }
    p.whenever { |submission|
      BroadcastPolicies::SubmissionPolicy.new(submission).
        should_dispatch_assignment_submitted_late?
    }

    p.dispatch :assignment_submitted
    p.to { assignment.context.instructors_in_charge_of(user_id) }
    p.whenever { |submission|
      BroadcastPolicies::SubmissionPolicy.new(submission).
        should_dispatch_assignment_submitted?
    }

    p.dispatch :assignment_resubmitted
    p.to { assignment.context.instructors_in_charge_of(user_id) }
    p.whenever { |submission|
      BroadcastPolicies::SubmissionPolicy.new(submission).
        should_dispatch_assignment_resubmitted?
    }

    p.dispatch :group_assignment_submitted_late
    p.to { assignment.context.instructors_in_charge_of(user_id) }
    p.whenever { |submission|
      BroadcastPolicies::SubmissionPolicy.new(submission).
        should_dispatch_group_assignment_submitted_late?
    }

    p.dispatch :submission_graded
    p.to { [student] + User.observing_students_in_course(student, assignment.context) }
    p.whenever { |submission|
      BroadcastPolicies::SubmissionPolicy.new(submission).
        should_dispatch_submission_graded?
    }

    p.dispatch :submission_grade_changed
    p.to { [student] + User.observing_students_in_course(student, assignment.context) }
    p.whenever { |submission|
      BroadcastPolicies::SubmissionPolicy.new(submission).
        should_dispatch_submission_grade_changed?
    }

  end

  def assignment_graded_in_the_last_hour?
    graded_at_before_last_save && graded_at_before_last_save > 1.hour.ago
  end

  def teacher
    @teacher ||= self.assignment.teacher_enrollment.user
  end

  def update_if_pending
    @attachments = nil
    if self.submission_type == 'online_quiz' && self.quiz_submission_id && self.score && self.score == self.quiz_submission.score
      self.workflow_state = self.quiz_submission.complete? ? 'graded' : 'pending_review'
    end
    true
  end

  def attachments
    Attachment.where(:id => self.attachment_associations.pluck(:attachment_id))
  end

  def attachments=(attachments)
    # Accept attachments that were already approved, those that were just created
    # or those that were part of some outside context.  This is all to prevent
    # one student from sneakily getting access to files in another user's comments,
    # since they're all being held on the assignment for now.
    attachments ||= []
    old_ids = (Array(self.attachment_ids || "").join(",")).split(",").map{|id| id.to_i}
    write_attribute(:attachment_ids, attachments.select{|a| a && a.id && old_ids.include?(a.id) || (a.recently_created? && a.context == self.assignment) || a.context != self.assignment }.map{|a| a.id}.join(","))
  end

  # someday code-archaeologists will wonder how this method came to be named
  # validate_single_submission.  their guess is as good as mine
  def validate_single_submission
    @full_url = nil
    if read_attribute(:url) && read_attribute(:url).length > 250
      self.body = read_attribute(:url)
      self.url = read_attribute(:url)[0..250]
    end
    unless submission_type
      self.submission_type ||= "online_url" if self.url
      self.submission_type ||= "online_text_entry" if self.body
      self.submission_type ||= "online_upload" unless self.attachment_ids.blank?
    end
    true
  end
  private :validate_single_submission

  def grade_change_audit(force_audit = self.assignment_changed_not_sub)
    newly_graded = self.saved_change_to_workflow_state? && self.workflow_state == 'graded'
    grade_changed = (self.saved_changes.keys & %w(grade score excused)).present?
    return true unless newly_graded || grade_changed || force_audit

    if grade_change_event_author_id.present?
      self.grader_id = grade_change_event_author_id
    end
    self.class.connection.after_transaction_commit { Auditors::GradeChange.record(self) }
  end

  scope :with_assignment, -> { joins(:assignment).merge(Assignment.active)}

  scope :graded, -> { where("(submissions.score IS NOT NULL AND submissions.workflow_state = 'graded') or submissions.excused = true") }

  scope :ungraded, -> { where(:grade => nil).preload(:assignment) }

  scope :in_workflow_state, lambda { |provided_state| where(:workflow_state => provided_state) }

  scope :having_submission, -> { where("submissions.submission_type IS NOT NULL") }
  scope :without_submission, -> { where(submission_type: nil, workflow_state: "unsubmitted") }
  scope :not_placeholder, -> {
    active.where("submissions.submission_type IS NOT NULL or submissions.excused or submissions.score IS NOT NULL or submissions.workflow_state = 'graded'")
  }

  scope :include_user, -> { preload(:user) }

  scope :include_assessment_requests, -> { preload(:assessment_requests, :assigned_assessments) }
  scope :include_versions, -> { preload(:versions) }
  scope :include_submission_comments, -> { preload(:submission_comments) }
  scope :speed_grader_includes, -> { preload(:versions, :submission_comments, :attachments, :rubric_assessment) }
  scope :for_user, lambda { |user| where(:user_id => user) }
  scope :needing_screenshot, -> { where("submissions.submission_type='online_url' AND submissions.attachment_id IS NULL AND submissions.process_attempts<3").order(:updated_at) }

  def assignment_visible_to_user?(user, opts={})
    return visible_to_user unless visible_to_user.nil?
    assignment.visible_to_user?(user, opts)
  end

  def needs_regrading?
    graded? && !grade_matches_current_submission?
  end

  def readable_state
    case workflow_state
    when 'submitted', 'pending_review'
      t 'state.submitted', 'submitted'
    when 'unsubmitted'
      t 'state.unsubmitted', 'unsubmitted'
    when 'graded'
      t 'state.graded', 'graded'
    end
  end

  def grading_type
    return nil unless self.assignment
    self.assignment.grading_type
  end

  # Note 2012-10-12:
  #   Deprecating this method due to view code in the model. The only place
  #   it appears to be used is in the _recent_feedback.html.erb partial.
  def readable_grade
    warn "[DEPRECATED] The Submission#readable_grade method will be removed soon"
    return nil unless grade
    case grading_type
      when 'points'
        "#{grade} out of #{assignment.points_possible}" rescue grade.capitalize
      else
        grade.capitalize
    end
  end

  def last_teacher_comment
    if association(:submission_comments).loaded?
      submission_comments.reverse.detect{ |com| !com.draft && com.author_id != user_id }
    else
      submission_comments.published.where.not(:author_id => user_id).order(:created_at => :desc).first
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
      where(:user_id => obj)
    else
      all
    end
  }

  def processed?
    if submission_type == "online_url"
      return attachment && attachment.content_type.match(/image/)
    end
    false
  end

  def provisional_grade(scorer, final: false, preloaded_grades: nil, default_to_null_grade: true)
    pg = if preloaded_grades
      pgs = preloaded_grades[self.id] || []
      if final
        pgs.detect(&:final)
      else
        pgs.detect{|pg| !pg.final && pg.scorer_id == scorer.id}
      end
    else
      if final
        self.provisional_grades.final.first
      else
        self.provisional_grades.not_final.where(scorer_id: scorer).first
      end
    end

    if default_to_null_grade && pg.nil?
      ModeratedGrading::NullProvisionalGrade.new(self, scorer.id, final)
    else
      pg
    end
  end

  def find_or_create_provisional_grade!(scorer, attrs = {})
    ModeratedGrading::ProvisionalGrade.unique_constraint_retry do
      if attrs[:final] && !self.assignment.permits_moderation?(scorer)
        raise Assignment::GradeError, 'User not authorized to give final provisional grades'
      end

      pg = find_existing_provisional_grade(scorer, attrs[:final]) || self.provisional_grades.build
      pg = update_provisional_grade(pg, scorer, attrs)
      pg.save! if attrs[:force_save] || pg.new_record? || pg.changed?
      pg
    end
  end

  def find_existing_provisional_grade(scorer, final)
    final ? self.provisional_grades.final.first : self.provisional_grades.not_final.find_by(scorer: scorer)
  end

  def moderated_grading_whitelist(current_user = self.user, loaded_attachments: nil)
    return nil unless assignment.moderated_grading? && current_user.present?

    has_crocodoc = (loaded_attachments || attachments).any?(&:crocodoc_available?)
    moderation_whitelist_for_user(current_user).map do |user|
      user.moderated_grading_ids(has_crocodoc)
    end
  end

  def moderation_whitelist_for_user(current_user)
    whitelist = []
    return whitelist unless current_user.present? && assignment.moderated_grading?

    if assignment.grades_published?
      whitelist.push(self.grader, self.user, current_user)
    elsif self.user == current_user
      # Requesting user is the student.
      whitelist << current_user
    elsif assignment.permits_moderation?(current_user)
      # Requesting user is the final grader or an administrator.
      whitelist.push(*assignment.moderation_grader_users_with_slot_taken, self.user, current_user)
    elsif assignment.can_be_moderated_grader?(current_user)
      # Requesting user is a provisional grader, or eligible to be one.
      if assignment.grader_comments_visible_to_graders
        whitelist.push(*assignment.moderation_grader_users_with_slot_taken, self.user, current_user)
      else
        whitelist.push(current_user, self.user)
      end
    end
    whitelist.compact.uniq
  end

  def anonymous_identities
    @anonymous_identities ||= assignment.anonymous_grader_identities_by_user_id.merge({
      user_id => { name: I18n.t('Student'), id: anonymous_id }
    })
  end

  def add_comment(opts={})
    opts = opts.symbolize_keys
    opts[:author] ||= opts[:commenter] || opts[:author] || opts[:user] || self.user unless opts[:skip_author]
    opts[:comment] = opts[:comment].try(:strip) || ""
    opts[:attachments] ||= opts[:comment_attachments]
    opts[:draft] = !!opts[:draft_comment]
    if opts[:comment].empty?
      if opts[:media_comment_id]
        opts[:comment] = t('media_comment', "This is a media comment.")
      elsif opts[:attachments].try(:length)
        opts[:comment] = t('attached_files_comment', "See attached files.")
      end
    end
    if opts[:provisional]
      pg = find_or_create_provisional_grade!(opts[:author], final: opts[:final])
      opts[:provisional_grade_id] = pg.id
    end
    if self.new_record?
      self.save!
    else
      self.touch
    end
    valid_keys = [:comment, :author, :media_comment_id, :media_comment_type,
                  :group_comment_id, :assessment_request, :attachments,
                  :anonymous, :hidden, :provisional_grade_id, :draft]
    if opts[:comment].present?
      comment = submission_comments.create!(opts.slice(*valid_keys))
    end
    opts[:assessment_request].comment_added(comment) if opts[:assessment_request] && comment

    comment
  end

  def comment_authors
    visible_submission_comments.preload(:author).map(&:author)
  end

  def commenting_instructors
    @commenting_instructors ||= comment_authors & context.instructors
  end

  def participating_instructors
    commenting_instructors.present? ? commenting_instructors : context.participating_instructors.to_a.uniq
  end

  def possible_participants_ids
    [user_id] + context.participating_instructors.uniq.map(&:id)
  end

  def limit_comments(user, session=nil)
    @comment_limiting_user = user
    @comment_limiting_session = session
  end

  def apply_provisional_grade_filter!(provisional_grade)
    @provisional_grade_filter = provisional_grade
    self.grade = provisional_grade.grade
    self.score = provisional_grade.score
    self.graded_at = provisional_grade.graded_at
    self.grade_matches_current_submission = provisional_grade.grade_matches_current_submission
    self.readonly!
  end

  def provisional_grade_id
    @provisional_grade_filter ? @provisional_grade_filter.id : nil
  end

  def submission_comments(*args)
    res = if @provisional_grade_filter
            @provisional_grade_filter.submission_comments
          else
            super
          end
    res = res.select{|sc| sc.grants_right?(@comment_limiting_user, @comment_limiting_session, :read) } if @comment_limiting_user
    res
  end

  def visible_submission_comments(*args)
    res = if @provisional_grade_filter
            @provisional_grade_filter.submission_comments.where(hidden: false)
          else
            super
          end
    res = res.select{|sc| sc.grants_right?(@comment_limiting_user, @comment_limiting_session, :read) } if @comment_limiting_user
    res
  end

  def assessment_request_count
    @assessment_requests_count ||= self.assessment_requests.length
  end

  def assigned_assessment_count
    @assigned_assessment_count ||= self.assigned_assessments.length
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
    user = obj.user rescue nil
    association = self.assignment.rubric_association
    res = self.assessment_requests.where(assessor_asset_id: obj.id, assessor_asset_type: obj.class.to_s, assessor_id: user.id, rubric_association_id: association.try(:id)).
      first_or_initialize
    res.user_id = self.user_id
    res.workflow_state = 'assigned' if res.new_record?
    just_created = res.new_record?
    res.send_reminder! # this method also saves the assessment_request
    case obj
    when User
      user = obj
    when Submission
      obj.assign_assessment(res) if just_created
    end
    res
  end

  def students
    self.group ? self.group.users : [self.user]
  end

  def broadcast_group_submission
    @group_broadcast_submission = true
    self.save!
    @group_broadcast_submission = false
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
    alias past_due past_due?

    def late?
      return false if excused?
      return late_policy_status == 'late' if late_policy_status.present?
      submitted_at.present? && past_due?
    end
    alias late late?

    def missing?
      return false if excused?
      return late_policy_status == 'missing' if late_policy_status.present?
      return false if submitted_at.present?
      return false unless past_due?

      assignment.expects_submission?
    end
    alias missing missing?

    def graded?
      excused || (!!score && workflow_state == 'graded')
    end

    def seconds_late
      return (seconds_late_override || 0) if late_policy_status == 'late'
      return 0 if cached_due_date.nil? || time_of_submission <= cached_due_date

      (time_of_submission - cached_due_date).to_i
    end

    def time_of_submission
      time = submitted_at || Time.zone.now
      time -= 60.seconds if submission_type == 'online_quiz'
      time
    end
    private :time_of_submission
  end
  include Tardiness

  def current_submission_graded?
    self.graded? && (!self.submitted_at || (self.graded_at && self.graded_at >= self.submitted_at))
  end

  def context
    self.assignment.context if self.assignment
  end

  def to_atom(opts={})
    prefix = self.assignment.context_prefix || ""
    author_name = self.assignment.present? && self.assignment.context.present? ? self.assignment.context.name : t('atom_no_author', "No Author")
    Atom::Entry.new do |entry|
      entry.title     = "#{self.user && self.user.name} -- #{self.assignment && self.assignment.title}#{", " + self.assignment.context.name if opts[:include_context]}"
      entry.authors  << Atom::Person.new(:name => author_name)
      entry.updated   = self.updated_at
      entry.published = self.created_at
      entry.id        = "tag:#{HostUrl.default_host},#{self.created_at.strftime("%Y-%m-%d")}:/submissions/#{self.feed_code}_#{self.updated_at.strftime("%Y-%m-%d")}"
      entry.links    << Atom::Link.new(:rel => 'alternate',
                                    :href => "http://#{HostUrl.context_host(self.assignment.context)}/#{prefix}/assignments/#{self.assignment_id}/submissions/#{self.id}")
      entry.content   = Atom::Content::Html.new(self.body || "")
      # entry.author    = Atom::Person.new(self.user)
    end
  end

  # include the versioned_attachments in as_json if this was loaded from a
  # specific version
  def serialization_methods
    !@without_versioned_attachments && simply_versioned_version_model ?
      [:versioned_attachments] :
      []
  end

  # mechanism to turn off the above behavior for the duration of a
  # block
  def without_versioned_attachments
    original, @without_versioned_attachments = @without_versioned_attachments, true
    yield
  ensure
    @exclude_versioned_attachments = original
  end

  def self.json_serialization_full_parameters(additional_parameters={})
    includes = { :quiz_submission => {} }
    methods = [ :submission_history, :attachments, :entered_score, :entered_grade ]
    methods << (additional_parameters.delete(:comments) || :submission_comments)
    excepts = additional_parameters.delete :except

    res = { :methods => methods, :include => includes }.merge(additional_parameters)
    if excepts
      excepts.each do |key|
        res[:methods].delete key
        res[:include].delete key
      end
    end
    res
  end

  def course_id=(val)
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

    if attachment = CutyCapt.snapshot_attachment_for_url(self.url)
      attachment.context = self
      attachment.save!
      attach_screenshot(attachment)
    else
      logger.error("Error capturing web snapshot for submission #{self.global_id}")
    end
  end

  def attach_screenshot(attachment)
    self.attachment = attachment
    self.processed = true
    self.save!
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

  def comments_for(user)
    user_can_read_grade?(user) ? submission_comments : visible_submission_comments
  end

  def filter_attributes_for_user(hash, user, session)
    unless user_can_read_grade?(user, session)
      %w(score grade published_score published_grade entered_score entered_grade).each do |secret_attr|
        hash.delete secret_attr
      end
    end
    hash
  end

  def update_participation
    # TODO: can we do this in bulk?
    return if assignment.deleted? || assignment.muted?
    return unless self.user_id

    return unless saved_change_to_score? || saved_change_to_grade? || saved_change_to_excused?

    return unless self.context.grants_right?(self.user, :participate_as_student)

    ContentParticipation.create_or_update({
      :content => self,
      :user => self.user,
      :workflow_state => "unread",
    })
  end

  def update_line_item_result
    return unless saved_change_to_score?
    Lti::Result.where(submission: self).update_all(result_score: score)
  end

  def delete_ignores
    if !submission_type.nil? || excused
      Ignore.where(asset_type: 'Assignment', asset_id: assignment_id, user_id: user_id, purpose: 'submitting').delete_all

      unless Submission.where(assignment_id: assignment_id).where(Submission.needs_grading_conditions).exists?
        Ignore.where(asset_type: 'Assignment', asset_id: assignment_id, purpose: 'grading', permanent: false).delete_all
      end
    end
    true
  end

  def point_data?
    !!(self.score || self.grade)
  end

  def read_state(current_user)
    return "read" unless current_user #default for logged out user
    uid = current_user.is_a?(User) ? current_user.id : current_user
    cp = if content_participations.loaded?
           content_participations.detect { |cp| cp.user_id == uid }
         else
           content_participations.where(user_id: uid).first
         end
    state = cp.try(:workflow_state)
    return state if state.present?
    return "read" if (assignment.deleted? || assignment.muted? || !self.user_id)
    return "unread" if (self.grade || self.score)
    has_comments = if visible_submission_comments.loaded?
                     visible_submission_comments.detect { |c| c.author_id != user_id }
                   else
                     visible_submission_comments.where("author_id<>?", user_id).first
                   end
    return "unread" if has_comments
    return "read"
  end

  def read?(current_user)
    read_state(current_user) == "read"
  end

  def unread?(current_user)
    !read?(current_user)
  end

  def mark_read(current_user)
    change_read_state("read", current_user)
  end

  def mark_unread(current_user)
    change_read_state("unread", current_user)
  end

  def change_read_state(new_state, current_user)
    return nil unless current_user
    return true if new_state == self.read_state(current_user)

    StreamItem.update_read_state_for_asset(self, new_state, current_user.id)
    clear_planner_cache(current_user)

    ContentParticipation.create_or_update({
      :content => self,
      :user => current_user,
      :workflow_state => new_state,
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
    self.assignment.muted?
  end

  def assignment_muted_changed
    self.grade_change_audit(true)
  end

  def without_graded_submission?
    !self.has_submission? && !self.graded?
  end

  def visible_rubric_assessments_for(viewing_user)
    return [] if self.assignment.muted? && !grants_right?(viewing_user, :read_grade)
    return [] unless self.assignment.rubric_association

    filtered_assessments = self.rubric_assessments.select do |a|
      a.grants_right?(viewing_user, :read) &&
        a.rubric_association == self.assignment.rubric_association
    end
    filtered_assessments.sort_by do |a|
      [
        a.assessment_type == 'grading' ? CanvasSort::First : CanvasSort::Last,
        Canvas::ICU.collation_key(a.assessor_name)
      ]
    end
  end

  def self.queue_bulk_update(context, section, grader, grade_data)
    progress = Progress.create!(:context => context, :tag => "submissions_update")
    progress.process_job(self, :process_bulk_update, {:n_strand => ["submissions_bulk_update", context.global_id]}, context, section, grader, grade_data)
    progress
  end

  def self.process_bulk_update(progress, context, section, grader, grade_data)
    missing_ids = []
    graded_user_ids = Set.new
    preloaded_assignments = Assignment.find(grade_data.keys).index_by(&:id)

    Submission.suspend_callbacks(:touch_graders) do
    grade_data.each do |assignment_id, user_grades|
      assignment = preloaded_assignments[assignment_id.to_i]

      scope = assignment.students_with_visibility(context.students_visible_to(grader, include: :inactive))
      if section
        scope = scope.where(:enrollments => { :course_section_id => section })
      end

      user_ids = user_grades.map { |id, data| id }
      preloaded_users = scope.where(:id => user_ids)
      preloaded_submissions = assignment.submissions.where(user_id: user_ids).group_by(&:user_id)

      Delayed::Batch.serial_batch(priority: Delayed::LOW_PRIORITY, n_strand: ["bulk_update_submissions", context.root_account.global_id]) do
        user_grades.each do |user_id, user_data|

          user = preloaded_users.detect{|u| u.global_id == Shard.global_id_for(user_id)}
          user ||= Api.sis_relation_for_collection(scope, [user_id], context.root_account).first
          unless user
            missing_ids << user_id
            next
          end

          submission = preloaded_submissions[user_id.to_i].first if preloaded_submissions[user_id.to_i]
          if !submission || user_data.key?(:posted_grade) || user_data.key?(:excuse)
            submissions =
              assignment.grade_student(user, :grader => grader,
                                       :grade => user_data[:posted_grade],
                                       :excuse => Canvas::Plugin.value_to_boolean(user_data[:excuse]),
                                       :skip_grade_calc => true, :return_if_score_unchanged => true)
            submissions.each { |s| graded_user_ids << s.user_id unless s.score_unchanged }
            submission = submissions.first
          end
          submission.user = user

          assessment = user_data[:rubric_assessment]
          if assessment.is_a?(Hash) && assignment.rubric_association
            # prepend each key with "criterion_", which is required by
            # the current RubricAssociation#assess code.
            assessment.keys.each do |crit_name|
              assessment["criterion_#{crit_name}"] = assessment.delete(crit_name)
            end
            assignment.rubric_association.assess(
              :assessor => grader, :user => user, :artifact => submission,
              :assessment => assessment.merge(:assessment_type => 'grading'))
          end

          comment = user_data.slice(:text_comment, :file_ids, :media_comment_id, :media_comment_type, :group_comment)
          if comment.present?
            comment = {
                :comment => comment[:text_comment],
                :author => grader,
                :hidden => assignment.muted?,
            }.merge(
                comment
            ).with_indifferent_access

            if file_ids = user_data[:file_ids]
              attachments = Attachment.where(id: file_ids).to_a.select{ |a|
                a.grants_right?(grader, :attach_to_submission_comment)
              }
              attachments.each { |a| a.ok_for_submission_comment = true }
              comment[:attachments] = attachments if attachments.any?
            end
            assignment.update_submission(user, comment)
          end

        end
      end
    end
    end

    if missing_ids.any?
      progress.message = "Couldn't find User(s) with API ids #{missing_ids.map{|id| "'#{id}'"}.join(", ")}"
      progress.save
      progress.fail
    end
  ensure
    context.touch_admins_later
    user_ids = graded_user_ids.to_a
    if user_ids.any?
      Rails.logger.debug "GRADES: recomputing scores in course #{context.id} for users #{user_ids} because of bulk submission update"
      context.recompute_student_scores(user_ids)
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
      (submission_type.present? && submission_type != 'online_quiz') ||
      (submission_type == 'online_quiz' && quiz_submission.completed?)
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

  private

  def set_anonymous_id
    self.anonymous_id = Anonymity.generate_id(existing_ids: Submission.anonymous_ids_for(assignment))
  end

  def update_provisional_grade(pg, scorer, attrs = {})
    pg.scorer = pg.current_user = scorer
    pg.final = !!attrs[:final]
    pg.grade = attrs[:grade] unless attrs[:grade].nil?
    pg.score = attrs[:score] unless attrs[:score].nil?
    pg.source_provisional_grade = attrs[:source_provisional_grade] if attrs.key?(:source_provisional_grade)
    pg.graded_anonymously = attrs[:graded_anonymously] unless attrs[:graded_anonymously].nil?
    pg.force_save = !!attrs[:force_save]
    pg
  end
end
