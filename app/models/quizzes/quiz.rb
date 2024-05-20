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
require "canvas/draft_state_validations"

class Quizzes::Quiz < ActiveRecord::Base
  extend RootAccountResolver
  self.table_name = "quizzes"

  include Workflow
  include HasContentTags
  include CopyAuthorizedLinks
  include ActionView::Helpers::SanitizeHelper
  extend ActionView::Helpers::SanitizeHelper::ClassMethods
  include ContextModuleItem
  include DatesOverridable
  include SearchTermHelper
  include Plannable
  include Canvas::DraftStateValidations
  include LockedFor

  attr_readonly :context_id, :context_type
  attr_accessor :notify_of_update, :saved_by, :saved_by_new_quizzes_migration

  has_many :quiz_questions, -> { order(:position) }, dependent: :destroy, class_name: "Quizzes::QuizQuestion", inverse_of: :quiz
  has_many :quiz_submissions, dependent: :destroy, class_name: "Quizzes::QuizSubmission"
  has_many :submissions, through: :quiz_submissions
  has_many :quiz_groups, -> { order(:position) }, dependent: :destroy, class_name: "Quizzes::QuizGroup"
  has_many :quiz_statistics, -> { order(:created_at) }, class_name: "Quizzes::QuizStatistics"
  has_many :attachments, as: :context, inverse_of: :context, dependent: :destroy
  has_many :quiz_regrades, class_name: "Quizzes::QuizRegrade"
  has_many :quiz_student_visibilities
  belongs_to :context, polymorphic: [:course]
  belongs_to :assignment, inverse_of: :quiz, class_name: "AbstractAssignment"
  belongs_to :assignment_group
  belongs_to :root_account, class_name: "Account"
  has_many :ignores, as: :asset
  has_one :master_content_tag, class_name: "MasterCourses::MasterContentTag", inverse_of: :quiz

  validates :description, length: { maximum: maximum_long_text_length, allow_blank: true }
  validates :title, length: { maximum: maximum_string_length, allow_nil: true }
  validates :context_id, presence: true
  validates :context_type, presence: true
  validates :points_possible, numericality: { less_than_or_equal_to: 2_000_000_000, allow_nil: true }
  validate :validate_quiz_type, if: :quiz_type_changed?
  validate :validate_ip_filter, if: :ip_filter_changed?
  validate :validate_time_limit, if: :time_limit_changed?
  validate :validate_hide_results, if: :hide_results_changed?
  validate :validate_correct_answer_visibility, if: lambda { |quiz|
    quiz.show_correct_answers_at_changed? ||
      quiz.hide_correct_answers_at_changed?
  }
  sanitize_field :description, CanvasSanitize::SANITIZE
  copy_authorized_links(:description) { [context, nil] }

  before_save :generate_quiz_data_on_publish, if: :workflow_state_changed?
  before_save :build_assignment
  before_save :set_defaults
  after_save :update_assignment
  before_save :check_if_needs_availability_cache_clear
  after_save :clear_availability_cache
  after_save :touch_context
  after_save :regrade_if_published
  # We currently only create LORs for quizzes that are assignments. If we change the quiz_type,
  # we should destroy or restore the results appropriately
  after_save :destroy_learning_outcome_results, if: -> { saved_change_to_quiz_type?(from: "assignment") }
  after_save :restore_learning_outcome_results, if: -> { saved_change_to_quiz_type?(to: "assignment") }
  serialize :quiz_data

  simply_versioned

  # This callback is listed here in order for the :link_assignment_overrides
  # method to be called after the simply_versioned callbacks. We want the
  # overrides to reflect the most recent version of the quiz.
  # If we placed this before simply_versioned, the :link_assignment_overrides
  # method would fire first, meaning that the overrides would reflect the
  # last version of the assignment, because the next callback would be a
  # simply_versioned callback updating the version.
  after_save :link_assignment_overrides, if: :new_assignment_id?

  resolves_root_account through: :context

  include MasterCourses::Restrictor
  restrict_columns :content, [:title, :description]
  restrict_columns :settings, %i[
    quiz_type
    assignment_group_id
    shuffle_answers
    time_limit
    disable_timer_autosubmission
    anonymous_submissions
    scoring_policy
    allowed_attempts
    hide_results
    one_time_results
    show_correct_answers
    show_correct_answers_last_attempt
    show_correct_answers_at
    hide_correct_answers_at
    one_question_at_a_time
    cant_go_back
    access_code
    ip_filter
    require_lockdown_browser
    require_lockdown_browser_for_results
  ]
  restrict_assignment_columns
  restrict_columns :state, [:workflow_state]

  # override has_one relationship provided by simply_versioned
  def current_version_unidirectional
    versions.limit(1)
  end

  def infer_times
    # set the time to 11:59 pm in the creator's time zone, if none given
    self.due_at = CanvasTime.fancy_midnight(due_at)
    self.lock_at = CanvasTime.fancy_midnight(lock_at)
  end

  def set_defaults
    self.cant_go_back = false unless one_question_at_a_time
    unless show_correct_answers
      self.show_correct_answers_last_attempt = false
      self.show_correct_answers_at = nil
      self.hide_correct_answers_at = nil
    end
    self.allowed_attempts = 1 if allowed_attempts.nil?
    if allowed_attempts <= 1
      self.show_correct_answers_last_attempt = false
    end
    self.scoring_policy = "keep_highest" if scoring_policy.nil?
    self.ip_filter = nil if ip_filter && ip_filter.strip.empty?
    if !available? && !survey?
      self.points_possible = current_points_possible
    end
    self.title = t("#quizzes.quiz.default_title", "Unnamed Quiz") if title.blank?
    self.quiz_type ||= "assignment"
    self.last_assignment_id = assignment_id_was if assignment_id_was
    if (!graded? && assignment_id) || (assignment_id_was && assignment_id != assignment_id_was)
      @old_assignment_id = assignment_id_was
      @assignment_to_set = assignment
      self.assignment_id = nil
    end

    unless require_lockdown_browser
      self.require_lockdown_browser_for_results = false
    end

    self.assignment_group_id ||= assignment.assignment_group_id if assignment
    self.question_count = question_count(true)
    @update_existing_submissions = true if for_assignment? && quiz_type_changed?
    @stored_questions = nil

    %i[
      shuffle_answers
      disable_timer_autosubmission
      could_be_locked
      anonymous_submissions
      require_lockdown_browser
      require_lockdown_browser_for_results
      one_question_at_a_time
      cant_go_back
      require_lockdown_browser_monitor
      only_visible_to_overrides
      one_time_results
      show_correct_answers_last_attempt
    ].each { |attr| self[attr] = false if self[attr].nil? }
    self[:show_correct_answers] = true if self[:show_correct_answers].nil?
  end

  # quizzes differ from other publishable objects in that they require we
  # generate quiz data and update time when we publish. This method makes it
  # harder to mess up (like someone setting using workflow_state directly)
  def generate_quiz_data_on_publish
    if workflow_state == "available"
      generate_quiz_data
      self.published_at = Time.zone.now
    end
  end
  private :generate_quiz_data_on_publish

  protected :set_defaults

  def new_assignment_id?
    last_assignment_id != assignment_id
  end

  def link_assignment_overrides
    override_students = [assignment_override_students]
    overrides = [assignment_overrides]
    overrides_params = { quiz_id: id, quiz_version: version_number }

    if assignment
      override_students += [assignment.assignment_override_students]
      overrides += [assignment.assignment_overrides]
      overrides_params[:assignment_version] = assignment.version_number
      overrides_params[:assignment_id] = assignment_id
    end

    fields = %i[assignment_version assignment_id quiz_version quiz_id]
    overrides.flatten.each do |override|
      fields.each do |field|
        override.send(:"#{field}=", overrides_params[field])
      end
      override.save!
    end

    override_students.each do |collection|
      collection.update_all(assignment_id:, quiz_id: id)
    end
  end

  def build_assignment(force: false)
    # There is no need to create a new assignment if the quiz being deleted
    return if workflow_state == "deleted"

    if !assignment_id && (graded? || (force && survey?)) && (force || !%i[assignment clone migration].include?(@saved_by))
      assignment = self.assignment
      assignment ||= context.assignments.build(title:, due_at:, submission_types: "online_quiz")
      assignment.assignment_group_id = self.assignment_group_id
      assignment.only_visible_to_overrides = only_visible_to_overrides
      assignment.saved_by = :quiz
      unless deleted?
        assignment.workflow_state = published? ? "published" : "unpublished"
      end
      assignment.save
      self.assignment_id = assignment.id
    end
  end

  def readable_type
    survey? ? t("#quizzes.quiz.types.survey", "Survey") : t("#quizzes.quiz.types.quiz", "Quiz")
  end

  def valid_ip?(ip)
    require "ipaddr"
    ip_filter.split(",").any? do |filter|
      addr_range = ::IPAddr.new(filter) rescue nil
      addr = ::IPAddr.new(ip) rescue nil
      addr && addr_range && addr_range.include?(addr)
    end
  end

  def self.count_points_possible(entries)
    util = Quizzes::QuizQuestion::AnswerSerializers::Util
    possible = BigDecimal("0.0")
    entries.each do |e|
      if e[:question_points] # QuizGroup
        possible += (util.to_decimal(e[:question_points].to_s) * util.to_decimal(e[:pick_count].to_s))
      else
        possible += util.to_decimal(e[:points_possible].to_s) unless e[:unsupported]
      end
    end
    possible.to_f
  end

  def current_points_possible
    entries = root_entries
    return assignment.points_possible if entries.empty? && assignment

    self.class.count_points_possible(entries)
  end

  def set_unpublished_question_count
    entries = root_entries(true)
    cnt = 0
    entries.each do |e|
      if e[:question_points]
        cnt += e[:pick_count]
      else
        cnt += 1 unless e[:unsupported] || e[:question_type] == Quizzes::QuizQuestion::Q_TEXT_ONLY
      end
    end

    # TODO: this is hacky, but we don't want callbacks to run because we're in an after_save. Refactor.
    Quizzes::Quiz.where(id: self).update_all(unpublished_question_count: cnt)
    self.unpublished_question_count = cnt
  rescue
    # TODO: no idea what we're protecting against here
  end

  def for_assignment?
    assignment_id && assignment && assignment.submission_types == "online_quiz"
  end

  def muted?
    assignment&.muted?
  end

  alias_method :destroy_permanently!, :destroy

  def destroy
    ContentTag.delete_for(self)
    self.workflow_state = "deleted"
    self.deleted_at = Time.now.utc
    res = save!
    if for_assignment? && !assignment.deleted?
      assignment.skip_downstream_changes! if @skip_downstream_changes
      assignment.destroy
    end
    res
  end

  def restore(_from = nil)
    self.workflow_state = if has_student_submissions?
                            "available"
                          else
                            "unpublished"
                          end
    save
    assignment.restore(:quiz) if for_assignment?
  end

  def unlink!(type)
    @saved_by = type
    self.assignment = nil
    if root_entries.empty? && !available?
      destroy
    else
      save
    end
  end

  def assignment_id=(val)
    @assignment_id_set = true
    write_attribute(:assignment_id, val)
  end

  def lock_at=(val)
    val = val.in_time_zone.end_of_day if val.is_a?(Date)
    if val.is_a?(String)
      super(Time.zone.parse(val))
      self.lock_at = CanvasTime.fancy_midnight(lock_at) unless val.include?(":")
    else
      super(val)
    end
  end

  def due_at=(val)
    val = val.in_time_zone.end_of_day if val.is_a?(Date)
    if val.is_a?(String)
      super(Time.zone.parse(val))
      infer_times unless val.include?(":")
    else
      super(val)
    end
  end

  def update_cached_due_dates?(next_quiz_type = nil)
    due_at_changed? ||
      workflow_state_changed? ||
      only_visible_to_overrides_changed? ||
      (assignment.nil? && ["assignment", "graded_survey"].include?(next_quiz_type))
  end

  def assignment?
    self.quiz_type == "assignment"
  end

  def survey?
    self.quiz_type == "survey" || graded_survey?
  end

  def graded?
    self.quiz_type == "assignment" || graded_survey?
  end

  def graded_survey?
    self.quiz_type == "graded_survey"
  end

  def ungraded?
    !graded?
  end

  # Determine if the quiz should display the correct answers and the score points.
  # Takes into account the quiz settings, the user viewing and the submission to
  # be viewed.
  def show_correct_answers?(user, submission)
    show_at = show_correct_answers_at
    hide_at = hide_correct_answers_at

    # NOTE: We don't have a submission user when the teacher is previewing the
    # quiz and displaying the results'
    return true if grants_right?(user, :grade) &&
                   (submission&.user && submission.user != user)

    return false unless show_correct_answers

    if show_correct_answers_last_attempt && submission
      return submission.attempts_left == 0 && submission.completed?
    end

    # If we're showing the results only one time, and are letting students
    # see their correct answers, don't take the showAt/hideAt dates into
    # consideration because we really want them to see the CAs just once,
    # no matter when they submit.
    return true if one_time_results

    # Are we past the date the correct answers should no longer be shown after?
    return false if hide_at.present? && Time.zone.now > hide_at

    show_at.present? ? Time.zone.now > show_at : true
  end

  def restrict_answers_for_concluded_course?(user: nil)
    course = context
    return false unless course.root_account.settings[:restrict_quiz_questions]

    if user.present?
      user_sections = course.sections_visible_to(user).select(&:restrict_enrollments_to_section_dates)
      return false if user_sections.present?
    end

    !!course.concluded?
  end

  def update_existing_submissions
    # If the quiz suddenly changes from non-graded to graded,
    # then this will update the existing submissions to reflect quiz
    # scores in the gradebook.
    quiz_submissions.each(&:save!)
  end

  def update_learning_outcome_results(state)
    LearningOutcomeResult.for_associated_asset(self).update_all(workflow_state: state, updated_at: Time.zone.now)
  end

  def destroy_learning_outcome_results
    delay_if_production.update_learning_outcome_results("deleted")
  end

  def restore_learning_outcome_results
    delay_if_production.update_learning_outcome_results("active")
  end

  def destroy_related_submissions
    quiz_submissions.each do |qs|
      submission = qs.submission
      qs.submission = nil
      qs.save! if qs.changed?
      submission.try(:destroy)
    end
  end

  def update_assignment
    delay_if_production.set_unpublished_question_count if id
    if !assignment_id && @old_assignment_id
      context_module_tags.preload(context_module: :content_tags).find_each do |cmt|
        cmt.confirm_valid_module_requirements
        cmt.update_course_pace_module_items
      end
    end
    if !graded? && (@old_assignment_id || last_assignment_id)
      ::Assignment.where(
        id: [@old_assignment_id, last_assignment_id].compact,
        submission_types: "online_quiz"
      ).update_all(workflow_state: "deleted", updated_at: Time.now.utc)
      course.recompute_student_scores
      delay_if_production(priority: Delayed::HIGH_PRIORITY).destroy_related_submissions
      ::ContentTag.delete_for(::Assignment.find(@old_assignment_id)) if @old_assignment_id
      ::ContentTag.delete_for(::Assignment.find(last_assignment_id)) if last_assignment_id
    end

    delay_if_production.update_existing_submissions if @update_existing_submissions
    if (assignment || @assignment_to_set) &&
       (@assignment_id_set || for_assignment?) &&
       @saved_by != :assignment &&
       (graded? || !@old_assignment_id)
      Quizzes::Quiz.where("assignment_id=? AND id<>?", assignment_id, self).update_all(workflow_state: "deleted", assignment_id: nil, updated_at: Time.now.utc) if assignment_id
      self.assignment = @assignment_to_set if @assignment_to_set && !assignment
      a = assignment
      a.quiz&.clear_changes_information # AR#changes persist in after_saves now - needed to prevent an autosave loop
      a.points_possible = points_possible
      a.description = description
      a.title = title
      a.due_at = due_at
      a.lock_at = lock_at
      a.unlock_at = unlock_at
      a.only_visible_to_overrides = only_visible_to_overrides
      a.submission_types = "online_quiz"
      a.assignment_group_id = self.assignment_group_id
      a.saved_by = :quiz
      if saved_by == :migration && a.update_cached_due_dates?
        a.needs_update_cached_due_dates = true
      end
      unless deleted?
        a.workflow_state = published? ? "published" : "unpublished"
      end
      @notify_of_update = a.will_save_change_to_workflow_state? && a.published? unless defined?(@notify_of_update)
      a.notify_of_update = @notify_of_update
      a.mark_as_importing!(@importing_migration) if @importing_migration
      a.with_versioning(false) do
        @notify_of_update ? a.save : a.save_without_broadcasting!
      end
      self.assignment_id = a.id
      Quizzes::Quiz.where(id: self).update_all(assignment_id: a.id)
      context_module_tags.find_each(&:update_course_pace_module_items)
    end
  end

  protected :update_assignment

  attr_reader :should_clear_availability_cache

  def check_if_needs_availability_cache_clear
    @should_clear_availability_cache ||= will_save_change_to_due_at? || will_save_change_to_lock_at? || will_save_change_to_unlock_at? || will_save_change_to_workflow_state?
  end

  def clear_availability_cache
    if should_clear_availability_cache && !saved_by == :migration
      clear_cache_key(:availability)
      assignment&.clear_cache_key(:availability)
    end
  end

  ##
  # when a quiz is updated, this method should be called to update the end_at
  # of all open quiz submissions. this ensures that students who are taking the
  # quiz when the time_limit is updated get the additional time added.
  def update_quiz_submission_end_at_times
    new_end_at = time_limit * 60.0

    update_sql = "started_at + INTERVAL '+? seconds'"

    # only update quiz submissions that:
    # 1. belong to this quiz;
    # 2. have been started; and
    # 3. won't lose time through this change.
    where_clause = <<~SQL.squish
        quiz_id = ? AND
        started_at IS NOT NULL AND
        finished_at IS NULL AND
      #{update_sql} > end_at
    SQL

    Quizzes::QuizSubmission.where(where_clause, self, new_end_at).update_all(["end_at = #{update_sql}", new_end_at])
  end

  workflow do
    state :created do
      event :did_edit, transitions_to: :edited
    end

    state :edited do
      event :offer, transitions_to: :available
    end

    state :available
    state :deleted
    state :unpublished
  end

  def root_entries_max_position
    question_max = quiz_questions.active.where(quiz_group_id: nil).maximum(:position)
    group_max = quiz_groups.maximum(:position)
    [question_max, group_max, 0].compact.max
  end

  def active_quiz_questions_without_group
    if quiz_questions.loaded?
      active_quiz_questions.reject(&:quiz_group_id)
    else
      active_quiz_questions.where(quiz_group_id: nil).to_a
    end
  end

  def active_quiz_questions
    if quiz_questions.loaded?
      quiz_questions.select(&:active?)
    else
      quiz_questions.active
    end
  end

  # Returns the list of all "root" entries, either questions or question
  # groups for this quiz.  This is PRE-SAVED data.  Once the quiz has
  # been saved, all the data can be found in Quizzes::Quiz.quiz_data
  def root_entries(force_check = false)
    return @root_entries if @root_entries && !force_check

    result = []
    result.concat active_quiz_questions_without_group
    result.concat quiz_groups
    result = result.sort_by { |e| e.position || ::CanvasSort::Last }.map do |e|
      res = nil
      if e.is_a? Quizzes::QuizQuestion
        res = e.data
      else # it's a Quizzes::QuizGroup
        data = e.attributes.with_indifferent_access
        data[:entry_type] = "quiz_group"
        if e.assessment_question_bank_id
          data[:assessment_question_bank_id] = e.assessment_question_bank_id
          data[:questions] = []
        else
          data[:questions] = e.quiz_questions.active.sort_by { |q| q.position || ::CanvasSort::Last }.map(&:data)
        end
        data[:pick_count] = e.pick_count
        res = data
      end
      res[:position] = e.position.to_i
      res
    end
    @root_entries = result
  end

  # Returns the number of questions a student will see on the
  # SAVED version of the quiz
  def question_count(force_check = false)
    return read_attribute(:question_count) if !force_check && read_attribute(:question_count)

    question_count = 0
    stored_questions.each do |q|
      if q[:pick_count]
        question_count += q[:pick_count]
      else
        question_count += 1 unless q[:question_type] == Quizzes::QuizQuestion::Q_TEXT_ONLY
      end
    end
    question_count || 0
  end

  def available_question_count
    published? ? question_count : unpublished_question_count
  end

  # Lists all the question types available in this quiz
  def question_types
    return [] unless quiz_data

    all_question_types = quiz_data.flat_map do |datum|
      if datum["entry_type"] == "quiz_group"
        if datum["assessment_question_bank_id"]
          # get ALL question types possible from the bank
          AssessmentQuestion
            .where(assessment_question_bank_id: datum["assessment_question_bank_id"])
            .pluck(:question_data).pluck("question_type")
        else
          datum["questions"].pluck("question_type")
        end
      else
        datum["question_type"]
      end
    end

    all_question_types.uniq
  end

  def assessment_question_bank_ids
    quiz_groups
      .pluck(:assessment_question_bank_id)
      .compact
      .uniq
  end

  def has_access_code
    access_code.present?
  end

  # Returns data for the SAVED version of the quiz.  That is, not
  # the version found by gathering relationships on the Quiz data models,
  # but the version being held in Quizzes::Quiz.quiz_data.  Caches the result
  # in @stored_questions.
  def stored_questions(preview = false)
    return @stored_questions if @stored_questions && !preview

    @stored_questions = begin
      data_set = if preview
                   generate_quiz_data(persist: false)
                 else
                   quiz_data || []
                 end

      builder = Quizzes::QuizQuestionBuilder.new({
                                                   shuffle_answers:
                                                 })

      builder.shuffle_quiz_data!(data_set)
    end
  end

  def single_attempt?
    allowed_attempts == 1
  end

  def unlimited_attempts?
    allowed_attempts == -1
  end

  def build_submission_end_at(submission, with_time_limit = true)
    course = context
    user   = submission.user
    end_at = nil

    if time_limit && with_time_limit
      end_at = submission.started_at + (time_limit.to_f * 60.0)
    end

    # add extra time
    if end_at && submission.extra_time
      end_at += (submission.extra_time * 60.0)
    end

    # Admins can take the full quiz whenever they want
    return end_at if user.is_a?(::User) && grants_right?(user, :grade)

    # We no longer use enrollment_term but get this info from enrollment_state
    fallback_end_at = course.enrollments.for_user(user).active_by_date
                            .maximum("enrollment_states.state_valid_until")

    # set to lock date
    if lock_at && !submission.manually_unlocked
      if !end_at || lock_at < end_at
        end_at = lock_at
      end
    elsif !end_at || (fallback_end_at && fallback_end_at < end_at)
      end_at = fallback_end_at
    end

    end_at
  end

  # Generates a submission for the specified user on this quiz, based
  # on the SAVED version of the quiz.  Does not consider permissions.
  def generate_submission(user, preview = false)
    submission = nil

    transaction do
      builder = Quizzes::QuizQuestionBuilder.new({
                                                   shuffle_answers:
                                                 })

      submission = Quizzes::SubmissionManager.new(self).find_or_create_submission(user, preview)
      submission.retake
      submission.attempt = (submission.attempt + 1) rescue 1
      submission.score = nil
      submission.fudge_points = nil

      submission.quiz_data = begin
        @stored_questions = nil
        builder.build_submission_questions(id, stored_questions(preview))
      end

      submission.quiz_version = version_number
      submission.started_at = ::Time.now
      submission.score_before_regrade = nil
      submission.end_at = build_submission_end_at(submission)
      submission.finished_at = nil
      submission.submission_data = {}
      submission.workflow_state = "preview" if preview
      submission.was_preview = preview
      submission.question_references_fixed = true

      if preview || submission.untaken?
        submission.save!
      else
        submission.with_versioning(true, &:save!)
      end
    end
    submission.record_creation_event unless preview
    submission
  end

  def generate_submission_for_participant(quiz_participant)
    identity = if quiz_participant.anonymous?
                 :user_code
               else
                 :user
               end

    generate_submission quiz_participant.send(identity), false
  end

  # Takes the PRE-SAVED version of the quiz and uses it to generate a
  # SAVED version.  That is, gathers the relationship entities from
  # the database and uses them to populate a static version that will
  # be held in Quizzes::Quiz.quiz_data
  def generate_quiz_data(opts = {})
    entries = root_entries(true)
    t = Time.now
    entries.each do |e|
      e[:published_at] = t
    end
    data = entries
    if opts[:persist] != false
      self.quiz_data = data

      unless survey? || saved_by_new_quizzes_migration
        possible = self.class.count_points_possible(data)
        self.points_possible = [possible, 0].max
      end
      self.allowed_attempts ||= 1
      check_if_submissions_need_review
    end
    data
  end

  def add_assessment_questions(assessment_questions, group = nil)
    questions = assessment_questions.map do |assessment_question|
      question = quiz_questions.build
      question.quiz_group_id = group.id if group && group.quiz_id == id
      question.write_attribute(:question_data, assessment_question.question_data)
      question.assessment_question = assessment_question
      question.assessment_question_version = assessment_question.version_number
      question.save
      question
    end
    questions.compact.uniq
  end

  def quiz_title
    result = title
    result = t("#quizzes.quiz.default_title", "Unnamed Quiz") if result == "undefined" || !result
    result = assignment.title if assignment
    result
  end

  alias_method :to_s, :quiz_title

  def low_level_locked_for?(user, opts = {})
    RequestCache.cache(locked_request_cache_key(user)) do
      user_submission = user && quiz_submissions.where(user_id: user.id).first
      return false if user_submission&.manually_unlocked

      quiz_for_user = overridden_for(user)

      unlock_time_not_yet_reached = quiz_for_user.unlock_at && quiz_for_user.unlock_at > Time.zone.now
      lock_time_already_occurred = quiz_for_user.lock_at && quiz_for_user.lock_at <= Time.zone.now

      locked = false
      lock_info = { object: quiz_for_user }
      if unlock_time_not_yet_reached
        locked = lock_info.merge({ unlock_at: quiz_for_user.unlock_at })
      elsif lock_time_already_occurred
        locked = lock_info.merge({ lock_at: quiz_for_user.lock_at, can_view: true })
      elsif !opts[:skip_assignment] && (assignment_lock = locked_by_assignment?(user, opts))
        locked = assignment_lock
      elsif (module_lock = locked_by_module_item?(user, opts))
        locked = lock_info.merge({ module: module_lock.context_module })
      elsif !context.try_rescue(:is_public) && !context.grants_right?(user, :participate_as_student) && !opts[:is_observer]
        locked = lock_info.merge({ missing_permission: :participate_as_student.to_s })
      end

      locked
    end
  end

  def locked_by_assignment?(user, opts = {})
    return false unless for_assignment?

    assignment.low_level_locked_for?(user, opts)
  end

  def context_module_action(user, action, points = nil)
    tags_to_update = context_module_tags.to_a
    if assignment
      tags_to_update += assignment.context_module_tags
    end
    tags_to_update.each { |tag| tag.context_module_action(user, action, points) }
  end

  # virtual attribute
  def locked=(new_val)
    new_val = Canvas::Plugin.value_to_boolean(new_val)
    if new_val
      # lock the quiz either until unlock_at, or indefinitely if unlock_at.nil?
      self.lock_at = Time.now
      self.unlock_at = [lock_at, unlock_at].min if unlock_at
    else
      # unlock the quiz
      self.unlock_at = Time.now
    end
  end

  def locked?
    (unlock_at && unlock_at > Time.now) ||
      (lock_at && lock_at <= Time.now)
  end

  def hide_results=(val)
    case val
    when Hash
      val = if val[:last_attempt] == "1"
              "until_after_last_attempt"
            elsif val[:never] != "1"
              "always"
            else
              nil
            end
    when ""
      val = nil
    end
    write_attribute(:hide_results, val)
  end

  def check_if_submissions_need_review
    self.class.connection.after_transaction_commit do
      version_num = version_number
      submissions_to_update = []
      quiz_submissions.each do |sub|
        next unless sub.completed?

        next if sub.quiz_version && sub.quiz_version >= version_num

        if changed_significantly_since?(sub.quiz_version)
          submissions_to_update << sub
        end
      end

      if submissions_to_update.any?
        shard.activate do
          Quizzes::QuizSubmission.where(id: submissions_to_update).update_all(workflow_state: "pending_review", updated_at: Time.now.utc)
        end
      end
    end
  end

  def changed_significantly_since?(version_number)
    @significant_version ||= {}
    return @significant_version[version_number] if @significant_version.key?(version_number)

    old_version = versions.get(version_number).model

    needs_review = false
    # Allow for floating point rounding error comparing to versions created before BigDecimal was used
    needs_review = true if [old_version.points_possible, points_possible].count(&:present?) == 1 ||
                           ((old_version.points_possible || 0) - (points_possible || 0)).abs > 0.0001
    needs_review = true if (old_version.quiz_data || []).length != (quiz_data || []).length
    unless needs_review
      new_data = quiz_data
      old_data = old_version.quiz_data
      new_data.each_with_index do |q, i|
        needs_review = true if (q[:id] || q["id"]) != (old_data[i][:id] || old_data[i]["id"])
      end
    end
    @significant_version[version_number] = needs_review
  end

  def validate_quiz_type
    return if self.quiz_type.blank?

    unless valid_quiz_type_values.include?(self.quiz_type)
      errors.add(:invalid_quiz_type, t("#quizzes.quiz.errors.invalid_quiz_type", "Quiz type is not valid"))
    end
  end

  def valid_quiz_type_values
    %w[practice_quiz assignment graded_survey survey]
  end

  def validate_ip_filter
    return if ip_filter.blank?

    require "ipaddr"
    begin
      ip_filter.split(",").each { |filter| ::IPAddr.new(filter) }
    rescue
      errors.add(:invalid_ip_filter, t("#quizzes.quiz.errors.invalid_ip_filter", "IP filter is not valid"))
    end
  end

  def validate_time_limit
    return if time_limit.blank?

    unless time_limit > 0
      errors.add(:time_limit, t("#quizzes.quiz.errors.invalid_time_limit", "Time Limit is not valid"))
    end
  end

  def validate_hide_results
    return if hide_results.blank?

    unless valid_hide_results_values.include?(hide_results)
      errors.add(:invalid_hide_results, t("#quizzes.quiz.errors.invalid_hide_results", "Hide results is not valid"))
    end
  end

  def valid_hide_results_values
    %w[always until_after_last_attempt until_after_due_date until_after_available_date]
  end

  def validate_correct_answer_visibility
    show_at = show_correct_answers_at
    hide_at = hide_correct_answers_at

    if show_at.present? && hide_at.present? && hide_at <= show_at
      errors.add(:show_correct_answers, "bad_range")
    end
  end

  def strip_html_answers(question)
    return if !question || !question[:answers] || !(%w[multiple_choice_question multiple_answers_question].include? question[:question_type])

    question[:answers].each do |answer|
      answer[:text] = strip_tags(answer[:html]) if answer[:html].present? && answer[:text].blank?
    end
  end

  def statistics(include_all_versions = true, includes_sis_ids = true)
    quiz_statistics.build(
      report_type: "student_analysis",
      includes_all_versions: include_all_versions,
      includes_sis_ids:
    ).report.generate
  end

  # finds or creates a QuizStatistics for the given report_type and
  # options
  def current_statistics_for(report_type, options = {})
    # item analysis always takes the first attempt (not necessarily the
    # most recent), thus we say it always cares about all versions
    options[:includes_all_versions] = true if report_type == "item_analysis"

    # item analysis doesn't include sis ids
    options[:includes_sis_ids] = false if report_type == "item_analysis"

    quiz_stats_opts = {
      report_type:,
      includes_all_versions: !!options[:includes_all_versions],
      includes_sis_ids: !!options[:includes_sis_ids],
      anonymous: anonymous_submissions?
    }

    last_quiz_activity = [
      published_at || created_at,
      quiz_submissions.completed.order("updated_at DESC").limit(1).pluck(:updated_at).first
    ].compact.max

    candidate_stats = quiz_statistics.report_type(report_type).where(quiz_stats_opts).last

    if candidate_stats.nil? || candidate_stats.created_at < last_quiz_activity
      quiz_statistics.create(quiz_stats_opts)
    else
      candidate_stats
    end
  end

  # Generate the CSV attachment of the current statistics for a given report
  # type.
  #
  # @param [Hash] options
  #   Options to pass to Quiz#current_statistics_for.
  #
  # @param [Boolean] [options.async=false]
  #   Pass true to generate the CSV in the background, otherwise this blocks.
  #
  # @return [Quizzes::QuizStatistics::Report]
  #   The QuizStatistics object that will ultimately contain the csv.
  def statistics_csv(report_type, options = {})
    current_statistics_for(report_type, options).tap do |stats|
      if options[:async]
        stats.generate_csv_in_background
      else
        stats.generate_csv
      end
    end
  end

  def post_to_sis=(post_to_sis)
    return unless assignment

    assignment.post_to_sis = post_to_sis
  end

  def post_to_sis?
    assignment&.post_to_sis
  end

  def unpublished_changes?
    last_edited_at && published_at && last_edited_at > published_at
  end

  def has_student_submissions?
    quiz_submissions.not_settings_only.where.not(user_id: nil).exists?
  end

  # clear out all questions so that the quiz can be replaced. this is currently
  # used by the respondus API.
  # returns false if the quiz can't be safely replaced, for instance if anybody
  # has taken the quiz.
  def clear_for_replacement
    return false if has_student_submissions?

    self.question_count = 0
    quiz_questions.active.map(&:destroy)
    quiz_groups.destroy_all
    self.quiz_data = nil
    true
  end

  def self.process_migration(data, migration, question_data)
    # TODO: use Importers::QuizImporter directly. this class method
    # will eventually get removed. leaving here while plugins get updated
    Importers::QuizImporter.process_migration(data, migration, question_data)
  end

  def self.serialization_excludes
    [:access_code]
  end

  set_policy do
    given do |user, session|
      !context.root_account.feature_enabled?(:granular_permissions_manage_assignments) &&
        context.grants_right?(user, session, :manage_assignments)
    end
    can :manage and can :read and can :create and can :update and can :submit and can :preview

    given do |user, session|
      context.root_account.feature_enabled?(:granular_permissions_manage_assignments) &&
        context.grants_right?(user, session, :manage_assignments_add)
    end
    can :read and can :create

    given do |user, session|
      context.root_account.feature_enabled?(:granular_permissions_manage_assignments) &&
        context.grants_right?(user, session, :manage_assignments_edit)
    end
    can :manage and can :read and can :update and can :submit and can :preview

    given do |user, session|
      !context.root_account.feature_enabled?(:granular_permissions_manage_assignments) &&
        context.grants_right?(user, session, :manage_assignments) &&
        (context.account_membership_allows(user) ||
         !due_for_any_student_in_closed_grading_period?)
    end
    can :delete

    given do |user, session|
      context.root_account.feature_enabled?(:granular_permissions_manage_assignments) &&
        context.grants_right?(user, session, :manage_assignments_delete) &&
        (context.account_membership_allows(user) ||
         !due_for_any_student_in_closed_grading_period?)
    end
    can :delete

    given { |user, session| context.grants_right?(user, session, :manage_grades) } # admins.include? user }
    can :read_statistics and can :read and can :submit and can :grade and can :review_grades

    given { |user| available? && context.try_rescue(:is_public) && !graded? && visible_to_user?(user) }
    can :submit

    given { |user, session| context.grants_right?(user, session, :read_as_admin) }
    can :read and can :submit and can :preview

    given do |user, session|
      published? && context.grants_right?(user, session, :read)
    end
    can :read

    given { |user, session| context.grants_right?(user, session, :view_all_grades) }
    can :read_statistics and can :review_grades

    given do |user, session|
      available? &&
        context.grants_right?(user, session, :participate_as_student) &&
        visible_to_user?(user)
    end
    can :read

    given do |user, session|
      available? &&
        context.grants_right?(user, session, :participate_as_student) &&
        visible_to_user?(user) &&
        !excused_for_student?(user)
    end
    can :submit

    given { |user| context.grants_right?(user, :view_quiz_answer_audits) }
    can :view_answer_audits
  end

  scope :include_assignment, -> { preload(:assignment) }
  scope :before, ->(date) { where("quizzes.created_at<?", date) }
  scope :active, -> { where("quizzes.workflow_state<>'deleted'") }
  scope :not_for_assignment, -> { where(assignment_id: nil) }
  scope :available, -> { where("quizzes.workflow_state = 'available'") }
  scope :for_course, ->(course_id) { where(context_type: "Course", context_id: course_id) }

  # NOTE: only use for courses with differentiated assignments on
  scope :visible_to_students_in_course_with_da, lambda { |student_ids, course_ids|
    joins(:quiz_student_visibilities)
      .where(quiz_student_visibilities: { user_id: student_ids, course_id: course_ids })
  }

  # Return all quizzes and their active overrides where either the
  # quiz or one of its overrides is due between start and ending.
  scope :due_between_with_overrides, lambda { |start, ending|
    joins("LEFT OUTER JOIN #{AssignmentOverride.quoted_table_name} assignment_overrides
          ON assignment_overrides.quiz_id = quizzes.id")
      .group("quizzes.id")
      .where('quizzes.due_at BETWEEN ? AND ?
          OR assignment_overrides.due_at_overridden AND
          assignment_overrides.due_at BETWEEN ? AND ?',
             start,
             ending,
             start,
             ending)
  }

  scope :ungraded_with_user_due_date, lambda { |user|
    from("(WITH overrides AS (
          SELECT DISTINCT ON (o.quiz_id, o.user_id) *
          FROM (
            SELECT ao.quiz_id, aos.user_id, ao.due_at, ao.due_at_overridden, 1 AS priority
            FROM #{AssignmentOverride.quoted_table_name} ao
            INNER JOIN #{AssignmentOverrideStudent.quoted_table_name} aos ON ao.id = aos.assignment_override_id AND ao.set_type = 'ADHOC'
            WHERE aos.user_id = #{User.connection.quote(user.id_for_database)}
              AND ao.workflow_state = 'active'
              AND aos.workflow_state <> 'deleted'
            UNION
            SELECT ao.quiz_id, e.user_id, ao.due_at, ao.due_at_overridden, 1 AS priority
            FROM #{AssignmentOverride.quoted_table_name} ao
            INNER JOIN #{Enrollment.quoted_table_name} e ON e.course_section_id = ao.set_id AND ao.set_type = 'CourseSection'
            WHERE e.user_id = #{User.connection.quote(user.id_for_database)}
              AND e.workflow_state NOT IN ('rejected', 'deleted', 'inactive')
              AND ao.workflow_state = 'active'
            UNION
            SELECT q.id, e.user_id, q.due_at, FALSE as due_at_overridden, 2 AS priority
            FROM #{Quizzes::Quiz.quoted_table_name} q
            INNER JOIN #{Enrollment.quoted_table_name} e ON e.course_id = q.context_id
            WHERE e.workflow_state NOT IN ('rejected', 'deleted', 'inactive')
              AND e.type in ('StudentEnrollment', 'StudentViewEnrollment')
              AND e.user_id = #{User.connection.quote(user.id_for_database)}
              AND q.assignment_id IS NULL
              AND NOT q.only_visible_to_overrides
          ) o
          ORDER BY o.user_id ASC, o.quiz_id ASC, priority ASC, o.due_at_overridden DESC, o.due_at DESC NULLS FIRST
        )
        SELECT CASE WHEN overrides.due_at_overridden THEN overrides.due_at ELSE q.due_at END as user_due_date, q.*
        FROM #{Quizzes::Quiz.quoted_table_name} q
        INNER JOIN overrides ON overrides.quiz_id = q.id) as quizzes")
      .select(arel.projections, "user_due_date").not_for_assignment
  }

  scope :ungraded_due_between_for_user, lambda { |start, ending, user|
    ungraded_with_user_due_date(user)
      .where(user_due_date: start..ending)
  }

  # Return quizzes (up to limit) that do not have any submissions
  scope :need_submitting_info, lambda { |user_id, limit|
    where("(SELECT COUNT(id) FROM #{Quizzes::QuizSubmission.quoted_table_name}
            WHERE quiz_id = quizzes.id
            AND workflow_state = 'complete'
            AND user_id = ?) = 0",
          user_id)
      .limit(limit)
      .order("quizzes.due_at")
      .preload(:context)
  }

  scope :not_locked, lambda {
    where("(quizzes.unlock_at IS NULL OR quizzes.unlock_at<:now) AND (quizzes.lock_at IS NULL OR quizzes.lock_at>:now)",
          now: Time.zone.now)
  }

  scope :not_ignored_by, lambda { |user, purpose|
    where.not(Ignore.where(asset_type: "Quizzes::Quiz",
                           user_id: user,
                           purpose:).where("asset_id=quizzes.id")
                       .arel.exists)
  }

  def peer_reviews_due_at
    nil
  end

  def submission_action_string
    t :submission_action_take_quiz, "Take %{title}", title:
  end

  def teachers
    context.teacher_enrollments.current.map(&:user)
  end

  def self.lockdown_browser_plugin_enabled?
    Canvas::Plugin.all_for_tag(:lockdown_browser).any? { |p| Canvas::Plugin.value_to_boolean(p.settings[:enabled]) }
  end

  def lockdown_browser_use_lti_tool?
    Canvas::Plugin.all_for_tag(:lockdown_browser).any? { |p| Canvas::Plugin.value_to_boolean(p.settings[:use_lti_tool]) }
  end

  def require_lockdown_browser
    self[:require_lockdown_browser] && Quizzes::Quiz.lockdown_browser_plugin_enabled?
  end

  alias_method :require_lockdown_browser?, :require_lockdown_browser

  def require_lockdown_browser_for_results
    require_lockdown_browser &&
      self[:require_lockdown_browser_for_results] &&
      Quizzes::Quiz.lockdown_browser_plugin_enabled?
  end

  alias_method :require_lockdown_browser_for_results?, :require_lockdown_browser_for_results

  def require_lockdown_browser_monitor
    self[:require_lockdown_browser_monitor] && Quizzes::Quiz.lockdown_browser_plugin_enabled?
  end

  alias_method :require_lockdown_browser_monitor?, :require_lockdown_browser_monitor

  def lockdown_browser_monitor_data
    self[:lockdown_browser_monitor_data]
  end

  def self.non_shuffled_questions
    %w[true_false_question matching_question fill_in_multiple_blanks_question]
  end

  def self.shuffleable_question_type?(question_type)
    !non_shuffled_questions.include?(question_type)
  end

  def shuffle_answers_for_user?(user)
    shuffle_answers? && !grants_right?(user, :manage)
  end

  def timer_autosubmit_disabled?
    context&.root_account&.feature_enabled?(:timer_without_autosubmission) && disable_timer_autosubmission
  end

  def access_code_key_for_user(user)
    # user might be nil (practice quiz in public course) and isn't really
    # necessary for this key anyway, but maintain backwards compat
    "quiz_#{id}_#{user.try(:id)}_entered_access_code"
  end

  def group_category_id
    assignment.try(:group_category_id)
  end

  def publish
    self.workflow_state = "available"
  end

  def unpublish
    self.workflow_state = "unpublished"
  end

  def publish!
    publish
    save!
    self
  end

  def unpublish!
    unpublish
    save!
    self
  end

  def can_unpublish?
    return true if new_record?
    return @can_unpublish unless @can_unpublish.nil?

    @can_unpublish = !has_student_submissions? && (assignment.blank? || assignment.can_unpublish?)
  end
  attr_writer :can_unpublish

  def self.preload_can_unpublish(quizzes, assmnt_ids_with_subs = nil)
    return unless quizzes.any?

    assmnt_ids_with_subs ||= Assignment.assignment_ids_with_submissions(quizzes.filter_map(&:assignment_id))

    # yes, this is a complicated query, but it greatly improves the runtime to do it this way
    filter = Quizzes::QuizSubmission.where("quiz_submissions.quiz_id=s.quiz_id")
                                    .not_settings_only.where.not(user_id: nil)
    values = quizzes.map { |q| "(#{q.id})" }.join(", ")
    constant_table = "( VALUES #{values} ) AS s(quiz_id)"

    quiz_ids_with_subs = Quizzes::QuizSubmission
                         .from(constant_table)
                         .where(filter.arel.exists)
                         .pluck("s.quiz_id")

    quizzes.each do |quiz|
      quiz.can_unpublish = !quiz_ids_with_subs.include?(quiz.id) &&
                           (quiz.assignment_id.nil? || !assmnt_ids_with_subs.include?(quiz.assignment_id))
    end
  end

  alias_method :unpublishable?, :can_unpublish?
  alias_method :unpublishable, :can_unpublish?

  # marks a quiz as having unpublished changes
  def self.mark_quiz_edited(id)
    now = Time.now.utc
    where(id:).update_all(last_edited_at: now, updated_at: now)
  end

  def mark_edited!
    self.class.mark_quiz_edited(id)
  end

  def anonymous_survey?
    survey? && anonymous_submissions
  end

  def has_file_upload_question?
    return false unless quiz_data.present?

    !!quiz_data.detect { |data_hash| data_hash[:question_type] == "file_upload_question" }
  end

  def draft_state
    state = workflow_state
    (state == "available") ? "active" : state
  end

  def active?
    draft_state == "active"
  end

  alias_method :published?, :active?
  alias_method :published, :active?

  def unpublished?
    !published?
  end

  def regrade_if_published
    unless unpublished_changes?
      options = {
        quiz: self,
        version_number:
      }
      if current_quiz_question_regrades.present?
        Quizzes::QuizRegrader::Regrader.delay(strand: "quiz:#{global_id}:regrading")
                                       .regrade!(options)
      end
    end
    true
  end

  def current_regrade
    Quizzes::QuizRegrade.where(quiz_id: id, quiz_version: version_number)
                        .where("quiz_question_regrades.regrade_option != 'disabled'")
                        .eager_load(:quiz_question_regrades)
                        .preload(quiz_question_regrades: :quiz_question).first
  end

  def current_quiz_question_regrades
    current_regrade ? current_regrade.quiz_question_regrades : []
  end

  def questions_regraded_since(created_at)
    question_regrades = Set.new
    quiz_regrades.where("quiz_regrades.created_at > ? AND quiz_question_regrades.regrade_option != 'disabled'", created_at)
                 .eager_load(:quiz_question_regrades).each do |regrade|
      ids = regrade.quiz_question_regrades.map(&:quiz_question_id)
      question_regrades.merge(ids)
    end
    question_regrades.count
  end

  def available?
    published?
  end

  def excused_for_student?(student)
    assignment&.submission_for_student(student)&.excused?
  end

  def is_module_item?
    context_module_tags.present?
  end

  def due_for_any_student_in_closed_grading_period?(periods = nil)
    return false unless due_at || has_overrides?

    periods ||= GradingPeriod.for(course)
    due_in_closed_period =
      !only_visible_to_overrides &&
      GradingPeriodHelper.date_in_closed_grading_period?(due_at, periods)
    due_in_closed_period ||= active_assignment_overrides.any? do |override|
      GradingPeriodHelper.date_in_closed_grading_period?(override.due_at, periods)
    end

    due_in_closed_period
  end

  delegate :feature_enabled?, to: :context

  # The IP filters available for this Quiz, which is an aggregate of the Quiz's
  # active IP filter and all the IP filters defined in its account hierarchy.
  #
  # @return [Array<Hash>]
  #   The set of IP filters, with three accessible String attributes:
  #
  #     - :name => a unique name for the filter
  #     - :account => name of the scope the filter is defined in (Quiz or Account)
  #     - :filter => the actual filter value (IP address or a range of)
  #
  def available_ip_filters
    filters = []
    accounts = context.account.account_chain.uniq

    if ip_filter.present?
      filters << {
        name: t("#quizzes.quiz.current_filter", "Current Filter"),
        account: title,
        filter: ip_filter
      }
    end

    accounts.each do |account|
      account_filters = account.settings[:ip_filters] || {}
      account_filters.sort_by(&:first).each do |key, filter|
        filters << {
          name: key,
          account: account.name,
          filter:
        }
      end
    end

    filters
  end

  def anonymize_students?
    assignment.present? && assignment.anonymize_students?
  end

  def self.class_names
    %w[Quiz Quizzes::Quiz]
  end

  def self.reflection_type_name
    "quizzes:quiz"
  end

  def run_if_overrides_changed!
    relock_modules!
    clear_cache_key(:availability)
    if assignment
      assignment.clear_cache_key(:availability)
      assignment.relock_modules!
    end
  end

  # Assignment#run_if_overrides_changed_later! uses its keyword arguments, but
  # this method does not
  def run_if_overrides_changed_later!(**)
    delay_if_production(singleton: "quiz_overrides_changed_#{global_id}").run_if_overrides_changed!
  end

  # returns visible students for differentiated assignments
  def visible_students_with_da(context_students)
    quiz_students = context_students.joins(:quiz_student_visibilities)
                                    .where(quiz_student_visibilities: { quiz_id: id })

    # empty quiz_students means the quiz is for everyone
    return quiz_students if quiz_students.present?

    context_students
  end

  # This alias exists to handle cases where a method that expects an
  # Assignment is instead passed a quiz (e.g., Submission#submission_zip).
  alias_attribute :anonymous_grading?, :anonymous_submissions
end
