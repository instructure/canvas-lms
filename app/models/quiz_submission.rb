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

    given {|user| user &&
      self.quiz.context.observer_enrollments.find_by_user_id_and_associated_user_id_and_workflow_state(user.id, self.user_id, 'active') }
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

  def questions_and_alignments(question_ids)
    return [], [] if question_ids.empty?

    questions = AssessmentQuestion.find_all_by_id(question_ids).compact
    bank_ids = questions.map(&:assessment_question_bank_id).uniq
    return questions, [] if bank_ids.empty?

    # equivalent to AssessmentQuestionBank#learning_outcome_alignments, but for multiple banks at once
    return questions, ContentTag.learning_outcome_alignments.active.scoped(
      :conditions => {
        :content_type => 'AssessmentQuestionBank',
        :content_id => bank_ids
      },
      :include => [:learning_outcome, :context]
    ).all
  end

  def track_outcomes(attempt)
    return unless user_id

    question_ids = (self.quiz_data || []).map{|q| q[:assessment_question_id] }.compact.uniq
    questions, alignments = questions_and_alignments(question_ids)
    return if questions.empty? || alignments.empty?

    tagged_bank_ids = Set.new(alignments.map(&:content_id))
    question_ids = questions.select{|q| tagged_bank_ids.include?(q.assessment_question_bank_id) }
    send_later_if_production(:update_outcomes_for_assessment_questions, question_ids, self.id, attempt) unless question_ids.empty?
  end

  def update_outcomes_for_assessment_questions(question_ids, submission_id, attempt)
    questions, alignments = questions_and_alignments(question_ids)
    return if questions.empty? || alignments.empty?

    submission = QuizSubmission.find(submission_id)
    versioned_submission = submission.attempt == attempt ? submission : submission.versions.sort_by(&:created_at).map(&:model).reverse.detect{|s| s.attempt == attempt }

    questions.each do |question|
      alignments.each do |alignment|
        if alignment.content_id == question.assessment_question_bank_id
          versioned_submission.create_outcome_result(question, alignment)
        end
      end
    end
  end

  def create_outcome_result(question, alignment)
    # find or create the user's unique LearningOutcomeResult for this alignment
    # of the quiz question.
    result = alignment.learning_outcome_results.
      for_association(quiz).
      for_associated_asset(question).
      find_or_initialize_by_user_id(user.id)

    # force the context and artifact
    result.artifact = self
    result.context = quiz.context || alignment.context

    # update the result with stuff from the quiz submission's question result
    cached_question = quiz_data.detect{|q| q[:assessment_question_id] == question.id }
    cached_answer = submission_data.detect{|q| q[:question_id] == cached_question[:id] }
    raise "Could not find valid question" unless cached_question
    raise "Could not find valid answer" unless cached_answer

    # mastery
    result.score = cached_answer[:points]
    result.possible = cached_question['points_possible']
    result.mastery = alignment.mastery_score && result.score && result.possible && (result.score / result.possible) > alignment.mastery_score

    # attempt
    result.attempt = attempt

    # title
    result.title = "#{user.name}, #{quiz.title}: #{cached_question[:name]}"

    result.assessed_at = Time.now
    result.save_to_version(result.attempt)
    result
  end

  def question(id)
    questions.detect { |q| q[:id].to_i == id.to_i }
  end

  def has_question?(id)
    question(id).present?
  end

  def temporary_data
    raise "Cannot view temporary data for completed quiz" unless !self.completed?
    raise "Cannot view temporary data for completed quiz" if self.submission_data && !self.submission_data.is_a?(Hash)
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

      all_present && !all_zeroes  # all zeroes applies to multiple answer questions
    end
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

    params = sanitize_params(params)

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

  def sanitize_params(params)
    # if the submission has already been graded
    if !self.submission_data.is_a?(Hash)
      return params.merge({:_already_graded => true})
    end

    if quiz.cant_go_back?
      params.reject! { |p,_|
        p =~ /\Aquestion_(\d)+/ && submission_data[:"_question_#{$1}_read"]
      }
    end
    params
  end
  
  def snapshot!(params)
    QuizSubmissionSnapshot.create(:quiz_submission => self, :attempt => self.attempt, :data => params)
  end
  
  def questions_as_object
    self.quiz_data || {}
  end
  
  def update_kept_score
    self.quiz_points_possible = self.quiz && self.quiz.points_possible
    return if self.manually_scored || @skip_after_save_score_updates
    
    if self.completed?
      if self.submission_data && self.submission_data.is_a?(Hash)
        self.grade_submission
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
    else # keep_latest
      latest_score
    end
  end

  def update_assignment_submission
    return if self.manually_scored || @skip_after_save_score_updates
    
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
      s.saved_by = :quiz_submission
      s.save!
    end
  end

  def highest_score_so_far(exclude_version_id=nil)
    scores = []
    scores << self.score if self.score
    scores += versions.reload.reject{|v| v.id == exclude_version_id}.map{|v| v.model.score || 0.0} rescue []
    scores.max
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
    !!(untaken? && quiz.time_limit && end_at && end_at.utc + 1.hour > Time.now.utc)
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

  def latest_submitted_version
    self.submitted_versions.last
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
    self.manually_scored = false
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

  # Updates a simply_versioned version instance in-place.  We want
  # a teacher to be able to come in and update points for an already-
  # taken quiz, even if it's a prior version of the submission. Thank you
  # simply_versioned for making this possible!
  def update_submission_version(version, attrs)
    version_data = YAML::load(version.yaml)
    TextHelper.recursively_strip_invalid_utf8!(version_data, true) if RUBY_VERSION >= '1.9'
    version_data["submission_data"] = self.submission_data if attrs.include?(:submission_data)
    version_data["temporary_user_code"] = "was #{version_data['score']} until #{Time.now.to_s}"
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
      elsif self.finished_at
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
    self.manually_scored = false
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

    # the interaction in here is messy

    # first we update the version we've been modifying, so that all versions are current.
    update_submission_version(version, [:submission_data, :score, :fudge_points, :workflow_state])

    if version.model.attempt == self.attempt && completed_before_changes
      self.without_versioning(&:save)
    else
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
        s.body = "user: #{self.user_id}, quiz: #{self.quiz_id}, score: #{self.kept_score}, time: #{Time.now.to_s}"
        s.saved_by = :quiz_submission
        s.save!
      end

      self.without_versioning(&:save)
    end
    self.reload
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
    qq = QuizQuestion::Base.from_question_data(q)
    user_answer = qq.score_question(params)
    result = {
      :correct => user_answer.correctness,
      :points => user_answer.score,
      :question_id => user_answer.question_id,
    }
    result[:answer_id] = user_answer.answer_id if user_answer.answer_id
    result.merge!(user_answer.answer_details)
    return result
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
