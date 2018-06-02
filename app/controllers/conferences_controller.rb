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

# @API Conferences
#
# API for accessing information on conferences.
#
# @model ConferenceRecording
#     {
#       "id": "ConferenceRecording",
#       "description": "",
#       "properties": {
#         "duration_minutes": {
#           "example": 0,
#           "type": "integer"
#         },
#         "title": {
#           "example": "course2: Test conference 3 [170]_0",
#           "type": "string"
#         },
#         "updated_at": {
#           "example": "2013-12-12T16:09:33.903-07:00",
#           "type": "datetime"
#         },
#         "created_at": {
#           "example": "2013-12-12T16:09:09.960-07:00",
#           "type": "datetime"
#         },
#         "playback_url": {
#           "example": "http://example.com/recording_url",
#           "type": "string"
#         }
#       }
#     }
#
# @model Conference
#     {
#       "id": "Conference",
#       "description": "",
#       "properties": {
#         "id": {
#           "description": "The id of the conference",
#           "example": 170,
#           "type": "integer"
#         },
#         "conference_type": {
#           "description": "The type of conference",
#           "example": "AdobeConnect",
#           "type": "string"
#         },
#         "conference_key": {
#           "description": "The 3rd party's ID for the conference",
#           "example": "abcdjoelisgreatxyz",
#           "type": "string"
#         },
#         "description": {
#           "description": "The description for the conference",
#           "example": "Conference Description",
#           "type": "string"
#         },
#         "duration": {
#           "description": "The expected duration the conference is supposed to last",
#           "example": 60,
#           "type": "integer"
#         },
#         "ended_at": {
#           "description": "The date that the conference ended at, null if it hasn't ended",
#           "example": "2013-12-13T17:23:26Z",
#           "type": "datetime"
#         },
#         "started_at": {
#           "description": "The date the conference started at, null if it hasn't started",
#           "example": "2013-12-12T23:02:17Z",
#           "type": "datetime"
#         },
#         "title": {
#           "description": "The title of the conference",
#           "example": "Test conference",
#           "type": "string"
#         },
#         "users": {
#           "description": "Array of user ids that are participants in the conference",
#           "example": [1, 7, 8, 9, 10],
#           "type": "array",
#           "items": { "type": "integer"}
#         },
#         "has_advanced_settings": {
#           "description": "True if the conference type has advanced settings.",
#           "example": false,
#           "type": "boolean"
#         },
#         "long_running": {
#           "description": "If true the conference is long running and has no expected end time",
#           "example": false,
#           "type": "boolean"
#         },
#         "user_settings": {
#           "description": "A collection of settings specific to the conference type",
#           "example": {"record": true},
#           "type": "object"
#         },
#         "recordings": {
#           "description": "A List of recordings for the conference",
#           "type": "array",
#           "items": { "$ref": "ConferenceRecording" }
#         },
#         "url": {
#           "description": "URL for the conference, may be null if the conference type doesn't set it",
#           "type": "string"
#         },
#         "join_url": {
#           "description": "URL to join the conference, may be null if the conference type doesn't set it",
#           "type": "string"
#         }
#       }
#     }
#
class ConferencesController < ApplicationController
  include Api::V1::Conferences

  before_action :require_context
  skip_before_action :load_user, :only => [:recording_ready]

  add_crumb(proc{ t '#crumbs.conferences', "Conferences"}) do |c|
    c.send(:named_context_url, c.instance_variable_get("@context"), :context_conferences_url)
  end

  before_action { |c| c.active_tab = "conferences" }
  before_action :require_config
  before_action :reject_student_view_student
  before_action :get_conference, :except => [:index, :create]

  # @API List conferences
  # Retrieve the paginated list of conferences for this context
  #
  # This API returns a JSON object containing the list of conferences,
  # the key for the list of conferences is "conferences"
  #
  # @example_request
  #     curl 'https://<canvas>/api/v1/courses/<course_id>/conferences' \
  #         -H "Authorization: Bearer <token>"
  #
  #     curl 'https://<canvas>/api/v1/groups/<group_id>/conferences' \
  #         -H "Authorization: Bearer <token>"
  #
  # @returns [Conference]
  def index
    return unless authorized_action(@context, @current_user, :read)
    return unless tab_enabled?(@context.class::TAB_CONFERENCES)
    return unless @current_user
    conferences = @context.grants_right?(@current_user, :manage_content) ?
      @context.web_conferences.active :
      @current_user.web_conferences.active.shard(@context.shard).where(context_type: @context.class.to_s, context_id: @context.id)
    conferences = conferences.with_config.order("created_at DESC, id DESC")
    api_request? ? api_index(conferences) : web_index(conferences)
  end

  def api_index(conferences)
    route = polymorphic_url([:api_v1, @context, :conferences])
    web_conferences = Api.paginate(conferences, self, route)
    render json: api_conferences_json(web_conferences, @current_user, session)
  end
  protected :api_index

  def web_index(conferences)
    @new_conferences, @concluded_conferences = conferences.partition { |conference|
      conference.ended_at.nil?
    }
    log_asset_access([ "conferences", @context ], "conferences", "other")
    case @context
    when Course
      @users = User.where(:id => @context.current_enrollments.not_fake.active_by_date.where.not(:user_id => @current_user).select(:user_id)).
        order(User.sortable_name_order_by_clause).to_a
    when Group
      @users = @context.participating_users_in_context.where("users.id<>?", @current_user).order(User.sortable_name_order_by_clause).to_a.uniq
    else
      @users = @context.users.where("users.id<>?", @current_user).order(User.sortable_name_order_by_clause).to_a.uniq
    end
    # exposing the initial data as json embedded on page.
    js_env(
      current_conferences: ui_conferences_json(@new_conferences, @context, @current_user, session),
      concluded_conferences: ui_conferences_json(@concluded_conferences, @context, @current_user, session),
      default_conference: default_conference_json(@context, @current_user, session),
      conference_type_details: conference_types_json(WebConference.conference_types),
      users: @users.map { |u| {:id => u.id, :name => u.last_name_first} },
    )
    set_tutorial_js_env
    flash[:error] = t('Some conferences on this page are hidden because of errors while retrieving their status') if @errors
  end
  protected :web_index

  def show
    if authorized_action(@conference, @current_user, :read)
      if params[:external_url]
        urls = @conference.external_url_for(params[:external_url], @current_user, params[:url_id])
        if request.xhr?
          return render :json => urls
        elsif urls.size == 1
          return redirect_to(urls.first[:url])
        end
      end
      return redirect_to course_conferences_url(@context, :anchor => "conference_#{@conference.id}")
    end
  end

  def create
    if authorized_action(@context.web_conferences.temp_record, @current_user, :create)
      @conference = @context.web_conferences.build(conference_params)
      @conference.settings[:default_return_url] = named_context_url(@context, :context_url, :include_host => true)
      @conference.user = @current_user
      members = get_new_members
      respond_to do |format|
        if @conference.save
          @conference.add_initiator(@current_user)
          members.uniq.each do |u|
            @conference.add_invitee(u)
          end
          @conference.save
          format.html { redirect_to named_context_url(@context, :context_conference_url, @conference.id) }
          format.json { render :json => WebConference.find(@conference.id).as_json(:permissions => {:user => @current_user, :session => session},
                                                                                :url => named_context_url(@context, :context_conference_url, @conference)) }
        else
          format.html { render :index }
          format.json { render :json => @conference.errors, :status => :bad_request }
        end
      end
    end
  end

  def update
    if authorized_action(@conference, @current_user, :update)
      @conference.user ||= @current_user
      members = get_new_members
      respond_to do |format|
        params[:web_conference].try(:delete, :long_running)
        params[:web_conference].try(:delete, :conference_type)
        if @conference.update_attributes(conference_params)
          # TODO: ability to dis-invite people
          members.uniq.each do |u|
            @conference.add_invitee(u)
          end
          @conference.save
          format.html { redirect_to named_context_url(@context, :context_conference_url, @conference.id) }
          format.json { render :json => @conference.as_json(:permissions => {:user => @current_user, :session => session},
                                                            :url => named_context_url(@context, :context_conference_url, @conference)) }
        else
          format.html { render :edit }
          format.json { render :json => @conference.errors, :status => :bad_request }
        end
      end
    end
  end

  def join
    if authorized_action(@conference, @current_user, :join)
      unless @conference.valid_config?
        flash[:error] = t(:type_disabled_error, "This type of conference is no longer enabled for this Canvas site")
        redirect_to named_context_url(@context, :context_conferences_url)
        return
      end
      if @conference.grants_right?(@current_user, session, :initiate) || @conference.grants_right?(@current_user, session, :resume) || @conference.active?(true)
        @conference.add_attendee(@current_user)
        @conference.restart if @conference.ended_at && @conference.grants_right?(@current_user, session, :initiate)
        log_asset_access(@conference, "conferences", "conferences", 'participate')
        if url = @conference.craft_url(@current_user, session, named_context_url(@context, :context_url, :include_host => true))
          redirect_to url
        else
          flash[:error] = t(:general_error, "There was an error joining the conference")
          redirect_to named_context_url(@context, :context_url)
        end
      else
        flash[:notice] = t(:inactive_error, "That conference is not currently active")
        redirect_to named_context_url(@context, :context_url)
      end
    end
  rescue StandardError => e
    flash[:error] = t(:general_error_with_message, "There was an error joining the conference. Message: '%{message}'", :message => e.message)
    redirect_to named_context_url(@context, :context_conferences_url)
  end

  def recording_ready
    secret = @conference.config[:secret_dec]
    begin
      signed_params = Canvas::Security.decode_jwt(params[:signed_parameters], [secret])
      if signed_params[:meeting_id] == @conference.conference_key
        @conference.recording_ready!
        render  json: [], status: :accepted
      else
        render json: signed_id_invalid_json, status: :unprocessable_entity
      end
    rescue Canvas::Security::InvalidToken
      render json: invalid_jwt_token_json, status: :unauthorized
    end
  end

  def close
    if authorized_action(@conference, @current_user, :close)
      unless @conference.active?
        return render :json => { :message => 'conference is not active', :status => :bad_request }
      end

      if @conference.close
        render :json => @conference.as_json(:permissions => {:user => @current_user, :session => session},
                                            :url => named_context_url(@context, :context_conference_url, @conference))
      else
        render :json => @conference.errors
      end
    end
  end

  def settings
    if authorized_action(@conference, @current_user, :update)
      if @conference.has_advanced_settings?
        redirect_to @conference.admin_settings_url(@current_user)
      else
        flash[:error] = t(:no_settings_error, "The conference does not have an advanced settings page")
        redirect_to named_context_url(@context, :context_conference_url, @conference.id)
      end
    end
  end

  def destroy
    if authorized_action(@conference, @current_user, :delete)
      @conference.transaction do
        @conference.web_conference_participants.scope.delete_all
        @conference.destroy
      end
      respond_to do |format|
        format.html { redirect_to named_context_url(@context, :context_conferences_url) }
        format.json { render :json => @conference }
      end
    end
  end

  def recording
    if authorized_action(@conference, @current_user, :read)
      @response = @conference.recording(params[:recording_id]) || {}
      respond_to do |format|
        format.html { redirect_to named_context_url(@context, :context_conferences_url) }
        format.json { render :json => @response }
      end
    end
  end

  def delete_recording
    if authorized_action(@conference, @current_user, :delete)
      @response = @conference.delete_recording(params[:recording_id])
      respond_to do |format|
        format.html { redirect_to named_context_url(@context, :context_conferences_url) }
        format.json { render :json => @response, :status => :ok }
      end
    end
  end

  protected

  def require_config
    unless WebConference.config
      flash[:error] = t('#conferences.disabled_error', "Web conferencing has not been enabled for this Canvas site")
      redirect_to named_context_url(@context, :context_url)
    end
  end

  def get_new_members
    members = [@current_user]

    if params[:user] && params[:user][:all] != '1'
      ids = []
      params[:user].each do |id, val|
        ids << id.to_i if val == '1'
      end
    else
      ids = @context.user_ids
    end

    if @context.is_a? Course
      members += @context.participating_users(ids).to_a
    else
      members += @context.participating_users_in_context(ids).to_a
    end

    members - @conference.invitees
  end

  private
  def get_conference
    @conference = @context.web_conferences.find(params[:conference_id] || params[:id])
  end

  def conference_params
    params.require(:web_conference).
      permit(:title, :duration, :description, :conference_type, :user_settings => strong_anything)
  end
end
