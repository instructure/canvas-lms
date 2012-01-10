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

# @API Roles
class RoleOverridesController < ApplicationController
  before_filter :require_context

  def index
    if authorized_action(@context, @current_user, :manage_role_overrides)
      @managing_account_roles = @context.is_a?(Account) && (params[:account_roles] || @context.site_admin?)

      if @managing_account_roles
        @role_types = RoleOverride.account_membership_types(@context)
      else
        @role_types = RoleOverride.enrollment_types
      end

      respond_to do |format|
        format.html
      end
    end
  end
  
  include Api::V1::Role

  # @API
  # Create a new admin role (admin membership type).
  #
  # @argument role
  #   Label and unique identifier for the role.
  #
  # @argument permissions[<X>][explicit] [Optional]
  # @argument permissions[<X>][enabled] [Optional]
  #   If explicit is 1 and enabled is 1, permission <X> will be explicitly
  #   granted to this role. If explicit is 1 and enabled has any other value
  #   (typically 0), permission <X> will be explicitly denied to this role. If
  #   explicit is any other value (typically 0) or absent, or if enabled is
  #   absent, the value for permission <X> will be inherited from upstream.
  #   Ignored if permission <X> is locked upstream (in an ancestor account).
  #
  #   May occur multiple times with unique values for <X>. Recognized
  #   permission names for <X> are:
  #
  #     become_user                      -- Become other users
  #     change_course_state              -- Change course state
  #     comment_on_others_submissions    -- View all students' submissions and make comments on them
  #     create_collaborations            -- Create student collaborations
  #     create_conferences               -- Create web conferences
  #     manage_account_memberships       -- Add/remove other admins for the account
  #     manage_account_settings          -- Manage account-level settings
  #     manage_admin_users               -- Add/remove other teachers, course designers or TAs to the course
  #     manage_alerts                    -- Manage global alerts
  #     manage_assignments               -- Manage (add / edit / delete) assignments and quizzes
  #     manage_calendar                  -- Add, edit and delete events on the course calendar
  #     manage_content                   -- Manage all other course content
  #     manage_courses                   -- Manage ( add / edit / delete ) courses
  #     manage_files                     -- Manage (add / edit / delete) course files
  #     manage_grades                    -- Edit grades (includes assessing rubrics)
  #     manage_groups                    -- Manage (create / edit / delete) groups
  #     manage_interaction_alerts        -- Manage alerts
  #     manage_jobs                      -- Manage background jobs
  #     manage_outcomes                  -- Manage learning outcomes
  #     manage_role_overrides            -- Manage permissions
  #     manage_sections                  -- Manage (create / edit / delete) course sections
  #     manage_sis                       -- Import and manage SIS data
  #     manage_site_settings             -- Manage site-wide and plugin settings
  #     manage_students                  -- Add/remove students for the course
  #     manage_user_logins               -- Modify login details for users
  #     manage_user_notes                -- Manage faculty journal entries
  #     manage_wiki                      -- Manage wiki (add / edit / delete pages)
  #     moderate_forum                   -- Moderate discussions ( delete / edit other's posts, lock topics)
  #     post_to_forum                    -- Post to discussions
  #     read_course_content              -- View course content
  #     read_course_list                 -- View the list of courses
  #     read_question_banks              -- View and link to question banks
  #     read_reports                     -- View usage reports for the course
  #     read_roster                      -- See the list of users
  #     send_messages                    -- Send messages to course members
  #     site_admin                       -- Use the Site Admin section and admin all other accounts
  #     view_all_grades                  -- View all grades
  #     view_error_reports               -- View error reports
  #     view_group_pages                 -- View the group pages of all student groups
  #     view_statistics                  -- View statistics
  #
  #   Some of these permissions are applicable only for roles on the site admin
  #   account or on a root account; if specified for a role on an inapplicable
  #   account, the permission will be ignored.
  #
  # @argument permissions[<X>][locked] [Optional]
  #   If the value is 1, permission <X> will be locked downstream (new roles in
  #   subaccounts cannot override the setting). For any other value, permission
  #   <X> is left unlocked. Ignored if permission <X> is already locked
  #   upstream. May occur multiple times with unique values for <X>.
  #
  # @response_field account
  #   JSON representation of the account the created role is in.
  #
  # @response_field role
  #   The label and unique identifier of the role.
  #
  # @response_field permissions
  #   A dictionary of permissions keyed by name (see permissions input
  #   parameter). The value for a given permission is a dictionary of the
  #   following boolean flags:
  #
  #   - enabled
  #
  #     Whether the role has the permission.
  #
  #   - locked
  #
  #     Whether the permission is locked by this role or by an upstream role.
  #
  #   - readonly
  #
  #     Whether the permission can be modified in this role (i.e. whether the
  #     permission is locked by an upstream role).
  #
  #   - explicit
  #
  #     Whether the value of enabled is specified explicitly by this role, or
  #     inherited from an upstream role.
  #
  #   - prior_default
  #
  #     The value that would have been inherited from upstream if the role had
  #     not explicitly set a value. Only present if explicit is true.
  #
  # @example_request
  #
  #   curl 'http://<canvas>/api/v1/accounts/<account_id>/roles.json' \ 
  #        -u '<username>:<password>' \ 
  #        -F 'role=New Role' \ 
  #        -F 'permissions[read_course_content][explicit]=1' \ 
  #        -F 'permissions[read_course_content][enabled]=1' \ 
  #        -F 'permissions[read_course_list][locked]=1' \ 
  #        -F 'permissions[read_question_banks][explicit]=1' \ 
  #        -F 'permissions[read_question_banks][enabled]=0' \ 
  #        -F 'permissions[read_question_banks][locked]=1'
  #
  # @example_response
  #
  #   {
  #     "role": "New Role",
  #     "account": {
  #       "id": 1019,
  #       "name": "CGNU",
  #       "parent_account_id": 73,
  #       "root_account_id": 1,
  #       "sis_account_id": "cgnu"
  #     },
  #     "permissions": {
  #       "read_course_content": {
  #         "enabled": true,
  #         "locked": false,
  #         "readonly": false,
  #         "explicit": true,
  #         "prior_default": false
  #       },
  #       "read_course_list": {
  #         "enabled": true,
  #         "locked": true,
  #         "readonly": true,
  #         "explicit": false
  #       },
  #       "read_question_banks": {
  #         "enabled": false,
  #         "locked": true,
  #         "readonly": false,
  #         "explicit": true,
  #         "prior_default": false
  #       },
  #       "read_reports": {
  #         "enabled": true,
  #         "locked": false,
  #         "readonly": false,
  #         "explicit": false
  #       },
  #       ...
  #     }
  #   }
  def add_role
    if authorized_action(@context, @current_user, :manage_role_overrides)
      role = api_request? ? params[:role] : params[:role_type]
      unless role.present?
        if api_request?
          render :json => {:message => "missing required parameter 'role'"}, :status => :bad_request
        else
          flash[:error] = t(:update_failed_notice, "Role creation failed")
          redirect_to named_context_url(@context, :context_permissions_url, :account_roles => params[:account_roles])
        end
        return
      end

      if @context.account_membership_types.include?(role) || RoleOverride::RESERVED_ROLES.include?(role)
        if api_request?
          render :json => {:message => "role already exists"}, :status => :bad_request
        else
          flash[:error] = t(:update_failed_notice, "Role creation failed")
          redirect_to named_context_url(@context, :context_permissions_url, :account_roles => params[:account_roles])
        end
        return
      end

      @context.add_account_membership_type(role)
      unless api_request?
        redirect_to named_context_url(@context, :context_permissions_url, :account_roles => params[:account_roles])
        return
      end

      # allow setting permissions immediately through API
      if params[:permissions]
        RoleOverride.manageable_permissions(@context).each do |permission|
          if settings = params[:permissions][permission]
            override = settings[:enabled].to_i == 1 if settings[:explicit].to_i == 1 && settings[:enabled].present?
            locked = settings[:locked].to_i == 1 if settings[:locked]
            RoleOverride.manage_role_override(@context, role, permission.to_s, :override => override, :locked => locked)
          end
        end
      end

      render :json => role_json(@context, role, @current_user, session)
    end
  end
  
  def remove_role
    if authorized_action(@context, @current_user, :manage_role_overrides)
      @context.remove_account_membership_type(params[:role])
      respond_to do |format|
        format.html { redirect_to named_context_url(@context, :context_permissions_url, :account_roles => '1') }
        format.json { render :json => @context.to_json(:only => [:membership_types, :id]) }
      end
    end
  end

  def create
    if authorized_action(@context, @current_user, :manage_role_overrides)
      @role_types = RoleOverride.enrollment_types
      @role_types = RoleOverride.account_membership_types(@context) if @context.is_a?(Account) && (params[:account_roles] || @context == Account.site_admin)
      if params[:permissions]
        RoleOverride.permissions.keys.each do |key|
          if params[:permissions][key]
            @role_types.each do |enrollment_type|
              role = enrollment_type[:name]
              if settings = params[:permissions][key][role]
                override = settings[:override] == 'checked' if ['checked', 'unchecked'].include?(settings[:override])
                locked = settings[:locked] == 'true' if settings[:locked]
                RoleOverride.manage_role_override(@context, role, key.to_s, :override => override, :locked => locked)
              end
            end
          end
        end
      end
      flash[:notice] = t 'notices.saved', "Changes Saved Successfully."
      redirect_to named_context_url(@context, :context_permissions_url, :account_roles => params[:account_roles])
    end
  end
end
