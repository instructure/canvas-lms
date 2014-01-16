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

class RoleOverride < ActiveRecord::Base
  belongs_to :context, :polymorphic => true # only Account now; we dropped Course level role overrides
  has_many :children, :class_name => "Role", :foreign_key => "parent_id"
  belongs_to :parent, :class_name => "Role"

  attr_accessible :context, :permission, :enrollment_type, :enabled, :applies_to_self, :applies_to_descendants

  validate :must_apply_to_something

  def must_apply_to_something
    self.errors.add(nil, "Must apply to something") unless applies_to_self? || applies_to_descendants?
  end

  def applies_to
    result = []
    result << :self if applies_to_self?
    result << :descendants if applies_to_descendants?
    result.presence
  end

  def self.account_membership_types(account)
    res = [{:name => "AccountAdmin", :base_role_name => AccountUser::BASE_ROLE_NAME, :label => t('roles.account_admin', "Account Admin")}]
    (account.available_account_roles - ['AccountAdmin']).each do |t|
      res << {:name => t, :base_role_name => AccountUser::BASE_ROLE_NAME, :label => t}
    end
    res
  end

  ENROLLMENT_TYPES =
    [
      # StudentViewEnrollment permissions will mirror StudentPermissions
      {:base_role_name => 'StudentEnrollment', :name => 'StudentEnrollment', :label => lambda { t('roles.student', 'Student') }, :plural_label => lambda { t('roles.students', 'Students') } },
      {:base_role_name => 'TeacherEnrollment', :name => 'TeacherEnrollment', :label => lambda { t('roles.teacher', 'Teacher') }, :plural_label => lambda { t('roles.teachers', 'Teachers') } },
      {:base_role_name => 'TaEnrollment', :name => 'TaEnrollment', :label => lambda { t('roles.ta', 'TA') }, :plural_label => lambda { t('roles.tas', 'TAs') } },
      {:base_role_name => 'DesignerEnrollment', :name => 'DesignerEnrollment', :label => lambda { t('roles.designer', 'Designer') }, :plural_label => lambda { t('roles.designers', 'Designers') } },
      {:base_role_name => 'ObserverEnrollment', :name => 'ObserverEnrollment', :label => lambda { t('roles.observer', 'Observer') }, :plural_label => lambda { t('roles.observers', 'Observers') } }
    ].freeze

  def self.enrollment_types
    ENROLLMENT_TYPES
  end

  BASE_ROLE_TYPES = ['AccountMembership', 'StudentEnrollment', 'TeacherEnrollment',
                     'TaEnrollment', 'ObserverEnrollment', 'DesignerEnrollment'].freeze
  def self.base_role_types
    BASE_ROLE_TYPES
  end

  NO_PERMISSIONS_TYPE = 'NoPermissions'

  KNOWN_ROLE_TYPES =
    [
      'TeacherEnrollment',
      'TaEnrollment',
      'DesignerEnrollment',
      'StudentEnrollment',
      'StudentViewEnrollment',
      'ObserverEnrollment',
      'TeacherlessStudentEnrollment',
      'AccountAdmin',
      'AccountMembership',
      NO_PERMISSIONS_TYPE
    ].freeze
  def self.known_role_types
    KNOWN_ROLE_TYPES
  end

  # immediately register stock canvas-lms permissions
  # NOTE: manage_alerts = Global Announcements and manage_interaction_alerts = Alerts
  # for legacy reasons
  # NOTE: if you add a permission, please also update the API documentation for
  # RoleOverridesController#add_role
  Permissions.register({
      :manage_wiki => {
        :label => lambda { t('permissions.manage_wiki', "Manage wiki (add / edit / delete pages)") },
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
      :read_forum => {
        :label => lambda { t('permissions.read_forum', "View discussions") },
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
        ]
      },
      :post_to_forum => {
        :label => lambda { t('permissions.post_to_forum', "Post to discussions") },
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
      :moderate_forum => {
        :label => lambda { t('permissions.moderate_form', "Moderate discussions ( delete / edit other's posts, lock topics)") },
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
      :send_messages_all => {
        :label => lambda { t('permissions.send_messages_all', "Send messages to the entire class") },
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
      :manage_outcomes => {
        :label => lambda { t('permissions.manage_outcomes', "Manage learning outcomes") },
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
      :create_conferences => {
        :label => lambda { t('permissions.create_conferences', "Create web conferences") },
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
      :create_collaborations => {
        :label => lambda { t('permissions.create_collaborations', "Create student collaborations") },
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
      :read_roster => {
        :label => lambda { t('permissions.read_roster', "See the list of users") },
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
      :view_all_grades => {
        :label => lambda { t('permissions.view_all_grades', "View all grades") },
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
        ]
      },
      :manage_grades => {
        :label => lambda { t('permissions.manage_grades', "Edit grades") },
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
      :manage_rubrics => {
          :label => lambda { t('permissions.manage_rubrics', "Create and edit assessing rubrics") },
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
      :comment_on_others_submissions => {
        :label => lambda { t('permissions.comment_on_others_submissions', "View all students' submissions and make comments on them") },
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
      :manage_students => {
        :label => lambda { t('permissions.manage_students', "Add/remove students for the course") },
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
      :manage_role_overrides => {
        :label => lambda { t('permissions.manage_role_overrides', "Manage permissions") },
        :account_only => true,
        :true_for => %w(AccountAdmin),
        :available_to => %w(AccountMembership)
      },
      :manage_account_memberships => {
        :label => lambda { t('permissions.manage_account_memberships', "Add/remove other admins for the account") },
        :available_to => [
          'AccountMembership'
        ],
        :true_for => [
          'AccountAdmin'
        ],
        :account_only => true
      },
      :manage_account_settings => {
        :label => lambda { t('permissions.manage_account_settings', "Manage account-level settings") },
        :available_to => [
          'AccountMembership'
        ],
        :true_for => [
          'AccountAdmin'
        ],
        :account_only => true
      },
      :manage_groups => {
        :label => lambda { t('permissions.manage_groups', "Manage (create / edit / delete) groups") },
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
      :view_group_pages => {
        :label => lambda { t('permissions.view_group_pages', "View the group pages of all student groups") },
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
        ]
      },
      :manage_files => {
        :label => lambda { t('permissions.manage_files', "Manage (add / edit / delete) course files") },
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
        ]
      },
      :manage_assignments => {
        :label => lambda { t('permissions.manage_assignments', "Manage (add / edit / delete) assignments and quizzes") },
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
        ]
      },
      :undelete_courses => {
        :label => lambda { t('permissions.undelete_courses', "Undelete courses") },
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
        :admin_tool => true,
        :account_only => true,
        :available_to => [
          'AccountAdmin',
          'AccountMembership'
        ],
        :true_for => [],
        :account_allows => lambda {|acct| acct.settings[:admins_can_view_notifications]}
      },
      :read_question_banks => {
        :label => lambda { t('permissions.read_question_banks', "View and link to question banks") },
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
        ]
      },
      :manage_calendar => {
        :label => lambda { t('permissions.manage_calendar', "Add, edit and delete events on the course calendar") },
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
      :read_reports => {
        :label => lambda { t('permissions.read_reports', "View usage reports for the course") },
        :available_to => [
          'StudentEnrollment',
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
      :manage_courses => {
        :label => lambda { t('permissions.manage_courses', "Manage ( add / edit / delete ) courses") },
        :available_to => [
          'AccountAdmin',
          'AccountMembership'
        ],
        :account_only => true,
        :true_for => [
          'AccountAdmin'
        ]
      },
      :manage_user_logins => {
        :label => lambda { t('permissions.manage_user_logins', "Modify login details for users") },
        :available_to => [
          'AccountAdmin',
          'AccountMembership'
        ],
        :account_only => true,
        :true_for => [
          'AccountAdmin'
        ]
      },
      :manage_alerts => {
        :label => lambda { t('permissions.manage_announcements', "Manage global announcements") },
        :account_only => true,
        :true_for => %w(AccountAdmin),
        :available_to => %w(AccountAdmin AccountMembership),
      },

      :read_messages => {
        :label => lambda { t('permissions.read_messages', "View notifications sent to users") },
        :account_only => :site_admin,
        :true_for => %w(AccountAdmin),
        :available_to => %w(AccountAdmin AccountMembership),
      },
      :become_user => {
        :label => lambda { t('permissions.become_user', "Become other users") },
        :account_only => :root,
        :true_for => %w(AccountAdmin),
        :available_to => %w(AccountAdmin AccountMembership),
      },
      :manage_site_settings => {
        :label => lambda { t('permissions.manage_site_settings', "Manage site-wide and plugin settings") },
        :account_only => :site_admin,
        :true_for => %w(AccountAdmin),
        :available_to => %w(AccountAdmin AccountMembership),
      },
      :manage_developer_keys => {
        :label => lambda { t('permissions.manage_developer_keys', "Manage developer keys") },
        :account_only => :site_admin,
        :true_for => %w(AccountAdmin),
        :available_to => %w(AccountAdmin AccountMembership),
      },
      :manage_sis => {
        :label => lambda { t('permissions.manage_sis', "Import and manage SIS data") },
        :account_only => true,
        :true_for => %w(AccountAdmin),
        :available_to => %w(AccountAdmin AccountMembership),
      },
      :read_sis => {
        :label => lambda { t('permission.read_sis', "Read SIS data") },
        :account_only => true,
        :true_for => %w(AccountAdmin TeacherEnrollment),
        :available_to => %w(AccountAdmin AccountMembership TeacherEnrollment TaEnrollment StudentEnrollment)
      },
      :read_course_list => {
        :label => lambda { t('permissions.read_course_list', "View the list of courses") },
        :account_only => true,
        :true_for => %w(AccountAdmin),
        :available_to => %w(AccountAdmin AccountMembership)
      },
      :view_statistics => {
        :label => lambda { t('permissions.view_statistics', "View statistics") },
        :account_only => true,
        :true_for => %w(AccountAdmin),
        :available_to => %w(AccountAdmin AccountMembership)
      },
      :manage_data_exports => {
        :label => lambda { t('permissions.generate_data_exports', "Generate Data Exports") }, #TODO add this setting to Permissions pane in account/settings.html.erb
        :account_only => true,
        :true_for => %w(AccountAdmin),
        :available_to => %w(AccountAdmin AccountMembership)
      },
      :manage_storage_quotas => {
          :label => lambda { t('permissions.manage_storage_quotas', "Manage storage quotas") },
          :account_only => true,
          :true_for => %w(AccountAdmin),
          :available_to => %w(AccountAdmin AccountMembership)
      },
      :manage_user_notes => {
        :label => lambda { t('permissions.manage_user_notes', "Manage faculty journal entries") },
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
        :if => :enable_user_notes
      },
      :read_course_content => {
        :label => lambda { t('permissions.read_course_content', "View course content") },
        :true_for => %w(AccountAdmin),
        :available_to => %w(AccountAdmin AccountMembership)
      },
      :manage_content => {
        :label => lambda { t('permissions.manage_content', "Manage all other course content") },
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
      :manage_interaction_alerts => {
        :label => lambda { t('permissions.manage_interaction_alerts', "Manage alerts") },
        :true_for => %w(AccountAdmin TeacherEnrollment),
        :available_to => %w(AccountAdmin AccountMembership TeacherEnrollment TaEnrollment),
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
      :change_course_state => {
        :label => lambda { t('permissions.change_course_state', "Change course state") },
        :true_for => %w(AccountAdmin TeacherEnrollment DesignerEnrollment),
        :available_to => %w(AccountAdmin AccountMembership TeacherEnrollment TaEnrollment DesignerEnrollment),
      },
      :manage_sections => {
        :label => lambda { t('permissions.manage_sections', "Manage (create / edit / delete) course sections") },
        :true_for => %w(AccountAdmin TeacherEnrollment DesignerEnrollment),
        :available_to => %w(AccountAdmin AccountMembership TeacherEnrollment TaEnrollment DesignerEnrollment),
      },
      :manage_frozen_assignments => {
        :label => lambda { t('permissions.manage_frozen_assignment', "Manage (edit / delete) frozen assignments") },
        :true_for => %w(AccountAdmin),
        :available_to => %w(AccountAdmin AccountMembership),
        :enabled_for_plugin => :assignment_freezer
      },
      :manage_feature_flags => {
        :label => lambda { t('permissions.manage_feature_flags', "Enable or disable features at an account level") },
        :true_for => %w(AccountAdmin),
        :available_to => %w(AccountAdmin AccountMembership)
      }
    })

  def self.permissions
    Permissions.retrieve
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

  def self.css_class_for(context, permission, base_role, custom_role=nil)
    generated_permission = self.permission_for(context, permission, base_role, custom_role)

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

  def self.readonly_for(context, permission, base_role, custom_role=nil)
    self.permission_for(context, permission, base_role, custom_role)[:readonly]
  end

  def self.title_for(context, permission, base_role, custom_role=nil)
    generated_permission = self.permission_for(context, permission, base_role, custom_role)
    if generated_permission[:readonly]
      t 'tooltips.readonly', "you do not have permission to change this."
    else
      t 'tooltips.toogle', "Click to toggle this permission ON or OFF"
    end
  end

  def self.locked_for(context, permission, base_role, custom_role=nil)
    self.permission_for(context, permission, base_role, custom_role)[:locked]
  end

  def self.hidden_value_for(context, permission, base_role, custom_role=nil)
    generated_permission = self.permission_for(context, permission, base_role, custom_role)
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

  def self.permission_for(role_context, permission, base_role, custom_role=nil)
    base_role = 'StudentEnrollment' if base_role == 'StudentViewEnrollment'
    custom_role = nil if base_role == NO_PERMISSIONS_TYPE
    if custom_role && custom_role == 'AccountAdmin'
      raise ArgumentError.new("Can't have AccountAdmin with base_role #{base_role}") unless base_role == AccountUser::BASE_ROLE_NAME
      # An AccountAdmin is the default account user and uses a different base
      # permission set. So set its base_role to AccountAdmin instead of AccountMembership
      base_role = 'AccountAdmin'
    end
    custom_role ||= base_role

    @cached_permissions ||= {}
    key = [role_context.cache_key, role_context.global_id, permission.to_s, custom_role.to_s].join
    permissionless_key = [role_context.cache_key, role_context.global_id, custom_role.to_s].join
    return @cached_permissions[key] if @cached_permissions[key]

    if !self.known_role_types.include?(base_role)
      raise ArgumentError.new("Invalid base_role #{base_role}")
    end
    default_data = self.permissions[permission]
    # Determine if the permission is able to be used for the account. A non-setting is 'true'.
    # Execute linked proc if given.
    account_allows = !!(default_data[:account_allows].nil? || (default_data[:account_allows].respond_to?(:call) &&
        default_data[:account_allows].call(role_context.root_account)))
    generated_permission = {
      :account_allows => account_allows,
      :permission =>  default_data,
      :enabled    =>  account_allows && (default_data[:true_for].include?(base_role) ? [:self, :descendants] : false),
      :locked     => !default_data[:available_to].include?(base_role),
      :readonly   => !default_data[:available_to].include?(base_role),
      :explicit   => false,
      :base_role_type => base_role,
      :enrollment_type => custom_role
    }
    if default_data[:account_only]
      if role_context.is_a? Account
        generated_permission[:enabled] = false if default_data[:account_only] == :root && !role_context.root_account?
        generated_permission[:enabled] = false if default_data[:account_only] == :site_admin && !role_context.site_admin?
      else
        generated_permission[:enabled] = false
      end
    end

    # cannot be overridden; don't bother looking for overrides
    return generated_permission if generated_permission[:locked]

    @@role_override_chain ||= {}
    overrides = @@role_override_chain[permissionless_key] ||= begin
      role_context.shard.activate do
        account_ids = role_context.account_chain_ids
        case_string = ""
        account_ids.each_with_index{|account_id, idx| case_string += " WHEN context_id='#{account_id}' THEN #{idx} " }
        overrides = RoleOverride.where(:context_id => account_ids, :enrollment_type => generated_permission[:enrollment_type].to_s).order("CASE #{case_string} ELSE 9999 END DESC")
        overrides.group_by(&:permission).freeze
      end
    end

    # walk the overrides from most general (root account) to most specific (the role's account)
    # and apply them; short-circuit once someone has locked it
    last_override = false
    (overrides[permission.to_s] || []).each do |override|
      # set the flag that we have an override for the context we're on
      last_override = override.context_id == role_context.id && override.context_type == role_context.class.base_class.name

      generated_permission[:context_id] = override.context_id
      generated_permission[:locked] = override.locked?
      # keep track of the value for the parent
      generated_permission[:prior_default] = generated_permission[:enabled]

      unless override.enabled.nil?
        generated_permission[:explicit] = true if last_override
        generated_permission[:enabled] = override.enabled? ? override.applies_to : nil
      end

      break if override.locked?
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
  def self.enabled_for?(role_context, context, permission, base_role, custom_role = nil)
    permission = permission_for(role_context, permission, base_role, custom_role)
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
    role_override = context.role_overrides.find_by_permission_and_enrollment_type(permission, role)
    if !settings[:override].nil? || settings[:locked]
      role_override ||= context.role_overrides.build(
        :permission => permission,
        :enrollment_type => role)
      role_override.enabled = settings[:override] unless settings[:override].nil?
      role_override.locked = settings[:locked] unless settings[:locked].nil?
      role_override.save!
    elsif role_override
      role_override.destroy
      role_override = nil
    end
    role_override
  end
end
