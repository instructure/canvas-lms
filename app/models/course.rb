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

require 'csv'

class Course < ActiveRecord::Base

  include Context
  include Workflow
  include TextHelper
  include HtmlTextHelper

  attr_accessible :name,
                  :section,
                  :account,
                  :group_weighting_scheme,
                  :start_at,
                  :conclude_at,
                  :grading_standard_id,
                  :is_public,
                  :allow_student_wiki_edits,
                  :show_public_context_messages,
                  :syllabus_body,
                  :public_description,
                  :allow_student_forum_attachments,
                  :allow_student_discussion_topics,
                  :allow_student_discussion_editing,
                  :show_total_grade_as_points,
                  :default_wiki_editing_roles,
                  :allow_student_organized_groups,
                  :course_code,
                  :default_view,
                  :show_all_discussion_entries,
                  :open_enrollment,
                  :allow_wiki_comments,
                  :turnitin_comments,
                  :self_enrollment,
                  :license,
                  :indexed,
                  :enrollment_term,
                  :abstract_course,
                  :root_account,
                  :storage_quota,
                  :storage_quota_mb,
                  :restrict_enrollments_to_course_dates,
                  :grading_standard,
                  :grading_standard_enabled,
                  :locale,
                  :integration_id,
                  :hide_final_grades,
                  :hide_distribution_graphs,
                  :lock_all_announcements,
                  :public_syllabus

  serialize :tab_configuration
  serialize :settings, Hash
  belongs_to :root_account, :class_name => 'Account'
  belongs_to :abstract_course
  belongs_to :enrollment_term
  belongs_to :grading_standard
  belongs_to :template_course, :class_name => 'Course'
  has_many :templated_courses, :class_name => 'Course', :foreign_key => 'template_course_id'

  has_many :course_sections
  has_many :active_course_sections, :class_name => 'CourseSection', :conditions => {:workflow_state => 'active'}
  has_many :enrollments, :include => [:user, :course], :conditions => ['enrollments.workflow_state != ?', 'deleted'], :dependent => :destroy
  has_many :all_enrollments, :class_name => 'Enrollment'
  has_many :current_enrollments, :class_name => 'Enrollment', :conditions => "enrollments.workflow_state NOT IN ('rejected', 'completed', 'deleted', 'inactive')", :include => :user
  has_many :typical_current_enrollments, :class_name => 'Enrollment', :conditions => "enrollments.workflow_state NOT IN ('rejected', 'completed', 'deleted', 'inactive') AND enrollments.type NOT IN ('StudentViewEnrollment', 'ObserverEnrollment', 'DesignerEnrollment')", :include => :user
  has_many :prior_enrollments, :class_name => 'Enrollment', :include => [:user, :course], :conditions => "enrollments.workflow_state = 'completed'"
  has_many :prior_users, :through => :prior_enrollments, :source => :user
  has_many :students, :through => :student_enrollments, :source => :user
  has_many :self_enrolled_students, :through => :student_enrollments, :source => :user, :conditions => "self_enrolled"
  has_many :all_students, :through => :all_student_enrollments, :source => :user
  has_many :participating_students, :through => :enrollments, :source => :user, :conditions => "enrollments.type IN ('StudentEnrollment', 'StudentViewEnrollment') and enrollments.workflow_state = 'active'"
  has_many :student_enrollments, :class_name => 'Enrollment', :conditions => "enrollments.workflow_state NOT IN ('rejected', 'completed', 'deleted', 'inactive') AND enrollments.type IN ('StudentEnrollment', 'StudentViewEnrollment')", :include => :user
  has_many :all_student_enrollments, :class_name => 'Enrollment', :conditions => "enrollments.workflow_state != 'deleted' AND enrollments.type IN ('StudentEnrollment', 'StudentViewEnrollment')", :include => :user
  has_many :all_real_users, :through => :all_real_enrollments, :source => :user
  has_many :all_real_enrollments, :class_name => 'Enrollment', :conditions => ["enrollments.workflow_state != 'deleted' AND enrollments.type <> 'StudentViewEnrollment'"], :include => :user
  has_many :all_real_students, :through => :all_real_student_enrollments, :source => :user
  has_many :all_real_student_enrollments, :class_name => 'StudentEnrollment', :conditions => [ "enrollments.type = 'StudentEnrollment'", "enrollments.workflow_state != ?", 'deleted'], :include => :user
  has_many :teachers, :through => :teacher_enrollments, :source => :user
  has_many :teacher_enrollments, :class_name => 'TeacherEnrollment', :conditions => ["enrollments.workflow_state != 'deleted' AND enrollments.type = 'TeacherEnrollment'"], :include => :user
  has_many :tas, :through => :ta_enrollments, :source => :user
  has_many :ta_enrollments, :class_name => 'TaEnrollment', :conditions => ['enrollments.workflow_state != ?', 'deleted'], :include => :user
  has_many :designers, :through => :designer_enrollments, :source => :user
  has_many :designer_enrollments, :class_name => 'DesignerEnrollment', :conditions => ['enrollments.workflow_state != ?', 'deleted'], :include => :user
  has_many :observers, :through => :observer_enrollments, :source => :user
  has_many :participating_observers, :through => :observer_enrollments, :source => :user, :conditions => ['enrollments.workflow_state = ?', 'active']
  has_many :observer_enrollments, :class_name => 'ObserverEnrollment', :conditions => ['enrollments.workflow_state != ?', 'deleted'], :include => :user
  has_many :instructors, :through => :enrollments, :source => :user, :conditions => "enrollments.type = 'TaEnrollment' or enrollments.type = 'TeacherEnrollment'"
  has_many :instructor_enrollments, :class_name => 'Enrollment', :conditions => "(enrollments.type = 'TaEnrollment' or enrollments.type = 'TeacherEnrollment')"
  has_many :participating_instructors, :through => :enrollments, :source => :user, :conditions => "(enrollments.type = 'TaEnrollment' or enrollments.type = 'TeacherEnrollment') and enrollments.workflow_state = 'active'"
  has_many :admins, :through => :enrollments, :source => :user, :conditions => "enrollments.type = 'TaEnrollment' or enrollments.type = 'TeacherEnrollment' or enrollments.type = 'DesignerEnrollment'"
  has_many :admin_enrollments, :class_name => 'Enrollment', :conditions => "(enrollments.type = 'TaEnrollment' or enrollments.type = 'TeacherEnrollment' or enrollments.type = 'DesignerEnrollment')"
  has_many :participating_admins, :through => :enrollments, :source => :user, :conditions => "(enrollments.type = 'TaEnrollment' or enrollments.type = 'TeacherEnrollment' or enrollments.type = 'DesignerEnrollment') and enrollments.workflow_state = 'active'"
  has_many :student_view_students, :through => :student_view_enrollments, :source => :user
  has_many :student_view_enrollments, :class_name => 'StudentViewEnrollment', :conditions => ['enrollments.workflow_state != ?', 'deleted'], :include => :user
  has_many :participating_typical_users, :through => :typical_current_enrollments, :source => :user
  has_many :custom_gradebook_columns, :dependent => :destroy, :order => 'custom_gradebook_columns.position, custom_gradebook_columns.title'

  include LearningOutcomeContext
  include RubricContext

  has_many :course_account_associations
  has_many :non_unique_associated_accounts, :source => :account, :through => :course_account_associations, :order => 'course_account_associations.depth'
  has_many :users, :through => :enrollments, :source => :user, :uniq => true
  has_many :current_users, :through => :current_enrollments, :source => :user, :uniq => true
  has_many :group_categories, :as => :context, :conditions => ['deleted_at IS NULL']
  has_many :all_group_categories, :class_name => 'GroupCategory', :as => :context
  has_many :groups, :as => :context
  has_many :active_groups, :as => :context, :class_name => 'Group', :conditions => ['groups.workflow_state != ?', 'deleted']
  has_many :assignment_groups, :as => :context, :dependent => :destroy, :order => 'assignment_groups.position, assignment_groups.name'
  has_many :assignments, :as => :context, :dependent => :destroy, :order => 'assignments.created_at'
  has_many :calendar_events, :as => :context, :conditions => ['calendar_events.workflow_state != ?', 'cancelled'], :dependent => :destroy
  has_many :submissions, :through => :assignments, :order => 'submissions.updated_at DESC', :dependent => :destroy
  has_many :discussion_topics, :as => :context, :conditions => ['discussion_topics.workflow_state != ?', 'deleted'], :include => :user, :dependent => :destroy, :order => 'discussion_topics.position DESC, discussion_topics.created_at DESC'
  has_many :active_discussion_topics, :as => :context, :class_name => 'DiscussionTopic', :conditions => ['discussion_topics.workflow_state != ?', 'deleted'], :include => :user
  has_many :all_discussion_topics, :as => :context, :class_name => "DiscussionTopic", :include => :user, :dependent => :destroy
  has_many :discussion_entries, :through => :discussion_topics, :include => [:discussion_topic, :user], :dependent => :destroy
  has_many :announcements, :as => :context, :class_name => 'Announcement', :dependent => :destroy
  has_many :active_announcements, :as => :context, :class_name => 'Announcement', :conditions => ['discussion_topics.workflow_state != ?', 'deleted']
  has_many :attachments, :as => :context, :dependent => :destroy, :extend => Attachment::FindInContextAssociation
  has_many :active_images, :as => :context, :class_name => 'Attachment', :conditions => ["attachments.file_state != ? AND attachments.content_type LIKE 'image%'", 'deleted'], :order => 'attachments.display_name', :include => :thumbnail
  has_many :active_assignments, :as => :context, :class_name => 'Assignment', :conditions => ['assignments.workflow_state != ?', 'deleted'], :order => 'assignments.title, assignments.position'
  has_many :folders, :as => :context, :dependent => :destroy, :order => 'folders.name'
  has_many :active_folders, :class_name => 'Folder', :as => :context, :conditions => ['folders.workflow_state != ?', 'deleted'], :order => 'folders.name'
  has_many :active_folders_with_sub_folders, :class_name => 'Folder', :as => :context, :include => [:active_sub_folders], :conditions => ['folders.workflow_state != ?', 'deleted'], :order => 'folders.name'
  has_many :active_folders_detailed, :class_name => 'Folder', :as => :context, :include => [:active_sub_folders, :active_file_attachments], :conditions => ['folders.workflow_state != ?', 'deleted'], :order => 'folders.name'
  has_many :messages, :as => :context, :dependent => :destroy
  has_many :context_external_tools, :as => :context, :dependent => :destroy, :order => 'name'
  belongs_to :wiki
  has_many :quizzes, :class_name => 'Quizzes::Quiz', :as => :context, :dependent => :destroy, :order => 'lock_at, title'
  has_many :active_quizzes, :class_name => 'Quizzes::Quiz', :as => :context, :include => :assignment, :conditions => ['quizzes.workflow_state != ?', 'deleted'], :order => 'created_at'
  has_many :assessment_questions, :through => :assessment_question_banks
  has_many :assessment_question_banks, :as => :context, :include => [:assessment_questions, :assessment_question_bank_users]
  def inherited_assessment_question_banks(include_self = false)
    self.account.inherited_assessment_question_banks(true, *(include_self ? [self] : []))
  end

  has_many :external_feeds, :as => :context, :dependent => :destroy
  belongs_to :default_grading_standard, :class_name => 'GradingStandard', :foreign_key => 'grading_standard_id'
  has_many :grading_standards, :as => :context, :conditions => ['workflow_state != ?', 'deleted']
  has_one :gradebook_upload, :as => :context, :dependent => :destroy
  has_many :web_conferences, :as => :context, :order => 'created_at DESC', :dependent => :destroy
  has_many :collaborations, :as => :context, :order => 'title, created_at', :dependent => :destroy
  has_many :context_modules, :as => :context, :order => :position, :dependent => :destroy
  has_many :active_context_modules, :as => :context, :class_name => 'ContextModule', :conditions => {:workflow_state => 'active'}
  has_many :context_module_tags, :class_name => 'ContentTag', :as => 'context', :order => :position, :conditions => ['tag_type = ?', 'context_module'], :dependent => :destroy
  has_many :media_objects, :as => :context
  has_many :page_views, :as => :context
  has_many :asset_user_accesses, :as => :context
  has_many :role_overrides, :as => :context
  has_many :content_migrations, :foreign_key => :context_id
  has_many :content_exports
  has_many :course_imports
  has_many :alerts, :as => :context, :include => :criteria
  has_many :appointment_group_contexts, :as => :context
  has_many :appointment_groups, :through => :appointment_group_contexts
  has_many :appointment_participants, :class_name => 'CalendarEvent', :foreign_key => :effective_context_code, :primary_key => :asset_string, :conditions => "workflow_state = 'locked' AND parent_calendar_event_id IS NOT NULL"
  attr_accessor :import_source
  has_many :zip_file_imports, :as => :context
  has_many :content_participation_counts, :as => :context, :dependent => :destroy
  has_many :polls, class_name: 'Polling::Poll'

  include Profile::Association

  before_save :assign_uuid
  before_validation :assert_defaults
  before_save :set_update_account_associations_if_changed
  before_save :update_enrollments_later
  before_save :update_show_total_grade_as_on_weighting_scheme_change
  after_save :update_final_scores_on_weighting_scheme_change
  after_save :update_account_associations_if_changed
  after_save :set_self_enrollment_code
  before_validation :verify_unique_sis_source_id
  validates_presence_of :account_id, :root_account_id, :enrollment_term_id, :workflow_state
  validates_length_of :syllabus_body, :maximum => maximum_long_text_length, :allow_nil => true, :allow_blank => true
  validates_length_of :name, :maximum => maximum_string_length, :allow_nil => true, :allow_blank => true
  validates_length_of :sis_source_id, :maximum => maximum_string_length, :allow_nil => true, :allow_blank => false
  validates_length_of :course_code, :maximum => maximum_string_length, :allow_nil => true, :allow_blank => true
  validates_locale :allow_nil => true

  sanitize_field :syllabus_body, CanvasSanitize::SANITIZE

  include StickySisFields
  are_sis_sticky :name, :course_code, :start_at, :conclude_at, :restrict_enrollments_to_course_dates, :enrollment_term_id, :workflow_state

  include FeatureFlags

  has_a_broadcast_policy

  def [](attr)
    attr.to_s == 'asset_string' ? self.asset_string : super
  end

  def events_for(user)
    if user
      CalendarEvent.
        active.
        for_user_and_context_codes(user, [asset_string]).
        includes(:child_events).
        reject(&:hidden?) +
      AppointmentGroup.manageable_by(user, [asset_string]) +
      assignments.active
    else
      calendar_events.active.includes(:child_events).reject(&:hidden?) +
      assignments.active
    end
  end

  def self.skip_updating_account_associations(&block)
    if @skip_updating_account_assocations
      block.call
    else
      begin
        @skip_updating_account_associations = true
        block.call
      ensure
        @skip_updating_account_associations = false
      end
    end
  end
  def self.skip_updating_account_associations?
    !!@skip_updating_account_associations
  end

  def set_update_account_associations_if_changed
    @should_update_account_associations = self.root_account_id_changed? || self.account_id_changed?
    @should_delay_account_associations = !self.new_record?
    true
  end

  def update_account_associations_if_changed
    send_now_or_later_if_production(@should_delay_account_associations ? :later : :now, :update_account_associations) if @should_update_account_associations && !self.class.skip_updating_account_associations?
  end

  def module_based?
    Rails.cache.fetch(['module_based_course', self].cache_key) do
      self.context_modules.active.any?{|m| m.completion_requirements && !m.completion_requirements.empty? }
    end
  end

  def modules_visible_to(user)
    if self.grants_right?(user, :manage_content)
      self.context_modules.not_deleted
    else
      self.context_modules.active
    end
  end

  def module_items_visible_to(user)
    if self.grants_right?(user, :manage_content)
      self.context_module_tags.not_deleted.joins(:context_module).where("context_modules.workflow_state <> 'deleted'")
    else
      self.context_module_tags.active.joins(:context_module).where(:context_modules => {:workflow_state => 'active'})
    end
  end

  def verify_unique_sis_source_id
    return true unless self.sis_source_id
    infer_root_account unless self.root_account_id
    existing_course = self.root_account.all_courses.find_by_sis_source_id(self.sis_source_id)
    return true if !existing_course || existing_course.id == self.id

    self.errors.add(:sis_source_id, t('errors.sis_in_use', "SIS ID \"%{sis_id}\" is already in use", :sis_id => self.sis_source_id))
    false
  end

  def public_license?
    license && license != 'private'
  end

  def self.licenses
    ActiveSupport::OrderedHash[
      'private',
      {
        :readable_license => t('#cc.private', 'Private (Copyrighted)'),
        :license_url => "http://en.wikipedia.org/wiki/Copyright"
      },
      'cc_by_nc_nd',
      {
        :readable_license => t('#cc.by_nc_nd', 'CC Attribution Non-Commercial No Derivatives'),
        :license_url => "http://creativecommons.org/licenses/by-nc-nd/3.0/"
      },
      'cc_by_nc_sa',
      {
        :readable_license => t('#cc.by_nc_sa', 'CC Attribution Non-Commercial Share Alike'),
        :license_url => "http://creativecommons.org/licenses/by-nc-sa/3.0"
      },
      'cc_by_nc',
      {
        :readable_license => t('#cc.by_nc', 'CC Attribution Non-Commercial'),
        :license_url => "http://creativecommons.org/licenses/by-nc/3.0"
      },
      'cc_by_nd',
      {
        :readable_license => t('#cc.by_nd', 'CC Attribution No Derivatives'),
        :license_url => "http://creativecommons.org/licenses/by-nd/3.0"
      },
      'cc_by_sa',
      {
        :readable_license => t('#cc.by_sa', 'CC Attribution Share Alike'),
        :license_url => "http://creativecommons.org/licenses/by-sa/3.0"
      },
      'cc_by',
      {
        :readable_license => t('#cc.by', 'CC Attribution'),
        :license_url => "http://creativecommons.org/licenses/by/3.0"
      },
      'public_domain',
      {
        :readable_license => t('#cc.public_domain', 'Public Domain'),
        :license_url => "http://en.wikipedia.org/wiki/Public_domain"
      },
    ]
  end

  def license_data
    licenses = self.class.licenses
    licenses[license] || licenses['private']
  end

  def license_url
    license_data[:license_url]
  end

  def readable_license
    license_data[:readable_license]
  end

  def self.update_account_associations(courses_or_course_ids, opts = {})
    return [] if courses_or_course_ids.empty?
    opts.reverse_merge! :account_chain_cache => {}
    account_chain_cache = opts[:account_chain_cache]

    # Split it up into manageable chunks
    user_ids_to_update_account_associations = []
    if courses_or_course_ids.length > 500
      opts = opts.dup
      opts.reverse_merge! :skip_user_account_associations => true
      courses_or_course_ids.uniq.compact.each_slice(500) do |courses_or_course_ids_slice|
        user_ids_to_update_account_associations += update_account_associations(courses_or_course_ids_slice, opts)
      end
    else

      if courses_or_course_ids.first.is_a? Course
        courses = courses_or_course_ids
        Course.send(:preload_associations, courses, :course_sections => :nonxlist_course)
        course_ids = courses.map(&:id)
      else
        course_ids = courses_or_course_ids
        courses = Course.where(:id => course_ids).
            includes(:course_sections => [:course, :nonxlist_course]).
            select([:id, :account_id]).
            all
      end
      course_ids_to_update_user_account_associations = []
      CourseAccountAssociation.transaction do
        current_associations = {}
        to_delete = []
        CourseAccountAssociation.where(:course_id => course_ids).each do |aa|
          key = [aa.course_section_id, aa.account_id]
          current_course_associations = current_associations[aa.course_id] ||= {}
          # duplicates. the unique index prevents these now, but this code
          # needs to hang around for the migration itself
          if current_course_associations.has_key?(key)
            to_delete << aa.id
            next
          end
          current_course_associations[key] = [aa.id, aa.depth]
        end

        courses.each do |course|
          did_an_update = false
          current_course_associations = current_associations[course.id] || {}

          # Courses are tied to accounts directly and through sections and crosslisted courses
          (course.course_sections + [nil]).each do |section|
            next if section && !section.active?
            section.course = course if section
            starting_account_ids = [course.account_id, section.try(:course).try(:account_id), section.try(:nonxlist_course).try(:account_id)].compact.uniq

            account_ids_with_depth = User.calculate_account_associations_from_accounts(starting_account_ids, account_chain_cache).map

            account_ids_with_depth.each do |account_id_with_depth|
              account_id = account_id_with_depth[0]
              depth = account_id_with_depth[1]
              key = [section.try(:id), account_id]
              association = current_course_associations[key]
              if association.nil?
                # new association, create it
                CourseAccountAssociation.create! do |aa|
                  aa.course_id = course.id
                  aa.course_section_id = section.try(:id)
                  aa.account_id = account_id
                  aa.depth = depth
                end
                did_an_update = true
              else
                if association[1] != depth
                  CourseAccountAssociation.where(:id => association[0]).update_all(:depth => depth)
                  did_an_update = true
                end
                # remove from list of existing
                current_course_associations.delete(key)
              end
            end
          end
          did_an_update ||= !current_course_associations.empty?
          if did_an_update
            course.course_account_associations.reset
            course.non_unique_associated_accounts.reset
            course_ids_to_update_user_account_associations << course.id
          end
        end

        to_delete += current_associations.map { |k, v| v.map { |k2, v2| v2[0] } }.flatten
        unless to_delete.empty?
          CourseAccountAssociation.where(:id => to_delete).delete_all
        end
      end

      user_ids_to_update_account_associations = Enrollment.
          where("course_id IN (?) AND workflow_state<>'deleted'", course_ids_to_update_user_account_associations).
          group(:user_id).pluck(:user_id) unless course_ids_to_update_user_account_associations.empty?
    end
    User.update_account_associations(user_ids_to_update_account_associations, :account_chain_cache => account_chain_cache) unless user_ids_to_update_account_associations.empty? || opts[:skip_user_account_associations]
    user_ids_to_update_account_associations
  end

  def update_account_associations
    self.shard.activate do
      Course.update_account_associations([self])
    end
  end

  def associated_accounts
    self.non_unique_associated_accounts.all.uniq
  end

  scope :recently_started, lambda { where(:start_at => 1.month.ago..Time.zone.now).order("start_at DESC").limit(10) }
  scope :recently_ended, lambda { where(:conclude_at => 1.month.ago..Time.zone.now).order("start_at DESC").limit(10) }
  scope :recently_created, lambda { where("created_at>?", 1.month.ago).order("created_at DESC").limit(50).includes(:teachers) }
  scope :for_term, lambda {|term| term ? where(:enrollment_term_id => term) : scoped }
  scope :active_first, lambda { order("CASE WHEN courses.workflow_state='available' THEN 0 ELSE 1 END, #{best_unicode_collation_key('name')}") }
  scope :name_like, lambda { |name| where(wildcard('courses.name', 'courses.sis_source_id', 'courses.course_code', name)) }
  scope :needs_account, lambda { |account, limit| where(:account_id => nil, :root_account_id => account).limit(limit) }
  scope :active, where("courses.workflow_state<>'deleted'")
  scope :least_recently_updated, lambda { |limit| order(:updated_at).limit(limit) }
  scope :manageable_by_user, lambda { |*args|
    # args[0] should be user_id, args[1], if true, will include completed
    # enrollments as well as active enrollments
    user_id = args[0]
    workflow_states = (args[1].present? ? %w{'active' 'completed'} : %w{'active'}).join(', ')
    uniq.joins("INNER JOIN (
         SELECT caa.course_id, au.user_id FROM course_account_associations AS caa
         INNER JOIN accounts AS a ON a.id = caa.account_id AND a.workflow_state = 'active'
         INNER JOIN account_users AS au ON au.account_id = a.id AND au.user_id = #{user_id.to_i}
       UNION SELECT courses.id AS course_id, e.user_id FROM courses
         INNER JOIN enrollments AS e ON e.course_id = courses.id AND e.user_id = #{user_id.to_i}
           AND e.workflow_state IN(#{workflow_states}) AND e.type IN ('TeacherEnrollment', 'TaEnrollment', 'DesignerEnrollment')
         WHERE courses.workflow_state <> 'deleted') as course_users
       ON course_users.course_id = courses.id")
  }
  scope :not_deleted, where("workflow_state<>'deleted'")

  scope :with_enrollments, lambda {
    where("EXISTS (?)", Enrollment.active.where("enrollments.course_id=courses.id"))
  }
  scope :without_enrollments, lambda {
    where("NOT EXISTS (?)", Enrollment.active.where("enrollments.course_id=courses.id"))
  }
  scope :completed, lambda {
    joins(:enrollment_term).
        where("courses.workflow_state='completed' OR courses.conclude_at<? OR enrollment_terms.end_at<?", Time.now.utc, Time.now.utc)
  }
  scope :not_completed, lambda {
    joins(:enrollment_term).
        where("courses.workflow_state<>'completed' AND
          (courses.conclude_at IS NULL OR courses.conclude_at>=?) AND
          (enrollment_terms.end_at IS NULL OR enrollment_terms.end_at>=?)", Time.now.utc, Time.now.utc)
  }
  scope :by_teachers, lambda { |teacher_ids|
    teacher_ids.empty? ?
      none :
      where("EXISTS (?)", Enrollment.active.where("enrollments.course_id=courses.id AND enrollments.type='TeacherEnrollment' AND enrollments.user_id IN (?)", teacher_ids))
  }
  scope :by_associated_accounts, lambda{ |account_ids|
    account_ids.empty? ?
      none :
      where("EXISTS (?)", CourseAccountAssociation.where("course_account_associations.course_id=courses.id AND course_account_associations.account_id IN (?)", account_ids))
  }

  scope :deleted, where(:workflow_state => 'deleted')

  set_broadcast_policy do |p|
    p.dispatch :grade_weight_changed
    p.to { participating_students }
    p.whenever { |record|
      (record.available? && @grade_weight_changed) ||
      record.changed_in_state(:available, :fields => :group_weighting_scheme)
    }

    p.dispatch :new_course
    p.to { self.root_account.account_users }
    p.whenever { |record|
      record.root_account &&
      ((record.just_created && record.name != Course.default_name) ||
      (record.prior_version.name == Course.default_name && record.name != Course.default_name))
    }
  end

  def self.default_name
    # TODO i18n
    t('default_name', "My Course")
  end

  def users_not_in_groups(groups, opts={})
    scope = User.joins(:not_ended_enrollments).
      where(enrollments: {course_id: self, type: 'StudentEnrollment'}).
      where(Group.not_in_group_sql_fragment(groups.map(&:id))).
      select("users.id, users.name").uniq
    scope = scope.select(opts[:order]).order(opts[:order]) if opts[:order]
    scope
  end

  def instructors_in_charge_of(user_id)
    scope = current_enrollments.
      where(:course_id => self, :user_id => user_id).
      where("course_section_id IS NOT NULL")
    section_ids = CANVAS_RAILS2 ?
      scope.pluck(:course_section_id).uniq :
      scope.uniq.pluck(:course_section_id)
    participating_instructors.restrict_to_sections(section_ids)
  end

  def user_is_instructor?(user)
    return unless user
    Rails.cache.fetch([self, user, "course_user_is_instructor"].cache_key) do
      user.cached_current_enrollments.any? { |e| e.course_id == self.id && e.participating_instructor? }
    end
  end

  def user_is_student?(user, opts = {})
    return unless user
    Rails.cache.fetch([self, user, "course_user_is_student", opts[:include_future]].cache_key) do
      user.cached_current_enrollments(:include_future => opts[:include_future]).any? { |e|
        e.course_id == self.id && (opts[:include_future] ? e.student? : e.participating_student?)
      }
    end
  end

  def user_has_been_instructor?(user)
    return unless user
    # enrollments should be on the course's shard
    self.shard.activate do
      Rails.cache.fetch([self, user, "course_user_has_been_instructor"].cache_key) do
        # active here is !deleted; it still includes concluded, etc.
        self.instructor_enrollments.active.find_by_user_id(user.id).present?
      end
    end
  end

  def user_has_been_admin?(user)
    return unless user
    Rails.cache.fetch([self, user, "course_user_has_been_admin"].cache_key) do
      # active here is !deleted; it still includes concluded, etc.
      self.admin_enrollments.active.find_by_user_id(user.id).present?
    end
  end

  def user_has_been_observer?(user)
    return unless user
    Rails.cache.fetch([self, user, "course_user_has_been_observer"].cache_key) do
      # active here is !deleted; it still includes concluded, etc.
      self.observer_enrollments.active.find_by_user_id(user.id).present?
    end
  end

  def user_has_been_student?(user)
    return unless user
    Rails.cache.fetch([self, user, "course_user_has_been_student"].cache_key) do
      self.all_student_enrollments.find_by_user_id(user.id).present?
    end
  end

  def user_has_no_enrollments?(user)
    return unless user
    Rails.cache.fetch([self, user, "course_user_has_no_enrollments"].cache_key) do
      enrollments.find_by_user_id(user.id).nil?
    end
  end


  # Public: Determine if a group weighting scheme should be applied.
  #
  # Returns boolean.
  def apply_group_weights?
    group_weighting_scheme == 'percent'
  end

  def apply_assignment_group_weights=(apply)
    if apply
      self.group_weighting_scheme = 'percent'
    else
      self.group_weighting_scheme = 'equal'
    end
  end

  def grade_weight_changed!
    @grade_weight_changed = true
    self.save!
    @grade_weight_changed = false
  end

  def membership_for_user(user)
    self.enrollments.find_by_user_id(user && user.id)
  end

  def infer_root_account
    # This is a bit tricky.  Basically, it ensures a is the current account;
    # if account is not loaded, it will not double load (because it's
    # already cached). If it's already loaded, and correct, it again will
    # only use the cache.  If it's already loaded and the wrong one, it will
    # force reload
    a = self.account(self.account && self.account.id != self.account_id)
    self.root_account_id = a.root_account_id if a
    self.root_account_id ||= a.id if a
    # Ditto
    self.root_account(self.root_account && self.root_account.id != self.root_account_id)
  end

  def assert_defaults
    self.tab_configuration ||= [] unless self.tab_configuration == []
    self.name = nil if self.name && self.name.strip.empty?
    self.name ||= t('missing_name', "Unnamed Course")
    self.course_code = nil if self.course_code == "" || (self.name_changed? && self.course_code && self.name_was && self.name_was.start_with?(self.course_code))
    if !self.course_code && self.name
      res = []
      split = self.name.split(/\s/)
      res << split[0]
      res << split[1..-1].find{|txt| txt.match(/\d/) } rescue nil
      self.course_code = res.compact.join(" ")
    end
    @group_weighting_scheme_changed = self.group_weighting_scheme_changed?
    self.indexed = nil unless self.is_public
    if self.account_id && self.account_id_changed?
      infer_root_account
    end
    if self.root_account_id && self.root_account_id_changed?
      a = self.account(self.account && self.account.id != self.account_id)
      self.account_id = nil if self.account_id && self.account_id != self.root_account_id && a && a.root_account_id != self.root_account_id
      self.account_id ||= self.root_account_id
    end
    self.root_account_id ||= Account.default.id
    self.account_id ||= self.root_account_id
    self.enrollment_term = nil if self.enrollment_term.try(:root_account_id) != self.root_account_id
    self.enrollment_term ||= self.root_account.default_enrollment_term
    self.allow_student_wiki_edits = (self.default_wiki_editing_roles || "").split(',').include?('students')
    true
  end

  def update_course_section_names
    return if @course_name_was == self.name || !@course_name_was
    sections = self.course_sections
    fields_to_possibly_rename = [:name]
    sections.each do |section|
      something_changed = false
      fields_to_possibly_rename.each do |field|
        section.send("#{field}=", section.default_section ?
          self.name :
          (section.send(field) || self.name).sub(@course_name_was, self.name) )
        something_changed = true if section.send(field) != section.send("#{field}_was")
      end
      if something_changed
        attr_hash = {:updated_at => Time.now.utc}
        fields_to_possibly_rename.each { |key| attr_hash[key] = section.send(key) }
        CourseSection.where(:id => section).update_all(attr_hash)
      end
    end
  end

  def update_enrollments_later
    self.update_enrolled_users if !self.new_record? && !(self.changes.keys & ['workflow_state', 'name', 'course_code', 'start_at', 'conclude_at', 'enrollment_term_id']).empty?
    true
  end

  def update_enrolled_users
    if self.completed?
      Enrollment.where(:course_id => self, :workflow_state => ['active', 'invited']).update_all(:workflow_state => 'completed')
      appointment_participants.active.current.update_all(:workflow_state => 'deleted')
      appointment_groups.each(&:clear_cached_available_slots!)
    elsif self.deleted?
      Enrollment.where("course_id=? AND workflow_state<>'deleted'", self).update_all(:workflow_state => 'deleted')
    end

    if self.root_account_id_changed?
      CourseSection.where(:course_id => self).update_all(:root_account_id => self.root_account_id)
      Enrollment.where(:course_id => self).update_all(:root_account_id => self.root_account_id)
    end

    case Enrollment.connection.adapter_name
    when 'MySQL', 'Mysql2'
      Enrollment.connection.execute("UPDATE users, enrollments SET users.updated_at=NOW(), enrollments.updated_at=NOW() WHERE users.id=enrollments.user_id AND enrollments.course_id=#{self.id}")
    else
      Enrollment.where(:course_id => self).update_all(:updated_at => Time.now.utc)
      User.where("id IN (SELECT user_id FROM enrollments WHERE course_id=?)", self).update_all(:updated_at => Time.now.utc)
    end
  end

  def self_enrollment_allowed?
    !!(self.account && self.account.self_enrollment_allowed?(self))
  end

  def self_enrollment_code
    read_attribute(:self_enrollment_code) || set_self_enrollment_code
  end

  def set_self_enrollment_code
    return if !self_enrollment? || read_attribute(:self_enrollment_code)

    # subset of letters and numbers that are unambiguous
    alphanums = 'ABCDEFGHJKLMNPRTWXY346789'
    code_length = 6

    # we're returning a 6-digit base-25(ish) code. that means there are ~250
    # million possible codes. we should expect to see our first collision
    # within the first 16k or so (thus the retry loop), but we won't risk ever
    # exhausting a retry loop until we've used up about 15% or so of the
    # keyspace. if needed, we can grow it at that point (but it's scoped to a
    # shard, and not all courses will have enrollment codes, so that may not be
    # necessary)
    code = nil
    self.class.unique_constraint_retry(10) do
      code = code_length.times.map{
        alphanums[(rand * alphanums.size).to_i, 1]
      }.join
      update_attribute :self_enrollment_code, code
    end
    code
  end

  def self_enrollment_limit_met?
    self_enrollment_limit && self_enrolled_students.size >= self_enrollment_limit
  end

  def long_self_enrollment_code
    @long_self_enrollment_code ||= Digest::MD5.hexdigest("#{uuid}_for_#{id}")
  end

  # still include the old longer format, since links may be out there
  def self_enrollment_codes
    [self_enrollment_code, long_self_enrollment_code]
  end

  def update_show_total_grade_as_on_weighting_scheme_change
    if group_weighting_scheme_changed? and self.group_weighting_scheme == 'percent'
      self.show_total_grade_as_points = false
    end
    true
  end

  def update_final_scores_on_weighting_scheme_change
    if @group_weighting_scheme_changed
      connection.after_transaction_commit { self.recompute_student_scores }
    end
  end

  def recompute_student_scores(student_ids = nil)
    Enrollment.recompute_final_score(student_ids || self.student_ids, self.id)
  end
  handle_asynchronously_if_production :recompute_student_scores,
    :singleton => proc { |c| "recompute_student_scores:#{ c.global_id }" }

  def home_page
    self.wiki.front_page
  end

  def context_code
    raise "DONT USE THIS, use .short_name instead" unless Rails.env.production?
  end

  def allow_media_comments?
    true || [].include?(self.id)
  end

  def short_name
    course_code
  end

  def short_name=(val)
    write_attribute(:course_code, val)
  end

  def short_name_slug
    CanvasTextHelper.truncate_text(short_name, :ellipsis => '')
  end

  # Allows the account to be set directly
  belongs_to :account

  def wiki_with_create
    Wiki.wiki_for_context(self)
  end
  alias_method_chain :wiki, :create

  # A universal lookup for all messages.
  def messages
    Message.for(self)
  end

  def do_complete
    self.conclude_at ||= Time.now
  end

  def do_unconclude
    self.conclude_at = nil
  end

  def do_offer
    self.start_at ||= Time.now
    send_later_if_production(:invite_uninvited_students)
  end

  def invite_uninvited_students
    self.enrollments.find_all_by_workflow_state("creation_pending").each do |e|
      e.invite!
    end
  end

  workflow do
    state :created do
      event :claim, :transitions_to => :claimed
      event :offer, :transitions_to => :available
      event :complete, :transitions_to => :completed
    end

    state :claimed do
      event :offer, :transitions_to => :available
      event :complete, :transitions_to => :completed
    end

    state :available do
      event :complete, :transitions_to => :completed
    end

    state :completed do
      event :unconclude, :transitions_to => :available
    end
    state :deleted
  end

  def api_state
    return 'unpublished' if workflow_state == 'created' || workflow_state == 'claimed'
    workflow_state
  end
  
  alias_method :destroy!, :destroy
  def destroy
    self.workflow_state = 'deleted'
    save!
  end

  def call_event(event)
    self.send(event) if self.current_state.events.include? event.to_sym
  end

  def claim_with_teacher(user)
    raise "Must provide a valid teacher" unless user
    return unless self.state == :created
    e = enroll_user(user, 'TeacherEnrollment', :enrollment_state => 'active') #teacher(user)
    claim
    e
  end

  def self.require_assignment_groups(contexts)
    courses = contexts.select{|c| c.is_a?(Course) }
    groups = Shard.partition_by_shard(courses) do |shard_courses|
      AssignmentGroup.select("id, context_id, context_type").where(:context_type => "Course", :context_id => shard_courses)
    end.index_by(&:context_id)
    courses.each do |course|
      if !groups[course.id]
        course.require_assignment_group rescue nil
      end
    end
  end

  def require_assignment_group
    shard.activate do
      return if Rails.cache.read(['has_assignment_group', self].cache_key)
      if self.assignment_groups.active.empty?
        self.assignment_groups.create(:name => t('#assignment_group.default_name', "Assignments"))
      end
      Rails.cache.write(['has_assignment_group', self].cache_key, true)
    end
  end

  def self.create_unique(uuid=nil, account_id=nil, root_account_id=nil)
    uuid ||= CanvasUuid::Uuid.generate_securish_uuid
    course = find_or_initialize_by_uuid(uuid)
    course = Course.new if course.deleted?
    course.name = self.default_name if course.new_record?
    course.short_name = t('default_short_name', "Course-101") if course.new_record?
    course.account_id = account_id || root_account_id
    course.root_account_id = root_account_id
    course.save!
    course
  end

  def <=>(other)
    self.id <=> other.id
  end

  def quota
    Rails.cache.fetch(['default_quota', self].cache_key) do
      storage_quota
    end
  end

  def storage_quota_mb
    storage_quota / 1.megabyte
  end

  def storage_quota_mb=(val)
    self.storage_quota = val.try(:to_i).try(:megabytes)
  end

  def storage_quota
    return read_attribute(:storage_quota) ||
      (self.account.default_storage_quota rescue nil) ||
      Setting.get('course_default_quota', 500.megabytes.to_s).to_i
  end

  def storage_quota=(val)
    val = val.to_f
    val = nil if val <= 0
    if account && account.default_storage_quota == val
      val = nil
    end
    write_attribute(:storage_quota, val)
  end

  def assign_uuid
    self.uuid ||= CanvasUuid::Uuid.generate_securish_uuid
  end
  protected :assign_uuid

  def full_name
    name
  end

  def to_atom
    Atom::Entry.new do |entry|
      entry.title     = self.name
      entry.updated   = self.updated_at
      entry.published = self.created_at
      entry.links    << Atom::Link.new(:rel => 'alternate',
                                    :href => "/#{context_url_prefix}/courses/#{self.id}")
    end
  end

  set_policy do
    given { |user| self.available? && self.is_public }
    can :read and can :read_outcomes and can :read_syllabus

    given { |user| self.available? && self.public_syllabus }
    can :read_syllabus

    RoleOverride.permissions.each do |permission, details|
      given {|user, session| (self.enrollment_allows(user, session, permission) || self.account_membership_allows(user, session, permission)) && (!details[:if] || send(details[:if])) }
      can permission
    end

    given { |user, session| session && session[:enrollment_uuid] && (hash = Enrollment.course_user_state(self, session[:enrollment_uuid]) || {}) && (hash[:enrollment_state] == "invited" || hash[:enrollment_state] == "active" && hash[:user_state].to_s == "pre_registered") && (self.available? || self.completed? || self.claimed? && hash[:is_admin]) }
    can :read and can :read_outcomes

    given { |user| (self.available? || self.completed?) && user && user.cached_current_enrollments.any?{|e| e.course_id == self.id && [:active, :invited, :completed].include?(e.state_based_on_date) } }
    can :read and can :read_outcomes

    # Active students
    given { |user|
      available?  && user &&
        user.cached_current_enrollments.any? { |e|
        e.course_id == id && e.participating_student?
      }
    }
    can :read and can :participate_as_student and can :read_grades and can :read_outcomes

    given { |user| (self.available? || self.completed?) && user && user.cached_not_ended_enrollments.any?{|e| e.course_id == self.id && e.participating_observer? && e.associated_user_id} }
    can :read_grades

    given { |user, session| self.available? && self.teacherless? && user && user.cached_not_ended_enrollments.any?{|e| e.course_id == self.id && e.participating_student? } && (!session || !session["role_course_#{self.id}"]) }
    can :update and can :delete and RoleOverride.teacherless_permissions.each{|p| can p }

    # Active admins (Teacher/TA/Designer)
    given { |user, session| (self.available? || self.created? || self.claimed?) && user && user.cached_not_ended_enrollments.any?{|e| e.course_id == self.id && e.participating_admin? } && (!session || !session["role_course_#{self.id}"]) }
    can :read_as_admin and can :read and can :manage and can :update and can :use_student_view and can :read_outcomes and can :view_unpublished_items and can :manage_feature_flags

    # Teachers and Designers can delete/reset, but not TAs
    given { |user, session| !self.deleted? && !self.sis_source_id && user && user.cached_not_ended_enrollments.any?{|e| e.course_id == self.id && e.participating_content_admin? } && (!session || !session["role_course_#{self.id}"]) }
    can :delete
    given { |user, session| !self.deleted? && user && user.cached_not_ended_enrollments.any?{|e| e.course_id == self.id && e.participating_content_admin? } && (!session || !session["role_course_#{self.id}"]) }
    can :reset_content

    # Student view student
    given { |user| user && user.fake_student? && user.cached_not_ended_enrollments.any?{ |e| e.course_id == self.id } }
    can :read and can :participate_as_student and can :read_grades and can :read_outcomes

    # Prior users
    given do |user|
      (available? || completed?) && user &&
        prior_enrollments.for_user(user).count > 0
    end
    can :read, :read_outcomes

    # Admin (Teacher/TA/Designer) of a concluded course
    given do |user|
      !self.deleted? && user &&
        (prior_enrollments.for_user(user).any?{|e| e.admin? } ||
         user.cached_not_ended_enrollments.any? do |e|
           e.course_id == self.id && e.admin? && e.completed?
         end
        )
    end
    can [:read, :read_as_admin, :read_roster, :read_prior_roster, :read_forum, :use_student_view, :read_outcomes]

    given do |user|
      !self.deleted? && user &&
        (prior_enrollments.for_user(user).any?{|e| e.instructor? } ||
          user.cached_not_ended_enrollments.any? do |e|
            e.course_id == self.id && e.instructor? && e.completed?
          end
        )
    end
    can :read_user_notes, :view_all_grades

    # Teacher or Designer of a concluded course
    given do |user|
      !self.deleted? && !self.sis_source_id && user &&
        (prior_enrollments.for_user(user).any?{|e| e.content_admin? } ||
          user.cached_not_ended_enrollments.any? do |e|
            e.course_id == self.id && e.content_admin? && e.state_based_on_date == :completed
          end
        )
    end
    can :delete

    # Student of a concluded course
    given do |user|
      (self.available? || self.completed?) && user &&
        (prior_enrollments.for_user(user).any?{|e| e.student? || e.assigned_observer? } ||
         user.cached_not_ended_enrollments.any? do |e|
          e.course_id == self.id && (e.student? || e.assigned_observer?) && e.state_based_on_date == :completed
         end
        )
    end
    can :read, :read_grades, :read_forum, :read_outcomes

    # Viewing as different role type
    given { |user, session| session && session["role_course_#{self.id}"] }
    can :read and can :read_outcomes

    # Admin
    given { |user, session| self.account_membership_allows(user, session) }
    can :read_as_admin

    given { |user, session| self.account_membership_allows(user, session, :manage_courses) }
    can :read_as_admin and can :manage and can :update and can :delete and can :use_student_view and can :reset_content and can :view_unpublished_items and can :manage_feature_flags

    given { |user, session| self.account_membership_allows(user, session, :read_course_content) }
    can :read and can :read_outcomes

    given { |user, session| !self.deleted? && self.sis_source_id && self.account_membership_allows(user, session, :manage_sis) }
    can :delete

    # Admins with read_roster can see prior enrollments (can't just check read_roster directly,
    # because students can't see prior enrollments)
    given { |user, session| self.account_membership_allows(user, session, :read_roster) }
    can :read_prior_roster
  end

  def allows_gradebook_uploads?
    !large_roster?
  end

  # Public: Determine if SpeedGrader is enabled for the Course.
  #
  # Returns a boolean.
  def allows_speed_grader?
    !large_roster?
  end

  def old_gradebook_visible?
    !(large_roster? || (
      student_count = Rails.cache.fetch(['student_count', self].cache_key) { students.count }
      student_count > Setting.get('gb1_max', '250').to_i)
    )
  end

  def enrollment_allows(user, session, permission)
    return false unless user && permission

    temp_type = session && session["role_course_#{self.id}"]

    @enrollment_lookup ||= {}
    @enrollment_lookup[user.id] ||= shard.activate do
      if temp_type
        [Enrollment.typed_enrollment(temp_type).new(:course => self, :user => user, :workflow_state => 'active')]
      else
        self.enrollments.active_or_pending.for_user(user).reject { |e| [:inactive, :completed].include?(e.state_based_on_date)}
      end
    end

    @enrollment_lookup[user.id].any? {|e| e.has_permission_to?(permission) }
  end

  def self.find_all_by_context_code(codes)
    ids = codes.map{|c| c.match(/\Acourse_(\d+)\z/)[1] rescue nil }.compact
    Course.where(:id => ids).includes(:current_enrollments).all
  end

  def end_at
    conclude_at
  end

  def end_at_changed?
    conclude_at_changed?
  end

  def recently_ended?
    conclude_at && conclude_at < Time.now.utc && conclude_at > 1.month.ago
  end

  # Public: Return true if the end date for a course (or its term, if the course doesn't have one) has passed.
  #
  # Returns boolean or nil.
  def soft_concluded?
    now = Time.now
    return end_at < now if end_at
    enrollment_term.end_at && enrollment_term.end_at < now
  end

  def soft_conclude!
    self.conclude_at = Time.now
    self.restrict_enrollments_to_course_dates = true
  end

  def concluded?
    completed? || soft_concluded?
  end

  def state_sortable
    case state
    when :invited
      1
    when :creation_pending
      1
    when :active
      0
    when :deleted
      5
    when :course_inactivated
      3
    when :rejected
      4
    when :completed
      2
    else
      6
    end
  end

  def account_chain
    self.account.account_chain
  end

  def account_chain_ids
    account_chain.map(&:id)
  end

  def institution_name
    return self.root_account.name if self.root_account_id != Account.default.id
    return (self.account || self.root_account).name
  end

  def account_users_for(user)
    return [] unless user
    @associated_account_ids ||= (self.associated_accounts + [Account.site_admin]).map { |a| a.active? ? a.id : nil }.compact
    @account_users ||= {}
    @account_users[user.global_id] ||= Shard.partition_by_shard(@associated_account_ids) do |account_chain_ids|
      if account_chain_ids == [Account.site_admin.id]
        Account.site_admin.account_users_for(user)
      else
        AccountUser.where(:account_id => account_chain_ids, :user_id => user).all
      end
    end
    @account_users[user.global_id] ||= []
    @account_users[user.global_id]
  end

  def account_membership_allows(user, session, permission = nil)
    return false unless user
    return false if session && session["role_course_#{self.id}"]

    @membership_allows ||= {}
    @membership_allows[[user.id, permission]] ||= self.account_users_for(user).any? { |au| permission.nil? || au.has_permission_to?(self, permission) }
  end

  def teacherless?
    # TODO: I need a better test for teacherless courses... in the mean time we'll just do this
    return false
    @teacherless_course ||= Rails.cache.fetch(['teacherless_course', self].cache_key) do
      !self.sis_source_id && self.teacher_enrollments.empty?
    end
  end

  def grade_publishing_status_translation(status, message)
    status = "unpublished" if status.blank?
    case status
    when 'error'
      if message.present?
        message = t('grade_publishing_status.error_with_message', "Error: %{message}", :message => message)
      else
        message = t('grade_publishing_status.error', "Error")
      end
    when 'unpublished'
      if message.present?
        message = t('grade_publishing_status.unpublished_with_message', "Unpublished: %{message}", :message => message)
      else
        message = t('grade_publishing_status.unpublished', "Unpublished")
      end
    when 'pending'
      if message.present?
        message = t('grade_publishing_status.pending_with_message', "Pending: %{message}", :message => message)
      else
        message = t('grade_publishing_status.pending', "Pending")
      end
    when 'publishing'
      if message.present?
        message = t('grade_publishing_status.publishing_with_message', "Publishing: %{message}", :message => message)
      else
        message = t('grade_publishing_status.publishing', "Publishing")
      end
    when 'published'
      if message.present?
        message = t('grade_publishing_status.published_with_message', "Published: %{message}", :message => message)
      else
        message = t('grade_publishing_status.published', "Published")
      end
    when 'unpublishable'
      if message.present?
        message = t('grade_publishing_status.unpublishable_with_message', "Unpublishable: %{message}", :message => message)
      else
        message = t('grade_publishing_status.unpublishable', "Unpublishable")
      end
    else
      if message.present?
        message = t('grade_publishing_status.unknown_with_message', "Unknown status, %{status}: %{message}", :message => message, :status => status)
      else
        message = t('grade_publishing_status.unknown', "Unknown status, %{status}", :status => status)
      end
    end
    message
  end

  def grade_publishing_statuses
    found_statuses = [].to_set
    enrollments = student_enrollments.not_fake.group_by do |e|
      found_statuses.add e.grade_publishing_status
      grade_publishing_status_translation(e.grade_publishing_status, e.grade_publishing_message)
    end
    overall_status = "error"
    overall_status = "unpublished" unless found_statuses.size > 0
    overall_status = (%w{error unpublished pending publishing published unpublishable}).detect{|s| found_statuses.include?(s)} || overall_status
    return enrollments, overall_status
  end

  def should_kick_off_grade_publishing_timeout?
    settings = Canvas::Plugin.find!('grade_export').settings
    settings[:success_timeout].to_i > 0 && Canvas::Plugin.value_to_boolean(settings[:wait_for_success])
  end

  def self.valid_grade_export_types
    @valid_grade_export_types ||= {
        "instructure_csv" => {
            :name => t('grade_export_types.instructure_csv', "Instructure formatted CSV"),
            :callback => lambda { |course, enrollments, publishing_user, publishing_pseudonym|
                course.generate_grade_publishing_csv_output(enrollments, publishing_user, publishing_pseudonym)
            },
            :requires_grading_standard => false,
            :requires_publishing_pseudonym => false
          }
      }
  end

  def allows_grade_publishing_by(user)
    return false unless Canvas::Plugin.find!('grade_export').enabled?
    settings = Canvas::Plugin.find!('grade_export').settings
    format_settings = Course.valid_grade_export_types[settings[:format_type]]
    return false unless format_settings
    return false if user.sis_pseudonym_for(self).nil? and format_settings[:requires_publishing_pseudonym]
    return true
  end

  def publish_final_grades(publishing_user, user_ids_to_publish = nil)
    # we want to set all the publishing statuses to 'pending' immediately,
    # and then as a delayed job, actually go publish them.

    raise "final grade publishing disabled" unless Canvas::Plugin.find!('grade_export').enabled?
    settings = Canvas::Plugin.find!('grade_export').settings

    last_publish_attempt_at = Time.now.utc
    scope = self.student_enrollments.not_fake
    scope = scope.where(user_id: user_ids_to_publish) if user_ids_to_publish
    scope.update_all(:grade_publishing_status => "pending",
                                        :grade_publishing_message => nil,
                                        :last_publish_attempt_at => last_publish_attempt_at)

    send_later_if_production(:send_final_grades_to_endpoint, publishing_user, user_ids_to_publish)
    send_at(last_publish_attempt_at + settings[:success_timeout].to_i.seconds, :expire_pending_grade_publishing_statuses, last_publish_attempt_at) if should_kick_off_grade_publishing_timeout?
  end

  def send_final_grades_to_endpoint(publishing_user, user_ids_to_publish = nil)
    # actual grade publishing logic is here, but you probably want
    # 'publish_final_grades'

    self.recompute_student_scores_without_send_later(user_ids_to_publish)
    enrollments = self.student_enrollments.not_fake.includes(:user, :course_section).order_by_sortable_name
    enrollments = enrollments.where(user_id: user_ids_to_publish) if user_ids_to_publish

    errors = []
    posts_to_make = []
    posted_enrollment_ids = []
    all_enrollment_ids = enrollments.map(&:id)

    begin

      raise "final grade publishing disabled" unless Canvas::Plugin.find!('grade_export').enabled?
      settings = Canvas::Plugin.find!('grade_export').settings
      raise "endpoint undefined" if settings[:publish_endpoint].blank?
      format_settings = Course.valid_grade_export_types[settings[:format_type]]
      raise "unknown format type: #{settings[:format_type]}" unless format_settings
      raise "grade publishing requires a grading standard" if !self.grading_standard_enabled? && format_settings[:requires_grading_standard]

      publishing_pseudonym = publishing_user.sis_pseudonym_for(self)
      raise "publishing disallowed for this publishing user" if publishing_pseudonym.nil? and format_settings[:requires_publishing_pseudonym]

      callback = Course.valid_grade_export_types[settings[:format_type]][:callback]

      posts_to_make = callback.call(self, enrollments, publishing_user, publishing_pseudonym)

    rescue => e
      Enrollment.where(:id => all_enrollment_ids).update_all(:grade_publishing_status => "error", :grade_publishing_message => e.to_s)
      raise e
    end

    posts_to_make.each do |enrollment_ids, res, mime_type, headers={}|
      begin
        posted_enrollment_ids += enrollment_ids
        if res
          SSLCommon.post_data(settings[:publish_endpoint], res, mime_type, headers )
        end
        Enrollment.where(:id => enrollment_ids).update_all(:grade_publishing_status => (should_kick_off_grade_publishing_timeout? ? "publishing" : "published"), :grade_publishing_message => nil)
      rescue => e
        errors << e
        Enrollment.where(:id => enrollment_ids).update_all(:grade_publishing_status => "error", :grade_publishing_message => e.to_s)
      end
    end

    Enrollment.where(:id => (all_enrollment_ids.to_set - posted_enrollment_ids.to_set).to_a).update_all(:grade_publishing_status => "unpublishable", :grade_publishing_message => nil)

    raise errors[0] if errors.size > 0
  end

  def generate_grade_publishing_csv_output(enrollments, publishing_user, publishing_pseudonym)
    enrollment_ids = []
    res = CSV.generate do |csv|
      row = ["publisher_id", "publisher_sis_id", "course_id", "course_sis_id", "section_id", "section_sis_id", "student_id", "student_sis_id", "enrollment_id", "enrollment_status", "score"]
      row << "grade" if self.grading_standard_enabled?
      csv << row
      enrollments.each do |enrollment|
        next unless enrollment.computed_final_score
        enrollment_ids << enrollment.id
        pseudonym_sis_ids = enrollment.user.pseudonyms.active.find_all_by_account_id(self.root_account_id).map{|p| p.sis_user_id}
        pseudonym_sis_ids = [nil] if pseudonym_sis_ids.empty?
        pseudonym_sis_ids.each do |pseudonym_sis_id|
          row = [publishing_user.try(:id), publishing_pseudonym.try(:sis_user_id),
                 enrollment.course.id, enrollment.course.sis_source_id,
                 enrollment.course_section.id, enrollment.course_section.sis_source_id,
                 enrollment.user.id, pseudonym_sis_id, enrollment.id,
                 enrollment.workflow_state, enrollment.computed_final_score]
          row << enrollment.computed_final_grade if self.grading_standard_enabled?
          csv << row
        end
      end
    end
    return [[enrollment_ids, res, "text/csv"]]
  end

  def expire_pending_grade_publishing_statuses(last_publish_attempt_at)
    self.student_enrollments.not_fake.where(:grade_publishing_status => ['pending', 'publishing'],
                                            :last_publish_attempt_at => last_publish_attempt_at).
        update_all(:grade_publishing_status => 'error', :grade_publishing_message => "Timed out.")
  end

  def enrollments_for_csv(options={})
    # user: used for name in csv output
    # course_section: used for display_name in csv output
    # user > pseudonyms: used for sis_user_id/unique_id if options[:include_sis_id]
    # user > pseudonyms > account: used in find_pseudonym_for_account > works_for_account
    includes = [:user, :course_section]
    includes = {:user => {:pseudonyms => :account}, :course_section => []} if options[:include_sis_id]
    scope = options[:user] ? self.enrollments_visible_to(options[:user]) : self.student_enrollments
    student_enrollments = scope.includes(includes).order_by_sortable_name
    student_enrollments = student_enrollments.all
    student_enrollments.partition{|enrollment| enrollment.type != "StudentViewEnrollment"}.flatten
  end
  private :enrollments_for_csv

  def gradebook_to_csv(options = {})
    student_enrollments = enrollments_for_csv(options)

    student_section_names = {}
    student_enrollments.each do |enrollment|
      student_section_names[enrollment.user_id] ||= []
      student_section_names[enrollment.user_id] << (enrollment.course_section.display_name rescue nil)
    end
    student_enrollments = student_enrollments.uniq(&:user_id) # remove duplicate enrollments for students enrolled in multiple sections

    calc = GradeCalculator.new(student_enrollments.map(&:user_id), self, :ignore_muted => false)
    grades = calc.compute_scores

    submissions = {}
    calc.submissions.each { |s| submissions[[s.user_id, s.assignment_id]] = s }
    assignments = calc.assignments
    groups = calc.groups

    read_only = t('csv.read_only_field', '(read only)')
    t 'csv.student', 'Student'
    t 'csv.id', 'ID'
    t 'csv.sis_user_id', 'SIS User ID'
    t 'csv.sis_login_id', 'SIS Login ID'
    t 'csv.section', 'Section'
    t 'csv.comments', 'Comments'
    t 'csv.current_score', 'Current Score'
    t 'csv.final_score', 'Final Score'
    t 'csv.final_grade', 'Final Grade'
    t 'csv.points_possible', 'Points Possible'
    CSV.generate do |csv|
      #First row
      row = ["Student", "ID"]
      row << "SIS User ID" << "SIS Login ID" if options[:include_sis_id]
      row << "Section"
      row.concat assignments.map(&:title_with_id)
      include_points = !apply_group_weights?
      groups.each { |g|
        if include_points
          row << "#{g.name} Current Points" << "#{g.name} Final Points"
        end
        row << "#{g.name} Current Score" << "#{g.name} Final Score"
      }
      row << "Current Points" << "Final Points" if include_points
      row << "Current Score" << "Final Score"
      row << "Final Grade" if self.grading_standard_enabled?
      csv << row

      group_filler_length = groups.size * (include_points ? 4 : 2)

      #Possible muted row
      if assignments.any?(&:muted)
        #This is is not translated since we look for this exact string when we upload to gradebook.
        row = [nil, nil, nil]
        row << nil << nil if options[:include_sis_id]
        row.concat(assignments.map { |a| 'Muted' if a.muted? })
        row.concat([nil] * group_filler_length)
        row << nil << nil if include_points
        row << nil << nil
        row << nil if self.grading_standard_enabled?
        csv << row
      end

      #Second Row
      row = ["    Points Possible", nil, nil]
      row << nil << nil if options[:include_sis_id]
      row.concat assignments.map(&:points_possible)
      row.concat([read_only] * group_filler_length)
      row << read_only << read_only if include_points
      row << read_only << read_only
      row << read_only if self.grading_standard_enabled?
      csv << row

      student_enrollments.each do |student_enrollment|
        student = student_enrollment.user
        student_sections = student_section_names[student.id].sort.to_sentence
        student_submissions = assignments.map do |a|
          submission = submissions[[student.id, a.id]]
          submission.try(:score)
        end
        #Last Row
        row = [student.last_name_first, student.id]
        if options[:include_sis_id]
          pseudonym = student.sis_pseudonym_for(self.root_account)
          row << pseudonym.try(:sis_user_id)
          pseudonym ||= student.find_pseudonym_for_account(self.root_account, true)
          row << pseudonym.try(:unique_id)
        end

        row << student_sections
        row.concat(student_submissions)

        (current_info, current_group_info),
          (final_info, final_group_info) = grades.shift
        groups.each do |g|
          row << current_group_info[g.id][:score] << final_group_info[g.id][:score] if include_points
          row << current_group_info[g.id][:grade] << final_group_info[g.id][:grade]
        end
        row << current_info[:total] << final_info[:total] if include_points
        row << current_info[:grade] << final_info[:grade]
        if self.grading_standard_enabled?
          row << score_to_grade(final_info[:grade])
        end
        csv << row
      end
    end
  end

  # included to make it easier to work with api, which returns
  # sis_source_id as sis_course_id.
  alias_attribute :sis_course_id, :sis_source_id

  def grading_standard_title
    if self.grading_standard_enabled?
      self.grading_standard.try(:title) || t('default_grading_scheme_name', "Default Grading Scheme")
    else
      nil
    end
  end

  def score_to_grade(score)
    return nil unless self.grading_standard_enabled? && score
    if grading_standard
      grading_standard.score_to_grade(score)
    else
      GradingStandard.default_instance.score_to_grade(score)
    end
  end

  def participants(include_observers=false)
    (participating_admins + participating_students + (include_observers ? participating_observers : [])).uniq
  end

  def enroll_user(user, type='StudentEnrollment', opts={})
    enrollment_state = opts[:enrollment_state]
    section = opts[:section]
    limit_privileges_to_course_section = opts[:limit_privileges_to_course_section]
    associated_user_id = opts[:associated_user_id]
    role_name = opts[:role_name]
    start_at = opts[:start_at]
    end_at = opts[:end_at]
    self_enrolled = opts[:self_enrolled]
    section ||= self.default_section
    enrollment_state ||= self.available? ? "invited" : "creation_pending"
    if type == 'TeacherEnrollment' || type == 'TaEnrollment' || type == 'DesignerEnrollment'
      enrollment_state = 'invited' if enrollment_state == 'creation_pending'
    else
      enrollment_state = 'creation_pending' if enrollment_state == 'invited' && !self.available?
    end
    Course.unique_constraint_retry do
      if opts[:allow_multiple_enrollments]
        e = self.all_enrollments.where(user_id: user, type: type, role_name: role_name, associated_user_id: associated_user_id, course_section_id: section.id).first
      else
        # order by course_section_id<>section.id so that if there *is* an existing enrollment for this section, we get it (false orders before true)
        e = self.all_enrollments.
          where(user_id: user, type: type, role_name: role_name, associated_user_id: associated_user_id).
          order("course_section_id<>#{section.id}").
          first
      end
      if e
        e.already_enrolled = true
        e.attributes = {
          :course_section => section,
          :workflow_state => 'invited',
          :limit_privileges_to_course_section => limit_privileges_to_course_section } if e.completed? || e.rejected? || e.deleted?
      end
      # if we're creating a new enrollment, we want to return it as the correct
      # subclass, but without using associations, we need to manually activate
      # sharding. We should probably find a way to go back to using the
      # association here -- just ran out of time.
      self.shard.activate do
        e ||= Enrollment.typed_enrollment(type).new(
          :user => user,
          :course => self,
          :course_section => section,
          :workflow_state => enrollment_state,
          :limit_privileges_to_course_section => limit_privileges_to_course_section)

      end
      e.associated_user_id = associated_user_id
      e.role_name = role_name
      e.self_enrolled = self_enrolled
      e.start_at = start_at
      e.end_at = end_at
      if e.changed?
        transaction do
          if connection.adapter_name == 'PostgreSQL' && connection.send(:postgresql_version) < 90300
            # without this, inserting/updating on enrollments will share lock the course, but then
            # it tries to touch the course, which will deadlock with another transaction doing the
            # same thing. on 9.3, it will KEY SHARE lock, which doesn't conflict with the NO KEY
            # UPDATE needed to touch it
            self.lock!
          end
          if opts[:no_notify]
            e.save_without_broadcasting
          else
            e.save
          end
        end
      end
      e.user = user
      self.claim if self.created? && e && e.admin?
      unless opts[:skip_touch_user]
        e.associated_user.try(:touch)
        user.touch
      end
      user.reload
      e
    end
  end

  def enroll_student(user, opts={})
    enroll_user(user, 'StudentEnrollment', opts)
  end

  def self_enroll_student(user, opts = {})
    enrollment = enroll_student(user, opts.merge(:self_enrolled => true))
    enrollment.accept(:force)
    unless opts[:skip_pseudonym]
      new_pseudonym = user.find_or_initialize_pseudonym_for_account(root_account)
      new_pseudonym.save if new_pseudonym && new_pseudonym.changed?
    end
    enrollment
  end

  def enroll_ta(user, opts={})
    enroll_user(user, 'TaEnrollment', opts)
  end

  def enroll_designer(user, opts={})
    enroll_user(user, 'DesignerEnrollment', opts)
  end

  def enroll_teacher(user, opts={})
    enroll_user(user, 'TeacherEnrollment', opts)
  end

  def resubmission_for(asset)
    if CANVAS_RAILS2
      # without the scoped, Rails 2 will try to do an update_all instead (due
      # to the association)
      asset.ignores.where(:purpose => 'grading', :permanent => false).scoped.delete_all
    else
      asset.ignores.where(:purpose => 'grading', :permanent => false).delete_all
    end
    instructors.order(:id).each(&:touch)
  end

  def grading_standard_enabled
    !!self.grading_standard_id
  end
  alias_method :grading_standard_enabled?, :grading_standard_enabled

  def grading_standard_enabled=(val)
    if Canvas::Plugin.value_to_boolean(val)
      self.grading_standard_id ||= 0
    else
      self.grading_standard = self.grading_standard_id = nil
    end
  end

  def add_aggregate_entries(entries, feed)
    if feed.feed_purpose == 'announcements'
      entries.each do |entry|
        user = entry.user || feed.user
        # If already existed and has been updated
        if entry.entry_changed? && entry.asset
          entry.asset.update_attributes(
            :title => entry.title,
            :message => entry.message
          )
        elsif !entry.asset
          announcement = self.announcements.build(
            :title => entry.title,
            :message => entry.message
          )
          announcement.user = user
          announcement.save
          entry.update_attributes(:asset => announcement)
        end
      end
    elsif feed.feed_purpose == 'calendar'
      entries.each do |entry|
        user = entry.user || feed.user
        # If already existed and has been updated
        if entry.entry_changed? && entry.asset
          event = entry.asset
          event.attributes = {
            :title => entry.title,
            :description => entry.message,
            :start_at => entry.start_at,
            :end_at => entry.end_at
          }
          event.workflow_state = 'cancelled' if entry.cancelled?
          event.save
        elsif entry.active? && !entry.asset
          event = self.calendar_events.build(
            :title => entry.title,
            :description => entry.message,
            :start_at => entry.start_at,
            :end_at => entry.end_at
          )
          event.workflow_state = 'read_only'
          event.workflow_state = 'cancelled' if entry.cancelled?
          event.save
          entry.update_attributes(:asset => event)
        end
      end
    end
  end

  def readable_default_wiki_editing_roles
    roles = self.default_wiki_editing_roles || "teachers"
    case roles
    when 'teachers'
      t('wiki_permissions.only_teachers', 'Only Teachers')
    when 'teachers,students'
      t('wiki_permissions.teachers_students', 'Teacher and Students')
    when 'teachers,students,public'
      t('wiki_permissions.all', 'Anyone')
    else
      t('wiki_permissions.only_teachers', 'Only Teachers')
    end
  end

  def default_section(opts = {})
    section = course_sections.active.find_by_default_section(true)
    if !section && opts[:include_xlists]
      section = CourseSection.active.where(:nonxlist_course_id => self).order(:id).first
    end
    if !section && !opts[:no_create]
      section = course_sections.build
      section.default_section = true
      section.course = self
      section.root_account_id = self.root_account_id
      Shackles.activate(:master) do
        section.save unless new_record?
      end
    end
    section
  end

  def assert_section
    if self.course_sections.active.empty?
      default = self.default_section
      default.workflow_state = 'active'
      default.save
    end
  end

  def file_structure_for(user)
    User.file_structure_for(self, user)
  end

  def self.copy_authorized_content(html, to_context, user)
    return html unless to_context
    pairs = []
    content_types_to_copy = ['files']
    matches = html.scan(/\/(courses|groups|users)\/(\d+)\/(\w+)/) do |match|
      pairs << [match[0].singularize, match[1].to_i] if content_types_to_copy.include?(match[2])
    end
    pairs = pairs.select{|p| p[0] != to_context.class.to_s || p[1] != to_context.id }
    pairs.uniq.each do |context_type, id|
      context = Context.find_by_asset_string("#{context_type}_#{id}") rescue nil
      if context
        next if to_context.respond_to?(:context) && context == to_context.context
        if context.grants_right?(user, nil, :manage_content)
          html = self.migrate_content_links(html, context, to_context, content_types_to_copy)
        else
          html = self.migrate_content_links(html, context, to_context, content_types_to_copy, user)
        end
      end
    end
    html
  end

  def turnitin_settings
    # check if somewhere up the account chain turnitin is enabled and
    # has valid settings
    account.turnitin_settings
  end

  def turnitin_pledge
    self.account.closest_turnitin_pledge
  end

  def all_turnitin_comments
    comments = self.account.closest_turnitin_comments || ""
    if self.turnitin_comments && !self.turnitin_comments.empty?
      comments += "\n\n" if comments && !comments.empty?
      comments += self.turnitin_comments
    end
    self.extend TextHelper
    format_message(comments).first
  end

  def turnitin_enabled?
    !!self.turnitin_settings
  end

  def self.migrate_content_links(html, from_context, to_context, supported_types=nil, user_to_check_for_permission=nil)
    return html unless html.present? && to_context

    from_name = from_context.class.name.tableize
    to_name = to_context.class.name.tableize

    @merge_mappings ||= {}
    rewriter = UserContent::HtmlRewriter.new(from_context, user_to_check_for_permission)
    limit_migrations_to_listed_types = !!supported_types
    rewriter.allowed_types = %w(assignments calendar_events discussion_topics collaborations files conferences quizzes groups modules)

    rewriter.set_default_handler do |match|
      new_url = match.url
      next(new_url) if supported_types && !supported_types.include?(match.type)
      if match.obj_id
        new_id = @merge_mappings["#{match.obj_class.name.underscore}_#{match.obj_id}"]
        next(new_url) unless rewriter.user_can_view_content? { match.obj_class.find_by_id(match.obj_id) }
        if !limit_migrations_to_listed_types || new_id
          new_url = new_url.gsub("#{match.type}/#{match.obj_id}", new_id ? "#{match.type}/#{new_id}" : "#{match.type}")
        end
      end
      new_url.gsub("/#{from_name}/#{from_context.id}", "/#{to_name}/#{to_context.id}")
    end

    rewriter.set_unknown_handler do |match|
      match.url.gsub("/#{from_name}/#{from_context.id}", "/#{to_name}/#{to_context.id}")
    end

    html = rewriter.translate_content(html)

    if !limit_migrations_to_listed_types
      # for things like calendar urls, swap out the old context id with the new one
      regex = Regexp.new("include_contexts=[^\\s&]*#{from_context.asset_string}")
      html = html.gsub(regex) do |match|
        match.gsub("#{from_context.asset_string}", "#{to_context.asset_string}")
      end
      # swap out the old host with the new host
      html = html.gsub(HostUrl.context_host(from_context), HostUrl.context_host(to_context))
    end

    html
  end

  def migrate_content_links(html, from_course)
    Course.migrate_content_links(html, from_course, self)
  end

  attr_accessor :merge_results
  def log_merge_result(text)
    @merge_results ||= []
    logger.debug text
    @merge_results << text
  end
  def warn_merge_result(text)
    log_merge_result(text)
  end

  def bool_res(val)
    Canvas::Plugin.value_to_boolean(val)
  end

  def import_from_migration(data, params, migration)
    Importers::CourseContentImporter.import_content(self, data, params, migration)
  end

  def add_migration_warning(message, exception='')
    self.content_migration.add_warning(message, exception) if self.content_migration
  end

  attr_accessor :imported_migration_items, :full_migration_hash, :external_url_hash, :content_migration,
                :folder_name_lookups, :attachment_path_id_lookup, :attachment_path_id_lookup_lower,
                :assignment_group_no_drop_assignments, :migration_results


  def backup_to_json
    backup.to_json
  end

  def backup
    res = []
    res += self.folders.active
    res += self.attachments.active
    res += self.assignment_groups.active
    res += self.assignments.active
    res += self.submissions
    res += self.quizzes
    res += self.discussion_topics.active
    res += self.discussion_entries.active
    res += self.wiki.wiki_pages.active
    res += self.calendar_events.active
    res
  end

  def map_merge(old_item, new_item)
    @merge_mappings ||= {}
    @merge_mappings[old_item.asset_string] = new_item && new_item.id
  end

  def merge_mapped_id(old_item)
    @merge_mappings ||= {}
    return nil unless old_item
    return @merge_mappings[old_item] if old_item.is_a?(String)
    @merge_mappings[old_item.asset_string]
  end

  def same_dates?(old, new, columns)
    old && new && columns.all?{|column|
      old.respond_to?(column) && new.respond_to?(column) && old.send(column) == new.send(column)
    }
  end

  def copy_attachments_from_course(course, options={})
    self.attachment_path_id_lookup = {}
    root_folder = Folder.root_folders(self).first
    root_folder_name = root_folder.name + '/'
    ce = options[:content_export]
    cm = options[:content_migration]

    attachments = course.attachments.where("file_state <> 'deleted'").all
    total = attachments.count + 1

    Attachment.skip_media_object_creation do
      attachments.each_with_index do |file, i|
        cm.update_import_progress((i.to_f/total) * 18.0) if cm && (i % 10 == 0)

        if !ce || ce.export_object?(file)
          begin
            new_file = file.clone_for(self, nil, :overwrite => true)
            self.attachment_path_id_lookup[file.full_display_path.gsub(/\A#{root_folder_name}/, '')] = new_file.migration_id
            new_folder_id = merge_mapped_id(file.folder)

            if file.folder && file.folder.parent_folder_id.nil?
              new_folder_id = root_folder.id
            end
            # make sure the file has somewhere to go
            if !new_folder_id
              # gather mapping of needed folders from old course to new course
              old_folders = []
              old_folders << file.folder
              new_folders = []
              new_folders << old_folders.last.clone_for(self, nil, options.merge({:include_subcontent => false}))
              while old_folders.last.parent_folder && old_folders.last.parent_folder.parent_folder_id
                old_folders << old_folders.last.parent_folder
                new_folders << old_folders.last.clone_for(self, nil, options.merge({:include_subcontent => false}))
              end
              old_folders.reverse!
              new_folders.reverse!
              # try to use folders that already match if possible
              final_new_folders = []
              parent_folder = Folder.root_folders(self).first
              old_folders.each_with_index do |folder, idx|
                if f = parent_folder.active_sub_folders.find_by_name(folder.name)
                  final_new_folders << f
                else
                  final_new_folders << new_folders[idx]
                end
                parent_folder = final_new_folders.last
              end
              # add or update the folder structure needed for the file
              final_new_folders.first.parent_folder_id ||=
                merge_mapped_id(old_folders.first.parent_folder) ||
                Folder.root_folders(self).first.id
              old_folders.each_with_index do |folder, idx|
                final_new_folders[idx].save!
                map_merge(folder, final_new_folders[idx])
                final_new_folders[idx + 1].parent_folder_id ||= final_new_folders[idx].id if final_new_folders[idx + 1]
              end
              new_folder_id = merge_mapped_id(file.folder)
            end
            new_file.folder_id = new_folder_id
            new_file.save_without_broadcasting!
            map_merge(file, new_file)
          rescue
            cm.add_warning(t(:file_copy_error, "Couldn't copy file \"%{name}\"", :name => file.display_name || file.path_name), $!)
          end
        end
      end
    end
  end

  def self.clonable_attributes
    [ :group_weighting_scheme, :grading_standard_id, :is_public,
      :allow_student_wiki_edits, :show_public_context_messages,
      :syllabus_body, :allow_student_forum_attachments,
      :default_wiki_editing_roles, :allow_student_organized_groups,
      :default_view, :show_total_grade_as_points,
      :show_all_discussion_entries, :open_enrollment,
      :storage_quota, :tab_configuration, :allow_wiki_comments,
      :turnitin_comments, :self_enrollment, :license, :indexed, :locale,
      :hide_final_grade, :hide_distribution_graphs,
      :allow_student_discussion_topics, :lock_all_announcements ]
  end

  def assert_assignment_group
    has_group = Rails.cache.fetch(['has_assignment_group', self.id].cache_key) do
      self.assignment_groups.active.count > 0
    end
    if !has_group
      group = self.assignment_groups.new :name => t('#assignment_group.default_name', "Assignments"), :position => 1
      group.save
    end
  end

  def set_course_dates_if_blank(shift_options)
    self.start_at ||= shift_options[:default_start_at]
    self.conclude_at ||= shift_options[:default_conclude_at]
  end

  def real_start_date
    return self.start_at.to_date if self.start_at
    all_dates.min
  end

  def all_dates
    (self.calendar_events.active + self.assignments.active).inject([]) {|list, e|
      list << e.end_at if e.end_at
      list << e.start_at if e.start_at
      list
    }.compact.flatten.map{|d| d.to_date }.uniq rescue []
  end

  def real_end_date
    return self.conclude_at.to_date if self.conclude_at
    all_dates.max
  end

  def is_a_context?
    true
  end

  def self.serialization_excludes; [:uuid]; end


  def section_visibilities_for(user)
    shard.activate do
      Rails.cache.fetch(['section_visibilities_for', user, self].cache_key) do
        enrollments = Enrollment.select([:course_section_id, :limit_privileges_to_course_section, :type, :associated_user_id]).
                       where("user_id=? AND course_id=? AND workflow_state<>'deleted'", user, self)
        enrollments.map do |e|
          {
            :course_section_id => e.course_section_id,
            :limit_privileges_to_course_section => e.limit_privileges_to_course_section,
            :type => e.type,
            :associated_user_id => e.associated_user_id,
            :admin => e.admin?
          }
        end
      end
    end
  end

  def visibility_limited_to_course_sections?(user, visibilities = section_visibilities_for(user))
    visibilities.all?{|s| s[:limit_privileges_to_course_section] }
  end

  # returns a scope, not an array of users/enrollments
  def students_visible_to(user, include_priors=false)
    enrollments_visible_to(user, :include_priors => include_priors, :return_users => true)
  end

  def enrollments_visible_to(user, opts = {})
    visibilities = section_visibilities_for(user)
    relation = []
    relation << 'all' if opts[:include_priors]
    if opts[:type] == :all
      relation << 'user' if opts[:return_users]
    else
      relation << (opts[:type].try(:to_s) || 'student')
    end
    if opts[:return_users]
      relation.last << 's'
    else
      relation << 'enrollments'
    end
    relation = relation.join('_')
    # our relations don't all follow the same pattern
    relation = case relation
                 when 'all_enrollments'; 'enrollments'
                 when 'enrollments'; 'current_enrollments'
                 else; relation
               end
    scope = self.send(relation.to_sym)
    if opts[:section_ids]
      scope = scope.where('enrollments.course_section_id' => opts[:section_ids].to_a)
    end
    visibility_level = enrollment_visibility_level_for(user, visibilities)
    account_admin = visibility_level == :full && visibilities.empty?
    # teachers, account admins, and student view students can see student view students
    if !visibilities.any?{|v|v[:admin] || v[:type] == 'StudentViewEnrollment' } && !account_admin
      scope = scope.where("enrollments.type<>'StudentViewEnrollment'")
    end
    # See also MessageableUser::Calculator (same logic used to get users across multiple courses) (should refactor)
    case visibility_level
      when :full, :limited then scope
      when :sections then scope.where("enrollments.course_section_id IN (?) OR (enrollments.limit_privileges_to_course_section=? AND enrollments.type IN ('TeacherEnrollment', 'TaEnrollment', 'DesignerEnrollment'))", visibilities.map{|s| s[:course_section_id]}, false)
      when :restricted then scope.where(:enrollments => { :user_id  => visibilities.map{|s| s[:associated_user_id]}.compact + [user] })
      else scope.none
    end
  end

  def users_visible_to(user, include_priors=false)
    visibilities = section_visibilities_for(user)
    scope = include_priors ? users : current_users
    # See also MessageableUsers (same logic used to get users across multiple courses) (should refactor)
    case enrollment_visibility_level_for(user, visibilities)
      when :full then scope
      when :sections then scope.where(:enrollments => { :course_section_id => visibilities.map {|s| s[:course_section_id] } })
      when :restricted then scope.where(:enrollments => { :user_id => (visibilities.map { |s| s[:associated_user_id] }.compact + [user]) })
      when :limited then scope.where("enrollments.type IN ('StudentEnrollment', 'TeacherEnrollment', 'TaEnrollment', 'StudentViewEnrollment')")
      else scope.none
    end
  end

  def sections_visible_to(user, sections = active_course_sections)
    visibilities = section_visibilities_for(user)
    section_ids = visibilities.map{ |s| s[:course_section_id] }
    case enrollment_visibility_level_for(user, visibilities)
    when :full, :limited
      if visibilities.all?{ |v| ['StudentEnrollment', 'StudentViewEnrollment', 'ObserverEnrollment'].include? v[:type] }
        sections.where(:id => section_ids)
      else
        sections
      end
    when :sections
      sections.where(:id => section_ids)
    else
      # return an empty set, but keep it as a scope for downstream consistency
      sections.none
    end
  end

  # derived from policy for Group#grants_right?(user, nil, :read)
  def groups_visible_to(user, groups = active_groups)
    if grants_rights?(user, nil, :manage_groups, :view_group_pages).values.any?
      # course-wide permissions; all groups are visible
      groups
    else
      # no course-wide permissions; only groups the user is a member of are
      # visible
      groups.joins(:participating_group_memberships).
        where('group_memberships.user_id' => user)
    end
  end

  def enrollment_visibility_level_for(user, visibilities = section_visibilities_for(user), require_message_permission = false)
    permissions = require_message_permission ?
      [:send_messages] :
      [:manage_grades, :manage_students, :manage_admin_users, :read_roster, :view_all_grades]
    granted_permissions = self.grants_rights?(user, nil, *permissions).select {|key, value| value}.keys
    if granted_permissions.empty?
      :restricted # e.g. observer, can only see admins in the course
    elsif visibilities.present? && visibility_limited_to_course_sections?(user, visibilities)
      :sections
    elsif granted_permissions.eql? [:read_roster]
      :limited
    else
      :full
    end
  end

  def invited_count_visible_to(user)
    scope = users_visible_to(user).
      where("enrollments.workflow_state = 'invited' AND enrollments.type != 'StudentViewEnrollment'")
    if CANVAS_RAILS2
      scope.count(:distinct => true, :select => 'users.id')
    else
      scope.select('users.id').uniq.count
    end
  end

  def unpublished?
    self.created? || self.claimed?
  end

  def tab_configuration
    super.map {|h| h.with_indifferent_access } rescue []
  end

  TAB_HOME = 0
  TAB_SYLLABUS = 1
  TAB_PAGES = 2
  TAB_ASSIGNMENTS = 3
  TAB_QUIZZES = 4
  TAB_GRADES = 5
  TAB_PEOPLE = 6
  TAB_GROUPS = 7
  TAB_DISCUSSIONS = 8
  TAB_MODULES = 10
  TAB_FILES = 11
  TAB_CONFERENCES = 12
  TAB_SETTINGS = 13
  TAB_ANNOUNCEMENTS = 14
  TAB_OUTCOMES = 15
  TAB_COLLABORATIONS = 16

  def self.default_tabs
    [
      { :id => TAB_HOME, :label => t('#tabs.home', "Home"), :css_class => 'home', :href => :course_path },
      { :id => TAB_ANNOUNCEMENTS, :label => t('#tabs.announcements', "Announcements"), :css_class => 'announcements', :href => :course_announcements_path },
      { :id => TAB_ASSIGNMENTS, :label => t('#tabs.assignments', "Assignments"), :css_class => 'assignments', :href => :course_assignments_path },
      { :id => TAB_DISCUSSIONS, :label => t('#tabs.discussions', "Discussions"), :css_class => 'discussions', :href => :course_discussion_topics_path },
      { :id => TAB_GRADES, :label => t('#tabs.grades', "Grades"), :css_class => 'grades', :href => :course_grades_path },
      { :id => TAB_PEOPLE, :label => t('#tabs.people', "People"), :css_class => 'people', :href => :course_users_path },
      { :id => TAB_PAGES, :label => t('#tabs.pages', "Pages"), :css_class => 'pages', :href => :course_wiki_pages_path },
      { :id => TAB_FILES, :label => t('#tabs.files', "Files"), :css_class => 'files', :href => :course_files_path },
      { :id => TAB_SYLLABUS, :label => t('#tabs.syllabus', "Syllabus"), :css_class => 'syllabus', :href => :syllabus_course_assignments_path },
      { :id => TAB_OUTCOMES, :label => t('#tabs.outcomes', "Outcomes"), :css_class => 'outcomes', :href => :course_outcomes_path },
      { :id => TAB_QUIZZES, :label => t('#tabs.quizzes', "Quizzes"), :css_class => 'quizzes', :href => :course_quizzes_path },
      { :id => TAB_MODULES, :label => t('#tabs.modules', "Modules"), :css_class => 'modules', :href => :course_context_modules_path },
      { :id => TAB_CONFERENCES, :label => t('#tabs.conferences', "Conferences"), :css_class => 'conferences', :href => :course_conferences_path },
      { :id => TAB_COLLABORATIONS, :label => t('#tabs.collaborations', "Collaborations"), :css_class => 'collaborations', :href => :course_collaborations_path },
      { :id => TAB_SETTINGS, :label => t('#tabs.settings', "Settings"), :css_class => 'settings', :href => :course_settings_path },
    ]
  end

  def tab_hidden?(id)
    tab = self.tab_configuration.find{|t| t[:id] == id}
    return tab && tab[:hidden]
  end

  def external_tool_tabs(opts)
    tools = self.context_external_tools.active.having_setting('course_navigation')
    account_ids = self.account_chain_ids
    tools += ContextExternalTool.active.having_setting('course_navigation').find_all_by_context_type_and_context_id('Account', account_ids)
    tools.sort_by(&:id).map do |tool|
     {
        :id => tool.asset_string,
        :label => tool.label_for(:course_navigation, opts[:language]),
        :css_class => tool.asset_string,
        :href => :course_external_tool_path,
        :visibility => tool.course_navigation(:visibility),
        :external => true,
        :hidden => tool.course_navigation(:default) == 'disabled',
        :args => [self.id, tool.id]
     }
    end
  end

  def tabs_available(user=nil, opts={})
    opts.reverse_merge!(:include_external => true)
    cache_key = [user, opts].cache_key
    @tabs_available ||= {}
    @tabs_available[cache_key] ||= uncached_tabs_available(user, opts)
  end

  def uncached_tabs_available(user, opts)
    # make sure t() is called before we switch to the slave, in case we update the user's selected locale in the process
    default_tabs = Course.default_tabs

    Shackles.activate(:slave) do
      # We will by default show everything in default_tabs, unless the teacher has configured otherwise.
      tabs = self.tab_configuration.compact
      settings_tab = default_tabs[-1]
      external_tabs = (opts[:include_external] && external_tool_tabs(opts)) || []
      tabs = tabs.map do |tab|
        default_tab = default_tabs.find {|t| t[:id] == tab[:id] } || external_tabs.find{|t| t[:id] == tab[:id] }
        if default_tab
          tab[:label] = default_tab[:label]
          tab[:href] = default_tab[:href]
          tab[:css_class] = default_tab[:css_class]
          tab[:args] = default_tab[:args]
          tab[:visibility] = default_tab[:visibility]
          tab[:external] = default_tab[:external]
          default_tabs.delete_if {|t| t[:id] == tab[:id] }
          external_tabs.delete_if {|t| t[:id] == tab[:id] }
          tab
        else
          # Remove any tabs we don't know about in default_tabs (in case we removed them or something, like Groups)
          nil
        end
      end
      tabs.compact!
      tabs += default_tabs
      tabs += external_tabs
      # Ensure that Settings is always at the bottom
      tabs.delete_if {|t| t[:id] == TAB_SETTINGS }
      tabs << settings_tab

      tabs.each do |tab|
        tab[:hidden_unused] = true if tab[:id] == TAB_MODULES && !active_record_types[:modules]
        tab[:hidden_unused] = true if tab[:id] == TAB_FILES && !active_record_types[:files]
        tab[:hidden_unused] = true if tab[:id] == TAB_QUIZZES && !active_record_types[:quizzes]
        tab[:hidden_unused] = true if tab[:id] == TAB_ASSIGNMENTS && !active_record_types[:assignments]
        tab[:hidden_unused] = true if tab[:id] == TAB_PAGES && !active_record_types[:pages] && !allow_student_wiki_edits
        tab[:hidden_unused] = true if tab[:id] == TAB_CONFERENCES && !active_record_types[:conferences] && !self.grants_right?(user, nil, :create_conferences)
        tab[:hidden_unused] = true if tab[:id] == TAB_ANNOUNCEMENTS && !active_record_types[:announcements]
        tab[:hidden_unused] = true if tab[:id] == TAB_OUTCOMES && !active_record_types[:outcomes]
      end

      # remove tabs that the user doesn't have access to
      unless opts[:for_reordering]
        unless self.grants_rights?(user, opts[:session], :read, :manage_content).values.any?
          tabs.delete_if { |t| t[:id] == TAB_HOME }
          tabs.delete_if { |t| t[:id] == TAB_ANNOUNCEMENTS }
          tabs.delete_if { |t| t[:id] == TAB_PAGES }
          tabs.delete_if { |t| t[:id] == TAB_OUTCOMES }
          tabs.delete_if { |t| t[:id] == TAB_CONFERENCES }
          tabs.delete_if { |t| t[:id] == TAB_COLLABORATIONS }
          tabs.delete_if { |t| t[:id] == TAB_MODULES }
        end
        unless self.grants_rights?(user, opts[:session], :participate_as_student, :manage_content).values.any?
          tabs.delete_if{ |t| t[:visibility] == 'members' }
        end
        unless self.grants_rights?(user, opts[:session], :read, :manage_content, :manage_assignments).values.any?
          tabs.delete_if { |t| t[:id] == TAB_ASSIGNMENTS }
          tabs.delete_if { |t| t[:id] == TAB_QUIZZES }
        end
        unless self.grants_rights?(user, opts[:session], :read, :read_syllabus, :manage_content, :manage_assignments).values.any?
          tabs.delete_if { |t| t[:id] == TAB_SYLLABUS }
        end
        tabs.delete_if{ |t| t[:visibility] == 'admins' } unless self.grants_right?(user, opts[:session], :manage_content)
        if self.grants_rights?(user, opts[:session], :manage_content, :manage_assignments).values.any?
          tabs.detect { |t| t[:id] == TAB_ASSIGNMENTS }[:manageable] = true
          tabs.detect { |t| t[:id] == TAB_SYLLABUS }[:manageable] = true
          tabs.detect { |t| t[:id] == TAB_QUIZZES }[:manageable] = true
        end
        tabs.delete_if { |t| t[:hidden] && t[:external] } unless opts[:api] && self.grants_rights?(user, nil, :manage_content)
        tabs.delete_if { |t| t[:id] == TAB_GRADES } unless self.grants_rights?(user, opts[:session], :read_grades, :view_all_grades, :manage_grades).values.any?
        tabs.detect { |t| t[:id] == TAB_GRADES }[:manageable] = true if self.grants_rights?(user, opts[:session], :view_all_grades, :manage_grades).values.any?
        tabs.delete_if { |t| t[:id] == TAB_PEOPLE } unless self.grants_rights?(user, opts[:session], :read_roster, :manage_students, :manage_admin_users).values.any?
        tabs.detect { |t| t[:id] == TAB_PEOPLE }[:manageable] = true if self.grants_rights?(user, opts[:session], :manage_students, :manage_admin_users).values.any?
        tabs.delete_if { |t| t[:id] == TAB_FILES } unless self.grants_rights?(user, opts[:session], :read, :manage_files).values.any?
        tabs.detect { |t| t[:id] == TAB_FILES }[:manageable] = true if self.grants_right?(user, opts[:session], :managed_files)
        tabs.delete_if { |t| t[:id] == TAB_DISCUSSIONS } unless self.grants_rights?(user, opts[:session], :read_forum, :moderate_forum, :post_to_forum).values.any?
        tabs.detect { |t| t[:id] == TAB_DISCUSSIONS }[:manageable] = true if self.grants_right?(user, opts[:session], :moderate_forum)
        tabs.delete_if { |t| t[:id] == TAB_SETTINGS } unless self.grants_right?(user, opts[:session], :read_as_admin)

        if !user || !self.grants_right?(user, nil, :manage_content)
          # remove some tabs for logged-out users or non-students
          if grants_rights?(user, nil, :read_as_admin, :participate_as_student).values.none?
            tabs.delete_if {|t| [TAB_PEOPLE, TAB_OUTCOMES].include?(t[:id]) }
          end

          unless discussion_topics.new.grants_right?(user, nil, :read)
            tabs.delete_if { |t| t[:id] == TAB_ANNOUNCEMENTS }
          end

          # remove hidden tabs from students
          tabs.delete_if {|t| (t[:hidden] || (t[:hidden_unused] && !opts[:include_hidden_unused])) && !t[:manageable] }
        end
      end
      # Uncommenting these lines will always put hidden links after visible links
      # tabs.each_with_index{|t, i| t[:sort_index] = i }
      # tabs = tabs.sort_by{|t| [t[:hidden_unused] || t[:hidden] ? 1 : 0, t[:sort_index]] } if !self.tab_configuration || self.tab_configuration.empty?
      tabs
    end
  end

  def allow_wiki_comments
    read_attribute(:allow_wiki_comments)
  end

  def account_name
    self.account.name rescue nil
  end

  def term_name
    self.enrollment_term.name rescue nil
  end

  def enable_user_notes
    root_account.enable_user_notes rescue false
  end

  def equella_settings
    account = self.account
    while account
      settings = account.equella_settings
      return settings if settings
      account = account.parent_account
    end
  end

  # This will move the course to be in the specified account.
  # All enrollments, sections, and other objects attached to the course will also be updated.
  def move_to_account(new_root_account, new_sub_account=nil)
    self.account = new_sub_account || new_root_account
    self.save if new_sub_account
    self.root_account = new_root_account
    user_ids = []

    CourseSection.where(:course_id => self).each do |cs|
      cs.update_attribute(:root_account_id, new_root_account.id)
    end

    Enrollment.where(:course_id => self).each do |e|
      e.update_attribute(:root_account_id, new_root_account.id)
      user_ids << e.user_id
    end

    self.save
    User.update_account_associations(user_ids)
  end


  cattr_accessor :settings_options
  self.settings_options = {}

  def self.add_setting(setting, opts = {})
    setting = setting.to_sym
    settings_options[setting] = opts
    cast_expression = "val.to_s"
    if opts[:boolean]
      opts[:default] ||= false
      cast_expression = "Canvas::Plugin.value_to_boolean(val)"
    end
    class_eval <<-CODE
      def #{setting}
        if settings_frd[#{setting.inspect}].nil? && !@disable_setting_defaults
          default = Course.settings_options[#{setting.inspect}][:default]
          default.respond_to?(:call) ? default.call(self) : default
        else
          settings_frd[#{setting.inspect}]
        end
      end
      def #{setting}=(val)
        settings_frd[#{setting.inspect}] = #{cast_expression}
      end
    CODE
    alias_method "#{setting}?", setting if opts[:boolean]
    if opts[:alias]
      alias_method opts[:alias], setting
      alias_method "#{opts[:alias]}=", "#{setting}="
      alias_method "#{opts[:alias]}?", "#{setting}?"
    end
  end

  # unfortunately we decided to pluralize this in the API after the fact...
  # so now we pluralize it everywhere except the actual settings hash and
  # course import/export :(
  add_setting :hide_final_grade, :alias => :hide_final_grades, :boolean => true
  add_setting :hide_distribution_graphs, :boolean => true
  add_setting :allow_student_discussion_topics, :boolean => true, :default => true
  add_setting :allow_student_discussion_editing, :boolean => true, :default => true
  add_setting :show_total_grade_as_points, :boolean => true, :default => false
  add_setting :lock_all_announcements, :boolean => true, :default => false
  add_setting :large_roster, :boolean => true, :default => lambda { |c| c.root_account.large_course_rosters? }
  add_setting :public_syllabus, :boolean => true, :default => false

  def user_can_manage_own_discussion_posts?(user)
    return true if allow_student_discussion_editing?
    return true if user_is_instructor?(user)
    false
  end

  def filter_attributes_for_user(hash, user, session)
    hash.delete('hide_final_grades') unless grants_right? user, :update
    hash
  end

  # DEPRECATED, use setting accessors instead
  def settings=(hash)
    write_attribute(:settings, hash)
  end

  # frozen, because you should use setters
  def settings
    settings_frd.dup.freeze
  end

  def settings_frd
    read_attribute(:settings) || write_attribute(:settings, {})
  end

  def disable_setting_defaults
    @disable_setting_defaults = true
    yield
  ensure
    @disable_setting_defaults = nil
  end

  def reset_content
    Course.transaction do
      new_course = Course.new
      self.attributes.delete_if{|k,v| [:id, :created_at, :updated_at, :syllabus_body, :wiki_id, :default_view, :tab_configuration].include?(k.to_sym) }.each do |key, val|
        new_course.write_attribute(key, val)
      end
      # there's a unique constraint on this, so we need to clear it out
      self.self_enrollment_code = nil
      self.self_enrollment = false
      # The order here is important; we have to set our sis id to nil and save first
      # so that the new course can be saved, then we need the new course saved to
      # get its id to move over sections and enrollments.  Setting this course to
      # deleted has to be last otherwise it would set all the enrollments to
      # deleted before they got moved
      self.uuid = self.sis_source_id = self.sis_batch_id = nil;
      self.save!
      Course.process_as_sis { new_course.save! }
      self.course_sections.update_all(:course_id => new_course)
      # we also want to bring along prior enrollments, so don't use the enrollments
      # association
      case Enrollment.connection.adapter_name
      when 'MySQL', 'Mysql2'
        Enrollment.connection.execute("UPDATE users, enrollments SET users.updated_at=#{Course.sanitize(Time.now.utc)}, enrollments.updated_at=#{Course.sanitize(Time.now.utc)}, enrollments.course_id=#{new_course.id} WHERE users.id=enrollments.user_id AND enrollments.course_id=#{self.id}")
      else
        Enrollment.where(:course_id => self).update_all(:course_id => new_course, :updated_at => Time.now.utc)
        User.where("id IN (SELECT user_id FROM enrollments WHERE course_id=?)", new_course).update_all(:updated_at => Time.now.utc)
      end
      self.replacement_course_id = new_course.id
      self.workflow_state = 'deleted'
      self.save!
      # Assign original course profile to the new course (automatically saves it)
      new_course.profile = self.profile

      Course.find(new_course.id)
    end
  end

  def has_open_course_imports?
    self.course_imports.where(:workflow_state => ['created', 'started']).exists?
  end

  def user_list_search_mode_for(user)
    if self.root_account.open_registration?
      return self.root_account.delegated_authentication? ? :preferred : :open
    end
    return :preferred if self.root_account.grants_right?(user, :manage_user_logins)
    :closed
  end

  def participating_users(user_ids)
    enrollments = self.enrollments.includes(:user).
      where(:enrollments => {:workflow_state => 'active'}, :users => {:id => user_ids})
    enrollments.select { |e| e.active? }.map(&:user).uniq
  end

  def student_view_student
    fake_student = find_or_create_student_view_student
    fake_student = sync_enrollments(fake_student)
    fake_student
  end

  # part of the way we isolate this fake student from places we don't want it
  # to appear is to ensure that it does not have a pseudonym or any
  # account_associations. if either of these conditions is false, something is
  # wrong.
  def find_or_create_student_view_student
    if self.student_view_students.active.count == 0
      fake_student = nil
      User.skip_updating_account_associations do
        fake_student = User.new(:name => t('student_view_student_name', "Test Student"))
        fake_student.preferences[:fake_student] = true
        fake_student.workflow_state = 'registered'
        fake_student.save
        # hash the unique_id so that it's hard to accidently enroll the user in
        # a course by entering something in a user list. :(
        fake_student.pseudonyms.create!(:account => self.root_account,
                                        :unique_id => Canvas::Security.hmac_sha1("Test Student_#{fake_student.id}"))
      end
      fake_student
    else
      self.student_view_students.active.first
    end
  end
  private :find_or_create_student_view_student

  # we want to make sure the student view student is always enrolled in all the
  # sections of the course, so that a section limited teacher can grade them.
  def sync_enrollments(fake_student)
    self.default_section unless course_sections.active.any?
    Enrollment.suspend_callbacks(:update_cached_due_dates) do
      self.course_sections.active.each do |section|
        # enroll fake_student will only create the enrollment if it doesn't already exist
        self.enroll_user(fake_student, 'StudentViewEnrollment',
                         :allow_multiple_enrollments => true,
                         :section => section,
                         :enrollment_state => 'active',
                         :no_notify => true,
                         :skip_touch_user => true)
      end
    end
    DueDateCacher.recompute_course(self)
    fake_student
  end
  private :sync_enrollments

  def associated_shards
    [Shard.default]
  end

  def includes_student?(user)
    return false if user.nil? || user.id.nil?
    student_enrollments.find_by_user_id(user.id).present?
  end

  def update_one(update_params)
    case update_params[:event]
      when 'offer'
        if self.completed?
          self.unconclude!
        else
          self.offer! unless self.available?
        end
      when 'conclude'
        self.complete! unless self.completed?
      when 'delete'
        self.sis_source_id = nil
        self.workflow_state = 'deleted'
        self.save!
      when 'undelete'
        self.workflow_state = 'claimed'
        self.save!
    end
  end

  def self.do_batch_update(progress, user, course_ids, update_params)
    account = progress.context
    progress_runner = ProgressRunner.new(progress)

    progress_runner.completed_message do |completed_count|
      t('batch_update_message', {
          :one => "1 course processed",
          :other => "%{count} courses processed"
        },
        :count => completed_count)
    end

    progress_runner.do_batch_update(course_ids) do |course_id|
      course = account.associated_courses.find_by_id(course_id)
      raise t('course_not_found', "The course was not found") unless course &&
          (course.workflow_state != 'deleted' || update_params[:event] == 'undelete')
      raise t('access_denied', "Access was denied") unless course.grants_right? user, :update
      course.update_one(update_params)
    end

  end

  def self.batch_update(account, user, course_ids, update_params)
    progress = account.progresses.create! :tag => "course_batch_update", :completion => 0.0
    job = Course.send_later_enqueue_args(:do_batch_update,
                                         { no_delay: true },
                                         progress, user, course_ids, update_params)
    progress.user_id = user.id
    progress.delayed_job_id = job.id
    progress.save!
    progress
  end

  def re_send_invitations!
    self.enrollments.invited.except(:includes).includes(:user => :communication_channels).find_each do |e|
      e.re_send_confirmation! if e.invited?
    end
  end

  def serialize_permissions(permissions_hash, user, session)
    permissions_hash.merge(
      create_discussion_topic: DiscussionTopic.context_allows_user_to_create?(self, user, session)
    )
  end

  def multiple_sections?
    self.active_course_sections.count > 1
  end
end
