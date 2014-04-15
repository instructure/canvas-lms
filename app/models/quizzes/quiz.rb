#
# Copyright (C) 2011 - 2013 Instructure, Inc.
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
require 'canvas/draft_state_validations'

class Quizzes::Quiz < ActiveRecord::Base
  self.table_name = 'quizzes' unless CANVAS_RAILS2

  include Workflow
  include HasContentTags
  include CopyAuthorizedLinks
  include ActionView::Helpers::SanitizeHelper
  extend ActionView::Helpers::SanitizeHelper::ClassMethods
  include ContextModuleItem
  include DatesOverridable
  include SearchTermHelper
  include Canvas::DraftStateValidations

  attr_accessible :title, :description, :points_possible, :assignment_id, :shuffle_answers,
    :show_correct_answers, :time_limit, :allowed_attempts, :scoring_policy, :quiz_type,
    :lock_at, :unlock_at, :due_at, :access_code, :anonymous_submissions, :assignment_group_id,
    :hide_results, :locked, :ip_filter, :require_lockdown_browser,
    :require_lockdown_browser_for_results, :context, :notify_of_update,
    :one_question_at_a_time, :cant_go_back, :show_correct_answers_at, :hide_correct_answers_at,
    :require_lockdown_browser_monitor, :lockdown_browser_monitor_data

  attr_readonly :context_id, :context_type
  attr_accessor :notify_of_update

  has_many :quiz_questions, :dependent => :destroy, :order => 'position', class_name: 'Quizzes::QuizQuestion'
  has_many :quiz_submissions, :dependent => :destroy, :class_name => 'Quizzes::QuizSubmission'
  has_many :quiz_groups, :dependent => :destroy, :order => 'position', class_name: 'Quizzes::QuizGroup'
  has_many :quiz_statistics, :class_name => 'Quizzes::QuizStatistics', :order => 'created_at'
  has_many :attachments, :as => :context, :dependent => :destroy
  has_many :quiz_regrades, class_name: 'Quizzes::QuizRegrade'
  belongs_to :context, :polymorphic => true
  belongs_to :assignment
  belongs_to :assignment_group

  def self.polymorphic_names
    [self.base_class.name, "Quiz"]
  end

  EXPORTABLE_ATTRIBUTES = [
    :id, :title, :description, :quiz_data, :points_possible, :context_id, :context_type, :assignment_id, :workflow_state, :shuffle_answers, :show_correct_answers, :time_limit,
    :allowed_attempts, :scoring_policy, :quiz_type, :created_at, :updated_at, :lock_at, :unlock_at, :deleted_at, :could_be_locked, :cloned_item_id, :unpublished_question_count,
    :due_at, :question_count, :last_assignment_id, :published_at, :last_edited_at, :anonymous_submissions, :assignment_group_id, :hide_results, :ip_filter, :require_lockdown_browser,
    :require_lockdown_browser_for_results, :one_question_at_a_time, :cant_go_back, :show_correct_answers_at, :hide_correct_answers_at, :require_lockdown_browser_monitor, :lockdown_browser_monitor_data
  ]

  EXPORTABLE_ASSOCIATIONS = [:quiz_questions, :quiz_submissions, :quiz_groups, :quiz_statistics, :attachments, :quiz_regrades, :context, :assignment, :assignment_group]

  validates_length_of :description, :maximum => maximum_long_text_length, :allow_nil => true, :allow_blank => true
  validates_length_of :title, :maximum => maximum_string_length, :allow_nil => true
  validates_presence_of :context_id
  validates_presence_of :context_type
  validates_numericality_of :points_possible, less_than_or_equal_to: 2000000000, allow_nil: true
  validate :validate_quiz_type, :if => :quiz_type_changed?
  validate :validate_ip_filter, :if => :ip_filter_changed?
  validate :validate_hide_results, :if => :hide_results_changed?
  validate :validate_draft_state_change, :if => :workflow_state_changed?
  validate :validate_correct_answer_visibility, :if => lambda { |quiz|
    quiz.show_correct_answers_at_changed? ||
      quiz.hide_correct_answers_at_changed?
  }
  sanitize_field :description, CanvasSanitize::SANITIZE
  copy_authorized_links(:description) { [self.context, nil] }

  before_save :build_assignment
  before_save :set_defaults
  before_save :flag_columns_that_need_republish
  after_save :update_assignment
  after_save :touch_context
  after_save :regrade_if_published

  serialize :quiz_data

  simply_versioned

  has_many :context_module_tags, :as => :content, :class_name => 'ContentTag', :conditions => "content_tags.tag_type='context_module' AND content_tags.workflow_state<>'deleted'", :include => {:context_module => [:content_tags]}

  # This callback is listed here in order for the :link_assignment_overrides
  # method to be called after the simply_versioned callbacks. We want the
  # overrides to reflect the most recent version of the quiz.
  # If we placed this before simply_versioned, the :link_assignment_overrides
  # method would fire first, meaning that the overrides would reflect the
  # last version of the assignment, because the next callback would be a
  # simply_versioned callback updating the version.
  after_save :link_assignment_overrides, :if => :assignment_id_changed?

  # override has_one relationship provided by simply_versioned
  def current_version_unidirectional
    versions.limit(1)
  end

  def infer_times
    # set the time to 11:59 pm in the creator's time zone, if none given
    self.due_at = CanvasTime.fancy_midnight(self.due_at)
    self.lock_at = CanvasTime.fancy_midnight(self.lock_at)
  end

  def set_defaults
    self.one_question_at_a_time = false if self.one_question_at_a_time == nil
    self.cant_go_back = false if self.cant_go_back == nil || self.one_question_at_a_time == false
    self.shuffle_answers = false if self.shuffle_answers == nil
    self.show_correct_answers = true if self.show_correct_answers == nil
    if !self.show_correct_answers
      self.show_correct_answers_at = nil
      self.hide_correct_answers_at = nil
    end
    self.allowed_attempts = 1 if self.allowed_attempts == nil
    self.scoring_policy = "keep_highest" if self.scoring_policy == nil
    self.due_at ||= self.lock_at if self.lock_at.present?
    self.ip_filter = nil if self.ip_filter && self.ip_filter.strip.empty?
    if !self.available? && !self.survey?
      self.points_possible = self.current_points_possible
    end
    self.title = t('#quizzes.quiz.default_title', "Unnamed Quiz") if self.title.blank?
    self.quiz_type ||= "assignment"
    self.last_assignment_id = self.assignment_id_was if self.assignment_id_was
    if (!graded? && self.assignment_id) || (self.assignment_id_was && self.assignment_id != self.assignment_id_was)
      @old_assignment_id = self.assignment_id_was
      @assignment_to_set = self.assignment
      self.assignment_id = nil
    end
    self.assignment_group_id ||= self.assignment.assignment_group_id if self.assignment
    self.question_count = self.question_count(true)
    @update_existing_submissions = true if self.for_assignment? && self.quiz_type_changed?
    @stored_questions = nil
  end

  # some attributes require us to republish for non-draft state
  # We can safely remove this when draft state is permanent
  def flag_columns_that_need_republish
    return if context.feature_enabled?(:draft_state)

    if shuffle_answers_changed? && !shuffle_answers
      self.last_edited_at = Time.now.utc
    end
  end

  protected :set_defaults

  def new_assignment_id?
    last_assignment_id != assignment_id
  end

  def link_assignment_overrides
    override_students = [assignment_override_students]
    overrides = [assignment_overrides]
    overrides_params = {:quiz_id => id, :quiz_version => version_number}

    if assignment
      override_students += [assignment.assignment_override_students]
      overrides += [assignment.assignment_overrides]
      overrides_params[:assignment_version] = assignment.version_number
      overrides_params[:assignment_id] = assignment_id
    end

    fields = [:assignment_version, :assignment_id, :quiz_version, :quiz_id]
    overrides.flatten.each do |override|
      fields.each do |field|
        override.send(:"#{field}=", overrides_params[field])
      end
      override.save!
    end

    override_students.each do |collection|
      collection.update_all(:assignment_id => assignment_id, :quiz_id => id)
    end
  end

  def build_assignment
    if (context.feature_enabled?(:draft_state) || self.available?) &&
      !self.assignment_id && self.graded? && @saved_by != :assignment &&
      @saved_by != :clone
      assignment = self.assignment
      assignment ||= self.context.assignments.build(:title => self.title, :due_at => self.due_at, :submission_types => 'online_quiz')
      assignment.assignment_group_id = self.assignment_group_id
      assignment.saved_by = :quiz
      if context.feature_enabled?(:draft_state) && !deleted?
        assignment.workflow_state = self.published? ? 'published' : 'unpublished'
      end
      assignment.save
      self.assignment_id = assignment.id
    end
  end

  def readable_type
    self.survey? ? t('#quizzes.quiz.types.survey', "Survey") : t('#quizzes.quiz.types.quiz', "Quiz")
  end

  def valid_ip?(ip)
    require 'ipaddr'
    ip_filter.split(/,/).any? do |filter|
      addr_range = ::IPAddr.new(filter) rescue nil
      addr = ::IPAddr.new(ip) rescue nil
      addr && addr_range && addr_range.include?(addr)
    end
  end

  def current_points_possible
    entries = self.root_entries
    possible = 0
    entries.each do |e|
      if e[:question_points]
        possible += (e[:question_points].to_f * e[:actual_pick_count])
      else
        possible += e[:points_possible].to_f unless e[:unsupported]
      end
    end
    possible = self.assignment.points_possible if entries.empty? && self.assignment
    possible
  end

  def set_unpublished_question_count
    entries = self.root_entries(true)
    cnt = 0
    entries.each do |e|
      if e[:question_points]
        cnt += e[:actual_pick_count]
      else
        cnt += 1 unless e[:unsupported]
      end
    end

    # TODO: this is hacky, but we don't want callbacks to run because we're in an after_save. Refactor.
    Quizzes::Quiz.where(:id => self).update_all(:unpublished_question_count => cnt)
    self.unpublished_question_count = cnt
  rescue
  end

  def for_assignment?
    self.assignment_id && self.assignment && self.assignment.submission_types == 'online_quiz'
  end

  def muted?
    self.assignment && self.assignment.muted?
  end

  alias_method :destroy!, :destroy

  def destroy
    self.workflow_state = 'deleted'
    self.deleted_at = Time.now.utc
    res = self.save
    if self.for_assignment?
      self.assignment.destroy unless self.assignment.deleted?
    end
    res
  end

  def restore(from=nil)
    self.workflow_state = self.context.feature_enabled?(:draft_state) ? 'unpublished' : 'edited'
    self.save
    self.assignment.restore(:quiz) if self.for_assignment?
  end

  def unlink_from(type)
    @saved_by = type
    if self.root_entries.empty? && !self.available?
      self.assignment = nil
      self.destroy
    else
      self.assignment = nil
      self.save
    end
  end

  def assignment_id=(val)
    @assignment_id_set = true
    write_attribute(:assignment_id, val)
  end

  def due_at=(val)
    val = val.in_time_zone.end_of_day if val.is_a?(Date)
    if val.is_a?(String)
      super(Time.zone.parse(val))
      infer_times unless val.match(/:/)
    else
      super(val)
    end
  end

  def assignment?
    self.quiz_type == 'assignment'
  end

  def survey?
    self.quiz_type == 'survey' || self.quiz_type == 'graded_survey'
  end

  def graded?
    self.quiz_type == 'assignment' || self.quiz_type == 'graded_survey'
  end

  def ungraded?
    !self.graded?
  end

  # Determine if the quiz should display the correct answers and the score points.
  # Takes into account the quiz settings, the user viewing and the submission to
  # be viewed.
  def show_correct_answers?(user, submission)
    show_at = self.show_correct_answers_at
    hide_at = self.hide_correct_answers_at

    # NOTE: We don't have a submission user when the teacher is previewing the
    # quiz and displaying the results'
    return true if self.grants_right?(user, nil, :grade) &&
      (submission && submission.user && submission.user != user)

    return false if !self.show_correct_answers

    # Are we past the date the correct answers should no longer be shown after?
    return false if hide_at.present? && Time.now > hide_at

    show_at.present? ? Time.now > show_at : true
  end

  def restrict_answers_for_concluded_course?
    course = self.context
    concluded = course.conclude_at && course.conclude_at < Time.now
    concluded && course.root_account.settings[:restrict_quiz_questions]
  end

  def update_existing_submissions
    # If the quiz suddenly changes from non-graded to graded,
    # then this will update the existing submissions to reflect quiz
    # scores in the gradebook.
    self.quiz_submissions.each { |s| s.save! }
  end

  attr_accessor :saved_by

  def update_assignment
    send_later_if_production(:set_unpublished_question_count) if self.id
    if !self.assignment_id && @old_assignment_id
      self.context_module_tags.each { |tag| tag.confirm_valid_module_requirements }
    end
    if !self.graded? && (@old_assignment_id || self.last_assignment_id)
      ::Assignment.where(:id => [@old_assignment_id, self.last_assignment_id].compact, :submission_types => 'online_quiz').update_all(:workflow_state => 'deleted', :updated_at => Time.now.utc)
      self.quiz_submissions.each do |qs|
        submission = qs.submission
        qs.submission = nil
        qs.save! if qs.changed?
        submission.try(:destroy)
      end
      ::ContentTag.delete_for(::Assignment.find(@old_assignment_id)) if @old_assignment_id
      ::ContentTag.delete_for(::Assignment.find(self.last_assignment_id)) if self.last_assignment_id
    end

    send_later_if_production(:update_existing_submissions) if @update_existing_submissions
    if (self.assignment || @assignment_to_set) && (@assignment_id_set || self.for_assignment?) && @saved_by != :assignment
      if !self.graded? && @old_assignment_id
      else
        Quizzes::Quiz.where("assignment_id=? AND id<>?", self.assignment_id, self).update_all(:workflow_state => 'deleted', :assignment_id => nil, :updated_at => Time.now.utc) if self.assignment_id
        self.assignment = @assignment_to_set if @assignment_to_set && !self.assignment
        a = self.assignment
        a.points_possible = self.points_possible
        a.description = self.description
        a.title = self.title
        a.due_at = self.due_at
        a.lock_at = self.lock_at
        a.unlock_at = self.unlock_at
        a.submission_types = "online_quiz"
        a.assignment_group_id = self.assignment_group_id
        a.saved_by = :quiz
        a.workflow_state = 'published' if a.deleted?
        if context.feature_enabled?(:draft_state) && !deleted?
          a.workflow_state = self.published? ? 'published' : 'unpublished'
        end
        @notify_of_update ||= a.workflow_state_changed? && a.published?
        a.notify_of_update = @notify_of_update
        a.with_versioning(false) do
          @notify_of_update ? a.save : a.save_without_broadcasting!
        end
        self.assignment_id = a.id
        Quizzes::Quiz.where(:id => self).update_all(:assignment_id => a)
      end
    end
  end

  protected :update_assignment

  ##
  # when a quiz is updated, this method should be called to update the end_at
  # of all open quiz submissions. this ensures that students who are taking the
  # quiz when the time_limit is updated get the additional time added.
  def update_quiz_submission_end_at_times
    new_end_at = time_limit * 60.0

    update_sql = case ActiveRecord::Base.connection.adapter_name
                 when 'PostgreSQL'
                   "started_at + INTERVAL '+? seconds'"
                 when 'MySQL', 'Mysql2'
                   "started_at + INTERVAL ? SECOND"
                 when /sqlite/
                   "DATETIME(started_at, '+? seconds')"
                 end

    # only update quiz submissions that:
    # 1. belong to this quiz;
    # 2. haven't been started; and
    # 3. won't lose time through this change.
    where_clause = <<-END
      quiz_id = ? AND
      started_at IS NOT NULL AND
      finished_at IS NULL AND
    #{update_sql} > end_at
    END

    Quizzes::QuizSubmission.where(where_clause, self, new_end_at).update_all(["end_at = #{update_sql}", new_end_at])
  end

  workflow do
    state :created do
      event :did_edit, :transitions_to => :edited
    end

    state :edited do
      event :offer, :transitions_to => :available
    end

    state :available
    state :deleted
    state :unpublished
  end

  def root_entries_max_position
    question_max = self.active_quiz_questions.where(quiz_group_id: nil).maximum(:position)
    group_max = self.quiz_groups.maximum(:position)
    [question_max, group_max, 0].compact.max
  end

  def active_quiz_questions_without_group
    if self.quiz_questions.loaded?
      active_quiz_questions.select { |q| !q.quiz_group_id }
    else
      active_quiz_questions.where(quiz_group_id: nil).all
    end
  end

  def active_quiz_questions
    if self.quiz_questions.loaded?
      quiz_questions.select(&:active?)
    else
      quiz_questions.active
    end
  end

  # Returns the list of all "root" entries, either questions or question
  # groups for this quiz.  This is PRE-SAVED data.  Once the quiz has
  # been saved, all the data can be found in Quizzes::Quiz.quiz_data
  def root_entries(force_check=false)
    return @root_entries if @root_entries && !force_check
    result = []
    result.concat self.active_quiz_questions_without_group
    result.concat self.quiz_groups
    result = result.sort_by { |e| e.position || ::CanvasSort::Last }.map do |e|
      res = nil
      if e.is_a? Quizzes::QuizQuestion
        res = e.data
      else #it's a Quizzes::QuizGroup
        data = e.attributes.with_indifferent_access
        data[:entry_type] = "quiz_group"
        if e.assessment_question_bank_id
          data[:assessment_question_bank_id] = e.assessment_question_bank_id
          data[:questions] = []
        else
          data[:questions] = e.quiz_questions.active.sort_by { |q| q.position || ::CanvasSort::Last }.map(&:data)
        end
        data[:actual_pick_count] = e.actual_pick_count
        res = data
      end
      res[:position] = e.position.to_i
      res
    end
    @root_entries = result
  end


  # Returns the number of questions a student will see on the
  # SAVED version of the quiz
  def question_count(force_check=false)
    return read_attribute(:question_count) if !force_check && read_attribute(:question_count)
    question_count = 0
    self.stored_questions.each do |q|
      if q[:pick_count]
        question_count += q[:actual_pick_count] || q[:pick_count]
      else
        question_count += 1 unless q[:question_type] == "text_only_question"
      end
    end
    question_count || 0
  end

  def available_question_count
    published? ? question_count : unpublished_question_count
  end

  # Returns data for the SAVED version of the quiz.  That is, not
  # the version found by gathering relationships on the Quiz data models,
  # but the version being held in Quizzes::Quiz.quiz_data.  Caches the result
  # in @stored_questions.
  def stored_questions(hashes=nil)
    res = []
    return @stored_questions if @stored_questions && !hashes
    questions = hashes || self.quiz_data || []
    questions.each do |val|

      if val[:answers]
        val[:answers] = prepare_answers(val)
        val[:matches] = val[:matches].sort_by { |m| m[:text] || ::CanvasSort::First } if val[:matches]
      elsif val[:questions] # It's a Quizzes::QuizGroup
        if val[:assessment_question_bank_id]
          # It points to a question bank
          # question/answer/match shuffling happens when a submission is generated
        else #normal Quizzes::QuizGroup
          questions = []
          val[:questions].each do |question|
            if question[:answers]
              question[:answers] = prepare_answers(question)
              question[:matches] = question[:matches].sort_by { |m| m[:text] || ::CanvasSort::First } if question[:matches]
            end
            questions << question
          end
          questions = questions.sort_by { |q| rand }
          val[:questions] = questions
        end
      end
      res << val
    end
    @stored_questions = res
    res
  end

  def single_attempt?
    self.allowed_attempts == 1
  end

  def unlimited_attempts?
    self.allowed_attempts == -1
  end

  def generate_submission_question(q)
    @idx ||= 1
    q[:name] = t '#quizzes.quiz.question_name_counter', "Question %{question_number}", :question_number => @idx
    if q[:question_type] == 'text_only_question'
      q[:name] = t '#quizzes.quiz.default_text_only_question_name', "Spacer"
      @idx -= 1
    elsif q[:question_type] == 'fill_in_multiple_blanks_question'
      text = q[:question_text]
      variables = q[:answers].map { |a| a[:blank_id] }.uniq
      variables.each do |variable|
        variable_id = ::AssessmentQuestion.variable_id(variable)
        re = Regexp.new("\\[#{variable}\\]")
        text = text.sub(re, "<input class='question_input' type='text' autocomplete='off' style='width: 120px;' name='question_#{q[:id]}_#{variable_id}' value='{{question_#{q[:id]}_#{variable_id}}}' />")
      end
      q[:original_question_text] = q[:question_text]
      q[:question_text] = text
    elsif q[:question_type] == 'multiple_dropdowns_question'
      text = q[:question_text]
      variables = q[:answers].map { |a| a[:blank_id] }.uniq
      variables.each do |variable|
        variable_id = ::AssessmentQuestion.variable_id(variable)
        variable_answers = q[:answers].select { |a| a[:blank_id] == variable }
        options = variable_answers.map { |a| "<option value='#{a[:id]}'>#{CGI::escapeHTML(a[:text])}</option>" }
        select = "<select class='question_input' name='question_#{q[:id]}_#{variable_id}'><option value=''>#{ERB::Util.h(t('#quizzes.quiz.default_question_input', "[ Select ]"))}</option>#{options}</select>"
        re = Regexp.new("\\[#{variable}\\]")
        text = text.sub(re, select)
      end
      q[:original_question_text] = q[:question_text]
      q[:question_text] = text
      # on equation questions, pick one of the formulas, plug it in
      # and you should be able to treat it like a numerical_answer
      # question for all intents and purposes
    elsif q[:question_type] == 'calculated_question'
      text = q[:question_text]
      q[:answers] = [q[:answers].sort_by { |a| rand }.first].compact
      if q[:answers].first
        q[:answers].first[:variables].each do |variable|
          re = Regexp.new("\\[#{variable[:name]}\\]")
          text = text.gsub(re, variable[:value].to_s)
        end
      end
      q[:question_text] = text
    end
    q[:question_name] = q[:name]
    @idx += 1
    q
  end

  # Generates a submission for the specified user on this quiz, based
  # on the SAVED version of the quiz.  Does not consider permissions.
  def generate_submission(user, preview=false)
    submission = Quizzes::SubmissionManager.new(self).find_or_create_submission(user, preview)
    submission.retake
    submission.attempt = (submission.attempt + 1) rescue 1
    user_questions = []
    @idx = 1
    @stored_questions = nil
    @submission_questions = self.stored_questions
    if preview
      @submission_questions = self.stored_questions(generate_quiz_data(:persist => false))
    end

    exclude_ids = @submission_questions.map { |q| q[:assessment_question_id] }.compact
    @submission_questions.each do |q|
      if q[:pick_count] #Quizzes::QuizGroup
        if q[:assessment_question_bank_id]
          bank = ::AssessmentQuestionBank.find_by_id(q[:assessment_question_bank_id]) if q[:assessment_question_bank_id].present?
          if bank
            questions = bank.select_for_submission(q[:pick_count], exclude_ids)
            questions = questions.map { |aq| aq.data }
            questions.each do |question|
              if question[:answers]
                question[:answers] = prepare_answers(question)
                question[:matches] = question[:matches].sort_by { |m| m[:text] || ::CanvasSort::First } if question[:matches]
              end
              question[:points_possible] = q[:question_points]
              question[:published_at] = q[:published_at]
              user_questions << generate_submission_question(question)
            end
          end
        else
          questions = q[:questions].shuffle
          q[:pick_count].times do |i|
            if questions[i]
              question = questions[i]
              question[:points_possible] = q[:question_points]
              user_questions << generate_submission_question(question)
            end
          end
        end
      else #just a question
        user_questions << generate_submission_question(q)
      end
    end

    submission.score = nil
    submission.fudge_points = nil
    submission.quiz_data = user_questions
    submission.quiz_version = self.version_number
    submission.started_at = ::Time.now
    submission.score_before_regrade = nil
    submission.end_at = nil
    submission.end_at = submission.started_at + (self.time_limit.to_f * 60.0) if self.time_limit
    # Admins can take the full quiz whenever they want
    unless user.is_a?(::User) && self.grants_right?(user, nil, :grade)
      submission.end_at = due_at if due_at && ::Time.now < due_at && (!submission.end_at || due_at < submission.end_at)
      submission.end_at = lock_at if lock_at && !submission.manually_unlocked && (!submission.end_at || lock_at < submission.end_at)
    end
    submission.end_at += (submission.extra_time * 60.0) if submission.end_at && submission.extra_time
    submission.finished_at = nil
    submission.submission_data = {}
    submission.workflow_state = 'preview' if preview
    submission.was_preview = preview
    if preview || submission.untaken?
      submission.save
    else
      submission.with_versioning(true, &:save!)
    end

    # Make sure the submission gets graded when it becomes overdue (if applicable)
    submission.grade_when_overdue unless preview || !submission.end_at
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

  def prepare_answers(question)
    if answers = question[:answers]
      if shuffle_answers && Quizzes::Quiz.shuffleable_question_type?(question[:question_type])
        answers.sort_by { |a| rand }
      else
        answers
      end
    end
  end

  # Takes the PRE-SAVED version of the quiz and uses it to generate a
  # SAVED version.  That is, gathers the relationship entities from
  # the database and uses them to populate a static version that will
  # be held in Quizzes::Quiz.quiz_data
  def generate_quiz_data(opts={})
    entries = self.root_entries(true)
    possible = 0
    t = Time.now
    entries.each do |e|
      if e[:question_points] #QuizGroup
        possible += (e[:question_points].to_f * e[:actual_pick_count])
      else
        possible += e[:points_possible].to_f
      end
      e[:published_at] = t
    end
    data = entries
    if opts[:persist] != false
      self.quiz_data = data

      if !self.survey?
        self.points_possible = possible
      end
      self.allowed_attempts ||= 1
      check_if_submissions_need_review
    end
    data
  end

  def add_assessment_questions(assessment_questions, group=nil)
    questions = assessment_questions.map do |assessment_question|
      question = self.quiz_questions.build
      question.quiz_group_id = group.id if group && group.quiz_id == self.id
      question.write_attribute(:question_data, assessment_question.question_data)
      question.assessment_question = assessment_question
      question.assessment_question_version = assessment_question.version_number
      question.save
      question
    end
    questions.compact.uniq
  end

  def quiz_title
    result = self.title
    result = t('#quizzes.quiz.default_title', "Unnamed Quiz") if result == "undefined" || !result
    result = self.assignment.title if self.assignment
    result
  end

  alias_method :to_s, :quiz_title


  def locked_for?(user, opts={})
    return false if opts[:check_policies] && self.grants_right?(user, nil, :update)
    ::Rails.cache.fetch(locked_cache_key(user), :expires_in => 1.minute) do
      locked = false
      quiz_for_user = self.overridden_for(user)
      if (quiz_for_user.unlock_at && quiz_for_user.unlock_at > Time.now)
        sub = user && quiz_submissions.find_by_user_id(user.id)
        if !sub || !sub.manually_unlocked
          locked = {:asset_string => self.asset_string, :unlock_at => quiz_for_user.unlock_at}
        end
      elsif (quiz_for_user.lock_at && quiz_for_user.lock_at <= Time.now)
        sub = user && quiz_submissions.find_by_user_id(user.id)
        if !sub || !sub.manually_unlocked
          locked = {:asset_string => self.asset_string, :lock_at => quiz_for_user.lock_at}
        end
      elsif !opts[:skip_assignment] && (self.for_assignment? && l = self.assignment.locked_for?(user, opts))
        sub = user && quiz_submissions.find_by_user_id(user.id)
        if !sub || !sub.manually_unlocked
          locked = l
        end
      elsif item = locked_by_module_item?(user, opts[:deep_check_if_needed])
        sub = user && quiz_submissions.find_by_user_id(user.id)
        if !sub || !sub.manually_unlocked
          locked = {:asset_string => self.asset_string, :context_module => item.context_module.attributes}
        end
      end

    locked
    end
  end

  def clear_locked_cache(user)
    super
    Rails.cache.delete(assignment.locked_cache_key(user)) if self.for_assignment?
  end

  def context_module_action(user, action, points=nil)
    tags_to_update = self.context_module_tags.to_a
    if self.assignment
      tags_to_update += self.assignment.context_module_tags
    end
    tags_to_update.each { |tag| tag.context_module_action(user, action, points) }
  end

  # virtual attribute
  def locked=(new_val)
    new_val = ::ActiveRecord::ConnectionAdapters::Column.value_to_boolean(new_val)
    if new_val
      #lock the quiz either until unlock_at, or indefinitely if unlock_at.nil?
      self.lock_at = Time.now
      self.unlock_at = [self.lock_at, self.unlock_at].min if self.unlock_at
    else
      # unlock the quiz
      self.unlock_at = Time.now
    end
  end

  def locked?
    (self.unlock_at && self.unlock_at > Time.now) ||
      (self.lock_at && self.lock_at <= Time.now)
  end

  def hide_results=(val)
    if (val.is_a?(Hash))
      if val[:last_attempt] == '1'
        val = 'until_after_last_attempt'
      elsif val[:never] != '1'
        val = 'always'
      else
        val = nil
      end
    end
    write_attribute(:hide_results, val)
  end

  def check_if_submissions_need_review
    self.quiz_submissions.each { |s| s.update_if_needs_review(self) }
  end

  def changed_significantly_since?(version_number)
    @significant_version ||= {}
    return @significant_version[version_number] if @significant_version[version_number]
    old_version = self.versions.get(version_number).model

    needs_review = false
    needs_review = true if old_version.points_possible != self.points_possible
    needs_review = true if (old_version.quiz_data || []).length != (self.quiz_data || []).length
    if !needs_review
      new_data = self.quiz_data
      old_data = old_version.quiz_data
      new_data.each_with_index do |q, i|
        needs_review = true if (q[:id] || q['id']) != (old_data[i][:id] || old_data[i]['id'])
      end
    end
    @significant_version[version_number] = needs_review
  end

  def migrate_content_links_by_hand(user)
    self.quiz_questions.active.each do |question|
      data = Quizzes::QuizQuestion.migrate_question_hash(question.question_data, :context => self.context, :user => user)
      question.write_attribute(:question_data, data)
      question.save
    end
    data = self.quiz_data
    if data
      data.each_with_index do |obj, idx|
        if obj[:answers]
          data[idx] = Quizzes::QuizQuestion.migrate_question_hash(data[idx], :context => self.context, :user => user)
        elsif val.questions
          questions = []
          obj[:questions].each do |question|
            questions << Quizzes::QuizQuestion.migrate_question_hash(question, :context => self.context, :user => user)
          end
          obj[:questions] = questions
          data[idx] = obj
        end
      end
    end
    self.quiz_data = data
  end

  def validate_quiz_type
    return if self.quiz_type.blank?
    unless valid_quiz_type_values.include?(self.quiz_type)
      errors.add(:invalid_quiz_type, t('#quizzes.quiz.errors.invalid_quiz_type', "Quiz type is not valid"))
    end
  end

  def valid_quiz_type_values
    %w[practice_quiz assignment graded_survey survey]
  end

  def validate_ip_filter
    return if self.ip_filter.blank?
    require 'ipaddr'
    begin
      self.ip_filter.split(/,/).each { |filter| ::IPAddr.new(filter) }
    rescue
      errors.add(:invalid_ip_filter, t('#quizzes.quiz.errors.invalid_ip_filter', "IP filter is not valid"))
    end
  end

  def validate_hide_results
    return if self.hide_results.blank?
    unless valid_hide_results_values.include?(self.hide_results)
      errors.add(:invalid_hide_results, t('#quizzes.quiz.errors.invalid_hide_results', "Hide results is not valid"))
    end
  end

  def valid_hide_results_values
    %w[always until_after_last_attempt until_after_due_date until_after_available_date]
  end

  def validate_correct_answer_visibility
    show_at = self.show_correct_answers_at
    hide_at = self.hide_correct_answers_at

    if show_at.present? && hide_at.present? && hide_at <= show_at
      errors.add(:show_correct_answers, 'bad_range')
    end
  end

  def strip_html_answers(question)
    return if !question || !question[:answers] || !(%w(multiple_choice_question multiple_answers_question).include? question[:question_type])
    for answer in question[:answers] do
      answer[:text] = strip_tags(answer[:html]) if !answer[:html].blank? && answer[:text].blank?
    end
  end

  def statistics(include_all_versions = true)
    quiz_statistics.build(
      :report_type => 'student_analysis',
      :includes_all_versions => include_all_versions
    ).report.generate
  end

  # finds or creates a QuizStatistics for the given report_type and
  # options
  def current_statistics_for(report_type, options = {})
    # item analysis always takes the first attempt (not necessarily the
    # most recent), thus we say it always cares about all versions
    options[:includes_all_versions] = true if report_type == 'item_analysis'

    quiz_stats_opts = {
      :report_type => report_type,
      :includes_all_versions => options[:includes_all_versions],
      :anonymous => anonymous_submissions?
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

  def unpublished_changes?
    self.last_edited_at && self.published_at && self.last_edited_at > self.published_at
  end

  def has_student_submissions?
    self.quiz_submissions.not_settings_only.where("user_id IS NOT NULL").exists?
  end

  # clear out all questions so that the quiz can be replaced. this is currently
  # used by the respondus API.
  # returns false if the quiz can't be safely replaced, for instance if anybody
  # has taken the quiz.
  def clear_for_replacement
    return false if has_student_submissions?

    self.question_count = 0
    self.quiz_questions.active.map(&:destroy)
    self.quiz_groups.destroy_all
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
    given { |user, session| self.cached_context_grants_right?(user, session, :manage_assignments) } #admins.include? user }
    can :read_statistics and can :manage and can :read and can :update and can :delete and can :create and can :submit

    given { |user, session| self.cached_context_grants_right?(user, session, :manage_grades) } #admins.include? user }
    can :read_statistics and can :read and can :submit and can :grade

    given { |user| self.available? && self.context.try_rescue(:is_public) && !self.graded? }
    can :submit

    given do |user, session|
      (feature_enabled?(:draft_state) ? published? : true) &&
        cached_context_grants_right?(user, session, :read)
    end
    can :read

    given { |user, session| self.cached_context_grants_right?(user, session, :view_all_grades) }
    can :read_statistics and can :review_grades

    given do |user, session|
      available? &&
        cached_context_grants_right?(user, session, :participate_as_student)
    end
    can :read and can :submit
  end

  scope :include_assignment, includes(:assignment)
  scope :before, lambda { |date| where("quizzes.created_at<?", date) }
  scope :active, where("quizzes.workflow_state<>'deleted'")
  scope :not_for_assignment, where(:assignment_id => nil)
  scope :available, where("quizzes.workflow_state = 'available'")

  def teachers
    context.teacher_enrollments.map(&:user)
  end

  def migrate_file_links
    Quizzes::QuizQuestionLinkMigrator.migrate_file_links_in_quiz(self)
  end

  def self.batch_migrate_file_links(ids)
    Quizzes::Quiz.where(:id => ids).each do |quiz|
      if quiz.migrate_file_links
        quiz.save
      end
    end
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

  alias :require_lockdown_browser? :require_lockdown_browser

  def require_lockdown_browser_for_results
    self[:require_lockdown_browser_for_results] && Quizzes::Quiz.lockdown_browser_plugin_enabled?
  end

  alias :require_lockdown_browser_for_results? :require_lockdown_browser_for_results

  def require_lockdown_browser_monitor
    self[:require_lockdown_browser_monitor] && Quizzes::Quiz.lockdown_browser_plugin_enabled?
  end

  alias :require_lockdown_browser_monitor? :require_lockdown_browser_monitor

  def lockdown_browser_monitor_data
    self[:lockdown_browser_monitor_data]
  end

  def self.non_shuffled_questions
    ["true_false_question", "matching_question", "fill_in_multiple_blanks_question"]
  end

  def self.shuffleable_question_type?(question_type)
    !non_shuffled_questions.include?(question_type)
  end

  def access_code_key_for_user(user)
    # user might be nil (practice quiz in public course) and isn't really
    # necessary for this key anyway, but maintain backwards compat
    "quiz_#{id}_#{user.try(:id)}_entered_access_code"
  end

  def group_category_id
    assignment.try(:group_category_id)
  end

  def publish!
    publish
    save!
    self
  end

  def publish
    self.generate_quiz_data
    self.workflow_state = 'available'
    self.published_at = Time.zone.now
  end

  def unpublish!
    unpublish
    save!
    self
  end

  def unpublish
    self.workflow_state = 'unpublished'
  end

  def can_unpublish?
    !has_student_submissions? &&
      (!assignment || !assignment.has_student_submissions?)
  end

  alias_method :unpublishable?, :can_unpublish?
  alias_method :unpublishable, :can_unpublish?

  # marks a quiz as having unpublished changes
  def self.mark_quiz_edited(id)
    where(:id => id).update_all(:last_edited_at => Time.now.utc)
  end

  def mark_edited!
    self.class.mark_quiz_edited(self.id)
  end

  def anonymous_survey?
    survey? && anonymous_submissions
  end

  def has_file_upload_question?
    return false unless quiz_data.present?
    !!quiz_data.detect { |data_hash| data_hash[:question_type] == 'file_upload_question' }
  end

  def draft_state
    state = self.workflow_state
    (state == 'available') ? 'active' : state
  end

  def active?
    draft_state == 'active'
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
        version_number: self.version_number
      }
      if current_quiz_question_regrades.present?
        Quizzes::QuizRegrader::Regrader.send_later(:regrade!, options)
      end
    end
    true
  end

  def current_regrade
    Quizzes::QuizRegrade.where(quiz_id: id, quiz_version: version_number).
      where("quiz_question_regrades.regrade_option != 'disabled'").
      includes(:quiz_question_regrades => :quiz_question).first
  end

  def current_quiz_question_regrades
    current_regrade ? current_regrade.quiz_question_regrades : []
  end

  def questions_regraded_since(created_at)
    question_regrades = Set.new
    quiz_regrades.where("quiz_regrades.created_at > ? AND quiz_question_regrades.regrade_option != 'disabled'", created_at)
                 .includes(:quiz_question_regrades).each do |regrade|
      ids = regrade.quiz_question_regrades.map { |qqr| qqr.quiz_question_id }
      question_regrades.merge(ids)
    end
    question_regrades.count
  end

  # override for draft state
  def available?
    feature_enabled?(:draft_state) ? published? : workflow_state == 'available'
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
    accounts = self.context.account.account_chain.uniq

    if self.ip_filter.present?
      filters << {
        name: t('#quizzes.quiz.current_filter', 'Current Filter'),
        account: self.title,
        filter: self.ip_filter
      }
    end

    accounts.each do |account|
      account_filters = account.settings[:ip_filters] || {}
      account_filters.sort_by(&:first).each do |key, filter|
        filters << {
          name: key,
          account: account.name,
          filter: filter
        }
      end
    end

    filters
  end

  def self.class_names
    %w(Quiz Quizzes::Quiz)
  end

  def self.reflection_type_name
    'quizzes:quiz'
  end

end
