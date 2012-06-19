#
# Copyright (C) 2012 Instructure, Inc.
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

class Course < ActiveRecord::Base

  include Context
  include Workflow

  attr_accessible :name,
                  :section,
                  :account,
                  :group_weighting_scheme,
                  :start_at,
                  :conclude_at,
                  :grading_standard_id,
                  :is_public,
                  :publish_grades_immediately,
                  :allow_student_wiki_edits,
                  :allow_student_assignment_edits,
                  :hashtag,
                  :show_public_context_messages,
                  :syllabus_body,
                  :public_description,
                  :allow_student_forum_attachments,
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
                  :settings

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
  has_many :current_enrollments, :class_name => 'Enrollment', :conditions => ['enrollments.workflow_state != ? AND enrollments.workflow_state != ? AND enrollments.workflow_state != ? AND enrollments.workflow_state != ?', 'rejected', 'completed', 'deleted', 'inactive'], :include => :user
  has_many :prior_enrollments, :class_name => 'Enrollment', :include => [:user, :course], :conditions => "enrollments.workflow_state = 'completed'"
  has_many :students, :through => :student_enrollments, :source => :user
  has_many :all_students, :through => :all_student_enrollments, :source => :user
  has_many :participating_students, :through => :enrollments, :source => :user, :conditions => "enrollments.type IN ('StudentEnrollment', 'StudentViewEnrollment') and enrollments.workflow_state = 'active'"
  has_many :student_enrollments, :class_name => 'Enrollment', :conditions => ["enrollments.workflow_state != ? AND enrollments.workflow_state != ? AND enrollments.workflow_state != ? AND enrollments.workflow_state != ? AND enrollments.type IN ('StudentEnrollment', 'StudentViewEnrollment')", 'deleted', 'completed', 'rejected', 'inactive'], :include => :user
  has_many :all_student_enrollments, :class_name => 'Enrollment', :conditions => ["enrollments.workflow_state != ? AND enrollments.type IN ('StudentEnrollment', 'StudentViewEnrollment')", 'deleted'], :include => :user
  has_many :all_real_students, :through => :all_real_student_enrollments, :source => :user
  has_many :all_real_student_enrollments, :class_name => 'StudentEnrollment', :conditions => ["enrollments.workflow_state != ?", 'deleted'], :include => :user
  has_many :detailed_enrollments, :class_name => 'Enrollment', :conditions => ['enrollments.workflow_state != ?', 'deleted'], :include => {:user => {:pseudonym => :communication_channel}}
  has_many :teachers, :through => :teacher_enrollments, :source => :user
  has_many :teacher_enrollments, :class_name => 'TeacherEnrollment', :conditions => ['enrollments.workflow_state != ?', 'deleted'], :include => :user
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

  has_many :learning_outcomes, :through => :learning_outcome_tags, :source => :learning_outcome_content, :conditions => "content_tags.content_type = 'LearningOutcome'"
  has_many :learning_outcome_tags, :as => :context, :class_name => 'ContentTag', :conditions => ['content_tags.tag_type = ? AND content_tags.workflow_state != ?', 'learning_outcome_association', 'deleted']
  has_many :created_learning_outcomes, :class_name => 'LearningOutcome', :as => :context
  has_many :learning_outcome_groups, :as => :context
  has_many :course_account_associations
  has_many :non_unique_associated_accounts, :source => :account, :through => :course_account_associations, :order => 'course_account_associations.depth'
  has_many :users, :through => :enrollments, :source => :user
  has_many :group_categories, :as => :context, :conditions => ['deleted_at IS NULL']
  has_many :all_group_categories, :class_name => 'GroupCategory', :as => :context
  has_many :groups, :as => :context
  has_many :active_groups, :as => :context, :class_name => 'Group', :conditions => ['groups.workflow_state != ?', 'deleted']
  has_many :group_categories, :as => :context, :conditions => ['deleted_at IS NULL']
  has_many :assignment_groups, :as => :context, :dependent => :destroy, :order => 'assignment_groups.position, assignment_groups.name'
  has_many :assignments, :as => :context, :dependent => :destroy, :order => 'assignments.created_at'
  has_many :calendar_events, :as => :context, :conditions => ['calendar_events.workflow_state != ?', 'cancelled'], :dependent => :destroy
  has_many :submissions, :through => :assignments, :order => 'submissions.updated_at DESC', :include => :quiz_submission, :dependent => :destroy
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
  has_many :default_wiki_wiki_pages, :class_name => 'WikiPage', :through => :wiki, :source => :wiki_pages, :conditions => ['wiki_pages.workflow_state != ?', 'deleted'], :order => 'wiki_pages.view_count DESC'
  has_many :wiki_namespaces, :as => :context, :dependent => :destroy
  has_many :quizzes, :as => :context, :dependent => :destroy, :order => 'lock_at, title'
  has_many :active_quizzes, :class_name => 'Quiz', :as => :context, :include => :assignment, :conditions => ['quizzes.workflow_state != ?', 'deleted'], :order => 'created_at'
  has_many :assessment_questions, :through => :assessment_question_banks
  has_many :assessment_question_banks, :as => :context, :include => [:assessment_questions, :assessment_question_bank_users]
  def inherited_assessment_question_banks(include_self = false)
    self.account.inherited_assessment_question_banks(true, *(include_self ? [self] : []))
  end

  has_many :external_feeds, :as => :context, :dependent => :destroy
  belongs_to :default_grading_standard, :class_name => 'GradingStandard', :foreign_key => 'grading_standard_id'
  has_many :grading_standards, :as => :context
  has_one :gradebook_upload, :as => :context, :dependent => :destroy
  has_many :web_conferences, :as => :context, :order => 'created_at DESC', :dependent => :destroy
  has_many :rubrics, :as => :context
  has_many :rubric_associations, :as => :context, :include => :rubric, :dependent => :destroy
  has_many :collaborations, :as => :context, :order => 'title, created_at', :dependent => :destroy
  has_one :scribd_account, :as => :scribdable
  has_many :short_message_associations, :as => :context, :include => :short_message, :dependent => :destroy
  has_many :short_messages, :through => :short_message_associations, :dependent => :destroy
  has_many :grading_standards, :as => :context
  has_many :context_modules, :as => :context, :order => :position, :dependent => :destroy
  has_many :active_context_modules, :as => :context, :class_name => 'ContextModule', :conditions => {:workflow_state => 'active'}
  has_many :context_module_tags, :class_name => 'ContentTag', :as => 'context', :order => :position, :conditions => ['tag_type = ?', 'context_module'], :dependent => :destroy
  has_many :media_objects, :as => :context
  has_many :page_views, :as => :context
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

  before_save :assign_uuid
  before_save :assert_defaults
  before_save :set_update_account_associations_if_changed
  before_save :update_enrollments_later
  after_save :update_final_scores_on_weighting_scheme_change
  after_save :update_account_associations_if_changed
  after_save :set_self_enrollment_code
  before_validation :verify_unique_sis_source_id
  validates_length_of :syllabus_body, :maximum => maximum_long_text_length, :allow_nil => true, :allow_blank => true
  validates_locale :allow_nil => true

  sanitize_field :syllabus_body, Instructure::SanitizeField::SANITIZE

  include StickySisFields
  are_sis_sticky :name, :course_code, :start_at, :conclude_at, :restrict_enrollments_to_course_dates, :enrollment_term_id, :workflow_state

  has_a_broadcast_policy

  def events_for(user)
    CalendarEvent.
      active.
      for_user_and_context_codes(user, [asset_string]).
      all(:include => :child_events).
      reject(&:hidden?) +
    AppointmentGroup.manageable_by(user, [asset_string]) +
    assignments.active
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

  def verify_unique_sis_source_id
    return true unless self.sis_source_id
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
        courses = Course.find(:all, :conditions => {:id => course_ids }, :include => { :course_sections => :nonxlist_course })
      end
      course_ids_to_update_user_account_associations = []
      CourseAccountAssociation.transaction do
        current_associations = {}
        to_delete = []
        CourseAccountAssociation.find(:all, :conditions => { :course_id => course_ids }).each do |aa|
          key = [aa.course_section_id, aa.account_id]
          # duplicates
          current_course_associations = current_associations[aa.course_id] ||= {}
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
            starting_account_ids = [course.account_id, section.try(:account_id), section.try(:nonxlist_course).try(:account_id)].compact.uniq

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
                  CourseAccountAssociation.update_all("depth=#{depth}", :id => association[0])
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
          CourseAccountAssociation.delete_all(:id => to_delete)
        end
      end

      user_ids_to_update_account_associations = Enrollment.find(:all, :select => 'user_id', :group => :user_id,
        :conditions => [ 'course_id IN(?) AND workflow_state <> ?', course_ids_to_update_user_account_associations, 'deleted' ]).map(&:user_id) unless
          course_ids_to_update_user_account_associations.empty?
    end
    User.update_account_associations(user_ids_to_update_account_associations, :account_chain_cache => account_chain_cache) unless user_ids_to_update_account_associations.empty? || opts[:skip_user_account_associations]
    user_ids_to_update_account_associations
  end

  def has_outcomes
    Rails.cache.fetch(['has_outcomes', self].cache_key) do
      self.learning_outcomes.count > 0
    end
  end

  def update_account_associations
    Course.update_account_associations([self])
  end

  def associated_accounts
    self.non_unique_associated_accounts.uniq
  end

  named_scope :recently_started, lambda {
    {:conditions => ['start_at < ? and start_at > ?', Time.now.utc, 1.month.ago], :order => 'start_at DESC', :limit => 10}
  }
  named_scope :recently_ended, lambda {
    {:conditions => ['conclude_at < ? and conclude_at > ?', Time.now.utc, 1.month.ago], :order => 'start_at DESC', :limit => 10}
  }
  named_scope :recently_created, lambda {
    {:conditions => ['created_at > ?', 1.month.ago], :order => 'created_at DESC', :limit => 50, :include => :teachers}
  }
  named_scope :for_term, lambda {|term|
    term ? {:conditions => ['courses.enrollment_term_id = ?', term.id]} : {}
  }
  named_scope :active_first, lambda {
    {:order => "CASE WHEN courses.workflow_state='available' THEN 0 ELSE 1 END, name"}
  }
  named_scope :limit, lambda {|limit|
    {:limit => limit }
  }
  named_scope :name_like, lambda { |name|
    { :conditions => wildcard('courses.name', 'courses.sis_source_id', 'courses.course_code', name) }
  }
  named_scope :needs_account, lambda{|account, limit|
    {:conditions => {:account_id => nil, :root_account_id => account.id}, :limit => limit }
  }
  named_scope :active, lambda{
    {:conditions => ['courses.workflow_state != ?', 'deleted'] }
  }
  named_scope :least_recently_updated, lambda{|limit|
    {:order => 'updated_at', :limit => limit }
  }
  named_scope :manageable_by_user, lambda{ |*args|
    # args[0] should be user_id, args[1], if true, will include completed
    # enrollments as well as active enrollments
    user_id = args[0]
    workflow_states = (args[1].present? ? %w{'active' 'completed'} : %w{'active'}).join(', ')
    { :select => 'DISTINCT courses.*',
      :joins => "INNER JOIN (
         SELECT caa.course_id, au.user_id FROM course_account_associations AS caa
         INNER JOIN accounts AS a ON a.id = caa.account_id AND a.workflow_state = 'active'
         INNER JOIN account_users AS au ON au.account_id = a.id AND au.user_id = #{user_id.to_i}
       UNION SELECT courses.id AS course_id, e.user_id FROM courses
         INNER JOIN enrollments AS e ON e.course_id = courses.id AND e.user_id = #{user_id.to_i}
           AND e.workflow_state IN(#{workflow_states}) AND e.type IN ('TeacherEnrollment', 'TaEnrollment', 'DesignerEnrollment')
         WHERE courses.workflow_state <> 'deleted') as course_users
       ON course_users.course_id = courses.id"
    }
  }
  named_scope :not_deleted, {:conditions => ['workflow_state != ?', 'deleted']}

  named_scope :with_enrollments, lambda {
    { :conditions => ["exists (#{Enrollment.active.send(:construct_finder_sql, {:select => "1", :conditions => ["enrollments.course_id = courses.id"]})})"] }
  }

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

  def users_not_in_groups_sql(groups, opts={})
    ["SELECT DISTINCT u.id, u.name#{", #{opts[:order_by]}" if opts[:order_by].present?}
        FROM users u
       INNER JOIN enrollments e ON e.user_id = u.id
       WHERE e.course_id = ? AND e.workflow_state NOT IN ('rejected', 'completed', 'deleted') AND e.type = 'StudentEnrollment'
             #{"AND NOT EXISTS (SELECT *
                                  FROM group_memberships gm
                                 WHERE gm.user_id = u.id AND
                                       gm.group_id IN (#{groups.map(&:id).join ','}))" unless groups.empty?}
       #{"ORDER BY #{opts[:order_by]}" if opts[:order_by].present?}
       #{"#{opts[:order_by_dir]}" if opts[:order_by_dir]}", self.id]
  end

  def users_not_in_groups(groups)
    User.find_by_sql(users_not_in_groups_sql(groups))
  end

  def paginate_users_not_in_groups(groups, page, per_page = 15)
    User.paginate_by_sql(users_not_in_groups_sql(groups, :order_by => "#{User.sortable_name_order_by_clause('u')}", :order_by_dir => "ASC"),
                         :page => page, :per_page => per_page)
  end

  def instructors_in_charge_of(user_id)
    section_ids = current_enrollments.find(:all, :select => 'course_section_id, course_id, user_id, limit_privileges_to_course_section', :conditions => {:course_id => self.id, :user_id => user_id}).map(&:course_section_id).compact.uniq
    participating_instructors.restrict_to_sections(section_ids)
  end

  def user_is_teacher?(user)
    return unless user
    Rails.cache.fetch([self, user, "course_user_is_teacher"].cache_key) do
      user.cached_current_enrollments.any? { |e| e.course_id == self.id && e.participating_instructor? }
    end
  end
  memoize :user_is_teacher?

  def user_is_student?(user)
    return unless user
    Rails.cache.fetch([self, user, "course_user_has_been_student"].cache_key) do
      self.student_enrollments.find_by_user_id(user.id).present?
    end
  end
  memoize :user_is_student?

  def user_has_been_teacher?(user)
    return unless user
    Rails.cache.fetch([self, user, "course_user_has_been_teacher"].cache_key) do
      self.teacher_enrollments.find_by_user_id(user.id).present?
    end
  end
  memoize :user_has_been_teacher?

  def user_has_been_student?(user)
    return unless user
    Rails.cache.fetch([self, user, "course_user_has_been_student"].cache_key) do
      self.all_student_enrollments.find_by_user_id(user.id).present?
    end
  end
  memoize :user_has_been_student?

  def grade_weight_changed!
    @grade_weight_changed = true
    self.save!
    @grade_weight_changed = false
  end

  def membership_for_user(user)
    self.enrollments.find_by_user_id(user && user.id)
  end

  def assert_defaults
    Hashtag.find_or_create_by_hashtag(self.hashtag) if self.hashtag && self.hashtag != ""
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
    if self.root_account_id && self.root_account_id_changed?
      a = self.account(self.account && self.account.id != self.account_id)
      self.account_id = nil if self.account_id && self.account_id != self.root_account_id && a && a.root_account_id != self.root_account_id
      self.account_id ||= self.root_account_id
    end
    self.root_account_id ||= Account.default.id
    self.account_id ||= self.root_account_id
    self.enrollment_term = nil if self.enrollment_term.try(:root_account_id) != self.root_account_id
    self.enrollment_term ||= self.root_account.default_enrollment_term
    self.publish_grades_immediately = true if self.publish_grades_immediately == nil
    self.allow_student_wiki_edits = (self.default_wiki_editing_roles || "").split(',').include?('students')
    true
  end

  def update_course_section_names
    return if @course_name_was == self.name || !@course_name_was
    sections = self.course_sections
    fields_to_possibly_rename = [:name, :section_code, :long_section_code]
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
        CourseSection.update_all(attr_hash, {:id => section.id})
      end
    end
  end

  def update_enrollments_later
    self.update_enrolled_users if !self.new_record? && !(self.changes.keys & ['workflow_state', 'name', 'course_code', 'start_at', 'conclude_at', 'enrollment_term_id']).empty?
    true
  end

  def update_enrolled_users
    if self.completed?
      Enrollment.update_all({:workflow_state => 'completed'}, "course_id=#{self.id} AND workflow_state IN('active', 'invited')")
      appointment_participants.active.current.update_all(:workflow_state => 'deleted')
      appointment_groups.each(&:clear_cached_available_slots!)
    elsif self.deleted?
      Enrollment.update_all({:workflow_state => 'deleted'}, "course_id=#{self.id} AND workflow_state!='deleted'")
    end

    if self.root_account_id_changed?
      Enrollment.update_all({:root_account_id => self.root_account_id}, :course_id => self.id)
    end

    case Enrollment.connection.adapter_name
    when 'MySQL'
      Enrollment.connection.execute("UPDATE users, enrollments SET users.updated_at=NOW(), enrollments.updated_at=NOW() WHERE users.id=enrollments.user_id AND enrollments.course_id=#{self.id}")
    else
      Enrollment.update_all({:updated_at => Time.now.utc}, :course_id => self.id)
      User.update_all({:updated_at => Time.now.utc}, "id IN (SELECT user_id FROM enrollments WHERE course_id=#{self.id})")
    end
  end

  def self_enrollment_allowed?
    !!(self.account && self.account.self_enrollment_allowed?(self))
  end

  def self_enrollment_code
    read_attribute(:self_enrollment_code) || set_self_enrollment_code if self_enrollment?
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

  def long_self_enrollment_code
    Digest::MD5.hexdigest("#{uuid}_for_#{id}")
  end
  memoize :long_self_enrollment_code

  # still include the old longer format, since links may be out there
  def self_enrollment_codes
    [self_enrollment_code, long_self_enrollment_code]
  end

  def update_final_scores_on_weighting_scheme_change
    if @group_weighting_scheme_changed
      Enrollment.send_later_if_production(:recompute_final_score, self.students.map(&:id), self.id)
    end
  end

  def recompute_student_scores
    Enrollment.recompute_final_score(self.students.map(&:id), self.id)
  end
  handle_asynchronously_if_production :recompute_student_scores,
    :singleton => proc { |c| "recompute_student_scores:#{ c.global_id }" }

  def home_page
    WikiNamespace.default_for_context(self).wiki.wiki_page
  end

  def context_code
    raise "DONT USE THIS, use .short_name instead" unless ENV['RAILS_ENV'] == "production"
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

  # Allows the account to be set directly
  belongs_to :account

  def wiki
    res = self.wiki_id && Wiki.find_by_id(self.wiki_id)
    unless res
      res = WikiNamespace.default_for_context(self).wiki
      self.wiki_id = res.id if res
      self.save
    end
    res
  end

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

  def hashtag_model
    Hashtag.find_by_hashtag(self.hashtag) if self.hashtag
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
    hash = {}
    courses.each{|c| hash[c.id] = {:found => false, :course => c} }
    groups = AssignmentGroup.find(:all, {:select => "id, context_id, context_type", :conditions => {:context_type => "Course", :context_id => courses.map(&:id)}})
    groups.each{|c| hash[c.context_id][:found] = true }
    hash.select{|id, obj| !obj[:found] }.each{|id, obj| obj[:course].require_assignment_group rescue nil }
  end

  def require_assignment_group
    has_group = Rails.cache.read(['has_assignment_group', self].cache_key)
    return if has_group && ENV['RAILS_ENV'] == 'production'
    if self.assignment_groups.active.empty?
      self.assignment_groups.create(:name => t('#assignment_group.default_name', "Assignments"))
    end
    Rails.cache.write(['has_assignment_group', self].cache_key, true)
  end

  def self.create_unique(uuid=nil, account_id=nil, root_account_id=nil)
    uuid ||= AutoHandle.generate_securish_uuid
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
      Setting.get_cached('course_default_quota', 500.megabytes.to_s).to_i
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
    self.uuid ||= AutoHandle.generate_securish_uuid
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
    can :read

    RoleOverride.permissions.each_key do |permission|
      given {|user, session| self.enrollment_allows(user, session, permission) || self.account_membership_allows(user, session, permission) }
      can permission
    end
    
    given { |user, session| session && session[:enrollment_uuid] && (hash = Enrollment.course_user_state(self, session[:enrollment_uuid]) || {}) && (hash[:enrollment_state] == "invited" || hash[:enrollment_state] == "active" && hash[:user_state] == "pre_registered") && (self.available? || self.completed? || self.claimed? && hash[:is_admin]) }
    can :read

    given { |user| (self.available? || self.completed?) && user && user.cached_current_enrollments.any?{|e| e.course_id == self.id && [:active, :invited, :completed].include?(e.state_based_on_date) } }
    can :read

    # may want to make this more restrictive, but this is what it was prior to creating student view
    given { |user| user && self.enrollments.not_fake.map(&:user_id).include?(user.id) }
    can :participate_in_groups

    # Active students
    given { |user| self.available? && user && user.cached_current_enrollments.any?{|e| e.course_id == self.id && e.participating_student? } }
    can :read and can :participate_as_student and can :read_grades
    
    given { |user| (self.available? || self.completed?) && user && user.cached_not_ended_enrollments.any?{|e| e.course_id == self.id && e.participating_observer? && e.associated_user_id} }
    can :read_grades

    given { |user, session| self.available? && self.teacherless? && user && user.cached_not_ended_enrollments.any?{|e| e.course_id == self.id && e.participating_student? } && (!session || !session["role_course_#{self.id}"]) }
    can :update and can :delete and RoleOverride.teacherless_permissions.each{|p| can p }

    # Active teachers
    given { |user, session| (self.available? || self.created? || self.claimed?) && user && user.cached_not_ended_enrollments.any?{|e| e.course_id == self.id && e.participating_admin? } && (!session || !session["role_course_#{self.id}"]) }
    can :read_as_admin and can :read and can :manage and can :update and can :use_student_view

    given { |user, session| !self.deleted? && !self.sis_source_id && user && user.cached_not_ended_enrollments.any?{|e| e.course_id == self.id && e.participating_admin? } && (!session || !session["role_course_#{self.id}"]) }
    can :delete

    # Student view student
    given { |user| user && user.fake_student? && user.cached_not_ended_enrollments.any?{ |e| e.course_id == self.id } }
    can :read and can :participate_as_student and can :read_grades

    # Prior users
    given { |user| (self.available? || self.completed?) && user && self.prior_enrollments.map(&:user_id).include?(user.id) }
    can :read

    # Teacher of a concluded course
    given { |user| !self.deleted? && user && (self.prior_enrollments.select{|e| e.admin? }.map(&:user_id).include?(user.id) || user.cached_not_ended_enrollments.any? { |e| e.course_id == self.id && e.admin? && e.completed? }) }
    can :read and can :read_as_admin and can :read_roster and can :read_prior_roster and can :read_forum and can :use_student_view

    given { |user| !self.deleted? && user && (self.prior_enrollments.select{|e| e.instructor? }.map(&:user_id).include?(user.id) || user.cached_not_ended_enrollments.any? { |e| e.course_id == self.id && e.instructor? && e.completed? }) }
    can :read_user_notes and can :view_all_grades

    given { |user| !self.deleted? && !self.sis_source_id && user && (self.prior_enrollments.select{|e| e.admin? }.map(&:user_id).include?(user.id) || user.cached_not_ended_enrollments.any? { |e| e.course_id == self.id && e.admin? && e.state_based_on_date == :completed })}
    can :delete

    # Student of a concluded course
    given { |user| (self.available? || self.completed?) && user && (self.prior_enrollments.select{|e| e.student? || e.assigned_observer? }.map(&:user_id).include?(user.id) || user.cached_not_ended_enrollments.any? { |e| e.course_id == self.id && (e.student? || e.assigned_observer?) && e.state_based_on_date == :completed }) }
    can :read and can :read_grades and can :read_forum

    # Viewing as different role type
    given { |user, session| session && session["role_course_#{self.id}"] }
    can :read

    # Admin
    given { |user, session| self.account_membership_allows(user, session) }
    can :read_as_admin

    given { |user, session| self.account_membership_allows(user, session, :manage_courses) }
    can :read_as_admin and can :manage and can :update and can :delete and can :use_student_view

    given { |user, session| self.account_membership_allows(user, session, :read_course_content) }
    can :read

    given { |user, session| !self.deleted? && self.sis_source_id && self.account_membership_allows(user, session, :manage_sis) }
    can :delete

    # Admins with read_roster can see prior enrollments (can't just check read_roster directly,
    # because students can't see prior enrollments)
    given { |user, session| self.account_membership_allows(user, session, :read_roster) }
    can :read_prior_roster
  end

  def enrollment_allows(user, session, permission)
    return false unless user && permission

    @enrollment_lookup ||= {}
    @enrollment_lookup[user.id] ||=
      if session && temp_type = session["role_course_#{self.id}"]
        [Enrollment.typed_enrollment(temp_type).new(:course => self, :user => user, :workflow_state => 'active')]
      else
        self.enrollments.active_or_pending.for_user(user).reject { |e| [:inactive, :completed].include?(e.state_based_on_date)}
      end

    @enrollment_lookup[user.id].any? {|e| e.has_permission_to?(permission) }
  end

  def self.find_all_by_context_code(codes)
    ids = codes.map{|c| c.match(/\Acourse_(\d+)\z/)[1] rescue nil }.compact
    Course.find(:all, :conditions => {:id => ids}, :include => :current_enrollments)
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

  def has_outcomes?
    self.learning_outcomes.count > 0
  end

  def account_chain
    self.account.account_chain
  end

  def account_chain_ids
    account_chain.map(&:id)
  end
  memoize :account_chain_ids

  def institution_name
    return self.root_account.name if self.root_account_id != Account.default.id
    return (self.account || self.root_account).name
  end
  memoize :institution_name

  def account_users_for(user)
    @associated_account_ids ||= (self.associated_accounts + [Account.site_admin]).map { |a| a.active? ? a.id: nil }.compact
    @account_users ||= {}
    @account_users[user] ||= AccountUser.find(:all, :conditions => { :account_id => @associated_account_ids, :user_id => user.id }) if user
    @account_users[user] ||= nil
    @account_users[user]
  end

  def account_membership_allows(user, session, permission = nil)
    return false unless user
    return false if session && session["role_course_#{self.id}"]

    @membership_allows ||= {}
    @membership_allows[[user.id, permission]] ||= self.account_users_for(user).any? { |au| permission.nil? || au.has_permission_to?(permission) }
  end

  def teacherless?
    # TODO: I need a better test for teacherless courses... in the mean time we'll just do this
    return false
    @teacherless_course ||= Rails.cache.fetch(['teacherless_course', self].cache_key) do
      !self.sis_source_id && self.teacher_enrollments.empty?
    end
  end

  def wiki_namespace
    WikiNamespace.default_for_context(self)
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
  memoize :grade_publishing_status_translation

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

  def publish_final_grades(publishing_user)
    # we want to set all the publishing statuses to 'pending' immediately,
    # and then as a delayed job, actually go publish them.

    raise "final grade publishing disabled" unless Canvas::Plugin.find!('grade_export').enabled?
    settings = Canvas::Plugin.find!('grade_export').settings

    last_publish_attempt_at = Time.now.utc
    self.student_enrollments.not_fake.update_all :grade_publishing_status => "pending",
                                        :grade_publishing_message => nil,
                                        :last_publish_attempt_at => last_publish_attempt_at

    send_later_if_production(:send_final_grades_to_endpoint, publishing_user)
    send_at(last_publish_attempt_at + settings[:success_timeout].to_i.seconds, :expire_pending_grade_publishing_statuses, last_publish_attempt_at) if should_kick_off_grade_publishing_timeout?
  end

  def send_final_grades_to_endpoint(publishing_user)
    # actual grade publishing logic is here, but you probably want
    # 'publish_final_grades'

    self.recompute_student_scores_without_send_later
    enrollments = self.student_enrollments.not_fake.scoped({:include => [:user, :course_section]}).find(:all, :order => User.sortable_name_order_by_clause('users'))

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
      Enrollment.update_all({ :grade_publishing_status => "error", :grade_publishing_message => "#{e}"}, { :id => all_enrollment_ids })
      raise e
    end

    posts_to_make.each do |enrollment_ids, res, mime_type|
      begin
        posted_enrollment_ids += enrollment_ids
        SSLCommon.post_data(settings[:publish_endpoint], res, mime_type)
        Enrollment.update_all({ :grade_publishing_status => (should_kick_off_grade_publishing_timeout? ? "publishing" : "published"), :grade_publishing_message => nil }, { :id => enrollment_ids })
      rescue => e
        errors << e
        Enrollment.update_all({ :grade_publishing_status => "error", :grade_publishing_message => "#{e}"}, { :id => enrollment_ids })
      end
    end

    Enrollment.update_all({ :grade_publishing_status => "unpublishable", :grade_publishing_message => nil }, { :id => (all_enrollment_ids.to_set - posted_enrollment_ids.to_set).to_a })

    raise errors[0] if errors.size > 0
  end

  def generate_grade_publishing_csv_output(enrollments, publishing_user, publishing_pseudonym)
    enrollment_ids = []
    res = FasterCSV.generate do |csv|
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
    self.student_enrollments.not_fake.scoped(:conditions => ["grade_publishing_status IN ('pending', 'publishing') AND last_publish_attempt_at = ?",
      last_publish_attempt_at]).update_all :grade_publishing_status => 'error', :grade_publishing_message => "Timed out."
  end

  def gradebook_to_csv(options = {})
    if options[:assignment_id]
      assignments = [self.assignments.active.gradeable.find(options[:assignment_id])]
    else
      group_order = {}
      self.assignment_groups.active.each_with_index{|group, idx| group_order[group.id] = idx}
      assignments = self.assignments.active.gradeable.find(:all).sort_by{|a| [a.due_at ? 1 : 0, a.due_at || 0, group_order[a.assignment_group_id] || 0, a.position || 0, a.title || ""]}
    end
    single = assignments.length == 1
    includes = [:user, :course_section]
    includes = {:user => :pseudonyms, :course_section => []} if options[:include_sis_id]
    student_enrollments = self.student_enrollments.scoped(:include => includes).find(:all, :order => User.sortable_name_order_by_clause('users'))
    # remove duplicate enrollments for students enrolled in multiple sections
    seen_users = []
    student_enrollments.reject! { |e| seen_users.include?(e.user_id) ? true : (seen_users << e.user_id; false) }
    submissions = self.submissions.inject({}) { |h, sub|
      h[[sub.user_id, sub.assignment_id]] = sub; h
    }
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
    res = FasterCSV.generate do |csv|
      #First row
      row = ["Student", "ID"]
      row.concat(["SIS User ID", "SIS Login ID"]) if options[:include_sis_id]
      row << "Section"
      row.concat(assignments.map{|a| single ? [a.title_with_id, 'Comments'] : a.title_with_id})
      row.concat(["Current Score", "Final Score"])
      row.concat(["Final Grade"]) if self.grading_standard_enabled?
      csv << row.flatten

      #Possible muted row
      if assignments.any?(&:muted)
        #This is is not translated since we look for this exact string when we upload to gradebook.
        row = ['Muted assignments do not impact Current and Final score columns', '', '']
        row.concat(['', '']) if options[:include_sis_id]
        row.concat(assignments.map{|a| single ? [(a.muted ? 'Muted': ''), ''] : (a.muted ? 'Muted' : '')})
        row.concat(['', ''])
        row.concat(['']) if self.grading_standard_enabled?
        csv << row.flatten
      end

      #Second Row
      row = ["    Points Possible", "", ""]
      row.concat(["", ""]) if options[:include_sis_id]
      row.concat(assignments.map{|a| single ? [a.points_possible, ''] : a.points_possible})
      row.concat([read_only, read_only])
      row.concat([read_only]) if self.grading_standard_enabled?
      csv << row.flatten

      student_enrollments.each do |student_enrollment|
        student = student_enrollment.user
        student_section = (student_enrollment.course_section.display_name rescue nil) || ""
        student_submissions = assignments.map do |a|
          submission = submissions[[student.id, a.id]]
          score = submission && submission.score ? submission.score : ""
          data = [score, ''] rescue ["", '']
          single ? data : data[0]
        end
        #Last Row
        row = [student.last_name_first, student.id]
        if options[:include_sis_id]
          pseudonym = student.sis_pseudonym_for(self.root_account)
          row << pseudonym.try(:sis_user_id)
          pseudonym ||= student.find_pseudonym_for_account(self.root_account, true)
          row << pseudonym.try(:unique_id)
        end
        row << student_section
        row.concat(student_submissions)
        row.concat([student_enrollment.computed_current_score, student_enrollment.computed_final_score])
        if self.grading_standard_enabled?
          row.concat([score_to_grade(student_enrollment.computed_final_score)])
        end
        csv << row.flatten
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
    scheme = self.grading_standard.try(:data) || GradingStandard.default_grading_standard
    GradingStandard.score_to_grade(scheme, score)
  end

  def participants(include_observers=false)
    (participating_admins + participating_students + (include_observers ? participating_observers : [])).uniq
  end

  def enroll_user(user, type='StudentEnrollment', opts={})
    enrollment_state = opts[:enrollment_state]
    section = opts[:section]
    limit_privileges_to_course_section = opts[:limit_privileges_to_course_section]
    section ||= self.default_section
    enrollment_state ||= self.available? ? "invited" : "creation_pending"
    if type == 'TeacherEnrollment' || type == 'TaEnrollment' || type == 'DesignerEnrollment'
      enrollment_state = 'invited' if enrollment_state == 'creation_pending'
    else
      enrollment_state = 'creation_pending' if enrollment_state == 'invited' && !self.available?
    end
    if opts[:allow_multiple_enrollments]
      e = self.enrollments.find_by_user_id_and_type_and_course_section_id(user.id, type, section.id)
    else
      e = self.enrollments.find_by_user_id_and_type(user.id, type)
    end
    e.attributes = { 
      :course_section => section, 
      :workflow_state => 'invited', 
      :limit_privileges_to_course_section => limit_privileges_to_course_section } if e && (e.completed? || e.rejected?)
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
    if e.changed?
      if opts[:no_notify]
        e.save_without_broadcasting
      else
        e.save
      end
    end
    e.user = user
    self.claim if self.created? && e && e.admin?
    user.try(:touch) unless opts[:skip_touch_user]
    user.try(:reload)
    e
 end

  def enroll_student(user, opts={})
    enroll_user(user, 'StudentEnrollment', opts)
  end

  def enroll_ta(user)
    enroll_user(user, 'TaEnrollment')
  end

  def enroll_designer(user)
    enroll_user(user, 'DesignerEnrollment')
  end

  def enroll_teacher(user)
    enroll_user(user, 'TeacherEnrollment')
  end

  def resubmission_for(asset_string)
    instructors.each{|u| u.ignored_item_changed!(asset_string, 'grading') }
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

  def default_section
    self.course_sections.active.find_or_create_by_default_section(true) do |section|
      section.course = self
      section.root_account = self.root_account
    end
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


  def merge_in(course, options = {}, import = nil)
    return [] if course == self
    res = merge_into_course(course, options, import)
    course.course_sections.active.each do |section|
      if options[:all_sections] || options[section.asset_string.to_sym]
        section.move_to_course(self)
      end
    end
    res
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
    self.account.turnitin_settings
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

  def self.find_or_create_for_new_context(obj_class, new_context, old_context, old_id)
    association_name = obj_class.table_name
    old_item = old_context.send(association_name).find_by_id(old_id)
    res = new_context.send(association_name).first(:conditions => { :cloned_item_id => old_item.cloned_item_id}, :order => 'id desc') if old_item
    if !res && old_item
      # make sure it's active by re-finding it with the active scope ... active
      old_item = old_context.send(association_name).active.find_by_id(old_item.id)
      res = old_item.clone_for(new_context) if old_item
      res.save if res
    end
    res
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
      new_id = @merge_mappings["#{match.obj_class.name.underscore}_#{match.obj_id}"]
      next(new_url) unless rewriter.user_can_view_content? { match.obj_class.find_by_id(match.obj_id) }
      if !new_id && to_context != from_context
        new_obj = self.find_or_create_for_new_context(match.obj_class, to_context, from_context, match.obj_id)
        new_id = new_obj.id if new_obj
      end
      if !limit_migrations_to_listed_types || new_id
        new_url = new_url.gsub("#{match.type}/#{match.obj_id}", new_id ? "#{match.type}/#{new_id}" : "#{match.type}")
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

  def process_migration_files(data, migration)
    return unless data['all_files_export'] && data['all_files_export']['file_path']
    return unless File.exist?(data['all_files_export']['file_path'])

    self.attachment_path_id_lookup ||= {}
    params = migration.migration_settings[:migration_ids_to_import]
    valid_paths = []
    (data['file_map'] || {}).each do |id, file|
      if !migration.context.attachments.detect { |f| f.migration_id == file['migration_id'] } || migration.migration_settings[:files_import_allow_rename]
        path = file['path_name'].starts_with?('/') ? file['path_name'][1..-1] : file['path_name']
        self.attachment_path_id_lookup[path] = file['migration_id']
        if params[:copy][:files]
          valid_paths << path if (bool_res(params[:copy][:files][file['migration_id'].to_sym]) rescue false)
        else
          valid_paths << path
        end
      end
    end
    valid_paths = [0] if valid_paths.empty? && params[:copy] && params[:copy][:files]
    logger.debug "adding #{valid_paths.length} files"
    total = valid_paths.length
    if valid_paths != [0]
      current = 0
      last = current
      callback = Proc.new do
        current += 1
        if (current - last) > 10
          last = current
          migration.fast_update_progress((current.to_f/total) * 18.0)
        end
      end
      unzip_opts = {
        :course => migration.context,
        :filename => data['all_files_export']['file_path'],
        :valid_paths => valid_paths,
        :callback => callback,
        :logger => logger,
        :rename_files => migration.migration_settings[:files_import_allow_rename],
        :migration_id_map => self.attachment_path_id_lookup,
      }
      if root_path = migration.migration_settings[:files_import_root_path]
        unzip_opts[:root_directory] = Folder.assert_path(
          root_path, migration.context)
      end
      unzipper = UnzipAttachment.new(unzip_opts)
      migration.fast_update_progress(1.0)
      unzipper.process
    end
  end
  private :process_migration_files

  def import_media_objects(mo_attachments, migration)
    wait_for_completion = (migration && migration.migration_settings[:worker_class] == CC::Importer::Canvas::Converter.name)
    unless mo_attachments.blank?
      MediaObject.add_media_files(mo_attachments, wait_for_completion)
    end
  end

  def import_from_migration(data, params, migration)
    params ||= {:copy=>{}}
    logger.debug "starting import"
    @full_migration_hash = data
    @external_url_hash = {}
    @migration_results = []
    @content_migration = migration
    (data['web_link_categories'] || []).map{|c| c['links'] }.flatten.each do |link|
      @external_url_hash[link['link_id']] = link
    end
    ActiveRecord::Base.skip_touch_context
    @imported_migration_items = []

    if !migration.for_course_copy?
      # These only need to be processed once
      Attachment.skip_media_object_creation do
        process_migration_files(data, migration); migration.fast_update_progress(18)
        Attachment.process_migration(data, migration); migration.fast_update_progress(20)
        mo_attachments = self.imported_migration_items.find_all { |i| i.is_a?(Attachment) && i.media_entry_id.present? }
        import_media_objects(mo_attachments, migration)
      end
    end

    migration.fast_update_progress(30)
    question_data = AssessmentQuestion.process_migration(data, migration); migration.fast_update_progress(35)
    Group.process_migration(data, migration); migration.fast_update_progress(36)
    LearningOutcome.process_migration(data, migration); migration.fast_update_progress(37)
    Rubric.process_migration(data, migration); migration.fast_update_progress(38)
    @assignment_group_no_drop_assignments = {}
    AssignmentGroup.process_migration(data, migration); migration.fast_update_progress(39)
    ExternalFeed.process_migration(data, migration); migration.fast_update_progress(39.5)
    GradingStandard.process_migration(data, migration); migration.fast_update_progress(40)
    Quiz.process_migration(data, migration, question_data); migration.fast_update_progress(50)
    ContextExternalTool.process_migration(data, migration); migration.fast_update_progress(54)

    #These need to be ran twice because they can reference each other
    DiscussionTopic.process_migration(data, migration);migration.fast_update_progress(55)
    WikiPage.process_migration(data, migration);migration.fast_update_progress(60)
    Assignment.process_migration(data, migration);migration.fast_update_progress(65)
    ContextModule.process_migration(data, migration);migration.fast_update_progress(70)
    # and second time...
    DiscussionTopic.process_migration(data, migration);migration.fast_update_progress(75)
    WikiPage.process_migration(data, migration);migration.fast_update_progress(80)
    Assignment.process_migration(data, migration);migration.fast_update_progress(85)

    #These aren't referenced by anything, but reference other things
    CalendarEvent.process_migration(data, migration);migration.fast_update_progress(90)
    WikiPage.process_migration_course_outline(data, migration);migration.fast_update_progress(95)

    if !migration.copy_options || migration.is_set?(migration.copy_options[:everything]) || migration.is_set?(migration.copy_options[:all_course_settings])
      import_settings_from_migration(data, migration); migration.fast_update_progress(96)
    end

    begin
      #Adjust dates
      if bool_res(params[:copy][:shift_dates])
        shift_options = (bool_res(params[:copy][:shift_dates]) rescue false) ? params[:copy] : {}
        shift_options = shift_date_options(self, shift_options)
        @imported_migration_items.each do |event|
          if event.is_a?(Assignment)
            event.due_at = shift_date(event.due_at, shift_options)
            event.lock_at = shift_date(event.lock_at, shift_options)
            event.unlock_at = shift_date(event.unlock_at, shift_options)
            event.peer_reviews_due_at = shift_date(event.peer_reviews_due_at, shift_options)
            event.save_without_broadcasting!
          elsif event.is_a?(DiscussionTopic)
            event.delayed_post_at = shift_date(event.delayed_post_at, shift_options)
            event.save_without_broadcasting!
          elsif event.is_a?(CalendarEvent)
            event.start_at = shift_date(event.start_at, shift_options)
            event.end_at = shift_date(event.end_at, shift_options)
            event.save_without_broadcasting!
          elsif event.is_a?(Quiz)
            event.due_at = shift_date(event.due_at, shift_options)
            event.lock_at = shift_date(event.lock_at, shift_options)
            event.unlock_at = shift_date(event.unlock_at, shift_options)
            event.save!
          elsif event.is_a?(ContextModule)
            event.unlock_at = shift_date(event.unlock_at, shift_options)
            event.start_at = shift_date(event.start_at, shift_options)
            event.end_at = shift_date(event.end_at, shift_options)
            event.save!
          end
        end

        self.start_at ||= shift_options[:new_start_date]
        self.conclude_at ||= shift_options[:new_end_date]
      end
    rescue
      add_migration_warning("Couldn't adjust the due dates.", $!)
    end
    migration.progress=100
    migration.migration_settings ||= {}
    migration.migration_settings[:imported_assets] = @imported_migration_items.map(&:asset_string)
    migration.workflow_state = :imported
    migration.save
    ActiveRecord::Base.skip_touch_context(false)
    self.touch
    @imported_migration_items
  end
  attr_accessor :imported_migration_items, :full_migration_hash, :external_url_hash, :content_migration
  attr_accessor :folder_name_lookups, :attachment_path_id_lookup, :assignment_group_no_drop_assignments

  def import_settings_from_migration(data, migration)
    return unless data[:course]
    settings = data[:course]
    self.syllabus_body = ImportedHtmlConverter.convert(settings[:syllabus_body], self) if settings[:syllabus_body]
    if settings[:tab_configuration] && settings[:tab_configuration].is_a?(Array)
      self.tab_configuration = settings[:tab_configuration]
    end
    if settings[:storage_quota] && ( migration.for_course_copy? || self.account.grants_right?(migration.user, nil, :manage_courses))
      self.storage_quota = settings[:storage_quota]
    end
    self.settings[:hide_final_grade] = !!settings[:hide_final_grade] unless settings[:hide_final_grade].nil?
    atts = Course.clonable_attributes
    atts -= Canvas::Migration::MigratorHelper::COURSE_NO_COPY_ATTS
    settings.slice(*atts.map(&:to_s)).each do |key, val|
      self.send("#{key}=", val)
    end
    if settings[:grading_standard_enabled]
      self.grading_standard_enabled = true
      if settings[:grading_standard_identifier_ref]
        if gs = self.grading_standards.find_by_migration_id(settings[:grading_standard_identifier_ref])
          self.grading_standard = gs
        else
          migration.add_warning("Couldn't find copied grading standard for the course.")
        end
      elsif settings[:grading_standard_id]
        if gs = GradingStandard.sorted_standards_for(self).find{|s|s.id == settings[:grading_standard_id]}
          self.grading_standard = gs
        else
          migration.add_warning("Couldn't find account grading standard for the course.")
        end
      end
    end
  end

  def add_migration_warning(message, exception='')
    return unless @content_migration
    @content_migration.add_warning(message, exception)
  end

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

  def may_have_links_to_migrate(item)
    @to_migrate_links ||= []
    @to_migrate_links << item
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

    attachments = course.attachments.all(:conditions => "file_state <> 'deleted'")
    total = attachments.count + 1

    attachments.each_with_index do |file, i|
      cm.fast_update_progress((i.to_f/total) * 18.0) if cm && (i % 10 == 0)
      if !ce || ce.export_object?(file)
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
          while old_folders.last.parent_folder && old_folders.last.parent_folder.parent_folder_id && !merge_mapped_id(old_folders.last.parent_folder)
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
        new_file.save!
        map_merge(file, new_file)
      end
    end
  end

  attr_accessor :merge_mappings
  COPY_OPTIONS = [:all_course_settings, :all_assignments, :all_external_tools, :all_files, :all_topics,
                  :all_calendar_events, :all_quizzes, :all_wiki_pages, :all_modules, :all_outcomes]
  def merge_into_course(course, options, course_import = nil)
    @merge_mappings = {}
    @merge_results = []
    to_shift_dates = []
    @to_migrate_links = []
    added_items = []
    delete_placeholder = nil

    if bool_res(options[:course_settings]) || bool_res(options[:all_course_settings])
      #Copy the course settings too
      course.attributes.slice(*Course.clonable_attributes.map(&:to_s)).keys.each do |attr|
        self.send("#{attr}=", course.send(attr))
      end
      may_have_links_to_migrate(self)
      self.save
    end
    if self.assignment_groups.length == 1 && self.assignment_groups.first.name == t('#assignment_group.default_name', "Assignments") && self.assignment_groups.first.assignments.empty?
      delete_placeholder = self.assignment_groups.first
      self.group_weighting_scheme = course.group_weighting_scheme
    elsif self.assignment_groups.length == 0
      self.group_weighting_scheme = course.group_weighting_scheme
    end
    # There are groups to migrate
    course.assignment_groups.active.each do |group|
      if bool_res(options[:everything]) || bool_res(options[:all_assignments]) || bool_res(options[group.asset_string.to_sym])
        new_group = group.clone_for(self)
        added_items << new_group
        new_group.save_without_broadcasting!
        map_merge(group, new_group)
      end
    end
    course.context_external_tools.active.each do |old_tool|
      course_import.tick(82) if course_import
      if bool_res(options[:everything]) || bool_res(options[:all_external_tools]) || bool_res(options[old_tool.asset_string.to_sym])
        new_tool = old_tool.clone_for(self)
        new_tool.save
        added_items << new_tool
      end
    end
    course.assignments.no_graded_quizzes_or_topics.active.select{|a| a.assignment_group_id }.each do |assignment|
      course_import.tick(15) if course_import
      if bool_res(options[:everything]) || bool_res(options[:all_assignments]) || bool_res(options[assignment.asset_string.to_sym])
        new_assignment = assignment.clone_for(self, nil, :migrate => false)
        to_shift_dates << new_assignment if new_assignment.clone_updated || same_dates?(assignment, new_assignment, [:due_at, :lock_at, :unlock_at, :peer_reviews_due_at])
        added_items << new_assignment
        new_assignment.save_without_broadcasting!
        map_merge(assignment, new_assignment)
      end
    end
    # next, attachments
    map_merge(Folder.root_folders(course).first, Folder.root_folders(self).first)
    course.attachments.all(:conditions => "file_state <> 'deleted'").each do |file|
      course_import.tick(30) if course_import
      if bool_res(options[:everything] ) || bool_res(options[:all_files] ) || bool_res(options[file.asset_string.to_sym] )
        new_file = file.clone_for(self)
        added_items << new_file
        new_folder_id = merge_mapped_id(file.folder)
        # make sure the file has somewhere to go
        if !new_folder_id
          # gather mapping of needed folders from old course to new course
          old_folders = []
          old_folders << file.folder
          new_folders = []
          new_folders << old_folders.last.clone_for(self, nil, options.merge({:include_subcontent => false}))
          while old_folders.last.parent_folder && old_folders.last.parent_folder.parent_folder_id && !merge_mapped_id(old_folders.last.parent_folder)
            old_folders << old_folders.last.parent_folder
            new_folders << old_folders.last.clone_for(self, nil, options.merge({:include_subcontent => false}))
          end
          added_items += new_folders
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
        new_file.save!
        map_merge(file, new_file)
      end
    end
    course.discussion_topics.active.each do |topic|
      course_import.tick(40) if course_import
      if bool_res(options[:everything] ) || bool_res(options[:all_topics] ) || bool_res(options[topic.asset_string.to_sym] ) || (topic.assignment_id && bool_res(options["assignment_#{topic.assignment_id}"]))
        include_entries = options["discussion_topic_#{topic.id}_entries"] == "1"
        new_topic = topic.clone_for(self, nil, :migrate => bool_res(options["#{topic.asset_string}_entries".to_sym] ), :include_entries => include_entries)
        to_shift_dates << new_topic if new_topic.delayed_post_at && (new_topic.clone_updated || same_dates?(topic, new_topic, [:delayed_post_at]))
        to_shift_dates << new_topic.assignment if new_topic.assignment && (new_topic.assignment_clone_updated || same_dates?(topic.assignment, new_topic.assignment, [:due_at, :lock_at, :unlock_at, :peer_reviews_due_at]))
        added_items << new_topic
        added_items << new_topic.assignment if new_topic.assignment
        new_topic.save_without_broadcasting!
        map_merge(topic, new_topic)
      end
    end
    course.calendar_events.active.each do |event|
      course_import.tick(50) if course_import
      if bool_res(options[:everything] ) || bool_res(options[:all_calendar_events] ) || bool_res(options[event.asset_string.to_sym] )
        new_event = event.clone_for(self, nil, :migrate => false)
        to_shift_dates << new_event if new_event.clone_updated || same_dates?(event, new_event, [:start_at, :end_at])
        added_items << new_event
        new_event.save_without_broadcasting!
        map_merge(event, new_event)
      end
    end
    course.quizzes.active.each do |quiz|
      course_import.tick(60) if course_import
      if bool_res(options[:everything] ) || bool_res(options[:all_quizzes] ) || bool_res(options[quiz.asset_string.to_sym] ) || (quiz.assignment_id && bool_res(options["assignment_#{quiz.assignment_id}"]))
        new_quiz = quiz.clone_for(self)
        to_shift_dates << new_quiz if new_quiz.clone_updated || same_dates?(quiz, new_quiz, [:due_at, :lock_at, :unlock_at])
        added_items << new_quiz
        added_items << new_quiz.assignment if new_quiz.assignment
        new_quiz.save!
        map_merge(quiz, new_quiz)
      end
    end
    course.wiki_namespaces.each do |wiki_namespace|
      wiki_namespace.wiki.wiki_pages.each do |page|
        course_import.tick(70) if course_import
        if bool_res(options[:everything] ) || bool_res(options[:all_wiki_pages] ) || bool_res(options[page.asset_string.to_sym] )
          if page.title.blank?
            next if page.body.blank?
            page.title = t('#wiki_page.missing_name', "Unnamed Page")
          end
          new_page = page.clone_for(self, nil, :migrate => false, :old_context => course)
          added_items << new_page
          new_page.wiki_id = self.wiki.id
          new_page.ensure_unique_title
          log_merge_result("Wiki Page \"#{page.title}\" renamed to \"#{new_page.title}\"") if new_page.title != page.title
          new_page.save_without_broadcasting!
          map_merge(page, new_page)
        end
      end
    end
    course.context_modules.active.each do |mod|
      course_import.tick(80) if course_import
      if bool_res(options[:everything] ) || bool_res(options[:all_modules] ) || bool_res(options[mod.asset_string.to_sym] )
        new_mod = mod.clone_for(self)
        to_shift_dates << new_mod if new_mod.clone_updated || same_dates?(mod, new_mod, [:unlock_at, :start_at, :end_at])
        new_mod.save!
        added_items << new_mod
        map_merge(mod, new_mod)
      end
    end

    orig_root = LearningOutcomeGroup.default_for(course)
    new_root = LearningOutcomeGroup.default_for(self)
    orig_root.sorted_content.each do |item|
      course_import.tick(85) if course_import
      use_outcome = lambda {|lo| bool_res(options[:everything] ) || bool_res(options[:all_outcomes] ) || bool_res(options[lo.asset_string.to_sym] ) }
      if item.is_a? LearningOutcome
        next unless use_outcome[item]
        lo = item.clone_for(self, new_root)
        added_items << lo
      else
        f = item.clone_for(self, new_root, use_outcome)
        added_items << f if f
      end
    end

    # Groups could be created by objects with attached assignments as well. (like quizzes/topics)
    # So don't delete the placeholder until everything has been cloned
    delete_placeholder.destroy if delete_placeholder && self.assignment_groups.length > 1

    @to_migrate_links.uniq.each do |obj|
      course_import.tick(90) if course_import
      if obj.is_a?(Assignment)
        obj.description = migrate_content_links(obj.description, course)
      elsif obj.is_a?(CalendarEvent)
        obj.description = migrate_content_links(obj.description, course)
      elsif obj.is_a?(DiscussionTopic)
        obj.message = migrate_content_links(obj.message, course)
        obj.discussion_entries.each do |entry|
          entry.message = migrate_content_links(obj.message, course)
          entry.save_without_broadcasting!
        end
      elsif obj.is_a?(WikiPage)
        obj.body = migrate_content_links(obj.body, course)
      elsif obj.is_a?(Quiz)
        obj.description = migrate_content_links(obj.description, course)
      elsif obj.is_a?(Course)
        obj.syllabus_body = migrate_content_links(obj.syllabus_body, course)
      end
      obj.save_without_broadcasting! rescue obj.save!
    end
    if !to_shift_dates.empty? && bool_res(options[:shift_dates])
      log_merge_result("Moving events to new dates")
      shift_options = (bool_res(options[:shift_dates]) rescue false) ? options : {}
      shift_options = shift_date_options(course, shift_options)
      to_shift_dates.uniq.each do |event|
        course_import.tick(100) if course_import
        if event.is_a?(Assignment)
          event.due_at = shift_date(event.due_at, shift_options)
          event.lock_at = shift_date(event.lock_at, shift_options)
          event.unlock_at = shift_date(event.unlock_at, shift_options)
          event.peer_reviews_due_at = shift_date(event.peer_reviews_due_at, shift_options)
        elsif event.is_a?(DiscussionTopic)
          event.delayed_post_at = shift_date(event.delayed_post_at, shift_options)
          log_merge_result("The Topic \"#{event.title}\" won't be posted until #{event.delayed_post_at.to_s}")
        elsif event.is_a?(CalendarEvent)
          event.start_at = shift_date(event.start_at, shift_options)
          event.end_at = shift_date(event.end_at, shift_options)
        elsif event.is_a?(Quiz)
          event.due_at = shift_date(event.due_at, shift_options)
          event.lock_at = shift_date(event.lock_at, shift_options)
          event.unlock_at = shift_date(event.unlock_at, shift_options)
        elsif event.is_a?(ContextModule)
          event.unlock_at = shift_date(event.unlock_at, shift_options)
          event.start_at = shift_date(event.start_at, shift_options)
          event.end_at = shift_date(event.end_at, shift_options)
        end
        event.respond_to?(:save_without_broadcasting!) ? event.save_without_broadcasting! : event.save!
      end
      self.start_at ||= shift_options[:new_start_date]
      self.conclude_at ||= shift_options[:new_end_date]
    end

    self.save

    if course_import
      course_import.added_item_codes = added_items.map{|i| i.asset_string }
      course_import.log = merge_results
      course_import.save!
    end
    added_items.map{|i| i.asset_string }
  end

  def self.clonable_attributes
    [ :group_weighting_scheme, :grading_standard_id, :is_public,
      :publish_grades_immediately, :allow_student_wiki_edits,
      :allow_student_assignment_edits, :hashtag, :show_public_context_messages,
      :syllabus_body, :allow_student_forum_attachments,
      :default_wiki_editing_roles, :allow_student_organized_groups,
      :default_view, :show_all_discussion_entries, :open_enrollment,
      :storage_quota, :tab_configuration, :allow_wiki_comments,
      :turnitin_comments, :self_enrollment, :license, :indexed, :settings, :locale ]
  end

  def clone_for(account, opts={})
    new_course = Course.new
    root_account = account.root_account
    self.attributes.delete_if{|k,v| [:id, :section, :account_id, :workflow_state, :created_at, :updated_at, :root_account_id, :enrollment_term_id, :sis_source_id, :sis_batch_id].include?(k.to_sym) }.each do |key, val|
      new_course.send("#{key}=", val)
    end
    new_course.workflow_state = 'created'
    new_course.name = opts[:name] if opts[:name]
    new_course.account_id = account.id
    new_course.root_account_id = root_account.id
    new_course.enrollment_term_id = opts[:enrollment_term_id]
    new_course.abstract_course_id = self.abstract_course_id
    new_course.save!
    if opts[:copy_content]
      new_course.send_later(:merge_into_course, self, :everything => true)
    end
    new_course
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

  def shift_date_options(course, options={})
    result = {}
    result[:old_start_date] = Date.parse(options[:old_start_date]) rescue course.real_start_date
    result[:old_end_date] = Date.parse(options[:old_end_date]) rescue course.real_end_date
    result[:new_start_date] = Date.parse(options[:new_start_date]) rescue self.real_start_date
    result[:new_end_date] = Date.parse(options[:new_end_date]) rescue self.real_end_date
    result[:day_substitutions] = options[:day_substitutions]
    result
  end

  def shift_date(time, options={})
    return nil unless time
    time = ActiveSupport::TimeWithZone.new(time.utc, Time.zone)
    old_date = time.to_date
    new_date = old_date.clone
    old_start_date = options[:old_start_date]
    old_end_date = options[:old_end_date]
    new_start_date = options[:new_start_date]
    new_end_date = options[:new_end_date]
    return time unless old_start_date && old_end_date && new_start_date && new_end_date
    old_full_diff = old_end_date - old_start_date
    old_event_diff = old_date - old_start_date
    old_event_percent = old_full_diff > 0 ? old_event_diff.to_f / old_full_diff.to_f : 0
    new_full_diff = new_end_date - new_start_date
    new_event_diff = (new_full_diff.to_f * old_event_percent).to_i
    new_date = new_start_date + new_event_diff
    options[:day_substitutions] ||= {}
    options[:day_substitutions][old_date.wday.to_s] ||= old_date.wday.to_s
    if options[:day_substitutions] && options[:day_substitutions][old_date.wday.to_s]
      if new_date.wday != options[:day_substitutions][old_date.wday.to_s].to_i
        new_date += (options[:day_substitutions][old_date.wday.to_s].to_i - new_date.wday) % 7
        new_date -= 7 unless new_date - 7 < new_start_date
      end
    end

    new_time = Time.utc(new_date.year, new_date.month, new_date.day, (time.hour rescue 0), (time.min rescue 0)).in_time_zone
    new_time -= new_time.utc_offset
    log_merge_result("Events for #{old_date.to_s} moved to #{new_date.to_s}")
    new_time
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


  def page_views_by_day(options={})
    conditions = {
      :context_id => self.id,
      :context_type => self.class.to_s
    }
    if options[:dates]
      conditions.merge!({
        :created_at => (options[:dates].first)..(options[:dates].last)
      })
    end
    PageView.count(
      :group => "date(created_at)",
      :conditions => conditions
    )
  end
  memoize :page_views_by_day

  def section_visibilities_for(user)
    Rails.cache.fetch(['section_visibilities_for', user, self].cache_key) do
      Enrollment.find(:all, :select => "course_section_id, limit_privileges_to_course_section, type, associated_user_id", :conditions => ['user_id = ? AND course_id = ? AND workflow_state != ?', user.id, self.id, 'deleted']).map{|e| {:course_section_id => e.course_section_id, :limit_privileges_to_course_section => e.limit_privileges_to_course_section, :type => e.type, :associated_user_id => e.associated_user_id, :admin => e.admin?} }
    end
  end
  memoize :section_visibilities_for

  def visibility_limited_to_course_sections?(user, visibilities = section_visibilities_for(user))
    !visibilities.any?{|s| !s[:limit_privileges_to_course_section] }
  end

  # returns a scope, not an array of users/enrollments
  def students_visible_to(user, include_priors=false)
    enrollments_visible_to(user, include_priors, true)
  end
  def enrollments_visible_to(user, include_priors=false, return_users=false, limit_to_section_ids=nil)
    visibilities = section_visibilities_for(user)
    if return_users
      scope = include_priors ? self.all_students : self.students
    else
      scope = include_priors ? self.all_student_enrollments : self.student_enrollments
    end
    if limit_to_section_ids
      scope = scope.scoped(:conditions => { 'enrollments.course_section_id' => limit_to_section_ids.to_a })
    end
    unless visibilities.any?{|v|v[:admin]}
      scope = scope.scoped(:conditions => "enrollments.type != 'StudentViewEnrollment'")
    end
    # See also Users#messageable_users (same logic used to get users across multiple courses)
    case enrollment_visibility_level_for(user, visibilities)
      when :full then scope
      when :sections then scope.scoped({:conditions => "enrollments.course_section_id IN (#{visibilities.map{|s| s[:course_section_id]}.join(",")})"})
      when :restricted then scope.scoped({:conditions => "enrollments.user_id IN (#{(visibilities.map{|s| s[:associated_user_id]}.compact + [user.id]).join(",")})"})
      else scope.scoped({:conditions => "FALSE"})
    end
  end

  def sections_visible_to(user, sections = active_course_sections)
    visibilities = section_visibilities_for(user)
    section_ids = visibilities.map{ |s| s[:course_section_id] }
    case enrollment_visibility_level_for(user, visibilities)
      when :full
        if visibilities.all?{ |v| ['StudentEnrollment', 'StudentViewEnrollment', 'ObserverEnrollment'].include? v[:type] }
          return sections.find_all_by_id(section_ids)
        else
          return sections
        end
      when :sections
        return sections.find_all_by_id(section_ids)
    end
    []
  end

  def enrollment_visibility_level_for(user, visibilities = section_visibilities_for(user))
    if visibilities.empty? # i.e. not enrolled
      if self.grants_rights?(user, nil, :manage_grades, :manage_students, :manage_admin_users, :read_roster)
        :full
      else
        :none
      end
    elsif visibilities.all?{ |e| e[:type] == 'ObserverEnrollment' }
      :restricted # e.g. observers shouldn't see anyone but the observed
    elsif visibility_limited_to_course_sections?(user, visibilities)
      :sections
    else
      :full
    end
  end

  def page_view_data(options={})
    # if they dont supply a date range then use the first day returned by page_views_by_day (which should be the first day that there is pageview statistics gathered)
    dates = options[:dates].nil? ? [page_views_by_day.sort.first.first.to_datetime, Time.now] : options[:dates]
    days = []
    dates.first.to_datetime.upto(dates.last) do |d|
      # this * 1000 part is because the Highcharts expects something like what Date.UTC(2006, 2, 28) would give you,
      # which is MILLISECONDS from the unix epoch, ruby's to_f gives you SECONDS since then.
      days << [ (d.at_beginning_of_day.to_f * 1000).to_i , page_views_by_day[d.to_date.to_s].to_i ]
    end
    days
  end
  memoize :page_view_data

  def unpublished?
    self.created? || self.claimed?
  end

  def only_wiki_is_public
    self.respond_to?(:wiki_is_public) && self.wiki_is_public && !self.is_public
  end

  def reply_from(opts)
    user = opts[:user]
    message = opts[:text].strip
    user = nil unless user && self.context.users.include?(user)
    if !user
      raise "Only comment participants may reply to messages"
    elsif !message || message.empty?
      raise "Message body cannot be blank"
    else
      recipients = self.teachers.map(&:id) - [user.id]
      conversation = user.initiate_conversation(recipients)
      conversation.add_message(message, :root_account_id => root_account_id)
    end
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
  TAB_CHAT = 9
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
      { :id => TAB_CHAT, :label => t('#tabs.chat', "Chat"), :css_class => 'chat', :href => :course_chat_path },
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
        :visibility => tool.settings[:course_navigation][:visibility],
        :external => true,
        :hidden => tool.settings[:course_navigation][:default] == 'disabled',
        :args => [self.id, tool.id]
     }
    end
  end

  def tabs_available(user=nil, opts={})
    # We will by default show everything in default_tabs, unless the teacher has configured otherwise.
    tabs = self.tab_configuration.compact
    default_tabs = Course.default_tabs
    settings_tab = default_tabs[-1]
    external_tabs = external_tool_tabs(opts)
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
        tabs.delete_if { |t| t[:id] == TAB_SYLLABUS }
        tabs.delete_if { |t| t[:id] == TAB_QUIZZES }
      end
      tabs.delete_if{ |t| t[:visibility] == 'admins' } unless self.grants_right?(user, opts[:session], :manage_content)
      if self.grants_rights?(user, opts[:session], :manage_content, :manage_assignments).values.any?
        tabs.detect { |t| t[:id] == TAB_ASSIGNMENTS }[:manageable] = true
        tabs.detect { |t| t[:id] == TAB_SYLLABUS }[:manageable] = true
        tabs.detect { |t| t[:id] == TAB_QUIZZES }[:manageable] = true
      end
      tabs.delete_if { |t| t[:hidden] && t[:external] }
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
        if self.grants_right?(user, nil, :read_as_admin)
          tabs.delete_if {|t| [TAB_CHAT].include?(t[:id]) }
        elsif !self.grants_right?(user, nil, :participate_as_student)
          tabs.delete_if {|t| [TAB_PEOPLE, TAB_CHAT].include?(t[:id]) }
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
  memoize :tabs_available

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

    CourseSection.find(:all, :conditions=>"course_id = #{self.id}").each do |cs|
      cs.update_attribute(:root_account_id, new_root_account.id)
    end

    Enrollment.find(:all, :conditions=>"course_id = #{self.id}").each do |e|
      e.update_attribute(:root_account_id, new_root_account.id)
      user_ids << e.user_id
    end

    self.save
    User.update_account_associations(user_ids)
  end


  cattr_accessor :settings_options
  self.settings_options = {}

  def self.add_setting(setting, opts=nil)
    self.settings_options[setting.to_sym] = opts || {}
  end

  # these settings either are or could be easily added to
  # the course settings page
  add_setting :hide_final_grade, :boolean => true

  def settings=(hash)

    if hash.is_a?(Hash)
      hash.each do |key, val|
        if settings_options[key.to_sym]
          opts = settings_options[key.to_sym]
          if opts[:boolean]
            settings[key.to_sym] = (val == true || val == 'true' || val == '1' || val == 'on')
          elsif opts[:hash]
            new_hash = {}
            if val.is_a?(Hash)
              val.each do |inner_key, inner_val|
                if opts[:values].include?(inner_key.to_sym)
                  new_hash[inner_key.to_sym] = inner_val.to_s
                end
              end
            end
            settings[key.to_sym] = new_hash.empty? ? nil : new_hash
          else
            settings[key.to_sym] = val.to_s
          end
        end
      end
    end
    settings
  end

  def settings
    result = self.read_attribute(:settings)
    return result if result
    return self.write_attribute(:settings, {}) unless frozen?
    {}.freeze
  end

  def reset_content
    Course.transaction do
      new_course = Course.new
      self.attributes.delete_if{|k,v| [:id, :created_at, :updated_at, :syllabus_body, :wiki_id, :default_view, :tab_configuration].include?(k.to_sym) }.each do |key, val|
        new_course.write_attribute(key, val)
      end
      # The order here is important; we have to set our sis id to nil and save first
      # so that the new course can be saved, then we need the new course saved to
      # get its id to move over sections and enrollments.  Setting this course to
      # deleted has to be last otherwise it would set all the enrollments to
      # deleted before they got moved
      self.uuid = self.sis_source_id = self.sis_batch_id = nil;
      self.save!
      Course.process_as_sis { new_course.save! }
      self.course_sections.update_all(:course_id => new_course.id)
      # we also want to bring along prior enrollments, so don't use the enrollments
      # association
      case Enrollment.connection.adapter_name
      when 'MySQL'
        Enrollment.connection.execute("UPDATE users, enrollments SET users.updated_at=#{Course.sanitize(Time.now.utc)}, enrollments.updated_at=#{Course.sanitize(Time.now.utc)}, enrollments.course_id=#{new_course.id} WHERE users.id=enrollments.user_id AND enrollments.course_id=#{self.id}")
      else
        Enrollment.update_all({:course_id => new_course.id, :updated_at => Time.now.utc}, :course_id => self.id)
        User.update_all({:updated_at => Time.now.utc}, "id IN (SELECT user_id FROM enrollments WHERE course_id=#{new_course.id})")
      end
      self.replacement_course_id = new_course.id
      self.workflow_state = 'deleted'
      self.save!
      Course.find(new_course.id)
    end
  end

  def has_open_course_imports?
    self.course_imports.scoped(:conditions => {
      :workflow_state => ['created', 'started']
    }).count > 0
  end

  def user_list_search_mode_for(user)
    if self.root_account.open_registration?
      return self.root_account.delegated_authentication? ? :preferred : :open
    end
    return :preferred if self.root_account.grants_right?(user, :manage_user_logins)
    :closed
  end

  def participating_users(user_ids)
    enrollments = self.enrollments.scoped(
      :include => :user,
      :conditions => ["enrollments.workflow_state = 'active' AND users.id IN (?)",
                      user_ids]
    )
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
    self.course_sections.active.each do |section|
      # enroll fake_student will only create the enrollment if it doesn't already exist
      self.enroll_user(fake_student, 'StudentViewEnrollment', 
                       :allow_multiple_enrollments => true, 
                       :section => section,
                       :enrollment_state => 'active', 
                       :no_notify => true, 
                       :skip_touch_user => true)
    end
    fake_student
  end
  private :sync_enrollments
end
