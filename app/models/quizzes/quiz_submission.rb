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

require 'sanitize'

class Quizzes::QuizSubmission < ActiveRecord::Base
  self.table_name = 'quiz_submissions'

  include Workflow

  attr_readonly :quiz_id, :user_id
  attr_accessor :grader_id

  GRACEFUL_FINISHED_AT_DRIFT_PERIOD = 5.minutes

  validates_presence_of :quiz_id
  validates_numericality_of :extra_time, greater_than_or_equal_to: 0,
    less_than_or_equal_to: 10080, # one week
    allow_nil: true
  validates_numericality_of :extra_attempts, greater_than_or_equal_to: 0,
    less_than_or_equal_to: 1000,
    allow_nil: true
  validates_numericality_of :quiz_points_possible, less_than_or_equal_to: 2000000000,
    allow_nil: true

  before_validation :update_quiz_points_possible
  before_validation :rectify_finished_at_drift, :if => :end_at?
  belongs_to :quiz, class_name: 'Quizzes::Quiz'
  belongs_to :user
  belongs_to :submission, :touch => true
  before_save :update_kept_score
  before_save :sanitize_responses
  before_save :update_assignment_submission
  after_save :save_assignment_submission
  after_save :context_module_action
  before_create :assign_validation_token
  after_save :delete_ignores

  has_many :attachments, :as => :context, :inverse_of => :context, :dependent => :destroy
  has_many :events, class_name: 'Quizzes::QuizSubmissionEvent'

  # update the QuizSubmission's Submission to 'graded' when the QuizSubmission is marked as 'complete.' this
  # ensures that quiz submissions with essay questions don't show as graded in the SpeedGrader until the instructor
  # has graded the essays.
  after_update :grade_submission!, if: :just_completed?

  def just_completed?
    submission_id? && saved_change_to_workflow_state? && completed?
  end

  def grade_submission!
    submission.update_attribute(:workflow_state, "graded")
  end

  serialize :quiz_data
  serialize :submission_data

  simply_versioned :automatic => false

  workflow do
    state :untaken do
      event :start_grading, :transitions_to => :pending_review
    end
    state :pending_review do
      event :complete, :transitions_to => :complete
      event :retake, :transitions_to => :untaken
    end
    state :complete do
      event :retake, :transitions_to => :untaken
    end
    state :settings_only do
      event :retake, :transitions_to => :untaken
    end
    state :preview
  end

  set_policy do
    given { |user| user && user.id == self.user_id }
    can :read and can :record_events

    given { |user| user && user.id == self.user_id && self.untaken? }
    can :update

    given { |user, session| self.quiz.grants_right?(user, session, :manage) || self.quiz.grants_right?(user, session, :review_grades) }
    can :read

    given { |user| user &&
            self.quiz.context.observer_enrollments.where(user_id: user, associated_user_id: self.user_id, workflow_state: 'active').exists? }
    can :read

    given {|user, session| quiz.context.grants_right?(user, session, :manage_grades) }
    can :update_scores and can :add_attempts and can :view_log
  end

  # override has_one relationship provided by simply_versioned
  def current_version_unidirectional
    versions.limit(1)
  end

  def sanitize_responses
    questions.select { |q| q['question_type'] == 'essay_question' }.each do |q|
      question_id = q['id']
      if graded?
        submission = submission_data.find { |s| s[:question_id] == question_id }
        submission[:text] = Sanitize.clean(submission[:text] || "", CanvasSanitize::SANITIZE) if submission
      else
        question_key = "question_#{question_id}"
        if submission_data[question_key]
          submission_data[question_key] = Sanitize.clean(submission_data[question_key] || "", CanvasSanitize::SANITIZE)
        end
      end
    end
    true
  end

  def question(id)
    questions.detect { |q| q[:id].to_i == id.to_i }
  end

  def has_question?(id)
    question(id).present?
  end

  def temporary_data
    raise "Cannot view temporary data for completed quiz" unless !self.completed?
    raise "Cannot view temporary data for completed quiz" if graded?
    res = (self.submission_data || {}).with_indifferent_access
    res
  end

  def question_answered?(id)
    keys = temporary_data.keys.select { |key|
      # find keys with answers for this question; skip question_x_marked and _read
      (key =~ /question_#{id}(_|$)/) && !(key =~ /_(marked|read)$/)
    }

    if keys.present?
      all_present = keys.all? { |key| temporary_data[key].present? }
      all_zeroes = keys.length > 1 && keys.all? { |key| temporary_data[key] == '0' }

      all_present && !all_zeroes # all zeroes applies to multiple answer questions
    end
  end

  def data
    raise "Cannot view data for uncompleted quiz" unless self.completed?
    raise "Cannot view data for uncompleted quiz" if !graded?

    Utf8Cleaner.recursively_strip_invalid_utf8!(self.submission_data, true)
  end

  def results_visible?(user: nil)
    return true unless quiz.present?
    return true if quiz.grants_right?(user, :review_grades)
    return false if quiz.restrict_answers_for_concluded_course?(user: user)
    return false if quiz.one_time_results && has_seen_results?
    return false if quiz.hide_results == 'always'

    results_visible_for_attempt?
  end

  def results_visible_for_attempt?
    return true unless quiz.hide_results == 'until_after_last_attempt'

    # Visible if quiz has unlimited attempts (no way to get to last
    # attempts), if this attempt is higher than the allowed attempts
    # (once you get into extra attempts), or if this attempt is
    # the last attempt and has been taken (checking for completion
    # prevents the student from starting to take the quiz for the last
    # time, then opening a new tab and looking at the results from
    # a prior attempt)
    !quiz.allowed_attempts ||
      quiz.allowed_attempts < 1 ||
      attempt > quiz.allowed_attempts ||
      last_attempt_completed?
  end
  private :results_visible_for_attempt?

  def last_attempt_completed?
    completed? && quiz.allowed_attempts && attempt >= quiz.allowed_attempts
  end

  def self.needs_grading
     resp = where("(
         quiz_submissions.workflow_state = 'untaken'
         AND quiz_submissions.end_at < :time
       ) OR
       (
         quiz_submissions.workflow_state = 'completed'
         AND quiz_submissions.submission_data IS NOT NULL
       )", {time: Time.now}).to_a
     resp.select! { |qs| qs.needs_grading? }
     resp
   end

  # There is also a needs_grading scope which needs to replicate this logic
  def needs_grading?(strict=false)
    overdue_and_needs_submission?(strict) || (self.completed? && !graded?)
  end

  def overdue_and_needs_submission?(strict=false)
    (strict && self.untaken? && self.overdue?(true)) ||
    (self.untaken? && self.end_at && self.end_at < Time.now)
  end
  alias_method :overdue_and_needs_submission, :overdue_and_needs_submission?

  def has_seen_results?
    !!self.has_seen_results
  end

  def finished_in_words
    extend ActionView::Helpers::DateHelper
    started_at && finished_at && time_ago_in_words(Time.now - (finished_at - started_at))
  end

  def finished_at_fallback
    [self.end_at, Time.zone.now].compact.min
  end

  def points_possible_at_submission_time
    self.questions.map { |q| q[:points_possible].to_f }.compact.sum || 0
  end

  def questions
    Utf8Cleaner.recursively_strip_invalid_utf8!(self.quiz_data, true) || []
  end

  def backup_submission_data(params)
    raise "Only a hash value is accepted for backup_submission_data calls" unless params.is_a?(Hash) || params.is_a?(ActionController::Parameters)

    params = sanitize_params(params)

    new_params = if !graded? && self.submission_data[:attempt] == self.attempt
      self.submission_data.deep_merge(params) rescue params
    else
      params
    end

    new_params[:attempt] = self.attempt

    # take a snapshot every 5 other saves:
    new_params[:cnt] ||= 0
    new_params[:cnt] = (new_params[:cnt].to_i + 1) % 5
    snapshot!(params) if new_params[:cnt] == 1

    self.class.where(id: self).
        where("workflow_state NOT IN ('complete', 'pending_review')").
        update_all(user_id: user_id, submission_data: new_params)

    record_answer(new_params)

    new_params
  end

  def record_answer(submission_data)
    extractor = Quizzes::LogAuditing::QuestionAnsweredEventExtractor.new
    extractor.create_event!(submission_data, self)
  end

  def record_creation_event
    self.events.create!(
      event_type: Quizzes::QuizSubmissionEvent::EVT_SUBMISSION_CREATED,
      event_data: {"quiz_version" => self.quiz_version, "quiz_data" => self.quiz_data},
      created_at: Time.zone.now,
      attempt: self.attempt
    )
  end

  def sanitize_params(params)
    params = params.to_unsafe_h if params.is_a?(ActionController::Parameters) # clear the strong params

    # if the submission has already been graded
    if graded?
      return params.merge({:_already_graded => true})
    end

    if quiz.cant_go_back?
      params.reject! do |param, _|
        question_being_answered = /\Aquestion_(?<question_id>\d+)/.match(param)
        next unless question_being_answered

        previously_read_marker = :"_question_#{question_being_answered[:question_id]}_read"

        submission_data[previously_read_marker]
      end
    end
    params
  end

  # Generate a snapshot of the QS representing its current state and answer data.
  #
  # Multiple snapshots can be taken for a single QS, and they're further scoped
  # to the QuizSubmission#attempt index.
  #
  # @param [Hash] submission_data
  #   Answer data the snapshot should represent.
  #
  # @param [Boolean] full_snapshot
  #   Set to true to indicate that the snapshot should represent both the QS's
  #   current answer data along with the passed in answer data (patched).
  #   This is useful for supporting incremental snapshots where you're only
  #   passing in the part of the answer data that has changed.
  #
  # @return [QuizSubmissionSnapshot]
  #   The latest, newly-created snapshot.
  def snapshot!(submission_data={}, full_snapshot=false)
    snapshot_data = submission_data || {}

    if full_snapshot
      snapshot_data = self.sanitize_params(snapshot_data).stringify_keys
      snapshot_data.merge!(self.submission_data || {})
    end

    Quizzes::QuizSubmissionSnapshot.create({
      quiz_submission: self,
      attempt: self.attempt,
      data: snapshot_data
    })
  end

  def quiz_question_ids
    questions.map { |question| question["id"] }.compact
  end

  def quiz_questions
    Quizzes::QuizQuestion.where(id: quiz_question_ids).to_a
  end

  def update_quiz_points_possible
    self.quiz_points_possible = self.quiz && self.quiz.points_possible
  end

  # This callback attempts to handle a somewhat edge-case reported in CNVS-8463
  # where the quiz auto-submits while the browser tab is inactive, but that
  # time at which the submission is turned in may have happened *after* the
  # timer had elapsed (and is never consistent).. When that happened,
  # admins/teachers were confused that those students had gained extra time when
  # in fact they didn't, it's just that the JS stalled with submitting at the
  # right time.
  #
  # This will reduce such "drift" only if it appears to be incidental by testing
  # if it happened within a relatively small window of time; the reason for that
  # is that if #finished_at was set to something like 5 hours after time-out
  # then there may be something more sinister going on and we don't want the
  # callback to shadow it.
  #
  # Of course, this is purely guess-work and is not bullet-proof.
  def rectify_finished_at_drift
    if self.finished_at && self.end_at && self.finished_at > self.end_at
      drift = self.finished_at - self.end_at

      if drift <= GRACEFUL_FINISHED_AT_DRIFT_PERIOD.to_i
        self.finished_at = self.end_at
      end
    end
  end

  def update_kept_score
    return if self.manually_scored || @skip_after_save_score_updates

    if self.completed?
      if self.submission_data && !graded?
        Quizzes::SubmissionGrader.new(self).grade_submission
      end

      self.kept_score = score_to_keep
    end
  end

  # self.kept_score is basically a cached version of this computed property. it
  # is not cleared when a new quiz_submission version is created and it should
  # always be current.  it only really makes sense on the current object, and
  # so we do not bother updating kept_score in previous versions when they are
  # updated.
  def score_to_keep
    if self.quiz && self.quiz.scoring_policy == "keep_highest"
      highest_score_so_far
    elsif self.quiz && self.quiz.scoring_policy == "keep_average"
      average_score_so_far
    else # keep_latest
      latest_score
    end
  end

  def update_assignment_submission
    return if self.manually_scored || @skip_after_save_score_updates
    if self.quiz && self.quiz.for_assignment? && assignment && !self.submission && self.user_id
      self.submission = assignment.find_or_create_submission(self.user_id)
    end
    if self.completed? && self.submission
      @assignment_submission = self.submission
      @assignment_submission.score = self.kept_score if self.kept_score
      @assignment_submission.submitted_at = self.finished_at
      @assignment_submission.grade_matches_current_submission = true
      @assignment_submission.quiz_submission_id = self.id
      @assignment_submission.graded_at = [self.end_at, Time.zone.now].compact.min
      @assignment_submission.grader_id = self.grader_id || "-#{self.quiz_id}".to_i
      @assignment_submission.body = "user: #{self.user_id}, quiz: #{self.quiz_id}, score: #{self.score}, time: #{Time.now}"
      @assignment_submission.user_id = self.user_id
      @assignment_submission.submission_type = "online_quiz"
      @assignment_submission.saved_by = :quiz_submission
    end
  end

  def save_assignment_submission
    @assignment_submission.save! if @assignment_submission
  end

  def scores_for_versions(exclude_version_id)
    versions = self.versions.reload.reject { |v| v.id == exclude_version_id } rescue []
    scores = {}
    scores[attempt] = self.score if self.score

    # only most recent version for each attempt - some have regraded a version
    versions.sort_by(&:number).reverse_each do |ver|
      scores[ver.model.attempt] ||= ver.model.score || 0.0
    end

    scores
  end
  private :scores_for_versions

  def average_score_so_far(exclude_version_id=nil)
    scores = scores_for_versions(exclude_version_id)
    (scores.values.sum.to_f / scores.size).round(2)
  end
  private :average_score_so_far

  def highest_score_so_far(exclude_version_id=nil)
    scores = scores_for_versions(exclude_version_id)
    scores.values.max
  end

  private :highest_score_so_far

  def latest_score
    # the current model's score is the latest, unless the quiz is currently in
    # progress, in which case it is nil
    s = self.score

    # otherwise, try to be the latest version's score, if possible
    if s.nil?
      v = versions.reload.current
      s = v.model.score if v.present?
    end

    s
  end

  private :latest_score

  # Adjust the fudge points so that the score is the given score
  # Used when the score is explicitly set by teacher instead of auto-calculating
  def set_final_score(final_score)
    version = self.versions.current # this gets us the most recent completed version
    return if final_score.blank? || version.blank?
    self.manually_scored = false
    @skip_after_save_score_updates = true
    serialized_model = version.model
    old_fudge = serialized_model.fudge_points || 0.0
    old_score = serialized_model.score
    base_score = old_score - old_fudge

    new_fudge = final_score - base_score
    self.score = final_score
    to_be_kept_score = final_score
    self.fudge_points = new_fudge

    if self.workflow_state == "pending_review"
      self.workflow_state = "complete"
      self.has_seen_results = false
    end

    if self.quiz && self.quiz.scoring_policy == "keep_highest"
      # exclude the score of the version we're curretly overwriting
      if to_be_kept_score < highest_score_so_far(version.id)
        self.manually_scored = true
      end
    end

    update_submission_version(version, [:score, :fudge_points, :manually_scored])

    # we might be in the middle of a new attempt, in which case we don't want
    # to overwrite the score and fudge points when we save
    self.reload if !self.completed?

    self.kept_score = to_be_kept_score
    self.without_versioning(&:save)
    @skip_after_save_score_updates = false
  end

  def time_left
    return unless end_at
    (end_at - Time.zone.now).round
  end

  def less_than_allotted_time?
    self.started_at && self.end_at && self.quiz && self.quiz.time_limit && (self.end_at - self.started_at) < self.quiz.time_limit.minutes.to_i
  end

  def completed?
    self.complete? || self.pending_review?
  end

  def overdue?(strict=false)
    now = (Time.now - ((strict ? 1 : 5) * 60))
    !!(end_at && end_at.localtime < now)
  end

  def extendable?
    !!(untaken? && quiz.time_limit && end_at && end_at.utc + 1.hour > Time.now.utc)
  end

  protected :update_assignment_submission

  def submitted_attempts
    attempts.version_models
  end

  def latest_submitted_attempt
    if completed?
      self
    else
      submitted_attempts.last
    end
  end

  def attempts
    Quizzes::QuizSubmissionHistory.new(self)
  end

  # Load the model for this quiz submission at a given attempt.
  #
  # @return [Quizzes::QuizSubmission|NilClass]
  #   The submission model at that attempt, or nil if there's no such attempt.
  def model_for_attempt(attempt)
    attempts.model_for(attempt)
  end

  def questions_regraded_since_last_attempt
    return if attempts.last.nil?

    version = attempts.last.versions.first
    quiz.questions_regraded_since(version.created_at)
  end

  def has_regrade?
    score_before_regrade.present?
  end

  def score_affected_by_regrade?
    score_before_regrade != kept_score
  end

  def attempts_left
    return -1 if self.quiz.allowed_attempts < 0
    [0, self.quiz.allowed_attempts - (self.attempt || 0) + (self.extra_attempts || 0)].max
  end

  def mark_completed
    Quizzes::QuizSubmission.where(:id => self).update_all({
      workflow_state: 'complete',
      has_seen_results: false
    })
  end

  # Complete (e.g, turn-in) the quiz submission by doing the following:
  #
  #  - generating a (full) snapshot of the current state along with any
  #  additional answer data that you pass in
  #  - marking the QS as complete (see #workflow_state)
  #  - grading the QS (see SubmissionGrader#grade_submission)
  #
  # @param [Hash] submission_data
  #   Additional answer data to attach to the QS before completing it.
  #
  # @return [QuizSubmission] self
  def complete!(submission_data={})
    self.snapshot!(submission_data, true)
    self.mark_completed
    Quizzes::SubmissionGrader.new(self).grade_submission
    self
  end

  def graded?
    self.submission_data.is_a?(Array)
  end

  # Updates a simply_versioned version instance in-place.  We want
  # a teacher to be able to come in and update points for an already-
  # taken quiz, even if it's a prior version of the submission. Thank you
  # simply_versioned for making this possible!
  def update_submission_version(version, attrs)
    version_data = YAML::load(version.yaml)
    version_data["submission_data"] = self.submission_data if attrs.include?(:submission_data)
    version_data["temporary_user_code"] = "was #{version_data['score']} until #{Time.now}"
    version_data["score"] = self.score if attrs.include?(:score)
    version_data["fudge_points"] = self.fudge_points if attrs.include?(:fudge_points)
    version_data["workflow_state"] = self.workflow_state if attrs.include?(:workflow_state)
    version_data["manually_scored"] = self.manually_scored if attrs.include?(:manually_scored)
    version.yaml = version_data.to_yaml
    res = version.save
    res
  end

  def context_module_action
    if self.quiz && self.user
      if self.score
        self.quiz.context_module_action(self.user, :scored, self.kept_score)
      end
      if self.finished_at
        self.quiz.context_module_action(self.user, :submitted)
      end
    end
  end

  def update_scores(params)
    original_score = self.score
    params = (params || {}).with_indifferent_access
    self.manually_scored = false
    self.grader_id = params[:grader_id]
    self.submission&.mark_unread(self.user)
    versions = self.versions
    version = versions.current
    version = versions.get(params[:submission_version_number]) if params[:submission_version_number]
    # note that self may not match versions.current, because we only save a new version on actual submit
    raise "Can't update submission scores unless it's completed" if !self.completed? && !params[:submission_version_number]

    data = version.model.submission_data || []
    res = []
    tally = 0
    completed_before_changes = self.completed?
    self.workflow_state = "complete"
    self.fudge_points = params[:fudge_points].to_f if params[:fudge_points] && params[:fudge_points] != ""
    tally += self.fudge_points if self.fudge_points
    data.each do |answer|
      unless answer.respond_to?(:with_indifferent_access)
        logger.error "submission = #{self.to_json}"
        logger.error "answer = #{answer.inspect}"
        raise "Quizzes::QuizSubmission.update_scores called on a quiz that appears to be in progress"
      end
      answer = answer.with_indifferent_access
      score = params["question_score_#{answer["question_id"]}".to_sym]
      answer["more_comments"] = params["question_comment_#{answer["question_id"]}".to_sym] if params["question_comment_#{answer["question_id"]}".to_sym]
      if score.present?
        begin
          float_score = score.to_f
        rescue
          float_score = nil
        end
        answer["points"] = float_score || answer["points"] || 0
        answer["correct"] = "defined" if answer["correct"] == "undefined" && float_score
      elsif score && score.empty?
        answer["points"] = 0
        answer["correct"] = "undefined"
      end
      if answer["correct"] == "undefined"
        question = quiz_data.find {|h| h[:id] == answer["question_id"] }
        self.workflow_state = "pending_review" if question && question["question_type"] != "text_only_question"
      end
      res << answer
      tally += answer["points"].to_f rescue 0
    end

    # Graded surveys always get the full points
    if quiz && quiz.graded_survey?
      self.score = quiz.points_possible
    else
      self.score = tally
    end

    self.submission_data = res

    # the interaction in here is messy

    # first we update the version we've been modifying, so that all versions are current.
    update_submission_version(version, [:submission_data, :score, :fudge_points, :workflow_state])

    if version.model.attempt != self.attempt || !completed_before_changes
      self.reload

      # score_to_keep should work regardless of the current model workflow_state and score
      # (ie even if the current model is an in-progress submission)
      self.kept_score = score_to_keep

      # if the current version is completed, then the normal save callbacks
      # will handle updating the submission. otherwise we need to set its score
      # here so that when it is touched by the association, it does not try to
      # sync an old score back to this quiz_submission
      if !self.completed? && self.submission
        s = self.submission
        s.score = self.kept_score
        s.grade_matches_current_submission = true
        s.body = "user: #{self.user_id}, quiz: #{self.quiz_id}, score: #{self.kept_score}, time: #{Time.now}"
        s.saved_by = :quiz_submission
      end
    end

    # submission has to be saved with versioning
    # to help Auditors::GradeChange record grade_before correctly
    self.submission.with_versioning(explicit: true, &:save) if self.submission.present?
    self.without_versioning(&:save)

    self.reload
    grader = Quizzes::SubmissionGrader.new(self)
    if grader.outcomes_require_update(self, original_score)
      grader.track_outcomes(version.model.attempt)
    end
    true
  end

  def duration
    (self.finished_at || self.started_at) - self.started_at rescue 0
  end

  def time_spent
    return unless finished_at.present?
    (finished_at - started_at + (extra_time||0)).round
  end

  scope :before, lambda { |date| where("quiz_submissions.created_at<?", date) }
  scope :updated_after, lambda { |date|
    date ? where("quiz_submissions.updated_at>?", date) : all
  }
  scope :for_user_ids, lambda { |user_ids| where(:user_id => user_ids) }
  scope :logged_out, -> { where("temporary_user_code is not null AND NOT was_preview") }
  scope :not_settings_only, -> { where("quiz_submissions.workflow_state<>'settings_only'") }
  scope :completed, -> { where(:workflow_state => %w(complete pending_review)) }

  # Excludes teacher preview submissions.
  #
  # You may still have to deal with StudentView submissions if you want
  # submissions made by students for real, which you can do by using the
  # for_user_ids scope and pass in quiz.context.all_real_student_ids.
  scope :not_preview, -> { where('was_preview IS NULL OR NOT was_preview') }

  # Excludes teacher preview and Student View submissions.
  scope :for_students, ->(quiz) { not_preview.for_user_ids(quiz.context.all_real_student_ids) }

  has_a_broadcast_policy

  set_broadcast_policy do |p|
    # evizitei: These broadcast policies use templates designed for
    # submissions, not quiz submissions.  The necessary delegations
    # are at the bottom of this class.
    p.dispatch :submission_graded
    p.to { ([user] + User.observing_students_in_course(user, self.context)).uniq(&:id) }
    p.whenever { |q_sub|
      BroadcastPolicies::QuizSubmissionPolicy.new(q_sub).
        should_dispatch_submission_graded?
    }

    p.dispatch :submission_grade_changed
    p.to { ([user] + User.observing_students_in_course(user, self.context)).uniq(&:id) }
    p.whenever { |q_sub|
      BroadcastPolicies::QuizSubmissionPolicy.new(q_sub).
        should_dispatch_submission_grade_changed?
    }

    p.dispatch :submission_needs_grading
    p.to { teachers }
    p.whenever { |q_sub|
      BroadcastPolicies::QuizSubmissionPolicy.new(q_sub).
        should_dispatch_submission_needs_grading?
    }
  end

  def teachers
    quiz.context.instructors_in_charge_of(user)
  end

  def assign_validation_token
    self.validation_token = SecureRandom.hex(32)
  end

  def delete_ignores
    if completed?
      Ignore.where(asset_type: 'Quizzes::Quiz', asset_id: quiz_id, user_id: user_id, purpose: 'submitting').delete_all
    end
    true
  end

  def valid_token?(token)
    self.validation_token.blank? || self.validation_token == token
  end

  # TODO: this could probably be put in as a convenience method in simply_versioned
  def save_with_versioning!
    self.with_versioning(true) { self.save! }
  end

  # evizitei: these 3 delegations allow quiz submissions to be used in
  # templates designed for regular submissions.  Any additional functionality
  # put into those templates will need to be provided in both submissions and
  # quiz_submissions
  delegate :assignment_id, :assignment, :to => :quiz
  delegate :graded_at, :to => :submission
  delegate :context, :to => :quiz
  delegate :excused?, to: :submission, allow_nil: true

  # Determine whether the QS can be retried (ie, re-generated).
  #
  # A QS is determined to be retriable if:
  #
  #   - it's a settings_only? one
  #   - it's a preview? one
  #   - it's complete and still has attempts left to spare
  #   - it's complete and the quiz allows for unlimited attempts
  #
  # @return [Boolean]
  #   Whether the QS is retriable.
  def retriable?
    return true if self.preview?
    return true if self.settings_only?

    attempts_left = self.attempts_left || 0

    self.completed? && (attempts_left > 0 || self.quiz.unlimited_attempts?)
  end

  # Locate the Quiz Submission for this participant, regardless of them being
  # enrolled students, or anonymous participants.
  #
  # @return [Relation]
  #   The QS Relation, for the participant.
  def self.for_participant(participant)
    participant.anonymous? ?
        where(temporary_user_code: participant.user_code) :
        where(user_id: participant.user.id)
  end

  def ensure_question_reference_integrity!
    fixer = ::Quizzes::QuizSubmission::QuestionReferenceDataFixer.new
    fixer.run!(self)
  end

  def due_at
    return quiz.due_at if submission.blank?

    quiz.overridden_for(submission.user, skip_clone: true).due_at
  end

  # same as the instance method, but with a hash of attributes, instead
  # of an instance, so that you can avoid instantiating
  def self.late_from_attributes?(attributes, quiz, submission)
    return submission.late_policy_status == 'late' if submission&.late_policy_status.present?
    return false if attributes['finished_at'].blank?

    due_at = if submission.blank?
      quiz.due_at
    else
      quiz.overridden_for(submission.user, skip_clone: true).due_at
    end
    return false if due_at.blank?

    check_time = attributes['finished_at'] - 60.seconds
    check_time > due_at
  end
end
