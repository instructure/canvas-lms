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
require 'set'
require 'canvas/draft_state_validations'
require 'bigdecimal'
require_dependency 'turnitin'
require_dependency 'vericite'

class Assignment < ActiveRecord::Base
  include Workflow
  include TextHelper
  include HasContentTags
  include CopyAuthorizedLinks
  include Mutable
  include ContextModuleItem
  include DatesOverridable
  include SearchTermHelper
  include Canvas::DraftStateValidations
  include TurnitinID

  attr_accessible :title, :name, :description, :due_at, :points_possible,
    :grading_type, :submission_types, :assignment_group, :unlock_at, :lock_at,
    :group_category, :group_category_id, :peer_review_count, :anonymous_peer_reviews,
    :peer_reviews_due_at, :peer_reviews_assign_at, :grading_standard_id,
    :peer_reviews, :automatic_peer_reviews, :grade_group_students_individually,
    :notify_of_update, :time_zone_edited, :turnitin_enabled, :vericite_enabled,
    :turnitin_settings, :context, :position, :allowed_extensions,
    :external_tool_tag_attributes, :freeze_on_copy,
    :only_visible_to_overrides, :post_to_sis, :integration_id, :integration_data, :moderated_grading

  ALLOWED_GRADING_TYPES = %w(
    pass_fail percent letter_grade gpa_scale points not_graded
  ).freeze

  attr_accessor :previous_id, :updating_user, :copying, :user_submitted

  attr_reader :assignment_changed

  has_many :submissions, :dependent => :destroy
  has_many :provisional_grades, :through => :submissions
  has_many :attachments, :as => :context, :dependent => :destroy
  has_many :assignment_student_visibilities
  has_one :quiz, class_name: 'Quizzes::Quiz'
  belongs_to :assignment_group
  has_one :discussion_topic, -> { where(root_topic_id: nil).order(:created_at) }
  has_many :learning_outcome_alignments, -> { where("content_tags.tag_type='learning_outcome' AND content_tags.workflow_state<>'deleted'").preload(:learning_outcome) }, as: :content, class_name: 'ContentTag'
  has_one :rubric_association, -> { where(purpose: 'grading').order(:created_at).preload(:rubric) }, as: :association
  has_one :rubric, :through => :rubric_association
  has_one :teacher_enrollment, -> { preload(:user).where(enrollments: { workflow_state: 'active', type: 'TeacherEnrollment' }) }, class_name: 'TeacherEnrollment', foreign_key: 'course_id', primary_key: 'context_id'
  has_many :ignores, :as => :asset
  has_many :moderated_grading_selections, class_name: 'ModeratedGrading::Selection'
  belongs_to :context, polymorphic: [:course]
  validates_length_of :title, :maximum => maximum_string_length, :allow_nil => false, :allow_blank => true
  belongs_to :grading_standard
  belongs_to :group_category

  has_one :external_tool_tag, :class_name => 'ContentTag', :as => :context, :dependent => :destroy
  validates_associated :external_tool_tag, :if => :external_tool?
  validate :group_category_changes_ok?
  validate :discussion_group_ok?
  validate :positive_points_possible?
  validate :moderation_setting_ok?

  accepts_nested_attributes_for :external_tool_tag, :update_only => true, :reject_if => proc { |attrs|
    # only accept the url, content_type, content_id, and new_tab params, the other accessible
    # params don't apply to an content tag being used as an external_tool_tag
    content = case attrs['content_type']
                when 'Lti::MessageHandler'
                  Lti::MessageHandler.find(attrs['content_id'].to_i)
                when 'ContextExternalTool'
                  ContextExternalTool.find(attrs['content_id'].to_i)
              end
    attrs[:content] = content if content
    attrs.slice!(:url, :new_tab, :content)
    false
  }
  before_validation do |assignment|
    if assignment.external_tool? && assignment.external_tool_tag
      assignment.external_tool_tag.context = assignment
      assignment.external_tool_tag.content_type ||= "ContextExternalTool"
    else
      assignment.association(:external_tool_tag).reset
    end
    true
  end

  def positive_points_possible?
    return if self.points_possible.to_i >= 0
    return unless self.points_possible_changed?
    errors.add(
      :points_possible,
      I18n.t(
        "invalid_points_possible",
        "The value of possible points for this assignment must be zero or greater."
      )
    )
  end

  def group_category_changes_ok?
    return if new_record?
    return unless has_submitted_submissions?
    if group_category_id_changed?
      errors.add :group_category_id, I18n.t("group_category_locked",
                                            "The group category can't be changed because students have already submitted on this assignment")
    end
  end

  def discussion_group_ok?
    return unless new_record? || group_category_id_changed?
    return unless group_category_id && submission_types == 'discussion_topic'
    errors.add :group_category_id, I18n.t("discussion_group_category_locked",
      "Group categories cannot be set directly on a discussion assignment, but should be set on the discussion instead")
  end

  def provisional_grades_exist?
    return false unless moderated_grading? || moderated_grading_changed?
    ModeratedGrading::ProvisionalGrade
      .where(submission_id: self.submissions.having_submission.select(:id))
      .where('score IS NOT NULL').exists?
  end

  def graded_submissions_exist?
    return false unless graded?
    (graded_count > 0) || provisional_grades_exist?
  end

  def moderated_grading_setting_changed?
    moderated_grading_changed? && moderated_grading.presence != moderated_grading_was.presence
  end

  def moderation_setting_ok?
    if moderated_grading_setting_changed? && graded_submissions_exist?
      errors.add :moderated_grading, I18n.t("Moderated grading setting cannot be changed if graded submissions exist")
    end
    if (moderated_grading_setting_changed? || new_record?) && moderated_grading?
      if !graded?
        errors.add :moderated_grading, I18n.t("Moderated grading setting cannot be enabled for ungraded assignments")
      end
      if has_group_category?
        errors.add :moderated_grading, I18n.t("Moderated grading setting cannot be enabled for group assignments")
      end
      if peer_reviews
        errors.add :moderated_grading, I18n.t("Moderated grading setting cannot be enabled for peer reviewed assignments")
      end
    end
  end

  API_NEEDED_FIELDS = %w(
    id
    title
    context_id
    context_type
    position
    points_possible
    grading_type
    due_at
    description
    lock_at
    unlock_at
    assignment_group_id
    peer_reviews
    automatic_peer_reviews
    peer_reviews_due_at
    peer_review_count
    submission_types
    group_category_id
    grade_group_students_individually
    turnitin_enabled
    turnitin_settings
    vericite_enabled
    allowed_extensions
    muted
    needs_grading_count
    could_be_locked
    freeze_on_copy
    copied
    all_day
    all_day_date
    created_at
    updated_at
    post_to_sis
    integration_data
    integration_id
    only_visible_to_overrides
    moderated_grading
    grades_published_at
  )

  def external_tool?
    self.submission_types == 'external_tool'
  end

  validates_presence_of :context_id, :context_type, :workflow_state

  validates_presence_of :title, if: :title_changed?
  validates_length_of :title, :maximum => maximum_string_length, :allow_nil => true
  validates_length_of :description, :maximum => maximum_long_text_length, :allow_nil => true, :allow_blank => true
  validates_length_of :allowed_extensions, :maximum => maximum_long_text_length, :allow_nil => true, :allow_blank => true
  validate :frozen_atts_not_altered, :if => :frozen?, :on => :update
  validates :grading_type, inclusion: { in: ALLOWED_GRADING_TYPES },
    allow_nil: true, on: :create

  acts_as_list :scope => :assignment_group
  simply_versioned :keep => 5
  sanitize_field :description, CanvasSanitize::SANITIZE
  copy_authorized_links( :description) { [self.context, nil] }

  def root_account
    context && context.root_account
  end

  def name
    self.title
  end

  def name=(val)
    self.title = val
  end

  serialize :integration_data, Hash

  serialize :turnitin_settings, Hash
  
  # file extensions allowed for online_upload submission
  serialize :allowed_extensions, Array

  def allowed_extensions=(new_value)
    # allow both comma and whitespace as separator
    new_value = new_value.split(/[\s,]+/) if new_value.is_a?(String)

    # remove the . if they put it on, and extra whitespace
    new_value.map! { |v| v.strip.gsub(/\A\./, '').downcase } if new_value.is_a?(Array)

    write_attribute(:allowed_extensions, new_value)
  end

  before_save :infer_grading_type,
              :process_if_quiz,
              :default_values,
              :update_submissions_if_details_changed,
              :maintain_group_category_attribute,
              :validate_assignment_overrides

  after_save  :update_grades_if_details_changed,
              :touch_assignment_group,
              :touch_context,
              :update_grading_standard,
              :update_quiz_or_discussion_topic,
              :update_submissions_later,
              :schedule_do_auto_peer_review_job_if_automatic_peer_review,
              :delete_empty_abandoned_children,
              :update_cached_due_dates,
              :touch_submissions_if_muted

  has_a_broadcast_policy

  after_save :remove_assignment_updated_flag # this needs to be after has_a_broadcast_policy for the message to be sent

  def validate_assignment_overrides(opts={})
    if opts[:force_override_destroy] || group_category_id_changed?
      # needs to be .each(&:destroy) instead of .update_all(:workflow_state =>
      # 'deleted') so that the override gets versioned properly
      active_assignment_overrides.
        where(:set_type => 'Group').
        each { |o|
          o.dont_touch_assignment = true
          o.destroy
        }
    end

    AssignmentOverrideStudent.clean_up_for_assignment(self)
  end

  def schedule_do_auto_peer_review_job_if_automatic_peer_review
    return unless needs_auto_peer_reviews_scheduled?

    reviews_due_at = self.peer_reviews_assign_at || self.due_at
    return if reviews_due_at.blank?

    self.send_later_enqueue_args(:do_auto_peer_review, {
      :run_at => reviews_due_at,
      :singleton => Shard.birth.activate { "assignment:auto_peer_review:#{self.id}" }
    })
  end

  attr_accessor :skip_schedule_peer_reviews
  alias_method :skip_schedule_peer_reviews?, :skip_schedule_peer_reviews
  def needs_auto_peer_reviews_scheduled?
    !skip_schedule_peer_reviews? && peer_reviews? && automatic_peer_reviews? && !peer_reviews_assigned?
  end

  def do_auto_peer_review
    assign_peer_reviews if needs_auto_peer_reviews_scheduled? && overdue?
  end

  def touch_assignment_group
    AssignmentGroup.where(:id => self.assignment_group_id).update_all(:updated_at => Time.now.utc) if self.assignment_group_id
    true
  end

  def update_student_submissions
    graded_at = Time.zone.now
    submissions.graded.preload(:user).find_each do |s|
      if grading_type == 'pass_fail' && ['complete', 'pass'].include?(s.grade)
        s.score = points_possible
      end
      s.grade = score_to_grade(s.score, s.grade)
      s.graded_at = graded_at
      s.assignment = self
      s.assignment_changed_not_sub = true
      s.with_versioning(:explicit => true) { s.save! }
    end
  end

  # if a teacher changes the settings for an assignment and students have
  # already been graded, then we need to update the "grade" column to
  # reflect the changes
  def update_submissions_if_details_changed
    if !new_record? && (points_possible_changed? || grading_type_changed? || grading_standard_id_changed?) && !submissions.graded.empty?
      send_later_if_production(:update_student_submissions)
    end
    true
  end

  def update_grades_if_details_changed
    if points_possible_changed? || muted_changed? || workflow_state_changed?
      Rails.logger.info "GRADES: recalculating because assignment #{global_id} changed. (#{changes.inspect})"
      self.class.connection.after_transaction_commit { self.context.recompute_student_scores }
    end
    true
  end

  def create_in_turnitin
    return false unless self.context.turnitin_settings
    return true if self.turnitin_settings[:current]
    turnitin = Turnitin::Client.new(*self.context.turnitin_settings)
    res = turnitin.createOrUpdateAssignment(self, self.turnitin_settings)

    # make sure the defaults get serialized
    self.turnitin_settings = turnitin_settings

    if res[:assignment_id]
      self.turnitin_settings[:created] = true
      self.turnitin_settings[:current] = true
      self.turnitin_settings.delete(:error)
    else
      self.turnitin_settings[:error] = res
    end
    self.save
    return self.turnitin_settings[:current]
  end
  
  def create_in_vericite
    return false unless Canvas::Plugin.find(:vericite).try(:enabled?)
    return true if self.turnitin_settings[:current] && self.turnitin_settings[:vericite] 
    vericite = VeriCite::Client.new()
    res = vericite.createOrUpdateAssignment(self, self.turnitin_settings)

    # make sure the defaults get serialized
    self.turnitin_settings = turnitin_settings

    if res[:assignment_id]
      self.turnitin_settings[:created] = true
      self.turnitin_settings[:current] = true
      self.turnitin_settings[:vericite] = true
      self.turnitin_settings.delete(:error)
    else
      self.turnitin_settings[:error] = res
    end
    self.save
    return self.turnitin_settings[:current]
  end

  def turnitin_settings
    super.empty? ? Turnitin::Client.default_assignment_turnitin_settings : super
  end
  
  def vericite_settings
    turnitin_settings.empty? ? VeriCite::Client.default_assignment_vericite_settings : turnitin_settings
  end

  def turnitin_settings=(settings)
    settings = Turnitin::Client.normalize_assignment_turnitin_settings(settings)
    unless settings.blank?
      [:created, :error].each do |key|
        settings[key] = self.turnitin_settings[key] if self.turnitin_settings[key]
      end
    end
    write_attribute :turnitin_settings, settings
  end
  
  def vericite_settings=(settings)
    settings = VeriCite::Client.normalize_assignment_vericite_settings(settings)
    unless settings.blank?
      [:created, :error].each do |key|
        settings[key] = self.turnitin_settings[key] if self.turnitin_settings[key]
      end
    end
    write_attribute :turnitin_settings, settings
  end

  def self.all_day_interpretation(opts={})
    if opts[:due_at]
      if opts[:due_at] == opts[:due_at_was]
        # (comparison is modulo time zone) no real change, leave as was
        return opts[:all_day_was], opts[:all_day_date_was]
      else
        # 'normal' case. compare due_at to fancy midnight and extract its
        # date-part
        return (opts[:due_at].strftime("%H:%M") == '23:59'), opts[:due_at].to_date
      end
    else
      # no due at = all_day and all_day_date are irrelevant
      return nil, nil
    end
  end

  def default_values
    raise "Assignments can only be assigned to Course records" if self.context_type && self.context_type != "Course"
    self.context_code = "#{self.context_type.underscore}_#{self.context_id}"
    self.title ||= (self.assignment_group.default_assignment_name rescue nil) || "Assignment"
    self.grading_type = "pass_fail" if self.submission_types == "attendance"

    self.infer_all_day

    if !self.assignment_group || (self.assignment_group.deleted? && !self.deleted?)
      ensure_assignment_group(false)
    end
    self.submission_types ||= "none"
    self.peer_reviews_assign_at = [self.due_at, self.peer_reviews_assign_at].compact.max
    # have to use peer_reviews_due_at here because it's the column name
    self.peer_reviews_assigned = false if peer_reviews_due_at_changed?
    self.points_possible = nil if self.submission_types == 'not_graded'
  end
  protected :default_values

  def ensure_assignment_group(do_save = true)
    self.context.require_assignment_group
    assignment_groups = self.context.assignment_groups.active
    if !assignment_groups.map(&:id).include?(self.assignment_group_id)
      self.assignment_group = assignment_groups.first
      save! if do_save
    end
  end

  def attendance?
    submission_types == 'attendance'
  end

  def due_date
    self.all_day ? self.all_day_date : self.due_at
  end

  def delete_empty_abandoned_children
    if submission_types_changed?
      unless self.submission_types == 'discussion_topic'
        self.discussion_topic.unlink_from(:assignment) if self.discussion_topic
      end
      unless self.submission_types == 'online_quiz'
        self.quiz.unlink_from(:assignment) if self.quiz
      end
    end
  end

  def update_submissions_later
    if assignment_group_id_changed? && assignment_group_id_was.present?
      AssignmentGroup.where(id: assignment_group_id_was).update_all(updated_at: Time.now.utc)
    end
    self.assignment_group.touch if self.assignment_group
    if points_possible_changed?
      send_later_if_production(:update_submissions)
    end
  end

  attr_accessor :updated_submissions # for testing
  def update_submissions
    @updated_submissions ||= []
    self.submissions.find_each do |submission|
      @updated_submissions << submission
      submission.save!
    end
  end

  def update_quiz_or_discussion_topic
    return true if self.deleted?
    if self.submission_types == "online_quiz" && @saved_by != :quiz
      quiz = Quizzes::Quiz.where(assignment_id: self).first || self.context.quizzes.build
      quiz.assignment_id = self.id
      quiz.title = self.title
      quiz.description = self.description
      quiz.due_at = self.due_at
      quiz.unlock_at = self.unlock_at
      quiz.lock_at = self.lock_at
      quiz.points_possible = self.points_possible
      quiz.assignment_group_id = self.assignment_group_id
      quiz.workflow_state = 'created' if quiz.deleted?
      quiz.saved_by = :assignment
      quiz.workflow_state = published? ? 'available' : 'unpublished'
      quiz.save if quiz.changed?
    elsif self.submission_types == "discussion_topic" && @saved_by != :discussion_topic
      topic = self.discussion_topic || self.context.discussion_topics.build(:user => @updating_user)
      topic.assignment_id = self.id
      topic.title = self.title
      topic.message = self.description
      topic.saved_by = :assignment
      topic.updated_at = Time.now
      topic.workflow_state = 'active' if topic.deleted?
      topic.workflow_state = published? ? 'active' : 'unpublished'
      topic.save
      self.discussion_topic = topic
    end
  end
  attr_writer :saved_by

  def update_grading_standard
    self.grading_standard.save! if self.grading_standard
  end

  def all_context_module_tags
    all_tags = context_module_tags.to_a
    all_tags.concat(discussion_topic.context_module_tags) if discussion_topic?
    all_tags.concat(quiz.context_module_tags) if quiz?
    all_tags
  end

  def context_module_action(user, action, points=nil)
    all_context_module_tags.each { |tag| tag.context_module_action(user, action, points) }
  end

  # this is necessary to generate new permissions cache keys for students
  def touch_submissions_if_muted
    if muted_changed?
      self.class.connection.after_transaction_commit do
        submissions.touch_all
      end
    end
  end

  # call this to perform notifications on an Assignment that is not being saved
  # (useful when a batch of overrides associated with a new assignment have been saved)
  def do_notifications!(prior_version=nil, notify=false)
    self.prior_version = prior_version
    @broadcasted = false
    # TODO: this will blow up if the group_category string is set on the
    # previous version, because it gets confused between the db string field
    # and the association.  one more reason to drop the db column
    self.prior_version ||= self.versions.previous(self.current_version.number).try(:model)
    self.just_created = self.prior_version.nil?
    self.notify_of_update = notify || false
    broadcast_notifications
    remove_assignment_updated_flag
  end

  set_broadcast_policy do |p|
    p.dispatch :assignment_due_date_changed
    p.to { |assignment|
      # everyone who is _not_ covered by an assignment override affecting due_at
      # (the AssignmentOverride records will take care of notifying those users)
      excluded_ids = participants_with_overridden_due_at.map(&:id).to_set
      BroadcastPolicies::AssignmentParticipants.new(assignment, excluded_ids).to
    }
    p.whenever { |assignment|
      BroadcastPolicies::AssignmentPolicy.new(assignment).
        should_dispatch_assignment_due_date_changed?
    }

    p.dispatch :assignment_changed
    p.to { |assignment|
      BroadcastPolicies::AssignmentParticipants.new(assignment).to
    }
    p.whenever { |assignment|
      BroadcastPolicies::AssignmentPolicy.new(assignment).
        should_dispatch_assignment_changed?
    }

    p.dispatch :assignment_created
    p.to { |assignment|
      BroadcastPolicies::AssignmentParticipants.new(assignment).to
    }
    p.whenever { |assignment|
      BroadcastPolicies::AssignmentPolicy.new(assignment).
        should_dispatch_assignment_created?
    }
    p.filter_asset_by_recipient { |assignment, user|
      assignment.overridden_for(user)
    }

    p.dispatch :assignment_unmuted
    p.to { |assignment|
      BroadcastPolicies::AssignmentParticipants.new(assignment).to
    }
    p.whenever { |assignment|
      BroadcastPolicies::AssignmentPolicy.new(assignment).
        should_dispatch_assignment_unmuted?
    }
  end

  def notify_of_update=(val)
    @assignment_changed = Canvas::Plugin.value_to_boolean(val)
  end

  def notify_of_update
    false
  end

  def remove_assignment_updated_flag
    @assignment_changed = false
    true
  end

  def points_uneditable?
    (self.submission_types == 'online_quiz') # && self.quiz && (self.quiz.edited? || self.quiz.available?))
  end

  workflow do
    state :published do
      event :unpublish, :transitions_to => :unpublished
    end
    state :unpublished do
      event :publish, :transitions_to => :published
    end
    state :deleted
  end

  alias_method :destroy_permanently!, :destroy
  def destroy
    self.workflow_state = 'deleted'
    ContentTag.delete_for(self)
    self.rubric_association.destroy if self.rubric_association
    self.save!

    self.discussion_topic.destroy if self.discussion_topic && !self.discussion_topic.deleted?
    self.quiz.destroy if self.quiz && !self.quiz.deleted?
    refresh_course_content_participation_counts
  end

  def refresh_course_content_participation_counts
    progress = self.context.progresses.build(tag: 'refresh_content_participation_counts')
    progress.save!
    progress.process_job(self.context, :refresh_content_participation_counts)
  end

  def time_zone_edited
    CGI::unescapeHTML(read_attribute(:time_zone_edited) || "")
  end

  def restore(from=nil)
    self.workflow_state = self.has_student_submissions? ? "published" : "unpublished"
    self.save
    self.discussion_topic.restore(:assignment) if from != :discussion_topic && self.discussion_topic
    self.quiz.restore(:assignment) if from != :quiz && self.quiz
    refresh_course_content_participation_counts
  end

  def participants_with_overridden_due_at
    Assignment.participants_with_overridden_due_at([self])
  end

  def self.participants_with_overridden_due_at(assignments)
    overridden_users = []

    AssignmentOverride.active.overriding_due_at.where(assignment_id: assignments).each do |o|
      overridden_users.concat(o.applies_to_students)
    end

    overridden_users.uniq!
    overridden_users
  end

  def students_with_visibility(scope=context.all_students)
    return scope unless self.differentiated_assignments_applies?
    scope.able_to_see_assignment_in_course_with_da(self.id, context.id)
  end

  attr_accessor :saved_by
  def process_if_quiz
    if self.submission_types == "online_quiz"
      self.points_possible = quiz.points_possible if quiz && quiz.available?
      copy_attrs = %w(due_at lock_at unlock_at)
      if quiz && @saved_by != :quiz &&
         copy_attrs.any? { |attr| changes[attr] }
        copy_attrs.each { |attr| quiz.send "#{attr}=", send(attr) }
        quiz.saved_by = :assignment
        quiz.save
      end
    end
  end
  protected :process_if_quiz

  def grading_scheme
    grading_standard_or_default.grading_scheme
  end

  def infer_grading_type
    self.grading_type ||= "points"
  end

  def score_to_grade_percent(score=0.0)
    if points_possible && points_possible > 0
      result = score.to_f / self.points_possible
      result = (result * 1000.0).round / 10.0
    else
      # there's not really any reasonable value we can set here -- if the
      # assignment is worth no points, any percentage is as valid as any other.
      score.to_f
    end
  end

  def grading_standard_or_default
    grading_standard ||
      context.default_grading_standard ||
      GradingStandard.default_instance
  end

  def score_to_grade(score=0.0, given_grade=nil)
    result = score.to_f
    case self.grading_type
    when "percent"
      result = "#{score_to_grade_percent(score)}%"
    when "pass_fail"
      passed = if points_possible && points_possible > 0
                 score.to_f > 0
               elsif given_grade
                 given_grade == "complete" || given_grade == "pass"
               end
      result = passed ? "complete" : "incomplete"
    when "letter_grade", "gpa_scale"
      if self.points_possible.to_f > 0.0
        score = (BigDecimal.new(score.to_s) / BigDecimal.new(points_possible.to_s)).to_f
        result = grading_standard_or_default.score_to_grade(score * 100)
      elsif given_grade
        # the score for a zero-point letter_grade assignment could be considered
        # to be *any* grade, so look at what the current given grade is
        # instead of trying to calculate it
        result = given_grade
      else
        # there's not really any reasonable value we can set here -- if the
        # assignment is worth no points, and the grader didn't enter an
        # explicit letter grade, any letter grade is as valid as any other.
        result = grading_standard_or_default.score_to_grade(score.to_f)
      end
    end
    result.to_s
  end

  def interpret_grade(grade)
    case grade.to_s
    when %r{%$}
      # interpret as a percentage
      percentage = grade.to_f / 100.0
      points_possible.to_f * percentage
    when %r{[\d\.]+}
      if grading_type == "gpa_scale"
        # if it matches something in a scheme, take that, else return nil
        return nil unless standard_based_score = grading_standard_or_default.grade_to_score(grade)
        (points_possible || 0.0) * standard_based_score / 100.0
      else
        # interpret as a numerical score
        grade.to_f
      end
    when "pass", "complete"
      points_possible.to_f
    when "fail", "incomplete"
      0.0
    else
      # try to treat it as a letter grade
      if uses_grading_standard && standard_based_score = grading_standard_or_default.grade_to_score(grade)
        (points_possible || 0.0) * standard_based_score / 100.0
      else
        nil
      end
    end
  end

  def grade_to_score(grade=nil)
    return nil if grade.blank?
    parsed_grade = interpret_grade(grade)
    case self.grading_type
    when "points", "percent", "letter_grade", "gpa_scale"
      score = parsed_grade
    when "pass_fail"
      # only allow full points or no points for pass_fail assignments
      score = case parsed_grade.to_f
      when points_possible
        points_possible
      when 0.0
        0.0
      else
        nil
      end
    when "not_graded"
      score = nil
    else
      raise "oops, we need to interpret a new grading_type. get coding."
    end
    score
  end

  def uses_grading_standard
    ["letter_grade", "gpa_scale"].include? grading_type
  end

  def infer_times
    # set the time to 11:59 pm in the creator's time zone, if none given
    self.due_at = CanvasTime.fancy_midnight(self.due_at)
    self.lock_at = CanvasTime.fancy_midnight(self.lock_at)
  end

  def infer_all_day
    # make the comparison to "fancy midnight" and the date-part extraction in
    # the time zone that was active during editing
    time_zone = (ActiveSupport::TimeZone.new(self.time_zone_edited) rescue nil) || Time.zone
    self.all_day, self.all_day_date = Assignment.all_day_interpretation(
      :due_at => self.due_at ? self.due_at.in_time_zone(time_zone) : nil,
      :due_at_was => self.due_at_was,
      :all_day_was => self.all_day_was,
      :all_day_date_was => self.all_day_date_was)
  end

  def to_atom(opts={})
    extend ApplicationHelper
    author_name = self.context.present? ? self.context.name : t('atom_no_author', "No Author")
    Atom::Entry.new do |entry|
      entry.title     = t(:feed_entry_title, "Assignment: %{assignment}", :assignment => self.title) unless opts[:include_context]
      entry.title     = t(:feed_entry_title_with_course, "Assignment, %{course}: %{assignment}", :assignment => self.title, :course => self.context.name) if opts[:include_context]
      entry.authors  << Atom::Person.new(:name => author_name)
      entry.updated   = self.updated_at.utc
      entry.published = self.created_at.utc
      entry.id        = "tag:#{HostUrl.default_host},#{self.created_at.strftime("%Y-%m-%d")}:/assignments/#{self.feed_code}_#{self.due_at.strftime("%Y-%m-%d-%H-%M") rescue "none"}"
      entry.links    << Atom::Link.new(:rel => 'alternate',
                                    :href => "http://#{HostUrl.context_host(self.context)}/#{context_url_prefix}/assignments/#{self.id}")
      entry.content   = Atom::Content::Html.new(before_label(:due, "Due") + " #{datetime_string(self.due_at, :due_date)}<br/>#{self.description}<br/><br/>
        <div>
          #{self.description}
        </div>
      ")
    end
  end

  def start_at
    due_at
  end

  def end_at
    due_at
  end

  def context_prefix
    context_url_prefix
  end

  def to_ics(in_own_calendar: true, preloaded_attachments: {}, user: nil)
    CalendarEvent::IcalEvent.new(self).to_ics(in_own_calendar:       in_own_calendar,
                                              preloaded_attachments: preloaded_attachments,
                                              include_description:   include_description?(user))
  end

  def include_description?(user)
    user && !self.locked_for?(user, :check_policies => true)
  end

  def all_day
    read_attribute(:all_day) || (self.new_record? && self.due_at && (self.due_at.strftime("%H:%M") == '23:59' || self.due_at.strftime("%H:%M") == '00:00'))
  end

  def self.preload_context_module_tags(assignments, include_context_modules: false)
    module_tags_include =
      if include_context_modules
        { context_module_tags: :context_module }
      else
        :context_module_tags
      end

    ActiveRecord::Associations::Preloader.new.preload(assignments, [
      module_tags_include,
      { :discussion_topic => :context_module_tags },
      { :quiz => :context_module_tags }
    ])
  end

  def locked_for?(user, opts={})
    return false if opts[:check_policies] && context.grants_right?(user, :read_as_admin)
    Rails.cache.fetch(locked_cache_key(user), :expires_in => 1.minute) do
      locked = false
      assignment_for_user = self.overridden_for(user)
      if (assignment_for_user.unlock_at && assignment_for_user.unlock_at > Time.now)
        locked = {:asset_string => assignment_for_user.asset_string, :unlock_at => assignment_for_user.unlock_at}
      elsif (assignment_for_user.lock_at && assignment_for_user.lock_at < Time.now)
        locked = {:asset_string => assignment_for_user.asset_string, :lock_at => assignment_for_user.lock_at, :can_view => true}
      elsif self.could_be_locked && item = locked_by_module_item?(user, opts[:deep_check_if_needed])
        locked = {:asset_string => self.asset_string, :context_module => item.context_module.attributes}
      elsif self.submission_types == 'discussion_topic' && self.discussion_topic &&
          topic_locked = self.discussion_topic.locked_for?(user, opts.merge(:skip_assignment => true))
        locked = topic_locked
      elsif self.submission_types == 'online_quiz' && self.quiz &&
          quiz_locked = self.quiz.locked_for?(user, opts.merge(:skip_assignment => true))
        locked = quiz_locked
      end
      locked
    end
  end

  def clear_locked_cache(user)
    super
    Rails.cache.delete(discussion_topic.locked_cache_key(user)) if self.submission_types == 'discussion_topic' && discussion_topic
    Rails.cache.delete(quiz.locked_cache_key(user)) if self.submission_types == 'online_quiz' && quiz
  end

  def submission_types_array
    (self.submission_types || "").split(",")
  end

  def submittable_type?
    submission_types && self.submission_types != "" && self.submission_types != "none" && self.submission_types != 'not_graded' && self.submission_types != "online_quiz" && self.submission_types != 'discussion_topic' && self.submission_types != 'attendance' && self.submission_types != "external_tool"
  end

  def graded_count
    return read_attribute(:graded_count).to_i if read_attribute(:graded_count)
    Rails.cache.fetch(['graded_count', self].cache_key) do
      submissions.graded.in_workflow_state('graded').count
    end
  end

  def has_submitted_submissions?
    return @has_submitted_submissions unless @has_submitted_submissions.nil?
    submitted_count > 0
  end
  attr_writer :has_submitted_submissions

  def submitted_count
    return read_attribute(:submitted_count).to_i if read_attribute(:submitted_count)
    Rails.cache.fetch(['submitted_count', self].cache_key) do
      self.submissions.having_submission.count
    end
  end

  set_policy do
    given { |user, session| self.context.grants_right?(user, session, :read) && self.published? }
    can :read and can :read_own_submission

    given { |user, session|
      (submittable_type? || submission_types == "discussion_topic") &&
      context.grants_right?(user, session, :participate_as_student) &&
      !locked_for?(user) &&
      visible_to_user?(user) &&
      !excused_for?(user)
    }
    can :submit and can :attach_submission_comment_files

    given { |user, session| self.context.grants_right?(user, session, :read_as_admin) }
    can :read

    given { |user, session| self.context.grants_right?(user, session, :manage_grades) }
    can :grade and can :attach_submission_comment_files

    given { |user, session| self.context.grants_right?(user, session, :manage_assignments) }
    can :update and can :delete and can :create and can :read and can :attach_submission_comment_files
  end

  def user_can_read_grades?(user, session=nil)
    RequestCache.cache('user_can_read_grades', self, user, session) do
      self.context.grants_right?(user, session, :view_all_grades) ||
        (self.published? && self.context.grants_right?(user, session, :manage_grades))
    end
  end

  def filter_attributes_for_user(hash, user, session)
    if lock_info = self.locked_for?(user, :check_policies => true)
      hash.delete('description')
      hash['lock_info'] = lock_info
    end
  end

  def participants(opts={})
    return context.participants(opts[:include_observers], excluded_user_ids: opts[:excluded_user_ids]) unless differentiated_assignments_applies?
    participants_with_visibility(opts)
  end

  def participants_with_visibility(opts={})
    users = context.participating_admins

    applicable_students = if opts[:excluded_user_ids]
                            students_with_visibility.reject{|s| opts[:excluded_user_ids].include?(s.id)}
                          else
                            students_with_visibility
                          end

    users += applicable_students

    if opts[:include_observers]
      users += User.observing_students_in_course(applicable_students.map(&:id), self.context_id)
      users += User.observing_full_course(context.id)
    end

    users.uniq
  end

  def set_default_grade(options={})
    score = self.grade_to_score(options[:default_grade])
    grade = self.score_to_grade(score)
    submissions_to_save = []
    self.context.students.find_in_batches do |students|
      submissions = find_or_create_submissions(students)
      submissions_to_save.concat(submissions.select  { !submissions.score || (options[:overwrite_existing_grades] && submissions.score != score) })
    end

    Submission.where(:id => submissions_to_save).update_all({
      :score => score,
      :grade => grade,
      :published_score => score,
      :published_grade => grade,
      :workflow_state => 'graded',
      :graded_at => Time.now.utc
    }) unless submissions_to_save.empty?

    Rails.logger.info "GRADES: recalculating because assignment #{global_id} had default grade set (#{options.inspect})"
    self.context.recompute_student_scores
    student_ids = context.student_ids
    send_later_if_production(:multiple_module_actions, student_ids, :scored, score)
  end

  def title_with_id
    "#{title} (#{id})"
  end

  def title_slug
    CanvasTextHelper.truncate_text(title, :ellipsis => '')
  end

  def self.title_and_id(str)
    if str =~ /\A(.*)\s\((\d+)\)\z/
      [$1, $2]
    else
      [str, nil]
    end
  end

  def group_students(student)
    group = nil
    students = [student]
    if has_group_category? && group = group_category.group_for(student)
      students = group.users
        .joins(:enrollments)
        .where(:enrollments => { :course_id => self.context})
        .merge(Course.instance_exec(&Course.reflections[CANVAS_RAILS4_0 ? :student_enrollments : 'student_enrollments'].scope).only(:where))
        .order("users.id") # this helps with preventing deadlock with other things that touch lots of users
        .uniq
        .to_a
    end
    [group, students]
  end

  def multiple_module_actions(student_ids, action, points=nil)
    students = self.context.students.where(id: student_ids)
    students.each do |user|
      self.context_module_action(user, action, points)
    end
  end

  def submission_for_student(user)
    self.submissions.where(user_id: user.id).first_or_initialize
  end

  class GradeError < StandardError; end

  def compute_grade_and_score(grade, score)
    if grade
      score = self.grade_to_score(grade)
    end
    if score
      grade = self.score_to_grade(score, grade)
    end
    [grade, score]
  end

  def grade_student(original_student, opts={})
    raise GradeError.new("Student is required") unless original_student
    unless context.includes_user?(original_student, context.admin_visible_student_enrollments) # allows inactive users to be graded
      raise GradeError.new("Student must be enrolled in the course as a student to be graded")
    end
    raise GradeError.new("Grader must be enrolled as a course admin") if opts[:grader] && !self.context.grants_right?(opts[:grader], :manage_grades)

    if opts.key? :excuse
      opts[:excused] = Canvas::Plugin.value_to_boolean(opts.delete(:excuse))
    end
    raise GradeError.new("Cannot simultaneously grade and excuse an assignment") if opts[:excused] && (opts[:grade] || opts[:score])
    raise GradeError.new("Provisional grades require a grader") if opts[:provisional] && opts[:grader].nil?

    opts.delete(:id)
    dont_overwrite_grade = opts.delete(:dont_overwrite_grade)
    group_comment = Canvas::Plugin.value_to_boolean(opts.delete(:group_comment))
    group, students = group_students(original_student)
    grader = opts.delete :grader
    grade, score = compute_grade_and_score(opts.delete(:grade), opts.delete(:score))
    comment = {
      :comment => (opts.delete :comment),
      :attachments => (opts.delete :comment_attachments),
      :author => grader,
      :media_comment_id => (opts.delete :media_comment_id),
      :media_comment_type => (opts.delete :media_comment_type),
      :hidden => muted?,
    }
    comment[:provisional] = true if opts[:provisional]
    comment[:final] = true if opts[:final]
    comment[:group_comment_id] = CanvasSlug.generate_securish_uuid if group_comment && group
    submissions = []


    grade_group_students = !(grade_group_students_individually || opts[:excused])

    find_or_create_submissions(students) do |submission|
      submission_updated = false
      submission.skip_grade_calc = opts[:skip_grade_calc]
      student = submission.user
      if student == original_student || grade_group_students
        previously_graded = submission.grade.present? || submission.excused?
        next if previously_graded && dont_overwrite_grade
        next if student != original_student && submission.excused?

        did_grade = false
        submission.attributes = opts.slice(:excused, :submission_type, :url, :body)
        submission.assignment = self
        submission.user = student

        unless opts[:provisional]
          submission.grader = grader
          submission.grade = grade
          submission.score = score
          submission.graded_anonymously = opts[:graded_anonymously] if opts.key?(:graded_anonymously)
          submission.excused = false if score.present?
          did_grade = true if score.present? || submission.excused?
        end

        submission.grade_matches_current_submission = true if did_grade

        if submission.changes.except(*%w{user_id assignment_id}).values.flatten.any?(&:present?)
          # changing turnitin_data from nil to {} doesn't count
          submission_updated = true
        end

        if (submission.score_changed? ||
            submission.grade_matches_current_submission) &&
            ((submission.score && submission.grade) || submission.excused?)
          submission.workflow_state = "graded"
        end
        submission.group = group
        submission.graded_at = Time.zone.now if did_grade
        previously_graded ? submission.with_versioning(:explicit => true) { submission.save! } : submission.save!

        if opts[:provisional]
          submission.find_or_create_provisional_grade!(scorer: grader, grade: grade, score: score, force_save: true, final: opts[:final])
        end
      end
      submission.add_comment(comment) if comment && (group_comment || student == original_student)
      submissions << submission if group_comment || student == original_student || submission_updated
    end

    submissions
  end

  def find_or_create_submission(user)
    Assignment.unique_constraint_retry do
      s = submissions.where(user_id: user).first
      if !s
        s = submissions.build
        user.is_a?(User) ? s.user = user : s.user_id = user
        s.save!
      end
      s
    end
  end

  def find_or_create_submissions(students)
    submissions = self.submissions.where(user_id: students).order(:user_id).to_a
    submissions_hash = submissions.index_by(&:user_id)
    # we touch the user in an after_save; the FK causes a read lock
    # to be taken on the user during submission INSERT, so to avoid
    # deadlocks, we pre-lock the users
    needs_lock = false
    shard.activate do
      if Submission.connection.adapter_name == 'PostgreSQL' && Submission.connection.send(:postgresql_version) < 90300
        needs_lock = Submission.connection.open_transactions == 0
        # we're already in a transaction, and can lock everyone at once
        if !needs_lock
          missing_users = students.map(&:id) - submissions_hash.keys
          User.shard(shard).where(id: missing_users).order(:id).lock.pluck(:id)
        end
      end
    end
    students.each do |student|
      submission = submissions_hash[student.id]
      if !submission
        begin
          transaction(requires_new: true) do
            # lock just one user
            if needs_lock
              User.shard(shard).where(id: student).lock.pluck(:id)
            end
            submission = self.submissions.build(user: student)
            submission.assignment = self
            yield submission if block_given?
            submission.save! if submission.changed?
            submissions << submission
          end
        rescue ActiveRecord::RecordNotUnique
          submission = self.submissions.where(user_id: student).first
          raise unless submission
          submissions << submission
          submission.assignment = self
          submission.user = student
          yield submission if block_given?
        end
      else
        submission.assignment = self
        submission.user = student
        yield submission if block_given?
      end
    end
    submissions
  end

  def find_asset_for_assessment(association, user_or_user_id, opts={})
    user = user_or_user_id.is_a?(User) ? user_or_user_id : self.context.users.where(id: user_or_user_id).first
    if association.purpose == "grading"
      if user
        sub = self.find_or_create_submission(user)
        if opts[:provisional_grader]
          [sub.find_or_create_provisional_grade!(:scorer => opts[:provisional_grader], :final => opts[:final]), user]
        else
          [sub, user]
        end
      else
        [nil, nil]
      end
    else
      [self, user]
    end
  end

  # Update at this point is solely used for commenting on the submission
  def update_submission(original_student, opts={})
    raise "Student Required" unless original_student
    submission = submissions.where(user_id: original_student).first
    res = []
    raise "No submission found for that student" unless submission
    group, students = group_students(original_student)
    opts[:author] ||= opts[:commenter] || opts[:user_id].present? && User.where(id: opts[:user_id]).first

    if opts[:comment] && opts[:assessment_request]
      # if there is no rubric the peer review is complete with just a comment
      opts[:assessment_request].complete unless opts[:assessment_request].rubric_association
    end

    if opts[:comment] && Canvas::Plugin.value_to_boolean(opts[:group_comment])
      uuid = CanvasSlug.generate_securish_uuid
      res = find_or_create_submissions(students) do |s|
        s.group = group
        s.save! if s.changed?
        opts[:group_comment_id] = uuid if group
        s.add_comment(opts)
        # SubmissionComment updates the submission directly in the db
        # in an after_save, and Rails doesn't preload the reverse association
        # on new objects so it can't set it on this object
        s.reload
      end
    else
      s = find_or_create_submission(original_student)
      s.group = group
      s.save! if s.changed?
      s.add_comment(opts)
      s.reload
      res = [s]
    end
    res
  end

  SUBMIT_HOMEWORK_ATTRS = %w[body url submission_type
                             media_comment_id media_comment_type]
  ALLOWABLE_SUBMIT_HOMEWORK_OPTS = (SUBMIT_HOMEWORK_ATTRS +
                                    %w[comment group_comment attachments]).to_set

  def submit_homework(original_student, opts={})
    # Only allow a few fields to be submitted.  Cannot submit the grade of a
    # homework assignment, for instance.
    opts.keys.each { |k|
      opts.delete(k) unless ALLOWABLE_SUBMIT_HOMEWORK_OPTS.include?(k.to_s)
    }
    raise "Student Required" unless original_student
    comment = opts.delete(:comment)
    group_comment = opts.delete(:group_comment)
    group, students = group_students(original_student)
    homeworks = []
    primary_homework = nil
    submitted = case opts[:submission_type]
                when "online_text_entry"
                  opts[:body].present?
                when "online_url"
                  opts[:url].present?
                when "online_upload"
                  opts[:attachments].size > 0
                else
                  true
                end
    transaction do
      find_or_create_submissions(students) do |homework|
        # clear out attributes from prior submissions
        if opts[:submission_type].present?
          SUBMIT_HOMEWORK_ATTRS.each { |attr| homework[attr] = nil }
        end

        student = homework.user
        homework.grade_matches_current_submission = homework.score ? false : true
        homework.attributes = opts.merge({
          :attachment => nil,
          :processed => false,
          :process_attempts => 0,
          :workflow_state => submitted ? "submitted" : "unsubmitted",
          :group => group
        })
        homework.submitted_at = Time.now

        homework.with_versioning(:explicit => (homework.submission_type != "discussion_topic")) do
          if group
            if student == original_student
              homework.broadcast_group_submission
            else
              homework.save_without_broadcasting!
            end
          else
            homework.save!
          end
        end
        homeworks << homework
        primary_homework = homework if student == original_student
      end
    end
    homeworks.each do |homework|
      context_module_action(homework.student, homework.workflow_state.to_sym)
      if comment && (group_comment || homework == primary_homework)
        hash = {:comment => comment, :author => original_student}
        hash[:group_comment_id] = CanvasSlug.generate_securish_uuid if group_comment && group
        homework.add_comment(hash)
      end
    end
    touch_context
    return primary_homework
  end

  def submissions_downloaded?
    self.submissions_downloads && self.submissions_downloads > 0
  end

  def serializable_hash(opts = {})
    super(opts.reverse_merge include_root: true)
  end

  def as_json(options={})
    json = super(options)
    if json && json['assignment']
      # remove anything coming automatically from deprecated db column
      json['assignment'].delete('group_category')
      if self.group_category
        # put back version from association
        json['assignment']['group_category'] = self.group_category.name
      elsif self.read_attribute('group_category').present?
        # or failing that, version from query
        json['assignment']['group_category'] = self.read_attribute('group_category')
      end
    end
    json
  end

  def grades_published?
    !moderated_grading? || grades_published_at.present?
  end

  def student_needs_provisional_grade?(student, preloaded_counts=nil)
    pg_count = if preloaded_counts
      preloaded_counts[student.id.to_s] || 0
    else
      self.provisional_grades.not_final.where(:submissions => {:user_id => student}).count
    end
    in_moderation_set = if self.moderated_grading_selections.loaded?
      self.moderated_grading_selections.detect{|s| s.student_id == student.id}.present?
    else
      self.moderated_grading_selections.where(:student_id => student).exists?
    end
    pg_count < (in_moderation_set ? 2 : 1)
  end

  def speed_grader_json(user, avatars: false, grading_role: :grader)
    Attachment.skip_thumbnails = true
    submission_fields = [:user_id, :id, :submitted_at, :workflow_state,
                         :grade, :grade_matches_current_submission,
                         :graded_at, :turnitin_data, :submission_type, :score,
                         :assignment_id, :submission_comments, :excused, :updated_at].freeze

    comment_fields = [:comment, :id, :author_name, :created_at, :author_id,
                      :media_comment_type, :media_comment_id,
                      :cached_attachments, :attachments].freeze

    attachment_fields = [:id, :comment_id, :content_type, :context_id, :context_type,
                         :display_name, :filename, :mime_class,
                         :size, :submitter_id, :workflow_state, :viewed_at].freeze

    res = as_json(
      :include => {
        :context => { :only => :id },
        :rubric_association => { :except => {} }
      },
      :include_root => false
    )

    # include :provisional here someday if we need to distinguish between provisional and real comments
    # (also in SubmissionComment#serialization_methods)
    submission_comment_methods = []
    submission_comment_methods << :avatar_path if avatars && !grade_as_group?

    res[:context][:rep_for_student] = {}

    students = representatives(user) do |rep, others|
      others.each { |s|
        res[:context][:rep_for_student][s.id] = rep.id
      }
    end

    enrollments = context.apply_enrollment_visibility(context.student_enrollments, user)

    is_provisional = grading_role == :provisional_grader || grading_role == :moderator
    rubric_assmnts = visible_rubric_assessments_for(user, :provisional_grader => is_provisional) || []

    # include all the rubric assessments if a moderator
    all_provisional_rubric_assmnts = grading_role == :moderator &&
      (visible_rubric_assessments_for(user, :provisional_moderator => true) || [])

    # if we're a provisional grader, calculate whether the student needs a grade
    preloaded_pg_counts = is_provisional && self.provisional_grades.not_final.group("submissions.user_id").count
    ActiveRecord::Associations::Preloader.new.preload(self, :moderated_grading_selections) if is_provisional # preload the association now

    res[:context][:students] = students.map do |u|
      json = u.as_json(:include_root => false,
                :methods => submission_comment_methods,
                :only => [:name, :id])

      if preloaded_pg_counts
        json[:needs_provisional_grade] = student_needs_provisional_grade?(u, preloaded_pg_counts)
      end

      json[:rubric_assessments] = rubric_assmnts.select{|ra| ra.user_id == u.id}.
        as_json(:methods => [:assessor_name], :include_root => false)

      json
    end

    res[:context][:active_course_sections] = context.sections_visible_to(user, self.sections_with_visibility(user)).
      map{|s| s.as_json(:include_root => false, :only => [:id, :name]) }
    res[:context][:enrollments] = enrollments.
        map{|s| s.as_json(:include_root => false, :only => [:user_id, :course_section_id]) }
    res[:context][:quiz] = self.quiz.as_json(:include_root => false, :only => [:anonymous_submissions])

    includes = [:versions, :quiz_submission, :user]
    includes << (grading_role == :grader ? :submission_comments : :all_submission_comments)
    submissions = self.submissions.where(:user_id => students).preload(*includes)

    preloaded_prov_grades = case grading_role
    when :moderator
      self.provisional_grades.order(:id).to_a.group_by(&:submission_id)
    when :provisional_grader
      self.provisional_grades.not_final.where(:scorer_id => user).order(:id).to_a.group_by(&:submission_id)
    else
      {}
    end

    preloaded_prov_selections = grading_role == :moderator ? self.moderated_grading_selections.index_by(&:student_id) : []

    res[:too_many_quiz_submissions] = too_many = too_many_qs_versions?(submissions)
    qs_versions = quiz_submission_versions(submissions, too_many)

    enrollment_types_by_id = enrollments.inject({}){ |h, e| h[e.user_id] ||= e.type; h }

    res[:submissions] = submissions.map do |sub|
      json = sub.as_json(:include_root => false,
        :methods => [:submission_history, :late],
        :only => submission_fields
      ).merge("from_enrollment_type" => enrollment_types_by_id[sub.user_id])

      if grading_role == :provisional_grader || grading_role == :moderator
        provisional_grade = sub.provisional_grade(user, preloaded_grades: preloaded_prov_grades)
        json.merge! provisional_grade.grade_attributes
      end

      comments = (provisional_grade || sub).submission_comments
      if grade_as_group?
        comments = comments.reject { |comment| comment.group_comment_id.nil? }
      end

      json[:submission_comments] = comments.as_json(
        include_root: false,
        methods: submission_comment_methods,
        only: comment_fields
      )

      json['attachments'] = sub.attachments.map{|att| att.as_json(
          :only => [:mime_class, :comment_id, :id, :submitter_id ]
      )}

      sub_attachments = []

      crocodoc_user_ids = if is_provisional
        [sub.user.crocodoc_id!, user.crocodoc_id!]
      else
        sub.crocodoc_whitelist
      end

      json['submission_history'] = if json['submission_history'] && (quiz.nil? || too_many)
                                     json['submission_history'].map do |version|
                                       version.as_json(
                                         :only => submission_fields,
                                         :methods => [:versioned_attachments, :late]
                                       ).tap do |version_json|
                                         if version_json['submission'] && version_json['submission']['versioned_attachments']
                                           version_json['submission']['versioned_attachments'].map! do |a|
                                             if grading_role == :moderator
                                                sub_attachments << a # we'll use to create custom crocodoc urls for each prov grade
                                             end
                                             a.as_json(
                                               :only => attachment_fields,
                                               :methods => [:view_inline_ping_url]
                                             ).tap { |json|
                                               json[:attachment][:canvadoc_url] = a.canvadoc_url(user)
                                               json[:attachment][:crocodoc_url] =  a.crocodoc_url(user, crocodoc_user_ids)
                                               json[:attachment][:submitted_to_crocodoc] = a.crocodoc_document.present?
                                             }
                                           end
                                         end
                                       end
                                     end
                                   elsif quiz && sub.quiz_submission
                                     qs_versions[sub.quiz_submission.id].map do |v|
                                       qs = v.model
                                       # copy already-loaded associations over to the
                                       # model so we don't have to load them again
                                       # when qs.late? gets called
                                       qs.quiz = quiz
                                       qs.submission = sub

                                       {submission: {
                                         grade: qs.score,
                                         show_grade_in_dropdown: true,
                                         submitted_at: qs.finished_at,
                                         late: qs.late?,
                                         version: v.number,
                                       }}
                                     end
                                   end

      if grading_role == :moderator
        pgs = preloaded_prov_grades[sub.id] || []
        selection = preloaded_prov_selections[sub.user.id]
        unless pgs.count == 0 || (pgs.count == 1 && pgs.first.scorer_id == user.id)
          json['provisional_grades'] = []
          pgs.each do |pg|
            pg_json = pg.grade_attributes.tap do |json|
              json[:rubric_assessments] = all_provisional_rubric_assmnts.select{|ra| ra.artifact_id == pg.id}.
                as_json(:methods => [:assessor_name], :include_root => false)

              json[:selected] = !!(selection && selection.selected_provisional_grade_id == pg.id)
              json[:crocodoc_urls] = sub_attachments.map { |a| pg.crocodoc_attachment_info(user, a) }
              json[:readonly] = !pg.final && (pg.scorer_id != user.id)
              json[:submission_comments] = pg.submission_comments.as_json(:include_root => false,
                                                                          :methods => submission_comment_methods,
                                                                          :only => comment_fields)
            end

            if pg.final
              json['final_provisional_grade'] = pg_json
            else
              json['provisional_grades'] << pg_json
            end
          end
        end
      end

      json
    end
    res[:GROUP_GRADING_MODE] = grade_as_group?
    res
  ensure
    Attachment.skip_thumbnails = nil
  end

  def sections_with_visibility(user)
    return context.active_course_sections unless self.differentiated_assignments_applies?

    visible_student_ids = visible_students_for_speed_grader(user).map(&:id)
    context.active_course_sections.joins(:student_enrollments).
      where(:enrollments => {:user_id => visible_student_ids, :type => "StudentEnrollment"}).uniq.reorder("name")
  end

  # quiz submission versions are too expensive to de-serialize so we have to
  # cap the number we will do
  def too_many_qs_versions?(student_submissions)
    qs_threshold = Setting.get("too_many_quiz_submission_versions", "150").to_i
    qs_threshold <= student_submissions.inject(0) do |sum, s|
      s.quiz_submission ? sum + s.quiz_submission.versions.size : sum
    end
  end

  # :including quiz submission versions won't work for records in the
  # database before namespace changes. This does a bulk pre-query to prevent
  # n+1 queries. replace this with an :include again after namespaced
  # polymorphic data is migrated
  def quiz_submission_versions(student_submissions, too_many_qs_versions)
    submissions_with_qs = student_submissions.select do |sub|
      quiz && sub.quiz_submission && !too_many_qs_versions
    end
    qs_versions = Version.where(versionable_type: 'Quizzes::QuizSubmission',
                                versionable_id: submissions_with_qs.map(&:quiz_submission)).
                          order(:number)

    qs_versions.each_with_object({}) do |version, hash|
      hash[version.versionable_id] ||= []
      hash[version.versionable_id] << version
    end
  end

  def grade_as_group?
    has_group_category? && !grade_group_students_individually?
  end

  # for group assignments, returns a single "student" for each
  # group's submission.  the students name will be changed to the group's
  # name.  for non-group assignments this just returns all visible users
  def representatives(user)
    if grade_as_group?
      submissions = self.submissions.preload(:user).to_a
      users_with_submissions = submissions.select(&:has_submission?).map(&:user)
      users_with_turnitin_data = if turnitin_enabled?
                                   submissions
                                   .reject { |s| s.turnitin_data.blank? }
                                   .map(&:user)
                                 else
                                   []
                                 end
      users_with_vericite_data = if vericite_enabled?
                                   submissions
                                   .reject { |s| s.turnitin_data.blank? }
                                   .map(&:user)
                                 else
                                   []
                                 end
      users_who_arent_excused = submissions.reject(&:excused?).map(&:user)
      reps_and_others = groups_and_ungrouped(user).map { |group_name, group_students|
        visible_group_students = group_students & visible_students_for_speed_grader(user)
        candidate_students = visible_group_students & users_who_arent_excused
        candidate_students = visible_group_students if candidate_students.empty?

        representative   = (candidate_students & (users_with_turnitin_data || users_with_vericite_data)).first
        representative ||= (candidate_students & users_with_submissions).first
        representative ||= candidate_students.first
        others = visible_group_students - [representative]
        next unless representative

        representative.readonly!
        representative.name = group_name
        representative.sortable_name = group_name
        representative.short_name = group_name

        [representative, others]
      }.compact

      sorted_reps_with_others = Canvas::ICU.collate_by(reps_and_others) { |rep, _|
      rep.sortable_name }
      if block_given?
        sorted_reps_with_others.each { |r,o| yield r, o }
      end
      sorted_reps_with_others.map &:first
    else
      visible_students_for_speed_grader(user)
    end
  end

  def groups_and_ungrouped(user)
    groups_and_users = group_category.
      groups.active.preload(group_memberships: :user).
      map { |g| [g.name, g.users] }
    users_in_group = groups_and_users.flat_map { |_,users| users }
    groupless_users = visible_students_for_speed_grader(user) - users_in_group
    phony_groups = groupless_users.map { |u| [u.name, [u]] }
    groups_and_users + phony_groups
  end
  private :groups_and_ungrouped

  # using this method instead of students_with_visibility so we
  # can add the includes and students_visible_to/participating_students scopes
  def visible_students_for_speed_grader(user)
    @visible_students_for_speed_grader ||= {}
    @visible_students_for_speed_grader[user.global_id] ||= (
      student_scope = user ? context.students_visible_to(user, include: :inactive) : context.participating_students
      students_with_visibility(student_scope)
    ).order_by_sortable_name.uniq.to_a
  end

  def visible_rubric_assessments_for(user, opts={})
    return [] unless user && self.rubric_association

    scope = self.rubric_association.rubric_assessments.preload(:assessor)

    if opts[:provisional_grader]
      scope = scope.for_provisional_grades.where(:assessor_id => user.id)
    elsif opts[:provisional_moderator]
      scope = scope.for_provisional_grades
    else
      scope = scope.for_submissions
      unless self.rubric_association.grants_any_right?(user, :manage, :view_rubric_assessments)
        scope = scope.where(:assessor_id => user.id)
      end
    end
    scope.to_a.sort_by{|a| [a.assessment_type == 'grading' ? CanvasSort::First : CanvasSort::Last, Canvas::ICU.collation_key(a.assessor_name)] }
  end

  # Takes a zipped file full of assignment comments/annotated assignments
  # and generates comments on each assignment's submission.  Quietly
  # ignore (for now) files that don't make sense to us.  The convention
  # for file naming (how we're sending it down to the teacher) is
  # last_name_first_name_user_id_attachment_id.
  # extension
  def generate_comments_from_files(filename, commenter)
    zip_extractor = ZipExtractor.new(filename)
    # Creates a list of hashes, each one with a :user, :filename, and :submission entry.
    @ignored_files = []
    file_map = zip_extractor.unzip_files.map { |f| infer_comment_context_from_filename(f) }.compact
    files_for_user = file_map.group_by { |f| f[:user] }
    comments = files_for_user.map do |user, files|
      attachments = files.map { |g|
        FileInContext.attach(self, g[:filename], g[:display_name])
      }
      comment = {
        comment: t(:comment_from_files, {one: "See attached file", other: "See attached files"}, count: files.size),
        author: commenter,
        hidden: muted?,
        attachments: attachments,
      }
      group, students = group_students(user)
      comment[:group_comment_id] = CanvasSlug.generate_securish_uuid if group
      find_or_create_submissions(students).map do |submission|
        submission.add_comment(comment)
      end
    end
    [comments.compact, @ignored_files]
  end

  def group_category_name
    self.read_attribute(:group_category)
  end

  def maintain_group_category_attribute
    # keep this field up to date even though it's not used (group_category_name
    # exists solely for the migration that introduces the GroupCategory model).
    # this way group_category_name is correct if someone mistakenly uses it
    # (modulo category renaming in the GroupCategory model).
    self.write_attribute(:group_category, self.group_category && self.group_category.name)
  end

  def has_group_category?
    self.group_category_id.present?
  end

  def assign_peer_review(reviewer, reviewee)
    reviewer_submission = self.find_or_create_submission(reviewer)
    reviewee_submission = self.find_or_create_submission(reviewee)
    reviewee_submission.assign_assessor(reviewer_submission)
  end

  def assign_peer_reviews
    return [] unless self.peer_review_count && self.peer_review_count > 0

    submissions = self.submissions.having_submission.include_assessment_requests
    student_ids = students_with_visibility(context.students.not_fake_student).pluck(:id)

    submissions = submissions.select{|s| student_ids.include?(s.user_id) }
    submission_ids = Set.new(submissions) { |s| s.id }

    # there could be any conceivable configuration of peer reviews already
    # assigned when this method is called, since teachers can assign individual
    # reviews manually and change peer_review_count at any time. so we can't
    # make many assumptions. that's where most of the complexity here comes
    # from.

    # we track existing assessment requests, and the ones we create here, so
    # that we don't have to constantly re-query the db.
    assessor_id_map = {}
    submissions.each do |s|
      assessor_id_map[s.id] = s.assessment_requests.map(&:assessor_asset_id)
    end
    res = []

    # for each submission that needs to do more assessments...
    # we sort the submissions randomly so that if there aren't enough
    # submissions still needing reviews, it's random who gets the duplicate
    # reviews.
    submissions.sort_by { rand }.each do |submission|
      existing = submission.assigned_assessments
      needed = self.peer_review_count - existing.size
      next if needed <= 0

      # candidate_set is all submissions for the assignment that this
      # submission isn't already assigned to review.
      candidate_set = submission_ids - existing.map { |a| a.asset_id }
      candidate_set.delete(submission.id) # don't assign to ourselves

      candidates = submissions.select { |c|
        candidate_set.include?(c.id)
      }.sort_by { |c|
        [
          # prefer those who need reviews done
          assessor_id_map[c.id].count < self.peer_review_count ? CanvasSort::First : CanvasSort::Last,
          # then prefer those who are not reviewing this submission
          assessor_id_map[submission.id].include?(c.id) ? CanvasSort::Last : CanvasSort::First,
          # then prefer those who need the most reviews done (that way we don't run the risk of
          # getting stuck with a submission needing more reviews than there are available reviewers left)
          assessor_id_map[c.id].count,
          # then prefer those who are assigned fewer reviews at this point --
          # this helps avoid loops where everybody is reviewing those who are
          # reviewing them, leaving the final assignee out in the cold.
          c.assigned_assessments.size,
          # random sort, all else being equal.
          rand,
        ]
      }

      # pick the number needed
      assessees = candidates[0, needed]

      # if there aren't enough candidates, we'll just not assign as many as
      # peer_review_count would allow. this'll only happen if peer_review_count
      # >= the number of submissions.

      assessees.each do |to_assess|
        # make the assignment
        res << to_assess.assign_assessor(submission)
        assessor_id_map[to_assess.id] << submission.id
      end
    end

    reviews_due_at = self.peer_reviews_assign_at || self.due_at
    if reviews_due_at && reviews_due_at < Time.now
      self.peer_reviews_assigned = true
    end
    self.save
    return res
  end

  # TODO: on a future deploy, rename the column peer_reviews_due_at
  # to peer_reviews_assign_at
  def peer_reviews_assign_at
    peer_reviews_due_at
  end

  def peer_reviews_assign_at=(val)
    write_attribute(:peer_reviews_due_at, val)
  end

  def has_peer_reviews?
    self.peer_reviews
  end

  def self.percent_considered_graded
    0.5
  end

  scope :include_submitted_count, -> { select(
    "assignments.*, (SELECT COUNT(*) FROM #{Submission.quoted_table_name}
    WHERE assignments.id = submissions.assignment_id
    AND submissions.submission_type IS NOT NULL) AS submitted_count") }

  scope :include_graded_count, -> { select(
    "assignments.*, (SELECT COUNT(*) FROM #{Submission.quoted_table_name}
    WHERE assignments.id = submissions.assignment_id
    AND submissions.grade IS NOT NULL) AS graded_count") }

  scope :include_quiz_and_topic, -> { preload(:quiz, :discussion_topic) }

  scope :no_graded_quizzes_or_topics, -> { where("submission_types NOT IN ('online_quiz', 'discussion_topic')") }

  scope :with_submissions, -> { preload(:submissions) }

  scope :with_submissions_for_user, lambda { |user|
    eager_load(:submissions).where(submissions: {user_id: user})
  }

  scope :for_context_codes, lambda { |codes| where(:context_code => codes) }
  scope :for_course, lambda { |course_id| where(:context_type => 'Course', :context_id => course_id) }
  scope :for_group_category, lambda { |group_category_id| where(:group_category_id => group_category_id) }

  # NOTE: only use for courses with differentiated assignments on
  scope :visible_to_students_in_course_with_da, lambda { |user_id, course_id|
    joins(:assignment_student_visibilities).
    where(:assignment_student_visibilities => { :user_id => user_id, :course_id => course_id })
  }

  # course_ids should be courses that restrict visibility based on overrides
  # ie: courses with differentiated assignments on or in which the user is not a teacher
  scope :filter_by_visibilities_in_given_courses, lambda { |user_ids, course_ids_that_have_da_enabled|
    if course_ids_that_have_da_enabled.nil? || course_ids_that_have_da_enabled.empty?
      active
    else
      user_ids = Array.wrap(user_ids).join(',')
      course_ids = Array.wrap(course_ids_that_have_da_enabled).join(',')
      scope = joins(sanitize_sql([<<-SQL, course_ids, user_ids]))
        LEFT OUTER JOIN #{AssignmentStudentVisibility.quoted_table_name} ON (
         assignment_student_visibilities.assignment_id = assignments.id
         AND assignment_student_visibilities.course_id IN (%s)
         AND assignment_student_visibilities.user_id IN (%s))
      SQL
      scope.where("(assignments.context_id NOT IN (?) AND assignments.workflow_state<>'deleted') OR (assignment_student_visibilities.assignment_id IS NOT NULL)", course_ids_that_have_da_enabled)
    end
  }

  scope :due_before, lambda { |date| where("assignments.due_at<?", date) }

  scope :due_after, lambda { |date| where("assignments.due_at>?", date) }
  scope :undated, -> { where(:due_at => nil) }

  scope :only_graded, -> { where("submission_types<>'not_graded'") }

  scope :with_just_calendar_attributes, -> {
    select(((Assignment.column_names & CalendarEvent.column_names) + ['due_at', 'assignment_group_id', 'could_be_locked', 'unlock_at', 'lock_at', 'submission_types', '(freeze_on_copy AND copied) AS frozen'] - ['cloned_item_id', 'migration_id']).join(", "))
  }

  scope :due_between, lambda { |start, ending| where(:due_at => start..ending) }

  # Return all assignments and their active overrides where either the
  # assignment or one of its overrides is due between start and ending.
  scope :due_between_with_overrides, lambda { |start, ending|
    joins("LEFT OUTER JOIN #{AssignmentOverride.quoted_table_name} assignment_overrides
          ON assignment_overrides.assignment_id = assignments.id").
    group("assignments.id").
    where('assignments.due_at BETWEEN ? AND ?
          OR assignment_overrides.due_at_overridden AND
          assignment_overrides.due_at BETWEEN ? AND ?', start, ending, start, ending)
  }

  scope :updated_after, lambda { |*args|
    if args.first
      where("assignments.updated_at IS NULL OR assignments.updated_at>?", args.first)
    else
      all
    end
  }

  scope :not_ignored_by, lambda { |user, purpose|
    where("NOT EXISTS (?)",
          Ignore.where(asset_type: 'Assignment',
                       user_id: user,
                       purpose: purpose).where('asset_id=assignments.id'))
  }

  # the map on the API_NEEDED_FIELDS here is because PostgreSQL will see the
  # query as ambigious for the "due_at" field if combined with another table
  # (e.g. assignment overrides) with similar fields (like id,lock_at,etc),
  # throwing an error.
  scope :api_needed_fields, -> { select(API_NEEDED_FIELDS.map{ |f| "assignments." + f.to_s}) }

  # This should only be used in the course drop down to show assignments needing a submission
  scope :need_submitting_info, lambda { |user_id, limit|
    chain = api_needed_fields.
      where("(SELECT COUNT(id) FROM #{Submission.quoted_table_name}
            WHERE assignment_id = assignments.id
            AND (submission_type IS NOT NULL OR excused = ?)
            AND user_id = ?) = 0", true, user_id).
      limit(limit).
      order("assignments.due_at")

    # select doesn't work with include() in rails3, and include(:context)
    # doesn't work because of the polymorphic association. So we'll preload
    # context for the assignments in a single query.
    chain.preload(:context)
  }

  # This should only be used in the course drop down to show assignments not yet graded.
  scope :need_grading_info, lambda {
    chain = api_needed_fields.
        where("assignments.needs_grading_count>0").
        order("assignments.due_at")

    chain.preload(:context)
  }

  scope :expecting_submission, -> { where("submission_types NOT IN ('', 'none', 'not_graded', 'on_paper') AND submission_types IS NOT NULL") }

  scope :gradeable, -> { where("assignments.submission_types<>'not_graded'") }

  scope :active, -> { where("assignments.workflow_state<>'deleted'") }
  scope :before, lambda { |date| where("assignments.created_at<?", date) }

  scope :not_locked, -> {
    where("(assignments.unlock_at IS NULL OR assignments.unlock_at<:now) AND (assignments.lock_at IS NULL OR assignments.lock_at>:now)",
      :now => Time.zone.now)
  }

  scope :order_by_base_due_at, -> { order("assignments.due_at") }

  scope :unpublished, -> { where(:workflow_state => 'unpublished') }
  scope :published, -> { where(:workflow_state => 'published') }

  def overdue?
    due_at && due_at <= Time.now
  end

  def readable_submission_types
    return nil unless expects_submission? || expects_external_submission?
    res = (self.submission_types || "").split(",").map{|s| readable_submission_type(s) }.compact
    res.to_sentence(:or)
  end

  def readable_submission_type(submission_type)
    case submission_type
    when 'online_quiz'
      t 'submission_types.a_quiz', "a quiz"
    when 'online_upload'
      t 'submission_types.a_file_upload', "a file upload"
    when 'online_text_entry'
      t 'submission_types.a_text_entry_box', "a text entry box"
    when 'online_url'
      t 'submission_types.a_website_url', "a website url"
    when 'discussion_topic'
      t 'submission_types.a_discussion_post', "a discussion post"
    when 'media_recording'
      t 'submission_types.a_media_recording', "a media recording"
    when 'on_paper'
      t 'submission_types.on_paper', "on paper"
    when 'external_tool'
      t 'submission_types.external_tool', "an external tool"
    else
      nil
    end
  end
  protected :readable_submission_type

  def expects_submission?
    submission_types && submission_types.strip != "" && submission_types != "none" && submission_types != 'not_graded' && submission_types != "on_paper" && submission_types != 'external_tool'
  end

  def expects_external_submission?
    submission_types == 'on_paper' || submission_types == 'external_tool'
  end

  def non_digital_submission?
    ["on_paper","none","not_graded",""].include?(submission_types.strip)
  end

  def allow_google_docs_submission?
    self.submission_types &&
      self.submission_types.match(/online_upload/)
  end

  def <=>(comparable)
    sort_key <=> comparable.sort_key
  end

  def sort_key
    # undated assignments go last
    [due_at || CanvasSort::Last, Canvas::ICU.collation_key(title)]
  end

  def special_class; nil; end

  def submission_action_string
    if submission_types == "online_quiz"
      t :submission_action_take_quiz, "Take %{title}", :title => title
    else
      t :submission_action_turn_in_assignment, "Turn in %{title}", :title => title
    end
  end

  # Infers the user, submission, and attachment from a filename
  def infer_comment_context_from_filename(fullpath)
    filename = File.basename(fullpath)
    split_filename = filename.split('_')
    # If the filename is like Richards_David_2_link.html, then there is no
    # useful attachment here.  The assignment was submitted as a URL and the
    # teacher commented directly with the gradebook.  Otherwise, grab that
    # last value and strip off everything after the first period.
    user_id, attachment_id = split_filename.grep(/^\d+$/).take(2)
    attachment_id = nil if split_filename.last =~ /^link/ || filename =~ /^\._/

    if user_id
      user = User.where(id: user_id).first
      submission = Submission.where(user_id: user_id, assignment_id: self).first
    end
    attachment = Attachment.where(id: attachment_id).first if attachment_id

    if !attachment || !submission ||
       !attachment.grants_right?(user, :read) ||
       !submission.attachments.where(:id => attachment_id).exists?
      @ignored_files << fullpath
      return nil
    end

    {
      :user => user,
      :submission => submission,
      :filename => fullpath,
      :display_name => attachment.display_name
    }
  end
  protected :infer_comment_context_from_filename

  FREEZABLE_ATTRIBUTES = %w{title description lock_at points_possible grading_type
                            submission_types assignment_group_id allowed_extensions
                            group_category_id notify_of_update peer_reviews workflow_state}
  def frozen?
    !!(self.freeze_on_copy && self.copied &&
       PluginSetting.settings_for_plugin(:assignment_freezer))
  end

  # indicates complete frozenness for an assignment.
  # if the user can edit at least one of the attributes, it is not frozen to
  # them
  def frozen_for_user?(user)
    return true if user.blank?
    frozen? && !self.context.grants_right?(user, :manage_frozen_assignments)
  end

  def frozen_attributes_for_user(user)
    FREEZABLE_ATTRIBUTES.select do |freezable_attribute|
      att_frozen? freezable_attribute, user
    end
  end

  def att_frozen?(att, user=nil)
    return false unless frozen?
    if settings = PluginSetting.settings_for_plugin(:assignment_freezer)
      if Canvas::Plugin.value_to_boolean(settings[att.to_s])
        if user
          return !self.context.grants_right?(user, :manage_frozen_assignments)
        else
          return true
        end
      end
    end

    false
  end

  def can_copy?(user)
    !att_frozen?("no_copying", user)
  end

  def frozen_atts_not_altered
    return if self.copying
    FREEZABLE_ATTRIBUTES.each do |att|
      if self.changes[att] && att_frozen?(att, @updating_user)
        self.errors.add(att,
          t('errors.cannot_save_att',
            "You don't have permission to edit the locked attribute %{att_name}",
            :att_name => att))
      end
    end
  end

  def update_cached_due_dates
    if due_at_changed? || workflow_state_changed?
      DueDateCacher.recompute(self)
    end
  end

  def graded?
    submission_types != 'not_graded'
  end

  def active?
    workflow_state != 'deleted'
  end

  def available?
    if Rails.env.production?
      published?
    else
      raise "Assignment#available? is deprecated. Use #published?"
    end
  end

  def has_student_submissions?
    if !@has_student_submissions.nil?
      @has_student_submissions
    elsif attribute_present? :student_submission_count
      student_submission_count.to_i > 0
    else
      submissions.having_submission.where("user_id IS NOT NULL").exists?
    end
  end
  attr_writer :has_student_submissions

  def group_category_deleted_with_submissions?
    self.group_category.try(:deleted_at?) && self.has_student_submissions?
  end

  def self.with_student_submission_count
    joins("LEFT OUTER JOIN #{Submission.quoted_table_name} s ON
           s.assignment_id = assignments.id AND
           s.submission_type IS NOT NULL")
    .group("assignments.id")
    .select("assignments.*, count(s.assignment_id) AS student_submission_count")
  end

  def can_unpublish?
    return true if new_record?
    return @can_unpublish unless @can_unpublish.nil?
    @can_unpublish = !has_student_submissions?
  end
  attr_writer :can_unpublish

  def self.preload_can_unpublish(assignments, assmnt_ids_with_subs=nil)
    return unless assignments.any?
    assmnt_ids_with_subs ||= assignment_ids_with_submissions(assignments.map(&:id))
    assignments.each{|a| a.can_unpublish = !(assmnt_ids_with_subs.include?(a.id)) }
  end

  def self.assignment_ids_with_submissions(assignment_ids)
    Submission.having_submission.where(:assignment_id => assignment_ids).uniq.pluck(:assignment_id)
  end

  # override so validations are called
  def publish
    self.workflow_state = 'published'
    self.save
  end

  # override so validations are called
  def unpublish
    self.workflow_state = 'unpublished'
    self.save
  end

  def excused_for?(user)
    s = submissions.where(user_id: user.id).first_or_initialize
    s.excused?
  end

  # simply versioned models are always marked new_record, but for our purposes
  # they are not new. this ensures that assignment override caching works as
  # intended for versioned assignments
  def cache_key
    new_record = @new_record
    @new_record = false if @simply_versioned_version_model
    super
  ensure
    @new_record = new_record if @simply_versioned_version_model
  end

  def quiz?
    submission_types == 'online_quiz' && quiz.present?
  end

  def discussion_topic?
    submission_types == 'discussion_topic' && discussion_topic.present?
  end

  def self.sis_grade_export_enabled?(context)
    context.feature_enabled?(:post_grades) ||
      context.root_account.feature_enabled?(:bulk_sis_grade_export) ||
      Lti::AppLaunchCollator.any?(context, [:post_grades])
  end

  def run_if_overrides_changed!
    self.relock_modules!
    self.discussion_topic.relock_modules! if self.discussion_topic
    self.quiz.relock_modules! if self.quiz
  end
end
