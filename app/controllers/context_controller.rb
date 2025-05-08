# frozen_string_literal: true

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

class ContextController < ApplicationController
  include SearchHelper
  include CustomSidebarLinksHelper

  before_action :require_context, except: [:inbox, :object_snippet]

  include HorizonMode
  before_action :load_canvas_career, only: [:roster]

  before_action :require_user, only: [:inbox, :report_avatar_image]
  before_action :reject_student_view_student, only: [:inbox]
  protect_from_forgery except: [:object_snippet], with: :exception

  include K5Mode

  MAX_MESSAGES_ON_PROFILE = 10

  # safely render object and embed tags as part of user content, by using a
  # iframe pointing to the separate files domain that doesn't contain a user's
  # session. see lib/user_content.rb and the user_content calls throughout the
  # views.
  def object_snippet
    if HostUrl.has_file_host? && !HostUrl.is_file_host?(request.host_with_port)
      return head :bad_request
    end

    @snippet = params[:object_data] || ""

    unless Canvas::Security.verify_hmac_sha1(params[:s], @snippet)
      return head :bad_request
    end

    # http://blogs.msdn.com/b/ieinternals/archive/2011/01/31/controlling-the-internet-explorer-xss-filter-with-the-x-xss-protection-http-header.aspx
    # recent versions of IE and Webkit have added client-side XSS prevention
    # measures. if data that includes potentially dangerous strings like
    # "<script..." or "<object..." is sent to the server and then that exact
    # same string is rendered in the html response, the browser will refuse to
    # render that part of the content. this header tells the browser that we're
    # doing it on purpose, so skip the XSS detection.
    response["X-XSS-Protection"] = "0"
    @snippet = Base64.decode64(@snippet)
    render layout: false
  end

  def inbox
    redirect_to conversations_url, status: :moved_permanently
  end

  def roster
    return unless authorized_action(@context, @current_user, :read_roster)

    page_has_instui_topnav
    log_asset_access(["roster", @context], "roster", "other")

    case @context
    when Course
      return unless tab_enabled?(Course::TAB_PEOPLE)

      if @context.concluded?
        sections = @context.course_sections.active.select(%i[id course_id name end_at restrict_enrollments_to_section_dates]).preload(:course)
        concluded_sections = sections.select(&:concluded?).map { |s| "section_#{s.id}" }
      else
        sections = @context.course_sections.active.select([:id, :name])
        concluded_sections = []
      end

      all_roles = Role.role_data(@context, @current_user)
      load_all_contexts(context: @context)
      manage_students = @context.grants_right?(@current_user, session, :manage_students) && !MasterCourses::MasterTemplate.is_master_course?(@context)
      can_add_enrollments = @context.grants_any_right?(@current_user, session, *RoleOverride::GRANULAR_COURSE_ENROLLMENT_PERMISSIONS)
      allow_assign_to_differentiation_tags = @context.account.feature_enabled?(:assign_to_differentiation_tags) && @context.account.allow_assign_to_differentiation_tags?
      js_permissions = {
        read_sis: @context.grants_any_right?(@current_user, session, :read_sis, :manage_sis),
        view_user_logins: @context.grants_right?(@current_user, session, :view_user_logins),
        manage_students:,
        add_users_to_course: can_add_enrollments,
        active_granular_enrollment_permissions: get_active_granular_enrollment_permissions(@context),
        read_reports: @context.grants_right?(@current_user, session, :read_reports),
        can_add_groups: can_do(@context.groups.temp_record, @current_user, :create),
        can_allow_course_admin_actions: @context.grants_right?(@current_user, session, :allow_course_admin_actions),
        can_manage_differentiation_tags: @context.grants_any_right?(@current_user, *RoleOverride::GRANULAR_MANAGE_TAGS_PERMISSIONS),
        can_generate_observer_pairing_code: @context.grants_right?(@current_user, :generate_observer_pairing_code),
        can_read_prior_roster: @context.grants_right?(@current_user, session, :read_prior_roster),
        can_read_roster: @context.grants_right?(@current_user, session, :read_roster),
        can_view_all_grades: @context.grants_right?(@current_user, session, :view_all_grades),
        self_registration: @context.root_account.self_registration?,
        user_is_instructor: @context.user_is_instructor?(@current_user),
        allow_assign_to_differentiation_tags:,
      }

      js_env({
               ALL_ROLES: all_roles,
               SECTIONS: sections.map { |s| { id: s.id.to_s, name: s.name } },
               CONCLUDED_SECTIONS: concluded_sections,
               SEARCH_URL: search_recipients_url,
               COURSE_ROOT_URL: "/courses/#{@context.id}",
               CONTEXTS: @contexts,
               resend_invitations_url: course_re_send_invitations_url(@context),
               permissions: js_permissions,
               course: {
                 id: @context.id,
                 completed: @context.completed?,
                 soft_concluded: @context.soft_concluded?,
                 concluded: @context.concluded?,
                 available: @context.available?,
                 pendingInvitationsCount: @context.invited_count_visible_to(@current_user),
                 hideSectionsOnCourseUsersPage: @context.sections_hidden_on_roster_page?(current_user: @current_user),
                 groups_url: context_url(@context, :context_groups_url),
                 prior_enrollments_url: course_prior_users_path(@context),
                 interactions_report_url: user_course_teacher_activity_url(@current_user, @context),
                 user_services_url: context_url(@context, :context_user_services_url),
                 observer_pairing_codes_url: course_observer_pairing_codes_url(@context),
                 course_student_count: allow_assign_to_differentiation_tags ? @context.student_enrollments.count : nil,
               }
             })
      set_tutorial_js_env

      if can_add_enrollments
        js_env({ ROOT_ACCOUNT_NAME: @domain_root_account.name })
        if @context.root_account.open_registration? || @context.root_account.grants_right?(@current_user, session, :manage_user_logins)
          js_env({ INVITE_USERS_URL: course_invite_users_url(@context) })
        end
      end
      if @context.grants_right?(@current_user, session, :read_as_admin)
        set_student_context_cards_js_env
      end
    when Group
      @users = if @context.grants_right?(@current_user, :read_as_admin)
                 @context.participating_users.distinct.order_by_sortable_name
               else
                 @context.participating_users_in_context(sort: true).distinct.order_by_sortable_name
               end
      @primary_users = { t("roster.group_members", "Group Members") => @users }
      if (course = @context.context.is_a?(Course) && @context.context)
        instructors = course.participating_instructors.order_by_sortable_name.distinct
        # UserSearch.scope_for makes the teachers and ta's list to match what api v1 is returning with respect to section restrictions
        @secondary_users = { t("roster.teachers_and_tas", "Teachers & TAs") => instructors.select { |instructor| UserSearch.scope_for(course, @current_user).include?(instructor) } }
      end
    end

    # Render upgraded People page if feature flag is enabled
    if @domain_root_account.feature_enabled?(:react_people_page)
      add_crumb t("People")
      js_bundle :course_people
      render html: "", layout: true
    end

    @secondary_users ||= {}
    @groups = @context.try(:groups)&.active || []

    # Render Modernized People Page if feature flag is enabled
    if @context.is_a?(Course) && @context.root_account.feature_enabled?(:people_page_modernization)
      add_crumb t("People"), context_url(@context, :context_users_url)
      js_bundle :course_people_new
      render html: "", layout: true
    end
  end

  def prior_users
    page_has_instui_topnav

    if authorized_action(@context, @current_user, %i[manage_students allow_course_admin_actions read_prior_roster])
      @prior_users = @context.prior_users
                             .by_top_enrollment.merge(Enrollment.not_fake)
                             .paginate(page: params[:page], per_page: 20)

      users = @prior_users.index_by(&:id)
      if users.present?
        # put the relevant prior enrollment on each user
        @context.prior_enrollments.where({ user_id: users.keys })
                .top_enrollment_by(:user_id, :student)
                .each { |e| users[e.user_id].prior_enrollment = e }
      end
    end
  end

  def roster_user_services
    if authorized_action(@context, @current_user, :read_roster)
      page_has_instui_topnav
      @users = @context.users.where(show_user_services: true).order_by_sortable_name
      @users_hash = {}
      @users_order_hash = {}
      @users.each_with_index do |u, i|
        @users_hash[u.id] = u
        @users_order_hash[u.id] = i
      end
      @current_user_services = {}
      @current_user.user_services.select { |s| feature_and_service_enabled?(s.service) }.each { |s| @current_user_services[s.service] = s }
      @services = UserService.for_user(@users.except(:select, :order)).sort_by { |s| @users_order_hash[s.user_id] || CanvasSort::Last }
      @services = @services.select do |service|
        feature_and_service_enabled?(service.service.to_sym)
      end
      @services_hash = @services.to_a.each_with_object({}) do |item, hash|
        mapped = item.service
        hash[mapped] ||= []
        hash[mapped] << item
      end
    end
  end

  def roster_user_usage
    GuardRail.activate(:secondary) do
      if authorized_action(@context, @current_user, :read_reports)
        @user = @context.users.find(params[:user_id])
        contexts = [@context] + @user.group_memberships_for(@context).to_a
        @accesses = AssetUserAccess.for_user(@user).where(context: contexts).most_recent
        respond_to do |format|
          format.html do
            add_crumb(t("#crumbs.people", "People"), context_url(@context, :context_users_url))
            add_crumb(@user.short_name, context_url(@context, :context_user_url, @user))
            add_crumb(t("#crumbs.access_report", "Access Report"))
            set_active_tab "people"

            @accesses = @accesses.paginate(page: params[:page], per_page: 50)
            @last_activity_at = @context.enrollments.where(user_id: @user).maximum(:last_activity_at)
            @aua_expiration_date = AssetUserAccess.expiration_date
            js_env(context_url: context_url(@context, :context_user_usage_url, @user, format: :json),
                   accesses_total_pages: @accesses.total_pages)
            @accesses.reject!(&:bad_discussion_context?)
          end
          format.json do
            @accesses = Api.paginate(@accesses, self, polymorphic_url([@context, :user_usage], user_id: @user), default_per_page: 50)
            @accesses.reject!(&:bad_discussion_context?)
            render json: @accesses.map { |a| a.as_json(methods: %i[readable_name asset_class_name icon]) }
          end
        end
      end
    end
  end

  def roster_user
    if authorized_action(@context, @current_user, :read_roster)
      raise ActiveRecord::RecordNotFound unless Api::ID_REGEX.match?(params[:id])

      user_id = Shard.relative_id_for(params[:id], Shard.current, @context.shard)
      case @context
      when Course
        is_admin = @context.grants_right?(@current_user, session, :read_as_admin)
        scope = @context.enrollments_visible_to(@current_user, include_concluded: is_admin).where(user_id:)
        scope = scope.active_or_pending unless is_admin
        @membership = scope.first
        if @membership
          @enrollments = scope.to_a
          user = @membership&.user
          js_permissions = {
            can_manage_user_details: user.grants_right?(@current_user, :manage_user_details)
          }
          timezones = I18nTimeZone.all.map { |tz| { name: tz.name, name_with_hour_offset: tz.to_s } }
          default_timezone_name = @domain_root_account.try(:default_time_zone)&.name || "Mountain Time (US & Canada)"
          js_env({
                   COURSE_ID: @context.id,
                   USER_ID: user_id,
                   LAST_ATTENDED_DATE: @enrollments.first.last_attended_at,
                   course: {
                     id: @context.id,
                     hideSectionsOnCourseUsersPage: @context.sections_hidden_on_roster_page?(current_user: @current_user)
                   },
                   PERMISSIONS: js_permissions,
                   TIMEZONES: timezones,
                   DEFAULT_TIMEZONE_NAME: default_timezone_name
                 })

          log_asset_access(@membership, "roster", "roster")
        end
      when Group
        @membership = @context.group_memberships.active.where(user_id:).first
        @enrollments = []
      end

      @user = @membership&.user
      # rubocop:disable Rails/ActionControllerFlashBeforeRender
      unless @user
        case @context
        when Course
          flash[:error] = t("no_user.course", "That user does not exist or is not currently a member of this course")
        when Group
          flash[:error] = t("no_user.group", "That user does not exist or is not currently a member of this group")
        end
        redirect_to named_context_url(@context, :context_users_url)
        return
      end
      # rubocop:enable Rails/ActionControllerFlashBeforeRender

      js_env(CONTEXT_USER_DISPLAY_NAME: @user.short_name)

      js_bundle :user_name, "context_roster_user"
      css_bundle :roster_user, :pairing_code

      enable_profiles = @domain_root_account.enable_profiles?
      show_recent_messages_on_new_roster_user_page =
        Account.site_admin.feature_enabled?(:show_recent_messages_on_new_roster_user_page)
      if (!enable_profiles || (enable_profiles && show_recent_messages_on_new_roster_user_page)) &&
         @user.grants_right?(@current_user, session, :read_profile)

        @topics = @context.active_discussion_topics
                          .not_fully_anonymous
                          .reject { |dt| dt.locked_for?(@current_user, check_policies: true) }
        entries = DiscussionEntry.not_anonymous.all_for_user(@user).all_for_topics(@topics).newest_first
        filtered_entries = entries.select { |entry| entry.grants_right?(@current_user, session, :read) }

        @messages = filtered_entries.take(MAX_MESSAGES_ON_PROFILE)
      end

      if enable_profiles
        @user_data = profile_data(
          @user.profile,
          @current_user,
          session,
          ["links", "user_services"]
        )
        add_body_class "not-editing"

        add_crumb(t("#crumbs.people", "People"), context_url(@context, :context_users_url))
        add_crumb(@user.short_name, context_url(@context, :context_user_url, @user))
        set_active_tab "people"

        render :new_roster_user, stream: can_stream_template?
        return false
      end

      add_crumb(t("#crumbs.people", "People"), context_url(@context, :context_users_url))
      add_crumb(context_user_name(@context, @user), context_url(@context, :context_user_url, @user))
      set_active_tab "people"

      render stream: can_stream_template?
      true
    end
  end

  WORKFLOW_TYPES = %i[all_discussion_topics
                      assignment_groups
                      assignments
                      collaborations
                      context_modules
                      enrollments
                      groups
                      quizzes
                      rubrics
                      wiki_pages
                      rubric_associations_with_deleted].freeze
  ITEM_TYPES = WORKFLOW_TYPES + [:attachments, :all_group_categories].freeze
  def undelete_index
    if authorized_action(@context, @current_user, RoleOverride::GRANULAR_MANAGE_COURSE_CONTENT_PERMISSIONS)
      @item_types =
        WORKFLOW_TYPES.each_with_object([]) do |workflow_type, item_types|
          if @context.class.reflections.key?(workflow_type.to_s)
            item_types << @context.association(workflow_type).reader
          end
        end

      @deleted_items = @item_types.reduce([]) do |acc, scope|
        acc + scope.where(workflow_state: "deleted").limit(25).to_a
      end.reject { |item| item.is_a?(DiscussionTopic) && !item.restorable? }

      @deleted_items += @context.attachments.where(file_state: "deleted").limit(25).to_a

      can_delete_group_categories = @context.grants_right?(@current_user, :manage_groups_delete)
      can_delete_differentiation_tag_categories = @context.grants_right?(@current_user, :manage_tags_delete)
      undelete_scope = if can_delete_group_categories && can_delete_differentiation_tag_categories
                         @context.combined_group_and_differentiation_tag_categories
                       elsif can_delete_group_categories
                         @context.all_group_categories
                       elsif can_delete_differentiation_tag_categories
                         @context.all_differentiation_tag_categories
                       else
                         nil
                       end
      if undelete_scope.present?
        @deleted_items += undelete_scope.where.not(deleted_at: nil).limit(25).to_a
      end

      @deleted_items.sort_by { |item| item.read_attribute(:deleted_at) || item.created_at }.reverse
    end
  end

  def undelete_item
    if authorized_action(@context, @current_user, :manage_course_content_add)
      type = params[:asset_string].split("_")
      id = type.pop
      type = type.join("_")
      scope = @context
      scope = @context.wiki if type == "wiki_page"
      type = "all_discussion_topic" if type == "discussion_topic"
      type = "all_group_category" if type == "group_category"
      if %w[all_group_category group].include?(type) && !@context.grants_right?(@current_user, :manage_groups_delete)
        return render_unauthorized_action
      end

      type = type.pluralize
      type = "rubric_associations_with_deleted" if type == "rubric_associations"
      unless ITEM_TYPES.include?(type.to_sym) && scope.class.reflections.key?(type)
        raise "invalid type"
      end

      @item = scope.association(type).reader.find(id)
      @item.restore
      if @item.errors.any?
        return render json: @item.errors.full_messages, status: :forbidden
      end

      render json: @item
    end
  end

  def get_active_granular_enrollment_permissions(context)
    enrollment_granular_permissions_map = {
      add_teacher_to_course: "TeacherEnrollment",
      add_ta_to_course: "TaEnrollment",
      add_designer_to_course: "DesignerEnrollment",
      add_student_to_course: "StudentEnrollment",
      add_observer_to_course: "ObserverEnrollment"
    }
    enrollment_granular_permissions_map.select do |key, _|
      context.grants_right?(@current_user, session, key)
    end.values
  end
end
