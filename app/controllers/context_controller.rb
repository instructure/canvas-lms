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

class ContextController < ApplicationController
  include SearchHelper

  before_filter :require_context, :except => [:inbox, :create_media_object, :kaltura_notifications, :media_object_redirect, :media_object_inline, :media_object_thumbnail, :object_snippet]
  before_filter :require_user, :only => [:inbox, :report_avatar_image]
  before_filter :reject_student_view_student, :only => [:inbox]
  protect_from_forgery :except => [:kaltura_notifications, :object_snippet]

  def create_media_object
    @context = Context.find_by_asset_string(params[:context_code])
    if authorized_action(@context, @current_user, :read)
      if params[:id] && params[:type] && @context.respond_to?(:media_objects)
        self.extend TextHelper
        @media_object = @context.media_objects.where(media_id: params[:id], media_type: params[:type]).first_or_initialize
        @media_object.title = CanvasTextHelper.truncate_text(params[:title], :max_length => 255) if params[:title]
        @media_object.user = @current_user
        @media_object.media_type = params[:type]
        @media_object.root_account_id = @domain_root_account.id if @domain_root_account && @media_object.respond_to?(:root_account_id)
        @media_object.user_entered_title = CanvasTextHelper.truncate_text(params[:user_entered_title], :max_length => 255) if params[:user_entered_title] && !params[:user_entered_title].empty?
        @media_object.save
      end
      render :json => @media_object
    end
  end

  def media_object_inline
    @show_embedded_chat = false
    @show_left_side = false
    @show_right_side = false
    @media_object = MediaObject.by_media_id(params[:id]).first
    js_env(MEDIA_OBJECT_ID: params[:id],
           MEDIA_OBJECT_TYPE: @media_object ? @media_object.media_type.to_s : 'video')
    render
  end

  def media_object_redirect
    mo = MediaObject.by_media_id(params[:id]).first
    mo.viewed! if mo
    config = CanvasKaltura::ClientV3.config
    if config
      redirect_to CanvasKaltura::ClientV3.new.assetSwfUrl(params[:id])
    else
      render :text => t(:media_objects_not_configured, "Media Objects not configured")
    end
  end

  def media_object_thumbnail
    media_id = params[:id]
    # we prefer using the MediaObject if it exists (so that it can give us
    # a different media_id if it wants to), but we will also use the provided
    # media id directly if we can't find a MediaObject. (They don't always get
    # created yet.)
    mo = MediaObject.by_media_id(media_id).first
    width = params[:width]
    height = params[:height]
    type = (params[:type].presence || 2).to_i
    config = CanvasKaltura::ClientV3.config
    if config
      redirect_to CanvasKaltura::ClientV3.new.thumbnail_url(mo.try(:media_id) || media_id,
                                                      :width => width,
                                                      :height => height,
                                                      :type => type),
                  :status => 301
    else
      render :text => t(:media_objects_not_configured, "Media Objects not configured")
    end
  end

  def kaltura_notifications
    request_params = request.request_parameters.to_a.sort_by{|k, v| k }.select{|k, v| k != 'sig' }
    logger.info('=== KALTURA NOTIFICATON ===')
    logger.info(request_params.to_yaml)
    if params[:signed_fields]
      valid_fields = params[:signed_fields].split(",")
      request_params = request_params.select{|k, v| valid_fields.include?(k.to_s) }
    end
    str = ""
    request_params.each do |k, v|
      str += k.to_s + v.to_s
    end
    hash = Digest::MD5.hexdigest(CanvasKaltura::ClientV3.config['secret_key'] + str)
    if hash == params[:sig]
      notifications = {}
      if params[:multi_notification] != 'true'
        notifications[0] = request.request_parameters
      else
        request.request_parameters.each do |k, value|
          key = k.to_s
          if match = key.match(/\Anot([^_]*)_(.*)\z/)
            num = match[1].to_s
            property = match[2].to_s
            notifications[num] ||= {}
            notifications[num][property] = value
          end
        end
      end
      notifications.each do |key, notification|
        if notification[:notification_type] == 'entry_add'
          entry_id = notification[:entry_id]
          mo = MediaObject.where(media_id: entry_id).first_or_initialize
          if !mo.new_record? || (notification[:partner_data] && !notification[:partner_data].empty?)
            data = JSON.parse(notification[:partner_data]) rescue nil
            if data && data['root_account_id'] && data['context_code']
              context = Context.find_by_asset_string(data['context_code'])
              context = nil unless context.respond_to?(:is_a_context?) && context.is_a_context?
              user = User.where(id: data['puser_id'].split("_").first).first if data['puser_id'].present?

              mo.context ||= context
              mo.user ||= user
              mo.save!
              mo.send_later(:retrieve_details)
            end
          end
        elsif notification[:notification_type] == 'entry_delete'
          entry_id = notification[:entry_id]
          mo = MediaObject.by_media_id(entry_id).first
          mo.destroy_without_destroying_attachment
        end
      end
      logger.info(notifications.to_yaml)
      render :text => "ok"
    else
      logger.info("md5 should have been #{hash} but was #{params[:sig]}")
      render :text => "failure"
    end
  rescue => e
    logger.warn("=== KALTURA NOTIFICATON ERROR ===")
    logger.warn(e.to_s)
    logger.warn(e.backtrace.join("\n"))
    render :text => "failure"
  end

  # safely render object and embed tags as part of user content, by using a
  # iframe pointing to the separate files domain that doesn't contain a user's
  # session. see lib/user_content.rb and the user_content calls throughout the
  # views.
  def object_snippet
    if HostUrl.has_file_host? && !HostUrl.is_file_host?(request.host_with_port)
      return render(:nothing => true, :status => 400)
    end

    @snippet = params[:object_data] || ""

    unless Canvas::Security.verify_hmac_sha1(params[:s], @snippet)
      return render :nothing => true, :status => 400
    end

    # http://blogs.msdn.com/b/ieinternals/archive/2011/01/31/controlling-the-internet-explorer-xss-filter-with-the-x-xss-protection-http-header.aspx
    # recent versions of IE and Webkit have added client-side XSS prevention
    # measures. if data that includes potentially dangerous strings like
    # "<script..." or "<object..." is sent to the server and then that exact
    # same string is rendered in the html response, the browser will refuse to
    # render that part of the content. this header tells the browser that we're
    # doing it on purpose, so skip the XSS detection.
    response['X-XSS-Protection'] = '0'
    @snippet = Base64.decode64(@snippet)
    render :layout => false
  end

  def inbox
    redirect_to conversations_url, :status => :moved_permanently
  end

  def roster
    return unless authorized_action(@context, @current_user, [:read_roster, :manage_students, :manage_admin_users])
    log_asset_access("roster:#{@context.asset_string}", 'roster', 'other')

    if @context.is_a?(Course)
      if @context.concluded?
        sections = @context.course_sections.active.select([:id, :course_id, :name, :end_at, :restrict_enrollments_to_section_dates]).preload(:course)
        concluded_sections = sections.select{|s| s.concluded?}.map{|s| "section_#{s.id}"}
      else
        sections = @context.course_sections.active.select([:id, :name])
        concluded_sections = []
      end

      all_roles = Role.role_data(@context, @current_user)
      load_all_contexts(:context => @context)
      js_env({
        :ALL_ROLES => all_roles,
        :SECTIONS => sections.map { |s| { :id => s.id.to_s, :name => s.name} },
        :CONCLUDED_SECTIONS => concluded_sections,
        :USER_LISTS_URL => polymorphic_path([@context, :user_lists], :format => :json),
        :ENROLL_USERS_URL => course_enroll_users_url(@context),
        :SEARCH_URL => search_recipients_url,
        :COURSE_ROOT_URL => "/courses/#{ @context.id }",
        :CONTEXTS => @contexts,
        :resend_invitations_url => course_re_send_invitations_url(@context),
        :permissions => {
          :manage_students => (manage_students = @context.grants_right?(@current_user, session, :manage_students)),
          :manage_admin_users => (manage_admins = @context.grants_right?(@current_user, session, :manage_admin_users)),
          :add_users => manage_students || manage_admins,
          :read_reports => @context.grants_right?(@current_user, session, :read_reports)
        },
        :course => {
          :id => @context.id,
          :completed => @context.completed?,
          :soft_concluded => @context.soft_concluded?,
          :concluded => @context.concluded?,
          :teacherless => @context.teacherless?,
          :available => @context.available?,
          :pendingInvitationsCount => @context.invited_count_visible_to(@current_user)
        }
      })
    elsif @context.is_a?(Group)
      @users         = @context.participating_users.order_by_sortable_name.uniq
      @primary_users = { t('roster.group_members', 'Group Members') => @users }
      if course = @context.context.try(:is_a?, Course) && @context.context
        @secondary_users = { t('roster.teachers_and_tas', 'Teachers & TAs') => course.instructors.order_by_sortable_name.uniq }
      end
    end

    @secondary_users ||= {}
    @groups = @context.groups.active rescue []
  end

  def prior_users
    if authorized_action(@context, @current_user, [:manage_students, :manage_admin_users, :read_prior_roster])
      @prior_users = @context.prior_users.
        by_top_enrollment.merge(Enrollment.not_fake).
        paginate(:page => params[:page], :per_page => 20)

      users = @prior_users.index_by(&:id)
      if users.present?
        # put the relevant prior enrollment on each user
        @context.prior_enrollments.where({:user_id => users.keys}).
          top_enrollment_by(:user_id, :student).
          each { |e| users[e.user_id].prior_enrollment = e }
      end
    end
  end

  def roster_user_services
    if authorized_action(@context, @current_user, :read_roster)
      @users = @context.users.where(show_user_services: true).order_by_sortable_name
      @users_hash = {}
      @users_order_hash = {}
      @users.each_with_index{|u, i| @users_hash[u.id] = u; @users_order_hash[u.id] = i }
      @current_user_services = {}
      @current_user.user_services.each{|s| @current_user_services[s.service] = s }
      @services = UserService.for_user(@users.except(:select, :order)).sort_by{|s| @users_order_hash[s.user_id] || CanvasSort::Last}
      @services = @services.select{|service|
        !UserService.configured_service?(service.service) || feature_and_service_enabled?(service.service.to_sym)
      }
      @services_hash = @services.to_a.inject({}) do |hash, item|
        mapped = item.service
        hash[mapped] ||= []
        hash[mapped] << item
        hash
      end
    end
  end

  def roster_user_usage
    if authorized_action(@context, @current_user, :read_reports)
      @user = @context.users.find(params[:user_id])
      @accesses = AssetUserAccess.for_user(@user).for_context(@context).most_recent
      respond_to do |format|
        format.html do
          @accesses = @accesses.paginate(page: params[:page], per_page: 50)
          js_env(context_url: context_url(@context, :context_user_usage_url, @user, :format => :json),
                 accesses_total_pages: @accesses.total_pages)
        end
        format.json do
          @accesses = Api.paginate(@accesses, self, polymorphic_url([@context, :user_usage], user_id: @user), default_per_page: 50)
          render :json => @accesses.map{ |a| a.as_json(methods: [:readable_name, :asset_class_name]) }
        end
      end
    end
  end

  def roster_user
    if authorized_action(@context, @current_user, :read_roster)
      if params[:id] !~ Api::ID_REGEX
        # todo stop generating an error report and fix the bad input
        ErrorReport.log_error('invalid_user_id',
                              {message: "invalid user_id in ContextController::roster_user",
                               current_user_id: @current_user.id,
                               current_user_name: @current_user.sortable_name}.
                                merge(ErrorReport.useful_http_env_stuff_from_request(request))
        )
        raise ActiveRecord::RecordNotFound
      end
      user_id = Shard.relative_id_for(params[:id], Shard.current, @context.shard)
      if @context.is_a?(Course)
        @membership = @context.enrollments.where(user_id: user_id).first
        log_asset_access(@membership, "roster", "roster")
      elsif @context.is_a?(Group)
        @membership = @context.group_memberships.where(user_id: user_id).first
      end
      @user = @membership.user rescue nil
      if !@user
        if @context.is_a?(Course)
          flash[:error] = t('no_user.course', "That user does not exist or is not currently a member of this course")
        elsif @context.is_a?(Group)
          flash[:error] = t('no_user.group', "That user does not exist or is not currently a member of this group")
        end
        redirect_to named_context_url(@context, :context_users_url)
        return
      end

      @topics = @context.discussion_topics.active.reject{|a| a.locked_for?(@current_user, :check_policies => true) }
      @entries = []
      @topics.each do |topic|
        @entries << topic if topic.user_id == @user.id
        @entries.concat topic.discussion_entries.active.where(user_id: @user)
      end
      @entries = @entries.sort_by {|e| e.created_at }
      @enrollments = @context.enrollments.for_user(@user) rescue []
      @messages = @entries
      @messages = @messages.select{|m| m.grants_right?(@current_user, session, :read) }.sort_by{|e| e.created_at }.reverse

      if @domain_root_account.enable_profiles?
        @user_data = profile_data(
          @user.profile,
          @current_user,
          session,
          ['links', 'user_services']
        )
        render :action => :new_roster_user
        return false
      end
      true
    end
  end

  def undelete_index
    if authorized_action(@context, @current_user, :manage_content)
      @item_types = [:all_discussion_topics, :assignments, :assignment_groups, :enrollments,
                     :rubrics, :collaborations, :quizzes, :context_modules].map {|assoc| @context.send(assoc) if @context.respond_to?(assoc)}.compact

      @item_types << @context.wiki.wiki_pages if @context.respond_to? :wiki
      @deleted_items = []
      @item_types.each do |scope|
        @deleted_items += scope.where(:workflow_state => 'deleted').limit(25).all
      end
      @deleted_items += @context.attachments.where(:file_state => 'deleted').limit(25).all
      @deleted_items.sort_by{|item| item.read_attribute(:deleted_at) || item.created_at }.reverse
    end
  end

  def undelete_item
    if authorized_action(@context, @current_user, :manage_content)
      type = params[:asset_string].split("_")
      id = type.pop
      type = type.join("_")
      scope = @context
      scope = @context.wiki if type == 'wiki_page'
      type = 'all_discussion_topic' if type == 'discussion_topic'
      @item = scope.send(type.pluralize).find(id)
      @item.restore
      render :json => @item
    end
  end
end
