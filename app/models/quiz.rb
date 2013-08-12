#
# Copyright (C) 2011 - 2012 Instructure, Inc.
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

require 'quiz_question_link_migrator'

class Quiz < ActiveRecord::Base
  include Workflow
  include HasContentTags
  include CopyAuthorizedLinks
  include ActionView::Helpers::SanitizeHelper
  extend ActionView::Helpers::SanitizeHelper::ClassMethods
  include ContextModuleItem
  include DatesOverridable
  include SearchTermHelper

  attr_accessible :title, :description, :points_possible, :assignment_id, :shuffle_answers,
    :show_correct_answers, :time_limit, :allowed_attempts, :scoring_policy, :quiz_type,
    :lock_at, :unlock_at, :due_at, :access_code, :anonymous_submissions, :assignment_group_id,
    :hide_results, :locked, :ip_filter, :require_lockdown_browser,
    :require_lockdown_browser_for_results, :context, :notify_of_update,
    :one_question_at_a_time, :cant_go_back

  attr_readonly :context_id, :context_type
  attr_accessor :notify_of_update

  has_many :quiz_questions, :dependent => :destroy, :order => 'position'
  has_many :quiz_submissions, :dependent => :destroy
  has_many :quiz_groups, :dependent => :destroy, :order => 'position'
  has_many :quiz_statistics, :class_name => 'QuizStatistics', :order => 'created_at'
  has_many :attachments, :as => :context, :dependent => :destroy
  belongs_to :context, :polymorphic => true
  belongs_to :assignment
  belongs_to :cloned_item
  belongs_to :assignment_group
  validates_length_of :description, :maximum => maximum_long_text_length, :allow_nil => true, :allow_blank => true
  validates_length_of :title, :maximum => maximum_string_length, :allow_nil => true
  validates_presence_of :context_id
  validates_presence_of :context_type
  validate :validate_quiz_type, :if => :quiz_type_changed?
  validate :validate_ip_filter, :if => :ip_filter_changed?
  validate :validate_hide_results, :if => :hide_results_changed?
  validate :validate_draft_state_change, :if => :workflow_state_changed?

  sanitize_field :description, Instructure::SanitizeField::SANITIZE
  copy_authorized_links(:description) { [self.context, nil] }
  before_save :build_assignment
  before_save :set_defaults
  after_save :update_assignment
  after_save :touch_context

  serialize :quiz_data

  simply_versioned
  # This callback is listed here in order for the :link_assignment_overrides
  # method to be called after the simply_versioned callbacks. We want the
  # overrides to reflect the most recent version of the quiz.
  # If we placed this before simply_versioned, the :link_assignment_overrides
  # method would fire first, meaning that the overrides would reflect the
  # last version of the assignment, because the next callback would be a
  # simply_versioned callback updating the version.
  after_save :link_assignment_overrides, :if => :assignment_id_changed?

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
    self.allowed_attempts = 1 if self.allowed_attempts == nil
    self.scoring_policy = "keep_highest" if self.scoring_policy == nil
    self.due_at ||= self.lock_at if self.lock_at.present?
    self.ip_filter = nil if self.ip_filter && self.ip_filter.strip.empty?
    if !self.available? && !self.survey?
      self.points_possible = self.current_points_possible
    end
    self.title = t(:default_title, "Unnamed Quiz") if self.title.blank?
    self.quiz_type ||= "assignment"
    self.last_assignment_id = self.assignment_id_was if self.assignment_id_was
    if (!graded? && self.assignment_id) || (self.assignment_id_was && self.assignment_id != self.assignment_id_was)
      @old_assignment_id = self.assignment_id_was
      self.assignment_id = nil
    end
    self.assignment_group_id ||= self.assignment.assignment_group_id if self.assignment
    self.question_count = self.question_count(true)
    @update_existing_submissions = true if self.for_assignment? && self.quiz_type_changed?
    @stored_questions = nil
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
    if self.available? && !self.assignment_id && self.graded? && @saved_by != :assignment && @saved_by != :clone
      assignment = self.assignment
      assignment ||= self.context.assignments.build(:title => self.title, :due_at => self.due_at, :submission_types => 'online_quiz')
      assignment.assignment_group_id = self.assignment_group_id
      assignment.saved_by = :quiz
      assignment.save
      self.assignment_id = assignment.id
    end
  end
  
  def readable_type
    self.survey? ? t('types.survey', "Survey") : t('types.quiz', "Quiz")
  end
  
  def valid_ip?(ip)
    require 'ipaddr'
    ip_filter.split(/,/).any? do |filter|
      addr_range = IPAddr.new(filter) rescue nil
      addr = IPAddr.new(ip) rescue nil
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
    Quiz.where(:id => self).update_all(:unpublished_question_count => cnt)
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
    # self.deleted_at = Time.now
    res = self.save
    if self.for_assignment?
      self.assignment.destroy unless self.assignment.deleted?
    end
    res
  end
  
  def restore
    self.workflow_state = 'edited'
    self.save
    self.assignment.restore(:quiz)
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

  # Determine if the quiz should display the correct answers.
  # Takes into account the quiz settings, the user viewing and
  # the submission to be viewed.
  def display_correct_answers?(user, submission)
    # NOTE: We don't have a submission user when the teacher is previewing the quiz and displaying the results'
    self.show_correct_answers || (self.grants_right?(user, nil, :grade) && (submission && submission.user && submission.user != user))
  end

  def update_existing_submissions
    # If the quiz suddenly changes from non-graded to graded,
    # then this will update the existing submissions to reflect quiz
    # scores in the gradebook.
    self.quiz_submissions.each{|s| s.touch }
  end
  
  attr_accessor :saved_by
  def update_assignment
    send_later_if_production(:set_unpublished_question_count) if self.id
    if !self.assignment_id && @old_assignment_id
      self.context_module_tags.each { |tag| tag.confirm_valid_module_requirements }
    end
    if !self.graded? && (@old_assignment_id || self.last_assignment_id)
      Assignment.where(:id => [@old_assignment_id, self.last_assignment_id].compact, :submission_types => 'online_quiz').update_all(:workflow_state => 'deleted', :updated_at => Time.now.utc)
      self.quiz_submissions.each do |qs|
        submission = qs.submission
        qs.submission = nil
        qs.save! if qs.changed?
        submission.try(:destroy)
      end
      ContentTag.delete_for(Assignment.find(@old_assignment_id)) if @old_assignment_id
      ContentTag.delete_for(Assignment.find(self.last_assignment_id)) if self.last_assignment_id
    end
    send_later_if_production(:update_existing_submissions) if @update_existing_submissions
    if self.assignment && (@assignment_id_set || self.for_assignment?) && @saved_by != :assignment
      if !self.graded? && @old_assignment_id
      else
        Quiz.where("assignment_id=? AND id<>?", self.assignment_id, self).update_all(:workflow_state => 'deleted', :assignment_id => nil, :updated_at => Time.now.utc) if self.assignment_id
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
        a.notify_of_update = @notify_of_update
        a.with_versioning(false) do
          @notify_of_update ? a.save : a.save_without_broadcasting!
        end
        self.assignment_id = a.id
        Quiz.where(:id => self).update_all(:assignment_id => a)
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

    QuizSubmission.where(where_clause, self, new_end_at).update_all(["end_at = #{update_sql}", new_end_at])
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
    question_max = self.quiz_questions.maximum(:position, :conditions => 'quiz_group_id is null')
    group_max = self.quiz_groups.maximum(:position)
    [question_max, group_max, 0].compact.max
  end

  # Returns the list of all "root" entries, either questions or question
  # groups for this quiz.  This is PRE-SAVED data.  Once the quiz has 
  # been saved, all the data can be found in Quiz.quiz_data
  def root_entries(force_check=false)
    return @root_entries if @root_entries && !force_check
    result = []
    all_questions = self.quiz_questions
    result.concat all_questions.select{|q| !q.quiz_group_id }
    result.concat self.quiz_groups
    result = result.sort_by{|e| e.position || 99999}.map do |e|
      res = nil
      if e.is_a? QuizQuestion
        res = e.data
      else #it's a QuizGroup
        data = e.attributes.with_indifferent_access
        data[:entry_type] = "quiz_group"
        if e.assessment_question_bank_id
          data[:assessment_question_bank_id] = e.assessment_question_bank_id
          data[:questions] = []
        else
          data[:questions] = e.quiz_questions.sort_by{|q| q.position || 99999}.map(&:data)
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
  
  # Returns data for the SAVED version of the quiz.  That is, not
  # the version found by gathering relationships on the Quiz data models,
  # but the version being held in Quiz.quiz_data.  Caches the result
  # in @stored_questions.
  def stored_questions(hashes=nil)
    res = []
    return @stored_questions if @stored_questions && !hashes
    questions = hashes || self.quiz_data || []
    questions.each do |val|
      
      if val[:answers]
        val[:answers] = prepare_answers(val)
        val[:matches] = val[:matches].sort_by{|m| m[:text] || "" } if val[:matches]
      elsif val[:questions] # It's a QuizGroup
        if val[:assessment_question_bank_id]
          # It points to a question bank
          # question/answer/match shuffling happens when a submission is generated
        else #normal QuizGroup
          questions = []
          val[:questions].each do |question|
            if question[:answers]
              question[:answers] = prepare_answers(question)
              question[:matches] = question[:matches].sort_by{|m| m[:text] || ""} if question[:matches]
            end
            questions << question
          end
          questions = questions.sort_by{|q| rand}
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
    q[:name] = t :question_name_counter, "Question %{question_number}", :question_number => @idx
    if q[:question_type] == 'text_only_question'
      q[:name] = t :default_text_only_question_name, "Spacer"
      @idx -= 1
    elsif q[:question_type] == 'fill_in_multiple_blanks_question'
      text = q[:question_text]
      variables = q[:answers].map{|a| a[:blank_id] }.uniq
      variables.each do |variable|
        variable_id = AssessmentQuestion.variable_id(variable)
        re = Regexp.new("\\[#{variable}\\]")
        text = text.sub(re, "<input class='question_input' type='text' autocomplete='off' style='width: 120px;' name='question_#{q[:id]}_#{variable_id}' value='{{question_#{q[:id]}_#{variable_id}}}' />")
      end
      q[:original_question_text] = q[:question_text]
      q[:question_text] = text
    elsif q[:question_type] == 'multiple_dropdowns_question'
      text = q[:question_text]
      variables = q[:answers].map{|a| a[:blank_id] }.uniq
      variables.each do |variable|
        variable_id = AssessmentQuestion.variable_id(variable)
        variable_answers = q[:answers].select{|a| a[:blank_id] == variable }
        options = variable_answers.map{|a| "<option value='#{a[:id]}'>#{CGI::escapeHTML(a[:text])}</option>" }
        select = "<select class='question_input' name='question_#{q[:id]}_#{variable_id}'><option value=''>#{t(:default_question_input, "[ Select ]")}</option>#{options}</select>"
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
      q[:answers] = [q[:answers].sort_by{|a| rand }.first].compact
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
  
  def find_or_create_submission(user, temporary=false, state=nil)
    s = nil
    state ||= 'untaken'
    if temporary || !user.is_a?(User)
      user_code = "#{user.to_s}"
      user_code = "user_#{user.id}" if user.is_a?(User)
      s = QuizSubmission.find_by_quiz_id_and_temporary_user_code(self.id, user_code)
      s ||= QuizSubmission.new(:quiz => self, :temporary_user_code => user_code)
      s.workflow_state ||= state
      s.save!
    else
      s = QuizSubmission.find_by_quiz_id_and_user_id(self.id, user.id)
      s ||= QuizSubmission.new(:quiz => self, :user => user)
      s.workflow_state ||= state
      s.save!
    end
    s
  end
  
  # Generates a submission for the specified user on this quiz, based
  # on the SAVED version of the quiz.  Does not consider permissions.
  def generate_submission(user, preview=false)
    submission = nil
    submission = self.find_or_create_submission(user, preview)
    submission.retake
    submission.attempt = (submission.attempt + 1) rescue 1
    user_questions = []
    @idx = 1
    @stored_questions = nil
    @submission_questions = self.stored_questions
    if preview
      @submission_questions = self.stored_questions(generate_quiz_data(:persist => false))
    end
    
    exclude_ids = @submission_questions.map{ |q| q[:assessment_question_id] }.compact
    @submission_questions.each do |q|
      if q[:pick_count] #QuizGroup
        if q[:assessment_question_bank_id]
          bank = AssessmentQuestionBank.find_by_id(q[:assessment_question_bank_id]) if q[:assessment_question_bank_id].present?
          if bank
            questions = bank.select_for_submission(q[:pick_count], exclude_ids)
            questions = questions.map{|aq| aq.data}
            questions.each do |question|
              if question[:answers]
                question[:answers] = prepare_answers(question)
                question[:matches] = question[:matches].sort_by{|m| m[:text] || ""} if question[:matches]
              end
              question[:points_possible] = q[:question_points]
              question[:published_at] = q[:published_at]
              user_questions << generate_submission_question(question)
            end
          end
        else
          q[:pick_count].times do |i|
            if q[:questions][i]
              question = q[:questions][i]
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
    submission.started_at = Time.now
    submission.end_at = nil
    submission.end_at = submission.started_at + (self.time_limit.to_f * 60.0) if self.time_limit
    # Admins can take the full quiz whenever they want
    unless user.is_a?(User) && self.grants_right?(user, nil, :grade)
      submission.end_at = due_at if due_at && Time.now < due_at && (!submission.end_at || due_at < submission.end_at)
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
    submission
  end

  def prepare_answers(question)
    if answers = question[:answers]
      if shuffle_answers && Quiz.shuffleable_question_type?(question[:question_type])
        answers.sort_by { |a| rand }
      else
        answers
      end
    end
  end
  
  # Takes the PRE-SAVED version of the quiz and uses it to generate a 
  # SAVED version.  That is, gathers the relationship entities from
  # the database and uses them to populate a static version that will
  # be held in Quiz.quiz_data
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
    result = t(:default_title, "Unnamed Quiz") if result == "undefined" || !result
    result = self.assignment.title if self.assignment
    result
  end
  alias_method :to_s, :quiz_title
  
  def locked_for?(user, opts={})
    return false if opts[:check_policies] && self.grants_right?(user, nil, :update)
    Rails.cache.fetch(locked_cache_key(user), :expires_in => 1.minute) do
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
      elsif (self.for_assignment? && l = self.assignment.locked_for?(user, opts))
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
  
  def context_module_action(user, action, points=nil)
    tags_to_update = self.context_module_tags.to_a
    if self.assignment
      tags_to_update += self.assignment.context_module_tags
    end
    tags_to_update.each { |tag| tag.context_module_action(user, action, points) }
  end

  # virtual attribute
  def locked=(new_val)
    new_val = ActiveRecord::ConnectionAdapters::Column.value_to_boolean(new_val)
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
    if(val.is_a?(Hash))
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
    self.quiz_submissions.each{|s| s.update_if_needs_review(self) }
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
    self.quiz_questions.each do |question|
      data = QuizQuestion.migrate_question_hash(question.question_data, :context => self.context, :user => user)
      question.write_attribute(:question_data, data)
      question.save
    end
    data = self.quiz_data
    if data
      data.each_with_index do |obj, idx|
        if obj[:answers]
          data[idx] = QuizQuestion.migrate_question_hash(data[idx], :context => self.context, :user => user)
        elsif val.questions
          questions = []
          obj[:questions].each do |question|
            questions << QuizQuestion.migrate_question_hash(question, :context => self.context, :user => user)
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
      errors.add(:invalid_quiz_type, t('errors.invalid_quiz_type', "Quiz type is not valid" ))
    end
  end

  def valid_quiz_type_values
    %w[practice_quiz assignment graded_survey survey]
  end

  def validate_ip_filter
    return if self.ip_filter.blank?
    require 'ipaddr'
    begin
      self.ip_filter.split(/,/).each { |filter| IPAddr.new(filter) }
    rescue
      errors.add(:invalid_ip_filter, t('errors.invalid_ip_filter', "IP filter is not valid"))
    end
  end

  def validate_hide_results
    return if self.hide_results.blank?
    unless valid_hide_results_values.include?(self.hide_results)
      errors.add(:invalid_hide_results, t('errors.invalid_hide_results', "Hide results is not valid" ))
    end
  end

  def valid_hide_results_values
    %w[always until_after_last_attempt]
  end
  
  attr_accessor :clone_updated
  def clone_for(context, original_dup=nil, options={}, retrying = false)
    dup = original_dup
    if !self.cloned_item && !self.new_record?
      self.cloned_item ||= ClonedItem.create(:original_item => self)
      self.save!
    end
    existing = context.quizzes.active.find_by_id(self.id)
    existing ||= context.quizzes.active.find_by_cloned_item_id(self.cloned_item_id || 0)
    return existing if existing && !options[:overwrite]
    if (context.merge_mapped_id(self.assignment))
      dup ||= Quiz.find_by_assignment_id(context.merge_mapped_id(self.assignment))
    end
    dup ||= Quiz.new
    dup = existing if existing && options[:overwrite]
    self.attributes.delete_if{|k,v| [:id, :assignment_id, :assignment_group_id].include?(k.to_sym) }.each do |key, val|
      dup.send("#{key}=", val)
    end
    # We need to save the quiz now so that the migrate_question_hash call will find
    # the duplicated quiz and not try to make it itself.
    dup.context = context
    dup.saved_by = :clone
    dup.save!
    data = self.quiz_data
    if data
      data.each_with_index do |obj, idx|
        if obj[:answers]
          data[idx] = QuizQuestion.migrate_question_hash(data[idx], :old_context => self.context, :new_context => context)
        elsif obj[:questions]
          questions = []
          obj[:questions].each do |question|
            questions << QuizQuestion.migrate_question_hash(question, :old_context => self.context, :new_context => context)
          end
          obj[:questions] = questions
          data[idx] = obj
        end
      end
    end
    dup.quiz_data = data
    dup.assignment_id = context.merge_mapped_id(self.assignment) rescue nil
    if !dup.assignment_id && self.assignment_id && self.assignment && !options[:cloning_for_assignment]
      new_assignment = self.assignment.clone_for(context, nil, :cloning_for_quiz => true)
      new_assignment.saved_by = :quiz
      new_assignment.save_without_broadcasting!
      context.map_merge(self.assignment, new_assignment)
      dup.assignment_id = new_assignment.id
    end
    begin
      dup.saved_by = :assignment if options[:cloning_for_assignment]
      dup.save!
    rescue => e
      logger.warn "Couldn't save quiz copy: #{e.to_s}"
      raise e if retrying
      return self.clone_for(context, original_dup, options, true)
    end
    entities = self.quiz_groups + self.quiz_questions
    entities.each do |entity|
      entity_dup = entity.clone_for(dup, nil, :old_context => self.context, :new_context => context)
      entity_dup.quiz_id = dup.id
      if entity_dup.respond_to?(:quiz_group_id=)
        entity_dup.quiz_group_id = context.merge_mapped_id(entity.quiz_group)
      end
      entity_dup.save!
      context.map_merge(entity, entity_dup)
    end
    dup.reload
    context.log_merge_result("Quiz \"#{self.title}\" created")
    context.may_have_links_to_migrate(dup)
    dup.updated_at = Time.now
    dup.clone_updated = true
    dup
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

  # finds or initializes a QuizStatistics for the given report_type and
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
      quiz_submissions.completed.order(:updated_at).pluck(:updated_at).last
    ].compact.max

    candidate_stats = quiz_statistics.report_type(report_type).where(quiz_stats_opts).last

    if candidate_stats.nil? || candidate_stats.created_at < last_quiz_activity
      quiz_statistics.build(quiz_stats_opts)
    else
      candidate_stats
    end
  end

  # returns the QuizStatistics object that will ultimately contain the csv
  # (it may be generating in the background)
  def statistics_csv(report_type, options = {})
    stats = current_statistics_for(report_type, options)
    return stats unless stats.new_record?
    stats.save!
    options[:async] ? stats.generate_csv_in_background : stats.generate_csv
    stats
  end

  def unpublished_changes?
    self.last_edited_at && self.published_at && self.last_edited_at > self.published_at
  end

  def has_student_submissions?
    self.quiz_submissions.any?{|s| !s.settings_only? && context.includes_student?(s.user) }
  end

  # clear out all questions so that the quiz can be replaced. this is currently
  # used by the respondus API.
  # returns false if the quiz can't be safely replaced, for instance if anybody
  # has taken the quiz.
  def clear_for_replacement
    return false if has_student_submissions?

    self.question_count = 0
    self.quiz_questions.destroy_all
    self.quiz_groups.destroy_all
    self.quiz_data = nil
    true
  end

  def self.process_migration(data, migration, question_data)
    assessments = data['assessments'] ? data['assessments']['assessments'] : []
    assessments ||= []
    assessments.each do |assessment|
      migration_id = assessment['migration_id'] || assessment['assessment_id']
      if migration.import_object?("quizzes", migration_id)
        allow_update = false
        # allow update if we find an existing item based on this migration setting
        if item_id = migration.migration_settings[:quiz_id_to_update]
          allow_update = true
          assessment[:id] = item_id.to_i
          if assessment[:assignment]
            assessment[:assignment][:id] = Quiz.find(item_id.to_i).try(:assignment_id)
          end
        end
        if assessment['assignment_migration_id']
          if assignment = data['assignments'].find{|a| a['migration_id'] == assessment['assignment_migration_id']}
            assignment['quiz_migration_id'] = migration_id
          end
        end
        begin
          assessment[:migration] = migration
          Quiz.import_from_migration(assessment, migration.context, question_data, nil, allow_update)
        rescue
          migration.add_import_warning(t('#migration.quiz_type', "Quiz"), assessment[:title], $!)
        end
      end
    end
  end

  # Import a quiz from a hash.
  # It assumes that all the referenced questions are already in the database
  def self.import_from_migration(hash, context, question_data, item=nil, allow_update = false)
    hash = hash.with_indifferent_access
    # there might not be an import id if it's just a text-only type...
    item ||= find_by_context_type_and_context_id_and_id(context.class.to_s, context.id, hash[:id]) if hash[:id]
    item ||= find_by_context_type_and_context_id_and_migration_id(context.class.to_s, context.id, hash[:migration_id]) if hash[:migration_id]
    if item && !allow_update
      if item.deleted?
        item.workflow_state = hash[:available] ? 'available' : 'created'
        item.save
      end
    end
    item ||= context.quizzes.new

    hash[:due_at] ||= hash[:due_date]
    hash[:due_at] ||= hash[:grading][:due_date] if hash[:grading]
    item.lock_at = Canvas::Migration::MigratorHelper.get_utc_time_from_timestamp(hash[:lock_at]) if hash[:lock_at]
    item.unlock_at = Canvas::Migration::MigratorHelper.get_utc_time_from_timestamp(hash[:unlock_at]) if hash[:unlock_at]
    item.due_at = Canvas::Migration::MigratorHelper.get_utc_time_from_timestamp(hash[:due_at]) if hash[:due_at]
    item.scoring_policy = hash[:which_attempt_to_keep] if hash[:which_attempt_to_keep]
    hash[:missing_links] = []
    item.description = ImportedHtmlConverter.convert(hash[:description], context, {:missing_links => hash[:missing_links]})
    [:migration_id, :title, :allowed_attempts, :time_limit,
     :shuffle_answers, :show_correct_answers, :points_possible, :hide_results,
     :access_code, :ip_filter, :scoring_policy, :require_lockdown_browser,
     :require_lockdown_browser_for_results, :anonymous_submissions, 
     :could_be_locked, :quiz_type, :one_question_at_a_time,
     :cant_go_back].each do |attr|
      item.send("#{attr}=", hash[attr]) if hash.key?(attr)
    end

    item.save!

    if context.respond_to?(:content_migration) && context.content_migration
      context.content_migration.add_missing_content_links(:class => item.class.to_s,
        :id => item.id, :missing_links => hash[:missing_links],
        :url => "/#{context.class.to_s.underscore.pluralize}/#{context.id}/#{item.class.to_s.underscore.pluralize}/#{item.id}")
    end

    if question_data
      hash[:questions] ||= []

      if question_data[:qq_data]
        questions_to_update = item.quiz_questions.where(:migration_id => question_data[:qq_data].keys)
        questions_to_update.each do |question_to_update|
          question_data[:qq_data].values.find{|q| q['migration_id'].eql?(question_to_update.migration_id)}['quiz_question_id'] = question_to_update.id
        end
      end

      if question_data[:aq_data]
        questions_to_update = item.quiz_questions.where(:migration_id => question_data[:aq_data].keys)
        questions_to_update.each do |question_to_update|
          question_data[:aq_data].values.find{|q| q['migration_id'].eql?(question_to_update.migration_id)}['quiz_question_id'] = question_to_update.id
        end
      end

      hash[:questions].each_with_index do |question, i|
        case question[:question_type]
          when "question_reference"
            if qq = question_data[:qq_data][question[:migration_id]]
              qq[:position] = i + 1
              if qq[:assessment_question_migration_id]
                if aq = question_data[:aq_data][qq[:assessment_question_migration_id]]
                  qq['assessment_question_id'] = aq['assessment_question_id']
                  aq_hash = AssessmentQuestion.prep_for_import(qq, context)
                  QuizQuestion.import_from_migration(aq_hash, context, item)
                else
                  aq_hash = AssessmentQuestion.import_from_migration(qq, context)
                  QuizQuestion.import_from_migration(aq_hash, context, item)
                end
              end
            elsif aq = question_data[:aq_data][question[:migration_id]]
              aq[:position] = i + 1
              aq[:points_possible] = question[:points_possible] if question[:points_possible]
              QuizQuestion.import_from_migration(aq, context, item)
            end
          when "question_group"
            QuizGroup.import_from_migration(question, context, item, question_data, i + 1, hash[:migration])
          when "text_only_question"
            qq = item.quiz_questions.new
            qq.question_data = question
            qq.position = i + 1
            qq.save!
        end
      end
    end
    item.reload # reload to catch question additions
    
    if hash[:assignment] && hash[:available]
      item.assignment = Assignment.import_from_migration(hash[:assignment], context, item.assignment)
    elsif !item.assignment && grading = hash[:grading]
      # The actual assignment will be created when the quiz is published
      item.quiz_type = 'assignment'
      hash[:assignment_group_migration_id] ||= grading[:assignment_group_migration_id]
    end

    if hash[:available]
      item.generate_quiz_data
      item.workflow_state = 'available'
      item.published_at = Time.now
    end
    
    if hash[:assignment_group_migration_id]
      if g = context.assignment_groups.find_by_migration_id(hash[:assignment_group_migration_id])
        item.assignment_group_id = g.id
      end
    end

    item.save

    context.imported_migration_items << item if context.imported_migration_items
    item
  end
  
  def self.serialization_excludes; [:access_code]; end

  set_policy do
    given { |user, session| self.cached_context_grants_right?(user, session, :manage_assignments) }#admins.include? user }
    can :read_statistics and can :manage and can :read and can :update and can :delete and can :create and can :submit
    
    given { |user, session| self.cached_context_grants_right?(user, session, :manage_grades) }#admins.include? user }
    can :read_statistics and can :manage and can :read and can :update and can :delete and can :create and can :submit and can :grade
    
    given { |user| self.available? && self.context.try_rescue(:is_public) && !self.graded? }
    can :submit
    
    given { |user, session| self.cached_context_grants_right?(user, session, :read) }#students.include?(user) }
    can :read

    given { |user, session| self.cached_context_grants_right?(user, session, :view_all_grades) }
    can :read_statistics and can :review_grades

    given { |user, session| self.available? && self.cached_context_grants_right?(user, session, :participate_as_student) }#students.include?(user) }
    can :read and can :submit
  end
  scope :include_assignment, includes(:assignment)
  scope :before, lambda { |date| where("quizzes.created_at<?", date) }
  scope :active, where("quizzes.workflow_state<>'deleted'")
  scope :not_for_assignment, where(:assignment_id => nil)

  def migrate_file_links
    QuizQuestionLinkMigrator.migrate_file_links_in_quiz(self)
  end

  def self.batch_migrate_file_links(ids)
    Quiz.where(:id => ids).each do |quiz|
      if quiz.migrate_file_links
        quiz.save
      end
    end
  end

  def self.lockdown_browser_plugin_enabled?
    Canvas::Plugin.all_for_tag(:lockdown_browser).any? { |p| p.settings[:enabled] }
  end

  def require_lockdown_browser
    self[:require_lockdown_browser] && Quiz.lockdown_browser_plugin_enabled?
  end
  alias :require_lockdown_browser? :require_lockdown_browser

  def require_lockdown_browser_for_results
    self[:require_lockdown_browser_for_results] && Quiz.lockdown_browser_plugin_enabled?
  end
  alias :require_lockdown_browser_for_results? :require_lockdown_browser_for_results

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
    self.generate_quiz_data
    self.workflow_state = 'available'
    self.published_at = Time.zone.now
    save!
    self
  end

  def unpublish!
    self.workflow_state = 'unpublished'
    save!
    self
  end

  def can_unpublish?
    !has_student_submissions?
  end

  # marks a quiz as having unpublished changes
  def self.mark_quiz_edited(id)
    where(:id =>id).update_all(:last_edited_at => Time.now.utc)
  end

  def anonymous_survey?
    survey? && anonymous_submissions
  end

  def has_file_upload_question?
    return false unless quiz_data.present?
    !!quiz_data.detect do |data_hash|
      data_hash[:question_type] == 'file_upload_question'
    end
  end
  def draft_state
    state = self.workflow_state
    (state == 'available') ? 'active' : state
  end

  def active?
    draft_state == 'active'
  end
  alias_method :published?, :active?

  def unpublished?; !published?; end

  def validate_draft_state_change
    old_draft_state, new_draft_state = self.changes['workflow_state']
    return if old_draft_state == new_draft_state
    if new_draft_state == 'unpublished' && has_student_submissions?
      self.errors.add :workflow_state, I18n.t('#quizzes.cant_unpublish_when_students_submit',
                                              "Can't unpublish if there are student submissions")
    end
  end

end
