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

require 'set'

class Assignment < ActiveRecord::Base
  include Workflow
  include TextHelper
  include HasContentTags
  include CopyAuthorizedLinks
  
  attr_accessible :title, :name, :description, :due_at, :points_possible,
    :min_score, :max_score, :mastery_score, :grading_type, :submission_types,
    :assignment_group, :unlock_at, :lock_at, :group_category,
    :peer_review_count, :peer_reviews_due_at, :grading_standard_id,
    :peer_reviews, :automatic_peer_reviews, :grade_group_students_individually,
    :notify_of_update, :time_zone_edited, :turnitin_enabled,
    :set_custom_field_values, :context, :position, :allowed_extensions
  attr_accessor :original_id
  
  has_many :submissions, :class_name => 'Submission', :dependent => :destroy
  has_many :terse_submissions, :class_name => 'Submission'
  has_many :verbose_submissions, :class_name => 'Submission', :include => [:submission_comments, :versions, :attachments, :rubric_assessment]
  has_many :attachments, :as => :context, :dependent => :destroy
  has_one :quiz
  belongs_to :assignment_group
  has_one :discussion_topic, :conditions => ['discussion_topics.root_topic_id IS NULL'], :order => 'created_at'
  has_one :context_module_tag, :as => :content, :class_name => 'ContentTag', :conditions => ['content_tags.tag_type = ? AND workflow_state != ?', 'context_module', 'deleted'], :include => {:context_module => [:context_module_progressions, :content_tags]}
  has_many :learning_outcome_tags, :as => :content, :class_name => 'ContentTag', :conditions => ['content_tags.tag_type = ? AND content_tags.workflow_state != ?', 'learning_outcome', 'deleted'], :include => :learning_outcome
  has_one :rubric_association, :as => :association, :conditions => ['rubric_associations.purpose = ?', "grading"], :order => :created_at, :include => :rubric
  has_one :rubric, :through => :rubric_association
  has_one :teacher_enrollment, :class_name => 'TeacherEnrollment', :foreign_key => 'course_id', :primary_key => 'context_id', :include => :user, :conditions => ['enrollments.workflow_state = ?', 'active']
  belongs_to :context, :polymorphic => true
  belongs_to :cloned_item
  belongs_to :grading_standard
  has_many :assignment_reminders, :dependent => :destroy

  validates_presence_of :context_id
  validates_presence_of :context_type
  validates_length_of :title, :maximum => maximum_string_length, :allow_nil => true
  validates_length_of :description, :maximum => maximum_long_text_length, :allow_nil => true, :allow_blank => true

  acts_as_list :scope => :assignment_group_id
  adheres_to_policy
  has_a_broadcast_policy
  simply_versioned :keep => 5
  sanitize_field :description, Instructure::SanitizeField::SANITIZE
  copy_authorized_links( :description) { [self.context, nil] }

  has_custom_fields :scopes => %w(root_account)

  def root_account
    context && context.root_account
  end

  def name=(val)
    self.title = val
  end

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
                :update_grades_if_details_changed
  
  after_save    :generate_reminders_if_changed,
                :touch_assignment_group,
                :touch_context,
                :update_grading_standard,
                :update_quiz_or_discussion_topic,
                :update_submissions_later,
                :clear_unannounced_grading_changes_if_just_unpublished,
                :schedule_do_auto_peer_review_job_if_automatic_peer_review,
                :delete_empty_abandoned_children,
                :remove_assignment_updated_flag
                
  def schedule_do_auto_peer_review_job_if_automatic_peer_review 
    # I was going to be smart and get rid of any existing job, 
    # but i figured it wasn't worth the extra column needed to keep track of a auto_peer_review_assigner_job_id
    # or the extra code needed.  The way this is now, it schedules a new job evertime this assignment gets saved 
    # (if it is supposed to be auto_peer_reviewed)
    if peer_reviews && automatic_peer_reviews && !peer_reviews_assigned
      # handle if it has already come due, but has not yet been auto_peer_reviewed
      if due_at && due_at <= Time.now
        # do_auto_peer_review
      else
       self.send_at(due_at, :do_auto_peer_review)
      end
    end
    true
  end
  
  def do_auto_peer_review
    assign_peer_reviews if peer_reviews && automatic_peer_reviews && !peer_reviews_assigned && due_at <= Time.now
  end
  
  def touch_assignment_group
    AssignmentGroup.update_all({:updated_at => Time.now}, {:id => self.assignment_group_id}) if self.assignment_group_id
    true
  end
  
  def update_student_grades(old_points_possible, old_grading_type)
    submissions.graded.each do |submission|
      submission.grade = score_to_grade(submission.score)
      submission.save
    end
  end
  
  # if a teacher changes the settings for an assignment and students have
  # already been graded, then we need to update the "grade" column to
  # reflect the changes
  def update_grades_if_details_changed
    if !new_record? && (points_possible_changed? || grading_type_changed? || grading_standard_id_changed?) && !submissions.graded.empty?
      send_later_if_production(:update_student_grades, points_possible_was, grading_type_was)
    end
    true
  end
  
  def default_values
    raise "Assignments can only be assigned to Course records" if self.context_type && self.context_type != "Course"
    self.context_code = "#{self.context_type.underscore}_#{self.context_id}"
    self.title ||= (self.assignment_group.default_assignment_name rescue nil) || "Assignment"
    self.grading_type = "pass_fail" if self.submission_types == "attendance"
    zoned_due_at = self.due_at && ActiveSupport::TimeWithZone.new(self.due_at.utc, (ActiveSupport::TimeZone.new(self.time_zone_edited) rescue nil) || Time.zone)
    if self.due_at_changed?
      if zoned_due_at && zoned_due_at.strftime("%H:%M") == '23:59'
        self.all_day = true
      elsif self.due_at && self.due_at_was && self.all_day && self.due_at.strftime("%H:%M") == self.due_at_was.strftime("%H:%M")
        self.all_day = true
      else
        self.all_day = false
      end
    end
    if self.assignment_group && self.assignment_group.deleted? && !self.deleted?
      self.assignment_group_id = nil
    end
    self.assignment_group_id ||= self.context.assignment_groups.active.first.id rescue nil
    self.mastery_score = [self.mastery_score, self.points_possible].min if self.mastery_score && self.points_possible
    self.all_day_date = (zoned_due_at.to_date rescue nil) if !self.all_day_date || self.due_at_changed? || self.all_day_date_changed?
    self.submission_types ||= "none"
    self.anonymous_peer_reviews = true if self.peer_reviews
    @workflow_state_was = self.workflow_state_was
    @points_possible_was = self.points_possible_was
    @submission_types_was = self.submission_types_was
    @due_at_was = self.due_at_was
    self.points_possible = nil if self.submission_types == 'not_graded'
  end
  protected :default_values
  
  def attendance?
    submission_types == 'attendance'
  end
  
  def due_date
    self.all_day ? self.all_day_date : self.due_at
  end
  
  def clear_unannounced_grading_changes_if_just_unpublished
    if @workflow_state_was == 'published' && self.available?
      Submission.update_all({:changed_since_publish => false}, {:assignment_id => self.id})
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
  
  def turnitin_enabled?
    self.turnitin_enabled
  end
  
  attr_accessor :updated_submissions
  def update_submissions_later
    if @old_assignment_group_id != self.assignment_group_id
      AssignmentGroup.find_by_id(@old_assignment_group_id).touch rescue nil
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
    self.submissions.each do |submission|
      @updated_submissions << submission
      if just_published
        submission.assignment_just_published!
      else
        submission.save!
      end
    end
  end
  
  def update_quiz_or_discussion_topic
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
      quiz.save
    elsif self.submission_types == "discussion_topic" && @saved_by != :discussion_topic
      topic = DiscussionTopic.find_by_assignment_id(self.id) || self.context.discussion_topics.build
      topic.assignment_id = self.id
      topic.title = self.title
      topic.message = self.description
      topic.saved_by = :assignment
      topic.updated_at = Time.now
      topic.workflow_state = 'active' if topic.deleted?
      topic.save
    end
  end
  attr_writer :saved_by
  
  def update_grading_standard
    self.grading_standard.save! if self.grading_standard
  end
  
  def context_module_action(user, action, points=nil)
    self.context_module_tag.context_module_action(user, action, points) if self.context_module_tag
    if self.submission_types == 'discussion_topic' && self.discussion_topic && self.discussion_topic.context_module_tag
      self.discussion_topic.context_module_tag.context_module_action(user, action, points)
    elsif self.submission_types == 'online_quiz' && self.quiz && self.quiz.context_module_tag
      self.quiz.context_module_tag.context_module_action(user, action, points)
    end
  end
  
  set_broadcast_policy do |p|
    p.dispatch :assignment_due_date_changed
    p.to { participants }
    p.whenever { |record|
      !self.suppress_broadcast and
      record.context.state == :available and record.changed_in_states([:available,:published], :fields => :due_at) and
      record.prior_version && (record.due_at.to_i.divmod(60)[0]) != (record.prior_version.due_at.to_i.divmod(60)[0]) and
      record.created_at < 3.hours.ago
    }
    
    p.dispatch :assignment_changed
    p.to { participants }
    p.whenever { |record| 
      !self.suppress_broadcast and
      record.created_at < Time.now - (30*60) and
      record.context.state == :available and [:available, :published].include?(record.state) and
      record.prior_version and (record.points_possible != record.prior_version.points_possible || @assignment_changed)
    }
    
    p.dispatch :assignment_created
    p.to { participants }
    p.whenever { |record| 
      !self.suppress_broadcast and
      record.context.state == :available and record.just_created 
    }
    
    p.dispatch :assignment_graded
    p.to { @students_whose_grade_just_changed }
    p.whenever {|record|
      !self.suppress_broadcast and
      @notify_affected_students_of_grading_change and 
      record.context.state == :available and
      @students_whose_grade_just_changed and !@students_whose_grade_just_changed.empty?
    }
      
    
    p.dispatch :assignment_graded
    p.to { participants }
    p.whenever {|record|
      !self.suppress_broadcast and
      @notify_all_students_of_grading and
      record.context.state == :available
    }

  end
  
  def notify_of_update=(val)
    @assignment_changed = (val == '1' || val == true)
  end

  def notify_of_update
    false
  end
  
  def remove_assignment_updated_flag
    @assignment_changed = false
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
    self.discussion_topic.destroy if self.discussion_topic && !self.discussion_topic.deleted?
    self.quiz.destroy if self.quiz && !self.quiz.deleted?
    ContentTag.delete_for(self)
    self.save
  end
  
  def time_zone_edited
    CGI::unescapeHTML(read_attribute(:time_zone_edited) || "")
  end
  
  def restore(from=nil)
    self.workflow_state = 'published'
    self.save
    self.discussion_topic.restore if self.discussion_topic && from != :discussion_topic
    self.quiz.restore if self.quiz && from != :quiz
  end
  
  def participants
    self.context.participants
  end
  
  def infer_state_from_course
    self.workflow_state = "published" if (self.context.publish_grades_immediately rescue false)
  end
  protected :infer_state_from_course
  
  attr_accessor :saved_by
  def process_if_quiz
    if self.submission_types == "online_quiz"
      self.points_possible = self.quiz.points_possible || 0.0 if self.quiz && self.quiz.available?
      if self.quiz && @saved_by != :quiz # save initiated by assignment, not quiz
        q = self.quiz
        q.due_at = self.due_at
        q.lock_at = self.lock_at
        q.unlock_at = self.unlock_at
        q.saved_by = :assignment
        q.save
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
  
  def score_to_grade(score=0.0)
    result = score.to_f
    if self.grading_type == "percent"
      result = score.to_f / self.points_possible
      result = (result * 1000.0).round / 10.0
      result = "#{result}%"
    elsif self.grading_type == "pass_fail"
      result = score.to_f == self.points_possible ? "complete" : "incomplete"
      result = "complete" if !self.points_possible && score > 0.0
    elsif self.grading_type == "letter_grade"
      grades = self.grading_scheme.sort_by{|s| s[1]}.reverse
      found = false
      score = score.to_f / self.points_possible
      result = grades[0][1]
      grades.each do |g|
        if score <= g[1]
          found = true
          result = g[0]
        end
      end
      result = grades[-1] if !result
    end
    result
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
      points_possible
    when "fail", "incomplete"
      0.0
    else
      # try to treat it as a letter grade
      if grading_scheme 
        percentage = grading_scheme[grade]
        percentage ||= grading_scheme.detect{|g, percent| g.downcase == grade.downcase }.try(:last)
        if percentage
          (points_possible * percentage * 100.0).round / 100.0
        else
          nil
        end
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
        points_possible || 1.0
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

  def infer_due_at
    # set to 11:59pm if it's 12:00am
    self.due_at += ((60 * 60 * 24) - 60) if self.due_at && self.due_at.hour == 0 && self.due_at.min == 0
  end

  def to_atom(opts={})
    extend ApplicationHelper
    Atom::Entry.new do |entry|
      entry.title     = "Assignment#{", " + self.context.name if opts[:include_context]}: #{self.title}"
      entry.updated   = self.updated_at.utc
      entry.published = self.created_at.utc
      entry.id        = "tag:#{HostUrl.default_host},#{self.created_at.strftime("%Y-%m-%d")}:/assignments/#{self.feed_code}_#{self.due_at.strftime("%Y-%m-%d-%H-%M") rescue "none"}"
      entry.links    << Atom::Link.new(:rel => 'alternate', 
                                    :href => "http://#{HostUrl.context_host(self.context)}/#{context_url_prefix}/assignments/#{self.id}")
      entry.content   = Atom::Content::Html.new("Due: #{datetime_string(self.due_at, :due_date)}<br/>#{self.description}<br/><br/>
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
    cal = Icalendar::Calendar.new
    # to appease Outlook
    cal.custom_property("METHOD","PUBLISH")

    event = Icalendar::Event.new
    event.klass =       "PUBLIC"
    event.start =       DateTime.civil(
                          self.due_at.utc.strftime("%Y").to_i, 
                          self.due_at.utc.strftime("%m").to_i,
                          self.due_at.utc.strftime("%d").to_i,
                          self.due_at.utc.strftime("%H").to_i, 
                          self.due_at.utc.strftime("%M").to_i) if self.due_at
    event.start.icalendar_tzid = 'UTC' if event.start
    event.end = event.start if event.start
    event.end.icalendar_tzid = 'UTC' if event.end
    if self.all_day
      event.start = Date.new(self.all_day_date.year, self.all_day_date.month, self.all_day_date.day)
      event.start.ical_params = {"VALUE"=>["DATE"]}
      event.end = event.start
      event.end.ical_params = {"VALUE"=>["DATE"]}
    end
    event.summary =     self.title
    event.description = self.description
    event.location =    self.location
    event.dtstamp =     self.updated_at.to_datetime
    # This will change when there are other things that have calendars...
    # can't call calendar_url or calendar_url_for here, have to do it manually
    event.url           "http://#{HostUrl.context_host(self.context)}/calendar?include_contexts=#{self.context.asset_string}&month=#{self.due_at.strftime("%m") rescue ""}&year=#{self.due_at.strftime("%Y") rescue ""}#assignment_#{self.id.to_s}"
    event.uid           "event-assignment-#{self.id.to_s}"
    event.sequence      0
    event = nil unless self.due_at
    
    return event unless in_own_calendar

    cal.add_event(event) if event

    return cal.to_ical

  end
  
  def all_day
    read_attribute(:all_day) || (self.new_record? && self.due_at && (self.due_at.strftime("%H:%M") == '23:59' || self.due_at.strftime("%H:%M") == '00:00'))
  end

  def locked_for?(user=nil, opts={})
    @locks ||= {}
    locked = false
    return false if opts[:check_policies] && self.grants_right?(user, nil, :update)
    @locks[user ? user.id : 0] ||= Rails.cache.fetch(['_locked_for', self, user].cache_key, :expires_in => 1.minute) do
      locked = false
      if (self.unlock_at && self.unlock_at > Time.now)
        locked = {:asset_string => self.asset_string, :unlock_at => self.unlock_at}
      elsif (self.lock_at && self.lock_at <= Time.now)
        locked = {:asset_string => self.asset_string, :lock_at => self.lock_at}
      elsif (self.could_be_locked && self.context_module_tag && !self.context_module_tag.available_for?(user, opts[:deep_check_if_needed]))
        locked = {:asset_string => self.asset_string, :context_module => self.context_module_tag.context_module.attributes}
      end
      locked
    end
  end
  
  def submittable_type?
    submission_types && self.submission_types != "" && self.submission_types != "none" && self.submission_types != 'not_graded' && self.submission_types != "online_quiz" && self.submission_types != 'discussion_topic' && self.submission_types != 'attendance'
  end
  
  def graded_count
    return read_attribute(:graded_count).to_i if read_attribute(:graded_count)
    Rails.cache.fetch(['graded_count', self].cache_key) do
      self.submissions.select(&:graded?).length
    end
  end
  
  def has_submitted_submissions?
    submitted_count > 0
  end
  
  def submitted_count
    return read_attribute(:submitted_count).to_i if read_attribute(:submitted_count)
    Rails.cache.fetch(['submitted_count', self].cache_key) do
      self.submissions.select{|s| s.has_submission? }.length
    end
  end
  
  set_policy do
    given { |user, session| self.cached_context_grants_right?(user, session, :read) }#students.find_by_id(user) }
    set { can :read and can :read_own_submission }
    
    given { |user, session| self.submittable_type? && 
      self.cached_context_grants_right?(user, session, :participate_as_student) &&
      !self.locked_for?(user)
    }
    set { can :submit and can :attach_submission_comment_files }
    
    given { |user, session| !self.locked_for?(user) && 
      (self.context.allow_student_assignment_edits rescue false) && 
      self.cached_context_grants_right?(user, session, :participate_as_student)
    }
    set { can :update_content }
    
    given { |user, session| self.cached_context_grants_right?(user, session, :manage_grades) }#self.context.admins.find_by_id(user) }
    set { can :update and can :update_content and can :grade and can :delete and can :create and can :read and can :attach_submission_comment_files }
    
    given { |user, session| self.cached_context_grants_right?(user, session, :manage_assignments) }#self.context.admins.find_by_id(user) }
    set { can :update and can :update_content and can :delete and can :create and can :read and can :attach_submission_comment_files }
  end

  def self.search(query)
    find(:all, :conditions => wildcard('title', 'description', query))
  end
  
  def grade_distribution
    tally = 0
    cnt = 0
    scores = self.submissions.map{|s| s.score}.compact
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
    self.context.students.each do |student|
      submission = self.find_or_create_submission(student)
      if !submission.score || options[:overwrite_existing_grades]
        if submission.score != score
          submission.score = score
          submissions_to_save << submission
          @students_whose_grade_just_changed << student
        end
      end
    end
    Enrollment.send_later_if_production(:recompute_final_score, context.students.map(&:id), self.context_id) rescue nil
    send_later_if_production(:multiple_module_actions, context.students.map(&:id), :scored, score)
    
    changed_since_publish = !!self.available?
    Submission.update_all({:score => score, :grade => grade, :published_score => score, :published_grade => grade, :changed_since_publish => changed_since_publish, :workflow_state => 'graded', :graded_at => Time.now}, {:id => submissions_to_save.map(&:id)} ) unless submissions_to_save.empty?
  end
  
  def update_user_from_rubric(user, assessment)
    score = self.points_possible * (assessment.score / assessment.rubric.points_possible)
    self.grade_student(user, :grade => self.score_to_grade(score), :grader => assessment.assessor)
  end
  
  def title_with_id
    "#{title} (#{id})"
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
    if self.group_category
      group = self.context.groups.active.for_category(self.group_category).to_a.find{|g| g.users.include?(student)}
      students = (group.users & self.context.students) if group && !self.grade_group_students_individually
    end
    [group, students]
  end
  
  def multiple_module_actions(student_ids, action, points=nil)
    students = self.context.students.find_all_by_id(student_ids).compact
    students.each do |user|
      self.context_module_action(user, action, points)
    end
  end
  
  def grade_student(original_student, opts={})
    raise "Student is required" unless original_student
    raise "Student must be enrolled in the course as a student to be graded" unless original_student && self.context.students.include?(original_student)
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
      :unique_key => Time.now.to_s
    }
    submissions = []
    tags = self.learning_outcome_tags.select{|t| !t.rubric_association_id }

    students.each do |student|
      submission_updated = false
      submission = self.find_or_create_submission(student) #submissions.find_or_create_by_user_id(student.id) #(:first, :conditions => {:assignment_id => self.id, :user_id => student.id})
      if student == original_student || !grade_group_students_individually
        submission.attributes = opts
        submission.assignment_id = self.id
        submission.user_id = student.id
        submission.grader_id = grader.id rescue nil
        if !opts[:grade] || opts[:grade] == ""
          submission.score = nil
          submission.grade = nil
        end
        did_grade = false
        if submission.grade
          did_grade = true
          submission.score = self.grade_to_score(submission.grade)
        end
        if self.points_possible && self.points_possible > 0 && submission.score
          did_grade = true
          submission.grade = self.score_to_grade(submission.score) 
        end
        submission.grade_matches_current_submission = true if did_grade
        submission_updated = true if submission.changed?
        submission.workflow_state = "graded" if submission.score_changed? || submission.grade_matches_current_submission
        submission.group = group
        submission.save!
        tags.each do |tag|
          tag.create_outcome_result(student, self, submission)
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
    attempts = 0
    begin
      s = Submission.find_or_initialize_by_assignment_id_and_user_id(assignment_id, user_id)
      s.created_correctly_from_assignment_rb = true
      s.save_without_broadcast if s.new_record?
      raise "bad" if s.new_record?
    rescue => e
      attempts += 1
      retry if attempts < 3
    end
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
    opts[:unique_key] = Time.now.to_s
    opts[:author] ||= opts[:commenter] || User.find_by_id(opts[:user_id])
    opts[:anonymous] = opts[:author] != original_student && self.anonymous_peer_reviews && !self.grants_right?(opts[:author], nil, :grade)
    
    if opts[:comment] && opts[:assessment_request]
      # if there is no rubric the peer review is complete with just a comment
      opts[:assessment_request].complete unless opts[:assessment_request].rubric_association
    end
    
    students.each do |student|
      if (opts['comment'] && opts['group_comment'] == "1") || student == original_student
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
      opts.delete(k) unless [:body, :url, :attachments, :submission_type, :comment, :media_comment_id, :media_comment_type].include?(k.to_sym) 
    }
    raise "Student Required" unless original_student
    raise "User must be enrolled in the course as a student to submit homework" unless context.students.include?(original_student)
    comment = opts.delete :comment
    group, students = group_students(original_student)
    homeworks = []
    ts = Time.now.to_s
    students.each do |student|
      homework = self.find_or_create_submission(student)
      homework.grade_matches_current_submission = homework.score ? false : true
      homework.attributes = opts.merge({
        :attachment => nil,
        :processed => false,
        :process_attempts => 0,
        :workflow_state => "submitted",
        :group => group
      })
      homework.submitted_at = Time.now

      homework.with_versioning(true) do
        group ? homework.save_without_broadcast : homework.save
      end
      context_module_action(student, :submitted)
      homework.add_comment({:comment => comment, :author => original_student, :unique_key => ts}) if comment
      homeworks << homework
    end
    homeworks[0].broadcast_group_submission if group && !homeworks.empty? 
    touch_context
    return homeworks[0] if homeworks.length == 1
    homeworks.find{|h| h.user_id == original_student.id}
  end
  
  
  
  def submissions_downloaded?
    self.submissions_downloads && self.submissions_downloads > 0
  end
  
  def submissions
    if @speed_grader
      self.verbose_submissions
    else
      self.terse_submissions
    end
  end

  def speed_grader_json(as_json=false)
    @speed_grader = true
    Attachment.skip_thumbnails = true
    res = self.send(as_json ? "as_json" : "to_json", 
      :include => {
        :context => {
          :only => :id,
          :include => {
            :students => {
              :only => nil
            },
            :enrollments  => {
              :only => [:user_id, :course_section_id]
            },
            :active_course_sections => {
              :only => [:id, :name]
            }
          }
        },
        :submissions => {
          :include => {
            :submission_comments => {},
            :attachments => {:except => :thumbnail_url},
            :rubric_assessment => {}
          },
          :methods => [:scribdable?, :conversion_status, :scribd_doc, :submission_history]
        },
        :rubric_association => {
          :except => {}
        }
      },
      :include_root => false
    )
    @speed_grader = false
    Attachment.skip_thumbnails = nil
    res
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
      comment = group.size == 1 ? 'See attached file' : 'See attached files'
      submission = group.first[:submission]
      user = group.first[:user]
      attachments = group.map { |g| FileInContext.attach(self, g[:filename], g[:display_name]) }
      comments << submission.add_comment({:comment => comment, :author => commenter, :attachments => attachments})
    end
    [comments.compact, @ignored_files]
  end
  
  def group_category
    attr = read_attribute(:group_category)
    attr && attr != "" ? attr : nil
  end
  
  def assign_peer_review(reviewer, reviewee)
    reviewer_submission = self.find_or_create_submission(reviewer)
    reviewee_submission = self.find_or_create_submission(reviewee)
    reviewee_submission.assign_assessor(reviewer_submission)
  end

  def assign_peer_reviews
    return [] unless self.peer_review_count && self.peer_review_count > 0

    submissions = self.submissions.having_submission.include_assessment_requests
    student_ids = self.context.students.map(&:id)
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

    if self.peer_reviews_due_at && self.peer_reviews_due_at < Time.now
      self.peer_reviews_assigned = true
    end
    self.save
    return res
  end
  
  def has_peer_reviews?
    self.peer_reviews
  end
  
  def self.percent_considered_graded
    0.5
  end
  
  named_scope :include_submitted_count, lambda {
    {:select => "assignments.*, (SELECT COUNT(*) FROM submissions 
      WHERE assignments.id = submissions.assignment_id 
      AND submissions.submission_type IS NOT NULL) AS submitted_count"
    }
  }
  
  named_scope :include_graded_count, lambda {
    {:select => "assignments.*, (SELECT COUNT(*) FROM submissions 
      WHERE assignments.id = submissions.assignment_id 
      AND submissions.grade IS NOT NULL) AS graded_count"
    }
  }
  
  # don't really need this scope anymore since we are doing the auto_peer_reviews assigning as a delayed job instead of a poller, but I'll leave it here if it is useful to anyone. -RS
  named_scope :to_be_auto_peer_reviewed, lambda {
    {:conditions => ['assignments.peer_reviews_assigned != ? AND assignments.peer_reviews = ? AND assignments.due_at < ? AND assignments.automatic_peer_reviews = ?', true, true, Time.now.utc, true], :order => 'assignments.updated_at, assignments.peer_reviews_due_at' }
  }
  named_scope :include_quiz_and_topic, lambda {
    {:include => [:quiz, :discussion_topic] }
  }
  
  named_scope :no_graded_quizzes_or_topics, :conditions=>"submission_types NOT IN ('online_quiz', 'discussion_topic')"
  
  named_scope :with_context_module_tags, lambda {
    {:include => :context_module_tag }
  }
  
  named_scope :with_submissions, lambda {
    {:include => :submissions }
  }
  
  named_scope :for_context_codes, lambda {|codes|
    {:conditions => ['assignments.context_code IN (?)', codes] }
  }

  named_scope :due_before, lambda{|date|
    {:conditions => ['assignments.due_at < ?', date] }
  }

  named_scope :due_after, lambda{|date|
    {:conditions => ['assignments.due_at > ?', date] }
  }
  named_scope :undated, :conditions => {:due_at => nil}
  
  named_scope :with_just_calendar_attributes, lambda {
    { :select => ((Assignment.column_names & CalendarEvent.column_names) + ['due_at', 'assignment_group_id'] - ['cloned_item_id', 'migration_id']).join(", ") }
  }

  named_scope :due_between, lambda { |start, ending|
    { :conditions => { :due_at => (start)..(ending) } }
  }
  named_scope :updated_after, lambda { |*args|
    if args.first
      { :conditions => [ "assignments.updated_at IS NULL OR assignments.updated_at > ?", args.first ] }
    end
  }
  
  # This should only be used in the course drop down to show assignments recently graded.
  named_scope :need_submitting_info, lambda{|user_id, limit, ignored_ids|
    ignored_ids ||= []
          {:select => 'id, title, points_possible, due_at, context_id, context_type, submission_types,' +
          '(SELECT name FROM courses WHERE id = assignments.context_id) AS context_name',
          :conditions =>["(SELECT COUNT(id) FROM submissions
              WHERE assignment_id = assignments.id
              AND submission_type IS NOT NULL
              AND user_id = ?) = 0 #{ignored_ids.empty? ? "" : "AND id NOT IN (#{ignored_ids.join(',')})"}", user_id],
          :limit => limit,
          :order => 'due_at ASC'
    }
  }

  # This should only be used in the course drop down to show assignments not yet graded.
  named_scope :need_grading_info, lambda{|limit, ignore_ids|
    ignore_ids ||= []
    {
      :select => 'assignments.id, title, points_possible, due_at, context_id, context_type, submission_types, ' +
                 '(SELECT name FROM courses WHERE id = assignments.context_id) AS context_name, needs_grading_count',
      :conditions => "needs_grading_count > 0 #{ignore_ids.empty? ? "" : "AND id NOT IN (#{ignore_ids.join(',')})"}",
      :limit => limit,
      :order=>'due_at ASC'
    }
  }

  named_scope :expecting_submission, :conditions=>"submission_types NOT IN ('', 'none', 'not_graded', 'on_paper') AND submission_types IS NOT NULL" 

  named_scope :mismatched_reminders, lambda {
    {:conditions => ['assignments.due_at IS NOT NULL AND (assignments.reminders_created_for_due_at IS NULL or assignments.due_at != assignments.reminders_created_for_due_at)']}
  }
  
  named_scope :gradeable, lambda {
    {:conditions => ['assignments.submission_types != ?', 'not_graded'] }
  }
  
  named_scope :need_publishing, lambda {
    {:conditions => ['assignments.due_at < ? AND assignments.workflow_state = ?', 1.week.ago, 'available'] }
  }
  
  named_scope :active, :conditions => ['assignments.workflow_state != ?', 'deleted']
  named_scope :before, lambda{|date|
    {:conditions => ['assignments.created_at < ?', date]}
  }

  def needs_publishing?
    self.due_at && self.due_at < 1.week.ago && self.available?
  end
  
  def generate_reminders_if_changed  
    send_later(:generate_reminders!) if (@due_at_was != self.due_at || @submission_types_was != self.submission_types) && due_at && submittable_type?
    true
  end
  
  def generate_reminders!
    return false unless due_at
    due_user_ids = []
    grading_user_ids = []
    assignment_reminders.each do |r|
      res = r.update_for(self)
      if r.reminder_type == 'grading' && res
        grading_user_ids << r.user_id
      elsif r.reminder_type == 'due_at' && res
        due_user_ids << r.user_id
      end
    end
    if submittable_type?
      students = self.context.students
      needed_ids = students.map{|s| s.id} - due_user_ids
      students.select{|s| needed_ids.include?(s.id)}.each do |s|
        r = assignment_reminders.build(:user => s, :reminder_type => 'due_at')
        r.update_for(self)
      end
    end
    admins = self.context.admins
    needed_ids = admins.map{|a| a.id} - grading_user_ids
    admins.select{|a| needed_ids.include?(a.id)}.each do |a|
      r = assignment_reminders.build(:user => a, :reminder_type => 'grading')
      r.update_for(self)
    end
    reminders_created_for_due_at = due_at
    save
  end
  
  def due_reminder_time_for(context, user)
    user.reminder_time_for_due_dates rescue nil
  end
  
  def grading_reminder_time_for(context, user)
    user.reminder_time_for_grading rescue nil
  end
  
  def reminder_teacher_to_publish!
    @remind_teacher_to_publish = true
    self.publishing_reminder_sent = true
    self.save!
    @remind_teacher_to_publish = false
  end
  
  def reminder_teacher_to_grade!
    @remind_teacher_to_grade = true
    self.save!
    @remind_teacher_to_grade = false
  end
  
  def overdue?
    due_at && due_at < Time.now
  end
  
  def readable_submission_types
    return nil unless self.expects_submission?
    res = (self.submission_types || "").split(",").map{|s| readable_submission_type(s) }.compact
    res[-1] = "or " + res[-1] if res.length > 1
    res.join(", ")
  end
  
  def readable_submission_type(submission_type)
    case submission_type
    when 'online_quiz'
      "a quiz"
    when 'online_upload'
      "a file upload"
    when 'online_text_entry'
      "a text entry box"
    when 'online_url'
      "a website url"
    when 'discussion_topic'
      "a discussion post"
    when 'media_recording'
      "a media recording"
    else
      nil
    end
    
  end
  protected :readable_submission_type
  
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
    self.attributes.delete_if{|k,v| [:id, :assignment_group_id, :group_category, :peer_review_count, :peer_reviews_assigned, :reminders_created_for_due_at, :publishing_reminder_sent, :previously_published].include?(k.to_sym) }.each do |key, val|
      dup.send("#{key}=", val)
    end

    context.log_merge_result("The Assignment \"#{self.title}\" was a group assignment, and you'll need to re-set the group settings for this new context") if self.group_category && !self.group_category.empty?
    context.log_merge_result("The Assignment \"#{self.title}\" was a peer review assignment, and you'll need to re-set the peer review settings for this new context") if self.peer_review_count && self.peer_review_count > 0
    
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
    end
    dup.assignment_group_id = context.merge_mapped_id(self.assignment_group) rescue nil
    if dup.assignment_group_id.nil? && self.assignment_group
      new_group = self.assignment_group.clone_for(context)
      new_group.save_without_broadcasting!
      dup.assignment_group = new_group
      context.map_merge(self.assignment_group, new_group)
    end
    context.log_merge_result("Assignment \"#{self.title}\" created")
    context.may_have_links_to_migrate(dup)
    dup.updated_at = Time.now
    dup.clone_updated = true
    dup
  end

  def self.process_migration(data, migration)
    assignments = data['assignments'] ? data['assignments']: []
    to_import = migration.to_import 'assignments'
    assignments.each do |assign|
      if assign['migration_id'] && (!to_import || to_import[assign['migration_id']])
        import_from_migration(assign, migration.context)
      end
    end
    migration_ids = assignments.map{|m| m['assignment_id'] }.compact
    conn = ActiveRecord::Base.connection
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
    if hash[:instructions_in_html] == false
      self.extend TextHelper
    end
    description = ""
    description += hash[:instructions_in_html] == false ? ImportedHtmlConverter.convert_text(hash[:description] || "", context) : ImportedHtmlConverter.convert(hash[:description] || "", context)
    description += hash[:instructions_in_html] == false ? ImportedHtmlConverter.convert_text(hash[:instructions] || "", context) : ImportedHtmlConverter.convert(hash[:instructions] || "", context)
    description += Attachment.attachment_list_from_migration(context, hash[:attachment_ids])
    item.description = description
    if ['discussion_topic'].include?(hash[:submission_format])
      item.saved_by = :discussion_topic
      item.submission_types = "discussion_topic"
    elsif ['online_file_upload','textwithattachments'].include?(hash[:submission_format])
      item.submission_types = "online_file_upload,online_text_entry"
    elsif ['online_text_entry'].include?(hash[:submission_format])
      item.submission_types = "online_text_entry"
    elsif ['webpage'].include?(hash[:submission_format])
      item.submission_types = "online_file_upload"
    elsif ['online_quiz'].include?(hash[:submission_format])
      item.saved_by = :quiz
      item.submission_types = "online_quiz"
    end
    if grading = hash[:grading]
      hash[:due_date] ||= grading[:due_date]
      item.assignment_group = context.assignment_groups.find_by_migration_id(grading[:assignment_group_migration_id]) if grading[:assignment_group_migration_id]
      if grading[:grade_type] == 'numeric'
        item.points_possible = grading[:points_possible] ? grading[:points_possible].to_f : 10
      elsif grading[:grade_type] == 'alphanumeric'
        item.grading_type = "letter_grade"
        item.points_possible = 100
      elsif grading[:grade_type] == 'rubric'
        rubric = context.rubrics.find_by_migration_id(grading[:rubric_id])
        rubric.associate_with(item, context, :purpose => 'grading') if rubric
        # raise "Need to implement rubric_association, probably on the second go-round"
      elsif grading[:grade_type] == 'not_graded'
        item.submission_types = 'not_graded'
      end
    end
    timestamp = hash[:due_date].to_i rescue 0
    item.due_at = Time.at(timestamp / 1000) if timestamp > 0
    item.assignment_group ||= context.assignment_groups.find_or_create_by_name("Imported Assignments")
    context.imported_migration_items << item if context.imported_migration_items && item.new_record?
    item.save_without_broadcasting!
    item
  end

  def self.find_or_create_for_new_context(new_context, old_context, old_id)
    res = new_context.assignments.active.find_by_cloned_item_id(old_context.assignments.find_by_id(old_id).cloned_item_id || 0) rescue nil
    res = nil if res && !res.cloned_item_id
    if !res
      old = old_context.assignments.active.find_by_id(old_id)
      res = old.clone_for(new_context) if old
      res.save if res
    end
    res
  end
  
  def expects_submission?
    submission_types && submission_types.strip != "" && submission_types != "none" && submission_types != 'not_graded' && submission_types != "on_paper"
  end
  
  def <=>(compairable)
    if compairable.respond_to?(:due_at)
      (self.due_at || Time.new) <=> (compairable.due_at || Time.new) 
    end
  end
  
  def special_class; nil; end
  
  def submission_action_string
    if self.submission_types == "online_quiz"
      "Take"
    else
      "Turn in"
    end
  rescue
    "Turn in"
  end
  
  protected
  
    # Takes an array of hashes and groups them by their :user entry.  All
    # hashes must have a user entry. 
    def partition_for_user(list)
      index = list.first[:user]
      found, remainder = list.partition { |e| e[:user] == index }
      if remainder.empty?
        [found]
      else
        [found] + partition_for_user(remainder)
      end
    end
    
    # Infers the user, submission, and attachment from a filename
    def infer_comment_context_from_filename(filename)
      split_filename = filename.split('_')
      # If the filename is like Richards_David_2_link.html, then there is no
      # useful attachment here.  The assignment was submitted as a URL and the
      # teacher commented directly with the gradebook.  Otherwise, grab that
      # last value and strip off everything after the first period. 
      attachment_id = (split_filename[-1] =~ /\Alink/) ? nil : split_filename[-1].split('.')[0].to_i
      attachment_id = nil if filename.match(/\A\._/)
      user_id = split_filename[-2].to_i
      user = User.find_by_id(user_id)
      attachment = Attachment.find_by_id(attachment_id) rescue nil
      submission = Submission.find_by_user_id_and_assignment_id(user_id, self.id)
      if !attachment || !submission
        @ignored_files << filename
        return nil
      end
      return {:user => user, :submission => submission, :filename => filename, :display_name => attachment.display_name}
    end
    
end

