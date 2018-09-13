#
# Copyright (C) 2011 - present Instructure, Inc.
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

class RoleOverride < ActiveRecord::Base
  belongs_to :context, polymorphic: [:account]

  belongs_to :role
  include Role::AssociationHelper

  validates :enabled, inclusion: [true, false]
  validates :locked, inclusion: [true, false]

  validate :must_apply_to_something

  after_save :update_role_changed_at

  def update_role_changed_at
    self.role.touch
  end

  def self.v2_labels(context, has_v2)
    context.feature_enabled?(:permissions_v2_ui) && has_v2
  end

  def must_apply_to_something
    self.errors.add(nil, "Must apply to something") unless applies_to_self? || applies_to_descendants?
  end

  def applies_to
    result = []
    result << :self if applies_to_self?
    result << :descendants if applies_to_descendants?
    result.presence
  end

  ACCOUNT_ADMIN_LABEL = lambda { t('roles.account_admin', "Account Admin") }
  def self.account_membership_types(account)
    res = [{:id => Role.get_built_in_role("AccountAdmin").id, :name => "AccountAdmin", :base_role_name => Role::DEFAULT_ACCOUNT_TYPE, :label => ACCOUNT_ADMIN_LABEL.call}]
    account.available_custom_account_roles.each do |r|
      res << {:id => r.id, :name => r.name, :base_role_name => Role::DEFAULT_ACCOUNT_TYPE, :label => r.name}
    end
    res
  end

  ENROLLMENT_TYPE_LABELS =
    [
      # StudentViewEnrollment permissions will mirror StudentPermissions
      {:base_role_name => 'StudentEnrollment', :name => 'StudentEnrollment', :label => lambda { t('roles.student', 'Student') }, :plural_label => lambda { t('roles.students', 'Students') } },
      {:base_role_name => 'TeacherEnrollment', :name => 'TeacherEnrollment', :label => lambda { t('roles.teacher', 'Teacher') }, :plural_label => lambda { t('roles.teachers', 'Teachers') } },
      {:base_role_name => 'TaEnrollment', :name => 'TaEnrollment', :label => lambda { t('roles.ta', 'TA') }, :plural_label => lambda { t('roles.tas', 'TAs') } },
      {:base_role_name => 'DesignerEnrollment', :name => 'DesignerEnrollment', :label => lambda { t('roles.designer', 'Designer') }, :plural_label => lambda { t('roles.designers', 'Designers') } },
      {:base_role_name => 'ObserverEnrollment', :name => 'ObserverEnrollment', :label => lambda { t('roles.observer', 'Observer') }, :plural_label => lambda { t('roles.observers', 'Observers') } }
    ].freeze
  def self.enrollment_type_labels
    ENROLLMENT_TYPE_LABELS
  end

  # immediately register stock canvas-lms permissions
  # NOTE: manage_alerts = Global Announcements and manage_interaction_alerts = Alerts
  # for legacy reasons
  # NOTE: if you add a permission, please also update the API documentation for
  # RoleOverridesController#add_role
  Permissions.register({
    :manage_account_settings => {
      :label => lambda { t('permissions.manage_account_settings', "Manage account-level settings") },
      :label_v2 => lambda { t("Account-level settings - manage") },
      :available_to => [
        'AccountMembership'
      ],
      :true_for => [
        'AccountAdmin'
      ],
      :account_only => true
     },
    :manage_account_memberships => {
      :label => lambda { t('permissions.manage_account_memberships', "Add/remove other admins for the account") },
      :label_v2 => lambda { t("Admins - add / remove") },
      :available_to => [
        'AccountMembership'
      ],
      :true_for => [
        'AccountAdmin'
      ],
      :account_only => true
     },
    :manage_master_courses => {
      :label => lambda { t('Blueprint Courses (create / edit / associate / delete)') },
      :label_v2 => lambda { t("Blueprint Courses - add / edit / associate / delete") },
      :available_to => [
        'AccountAdmin',
        'AccountMembership'
      ],
      :account_only => true,
      :true_for => [
        'AccountAdmin'
      ],
      :account_allows => lambda {|a| a.root_account.feature_allowed?(:master_courses)}
     },
    :manage_catalog => {
      :label => lambda { t('permissions.manage_catalog', "Manage catalog") },
      :label_v2 => lambda { t("Catalog - manage") },
      :account_only => true,
      :true_for => %w(AccountAdmin),
      :available_to => %w(AccountAdmin AccountMembership),
      :account_allows => lambda {|a| a.settings[:catalog_enabled]}
     },
    :manage_courses => {
      :label => lambda { t('permissions.manage_', "Manage ( add / edit / delete ) ") },
      :label_v2 => lambda { t("Courses - add / edit / delete") },
      :available_to => [
        'AccountAdmin',
        'AccountMembership'
      ],
      :account_only => true,
      :true_for => [
        'AccountAdmin'
      ]
     },
    :read_course_list => {
      :label => lambda { t('permissions.read_course_list', "View the list of courses") },
      :label_v2 => lambda { t("Courses - view list") },
      :account_only => true,
      :true_for => %w(AccountAdmin),
      :available_to => %w(AccountAdmin AccountMembership)
     },
    :manage_developer_keys => {
      :label => lambda { t('permissions.manage_developer_keys', "Manage developer keys") },
      :label_v2 => lambda { t("Developer Keys - manage ") },
      :account_only => true,
      :true_for => %w(AccountAdmin),
      :available_to => %w(AccountAdmin AccountMembership),
     },
    :manage_alerts => {
      :label => lambda { t('permissions.manage_announcements', "Manage global announcements") },
      :label_v2 => lambda { t("Global Announcements - add / edit / delete") },
      :account_only => true,
      :true_for => %w(AccountAdmin),
      :available_to => %w(AccountAdmin AccountMembership),
     },
    :manage_role_overrides => {
      :label => lambda { t('permissions.manage_role_overrides', "Manage permissions") },
      :label_v2 => lambda { t("Permissions - manage") },
      :account_only => true,
      :true_for => %w(AccountAdmin),
      :available_to => %w(AccountMembership)
     },
    :import_sis => {
      :label => lambda { t('Import SIS data') },
      :label_v2 => lambda { t("SIS Data - import") },
      :account_only => :root,
      :true_for => %w(AccountAdmin),
      :available_to => %w(AccountAdmin AccountMembership),
     },
    :manage_sis => {
      :label => lambda { t('permissions.manage_sis', "Manage SIS data") },
      :label_v2 => lambda { t("SIS Data - manage") },
      :account_only => :root,
      :true_for => %w(AccountAdmin),
      :available_to => %w(AccountAdmin AccountMembership),
     },
    :view_statistics => {
      :label => lambda { t('permissions.view_statistics', "View statistics") },
      :label_v2 => lambda { t("Statistics - view") },
      :account_only => true,
      :true_for => %w(AccountAdmin),
      :available_to => %w(AccountAdmin AccountMembership)
     },
    :manage_storage_quotas => {
      :label => lambda { t('permissions.manage_storage_quotas', "Manage storage quotas") },
      :label_v2 => lambda { t("Storage Quotas - manage") },
        :account_only => true,
        :true_for => %w(AccountAdmin),
        :available_to => %w(AccountAdmin AccountMembership)
     },
    :become_user => {
      :label => lambda { t('Act as users') },
      :label_v2 => lambda { t("Users - act as") },
      :account_only => :root,
      :true_for => %w(AccountAdmin),
      :available_to => %w(AccountAdmin AccountMembership),
     },
    :manage_user_observers => {
      :label => lambda { t('permissions.manage_user_observers', "Manage observers for users") },
      :label_v2 => lambda { t("Users - add / remove observers") },
      :account_only => :root,
      :true_for => %w(AccountAdmin),
      :available_to => %w(AccountAdmin AccountMembership),
     },
    :manage_user_logins => {
      :label => lambda { t('permissions.manage_user_logins', "Modify login details for users") },
      :label_v2 => lambda { t("Users - manage login details") },
      :available_to => [
        'AccountAdmin',
        'AccountMembership'
      ],
      :account_only => :root,
      :true_for => [
        'AccountAdmin'
      ]
     },
    :undelete_courses => {
      :label => lambda { t('permissions.undelete_courses', "Undelete courses") },
      :label_v2 => lambda { t("Courses - undelete") },
      :admin_tool => true,
      :account_only => true,
      :available_to => [
        'AccountAdmin',
        'AccountMembership'
      ],
      :true_for => [ 'AccountAdmin' ]
     },
    :view_course_changes => {
      :label => lambda { t('permissions.view_course_changes', "View Course Change Logs") },
      :label_v2 => lambda { t("Courses - view change logs") },
      :admin_tool => true,
      :account_only => true,
      :available_to => [
        'AccountAdmin',
        'AccountMembership'
      ],
      :true_for => [ 'AccountAdmin' ]
     },
    :view_grade_changes => {
      :label => lambda { t('permissions.view_grade_changes', "View Grade Change Logs") },
      :label_v2 => lambda { t("Grades - view change logs") },
      :admin_tool => true,
      :account_only => true,
      :available_to => [
        'AccountAdmin',
        'AccountMembership'
      ],
      :true_for => [ 'AccountAdmin' ]
     },
    :view_notifications => {
      :label => lambda { t('permissions.view_notifications', "View notifications") },
      :label_v2 => lambda { t("Notifications - view") },
      :admin_tool => true,
      :account_only => true,
      :available_to => [
        'AccountAdmin',
        'AccountMembership'
      ],
      :true_for => [],
      :account_allows => lambda {|acct| acct.settings[:admins_can_view_notifications]}
     },
    :manage_jobs => {
      :label => lambda { t('permissions.managed_jobs', "Manage background jobs") },
      :account_only => :site_admin,
      :true_for => %w(AccountAdmin),
      :available_to => %w(AccountAdmin AccountMembership),
     },
    :view_jobs => {
        :label => lambda { t('permissions.view_jobs', "View background jobs") },
        :account_only => :site_admin,
        :true_for => %w(AccountAdmin),
        :available_to => %w(AccountAdmin AccountMembership),
     },
    :view_error_reports => {
      :label => lambda { t('permissions.view_error_reports', "View error reports") },
      :account_only => :site_admin,
      :true_for => %w(AccountAdmin),
      :available_to => %w(AccountAdmin AccountMembership),
     },
    :manage_global_outcomes => {
      :label => lambda { t('permissions.manage_global_outcomes', "Manage global learning outcomes") },
      :account_only => :site_admin,
      :true_for => %w(AccountAdmin),
      :available_to => %w(AccountAdmin AccountMembership),
     },
    :reset_any_mfa => {
      :label => -> { t('Reset Multi-Factor Authentication') },
      :account_only => :root,
      :true_for => %w(AccountAdmin),
      :available_to => %w(AccountAdmin AccountMembership),
      :account_allows => lambda {|a| a.mfa_settings != :disabled}
     },
    :manage_interaction_alerts => {
      :label => lambda { t('permissions.manage_interaction_alerts', "Manage alerts") },
      :label_v2 => lambda { t("Alerts - add / edit / delete") },
      :true_for => %w(AccountAdmin TeacherEnrollment),
      :available_to => %w(AccountAdmin AccountMembership TeacherEnrollment TaEnrollment),
     },
    :read_announcements => {
      :label => lambda { t('View announcements') },
      :label_v2 => lambda { t("Announcements - view") },
      :available_to => [
        'StudentEnrollment',
        'TaEnrollment',
        'DesignerEnrollment',
        'TeacherEnrollment',
        'TeacherlessStudentEnrollment',
        'ObserverEnrollment',
        'AccountAdmin',
        'AccountMembership'
      ],
      :true_for => [
        'StudentEnrollment',
        'TaEnrollment',
        'DesignerEnrollment',
        'ObserverEnrollment',
        'TeacherEnrollment',
        'AccountAdmin'
      ],
      :applies_to_concluded => true
     },
    :manage_assignments => {
      :label => lambda { t('permissions.manage_assignments', "Manage (add / edit / delete) assignments and quizzes") },
      :label_v2 => lambda { t("Assignments and Quizzes - add / edit / delete") },
      :available_to => [
        'TaEnrollment',
        'DesignerEnrollment',
        'TeacherEnrollment',
        'TeacherlessStudentEnrollment',
        'ObserverEnrollment',
        'AccountAdmin',
        'AccountMembership'
      ],
      :true_for => [
        'TaEnrollment',
        'DesignerEnrollment',
        'TeacherEnrollment',
        'AccountAdmin'
      ],
      :acts_as_access_token_scope => true
     },
    :send_messages_all => {
      :label => lambda { t('permissions.send_messages_all', "Send messages to the entire class") },
      :label_v2 => lambda { t("Conversations - send messages to entire class") },
      :available_to => [
        'StudentEnrollment',
        'TaEnrollment',
        'DesignerEnrollment',
        'TeacherEnrollment',
        'TeacherlessStudentEnrollment',
        'ObserverEnrollment',
        'AccountAdmin',
        'AccountMembership'
      ],
      :true_for => [
        'TaEnrollment',
        'DesignerEnrollment',
        'TeacherEnrollment',
        'AccountAdmin'
      ]
     },
    :send_messages => {
      :label => lambda { t('permissions.send_messages', "Send messages to individual course members") },
      :label_v2 => lambda { t("Conversations - send messages to individual course members") },
      :available_to => [
        'StudentEnrollment',
        'TaEnrollment',
        'DesignerEnrollment',
        'TeacherEnrollment',
        'TeacherlessStudentEnrollment',
        'ObserverEnrollment',
        'AccountAdmin',
        'AccountMembership'
      ],
      :true_for => [
        'StudentEnrollment',
        'TaEnrollment',
        'DesignerEnrollment',
        'TeacherEnrollment',
        'AccountAdmin'
      ]
     },
    :manage_calendar => {
      :label => lambda { t('permissions.manage_calendar', "Add, edit and delete events on the course calendar") },
      :label_v2 => lambda { t("Course Calendar - add / edit / delete events") },
      :available_to => [
        'StudentEnrollment',
        'TaEnrollment',
        'DesignerEnrollment',
        'TeacherEnrollment',
        'TeacherlessStudentEnrollment',
        'ObserverEnrollment',
        'AccountAdmin',
        'AccountMembership'
      ],
      :true_for => [
        'TaEnrollment',
        'DesignerEnrollment',
        'TeacherEnrollment',
        'AccountAdmin'
      ]
     },
    :manage_content => {
      :label => lambda { t('permissions.manage_content', "Manage all other course content") },
      :label_v2 => lambda { t("Course Content - add / edit / delete") },
      :available_to => [
        'TaEnrollment',
        'TeacherEnrollment',
        'DesignerEnrollment',
        'TeacherlessStudentEnrollment',
        'ObserverEnrollment',
        'AccountAdmin',
        'AccountMembership'
      ],
      :true_for => [
        'TaEnrollment',
        'TeacherEnrollment',
        'DesignerEnrollment',
        'AccountAdmin'
      ]
     },
    :read_course_content => {
      :label => lambda { t('permissions.read_course_content', "View course content") },
      :label_v2 => lambda { t("Course Content - view") },
      :true_for => %w(AccountAdmin),
      :available_to => %w(AccountAdmin AccountMembership)
     },
    :manage_files => {
      :label => lambda { t('permissions.manage_files', "Manage (add / edit / delete) course files") },
      :label_v2 => lambda { t("Course Files - add / edit / delete") },
      :available_to => [
        'TaEnrollment',
        'DesignerEnrollment',
        'TeacherEnrollment',
        'TeacherlessStudentEnrollment',
        'ObserverEnrollment',
        'AccountAdmin',
        'AccountMembership'
      ],
      :true_for => [
        'TaEnrollment',
        'DesignerEnrollment',
        'TeacherEnrollment',
        'AccountAdmin'
      ],
      :acts_as_access_token_scope => true
     },
    :manage_sections => {
      :label => lambda { t('permissions.manage_sections', "Manage (create / edit / delete) course sections") },
      :label_v2 => lambda { t("Course Sections - add / edit / delete") },
      :true_for => %w(AccountAdmin TeacherEnrollment DesignerEnrollment),
      :available_to => %w(AccountAdmin AccountMembership TeacherEnrollment TaEnrollment DesignerEnrollment),
     },
    :change_course_state => {
      :label => lambda { t('permissions.change_course_state', "Change course state") },
      :label_v2 => lambda { t("Course State - manage") },
      :true_for => %w(AccountAdmin TeacherEnrollment DesignerEnrollment),
      :available_to => %w(AccountAdmin AccountMembership TeacherEnrollment TaEnrollment DesignerEnrollment),
     },
    :read_reports => {
      :label => lambda { t('permissions.read_reports', "View usage reports for the course") },
      :label_v2 => lambda { t("Courses - view usage reports") },
      :available_to => [
        'TaEnrollment',
        'DesignerEnrollment',
        'TeacherEnrollment',
        'AccountAdmin',
        'AccountMembership'
      ],
      :true_for => [
        'TaEnrollment',
        'DesignerEnrollment',
        'TeacherEnrollment',
        'AccountAdmin'
      ]
     },
    :create_forum => {
      :label => lambda { t("Create new discussions") },
      :label_v2 => lambda { t("Discussions - create") },
      :available_to => [
        'StudentEnrollment',
        'TaEnrollment',
        'DesignerEnrollment',
        'TeacherEnrollment',
        'TeacherlessStudentEnrollment',
        'ObserverEnrollment',
        'AccountAdmin',
        'AccountMembership'
      ],
      :true_for => [
        'StudentEnrollment',
        'TaEnrollment',
        'DesignerEnrollment',
        'TeacherEnrollment',
        'AccountAdmin'
      ],
      :restrict_future_enrollments => true
     },
    :moderate_forum => {
      :label => lambda { t('permissions.moderate_form', "Moderate discussions ( delete / edit other's posts, lock topics)") },
      :label_v2 => lambda { t("Discussions - moderate") },
      :available_to => [
        'StudentEnrollment',
        'TaEnrollment',
        'DesignerEnrollment',
        'TeacherEnrollment',
        'TeacherlessStudentEnrollment',
        'ObserverEnrollment',
        'AccountAdmin',
        'AccountMembership'
      ],
      :true_for => [
        'TaEnrollment',
        'DesignerEnrollment',
        'TeacherEnrollment',
        'AccountAdmin'
      ]
     },
    :post_to_forum => {
      :label => lambda { t('permissions.post_to_forum', "Post to discussions") },
      :label_v2 => lambda { t("Discussions - post") },
      :available_to => [
        'StudentEnrollment',
        'TaEnrollment',
        'DesignerEnrollment',
        'TeacherEnrollment',
        'TeacherlessStudentEnrollment',
        'ObserverEnrollment',
        'AccountAdmin',
        'AccountMembership'
      ],
      :true_for => [
        'StudentEnrollment',
        'TaEnrollment',
        'DesignerEnrollment',
        'TeacherEnrollment',
        'AccountAdmin'
      ],
      :restrict_future_enrollments => true,
      :applies_to_concluded => ['TeacherEnrollment', 'TaEnrollment']
     },
    :read_forum => {
      :label => lambda { t('permissions.read_forum', "View discussions") },
      :label_v2 => lambda { t("Discussions - view") },
      :available_to => [
        'StudentEnrollment',
        'TaEnrollment',
        'DesignerEnrollment',
        'TeacherEnrollment',
        'TeacherlessStudentEnrollment',
        'ObserverEnrollment',
        'AccountAdmin',
        'AccountMembership'
      ],
      :true_for => [
        'StudentEnrollment',
        'TaEnrollment',
        'DesignerEnrollment',
        'ObserverEnrollment',
        'TeacherEnrollment',
        'AccountAdmin'
      ],
      :applies_to_concluded => true
     },
    :manage_feature_flags => {
      :label => lambda { t('permissions.manage_feature_flags', "Enable or disable features at an account level") },
      :label_v2 => lambda { t("Feature Options - enable / disable") },
      :true_for => %w(AccountAdmin),
      :available_to => %w(AccountAdmin AccountMembership)
     },
    :manage_user_notes => {
      :label => lambda { t('permissions.manage_user_notes', "Manage faculty journal entries") },
                             :label_v2 =>  lambda { t("Faculty Journal - manage entries") },
      :available_to => [
        'TaEnrollment',
        'TeacherEnrollment',
        'AccountAdmin',
        'AccountMembership'
      ],
      :true_for => [
        'TaEnrollment',
        'TeacherEnrollment',
        'AccountAdmin'
      ],
      :account_allows => lambda {|a| a.root_account.enable_user_notes}
     },
    :select_final_grade => {
      :label => -> { t('Grades - Select final grade for moderation') },
      :true_for => %w(AccountAdmin TeacherEnrollment TaEnrollment),
      :available_to => %w(AccountAdmin AccountMembership TeacherEnrollment TaEnrollment)
     },
    :view_audit_trail => {
      :label => -> { t('Grades - View audit trail') },
      :true_for => %w(AccountAdmin),
      :available_to => %w(TeacherEnrollment AccountAdmin AccountMembership)
     },
    :manage_grades => {
      :label => lambda { t('permissions.manage_grades', "Edit grades") },
      :label_v2 => lambda { t("Grades - edit") },
      :available_to => [
        'TaEnrollment',
        'TeacherEnrollment',
        'AccountAdmin',
        'AccountMembership'
      ],
      :true_for => [
        'TaEnrollment',
        'TeacherEnrollment',
        'AccountAdmin'
      ]
     },
    :moderate_grades => {
      :label => -> { t('Moderate Grades') },
      :label_v2 => -> { t('Grades - moderate') },
      :true_for => %w(AccountAdmin TeacherEnrollment),
      :available_to => %w(AccountAdmin AccountMembership TeacherEnrollment TaEnrollment)
     },
    :view_all_grades => {
      :label => lambda { t('permissions.view_all_grades', "View all grades") },
      :label_v2 => lambda { t("Grades - view all grades") },
      :available_to => [
        'TaEnrollment',
        'DesignerEnrollment',
        'TeacherEnrollment',
        'AccountAdmin',
        'AccountMembership'
      ],
      :true_for => [
        'TaEnrollment',
        'TeacherEnrollment',
        'AccountAdmin'
      ],
      :applies_to_concluded => true
     },
    :manage_groups => {
      :label => lambda { t('permissions.manage_groups', "Manage (create / edit / delete) groups") },
      :label_v2 => lambda { t("Groups - add / edit / delete") },
      :available_to => [
        'TaEnrollment',
        'DesignerEnrollment',
        'TeacherEnrollment',
        'AccountAdmin',
        'AccountMembership'
      ],
      :true_for => [
        'TaEnrollment',
        'DesignerEnrollment',
        'TeacherEnrollment',
        'AccountAdmin'
      ],
      :acts_as_access_token_scope => true
     },
    :view_group_pages => {
      :label => lambda { t('permissions.view_group_pages', "View the group pages of all student groups") },
      :label_v2 => lambda { t("Groups - view all student groups") },
      :available_to => [
        'StudentEnrollment',
        'TaEnrollment',
        'DesignerEnrollment',
        'TeacherEnrollment',
        'ObserverEnrollment',
        'AccountAdmin',
        'AccountMembership'
      ],
      :true_for => [
        'TaEnrollment',
        'DesignerEnrollment',
        'TeacherEnrollment',
        'AccountAdmin'
      ],
      :applies_to_concluded => true
     },
    :lti_add_edit => {
      :label => -> { t('LTI add and edit') },
      :label_v2 => -> { t('LTI - add / edit / delete') },
      :true_for => %w(TeacherEnrollment TaEnrollment DesignerEnrollment AccountAdmin),
      :available_to => %w(TeacherEnrollment TaEnrollment DesignerEnrollment AccountAdmin AccountMembership)
     },
    :manage_outcomes => {
      :label => lambda { t('permissions.manage_outcomes', "Manage learning outcomes") },
      :label_v2 => lambda { t("Learning Outcomes - add / edit / delete") },
      :available_to => [
        'StudentEnrollment',
        'TaEnrollment',
        'DesignerEnrollment',
        'TeacherEnrollment',
        'TeacherlessStudentEnrollment',
        'ObserverEnrollment',
        'AccountAdmin',
        'AccountMembership'
      ],
      :true_for => [
        'DesignerEnrollment',
        'TeacherEnrollment',
        'TeacherlessStudentEnrollment',
        'AccountAdmin'
      ]
     },
    :import_outcomes => {
      :label => lambda { t("Import learning outcomes") },
      :label_v2 => lambda { t("Learning Outcomes - import") },
      :available_to => [
      'TaEnrollment',
      'DesignerEnrollment',
      'TeacherEnrollment',
      'TeacherlessStudentEnrollment',
      'ObserverEnrollment',
      'AccountAdmin',
      'AccountMembership'
    ],
    :true_for => [
      'DesignerEnrollment',
      'TeacherEnrollment',
      'TeacherlessStudentEnrollment',
      'AccountAdmin'
    ]
   },
  :manage_frozen_assignments => {
      :label => lambda { t('permissions.manage_frozen_assignment', "Manage (edit / delete) frozen assignments") },
      :true_for => %w(AccountAdmin),
      :available_to => %w(AccountAdmin AccountMembership),
      :enabled_for_plugin => :assignment_freezer
    },
  :manage_site_settings => {
    :label => lambda { t('permissions.manage_site_settings', "Manage site-wide and plugin settings") },
    :account_only => :site_admin,
    :true_for => %w(AccountAdmin),
    :available_to => %w(AccountAdmin AccountMembership),
   },
  :manage_wiki => {
      :label => lambda { t("Manage (add / edit / delete) pages") },
      :label_v2 =>  lambda { t("Pages - add / edit / delete") },
    :available_to => [
      'TaEnrollment',
      'TeacherEnrollment',
      'DesignerEnrollment',
      'TeacherlessStudentEnrollment',
      'ObserverEnrollment',
      'AccountAdmin',
      'AccountMembership'
    ],
    :true_for => [
      'TaEnrollment',
      'TeacherEnrollment',
      'DesignerEnrollment',
      'AccountAdmin'
    ]
   },
  :read_question_banks => {
    :label => lambda { t('permissions.read_question_banks', "View and link to question banks") },
    :label_v2 => lambda { t("Question banks - view and link") },
    :available_to => [
      'TaEnrollment',
      'DesignerEnrollment',
      'TeacherEnrollment',
      'TeacherlessStudentEnrollment',
      'ObserverEnrollment',
      'AccountAdmin',
      'AccountMembership'
    ],
    :true_for => [
      'TaEnrollment',
      'DesignerEnrollment',
      'TeacherEnrollment',
      'AccountAdmin'
    ],
    :applies_to_concluded => true
   },
  :view_quiz_answer_audits => {
    :label => lambda { t('permissions.view_quiz_answer_audits', 'View the answer matrix in Quiz Submission Logs')},
    :label_v2 => lambda { t('Quizzes - view submission log')},
    :true_for => %w(AccountAdmin),
    :available_to => %w(AccountAdmin AccountMembership),
    :account_allows => lambda {|a| a.feature_allowed?(:quiz_log_auditing)}
   },
  :manage_rubrics => {
    :label => lambda { t('permissions.manage_rubrics', "Create and edit assessing rubrics") },
    :label_v2 => lambda { t("Rubrics - add / edit / delete") },
      :available_to => [
          'TaEnrollment',
          'DesignerEnrollment',
          'TeacherEnrollment',
          'AccountAdmin',
          'AccountMembership'
      ],
      :true_for => [
          'DesignerEnrollment',
          'TaEnrollment',
          'TeacherEnrollment',
          'AccountAdmin'
      ]
   },
  :read_sis => {
    :label => lambda { t('permission.read_sis', "Read SIS data") },
    :label_v2 => lambda { t("SIS Data - read") },
    :true_for => %w(AccountAdmin TeacherEnrollment),
    :available_to => %w(AccountAdmin AccountMembership TeacherEnrollment TaEnrollment StudentEnrollment)
   },
  :create_collaborations => {
    :label => lambda { t('permissions.create_collaborations', "Create student collaborations") },
    :label_v2 => lambda { t("Student Collaborations - create") },
    :available_to => [
      'StudentEnrollment',
      'TaEnrollment',
      'DesignerEnrollment',
      'TeacherEnrollment',
      'TeacherlessStudentEnrollment',
      'ObserverEnrollment',
      'AccountAdmin',
      'AccountMembership'
    ],
    :true_for => [
      'StudentEnrollment',
      'TaEnrollment',
      'DesignerEnrollment',
      'TeacherEnrollment',
      'AccountAdmin'
    ]
   },
  :comment_on_others_submissions => {
    :label => lambda { t('permissions.comment_on_others_submissions', "View all students' submissions and make comments on them") },
    :label_v2 => lambda { t("Submissions - view and make comments") },
    :available_to => [
      'StudentEnrollment',
      'TaEnrollment',
      'DesignerEnrollment',
      'TeacherEnrollment',
      'TeacherlessStudentEnrollment',
      'AccountAdmin',
      'AccountMembership'
    ],
    :true_for => [
      'TaEnrollment',
      'DesignerEnrollment',
      'TeacherEnrollment',
      'AccountAdmin'
    ]
   },
  :generate_observer_pairing_code => {
    :label => -> { t('Users - Generate observer pairing codes for students') },
    :true_for => %w(AccountAdmin),
    :available_to => %w(TeacherEnrollment ObserverEnrollment TaEnrollment AccountAdmin AccountMembership DesignerEnrollment)
   },
  :manage_students => {
    :label => lambda { t('permissions.manage_students', "Add/remove students for the course") },
    :label_v2 => lambda { t("Users - add / remove students in courses") },
    :available_to => [
      'TaEnrollment',
      'DesignerEnrollment',
      'TeacherEnrollment',
      'TeacherlessStudentEnrollment',
      'AccountAdmin',
      'AccountMembership'
    ],
    :true_for => [
      'TaEnrollment',
      'DesignerEnrollment',
      'TeacherEnrollment',
      'AccountAdmin'
    ]
   },
  :manage_admin_users => {
    :label => lambda { t('permissions.manage_admin_users', "Add/remove other teachers, course designers or TAs to the course") },
    :label_v2 => lambda { t("Users - add / remove teachers, course designers, or TAs in courses") },
    :available_to => [
      'TaEnrollment',
      'DesignerEnrollment',
      'TeacherEnrollment',
      'AccountAdmin',
      'AccountMembership'
    ],
    :true_for => [
      'TeacherEnrollment',
      'AccountAdmin'
    ]
   },
  :read_roster => {
    :label => lambda { t('permissions.read_roster', "See the list of users") },
    :label_v2 => lambda { t("Users - view list") },
    :available_to => [
      'StudentEnrollment',
      'TaEnrollment',
      'DesignerEnrollment',
      'TeacherEnrollment',
      'TeacherlessStudentEnrollment',
      'ObserverEnrollment',
      'AccountAdmin',
      'AccountMembership'
    ],
    :true_for => [
      'StudentEnrollment',
      'TaEnrollment',
      'DesignerEnrollment',
      'TeacherEnrollment',
      'AccountAdmin'
    ],
    :applies_to_concluded => ['TeacherEnrollment', 'TaEnrollment', 'DesignerEnrollment']
   },
  :view_user_logins => {
    :label => lambda { t("View login ids for users") },
    :label_v2 => lambda { t("Users - view login IDs") },
    :available_to => %w(AccountAdmin AccountMembership TeacherEnrollment TaEnrollment),
    :true_for => %w(AccountAdmin TeacherEnrollment TaEnrollment)
   },
  :read_email_addresses => {
    :label => lambda { t("See other users' primary email address") },
    :label_v2 => lambda { t("Users - view primary email address") },
    :available_to => [
      'StudentEnrollment',
      'TaEnrollment',
      'DesignerEnrollment',
      'TeacherEnrollment',
      'TeacherlessStudentEnrollment',
      'ObserverEnrollment',
      'AccountAdmin',
      'AccountMembership'
    ],
    :true_for => [
      'TaEnrollment',
      'TeacherEnrollment',
      'AccountAdmin'
    ],
    :applies_to_concluded => ['TeacherEnrollment', 'TaEnrollment']
   },
  :read_messages => {
    :label => lambda { t('permissions.read_messages', "View notifications sent to users") },
    :account_only => :site_admin,
    :true_for => %w(AccountAdmin),
    :available_to => %w(AccountAdmin AccountMembership),
   },
  :create_conferences => {
    :label => lambda { t('permissions.create_conferences', "Create web conferences") },
    :label_v2 => lambda { t("Web Conferences - create") },
    :available_to => [
      'StudentEnrollment',
      'TaEnrollment',
      'DesignerEnrollment',
      'TeacherEnrollment',
      'TeacherlessStudentEnrollment',
      'ObserverEnrollment',
      'AccountAdmin',
      'AccountMembership'
    ],
    :true_for => [
      'StudentEnrollment',
      'TaEnrollment',
      'DesignerEnrollment',
      'TeacherEnrollment',
      'AccountAdmin'
    ]
  }
    })

  ACCESS_TOKEN_SCOPE_PREFIX = 'https://api.instructure.com/auth/canvas'.freeze

  def self.permissions
    Permissions.retrieve
  end

  # permissions that apply to concluded courses/enrollments
  def self.concluded_permission_types
    self.permissions.select{|k, p| !!p[:applies_to_concluded]}
  end

  def self.manageable_permissions(context, base_role_type=nil)
    permissions = self.permissions.dup
    permissions.reject!{ |k, p| p[:account_only] == :site_admin } unless context.site_admin?
    permissions.reject!{ |k, p| p[:account_only] == :root } unless context.root_account?
    permissions.reject!{ |k, p| !p[:available_to].include?(base_role_type)} unless base_role_type.nil?
    permissions.reject!{ |k, p| p[:account_allows] && !p[:account_allows].call(context)}
    permissions.reject!{ |k, p| p[:enabled_for_plugin] &&
      !((plugin = Canvas::Plugin.find(p[:enabled_for_plugin])) && plugin.enabled?)}
    permissions
  end

  def self.manageable_access_token_scopes(context)
    permissions = manageable_permissions(context).dup
    permissions.select! { |_, p| p[:acts_as_access_token_scope].present? }

    permissions.map do |k, p|
      {
        name: "#{ACCESS_TOKEN_SCOPE_PREFIX}.#{k}",
        label:  v2_labels(@context, p.key?(label_v2)) ? p[:label_v2].call : p[:label].call
      }
    end
  end

  def self.css_class_for(context, permission, role, role_context=nil)
    generated_permission = self.permission_for(context, permission, role, role_context=nil)

    css = []
    if generated_permission[:readonly]
      css << "six-checkbox-disabled-#{generated_permission[:enabled] ? 'checked' : 'unchecked' }"
    else
      if generated_permission[:explicit]
        css << "six-checkbox-default-#{generated_permission[:prior_default] ? 'checked' : 'unchecked'}"
      end
      css << "six-checkbox#{generated_permission[:explicit] ? '' : '-default' }-#{generated_permission[:enabled] ? 'checked' : 'unchecked' }"
    end
    css.join(' ')
  end

  def self.readonly_for(context, permission, role, role_context=nil)
    self.permission_for(context, permission, role, role_context)[:readonly]
  end

  def self.title_for(context, permission, role, role_context=nil)
    if self.readonly_for(context, permission, role, role_context)
      t 'tooltips.readonly', "you do not have permission to change this."
    else
      t 'tooltips.toogle', "Click to toggle this permission ON or OFF"
    end
  end

  def self.locked_for(context, permission, role, role_context=nil)
    self.permission_for(context, permission, role, role_context)[:locked]
  end

  def self.hidden_value_for(context, permission, role, role_context=nil)
    generated_permission = self.permission_for(context, permission, role, role_context)
    if !generated_permission[:readonly] && generated_permission[:explicit]
      generated_permission[:enabled] ? 'checked' : 'unchecked'
    else
      ''
    end
  end

  def self.teacherless_permissions
    @teacherless_permissions ||= permissions.select{|p, data| data[:available_to].include?('TeacherlessStudentEnrollment') }.map{|p, data| p }
  end

  def self.clear_cached_contexts
    @@role_override_chain = {}
    @cached_permissions = {}
  end

  def self.permission_for(context, permission, role, role_context=nil)
    # TODO: optimize all this stuff

    @cached_permissions ||= {}
    role_context ||= role.account
    permissionless_key = [context.cache_key, context.global_id, role.global_id, role_context.try(:global_id)].join("/")
    key = [permissionless_key, permission].join("/")

    return @cached_permissions[key] if @cached_permissions[key]

    default_data = self.permissions[permission]
    # Determine if the permission is able to be used for the account. A non-setting is 'true'.
    # Execute linked proc if given.
    account_allows = !!(default_data[:account_allows].nil? || (default_data[:account_allows].respond_to?(:call) &&
        default_data[:account_allows].call(context.root_account)))

    base_role = role.base_role_type
    locked = !default_data[:available_to].include?(base_role) || !account_allows

    generated_permission = {
      :account_allows => account_allows,
      :permission =>  default_data,
      :enabled    =>  account_allows && (default_data[:true_for].include?(base_role) ? [:self, :descendants] : false),
      :locked     => locked,
      :readonly   => locked,
      :explicit   => false,
      :base_role_type => base_role,
      :enrollment_type => role.name,
      :role_id => role.id
    }

    if default_data[:account_only]
      # note: built-in roles don't have an account so we need to remember to send it in explicitly
      generated_permission[:enabled] = false if default_data[:account_only] == :root &&
          !(role_context && role_context.is_a?(Account) && role_context.root_account?)

      generated_permission[:enabled] = false if default_data[:account_only] == :site_admin &&
          !(role_context && role_context.is_a?(Account) && role_context.site_admin?)
    end

    # cannot be overridden; don't bother looking for overrides
    return generated_permission if locked

    @@role_override_chain ||= {}
    overrides = @@role_override_chain[permissionless_key] ||= begin
      context.shard.activate do
        accounts = context.account_chain(include_site_admin: true)
        overrides = Shard.partition_by_shard(accounts) do |shard_accounts|
          # skip loading from site admin if the role is not from site admin
          next if shard_accounts == [Account.site_admin] && role_context != Account.site_admin
          RoleOverride.where(:context_id => accounts, :context_type => 'Account', :role_id => role)
        end

        accounts.reverse!
        overrides = overrides.group_by(&:permission)

        # every context has to be represented so that we can't miss role_context below
        overrides.each_key do |permission|
          overrides_by_account = overrides[permission].index_by(&:context_id)
          overrides[permission] = accounts.map do |account|
            overrides_by_account[account.id] || RoleOverride.new { |ro| ro.context = account }
          end
        end
        overrides
      end
    end

    # walk the overrides from most general (site admin, root account) to most specific (the role's account)
    # and apply them; short-circuit once someone has locked it
    last_override = false
    hit_role_context = false
    (overrides[permission.to_s] || []).each do |override|
      # set the flag that we have an override for the context we're on
      last_override = override.context_id == context.id && override.context_type == context.class.base_class.name

      generated_permission[:context_id] = override.context_id unless override.new_record?
      generated_permission[:locked] = override.locked?
      # keep track of the value for the parent
      generated_permission[:prior_default] = generated_permission[:enabled]

      # override.enabled.nil? is no longer possible, but is important for the migration that removes nils
      if override.new_record? || override.enabled.nil?
        if last_override
          if generated_permission[:enabled] == [:descendants]
            generated_permission[:enabled] = [:self, :descendants]
          elsif generated_permission[:enabled] == [:self]
            generated_permission[:enabled] = nil
          end
        end
      else
        generated_permission[:explicit] = true if last_override
        if hit_role_context
          generated_permission[:enabled] ||= override.enabled? ? override.applies_to : nil
        else
          generated_permission[:enabled] = override.enabled? ? override.applies_to : nil
        end
      end
      hit_role_context ||= (role_context.is_a?(Account) && override.has_asset?(role_context))

      break if override.locked?
      break if generated_permission[:enabled] && hit_role_context
    end

    # there was not an override matching this context, so do a half loop
    # to set the inherited values
    if !last_override
      generated_permission[:prior_default] = generated_permission[:enabled]
      generated_permission[:readonly] = true if generated_permission[:locked]
    end

    @cached_permissions[key] = generated_permission.freeze
  end

  # returns just the :enabled key of permission_for, adjusted for applying it to a certain
  # context
  def self.enabled_for?(context, permission, role, role_context=nil)
    permission = permission_for(context, permission, role, role_context)
    return [] unless permission[:enabled]

    # this override applies to self, and we are self; no adjustment necessary
    return permission[:enabled] if context.id == permission[:context_id]
    # this override applies to descendants, and we're not applying it to self
    #   (presumed that other logic prevents calling this method with context being a parent of role_context)
    return [:self, :descendants] if context.id != permission[:context_id] && permission[:enabled].include?(:descendants)
    []
  end

  # settings is a hash with recognized keys :override and :locked. each key
  # differentiates nil, false, and truthy as possible values
  def self.manage_role_override(context, role, permission, settings)
    context.shard.activate do
      role_override = context.role_overrides.where(:permission => permission, :role_id => role.id).first
      if !settings[:override].nil? || settings[:locked]
        role_override ||= context.role_overrides.build(
          :permission => permission,
          :role => role)
        role_override.enabled = settings[:override] unless settings[:override].nil?
        role_override.locked = settings[:locked] unless settings[:locked].nil?
        role_override.applies_to_self = settings[:applies_to_self] unless settings[:applies_to_self].nil?
        unless settings[:applies_to_descendants].nil?
          role_override.applies_to_descendants = settings[:applies_to_descendants]
        end
        role_override.save!
      elsif role_override
        role_override.destroy
        role_override = nil
      end
      role_override
    end
  end
end
