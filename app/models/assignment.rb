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

require 'set'

class Assignment < ActiveRecord::Base
  include Workflow
  include TextHelper
  include HasContentTags
  include CopyAuthorizedLinks
  include Mutable
  include ContextModuleItem
  include DatesOverridable

  attr_accessible :title, :name, :description, :due_at, :points_possible,
    :min_score, :max_score, :mastery_score, :grading_type, :submission_types,
    :assignment_group, :unlock_at, :lock_at, :group_category, :group_category_id,
    :peer_review_count, :peer_reviews_due_at, :peer_reviews_assign_at, :grading_standard_id,
    :peer_reviews, :automatic_peer_reviews, :grade_group_students_individually,
    :notify_of_update, :time_zone_edited, :turnitin_enabled, :turnitin_settings,
    :context, :position, :allowed_extensions, :external_tool_tag_attributes,
    :freeze_on_copy, :assignment_group_id
    
  attr_accessor :original_id, :updating_user, :copying

  has_many :submissions, :class_name => 'Submission', :dependent => :destroy
  has_many :attachments, :as => :context, :dependent => :destroy
  has_one :quiz
  belongs_to :assignment_group
  has_one :discussion_topic, :conditions => ['discussion_topics.root_topic_id IS NULL'], :order => 'created_at'
  has_many :learning_outcome_alignments, :as => :content, :class_name => 'ContentTag', :conditions => ['content_tags.tag_type = ? AND content_tags.workflow_state != ?', 'learning_outcome', 'deleted'], :include => :learning_outcome
  has_one :rubric_association, :as => :association, :conditions => ['rubric_associations.purpose = ?', "grading"], :order => :created_at, :include => :rubric
  has_one :rubric, :through => :rubric_association
  has_one :teacher_enrollment, :class_name => 'TeacherEnrollment', :foreign_key => 'course_id', :primary_key => 'context_id', :include => :user, :conditions => ["enrollments.workflow_state = 'active' AND enrollments.type = 'TeacherEnrollment'"]
  has_many :ignores, :as => :asset
  belongs_to :context, :polymorphic => true
  belongs_to :cloned_item
  belongs_to :grading_standard
  belongs_to :group_category

  has_one :external_tool_tag, :class_name => 'ContentTag', :as => :context, :dependent => :destroy
  validates_associated :external_tool_tag, :if => :external_tool?

  accepts_nested_attributes_for :external_tool_tag, :reject_if => proc { |attrs|
    # only accept the url and new_tab params, the other accessible
    # params don't apply to an content tag being used as an external_tool_tag
    attrs.slice!(:url, :new_tab)
    false
  }
  before_validation do |assignment|
    if assignment.external_tool? && assignment.external_tool_tag
      assignment.external_tool_tag.context = assignment
      assignment.external_tool_tag.content_type = "ContextExternalTool"
    else
      assignment.external_tool_tag = nil
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
    allowed_extensions
    muted
    needs_grading_count
    could_be_locked
    freeze_on_copy
    copied
    all_day
    all_day_date
  )
  # create a shim for plugins that use the old association name. this is
  # TEMPORARY. the plugins should update to use the new association name, and
  # once they're updated, this shim removed. DO NOT USE in new code.
  def learning_outcome_tags
    learning_outcome_alignments
  end

  def external_tool?
    self.submission_types == 'external_tool'
  end

  validates_presence_of :context_id
  validates_presence_of :context_type
  validates_length_of :title, :maximum => maximum_string_length, :allow_nil => true
  validates_length_of :description, :maximum => maximum_long_text_length, :allow_nil => true, :allow_blank => true
  validate :frozen_atts_not_altered, :if => :frozen?, :on => :update

  acts_as_list :scope => :assignment_group_id
  simply_versioned :keep => 5
  sanitize_field :description, Instructure::SanitizeField::SANITIZE
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

  serialize :turnitin_settings, Hash
  # file extensions allowed for online_upload submission
  serialize :allowed_extensions, Array

  def allowed_extensions=(new_value)
    if new_value.is_a?(String)
      # allow both comma and whitespace as separator, and remove the . if they
      # put it on.
      new_value = new_value.split(/[\s,]+/).map { |v| v.strip.gsub(/\A\./, '').downcase }
    end
    write_attribute(:allowed_extensions, new_value)
  end

  before_create :infer_state_from_course

  before_save   :set_old_assignment_group_id,
                :deliver_messages_if_publishing,
                :infer_grading_type,
                :process_if_quiz,
                :default_values,
                :update_submissions_if_details_changed,
                :maintain_group_category_attribute

  after_save    :update_grades_if_details_changed,
                :touch_assignment_group,
                :touch_context,
                :update_grading_standard,
                :update_quiz_or_discussion_topic,
                :update_submissions_later,
                :clear_unannounced_grading_changes_if_just_unpublished,
                :schedule_do_auto_peer_review_job_if_automatic_peer_review,
                :delete_empty_abandoned_children,
                :validate_assignment_overrides,
                :recompute_submission_lateness_later

  has_a_broadcast_policy

  after_save :remove_assignment_updated_flag # this needs to be after has_a_broadcast_policy for the message to be sent

  def validate_assignment_overrides
    if group_category_id_changed? 
      # needs to be .each(&:destroy) instead of .update_all(:workflow_state =>
      # 'deleted') so that the override gets versioned properly
      active_assignment_overrides.
        where(:set_type => 'Group').
        each { |o|
          o.dont_touch_assignment = true
          o.destroy
        }
    end
  end

  def schedule_do_auto_peer_review_job_if_automatic_peer_review
    if peer_reviews && automatic_peer_reviews && !peer_reviews_assigned
      # handle if it has already come due, but has not yet been auto_peer_reviewed
      if overdue?
        # do_auto_peer_review
      elsif due_at
        self.send_later_enqueue_args(:do_auto_peer_review, {
          :run_at => due_at,
          :singleton => Shard.default.activate { "assignment:auto_peer_review:#{self.id}" }
        })
      end
    end
    true
  end

  def do_auto_peer_review
    assign_peer_reviews if peer_reviews && automatic_peer_reviews && !peer_reviews_assigned && overdue?
  end

  def touch_assignment_group
    AssignmentGroup.where(:id => self.assignment_group_id).update_all(:updated_at => Time.now.utc) if self.assignment_group_id
    true
  end

  def update_student_submissions
    submissions.graded.find_each do |submission|
      submission.grade = score_to_grade(submission.score)
      submission.graded_at = Time.zone.now
      submission.with_versioning(:explicit => true) { submission.save! }
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
    if @points_possible_was != self.points_possible || @grades_affected || @muted_was != self.muted
      connection.after_transaction_commit { self.context.recompute_student_scores }
    end
    true
  end

  def create_in_turnitin
    return false unless self.context.turnitin_settings
    return true if self.turnitin_settings[:current]
    turnitin = Turnitin::Client.new(*self.context.turnitin_settings)
    res = turnitin.createOrUpdateAssignment(self, self.turnitin_settings)

    unless read_attribute(:turnitin_settings)
      self.turnitin_settings = Turnitin::Client.default_assignment_turnitin_settings
    end

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

  def turnitin_settings
    read_attribute(:turnitin_settings) || Turnitin::Client.default_assignment_turnitin_settings
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
    self.mastery_score = [self.mastery_score, self.points_possible].min if self.mastery_score && self.points_possible
    self.submission_types ||= "none"
    self.peer_reviews_assign_at = [self.due_at, self.peer_reviews_assign_at].compact.max
    @workflow_state_was = self.workflow_state_was
    @points_possible_was = self.points_possible_was
    @muted_was = self.muted_was
    @submission_types_was = self.submission_types_was
    @due_at_was = self.due_at_was
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

  def clear_unannounced_grading_changes_if_just_unpublished
    if @workflow_state_was == 'published' && self.available?
      Submission.where(:assignment_id => self).update_all(:changed_since_publish => false)
    end
    true
  end

  def delete_empty_abandoned_children
    if @submission_types_was != self.submission_types
      unless self.submission_types == 'discussion_topic'
        self.discussion_topic.unlink_from(:assignment) if self.discussion_topic
      end
      unless self.submission_types == 'online_quiz'
        self.quiz.unlink_from(:assignment) if self.quiz
      end
    end
  end

  attr_accessor :updated_submissions
  def update_submissions_later
    if @old_assignment_group_id != self.assignment_group_id
      AssignmentGroup.find_by_id(@old_assignment_group_id).try(:touch) if @old_assignment_group_id.present?
    end
    self.assignment_group.touch if self.assignment_group
    if @notify_graded_students_of_grading
      send_later_if_production(:update_submissions, true)
    elsif @points_possible_was != self.points_possible #|| self.published?
      send_later_if_production(:update_submissions)
    end
  end

  def update_submissions(just_published=false)
    @updated_submissions ||= []
    self.submissions.find_each do |submission|
      @updated_submissions << submission
      if just_published
        submission.assignment_just_published!
      else
        submission.save!
      end
    end
  end

  def update_quiz_or_discussion_topic
    return true if self.deleted?
    if self.submission_types == "online_quiz" && @saved_by != :quiz
      quiz = Quiz.find_by_assignment_id(self.id) || self.context.quizzes.build
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
      quiz.save if quiz.changed?
    elsif self.submission_types == "discussion_topic" && @saved_by != :discussion_topic
      topic = self.discussion_topic || self.context.discussion_topics.build(:user => @updating_user)
      topic.assignment_id = self.id
      topic.title = self.title
      topic.message = self.description
      topic.saved_by = :assignment
      topic.updated_at = Time.now
      topic.workflow_state = 'active' if topic.deleted?
      topic.save
      self.discussion_topic = topic
    end
  end
  attr_writer :saved_by

  def update_grading_standard
    self.grading_standard.save! if self.grading_standard
  end

  def context_module_action(user, action, points=nil)
    tags_to_update = self.context_module_tags.to_a
    if self.submission_types == 'discussion_topic' && self.discussion_topic
      tags_to_update += self.discussion_topic.context_module_tags
    elsif self.submission_types == 'online_quiz' && self.quiz
      tags_to_update += self.quiz.context_module_tags
    end
    tags_to_update.each { |tag| tag.context_module_action(user, action, points) }
  end

  def context_module_tag_info(user)
    tag_info = {:points_possible => self.points_possible}
    if self.multiple_due_dates_apply_to?(user)
      tag_info[:vdd_tooltip] = OverrideTooltipPresenter.new(self, user).as_json
    else
      tag_info[:due_date] = self.overridden_for(user).due_at.utc.iso8601 rescue nil
    end
    tag_info
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
    p.to {
      # everyone who is _not_ covered by an assignment override affecting due_at
      # (the AssignmentOverride records will take care of notifying those users)
      participants - participants_with_overridden_due_at
    }
    p.whenever { |record|
      !self.suppress_broadcast and
      record.context.state == :available and record.changed_in_states([:available,:published], :fields => :due_at) and
      record.prior_version && !Assignment.due_dates_equal?(record.due_at, record.prior_version.due_at) and
      record.created_at < 3.hours.ago
    }

    p.dispatch :assignment_changed
    p.to { participants }
    p.whenever { |record|
      !self.suppress_broadcast and
      !record.muted? and
      record.created_at < 30.minutes.ago and
      record.context.state == :available and [:available, :published].include?(record.state) and
      record.prior_version and (record.points_possible != record.prior_version.points_possible || @assignment_changed)
    }

    p.dispatch :assignment_created
    p.to { participants }
    p.whenever { |record|
      !self.suppress_broadcast and
      record.context.state == :available and record.just_created
    }
    p.filter_asset_by_recipient { |record, user|
      record.overridden_for(user)
    }

    p.dispatch :assignment_graded
    p.to { @students_whose_grade_just_changed }
    p.whenever {|record|
      !self.suppress_broadcast and
      !record.muted? and
      @notify_affected_students_of_grading_change and
      record.context.state == :available and
      @students_whose_grade_just_changed and !@students_whose_grade_just_changed.empty?
    }

    p.dispatch :assignment_graded
    p.to { participants }
    p.whenever {|record|
      !self.suppress_broadcast and
      !record.muted? and
      @notify_all_students_of_grading and
      record.context.state == :available
    }

    p.dispatch :assignment_unmuted
    p.to { participants }
    p.whenever { |record|
      !self.suppress_broadcast and
      record.recently_unmuted
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

  attr_accessor :suppress_broadcast

  def deliver_messages_if_publishing
    @notify_graded_students_of_grading = false
    @notify_all_students_of_grading = false
    if self.workflow_state == 'published' && self.workflow_state_was == 'available'
      if self.previously_published
        @notify_graded_students_of_grading = true
      else
        @notify_all_students_of_grading = true
      end
    end
    self.previously_published = true if self.workflow_state == 'published' || self.workflow_state_was == 'published'
  end

  def points_uneditable?
    (self.submission_types == 'online_quiz') # && self.quiz && (self.quiz.edited? || self.quiz.available?))
  end

  workflow do
    state :available do
      event :publish, :transitions_to => :published
    end
    # 'published' means the grades have been published, and are now viewable to students
    state :published do
      event :unpublish, :transitions_to => :available
    end
    state :deleted
  end

  alias_method :destroy!, :destroy
  def destroy
    self.workflow_state = 'deleted'
    ContentTag.delete_for(self)
    @grades_affected = true
    self.save

    self.discussion_topic.destroy if self.discussion_topic && !self.discussion_topic.deleted?
    self.quiz.destroy if self.quiz && !self.quiz.deleted?
  end

  def time_zone_edited
    CGI::unescapeHTML(read_attribute(:time_zone_edited) || "")
  end

  def restore(from=nil)
    self.workflow_state = 'published'
    @grades_affected = true
    self.save
    self.discussion_topic.restore if self.discussion_topic && from != :discussion_topic
    self.quiz.restore if self.quiz && from != :quiz
  end

  def participants
    self.context.participants
  end

  def participants_with_overridden_due_at
    assignment_overrides.active.overriding_due_at.inject([]) do |overridden_users, o|
      overridden_users.concat(o.applies_to_students)
    end
  end

  def infer_state_from_course
    self.workflow_state = "published" if (self.context.publish_grades_immediately rescue false)
    if self.assignment_group_id.nil?
      self.context.require_assignment_group
      self.assignment_group = self.context.assignment_groups.active.first
    end
  end
  protected :infer_state_from_course

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
      if self.submission_types_changed? && self.submission_types_was != 'online_quiz'
        self.before_quiz_submission_types = self.submission_types_was
      end
    end
  end
  protected :process_if_quiz

  def grading_scheme
    if self.grading_standard
      self.grading_standard.grading_scheme
    else
      GradingStandard.default_grading_scheme
    end
  end

  def infer_grading_type
    self.grading_type ||= "points"
  end

  def score_to_grade_percent(score=0.0)
    if self.points_possible > 0
      result = score.to_f / self.points_possible
      result = (result * 1000.0).round / 10.0
    else
      # there's not really any reasonable value we can set here -- if the
      # assignment is worth no points, any percentage is as valid as any other.
      score.to_f
    end
  end

  def score_to_grade(score=0.0, given_grade=nil)
    result = score.to_f
    if self.grading_type == "percent"
      result = score_to_grade_percent(score)
      result = "#{result}%"
    elsif self.grading_type == "pass_fail"
      if self.points_possible.to_f > 0.0
        passed = score.to_f == self.points_possible.to_f
      elsif given_grade
        # the score for a zero-point pass/fail assignment could be considered
        # either pass *or* fail, so look at what the current given grade is
        # instead
        passed = ["complete", "pass"].include?(given_grade)
      else
        passed = score.to_f > 0.0
      end
      result = passed ? "complete" : "incomplete"
    elsif self.grading_type == "letter_grade"
      if self.points_possible.to_f > 0.0
        score = score.to_f / self.points_possible.to_f
        result = GradingStandard.score_to_grade(self.grading_scheme, score * 100)
      elsif given_grade
        # the score for a zero-point letter_grade assignment could be considered
        # to be *any* grade, so look at what the current given grade is
        # instead of trying to calculate it
        result = given_grade
      else
        # there's not really any reasonable value we can set here -- if the
        # assignment is worth no points, and the grader didn't enter an
        # explicit letter grade, any letter grade is as valid as any other.
        result = GradingStandard.score_to_grade(self.grading_scheme, score.to_f)
      end
    end
    result.to_s
  end

  def self.interpret_grade(grade, points_possible, grading_scheme = nil)
    case grade.to_s
    when %r{%$}
      # interpret as a percentage
      percentage = grade.to_f / 100.0
      (points_possible * percentage * 100.0).round / 100.0
    when %r{[\d\.]+}
      # interpret as a numerical score
      (grade.to_f * 100.0).round / 100.0
    when "pass", "complete"
      points_possible.to_f
    when "fail", "incomplete"
      0.0
    else
      # try to treat it as a letter grade
      if grading_scheme && standard_based_score = GradingStandard.grade_to_score(grading_scheme, grade)
        ((points_possible || 0.0) * standard_based_score).round / 100.0
      else
        nil
      end
    end
  end

  def grade_to_score(grade=nil)
    return nil if grade.nil?
    grading_scheme = self.grading_type == "letter_grade" && self.grading_scheme
    parsed_grade = Assignment.interpret_grade(grade, points_possible, grading_scheme)

    case self.grading_type
    when "points", "percent", "letter_grade"
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

  def set_old_assignment_group_id
    @old_assignment_group_id = self.assignment_group_id_was
  end
  protected :set_old_assignment_group_id

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

  def to_ics(in_own_calendar=true)
    return CalendarEvent::IcalEvent.new(self).to_ics(in_own_calendar)
  end

  def all_day
    read_attribute(:all_day) || (self.new_record? && self.due_at && (self.due_at.strftime("%H:%M") == '23:59' || self.due_at.strftime("%H:%M") == '00:00'))
  end

  def locked_for?(user=nil, opts={})
    return false if opts[:check_policies] && self.grants_right?(user, nil, :update)
    Rails.cache.fetch(locked_cache_key(user), :expires_in => 1.minute) do
      locked = false
      assignment_for_user = self.overridden_for(user)
      if (assignment_for_user.unlock_at && assignment_for_user.unlock_at > Time.now)
        locked = {:asset_string => self.asset_string, :unlock_at => assignment_for_user.unlock_at}
      elsif (assignment_for_user.lock_at && assignment_for_user.lock_at <= Time.now)
        locked = {:asset_string => self.asset_string, :lock_at => assignment_for_user.lock_at}
      elsif self.could_be_locked && item = locked_by_module_item?(user, opts[:deep_check_if_needed])
        locked = {:asset_string => self.asset_string, :context_module => item.context_module.attributes}
      end
      locked
    end
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
    submitted_count > 0
  end

  def submitted_count
    return read_attribute(:submitted_count).to_i if read_attribute(:submitted_count)
    Rails.cache.fetch(['submitted_count', self].cache_key) do
      self.submissions.having_submission.count
    end
  end

  set_policy do
    given { |user, session| self.cached_context_grants_right?(user, session, :read) }
    can :read and can :read_own_submission

    given { |user, session| self.submittable_type? &&
      self.cached_context_grants_right?(user, session, :participate_as_student) &&
      !self.locked_for?(user)
    }
    can :submit and can :attach_submission_comment_files

    given { |user, session| self.cached_context_grants_right?(user, session, :manage_grades) }
    can :update and can :grade and can :delete and can :create and can :read and can :attach_submission_comment_files

    given { |user, session| self.cached_context_grants_right?(user, session, :manage_assignments) }
    can :update and can :delete and can :create and can :read and can :attach_submission_comment_files
  end

  def filter_attributes_for_user(hash, user, session)
    if lock_info = self.locked_for?(user, :check_policies => true)
      hash.delete('description')
      hash['lock_info'] = lock_info
    end
  end

  def grade_distribution(submissions = nil)
    submissions ||= self.submissions
    tally = 0
    cnt = 0
    scores = submissions.map{|s| s.score}.compact
    scores.each do |score|
      tally += score
      cnt += 1
    end
    high = scores.max
    low = scores.min
    mean = tally.to_f / cnt.to_f
    [high, low, mean]
  end

  # Everyone, students, TAs, teachers
  def participants
    context.participants
  end

  def notify_affected_students_of_grading_change!
    @notify_affected_students_of_grading_change = true
    self.save! if @students_whose_grade_just_changed && !@students_whose_grade_just_changed
    @notify_affected_students_of_grading_change = false
  end

  def set_default_grade(options={})
    score = self.grade_to_score(options[:default_grade])
    grade = self.score_to_grade(score)
    submissions_to_save = []
    @students_whose_grade_just_changed = []
    self.context.students.find_each do |student|
      User.send(:with_exclusive_scope) do
        submission = self.find_or_create_submission(student)
        if !submission.score || options[:overwrite_existing_grades]
          if submission.score != score
            submissions_to_save << submission
            @students_whose_grade_just_changed << student
          end
        end
      end
    end

    changed_since_publish = !!self.available?
    Submission.where(:id => submissions_to_save).update_all(:score => score, :grade => grade, :published_score => score, :published_grade => grade, :changed_since_publish => changed_since_publish, :workflow_state => 'graded', :graded_at => Time.now.utc) unless submissions_to_save.empty?

    self.context.recompute_student_scores
    student_ids = context.student_ids
    send_later_if_production(:multiple_module_actions, student_ids, :scored, score)
  end

  def update_user_from_rubric(user, assessment)
    score = self.points_possible * (assessment.score / assessment.rubric.points_possible)
    self.grade_student(user, :grade => self.score_to_grade(score), :grader => assessment.assessor)
  end

  def title_with_id
    "#{title} (#{id})"
  end

  def title_slug
    truncate_text(title, :ellipsis => '')
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
    if self.has_group_category?
      group = self.group_category.group_for(student)
      if group
        students = group.users.joins("INNER JOIN enrollments ON enrollments.user_id=users.id").
          where(:enrollments => { :course_id => self.context}).
          where(Course.reflections[:student_enrollments].options[:conditions]).all
      end
    end
    [group, students]
  end

  def multiple_module_actions(student_ids, action, points=nil)
    students = self.context.students.find_all_by_id(student_ids).compact
    students.each do |user|
      self.context_module_action(user, action, points)
    end
  end

  def submission_for_student(user)
    self.submissions.find_or_initialize_by_user_id(user.id)
  end

  def grade_student(original_student, opts={})
    raise "Student is required" unless original_student
    raise "Student must be enrolled in the course as a student to be graded" unless context.includes_student?(original_student)
    raise "Grader must be enrolled as a course admin" if opts[:grader] && !self.context.grants_right?(opts[:grader], nil, :manage_grades)
    opts.delete(:id)
    group_comment = opts.delete :group_comment
    group, students = group_students(original_student)
    grader = opts.delete :grader
    comment = {
      :comment => (opts.delete :comment),
      :attachments => (opts.delete :comment_attachments),
      :author => grader,
      :media_comment_id => (opts.delete :media_comment_id),
      :media_comment_type => (opts.delete :media_comment_type),
    }
    submissions = []

    students.each do |student|
      submission_updated = false
      submission = self.find_or_create_submission(student) #submissions.find_or_create_by_user_id(student.id) #(:first, :conditions => {:assignment_id => self.id, :user_id => student.id})
      if student == original_student || !grade_group_students_individually
        previously_graded = submission.grade.present?
        submission.attributes = opts
        submission.assignment_id = self.id
        submission.user_id = student.id
        submission.grader_id = grader.try(:id)
        if !opts[:grade] || opts[:grade] == ""
          submission.score = nil
          submission.grade = nil
        end
        did_grade = false
        if submission.grade
          did_grade = true
          submission.score = self.grade_to_score(submission.grade)
        end
        if submission.score
          did_grade = true
          submission.grade = self.score_to_grade(submission.score, submission.grade)
        end
        submission.grade_matches_current_submission = true if did_grade
        submission_updated = true if submission.changed?
        submission.workflow_state = "graded" if submission.score_changed? || submission.grade_matches_current_submission
        submission.group = group
        submission.graded_at = Time.zone.now if did_grade
        previously_graded ? submission.with_versioning(:explicit => true) { submission.save! } : submission.save!

        unless self.rubric_association
          self.learning_outcome_alignments.each do |alignment|
            submission.create_outcome_result(alignment)
          end
        end
      end
      submission.add_comment(comment) if comment && (group_comment == "1" || student == original_student)
      submissions << submission if group_comment == "1" || student == original_student || submission_updated
    end

    submissions
  end

  def hide_max_scores_for_assignments
    false
  end

  def hide_min_scores_for_assignments
    false
  end

  def self.find_or_create_submission(assignment_id, user_id)
    s = nil
    unique_constraint_retry do
      s = Submission.find_or_initialize_by_assignment_id_and_user_id(assignment_id, user_id)
      s.save_without_broadcast if s.new_record?
    end
    raise "bad" if s.new_record?
    s
  end

  def find_or_create_submission(user)
    user_id = user.is_a?(User) ? user.id : user
    Assignment.find_or_create_submission(self.id, user_id)
  end

  def find_asset_for_assessment(association, user_id)
    user = self.context.users.find_by_id(user_id)
    if association.purpose == "grading"
      user ? [self.find_or_create_submission(user), user] : [nil, nil]
    else
      [self, user]
    end
  end

  def find_submission(user)
    Submission.find_by_assignment_id_and_user_id(self.id, user.id)
  end

  # Update at this point is solely used for commenting on the submission
  def update_submission(original_student, opts={})
    raise "Student Required" unless original_student
    submission = submissions.find_by_user_id(original_student.id)
    res = []
    raise "No submission found for that student" unless submission
    group, students = group_students(original_student)
    opts[:author] ||= opts[:commenter] || opts[:user_id].present? && User.find_by_id(opts[:user_id])

    if opts[:comment] && opts[:assessment_request]
      # if there is no rubric the peer review is complete with just a comment
      opts[:assessment_request].complete unless opts[:assessment_request].rubric_association
    end

    students.each do |student|
      if (opts['comment'] && Canvas::Plugin.value_to_boolean(opts['group_comment'])) || student == original_student
        s = self.find_or_create_submission(student)
        s.assignment_id = self.id
        s.user_id = student.id
        s.group = group
        s.save! if s.changed?
        s.add_comment(opts)
        s.reload
        res << s
      end
    end
    res
  end

  def submit_homework(original_student, opts={})
    # Only allow a few fields to be submitted.  Cannot submit the grade of a
    # homework assignment, for instance.
    opts.keys.each { |k|
      opts.delete(k) unless [:body, :url, :attachments, :submission_type, :comment, :media_comment_id, :media_comment_type, :group_comment].include?(k.to_sym)
    }
    raise "Student Required" unless original_student
    raise "User must be enrolled in the course as a student to submit homework" unless context.student_enrollments.except(:includes).where(:user_id => original_student).exists?
    comment = opts.delete(:comment)
    group_comment = opts.delete(:group_comment)
    group, students = group_students(original_student)
    homeworks = []
    primary_homework = nil
    ts = Time.now.to_s
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
      students.each do |student|
        Assignment.unique_constraint_retry do
          homework = Submission.find_or_initialize_by_assignment_id_and_user_id(self.id, student.id)
          homework.grade_matches_current_submission = homework.score ? false : true
          homework.attributes = opts.merge({
            :attachment => nil,
            :processed => false,
            :process_attempts => 0,
            :workflow_state => submitted ? "submitted" : "unsubmitted",
            :group => group
          })
          homework.submitted_at = Time.now

          homework.with_versioning(:explicit => true) do
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
    end
    homeworks.each do |homework|
      context_module_action(homework.student, :submitted)
      homework.add_comment({:comment => comment, :author => original_student}) if comment && (group_comment || homework == primary_homework)
    end
    touch_context
    return primary_homework
  end

  def submissions_downloaded?
    self.submissions_downloads && self.submissions_downloads > 0
  end

  def as_json(options=nil)
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

  def speed_grader_json(user, avatars=false)
    Attachment.skip_thumbnails = true
    submission_fields = [ :user_id, :id, :submitted_at, :workflow_state,
                          :grade, :grade_matches_current_submission,
                          :graded_at, :turnitin_data, :submission_type, :score,
                          :assignment_id, :submission_comments ]

    comment_fields = [:comment, :id, :author_name, :created_at, :author_id,
                      :media_comment_type, :media_comment_id,
                      :cached_attachments, :attachments]

    res = as_json(
      :include => {
        :context => { :only => :id },
        :rubric_association => { :except => {} }
      },
      :include_root => false
    )
    avatar_methods = avatars ? [:avatar_path] : []
    visible_students = context.students_visible_to(user).order_by_sortable_name.uniq
    res[:context][:students] = visible_students.
      map{|u| u.as_json(:include_root => false, :methods => avatar_methods, :only => [:name, :id])}
    res[:context][:active_course_sections] = context.sections_visible_to(user).
      map{|s| s.as_json(:include_root => false, :only => [:id, :name]) }
    res[:context][:enrollments] = context.enrollments_visible_to(user).
      map{|s| s.as_json(:include_root => false, :only => [:user_id, :course_section_id]) }
    res[:context][:quiz] = self.quiz.as_json(:include_root => false, :only => [:anonymous_submissions])
    res[:submissions] = submissions.where(:user_id => visible_students).map{|s|
      json = s.as_json(:include_root => false,
        :include => {
          :submission_comments => {
            :methods => avatar_methods,
            :only => comment_fields
          },
          :attachments => {
            :only => [:mime_class, :comment_id, :id, :submitter_id ]
          },
        },
        :methods => [:scribdable?, :scribd_doc, :submission_history, :late],
        :only => submission_fields
      )
      if json['submission_history']
        json['submission_history'].map! do |s|
          s.as_json(
            :include => {
              :submission_comments => { :only => comment_fields }
            },
            :only => submission_fields,
            :methods => [:versioned_attachments, :late]
          )
        end
      end
      json
    }
    res
  ensure
    Attachment.skip_thumbnails = nil
  end

  def visible_rubric_assessments_for(user)
    if self.rubric_association
      self.rubric_association.rubric_assessments.select{|a| a.grants_rights?(user, :read)[:read]}.sort_by{|a| [a.assessment_type == 'grading' ? '0' : '1', a.assessor_name] }
    end
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
    comment_map = partition_for_user(file_map)
    comments = []
    comment_map.each do |group|
      comment = t :comment_from_files, { :one => "See attached file", :other => "See attached files" }, :count => group.size
      submission = group.first[:submission]
      user = group.first[:user]
      attachments = group.map { |g| FileInContext.attach(self, g[:filename], g[:display_name]) }
      comments << submission.add_comment({:comment => comment, :author => commenter, :attachments => attachments, :hidden => self.muted?})
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
    student_ids = context.student_ids
    submissions = submissions.select{|s| student_ids.include?(s.user_id) }
    submission_ids = Set.new(submissions) { |s| s.id }

    # there could be any conceivable configuration of peer reviews already
    # assigned when this method is called, since teachers can assign individual
    # reviews manually and change peer_review_count at any time. so we can't
    # make many assumptions. that's where most of the complexity here comes
    # from.

    # we track existing assessment requests, and the ones we create here, so
    # that we don't have to constantly re-query the db.
    assessment_request_counts = {}
    submissions.each do |s|
      assessment_request_counts[s.id] = s.assessment_requests.size
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
          # prefer those who still need more reviews done.
          assessment_request_counts[c.id] < self.peer_review_count ? 0 : 1,
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
        assessment_request_counts[to_assess.id] += 1
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

  scope :include_submitted_count, select(
    "assignments.*, (SELECT COUNT(*) FROM submissions
    WHERE assignments.id = submissions.assignment_id
    AND submissions.submission_type IS NOT NULL) AS submitted_count")

  scope :include_graded_count, select(
    "assignments.*, (SELECT COUNT(*) FROM submissions
    WHERE assignments.id = submissions.assignment_id
    AND submissions.grade IS NOT NULL) AS graded_count")

  scope :include_quiz_and_topic, includes(:quiz, :discussion_topic)

  scope :no_graded_quizzes_or_topics, where("submission_types NOT IN ('online_quiz', 'discussion_topic')")

  scope :with_submissions, includes(:submissions)

  scope :for_context_codes, lambda { |codes| where(:context_code => codes) }
  scope :for_course, lambda { |course_id| where(:context_type => 'Course', :context_id => course_id) }

  scope :due_before, lambda { |date| where("assignments.due_at<?", date) }

  scope :due_after, lambda { |date| where("assignments.due_at>?", date) }
  scope :undated, where(:due_at => nil)

  scope :only_graded, where("submission_types<>'not_graded'")

  scope :with_just_calendar_attributes, lambda {
    select(((Assignment.column_names & CalendarEvent.column_names) + ['due_at', 'assignment_group_id', 'could_be_locked', 'unlock_at', 'lock_at', 'submission_types', '(freeze_on_copy AND copied) AS frozen'] - ['cloned_item_id', 'migration_id']).join(", "))
  }

  scope :due_between, lambda { |start, ending| where(:due_at => start..ending) }

  # Return all assignments and their active overrides where either the
  # assignment or one of its overrides is due between start and ending.
  scope :due_between_with_overrides, lambda { |start, ending|
    includes(:assignment_overrides).
        where('assignments.due_at BETWEEN ? AND ?
              OR assignment_overrides.due_at_overridden AND
              assignment_overrides.due_at BETWEEN ? AND ?', start, ending, start, ending)
  }

  scope :updated_after, lambda { |*args|
    if args.first
      where("assignments.updated_at IS NULL OR assignments.updated_at>?", args.first)
    else
      scoped
    end
  }

  scope :not_ignored_by, lambda { |user, purpose|
    where("NOT EXISTS (SELECT * FROM ignores WHERE asset_type='Assignment' AND asset_id=assignments.id AND user_id=? AND purpose=?)",
          user, purpose)
  }

  # the map on the API_NEEDED_FIELDS here is because PostgreSQL will see the
  # query as ambigious for the "due_at" field if combined with another table
  # (e.g. assignment overrides) with similar fields (like id,lock_at,etc),
  # throwing an error.
  scope :api_needed_fields, select(API_NEEDED_FIELDS.map{ |f| "assignments." + f.to_s})

  # This should only be used in the course drop down to show assignments needing a submission
  scope :need_submitting_info, lambda { |user_id, limit|
    api_needed_fields.
      select("(SELECT name FROM courses WHERE courses.id = assignments.context_id) AS context_name").
      where("(SELECT COUNT(id) FROM submissions
            WHERE assignment_id = assignments.id
            AND submission_type IS NOT NULL
            AND user_id = ?) = 0", user_id).
      limit(limit).
      order("assignments.due_at")
  }

  # This should only be used in the course drop down to show assignments not yet graded.
  scope :need_grading_info, lambda { |limit|
    api_needed_fields.
        select("(SELECT name FROM courses WHERE id = assignments.context_id) AS context_name, needs_grading_count").
        where("assignments.needs_grading_count>0").
        limit(limit).
        order("assignments.due_at")
  }

  scope :expecting_submission, where("submission_types NOT IN ('', 'none', 'not_graded', 'on_paper') AND submission_types IS NOT NULL")

  scope :gradeable, where("assignments.submission_types<>'not_graded'")

  scope :need_publishing, lambda {
    where("assignments.due_at<? AND assignments.workflow_state='available'", 1.week.ago)
  }

  scope :active, where("assignments.workflow_state<>'deleted'")
  scope :before, lambda { |date| where("assignments.created_at<?", date) }

  scope :not_locked, lambda {
    where("(assignments.unlock_at IS NULL OR assignments.unlock_at<:now) AND (assignments.lock_at IS NULL OR assignments.lock_at>:now)",
      :now => Time.zone.now)
  }

  scope :order_by_base_due_at, order("assignments.due_at")

  def needs_publishing?
    self.due_at && self.due_at < 1.week.ago && self.available?
  end

  def overdue?
    due_at && due_at <= Time.now
  end

  def readable_submission_types
    return nil unless self.expects_submission?
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
    else
      nil
    end
  end
  protected :readable_submission_type

  CLONE_FOR_EXCLUDE_ATTRIBUTES = [:id, :assignment_group_id, :group_category, :peer_review_count, :peer_reviews_assigned, :previously_published, :needs_grading_count]

  attr_accessor :clone_updated
  def clone_for(context, dup=nil, options={}) #migrate=true)
    options[:migrate] = true if options[:migrate] == nil
    if !self.cloned_item && !self.new_record?
      self.cloned_item ||= ClonedItem.create(:original_item => self)
      self.save!
    end
    existing = context.assignments.active.find_by_id(self.id)
    existing ||= context.assignments.active.find_by_cloned_item_id(self.cloned_item_id || 0)
    return existing if existing && !options[:overwrite]
    dup ||= Assignment.new
    dup = existing if existing && options[:overwrite]
    self.attributes.delete_if{|k,v| CLONE_FOR_EXCLUDE_ATTRIBUTES.include?(k.to_sym) }.each do |key, val|
      dup.send("#{key}=", val)
    end

    context.log_merge_result(t('warnings.group_assignment', "The Assignment \"%{assignment}\" was a group assignment, and you'll need to re-set the group settings for this new context", :assignment => self.title)) if self.has_group_category?
    context.log_merge_result(t('warnings.peer_assignment', "The Assignment \"%{assignment}\" was a peer review assignment, and you'll need to re-set the peer review settings for this new context", :assignment => self.title)) if self.peer_review_count && self.peer_review_count > 0

    dup.context = context
    dup.description = context.migrate_content_links(self.description, self.context) if options[:migrate]
    dup.saved_by = :quiz if options[:cloning_for_quiz]
    dup.saved_by = :discussion_topic if options[:cloning_for_topic]
    dup.save_without_broadcasting!
    if self.rubric_association
      old_association = self.rubric_association
      new_association = RubricAssociation.new(
        :rubric => old_association.rubric,
        :association => dup,
        :use_for_grading => old_association.use_for_grading,
        :title => old_association.title,
        :description => old_association.description,
        :summary_data => old_association.summary_data,
        :purpose => old_association.purpose,
        :url => old_association.url,
        :context => dup.context
      )
      new_association.save_without_broadcasting!
    end
    if self.submission_types == 'online_quiz' && self.quiz && !options[:cloning_for_quiz]
      new_quiz = Quiz.find_by_assignment_id(dup.id)
      new_quiz = self.quiz.clone_for(context, new_quiz, :cloning_for_assignment=>true)
      new_quiz.assignment_id = dup.id
      new_quiz.save! #_without_broadcasting!
    elsif self.submission_types == 'discussion_topic' && self.discussion_topic && !options[:cloning_for_topic]
      new_topic = DiscussionTopic.find_by_assignment_id(dup.id)
      new_topic = self.discussion_topic.clone_for(context, new_topic, :cloning_for_assignment=>true)
      new_topic.assignment_id = dup.id
      dup.submission_types = 'discussion_topic'
      new_topic.save!
    elsif self.submission_types == 'external_tool' && self.external_tool_tag
      tag = dup.build_external_tool_tag(:url => external_tool_tag.url, :new_tab => external_tool_tag.new_tab)
      tag.content_type = 'ContextExternalTool'
      tag.save
    end
    dup.assignment_group_id = context.merge_mapped_id(self.assignment_group) rescue nil
    if dup.assignment_group_id.nil? && self.assignment_group
      new_group = self.assignment_group.clone_for(context)
      new_group.save_without_broadcasting!
      dup.assignment_group = new_group
      context.map_merge(self.assignment_group, new_group)
    end
    context.log_merge_result(t('messages.assignment_created', "Assignment \"%{assignment}\" created", :assignment => self.title))
    context.may_have_links_to_migrate(dup)
    dup.updated_at = Time.now
    dup.clone_updated = true
    dup
  end

  def self.process_migration(data, migration)
    assignments = data['assignments'] ? data['assignments']: []
    to_import = migration.to_import 'assignments'
    assignments.each do |assign|
      if migration.import_object?("assignments", assign['migration_id'])
        begin
          import_from_migration(assign, migration.context)
        rescue
          migration.add_import_warning(t('#migration.assignment_type', "Assignment"), assign[:title], $!)
        end
      end
    end
    migration_ids = assignments.map{|m| m['assignment_id'] }.compact
    conn = self.connection
    cases = []
    max = migration.context.assignments.map(&:position).compact.max || 0
    migration.context.assignments
    assignments.each_with_index{|m, idx| cases << " WHEN migration_id=#{conn.quote(m['assignment_id'])} THEN #{max + idx + 1} " if m['assignment_id'] }
    unless cases.empty?
      conn.execute("UPDATE assignments SET position=CASE #{cases.join(' ')} ELSE NULL END WHERE context_id=#{migration.context.id} AND context_type=#{conn.quote(migration.context.class.to_s)} AND migration_id IN (#{migration_ids.map{|id| conn.quote(id)}.join(',')})")
    end
  end


  def self.import_from_migration(hash, context, item=nil)
    hash = hash.with_indifferent_access
    return nil if hash[:migration_id] && hash[:assignments_to_import] && !hash[:assignments_to_import][hash[:migration_id]]
    item ||= find_by_context_type_and_context_id_and_id(context.class.to_s, context.id, hash[:id])
    item ||= find_by_context_type_and_context_id_and_migration_id(context.class.to_s, context.id, hash[:migration_id]) if hash[:migration_id]
    item ||= context.assignments.new #new(:context => context)
    item.title = hash[:title]
    item.migration_id = hash[:migration_id]
    item.workflow_state = 'available' if item.deleted?
    if hash[:instructions_in_html] == false
      self.extend TextHelper
    end
    hash[:missing_links] = {:description => [], :instructions => [], }
    description = ""
    description += hash[:instructions_in_html] == false ? ImportedHtmlConverter.convert_text(hash[:description] || "", context) : ImportedHtmlConverter.convert(hash[:description] || "", context, {:missing_links => hash[:missing_links][:description]})
    description += hash[:instructions_in_html] == false ? ImportedHtmlConverter.convert_text(hash[:instructions] || "", context) : ImportedHtmlConverter.convert(hash[:instructions] || "", context, {:missing_links => hash[:missing_links][:instructions]})
    description += Attachment.attachment_list_from_migration(context, hash[:attachment_ids])
    item.description = description

    if hash[:freeze_on_copy]
      item.freeze_on_copy = true
      item.copied = true
      item.copying = true
    end
    if !hash[:submission_types].blank?
      item.submission_types = hash[:submission_types]
    elsif ['discussion_topic'].include?(hash[:submission_format])
      item.submission_types = "discussion_topic"
    elsif ['online_upload','textwithattachments'].include?(hash[:submission_format])
      item.submission_types = "online_upload,online_text_entry"
    elsif ['online_text_entry'].include?(hash[:submission_format])
      item.submission_types = "online_text_entry"
    elsif ['webpage'].include?(hash[:submission_format])
      item.submission_types = "online_upload"
    elsif ['online_quiz'].include?(hash[:submission_format])
      item.submission_types = "online_quiz"
    elsif ['external_tool'].include?(hash[:submission_format])
      item.submission_types = "external_tool"
    end
    if item.submission_types == "online_quiz"
      item.saved_by = :quiz
    end
    if item.submission_types == "discussion_topic"
      item.saved_by = :discussion_topic
    end

    if hash[:grading_type]
      item.grading_type = hash[:grading_type]
      item.points_possible = hash[:points_possible]
    elsif grading = hash[:grading]
      hash[:due_at] ||= grading[:due_at] || grading[:due_date]
      hash[:assignment_group_migration_id] ||= grading[:assignment_group_migration_id]
      if grading[:grade_type] =~ /numeric|points/i
        item.points_possible = grading[:points_possible] ? grading[:points_possible].to_f : 10
      elsif grading[:grade_type] =~ /alphanumeric|letter_grade/i
        item.grading_type = "letter_grade"
        item.points_possible = grading[:points_possible] ? grading[:points_possible].to_f : 100
      elsif grading[:grade_type] == 'rubric'
        hash[:rubric_migration_id] ||= grading[:rubric_id]
      elsif grading[:grade_type] == 'not_graded'
        item.submission_types = 'not_graded'
      end
    end

    # Associating with a rubric or a quiz might cause item to get saved, no longer indicating
    # that it is a new record.  We need to know that below, where we add to the list of
    # imported items
    new_record = item.new_record?
    if hash[:rubric_migration_id]
      rubric = context.rubrics.find_by_migration_id(hash[:rubric_migration_id])
      if rubric
        assoc = rubric.associate_with(item, context, :purpose => 'grading')
        assoc.use_for_grading = !!hash[:rubric_use_for_grading] if hash.has_key?(:rubric_use_for_grading)
        assoc.hide_score_total = !!hash[:rubric_hide_score_total] if hash.has_key?(:rubric_hide_score_total)
        if hash[:saved_rubric_comments]
          assoc.summary_data ||= {}
          assoc.summary_data[:saved_comments] ||= {}
          assoc.summary_data[:saved_comments] = hash[:saved_rubric_comments]
        end
        assoc.save
      end
    end
    if hash[:grading_standard_migration_id]
      gs = context.grading_standards.find_by_migration_id(hash[:grading_standard_migration_id])
      item.grading_standard = gs if gs
    end
    if hash[:quiz_migration_id]
      if quiz = context.quizzes.find_by_migration_id(hash[:quiz_migration_id])
        # the quiz is published because it has an assignment
        quiz.assignment = item
        quiz.generate_quiz_data
        quiz.published_at = Time.now
        quiz.workflow_state = 'available'
        quiz.save
      end
      item.submission_types = 'online_quiz'
      item.saved_by = :quiz
    end
    if hash[:assignment_group_migration_id]
      item.assignment_group = context.assignment_groups.find_by_migration_id(hash[:assignment_group_migration_id])
    end
    item.assignment_group ||= context.assignment_groups.find_or_create_by_name(t :imported_assignments_group, "Imported Assignments")

    hash[:due_at] ||= hash[:due_date]
    [:due_at, :lock_at, :unlock_at, :peer_reviews_due_at].each do |key|
      item.send"#{key}=", Canvas::Migration::MigratorHelper.get_utc_time_from_timestamp(hash[key]) unless hash[key].nil?
    end

    [:turnitin_enabled, :peer_reviews_assigned, :peer_reviews,
     :automatic_peer_reviews, :anonymous_peer_reviews,
     :grade_group_students_individually, :allowed_extensions, :min_score,
     :max_score, :mastery_score, :position, :peer_review_count
    ].each do |prop|
      item.send("#{prop}=", hash[prop]) unless hash[prop].nil?
    end

    context.imported_migration_items << item if context.imported_migration_items && new_record
    item.save_without_broadcasting!

    if context.respond_to?(:content_migration) && context.content_migration
      hash[:missing_links].each do |field, missing_links|
        context.content_migration.add_missing_content_links(:class => item.class.to_s,
          :id => item.id, :field => field, :missing_links => missing_links,
          :url => "/#{context.class.to_s.underscore.pluralize}/#{context.id}/#{item.class.to_s.underscore.pluralize}/#{item.id}")
      end
    end

    if item.submission_types == 'external_tool'
      tag = item.create_external_tool_tag(:url => hash[:external_tool_url], :new_tab => hash[:external_tool_new_tab])
      tag.content_type = 'ContextExternalTool'
      if !tag.save
        context.add_migration_warning(t('errors.import.external_tool_url', "The url for the external tool assignment \"%{assignment_name}\" wasn't valid.", :assignment_name => item.title)) if tag.errors["url"]
        item.external_tool_tag = nil
      end
    end

    if context.respond_to?(:assignment_group_no_drop_assignments) && context.assignment_group_no_drop_assignments
      if group = context.assignment_group_no_drop_assignments[item.migration_id]
        AssignmentGroup.add_never_drop_assignment(group, item)
      end
    end

    item
  end

  def expects_submission?
    submission_types && submission_types.strip != "" && submission_types != "none" && submission_types != 'not_graded' && submission_types != "on_paper" && submission_types != 'external_tool'
  end

  def expects_external_submission?
    submission_types == 'on_paper' || submission_types == 'external_tool'
  end

  def allow_google_docs_submission?
    self.submission_types && 
      self.submission_types.match(/online_upload/) && 
      (self.allowed_extensions.blank? || self.allowed_extensions.grep(/doc|xls|ppt/).present?)
  end

  def <=>(comparable)
    sort_key <=> comparable.sort_key
  end

  def sort_key
    # undated assignments go last
    [due_at ? 0 : 1, due_at || 0, title]
  end

  def special_class; nil; end

  def submission_action_string
    if submission_types == "online_quiz"
      t :submission_action_take_quiz, "Take %{title}", :title => title
    else
      t :submission_action_turn_in_assignment, "Turn in %{title}", :title => title
    end
  end


    # Takes an array of hashes and groups them by their :user entry.  All
    # hashes must have a user entry.
    def partition_for_user(list)
      return [] if list.empty?
      index = list.first[:user]
      found, remainder = list.partition { |e| e[:user] == index }
      if remainder.empty?
        [found]
      else
        [found] + partition_for_user(remainder)
      end
    end
    protected :partition_for_user

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
      user = User.find_by_id(user_id)
      submission = Submission.find_by_user_id_and_assignment_id(user_id, self.id)
    end
    attachment = Attachment.find_by_id(attachment_id) if attachment_id

    if !attachment || !submission
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

  def needs_grading_count_for_user(user)
    vis = self.context.section_visibilities_for(user)
    self.shard.activate do
      # the needs_grading_count trigger should change self.updated_at, invalidating the cache
      Rails.cache.fetch(['assignment_user_grading_count', self, user].cache_key) do
        case self.context.enrollment_visibility_level_for(user, vis)
          when :full
            self.needs_grading_count
          when :sections
            self.submissions.joins("INNER JOIN enrollments e ON e.user_id = submissions.user_id").
                where(<<-SQL, self, self.context, vis.map {|v| v[:course_section_id]}).count(:id, :distinct => true)
              submissions.assignment_id = ?
                AND e.course_id = ?
                AND e.course_section_id in (?)
                AND e.type IN ('StudentEnrollment', 'StudentViewEnrollment')
                AND e.workflow_state = 'active'
                AND submissions.submission_type IS NOT NULL
                AND (submissions.workflow_state = 'pending_review'
                  OR (submissions.workflow_state = 'submitted'
                    AND (submissions.score IS NULL OR NOT submissions.grade_matches_current_submission)))
              SQL
          else
            0
        end
      end
    end
  end

  def recompute_submission_lateness_later
    if due_at_changed?
      send_later_if_production :recompute_submission_lateness
    end
    true
  end

  def recompute_submission_lateness
    submissions.find_each do |s|
      s.compute_lateness
      s.save!
    end
    true
  end

  def graded?
    submission_types != 'not_graded'
  end

  def active?
    workflow_state != 'deleted'
  end
end
