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

class QuizSubmission < ActiveRecord::Base
  include Workflow
  attr_accessible :quiz, :user, :temporary_user_code, :submission_data
  attr_readonly :quiz_id, :user_id
  validates_presence_of :quiz_id
  
  belongs_to :quiz
  belongs_to :user
  belongs_to :submission, :touch => true
  before_save :update_kept_score
  before_save :sanitize_responses
  before_save :update_assignment_submission

  # update the QuizSubmission's Submission to 'graded' when the QuizSubmission is marked as 'complete.' this
  # ensures that quiz submissions with essay questions don't show as graded in the SpeedGrader until the instructor
  # has graded the essays.
  trigger.after(:update).where("NEW.submission_id IS NOT NULL AND OLD.workflow_state <> NEW.workflow_state AND NEW.workflow_state = 'complete'") do
    "UPDATE submissions SET workflow_state = 'graded' WHERE id = NEW.submission_id"
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
    given {|user| user && user.id == self.user_id }
    can :read
    
    given {|user| user && user.id == self.user_id && self.untaken? }
    can :update
    
    given {|user, session| self.quiz.grants_right?(user, session, :manage) || self.quiz.grants_right?(user, session, :review_grades) }
    can :read
    
    given {|user, session| self.quiz.grants_right?(user, session, :manage) }
    can :update_scores
    
    given {|user, session| self.quiz.grants_right?(user, session, :manage) }
    can :add_attempts
  end
  
  def sanitize_responses
    questions && questions.select {|q| q['question_type'] == 'essay_question' }.each do |q|
      question_id = q['id']
      if submission_data.is_a?(Array)
        if submission = submission_data.find {|s| s[:question_id] == question_id }
          submission[:text] = Sanitize.clean(submission[:text] || "", Instructure::SanitizeField::SANITIZE)
        end
      elsif submission_data.is_a?(Hash)
        question_key = "question_#{question_id}"
        if submission_data[question_key]
          submission_data[question_key] = Sanitize.clean(submission_data[question_key] || "", Instructure::SanitizeField::SANITIZE)
        end
      end
    end
    true
  end
  
  def track_outcomes(attempt)
    return unless user_id
    question_ids = (self.quiz_data || []).map{|q| q[:assessment_question_id] }.compact.uniq
    questions = question_ids.empty? ? [] : AssessmentQuestion.find_all_by_id(question_ids).compact
    bank_ids = questions.map(&:assessment_question_bank_id).uniq
    tagged_bank_ids = (bank_ids.empty? ? [] : ContentTag.outcome_tags_for_banks(bank_ids).scoped(:select => 'content_id')).map(&:content_id).uniq
    if !tagged_bank_ids.empty?
      question_ids = questions.select{|q| tagged_bank_ids.include?(q.assessment_question_bank_id) }
      send_later_if_production(:update_outcomes_for_assessment_questions, question_ids, self.id, attempt) unless question_ids.empty?
    end
  end
  
  def update_outcomes_for_assessment_questions(question_ids, submission_id, attempt)
    return if question_ids.empty?
    submission = QuizSubmission.find(submission_id)
    versioned_submission = submission.attempt == attempt ? submission : submission.versions.sort_by(&:created_at).map(&:model).reverse.detect{|s| s.attempt == attempt }
    questions = AssessmentQuestion.find_all_by_id(question_ids).compact
    bank_ids = questions.map(&:assessment_question_bank_id).uniq
    return if bank_ids.empty?
    tags = ContentTag.outcome_tags_for_banks(bank_ids)
    questions.each do |question|
      question_tags = tags.select{|t| t.content_id == question.assessment_question_bank_id }
      question_tags.each do |tag|
        tag.create_outcome_result(self.user, self.quiz, versioned_submission, {:assessment_question => question})
      end
    end
  end
  
  def temporary_data
    raise "Cannot view temporary data for completed quiz" unless !self.completed?
    raise "Cannot view temporary data for completed quiz" if self.submission_data && !self.submission_data.is_a?(Hash)
    res = (self.submission_data || {}).with_indifferent_access
    res
  end
  
  def data
    raise "Cannot view data for uncompleted quiz" unless self.completed?
    raise "Cannot view data for uncompleted quiz" if self.submission_data && !self.submission_data.is_a?(Array)
    res = self.submission_data || []
    res
  end
  
  def results_visible?
    return true unless quiz
    if quiz.hide_results == 'always'
      false
    elsif quiz.hide_results == 'until_after_last_attempt'
      # Visible if quiz has unlimited attempts (no way to get to last
      # attempts), if this attempt it higher than the allowed attempts
      # (once you get into extra attempts), or if this attempt is
      # the last attempt and has been taken (checking for completion
      # prevents the student from starting to take the quiz for the last 
      # time, then opening a new tab and looking at the results from 
      # a prior attempt)
      !quiz.allowed_attempts || quiz.allowed_attempts < 1 || attempt > quiz.allowed_attempts || (completed? && attempt == quiz.allowed_attempts)
    else
      true
    end
  end
  
  def needs_grading?(strict=false)
    if strict && self.untaken? && self.overdue?(true)
      true
    elsif self.untaken? && self.end_at && self.end_at < Time.now && !self.extendable?
      true
    elsif self.completed? && self.submission_data && self.submission_data.is_a?(Hash)
      true
    else
      false
    end
  end
  
  def finished_in_words
    extend ActionView::Helpers::DateHelper
    started_at && finished_at && time_ago_in_words(Time.now - (finished_at - started_at))
  end
  
  def points_possible_at_submission_time
    self.questions_as_object.map{|q| q[:points_possible].to_i }.compact.sum || 0
  end
  
  def questions
    self.quiz_data
  end
  
  def backup_submission_data(params)
    raise "Only a hash value is accepted for backup_submission_data calls" unless params.is_a?(Hash)
    conn = QuizSubmission.connection
    new_params = params
    if self.submission_data.is_a?(Hash) && self.submission_data[:attempt] == self.attempt
      new_params = self.submission_data.deep_merge(params) rescue params
    end
    new_params[:attempt] = self.attempt
    new_params[:cnt] ||= 0
    new_params[:cnt] = (new_params[:cnt].to_i + 1) % 5
    snapshot!(params) if new_params[:cnt] == 1
    conn.execute("UPDATE quiz_submissions SET user_id=#{self.user_id || 'NULL'}, submission_data=#{conn.quote(new_params.to_yaml)} WHERE workflow_state NOT IN ('complete', 'pending_review') AND id=#{self.id}")
  end
  
  def snapshot!(params)
    QuizSubmissionSnapshot.create(:quiz_submission => self, :attempt => self.attempt, :data => params)
  end
  
  def questions_as_object
    self.quiz_data || {}
  end
  
  def update_kept_score
    self.quiz_points_possible = self.quiz && self.quiz.points_possible
    if self.completed?
      if self.submission_data && self.submission_data.is_a?(Hash)
        self.grade_submission
      end
      self.kept_score = self.score
      if self.quiz && self.quiz.scoring_policy == "keep_highest"
        scores = [self.kept_score]
        scores += versions.map{|v| v.model.score || 0.0} rescue []
        self.kept_score = scores.max rescue 0
      end
    end
  end
  
  def update_assignment_submission
    if self.quiz && self.quiz.for_assignment? && self.quiz.assignment && !self.submission && self.user_id
      self.submission = self.quiz.assignment.find_or_create_submission(self.user_id)
    end
    if self.completed? && self.submission
      s = self.submission
      s.score = self.kept_score if self.kept_score
      s.submitted_at = self.finished_at
      s.grade_matches_current_submission = true
      s.quiz_submission_id = self.id
      s.graded_at = self.end_at || Time.now
      s.grader_id = "-#{self.quiz_id}".to_i
      s.body = "user: #{self.user_id}, quiz: #{self.quiz_id}, score: #{self.score}, time: #{Time.now.to_s}"
      s.user_id = self.user_id
      s.submission_type = "online_quiz"
      s.save!
    end
  end

  def less_than_allotted_time?
    self.started_at && self.end_at && self.quiz && self.quiz.time_limit && (self.end_at - self.started_at) < self.quiz.time_limit.minutes
  end
  
  def completed?
    self.complete? || self.pending_review?
  end
  
  def overdue?(strict=false)
    now = (Time.now - ((strict ? 1 : 5) * 60))
    !!(end_at && end_at.localtime < now)
  end
  
  def extendable?
    !!(untaken? && end_at && end_at < 1.hour.from_now)
  end
  
  protected :update_assignment_submission
  
  # Returned in order oldest to newest
  def submitted_versions
    found_attempts = {}
    res = []

    found_attempts[self.attempt] = true if self.completed?
    self.versions.sort_by(&:created_at).each do |version|
      model = version.model
      if !found_attempts[model.attempt]
        model.readonly!
        if model.completed?
          res << model
          found_attempts[model.attempt] = true
        end
      end
    end
    res << self if self.completed?
    res
  end
  
  def attempts_left
    return -1 if self.quiz.allowed_attempts < 0
    [0, self.quiz.allowed_attempts - (self.attempt || 0) + (self.extra_attempts || 0)].max
  end
  
  def mark_completed
    QuizSubmission.update_all({ :workflow_state => 'complete' }, { :id => self.id })
  end
  
  def grade_submission(opts={})
    if self.submission_data.is_a?(Array)
      raise "Can't grade an already-submitted submission: #{self.workflow_state} #{self.submission_data.class.to_s}" 
    end
    @tally = 0
    @user_answers = []
    data = self.submission_data || {}
    self.questions_as_object.each do |q|
      user_answer = self.class.score_question(q, data)
      @user_answers << user_answer
      @tally += (user_answer[:points] || 0) if user_answer[:correct]
    end
    self.score = @tally
    self.score = self.quiz.points_possible if self.quiz && self.quiz.quiz_type == 'graded_survey'
    self.submission_data = @user_answers
    self.workflow_state = "complete"
    @user_answers.each do |answer|
      self.workflow_state = "pending_review" if answer[:correct] == "undefined"
    end
    self.finished_at = Time.now
    self.manually_unlocked = nil
    self.finished_at = opts[:finished_at] if opts[:finished_at]
    if self.quiz.for_assignment? && self.user_id
      assignment_submission = self.quiz.assignment.find_or_create_submission(self.user_id)
      self.submission = assignment_submission
    end
    self.with_versioning(true) do |s|
      s.save
    end
    self.context_module_action
    track_outcomes(self.attempt)
    true
  end
  
  def re_grade_submission(all_versions=false)
    versions = [OpenObject.new(:model => self)]
    versions += self.submitted_versions if all_versions
    current_quiz_data = self.quiz.quiz_data
    versions.each do |version|
      submission = version.model
      submission_data = submission.submission_data
      submission_data.each do |question|
        re_grade_question(question)
      end
      if version.is_a?(Version)
        submission.update_submission_version(version)
      else
        self.submission_data = submission.submission_data
        self.score = submission.score
        self.save
      end
      track_outcomes(self.attempt) if self.attempt
    end
  end
  
  # Updates a simply_versioned version instance in-place.  We want
  # a teacher to be able to come in and update points for an already-
  # taken quiz, even if it's a prior version of the submission. Thank you
  # simply_versioned for making this possible!
  def update_submission_version(version)
    version_data = YAML::load(version.yaml)
    version_data["submission_data"] = self.submission_data
    version_data["temporary_user_code"] = "was #{version_data['score']} until #{Time.now.to_s}"
    version_data["score"] = self.score
    version_data["fudge_points"] = self.fudge_points
    version_data["workflow_state"] = self.workflow_state
    version.yaml = version_data.to_yaml
    res = version.save
    res
  end
  
  def context_module_action
    if self.quiz && self.user
      if self.score
        self.quiz.context_module_action(self.user, :scored, self.kept_score)
      elsif self.submitted_at
        self.quiz.context_module_action(self.user, :submitted)
      end
    end
  end
  
  def update_if_needs_review(quiz=nil)
    quiz = self.quiz if !quiz || quiz.id != self.quiz_id
    return false unless self.completed?
    return false if self.quiz_version && self.quiz_version >= quiz.version_number
    if quiz.changed_significantly_since?(self.quiz_version)
      self.workflow_state = 'pending_review'
      self.save
      return true
    end
    false
  end
  
  def update_scores(params)
    params = (params || {}).with_indifferent_access
    versions = self.versions
    version = versions.current
    version = versions.get(params[:submission_version_number]) if params[:submission_version_number]
    # note that self may not match versions.current, because we only save a new version on actual submit
    raise "Can't update submission scores unless it's completed" if !self.completed? && !params[:submission_version_number]
    
    data = version.model.submission_data || []
    res = []
    tally = 0
    self.workflow_state = "complete"
    self.fudge_points = params[:fudge_points].to_f if params[:fudge_points] && params[:fudge_points] != ""
    tally += self.fudge_points if self.fudge_points
    data.each do |answer|
      unless answer.respond_to?(:with_indifferent_access)
        logger.error "submission = #{self.to_json}"
        logger.error "answer = #{answer.inspect}"
        raise "QuizSubmission.update_scores called on a quiz that appears to be in progress"
      end
      answer = answer.with_indifferent_access
      score = params["question_score_#{answer["question_id"]}".to_sym]
      answer["more_comments"] = params["question_comment_#{answer["question_id"]}".to_sym] if params["question_comment_#{answer["question_id"]}".to_sym]
      if score != "--" && score != ""
        answer["points"] = (score.to_f rescue nil) || answer["points"] || 0
        answer["correct"] = "defined" if answer["correct"] == "undefined" && (score.to_f rescue nil)
      elsif score == "--"
        answer["points"] = 0
        answer["correct"] = "undefined"
      end
      self.workflow_state = "pending_review" if answer["correct"] == "undefined"
      res << answer
      tally += answer["points"].to_f rescue 0
    end
    self.score = tally
    self.submission_data = res

    update_submission_version(version)
    if version == versions.current
      self.with_versioning(false) do |s|
        s.save
      end
    elsif (self.quiz && self.quiz.scoring_policy == 'keep_highest' && self.score > self.kept_score)
      # Force a save on the latest version so kept_score gets updated correctly
      old_state = self.workflow_state
      self.reload
      self.workflow_state = old_state
      self.without_versioning(&:save)
    end
    self.context_module_action
    track_outcomes(version.model.attempt)
    true
  end
  
  def duration
    (self.finished_at || self.started_at) - self.started_at rescue 0
  end
  
  def self.score_question(q, params)
    params = params.with_indifferent_access
    # TODO: undefined_if_blank - we need a better solution for the
    # following problem: since teachers can modify quizzes after students
    # have submitted (we warn them not to, but it is possible) we need
    # a good way to mark questions as needing attention for past submissions.
    # If a student already took the quiz and then a new question gets
    # added or the question answer they selected goes away, then the
    # the teacher gets the added burden of going back and manually assigning
    # scores for these questions per student.
    undefined_if_blank = params[:undefined_if_blank]
    answer_text = params["question_#{q[:id]}"] rescue ""
    user_answer = {}
    user_answer[:text] = answer_text || ""
    user_answer[:question_id] = q[:id]
    user_answer[:points] = 0
    user_answer[:correct] = false
    question_type = q[:question_type]
    q[:points_possible] = q[:points_possible].to_f
    if question_type == "multiple_choice_question" || question_type == "true_false_question" || question_type == "missing_word_question"
      q[:answers].each do |answer|
        if answer[:id] == answer_text.to_i
          user_answer[:answer_id] = answer[:id]
          user_answer[:correct] = answer[:weight] == 100
          user_answer[:points] = q[:points_possible]
        end
      end
      user_answer[:correct] = "undefined" if answer_text == nil && undefined_if_blank
    elsif question_type == "short_answer_question"
      answers = q[:answers].sort_by{|a| a[:weight] || 0}
      match = false
      answers.each do |answer|
        if (answer[:text] || "").strip.downcase == CGI::escapeHTML(answer_text || "").strip.downcase && !match
          match = true
          user_answer[:answer_id] = answer[:id]
          user_answer[:correct] = true
          user_answer[:points] = q[:points_possible]
        end
      end
      user_answer[:correct] = "undefined" if answer_text == nil && undefined_if_blank
    elsif question_type == "essay_question" 
      config = Instructure::SanitizeField::SANITIZE
      user_answer[:text] = Sanitize.clean(user_answer[:text] || "", config)
      user_answer[:correct] = "undefined"
    elsif question_type == "text_only_question"
      user_answer[:correct] = "no_score"
    elsif question_type == "matching_question"
      user_answer[:points] = 0
      found_match = false
      q[:answers].each do |answer|
        answer_match = params["question_#{q[:id]}_answer_#{answer[:id]}"].to_s rescue ""
        found_match = true if answer_match != nil
        found_matched = q[:answers].find{|a| a[:match_id].to_i == answer_match.to_i}
        if found_matched == answer || (found_matched && found_matched[:right] && found_matched[:right] == answer[:right])
          user_answer[:points] += (q[:points_possible].to_f / q[:answers].length.to_f) rescue 0
          answer_match = answer[:match_id].to_s
        end
        user_answer["answer_#{answer[:id]}".to_sym] = answer_match
      end
      if q[:allow_partial_credit] == false && user_answer[:points] < q[:points_possible].to_f
        user_answer[:points] = 0
      end
      user_answer[:correct] = "partial"
      user_answer[:correct] = false if user_answer[:points] == 0
      user_answer[:correct] = true if user_answer[:points] == q[:points_possible]
      user_answer[:correct] = "undefined" if !found_match && undefined_if_blank
    elsif question_type == "numerical_question"
      answer_number = answer_text.to_f
      answers = q[:answers].sort_by{|a| a[:weight] || 0}
      match = false
      answers.each do |answer|
        if !match
          if answer[:numerical_answer_type] == "exact_answer"
            match = true if answer_number >= answer[:exact] - answer[:margin] && answer_number <= answer[:exact] + answer[:margin]
          else
            match = true if answer_number >= answer[:start] && answer_number <= answer[:end]
          end
          if match
            user_answer[:answer_id] = answer[:id]
            user_answer[:correct] = true
            user_answer[:points] = q[:points_possible]
          end
        end
      end
      user_answer[:correct] = "undefined" if answer_text == nil && undefined_if_blank
    elsif question_type == "calculated_question"
      answer_number = answer_text.to_f
      val = q[:answers].first[:answer].to_f rescue 0
      margin = q[:answers].first[:answer_tolerance].to_f rescue 0
      min = val - margin
      max = val + margin
      user_answer[:answer_id] = q[:answers].first[:id]
      if answer_number >= min && answer_number <= max
        user_answer[:correct] = true
        user_answer[:points] = q[:points_possible]
      end
    elsif question_type == "multiple_answers_question"
      correct_sequence = ""
      user_sequence = ""
      found_any = false
      user_answer[:points] = 0
      n_correct = q[:answers].select{|a| a[:weight] == 100}.length
      n_correct = 1 if n_correct == 0
      q[:answers].each do |answer|
        response = params["question_#{q[:id]}_answer_#{answer[:id]}"] rescue ""
        response ||= ""
        found_any = true if response != nil
        user_answer["answer_#{answer[:id]}".to_sym] = response
        correct = nil
        # Total possible is divided by the number of correct answers.
        # For every correct answer they correctly select, they get partial
        # points.  For every correct answer they don't select, do nothing.  
        # For every incorrect answer that they select, dock them partial
        # points.
        correct = true if answer[:weight] == 100 && response == "1"
        correct = false if answer[:weight] != 100 && response == "1"
        if correct == true
          user_answer[:points] += (q[:points_possible].to_f / n_correct.to_f) rescue 0
        elsif correct == false
          dock = (q[:incorrect_dock] || (q[:points_possible].to_f / n_correct.to_f)).to_f rescue 0.0
          user_answer[:points] -= dock
        end
        correct_sequence = correct_sequence + (answer[:weight] == 100 ? "1" : "0")
        user_sequence = user_sequence + (response == "1" ? "1" : "0")
      end
      # even if they only selected wrong answers, they can't score less than 0
      user_answer[:points] = [user_answer[:points], 0].max
      if correct_sequence == user_sequence
        user_answer[:points] = q[:points_possible]
      end
      if q[:allow_partial_credit] == false && user_answer[:points] < q[:points_possible].to_f
        user_answer[:points] = 0
      end
      user_answer[:correct] = "partial"
      user_answer[:correct] = false if user_answer[:points] == 0
      user_answer[:correct] = true if user_answer[:points] == q[:points_possible]
      user_answer[:correct] = "undefined" if !found_any && undefined_if_blank
    elsif question_type == "multiple_dropdowns_question"
      chosen_answers = {}
      variables = q[:answers].map{|a| a[:blank_id] }.uniq
      variables.each do |variable|
        variable_id = AssessmentQuestion.variable_id(variable)
        response = (params["question_#{q[:id]}_#{variable_id}"] rescue nil).to_i
        chosen_answer = q[:answers].detect{|answer| answer[:blank_id] == variable && answer[:id] == response.to_i }
        chosen_answers[variable] = chosen_answer
      end
      answer_tally = 0
      chosen_answers.each do |variable, answer|
        answer_tally += q[:points_possible].to_f / variables.length.to_f if answer && answer[:weight] == 100 && !variables.empty?
        user_answer["answer_for_#{variable}".to_sym] = answer[:id] rescue nil
        user_answer["answer_id_for_#{variable}".to_sym] = answer[:id] rescue nil
      end
      user_answer[:points] = answer_tally
      user_answer[:correct] = true if answer_tally == q[:points_possible]
      user_answer[:correct] = "partial" if answer_tally > 0 && answer_tally < q[:points_possible]
    elsif question_type == "fill_in_multiple_blanks_question"
      chosen_answers = {}
      variables = q[:answers].map{|a| a[:blank_id] }.uniq
      variables.each do |variable|
        variable_id = AssessmentQuestion.variable_id(variable)
        response = params["question_#{q[:id]}_#{variable_id}"]
        response ||= ""
        chosen_answer = q[:answers].detect{|answer| answer[:blank_id] == variable && (answer[:text] || "").strip.downcase == response.strip.downcase }
        chosen_answers[variable] = chosen_answer || {:text => response, :weight => 0}
      end
      answer_tally = 0
      chosen_answers.each do |variable, answer|
        answer_tally += 1 if answer[:weight] == 100 && !variables.empty?
        user_answer["answer_for_#{variable}".to_sym] = answer[:text] rescue nil
        user_answer["answer_id_for_#{variable}".to_sym] = answer[:id] rescue nil
      end
      if !variables.empty?
        user_answer[:points] = (answer_tally / variables.length.to_f) * q[:points_possible].to_f
      end
      user_answer[:correct] = true if answer_tally == variables.length.to_i
      user_answer[:correct] = "partial" if answer_tally > 0 && answer_tally < variables.length.to_i
    else
    end
    user_answer[:points] = 0.0 unless user_answer[:correct]
    user_answer[:points] = (user_answer[:points] * 100.0).round.to_f / 100.0
    user_answer
  end
  
  named_scope :before, lambda{|date|
    {:conditions => ['quiz_submissions.created_at < ?', date]}
  }
  named_scope :updated_after, lambda{|date|
    if date
      {:conditions => ['quiz_submissions.updated_at > ?', date]}
    end
  }
  named_scope :for_user_ids, lambda{|user_ids|
    {:conditions => {:user_id => user_ids} }
  }
end
