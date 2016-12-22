#
# Copyright (C) 2011 - 2014 Instructure, Inc.
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
    }.freeze
  }.freeze

  attr_protected :submitted_at
  attr_readonly :assignment_id
  attr_accessor :visible_to_user,
                :skip_grade_calc

  belongs_to :attachment # this refers to the screenshot of the submission if it is a url submission
  belongs_to :assignment
  belongs_to :user
  belongs_to :grader, :class_name => 'User'
  belongs_to :group
  belongs_to :media_object
  belongs_to :student, :class_name => 'User', :foreign_key => :user_id

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
  has_many :attachment_associations, :as => :context
  has_many :provisional_grades, class_name: 'ModeratedGrading::ProvisionalGrade'
  has_one :rubric_assessment, -> { where(assessment_type: 'grading') }, as: :artifact

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
  validate :ensure_grader_can_grade

  scope :with_comments, -> { preload(:submission_comments) }
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

  scope :for_course, lambda { |course|
    where(assignment_id: course.assignments.except(:order))
  }

  workflow do
    state :submitted do
      event :grade_it, :transitions_to => :graded
    end
    state :unsubmitted
    state :pending_review
    state :graded
  end


  # see #needs_grading?
  def self.needs_grading_conditions
    conditions = <<-SQL
      submissions.submission_type IS NOT NULL
      AND (submissions.workflow_state = 'pending_review'
        OR (submissions.workflow_state = 'submitted'
          AND (submissions.score IS NULL OR NOT submissions.grade_matches_current_submission)
        )
      )
    SQL
    conditions.gsub!(/\s+/, ' ')
    conditions
  end

  # see .needs_grading_conditions
  def needs_grading?(was = false)
    suffix = was ? "_was" : ""

    !send("submission_type#{suffix}").nil? &&
    (send("workflow_state#{suffix}") == 'pending_review' ||
      (send("workflow_state#{suffix}") == 'submitted' &&
        (send("score#{suffix}").nil? || !send("grade_matches_current_submission#{suffix}"))
      )
    )
  end

  def needs_grading_changed?
    needs_grading? != needs_grading?(:was)
  end

  scope :needs_grading, -> { where(needs_grading_conditions) }


  sanitize_field :body, CanvasSanitize::SANITIZE

  attr_accessor :saved_by,
                :assignment_changed_not_sub,
                :grading_error_message
  before_save :update_if_pending
  before_save :validate_single_submission, :infer_values
  before_save :prep_for_submitting_to_turnitin
  before_save :prep_for_submitting_to_vericite
  before_save :check_url_changed
  before_save :check_reset_graded_anonymously
  before_create :cache_due_date
  after_save :touch_user
  after_save :touch_graders
  after_save :update_assignment
  after_save :update_attachment_associations
  after_save :submit_attachments_to_canvadocs
  after_save :queue_websnap
  after_save :update_final_score
  after_save :submit_to_turnitin_later
  after_save :submit_to_vericite_later
  after_save :update_admins_if_just_submitted
  after_save :check_for_media_object
  after_save :update_quiz_submission
  after_save :update_participation

  def autograded?
    # AutoGrader == (quiz_id * -1)
    !!(self.grader_id && self.grader_id < 0)
  end

  def adjust_needs_grading_count(mode = :increment)
    amount = mode == :increment ? 1 : -1
    Assignment.
      where(id: assignment_id, context_type: 'Course').
      where("EXISTS (?)",
        Enrollment.where(Enrollment.active_student_conditions).
        where(user_id: user_id).
        where("course_id=assignments.context_id")).
      update_all(["needs_grading_count=needs_grading_count+?, updated_at=?", amount, Time.now.utc])
    # TODO: add this to the SQL above when DA is on for everybody
    # and remove NeedsGradingCountQuery#manual_count
    # AND EXISTS (SELECT assignment_student_visibilities.* WHERE assignment_student_visibilities.user_id = NEW.user_id AND assignment_student_visibilities.assignment_id = NEW.assignment_id);
  end

  after_create :update_needs_grading_count, if: :needs_grading?
  after_update :update_needs_grading_count, if: :needs_grading_changed?
  def update_needs_grading_count
    self.class.connection.after_transaction_commit do
      adjust_needs_grading_count(needs_grading? ? :increment : :decrement)
    end
  end

  attr_reader :group_broadcast_submission

  has_a_broadcast_policy

  simply_versioned :explicit => true,
    :when => lambda{ |model| model.new_version_needed? },
    :on_create => lambda{ |model,version| SubmissionVersion.index_version(version) },
    :on_load => lambda{ |model,version| model.cached_due_date = version.versionable.cached_due_date }

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
    can :read and can :comment and can :make_group_comment and can :read_grade

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

  def can_view_plagiarism_report(type, user, session)
    if(type == "vericite")
      plagData = self.vericite_data_hash
      @submit_to_vericite = false
      settings = assignment.vericite_settings
    else
      plagData = self.turnitin_data
      @submit_to_turnitin = false
      settings = assignment.turnitin_settings
    end
    return plagData &&
    user_can_read_grade?(user, session) &&
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

  def user_can_read_grade?(user, session=nil)
    # improves performance by checking permissions on the assignment before the submission
    self.assignment.user_can_read_grades?(user, session) || self.grants_right?(user, session, :read_grade)
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
    if score_changed? || excused_changed? ||
        (workflow_state_was == "pending_review" && workflow_state == "graded")
      if skip_grade_calc
        Rails.logger.info "GRADES: NOT recomputing scores for submission #{global_id} because skip_grade_calc was set"
      else
        Rails.logger.info "GRADES: submission #{global_id} score changed. recomputing grade for course #{context.global_id} user #{user_id}."
        self.class.connection.after_transaction_commit do
          Enrollment.send_later_if_production_enqueue_args(:recompute_final_score, { run_at: 3.seconds.from_now }, self.user_id, self.context.id)
        end
      end
      self.assignment.send_later_if_production(:multiple_module_actions, [self.user_id], :scored, self.score) if self.assignment
    end
    true
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

  def prep_for_submitting_to_turnitin
    prep_for_submitting_to_plagiarism('turnitin')
  end

  TURNITIN_JOB_OPTS = { :n_strand => 'turnitin', :priority => Delayed::LOW_PRIORITY, :max_attempts => 2 }

  def submit_to_turnitin_later
    submit_to_plagiarism_later('turnitin')
  end

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

  def turnitin_assets
    if self.submission_type == 'online_upload'
      self.attachments.select{ |a| a.turnitinable? }
    elsif self.submission_type == 'online_text_entry'
      [self]
    else
      []
    end
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
    turnitinable_by_lti? ? retrieve_lti_tii_score : submit_to_turnitin_later
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
    # since there could be multiple versions, let's not waste calls for old versions and use the old score
    if Canvas::Plugin.find(:vericite).try(:enabled?) && !self.readonly? && lookup_data && self.versions.current && self.versions.current.number == self.version_number
      self.vericite_data_hash.keys.each do |asset_string|
        data = self.vericite_data_hash[asset_string]
        next unless data && data.is_a?(Hash) && data[:object_id]
        update_scores = update_scores || vericite_recheck_score(data)
      end
      # we have found at least one score that is stale, call VeriCite and save the results
      if update_scores
        check_vericite_status
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
    self.vericite_data_hash.keys.each do |asset_string|
      data = self.vericite_data_hash[asset_string]
      next unless data && data.is_a?(Hash) && data[:object_id]
      # check to see if the score is stale, if so, delete it and fetch again
      recheck_score = vericite_recheck_score(data)
      # keep track whether all scores are updates or if any are new
      recheck_score_all = recheck_score_all && recheck_score
      # look up scores if:
      if recheck_score || data[:similarity_score].blank?
        if attempt < VERICITE_STATUS_RETRY
          # keep track of when we asked for this score, so if it fails, we don't keep trying immediately again (i.e. wain 20 sec before trying again)
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
    end

    if !self.vericite_data_hash.empty?
      # only set vericite provider flag if the hash isn't empty
      self.vericite_data_hash[:provider] = :vericite
    end
    retry_mins = 2 ** attempt
    if retry_mins > 240
      #cap the retry max wait to 4 hours
      retry_mins = 240;
    end
    send_at(retry_mins.minutes.from_now, :check_vericite_status, attempt + 1) if needs_retry
    self.vericite_data_changed!
    # if all we did was recheck scores, do not version this save (i.e. increase the attempt number)
    if recheck_score_all
      self.with_versioning( false ) do |t|
        t.save!
      end
    else
      self.save
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

  def prep_for_submitting_to_vericite
    prep_for_submitting_to_plagiarism('vericite')
  end

  VERICITE_JOB_OPTS = { :n_strand => 'vericite', :priority => Delayed::LOW_PRIORITY, :max_attempts => 2 }

  def submit_to_vericite_later
    submit_to_plagiarism_later('vericite')
  end

  VERICITE_RETRY = 5
  def submit_to_vericite(attempt=0)
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
    self.save

    @submit_to_vericite = true
    submit_to_vericite_later
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

  def prep_for_submitting_to_plagiarism(type)
    if(type == "vericite")
      plagData = self.vericite_data_hash
      @submit_to_vericite = false
      canSubmit = self.vericiteable?
    else
      plagData = self.turnitin_data
      @submit_to_turnitin = false
      canSubmit = self.turnitinable?
    end
    last_attempt = plagData && plagData[:last_processed_attempt]
    if canSubmit && (!last_attempt || last_attempt < self.attempt) && (@group_broadcast_submission || !self.group)
      if plagData[:last_processed_attempt] != self.attempt
        plagData[:last_processed_attempt] = self.attempt
      end
      if(type == "vericite")
        @submit_to_vericite = true
      else
        @submit_to_turnitin = true
      end
    end
  end

  def submit_to_plagiarism_later(type)
    if(type == "vericite")
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
    associations = self.attachment_associations
    association_ids = associations.map(&:attachment_id)
    ids = (Array(self.attachment_ids || "").join(',')).split(",").map{|id| id.to_i}
    ids << self.attachment_id if self.attachment_id
    ids.uniq!
    existing_associations = associations.select{|a| ids.include?(a.attachment_id) }
    (associations - existing_associations).each{|a| a.destroy }
    unassociated_ids = ids.reject{|id| association_ids.include?(id) }
    return if unassociated_ids.empty?
    attachments = Attachment.where(id: unassociated_ids)
    attachments.each do |a|
      if (a.context_type == 'User' && a.context_id == user_id) ||
         (a.context_type == 'Group' && a.context_id == group_id) ||
         (a.context_type == 'Assignment' && a.context_id == assignment_id && a.available?) ||
         attachment_fake_belongs_to_group(a)
        aa = self.attachment_associations.where(attachment_id: a).first
        aa ||= self.attachment_associations.create(:attachment => a)
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
    if attachment_ids_changed? && submission_type != 'discussion_topic'
      attachments.preload(:crocodoc_document, :canvadoc).each do |a|
        # moderated grading annotations are only supported in crocodoc right now
        dont_submit_to_canvadocs = assignment.moderated_grading?

        # associate previewable-document and submission for permission checks
        if a.canvadocable? && Canvadocs.annotations_supported? && !dont_submit_to_canvadocs
          submit_to_canvadocs = true
          a.create_canvadoc!(canvadoc_params) unless a.canvadoc
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
          a.send_later_enqueue_args :submit_to_canvadocs, {
            :n_strand     => 'canvadocs',
            :max_attempts => 1,
            :priority => Delayed::LOW_PRIORITY
          }, 1, wants_annotation: true, force_crocodoc: dont_submit_to_canvadocs
        end
      end
    end
  end

  def infer_values
    if assignment
      self.context_code = assignment.context_code
    end

    self.submitted_at ||= Time.now if self.has_submission? || (self.submission_type && !self.submission_type.empty?)
    self.quiz_submission.reload if self.quiz_submission_id
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
    if score_changed?
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

  def cache_due_date
    self.cached_due_date = assignment.overridden_for(user).due_at
  end

  def update_admins_if_just_submitted
    if @just_submitted
      context.send_later_if_production(:resubmission_for, assignment)
    end
    true
  end

  def check_for_media_object
    if self.media_comment_id.present? && self.media_comment_id_changed?
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
        end
        if model.submitted_at && last_submitted_at.to_i != model.submitted_at.to_i
          res << model
          last_submitted_at = model.submitted_at
        end
      end
      res = self.versions.to_a[0,1].map(&:model) if res.empty?
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
    return :unpublished unless assignment.published?
    return :not_autograded if grader_id >= 0

    student_id = user_id || self.user.try(:id)

    if assignment.in_closed_grading_period_for_student?(student_id)
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

    return :unpublished unless assignment.published?
    return :cant_manage_grades unless context.grants_right?(user, nil, :manage_grades)
    return :account_admin if context.account_membership_allows(user)

    student_id = self.user_id || self.user.try(:id)

    if assignment.in_closed_grading_period_for_student?(student_id)
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

  def versioned_attachments
    if @versioned_attachments
      @versioned_attachments
    else
      ids = (attachment_ids || "").split(",")
      ids << attachment_id if attachment_id
      self.versioned_attachments = (ids.empty? ? [] : Attachment.where(:id => ids))
      @versioned_attachments
    end
  end

  def versioned_attachments=(attachments)
    @versioned_attachments = Array(attachments).compact.select { |a|
      (a.context_type == 'User' && a.context_id == user_id) ||
      (a.context_type == 'Group' && a.context_id == group_id) ||
      (a.context_type == 'Assignment' && a.context_id == assignment_id && a.available?)
    }
  end

  # use this method to pre-load the versioned_attachments for a bunch of
  # submissions (avoids having O(N) attachment queries)
  # NOTE: all submissions must belong to the same shard
  def self.bulk_load_versioned_attachments(submissions, preloads: [:thumbnail, :media_object])
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
    attachment_ids_by_submission_and_index = Hash[submissions_with_index_and_attachment_ids]

    bulk_attachment_ids = attachment_ids_by_submission_and_index.values.flatten

    if bulk_attachment_ids.empty?
      attachments_by_id = {}
    else
      attachments_by_id = Attachment.where(:id => bulk_attachment_ids)
                          .preload(preloads)
                          .group_by(&:id)
    end

    submissions.each_with_index do |s, index|
      s.versioned_attachments =
        attachments_by_id.values_at(*attachment_ids_by_submission_and_index[[s, index]]).flatten
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
      [s, attachments_by_id.values_at(*attachment_ids_by_submission[s]).flatten.uniq]
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
    self.prior_version && self.prior_version.graded_at && self.prior_version.graded_at > 1.hour.ago
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
      self.submission_type ||= "online_upload" if !self.attachments.empty?
    end
    true
  end
  private :validate_single_submission

  def canvadoc_params
    { preferred_plugin_course_id: preferred_plugin_course_id }
  end
  private :canvadoc_params

  def preferred_plugin_course_id
    if self.context && self.context.is_a?(Course)
      self.context.id
    else
      nil
    end
  end
  private :preferred_plugin_course_id

  def grade_change_audit
    return true unless (self.changed & %w(grade score excused)).present? || self.assignment_changed_not_sub
    self.class.connection.after_transaction_commit { Auditors::GradeChange.record(self) }
  end

  scope :with_assignment, -> { joins(:assignment).where("assignments.workflow_state <> 'deleted'")}

  scope :graded, -> { where("submissions.grade IS NOT NULL") }

  scope :ungraded, -> { where(:grade => nil).preload(:assignment) }

  scope :in_workflow_state, lambda { |provided_state| where(:workflow_state => provided_state) }

  scope :having_submission, -> { where("submissions.submission_type IS NOT NULL") }
  scope :without_submission, -> { where(submission_type: nil, workflow_state: "unsubmitted") }

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
    submission_comments.published.reverse.find{ |com| com.author_id != user_id }
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

  def provisional_grade(scorer, final: false, preloaded_grades: nil)
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
    pg ||= ModeratedGrading::NullProvisionalGrade.new(self, scorer.id, final)
  end

  def find_or_create_provisional_grade!(scorer, attrs = {})
    ModeratedGrading::ProvisionalGrade.unique_constraint_retry do
      if attrs[:final] && !self.assignment.context.grants_right?(scorer, :moderate_grades)
        raise Assignment::GradeError.new("User not authorized to give final provisional grades")
      end

      pg = find_existing_provisional_grade(scorer, attrs[:final]) || self.provisional_grades.build

      update_provisional_grade(pg, scorer, attrs)
      pg.save! if attrs[:force_save] || pg.new_record? || pg.changed?
      pg
    end
  end

  def update_provisional_grade(pg, scorer, attrs = {})
    pg.scorer = scorer
    pg.final = !!attrs[:final]
    pg.grade = attrs[:grade] unless attrs[:grade].nil?
    pg.score = attrs[:score] unless attrs[:score].nil?
    pg.source_provisional_grade = attrs[:source_provisional_grade]
    pg.graded_anonymously = attrs[:graded_anonymously] unless attrs[:graded_anonymously].nil?
    pg.force_save = !!attrs[:force_save]
  end

  def find_existing_provisional_grade(scorer, final)
    final ? self.provisional_grades.final.first : self.provisional_grades.not_final.find_by(scorer: scorer)
  end

  def crocodoc_whitelist
    if assignment.moderated_grading?
      if assignment.grades_published?
        sel = assignment.moderated_grading_selections.where(student_id: self.user).first
        if sel && (pg = sel.provisional_grade)
          # include the student, the final grader, and the source grader (if a moderator copied a mark)
          annotators = [self.user, pg.scorer]
          annotators << pg.source_provisional_grade.scorer if pg.source_provisional_grade
          annotators.map(&:crocodoc_id!)
        else
          # student not in moderation set: no filter
          nil
        end
      else
        # grades not yet published: students see only their own annotations
        # (speedgrader overrides this for provisional graders)
        [self.user.crocodoc_id!]
      end
    else
      # not a moderated assignment: no filter
      nil
    end
  end

  def add_comment(opts={})
    opts = opts.symbolize_keys
    opts[:author] ||= opts[:commenter] || opts[:author] || opts[:user] || self.user
    opts[:comment] = opts[:comment].try(:strip) || ""
    opts[:attachments] ||= opts[:comment_attachments]
    opts[:draft] = opts[:draft_comment]
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
    commenting_instructors.present? ? commenting_instructors : context.participating_instructors.uniq
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
  #  * score (Fixnum)
  #  * excused (Boolean)
  #
  module Tardiness
    def past_due?
      return false if cached_due_date.nil?
      check_time = submitted_at || Time.now
      check_time -= 60.seconds if submission_type == 'online_quiz'
      cached_due_date < check_time
    end
    alias_method :past_due, :past_due?

    def late?
      submitted_at.present? && past_due?
    end
    alias_method :late, :late?

    def missing?
      return false if !past_due? || submitted_at.present?
      assignment.expects_submission? || !(self.excused || (self.graded? && self.score > 0))
    end
    alias_method :missing, :missing?

    # QUESTIONS ABOUT EXCUSED:
    #   * what happens for group assignments? excuse individually
    #     * can't excuse for group assignments in speedgrader 1.0
    #     * TODO make sure Assignment#representatives is updated accordingly
    #
    # QUESTIONS FOR ME:
    #   * are we messing up graded / not graded counts???
    def graded?
      excused || (!!score && workflow_state == 'graded')
    end
  end
  include Tardiness

  def current_submission_graded?
    self.graded? && (!self.submitted_at || (self.graded_at && self.graded_at >= self.submitted_at))
  end

  def context(_user=nil)
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
    methods = [ :formatted_body, :submission_history, :attachments ]
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
      %w(score published_grade published_score grade).each do |secret_attr|
        hash.delete secret_attr
      end
    end
    hash
  end

  def update_participation
    # TODO: can we do this in bulk?
    return if assignment.deleted? || assignment.muted?
    return unless self.user_id

    return unless self.context.grants_right?(self.user, :participate_as_student)

    if score_changed? || grade_changed? || excused_changed?
      ContentParticipation.create_or_update({
        :content => self,
        :user => self.user,
        :workflow_state => "unread",
      })
    end
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

  def change_read_state(new_state, current_user)
    return nil unless current_user
    return true if new_state == self.read_state(current_user)

    StreamItem.update_read_state_for_asset(self, new_state, current_user.id)

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

  def without_graded_submission?
    !self.has_submission? && !self.graded?
  end

  def visible_rubric_assessments_for(viewing_user)
    return [] if self.assignment.muted? && !grants_right?(viewing_user, :read_grade)
    filtered_assessments = self.rubric_assessments.select do |a|
      a.grants_right?(viewing_user, :read)
    end
    filtered_assessments.sort_by do |a|
      if a.assessment_type == 'grading'
        [CanvasSort::First]
      else
        [CanvasSort::Last, Canvas::ICU.collation_key(a.assessor_name)]
      end
    end
  end

  def rubric_association_with_assessing_user_id
    self.assignment.rubric_association.tap do |association|
      association.assessing_user_id = self.user_id if association
    end
  end

  def self.queue_bulk_update(context, section, grader, grade_data)
    progress = Progress.create!(:context => context, :tag => "submissions_update")
    progress.process_job(self, :process_bulk_update, {}, context, section, grader, grade_data)
    progress
  end

  def self.process_bulk_update(progress, context, section, grader, grade_data)
    missing_ids = []
    graded_user_ids = Set.new
    preloaded_assignments = Assignment.find(grade_data.keys).index_by(&:id)


    grade_data.each do |assignment_id, user_grades|
      assignment = preloaded_assignments[assignment_id.to_i]

      scope = assignment.students_with_visibility(context.students_visible_to(grader, include: :inactive))
      if section
        scope = scope.where(:enrollments => { :course_section_id => section })
      end

      user_ids = user_grades.map { |id, data| id }
      preloaded_users = scope.where(:id => user_ids)
      preloaded_submissions = assignment.submissions.where(user_id: user_ids).group_by(&:user_id)

      Delayed::Batch.serial_batch(:priority => Delayed::LOW_PRIORITY) do
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
                                       :skip_grade_calc => true)
            submissions.each { |s| graded_user_ids << s.user_id }
            submission = submissions.first
          end

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

    if missing_ids.any?
      progress.message = "Couldn't find User(s) with API ids #{missing_ids.map{|id| "'#{id}'"}.join(", ")}"
      progress.save
      progress.fail
    end
  ensure
    user_ids = graded_user_ids.to_a
    Rails.logger.info "GRADES: recomputing scores in course #{context.id} for users #{user_ids} because of bulk submission update"
    context.recompute_student_scores(user_ids)
  end
end
