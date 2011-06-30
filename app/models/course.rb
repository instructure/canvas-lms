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

class Course < ActiveRecord::Base
  
  adheres_to_policy
  
  include Context
  include Workflow
  include EnrollmentDateRestrictions

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
                  :hidden_tabs,
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
                  :grading_standard_enabled

  serialize :tab_configuration
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
  has_many :students, :through => :student_enrollments, :source => :user, :order => :sortable_name
  has_many :all_students, :through => :all_student_enrollments, :source => :user, :order => :sortable_name
  has_many :participating_students, :through => :enrollments, :source => :user, :conditions => "enrollments.type = 'StudentEnrollment' and enrollments.workflow_state = 'active'"
  has_many :student_enrollments, :class_name => 'StudentEnrollment', :conditions => ['enrollments.workflow_state != ? AND enrollments.workflow_state != ? AND enrollments.workflow_state != ? AND enrollments.workflow_state != ?', 'deleted', 'completed', 'rejected', 'inactive'], :include => :user #, :conditions => "type = 'StudentEnrollment'"
  has_many :all_student_enrollments, :class_name => 'StudentEnrollment', :conditions => ['enrollments.workflow_state != ?', 'deleted'], :include => :user
  has_many :detailed_enrollments, :class_name => 'Enrollment', :conditions => ['enrollments.workflow_state != ?', 'deleted'], :include => {:user => {:pseudonym => :communication_channel}}
  has_many :teachers, :through => :teacher_enrollments, :source => :user
  has_many :teacher_enrollments, :class_name => 'TeacherEnrollment', :conditions => ['enrollments.workflow_state != ?', 'deleted'], :include => :user
  has_many :tas, :through => :ta_enrollments, :source => :user
  has_many :ta_enrollments, :class_name => 'TaEnrollment', :conditions => ['enrollments.workflow_state != ?', 'deleted'], :include => :user
  has_many :designers, :through => :designer_enrollments, :source => :user
  has_many :designer_enrollments, :class_name => 'DesignerEnrollment', :conditions => ['enrollments.workflow_state != ?', 'deleted'], :include => :user
  has_many :observers, :through => :observer_enrollments, :source => :user
  has_many :observer_enrollments, :class_name => 'ObserverEnrollment', :conditions => ['enrollments.workflow_state != ?', 'deleted'], :include => :user
  has_many :admins, :through => :enrollments, :source => :user, :conditions => "enrollments.type = 'TaEnrollment' or enrollments.type = 'TeacherEnrollment'"
  has_many :participating_admins, :through => :enrollments, :source => :user, :conditions => "(enrollments.type = 'TaEnrollment' or enrollments.type = 'TeacherEnrollment') and enrollments.workflow_state = 'active'"
  
  has_many :learning_outcomes, :through => :learning_outcome_tags, :source => :learning_outcome_content
  has_many :learning_outcome_tags, :as => :context, :class_name => 'ContentTag', :conditions => ['content_tags.tag_type = ? AND content_tags.workflow_state != ?', 'learning_outcome_association', 'deleted']
  has_many :created_learning_outcomes, :class_name => 'LearningOutcome', :as => :context
  has_many :learning_outcome_groups, :as => :context
  has_many :course_account_associations
  has_many :non_unique_associated_accounts, :source => :account, :through => :course_account_associations, :order => 'course_account_associations.depth'
  has_many :users, :through => :enrollments, :source => :user
  has_many :groups, :as => :context
  has_many :active_groups, :as => :context, :class_name => 'Group', :conditions => ['groups.workflow_state != ?', 'deleted']
  has_many :assignment_groups, :as => :context, :dependent => :destroy, :order => 'assignment_groups.position, assignment_groups.name'
  has_many :assignments, :as => :context, :dependent => :destroy, :order => 'assignments.created_at'
  has_many :calendar_events, :as => :context, :conditions => ['calendar_events.workflow_state != ?', 'cancelled'], :dependent => :destroy
  has_many :submissions, :through => :assignments, :order => 'submissions.updated_at DESC', :include => :quiz_submission, :dependent => :destroy
  has_many :discussion_topics, :as => :context, :conditions => ['discussion_topics.workflow_state != ?', 'deleted'], :include => :user, :dependent => :destroy, :order => 'discussion_topics.position DESC, discussion_topics.created_at DESC'
  has_many :active_discussion_topics, :as => :context, :class_name => 'DiscussionTopic', :conditions => ['discussion_topics.workflow_state != ?', 'deleted'], :include => :user
  has_many :all_discussion_topics, :as => :context, :class_name => "DiscussionTopic", :include => :user, :dependent => :destroy
  has_many :discussion_entries, :through => :discussion_topics, :include => [:discussion_topic, :user], :dependent => :destroy
  has_many :announcements, :as => :context, :class_name => 'Announcement', :dependent => :destroy
  has_many :active_announcements, :as => :context, :class_name => 'Announcement', :conditions => ['discussion_topics.workflow_state != ?', 'deleted'], :order => 'created_at DESC'
  has_many :attachments, :as => :context, :dependent => :destroy
  has_many :active_attachments, :as => :context, :class_name => 'Attachment', :conditions => ['attachments.file_state != ?', 'deleted'], :order => 'attachments.display_name'
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
  has_many :assessment_questions, :as => :context
  has_many :assessment_question_banks, :as => :context, :include => [:assessment_questions, :assessment_question_bank_users]
  has_many :external_feeds, :as => :context, :dependent => :destroy
  belongs_to :default_grading_standard, :class_name => 'GradingStandard', :foreign_key => 'grading_standard_id'
  has_many :grading_standards, :as => :context
  has_one :gradebook_upload, :as => :context, :dependent => :destroy
  has_many :web_conferences, :as => :context, :order => 'created_at DESC', :dependent => :destroy
  has_many :rubrics, :as => :context
  has_many :rubric_associations, :as => :context, :include => :rubric, :dependent => :destroy
  has_many :tags, :class_name => 'ContentTag', :as => 'context', :order => 'LOWER(title)', :conditions => {:tag_type => 'default'}, :dependent => :destroy
  has_many :collaborations, :as => :context, :order => 'title, created_at', :dependent => :destroy
  has_one :scribd_account, :as => :scribdable
  has_many :short_message_associations, :as => :context, :include => :short_message, :dependent => :destroy
  has_many :short_messages, :through => :short_message_associations, :dependent => :destroy
  has_many :grading_standards, :as => :context
  has_many :context_messages, :as => :context, :dependent => :destroy
  has_many :context_modules, :as => :context, :order => :position, :dependent => :destroy
  has_many :active_context_modules, :as => :context, :class_name => 'ContextModule', :conditions => {:workflow_state => 'active'}
  has_many :context_module_tags, :class_name => 'ContentTag', :as => 'context', :order => :position, :conditions => ['tag_type = ?', 'context_module'], :dependent => :destroy
  has_many :media_objects, :as => :context
  has_many :page_views, :as => :context
  has_many :role_overrides, :as => :context
  has_many :content_exports
  attr_accessor :import_source
  
  before_save :assign_uuid
  before_save :assert_defaults
  before_save :set_update_account_associations_if_changed
  before_save :update_enrollments_later
  after_save :update_final_scores_on_weighting_scheme_change
  after_save :update_account_associations_if_changed
  before_validation :verify_unique_sis_source_id
  validates_length_of :syllabus_body, :maximum => maximum_long_text_length, :allow_nil => true, :allow_blank => true
  
  sanitize_field :syllabus_body, Instructure::SanitizeField::SANITIZE
  
  has_a_broadcast_policy
  
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
    true
  end
  
  def update_account_associations_if_changed
    send_later_if_production(:update_account_associations) if @should_update_account_associations && !self.class.skip_updating_account_associations?
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

  def self.update_account_associations(course_ids)
    Course.find_all_by_id(course_ids).compact.each do |course|
      course.update_account_associations
    end
  end
  
  def has_outcomes
    Rails.cache.fetch(['has_outcomes', self].cache_key) do
      self.learning_outcome_tags.count > 0
    end
  end
  
  def update_account_associations(update_user_account_associations = true)
    # Look up the current associations, and remove any duplicates.
    associations_hash = {}
    to_delete = {}
    self.course_account_associations.each do |association|
      key = [association.account_id, association.course_section_id]
      if !associations_hash[key]
        associations_hash[key] = association
        to_delete[key] = association
      else
        association.destroy
      end
    end
    
    did_an_update = false
    
    # Courses are tied to accounts directly and through sections and crosslisted courses
    all_sections = self.course_sections.active.find(:all)
    initial_entities = ([self] + all_sections + all_sections.map(&:nonxlist_course)).compact.uniq
    Course.skip_updating_account_associations do
      initial_entities.each do |entity|
        accounts = entity.account ? entity.account.account_chain : []
        section = (entity.is_a?(Course) ? entity.default_section : entity)
        accounts.each_with_index do |account, idx|
          key = [account.id, section.id]
          if associations_hash[key]
            unless associations_hash[key].depth == idx
              associations_hash[key].update_attributes(:depth => idx)
              did_an_update = true
            end
            to_delete.delete(key)
          else
            associations_hash[key] = self.course_account_associations.create(:account => account, :depth => idx, :course_section => section)
            did_an_update = true
          end
        end
      end
    end
    to_delete.each_value {|association| association.destroy; did_an_update = true }
    
    if did_an_update && update_user_account_associations
      self.users.each {|u| u.update_account_associations }
    end
    
    true
  end
  
  def associated_accounts
    self.non_unique_associated_accounts.uniq
  end
  
  # objects returned from this query will give you an additional attribute "page_views_count" that you can use, so:
  # Account.first.courses.most_active(10).first.page_views_count  #=> "466" 
  named_scope :most_active, lambda { |limit|
    {
      :select => "courses.*, (SELECT COUNT(*) FROM page_views WHERE context_id = courses.id AND context_type = 'Course') AS page_views_count",
      :order => "page_views_count DESC",
      :limit => limit
    }
  }
  named_scope :recently_started, lambda {
    {:conditions => ['start_at < ? and start_at > ?', Time.now, 1.month.ago], :order => 'start_at DESC', :limit => 10}
  }
  named_scope :recently_ended, lambda {
    {:conditions => ['conclude_at < ? and conclude_at > ?', Time.now, 1.month.ago], :order => 'start_at DESC', :limit => 10}
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
  named_scope :manageable_by_user, lambda{|user_id|
    { :select => 'DISTINCT courses.*',
      :joins => "INNER JOIN (
         SELECT caa.course_id, au.user_id FROM course_account_associations AS caa
         INNER JOIN accounts AS a ON a.id = caa.account_id AND a.workflow_state = 'active'
         INNER JOIN account_users AS au ON au.account_id = a.id AND au.user_id = #{user_id.to_i}
       UNION SELECT courses.id AS course_id, e.user_id FROM courses
         INNER JOIN enrollments AS e ON e.course_id = courses.id AND e.user_id = #{user_id.to_i}
           AND e.workflow_state = 'active' AND e.type IN ('TeacherEnrollment', 'TaEnrollment')
         WHERE courses.workflow_state NOT IN ('aborted', 'deleted')) as course_users
       ON course_users.course_id = courses.id"
    }
  }
  named_scope :not_deleted, {:conditions => ['workflow_state != ?', 'deleted']}

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
  
  def paginate_users_not_in_groups(groups, page, per_page = 15)
    User.paginate_by_sql(["SELECT u.id, u.name
                             FROM users u
                            INNER JOIN enrollments e ON e.user_id = u.id
                            WHERE e.course_id = ? AND e.workflow_state NOT IN ('rejected', 'completed', 'deleted') AND e.type = 'StudentEnrollment'
                                  #{"AND NOT EXISTS (SELECT *
                                                       FROM group_memberships gm
                                                      WHERE gm.user_id = u.id AND
                                                            gm.group_id IN (#{groups.map(&:id).join ','}))" unless groups.empty?}
                            ORDER BY u.sortable_name ASC", self.id], :page => page, :per_page => per_page)
  end
  
  def admins_in_charge_of(user_id)
    section_ids = current_enrollments.find(:all, :select => 'course_section_id, course_id, user_id, limit_priveleges_to_course_section', :conditions => {:course_id => self.id, :user_id => user_id}).map(&:course_section_id).compact.uniq
    if section_ids.empty?
      participating_admins
    else
      participating_admins.for_course_section(section_ids)
    end
  end
  
  def user_is_teacher?(user)
    return unless user
    cache_key = [self, user, "course_user_is_teacher"].cache_key
    res = Rails.cache.read(cache_key)
    if res.nil?
      res = user.cached_current_enrollments.any? { |e| e.course_id == self.id && e.participating_admin? }
      Rails.cache.write(cache_key, res)
    end
    res
  end
  memoize :user_is_teacher?
  
  def user_is_student?(user)
    return unless user
    cache_key = [self, user, "course_user_is_student"].cache_key
    res = Rails.cache.read(cache_key)
    if res.nil?
      res = !self.student_enrollments.find_by_user_id(user.id).nil?
      Rails.cache.write(cache_key, res)
    end
    res
  end
  memoize :user_is_student?
  
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
    self.enrollment_term
    self.enrollment_term = nil if self.enrollment_term && self.enrollment_term.root_account_id != self.root_account_id
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
        attr_hash = {:updated_at => Time.now}
        fields_to_possibly_rename.each { |key| attr_hash[key] = section.send(key) }
        CourseSection.update_all(attr_hash, {:id => section.id})
      end
    end
  end
  
  def update_enrollments_later
    send_later(:update_enrolled_users) if !self.new_record? && !(self.changes.keys & ['workflow_state', 'name', 'course_code']).empty?
    true
  end
  
  def update_enrolled_users
    if self.completed?
      enrollments = self.enrollments.scoped(:select => "id, user_id, course_id", :conditions=>"workflow_state IN ('active', 'invited')")
      Enrollment.update_all({:workflow_state => 'completed'}, {:id => enrollments.map(&:id)})
    elsif self.deleted?
      enrollments = self.enrollments.scoped(:select => "id, user_id, course_id", :conditions=>"workflow_state != 'deleted'")
      Enrollment.update_all({:workflow_state => 'deleted'}, {:id => enrollments.map(&:id)})
    end
    enrollments = self.enrollments.scoped(:select => "id, user_id, course_id")
    Enrollment.update_all({:updated_at => Time.now}, {:id => enrollments.map(&:id)})
    User.update_all({:updated_at => Time.now}, {:id => enrollments.map(&:user_id)})
  end
  
  def self_enrollment_allowed?
    !!(self.account && self.account.self_enrollment_allowed?(self))
  end
  
  def self_enrollment_code
    Digest::MD5.hexdigest("#{uuid}_for_#{id}")
  end
  memoize :self_enrollment_code
  
  def update_final_scores_on_weighting_scheme_change
    if @group_weighting_scheme_changed
      Enrollment.send_later_if_production(:recompute_final_score, self.students.map(&:id), self.id)
    end
  end
  
  def recompute_student_scores
    Enrollment.send_later_if_production(:recompute_final_score, self.students.map(&:id), self.id)
  end
  
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
      event :abort_it, :transitions_to => :aborted
      event :complete, :transitions_to => :completed
    end
    
    state :claimed do
      event :offer, :transitions_to => :available
      event :abort_it, :transitions_to => :aborted
      event :complete, :transitions_to => :completed
    end
    
    state :available do
      event :abort_it, :transitions_to => :aborted
      event :complete, :transitions_to => :completed
    end

    state :aborted
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
      return read_attribute(:storage_quota) ||
        (self.account.default_storage_quota rescue nil) ||
        Setting.get_cached('course_default_quota', 500.megabytes.to_s).to_i
    end
  end
  
  def storage_quota_mb
    storage_quota < 1.megabyte ? storage_quota : storage_quota / 1.megabyte
  end
  
  def storage_quota_mb=(val)
    # TODO: convert MB to bytes once this commit has been deployed
    self.storage_quota = val
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
    # There are two types of read permissions for a course.  If a course is public,
    # then visitors can "read" content in the site, but shouldn't be able to see
    # confidential information, and shouldn't be taken to things like the dashboard view.
    # "read_full" implies access to the dashboard and course roster.
    given { |user| self.available? && self.is_public }
    set { can :read }
    
    RoleOverride.permissions.each do |permission, params|
      given {|user, session| self.enrollment_allows(user, session, permission) || self.account_membership_allows(user, session, permission) }
      set { can permission }
    end
    
    given { |user, session| session && session[:enrollment_uuid] && (hash = Enrollment.course_user_state(self, session[:enrollment_uuid]) || {}) && hash[:enrollment_state] == "invited" }
    set { can :read }
    
    given { |user, session| session && session[:enrollment_uuid] && (hash = Enrollment.course_user_state(self, session[:enrollment_uuid]) || {}) && hash[:enrollment_state] == "active" && hash[:user_state] == "pre_registered" }
    set { can :read }
    
    given { |user| self.available? && user && user.cached_current_enrollments.any?{|e| e.course_id == self.id && !e.rejected? && !e.deleted? } }
    set { can :read }
    
    given { |user| self.available? && user &&  user.cached_current_enrollments.any?{|e| e.course_id == self.id && e.participating_student? } }
    set { can :read and can :participate_as_student and can :read_grades and can :read_groups }

    given { |user| self.completed? && user && user.cached_current_enrollments.any?{|e| e.course_id == self.id && e.participating_student? } }
    set { can :read and can :read_groups }
    
    given { |user| (self.available? || self.completed?) && user &&  user.cached_not_ended_enrollments.any?{|e| e.course_id == self.id && e.participating_observer? } }
    set { can :read }
    
    given { |user| (self.available? || self.completed?) && user && user.cached_not_ended_enrollments.any?{|e| e.course_id == self.id && e.participating_observer? && e.associated_user_id} }
    set { can :read_grades }
     
    given { |user, session| self.available? && self.teacherless? && user && user.cached_not_ended_enrollments.any?{|e| e.course_id == self.id && e.participating_student? } && (!session || !session["role_course_#{self.id}"]) }
    set { can :update and can :delete and RoleOverride.teacherless_permissions.each{|p| can p } }
    
    given { |user, session| (self.available? || self.created? || self.claimed? || self.completed?) && user && user.cached_not_ended_enrollments.any?{|e| e.course_id == self.id && e.participating_admin? } && (!session || !session["role_course_#{self.id}"]) }
    set { can :read and can :manage and can :manage_content and can :impersonate_as_context_member and can :update and can :delete and can :read_reports and can :read_groups and can :create_user_notes and can :read_user_notes and can :delete_user_notes }
    
    given { |user| !self.deleted? && self.prior_enrollments.map(&:user_id).include?(user && user.id) }
    set { can :read}
    
    given { |user| !self.deleted? && self.prior_enrollments.select{|e| e.admin? }.map(&:user_id).include?(user && user.id) }
    set { can :read_as_admin and can :read_user_notes and can :read_roster }
    
    given { |user| !self.deleted? && self.prior_enrollments.select{|e| e.student? || e.assigned_observer? }.map(&:user_id).include?(user && user.id) }
    set { can :read and can :read_grades}
    
    given { |user, session| session && session["role_course_#{self.id}"] }
    set { can :read }
    
    given { |user, session| user && account.grants_right?(user, session, :manage) && (!session || !session["role_course_#{self.id}"]) rescue false }
    set { can :update and can :manage and can :manage_content and can :impersonate_as_context_member and can :delete and can :create and can :read and can :read_groups }
  end
  
  def enrollment_allows(user, session, permission)
    return false unless user && permission

    @enrollment_lookup ||= {}
    @enrollment_lookup[user.id] ||=
      if session && temp_type = session["role_course_#{self.id}"]
        [Enrollment.typed_enrollment(temp_type).new(:course_id => self.id, :user_id => user.id, :workflow_state => 'active')] rescue nil
      else
        self.enrollments.active_or_pending.for_user(user)
      end

    @enrollment_lookup[user.id].any? {|e| e.has_permission_to?(permission) }
  end
  
  def self.find_all_by_context_code(codes)
    ids = codes.map{|c| c.match(/\Acourse_(\d+)\z/)[1] rescue nil }.compact
    Course.find(:all, :conditions => {:id => ids}, :include => :current_enrollments)
  end
  
  def enrollment_dates_for(enrollment)
    if enrollment.start_at && enrollment.end_at
      [enrollment.start_at, enrollment.end_at]
    elsif (section = enrollment.course_section_id && course_sections.find_by_id(enrollment.course_section_id)) && 
          section && section.restrict_enrollments_to_section_dates && !enrollment.admin?
      [section.start_at, section.end_at]
    elsif self.restrict_enrollments_to_course_dates && !enrollment.admin?
      [start_at, end_at]
    elsif enrollment_term
      enrollment_term.enrollment_dates_for(enrollment)
    else
      [nil, nil]
    end
  end
  
  def enrollment_state_based_on_date(enrollment)
    start_at, end_at = enrollment_dates_for(enrollment)
    if start_at && start_at >= Time.now
      'inactive'
    elsif end_at && end_at <= Time.now
      'completed'
    else
      'active'
    end
  end
  
  def end_at
    conclude_at
  end
  
  def end_at_changed?
    conclude_at_changed?
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
  
  def institution_name
    return self.root_account.name if self.root_account_id != Account.default.id
    return (self.account || self.root_account).name
  end
  memoize :institution_name
  
  def account_membership_allows(user, session, permission)
    return false unless user && permission && AccountUser.any_for?(user) #.for_user(user).length > 0
    return false if session && session["role_course_#{self.id}"]
    @membership_allows ||= {}
    @membership_allows[[user.id, permission]] ||= (self.associated_accounts + [Account.site_admin]).uniq.any?{|a| a.membership_allows(user, permission) }
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

  def grade_publishing_status
    statuses = {}
    success_deadline = PluginSetting.settings_for_plugin('grade_export')[:success_timeout].to_i.seconds.ago.to_s(:db)
    student_enrollments.find(:all, :select => "DISTINCT grade_publishing_status, 0 AS user_id").each do |enrollment|
        status = enrollment.grade_publishing_status
        status ||= "unpublished"
        statuses[status] = true
    end
    return "unpublished" unless statuses.size > 0
    # to fake a course-level grade publishing status, we look at all possible
    # enrollments, and return statuses if we find any, in this order.
    ["error", "unpublished", "pending", "publishing", "published", "unpublishable"].each do |status|
      return status if statuses.has_key?(status)
    end
    return "error"
  end

  def publish_final_grades(publishing_user)
    # we want to set all the publishing statuses to 'pending' immediately,
    # and then as a delayed job, actually go publish them.

    settings = PluginSetting.settings_for_plugin('grade_export')
    raise "final grade publishing disabled" unless settings[:enabled] == "true"
    raise "endpoint undefined" if settings[:publish_endpoint].nil? || settings[:publish_endpoint].empty?

    last_publish_attempt_at = Time.now.utc
    self.student_enrollments.update_all :grade_publishing_status => "pending",
                                        :last_publish_attempt_at => last_publish_attempt_at

    send_later_if_production(:send_final_grades_to_endpoint, publishing_user)
    send_at(last_publish_attempt_at + settings[:success_timeout].to_i.seconds, :expire_pending_grade_publishing_statuses, last_publish_attempt_at) if settings[:success_timeout].present? && settings[:wait_for_success] && Rails.env.production?
  end

  def self.valid_grade_export_types
    @valid_grade_export_types ||= {
        "instructure_csv" => {
            :name => t('grade_export_types.instructure_csv', "Instructure formatted CSV"),
            :callback => lambda { |course, enrollments, publishing_pseudonym|
                course.generate_grade_publishing_csv_output(enrollments, publishing_pseudonym)
            }
          }
      }
  end

  def send_final_grades_to_endpoint(publishing_user)
    # actual grade publishing logic is here, but you probably want
    # 'publish_final_grades'

    enrollments = self.student_enrollments.scoped({:include => [:user, :course_section]}).find(:all, :order => "users.sortable_name")

    begin

      settings = PluginSetting.settings_for_plugin('grade_export')
      raise "final grade publishing disabled" unless settings[:enabled] == "true"
      raise "endpoint undefined" if settings[:publish_endpoint].blank?

      publishing_pseudonym = publishing_user.pseudonyms.active.find_by_account_id(self.root_account_id, :order => "sis_user_id DESC")

      errors = []
      posts_to_make = []
      ignored_enrollment_ids = []

      if Course.valid_grade_export_types.has_key?(settings[:format_type])
        callback = Course.valid_grade_export_types[settings[:format_type]][:callback]
        posts_to_make, ignored_enrollment_ids = callback.call(self, enrollments,
            publishing_pseudonym)
      end

    rescue
      Enrollment.update_all({ :grade_publishing_status => "error" }, { :id => enrollments.map(&:id) })
      raise
    end

    Enrollment.update_all({ :grade_publishing_status => "unpublishable" }, { :id => ignored_enrollment_ids })

    posts_to_make.each do |enrollment_ids, res, mime_type|
      begin
        SSLCommon.post_data(settings[:publish_endpoint], res, mime_type)
        Enrollment.update_all({ :grade_publishing_status => (settings[:wait_for_success] == "yes" ? "publishing" : "published") }, { :id => enrollment_ids })
      rescue => e
        errors << e
        Enrollment.update_all({ :grade_publishing_status => "error" }, { :id => enrollment_ids })
      end
    end

    raise errors[0] if errors.size > 0
  end
  
  def generate_grade_publishing_csv_output(enrollments, publishing_pseudonym)
    enrollment_ids = []
    res = FasterCSV.generate do |csv|
      csv << ["publisher_id", "publisher_sis_id", "section_id", "section_sis_id", "student_id", "student_sis_id", "enrollment_id", "enrollment_status", "grade", "score"]
      enrollments.each do |enrollment|
        enrollment_ids << enrollment.id
        next unless enrollment.computed_final_score
        enrollment.user.pseudonyms.active.find_all_by_account_id(self.root_account_id).each do |user_pseudonym|
          csv << [publishing_pseudonym.try(:id), publishing_pseudonym.try(:sis_user_id), enrollment.course_section.id, enrollment.course_section.sis_source_id, user_pseudonym.id, user_pseudonym.sis_user_id, enrollment.id, enrollment.workflow_state, enrollment.computed_final_grade, enrollment.computed_final_score]
        end
      end
    end
    return [[enrollment_ids, res, "text/csv"]], []
  end

  def expire_pending_grade_publishing_statuses(last_publish_attempt_at)
    self.student_enrollments.scoped(:conditions => ["grade_publishing_status IN ('pending', 'publishing') AND last_publish_attempt_at = ?",
      last_publish_attempt_at]).update_all :grade_publishing_status => 'error'
  end

  def gradebook_to_csv(options = {})
    assignments = self.assignments.active.gradeable
    assignments = [assignments.find(options[:assignment_id])] if options[:assignment_id]
    single = assignments.length == 1
    student_enrollments = self.student_enrollments.scoped({:include => [:user, :course_section]}).find(:all, :order => "users.sortable_name")
    submissions = self.submissions.inject({}) { |h, sub|
      h[[sub.user_id, sub.assignment_id]] = sub; h
    }
    read_only = t('csv.read_only_field', '(read only)')
    t 'csv.student', 'Student'
    t 'csv.id', 'ID'
    t 'csv.section', 'Section'
    t 'csv.comments', 'Comments'
    t 'csv.current_score', 'Current Score'
    t 'csv.final_score', 'Final Score'
    t 'csv.final_grade', 'Final Grade'
    t 'csv.points_possible', 'Points Possible'
    res = FasterCSV.generate do |csv|
      #First row
      row = ["Student", "ID", "Section"]
      row.concat(assignments.map{|a| single ? [a.title_with_id, 'Comments'] : a.title_with_id})
      row.concat(["Current Score", "Final Score"])
      row.concat(["Final Grade"]) if self.grading_standard_id
      csv << row.flatten
      
      #Second Row
      row = ["    Points Possible", "", ""]
      row.concat(assignments.map{|a| single ? [a.points_possible, ''] : a.points_possible})
      row.concat([read_only, read_only])
      row.concat([read_only]) if self.grading_standard_id
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
        row = [student.last_name_first, student.id, student_section]
        row.concat(student_submissions)
        row.concat([student_enrollment.computed_current_score, student_enrollment.computed_final_score])
        if self.grading_standard_id
          row.concat([score_to_grade(student_enrollment.computed_final_score)])
        end
        csv << row.flatten
      end
    end
  end
  
  def grading_standard_title
    if self.grading_standard_id
      self.grading_standard.try(:title) || t('default_grading_scheme_name', "Default Grading Scheme")
    else
      nil
    end
  end
  
  def score_to_grade(score)
    return "" unless self.grading_standard_id && score
    scheme = self.grading_standard.try(:data) || GradingStandard.default_grading_standard
    scheme.min_by {|s| score <= s[1] * 100 ? s[1] : Float::MAX }[0]
  end

  def participants
    (participating_admins + participating_students).uniq
  end
  
  def enroll_user(user, type='StudentEnrollment', opts={}) 
    enrollment_state = opts[:enrollment_state]
    section = opts[:section]
    invitation_email = opts[:invitation_email]
    limit_priveleges_to_course_section = opts[:limit_priveleges_to_course_section]
    section ||= self.default_section
    enrollment_state ||= self.available? ? "invited" : "creation_pending"
    enrollment_state = 'invited' if enrollment_state == 'creation_pending' && (type == 'TeacherEnrollment' || type == 'TaEnrollment')
    e = self.enrollments.find_by_user_id_and_type(user.id, type) if user
    e.update_attributes(:workflow_state => 'invited', :course_section => section, :limit_priveleges_to_course_section => limit_priveleges_to_course_section) if e && (e.completed? || e.rejected?)
    e ||= self.send(type.underscore.pluralize).create(:user => user, :workflow_state => enrollment_state, :course_section => section, :invitation_email => invitation_email, :limit_priveleges_to_course_section => limit_priveleges_to_course_section)
    self.claim if self.created? && e && e.admin?
    e
 end
  
  def enroll_student(user)
    enroll_user(user, 'StudentEnrollment')
  end
  
  def enroll_ta(user)
    enroll_user(user, 'TaEnrollment')
  end
  
  def enroll_teacher(user)
    enroll_user(user, 'TeacherEnrollment')
  end
  
  def resubmission_for(asset_string)
    admins.each{|u| u.ignored_item_changed!(asset_string, 'grading') }
  end
  
  def grading_standard_enabled
    !!self.grading_standard_id
  end
  
  def grading_standard_enabled=(val)
    if val == false || val == '0' || val == 'false' || val == 'off'
      self.grading_standard = nil
    else
      self.grading_standard_id ||= 0
    end
  end
  
  def gradebook_json
    hash = self.as_json(:include_root => false)
    submissions = self.submissions
    hash['active_assignments'] = self.active_assignments.map{|a| a.as_json(:include_root => false) }
    hash['students'] = self.students.map do |user|
      res = user.as_json(:include_root => false)
      res['submissions'] = submissions.select{|s| s.user_id == user.id }.map{|s| s.as_json(:include_root => false) }
      res
    end
    hash.to_json
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
  
  
  def merge_in(course, options={})
    return [] if course == self
    res = merge_into_course(course, options)
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
    if !res
      old_item = old_context.send(association_name).active.find_by_id(old_id)
      res = old_item.clone_for(new_context) if old_item
      res.save if res
    end
    res
  end
  
  def self.migrate_content_links(html, from_context, to_context, supported_types=nil, user_to_check_for_permission=nil)
    return html unless from_context
    @merge_mappings ||= {}
    limit_migrations_to_listed_types = !!supported_types
    from_name = "courses"
    from_name = "users" if from_context.is_a?(User)
    from_name = "groups" if from_context.is_a?(Group)
    to_name = "courses"
    to_name = "users" if to_context.is_a?(User)
    to_name = "groups" if to_context.is_a?(Group)
    regex = Regexp.new("/#{from_name}/#{from_context.id}/([^\\s]*)")
    html ||= ""
    html = html.gsub(regex) do |relative_url|
      sub_spot = $1
      matched = false
      is_sub_item = false
      {'assignments' => Assignment,
        'calendar_events' => CalendarEvent,
        'discussion_topics' => DiscussionTopic,
        'collaborations' => Collaboration,
        'files' => Attachment,
        'conferences' => WebConference,
        'quizzes' => Quiz,
        'groups' => Group,
        'modules' => ContextModule
      }.each do |type, obj_class|
        sub_regex = Regexp.new("#{type}/(\\d+)[^\\s]*$")
        is_sub_item ||= sub_spot.match(sub_regex)
        next if matched || (supported_types && !supported_types.include?(type))
        if item = sub_spot.match(sub_regex)
          matched = sub_spot.match(sub_regex)
          new_id = @merge_mappings["#{obj_class.to_s.underscore}_#{item[1]}"]
          allow_migrate_content = true
          if user_to_check_for_permission
            allow_migrate_content = from_context.grants_right?(user_to_check_for_permission, nil, :manage_content)
            if !allow_migrate_content
              obj = obj_class.find(item[1]) rescue nil
              allow_migrate_content = true if obj && obj.respond_to?(:grants_right?) && obj.grants_right?(user_to_check_for_permission, nil, :read)
              allow_migrate_content = false if obj && obj.respond_to?(:locked_for?) && obj.locked_for?(user_to_check_for_permission)
            end
          end
          if !new_id && allow_migrate_content && to_context != from_context
            new_obj = self.find_or_create_for_new_context(obj_class, to_context, from_context, item[1])
            new_id ||= new_obj.id if new_obj
          end
          if !limit_migrations_to_listed_types || new_id
            relative_url = relative_url.gsub("#{type}/#{item[1]}", new_id ? "#{type}/#{new_id}" : "#{type}")
          end
        end
      end
      if is_sub_item && !matched
        relative_url
      else
        relative_url = relative_url.gsub("/#{from_name}/#{from_context.id}", "/#{to_name}/#{to_context.id}")
      end
    end
    if !limit_migrations_to_listed_types
      regex = Regexp.new("include_contexts=[^\\s&]*#{from_context.asset_string}")
      html = html.gsub(regex) do |match|
        match.gsub("#{from_context.asset_string}", "#{to_context.asset_string}")
      end
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
    val == '1' || val == true || val == 'yes'
  end
  
  def boolean_hash(hash)
    res = {}
    hash.each do |key, val|
      res[key] = true if bool_res(hash[key])
    end
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

  def import_from_migration(data, params, migration)
    params ||= {:copy=>{}}
    logger.debug "starting import"
    @full_migration_hash = data
    @external_url_hash = {}
    @migration_results = []
    (data['web_link_categories'] || []).map{|c| c['links'] }.flatten.each do |link|
      @external_url_hash[link['link_id']] = link
    end
    ActiveRecord::Base.skip_touch_context
    @imported_migration_items = []

    # These only need to be processed once
    Attachment.skip_media_object_creation do
      process_migration_files(data, migration); migration.fast_update_progress(18)
      Attachment.process_migration(data, migration); migration.fast_update_progress(20)
      mo_attachments = self.imported_migration_items.find_all { |i| i.is_a?(Attachment) && i.media_entry_id.present? }
      # we'll wait synchronously for the media objects to be uploaded, so that
      # we have the media_ids that we need later.
      unless mo_attachments.blank?
        import_media_objects_and_attachments(mo_attachments, migration)
      end
    end

    # needs to happen after the files are processed, so that they are available in the syllabus
    import_settings_from_migration(data); migration.fast_update_progress(21)

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
    #todo - Import external tools when there are post-migration messages to tell the user to add shared secret/password
    #ContextExternalTool.process_migration(data, migration)

    2.times do |i|
      DiscussionTopic.process_migration(data, migration)
      WikiPage.process_migration(data, migration)
      migration.fast_update_progress((i==0 ? 55 : 75))
      Assignment.process_migration(data, migration)
      ContextModule.process_migration(data, migration)
      migration.fast_update_progress((i==0 ? 65 : 80))
    end
    #These aren't referenced by anything, but reference other things
    CalendarEvent.process_migration(data, migration)
    WikiPage.process_migration_course_outline(data, migration)
    migration.fast_update_progress(90)
    
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
          end
        end
      end
    rescue
      migration.add_warning("Couldn't adjust the due dates.", $!)
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
  attr_accessor :imported_migration_items, :full_migration_hash, :external_url_hash
  attr_accessor :folder_name_lookups, :attachment_path_id_lookup, :assignment_group_no_drop_assignments
  
  def import_settings_from_migration(data)
    return unless data[:course]
    settings = data[:course]
    self.conclude_at = Canvas::MigratorHelper.get_utc_time_from_timestamp(settings[:conclude_at]) if settings[:conclude_at]
    self.start_at = Canvas::MigratorHelper.get_utc_time_from_timestamp(settings[:start_at]) if settings[:start_at]
    self.syllabus_body = ImportedHtmlConverter.convert(settings[:syllabus_body], self) if settings[:syllabus_body]
    atts = Course.clonable_attributes
    atts -= Canvas::MigratorHelper::COURSE_NO_COPY_ATTS
    settings.slice(*atts.map(&:to_s)).each do |key, val|
      self.send("#{key}=", val)
    end
  end

  def import_media_objects_and_attachments(mo_attachments, migration)
    MediaObject.add_media_files(mo_attachments, true)
    # attachments in /media_objects were created on export, soley to
    # download and include a media object in the export. now that they've
    # been sent to kaltura, we can remove them.
    failed_uploads, mo_attachments = mo_attachments.partition { |a| a.media_object.nil? }

    unless failed_uploads.empty?
      migration.add_warning(t('errors.import.kaltura', "There was an error importing Kaltura media objects. Some or all of your media was not imported."), failed_uploads.map&(:id))
    end

    to_remove = mo_attachments.find_all { |a| a.full_path.starts_with?(File.join(Folder::ROOT_FOLDER_NAME, CC::CCHelper::MEDIA_OBJECTS_FOLDER) + '/') }
    to_remove.each do |a|
      a.destroy(false)
    end
    folder = to_remove.last.folder if to_remove.last
    if folder && folder.file_attachments.active.count == 0 && folder.active_sub_folders.count == 0
      folder.destroy
    end
  rescue Exception => e
    migration.add_warning(t('errors.import.kaltura', "There was an error importing Kaltura media objects. Some or all of your media was not imported."), e)
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
  
  attr_accessor :merge_mappings
  def merge_into_course(course, options)
    course_import = options[:import]
    @merge_mappings = {}
    @merge_results = []
    to_shift_dates = []
    @to_migrate_links = []
    added_items = []
    delete_placeholder = nil
    
    if bool_res(options[:course_settings])
      #Copy the course settings too
      course.attributes.slice(*Course.clonable_attributes.map(&:to_s)).keys.each do |attr|
        self.send("#{attr}=", course.send(attr))
      end
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
        new_file.save_without_broadcasting!
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
      if bool_res(options[:everything] ) || bool_res(options[:all_quizzes] ) || bool_res(options[quiz.asset_string.to_sym] ) || (quiz.assignment_id && bool_res(["assignment_#{quiz.assignment_id}"]))
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
      course_import.workflow_state = 'completed'
      course_import.progress = 100
      course_import.save!
    end
    added_items.map{|i| i.asset_string }
  end

  def self.clonable_attributes
    [ :group_weighting_scheme, :grading_standard_id, :is_public,
      :publish_grades_immediately, :allow_student_wiki_edits,
      :allow_student_assignment_edits, :hashtag, :show_public_context_messages,
      :syllabus_body, :hidden_tabs, :allow_student_forum_attachments,
      :default_wiki_editing_roles, :allow_student_organized_groups,
      :default_view, :show_all_discussion_entries, :open_enrollment,
      :storage_quota, :tab_configuration, :allow_wiki_comments,
      :turnitin_comments, :self_enrollment, :license, :indexed ]
  end

  def clone_for(account, opts={})
    new_course = Course.new
    root_account = account.root_account || account
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
    result[:day_substitions] = options[:day_substitions]
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
    
    new_time = ActiveSupport::TimeWithZone.new(Time.utc(new_date.year, new_date.month, new_date.day, (time.hour rescue 0), (time.min rescue 0)), Time.zone) - Time.zone.utc_offset
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
        :created_at, (options[:dates].first)..(options[:dates].last)
      })
    end
    PageView.count(
      :group => "date(created_at)", 
      :conditions => conditions
    )
  end
  memoize :page_views_by_day
  
  def visibility_limited_to_course_sections?(user)
    section_visibilities = Rails.cache.fetch(['section_visibilities_for', user, self].cache_key) do
      Enrollment.find(:all, :select => "course_section_id, limit_priveleges_to_course_section, type", :conditions => {:user_id => user.id, :course_id => self.id}).map{|e| {:course_section_id => e.course_section_id, :limit_priveleges_to_course_section => e.limit_priveleges_to_course_section, :type => e.type } }
    end
    !section_visibilities.any?{|s| !s[:limit_priveleges_to_course_section] }
  end
  
  # returns a scope, not an array of users/enrollments
  def students_visible_to(user, include_priors=false)
    enrollments_visible_to(user, include_priors, true)
  end
  def enrollments_visible_to(user, include_priors=false, return_users=false)
    section_visibilities = Rails.cache.fetch(['section_visibilities_for', user, self].cache_key) do
      Enrollment.find(:all, :select => "course_section_id, limit_priveleges_to_course_section, type", :conditions => ['user_id = ? AND course_id = ? AND workflow_state != ?', user.id, self.id, 'deleted']).map{|e| {:course_section_id => e.course_section_id, :limit_priveleges_to_course_section => e.limit_priveleges_to_course_section, :type => e.type } }
    end
    if return_users
      scope = include_priors ? self.all_students : self.students
    else
      scope = include_priors ? self.all_student_enrollments : self.student_enrollments
    end
    if section_visibilities.any?{|s| !s[:limit_priveleges_to_course_section] }
      scope
    elsif section_visibilities.empty?
      if self.grants_right?(user, nil, :manage_grades)
        scope
      else
        scope.scoped({:conditions => ['enrollments.user_id = ? OR enrollments.associated_user_id = ?', user.id, user.id]})
      end
    else
      scope.scoped({:conditions => "enrollments.course_section_id IN (#{section_visibilities.map{|s| s[:course_section_id]}.join(",")})"})
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
      recipients = (self.teachers.map(&:id) - [user.id]).join(",")
      ContextMessage.create!({
        :context_id => self.id,
        :context_type => self.class.to_s,
        :user_id => user.id,
        :subject => subject,
        :recipients => recipients,
        :body => message
      })
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
      { :id => TAB_HOME, :label => t('#tabs.home', "Home"), :href => :course_path },
      { :id => TAB_ANNOUNCEMENTS, :label => t('#tabs.announcements', "Announcements"), :href => :course_announcements_path },
      { :id => TAB_ASSIGNMENTS, :label => t('#tabs.assignments', "Assignments"), :href => :course_assignments_path },
      { :id => TAB_DISCUSSIONS, :label => t('#tabs.discussions', "Discussions"), :href => :course_discussion_topics_path },
      { :id => TAB_GRADES, :label => t('#tabs.grades', "Grades"), :href => :course_grades_path },
      { :id => TAB_PEOPLE, :label => t('#tabs.people', "People"), :href => :course_users_path },
      { :id => TAB_CHAT, :label => t('#tabs.chat', "Chat"), :href => :course_chat_path },
      { :id => TAB_PAGES, :label => t('#tabs.pages', "Pages"), :href => :course_wiki_pages_path },
      { :id => TAB_FILES, :label => t('#tabs.files', "Files"), :href => :course_files_path },
      { :id => TAB_SYLLABUS, :label => t('#tabs.syllabus', "Syllabus"), :href => :syllabus_course_assignments_path },
      { :id => TAB_OUTCOMES, :label => t('#tabs.outcomes', "Outcomes"), :href => :course_outcomes_path },
      { :id => TAB_QUIZZES, :label => t('#tabs.quizzes', "Quizzes"), :href => :course_quizzes_path },
      { :id => TAB_MODULES, :label => t('#tabs.modules', "Modules"), :href => :course_context_modules_path },
      { :id => TAB_CONFERENCES, :label => t('#tabs.conferences', "Conferences"), :href => :course_conferences_path },
      { :id => TAB_COLLABORATIONS, :label => t('#tabs.collaborations', "Collaborations"), :href => :course_collaborations_path },
      { :id => TAB_SETTINGS, :label => t('#tabs.settings', "Settings"), :href => :course_details_path },
    ]
  end
  
  def tabs_available(user=nil, opts={})
    # We will by default show everything in default_tabs, unless the teacher has configured otherwise.
    tabs = self.tab_configuration.compact
    default_tabs = Course.default_tabs
    tabs = tabs.map do |tab|
      default_tab = default_tabs.find {|t| t[:id] == tab[:id] }
      if default_tab
        tab[:label] = default_tab[:label]
        tab[:href] = default_tab[:href]
        default_tabs.delete_if {|t| t[:id] == tab[:id] }
        tab
      else
        # Remove any tabs we don't know about in default_tabs (in case we removed them or something, like Groups)
        nil
      end
    end
    tabs.compact!
    tabs += default_tabs
    
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
    if !user || !self.grants_right?(user, nil, :manage_content)
      tabs.delete_if{ |t| t[:id] == TAB_SETTINGS }
      
      # remove some tabs for logged-out users or non-students
      if self.grants_right?(user, nil, :read_as_admin)
        tabs.delete_if {|t| [TAB_CHAT].include?(t[:id]) } 
      elsif !self.grants_right?(user, nil, :participate_as_student)
        tabs.delete_if {|t| [TAB_PEOPLE, TAB_CHAT].include?(t[:id]) } 
      end
      if !self.grants_right?(user, nil, :read_grades) && !self.grants_right?(user, nil, :read_as_admin)
        tabs.delete_if {|t| [TAB_GRADES].include?(t[:id]) } 
      end
      
      # remove hidden tabs from students
      tabs.delete_if {|t| t[:hidden] || (t[:hidden_unused] && !opts[:include_hidden_unused]) }
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
    (root_account || account).enable_user_notes rescue false
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
  
end
