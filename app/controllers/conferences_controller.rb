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

class ConferencesController < ApplicationController
  include Api::V1::Conferences

  before_filter :require_context
  add_crumb(proc{ t '#crumbs.conferences', "Conferences"}) { |c| c.send(:named_context_url, c.instance_variable_get("@context"), :context_conferences_url) }
  before_filter { |c| c.active_tab = "conferences" }
  before_filter :require_config
  before_filter :reject_student_view_student
  before_filter :get_conference, :except => [:index, :create]

  def index
    @new_conferences, @concluded_conferences = @context.web_conferences.select { |conference|
      conference.grants_right?(@current_user, session, :read)
    }.partition { |conference|
      conference.ended_at.nil?
    }

    if authorized_action(@context, @current_user, :read)
      return unless tab_enabled?(@context.class::TAB_CONFERENCES)
      log_asset_access("conferences:#{@context.asset_string}", "conferences", "other")

      scope = @context.users
      if @context.respond_to?(:participating_typical_users)
        scope = @context.participating_typical_users
      end
      @users = scope.where("users.id<>?", @current_user).order(User.sortable_name_order_by_clause).all.uniq

      permissions = {:permissions => {:user => @current_user, :session => session}}
      # exposing the initial data as json embedded on page.
      js_env(
        current_conferences: conferences_json(@new_conferences, @context, @current_user, session),
        concluded_conferences: conferences_json(@concluded_conferences, @context, @current_user, session),
        default_conference: default_conference_json(@context, @current_user, session),
        conference_type_details: conference_types_json(WebConference.conference_types),
        users: @users.map{|u| {:id => u.id, :name => u.last_name_first}},
      )

    end
  end

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
      log_asset_access(@conference, "conferences", "conferences")
    end
  end

  def create
    if authorized_action(@context.web_conferences.new, @current_user, :create)
      params[:web_conference].try(:delete, :long_running)
      @conference = @context.web_conferences.build(params[:web_conference])
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
          format.json { render :json => WebConference.find(@conference).to_json(:permissions => {:user => @current_user, :session => session},
                                                                                :url => named_context_url(@context, :context_conference_url, @conference)) }
        else
          format.html { render :action => 'index' }
          format.json { render :json => @conference.errors.to_json, :status => :bad_request }
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
        if @conference.update_attributes(params[:web_conference])
          # TODO: ability to dis-invite people
          members.uniq.each do |u|
            @conference.add_invitee(u)
          end
          @conference.save
          format.html { redirect_to named_context_url(@context, :context_conference_url, @conference.id) }
          format.json { render :json => @conference.to_json(:permissions => {:user => @current_user, :session => session},
                                                            :url => named_context_url(@context, :context_conference_url, @conference)) }
        else
          format.html { render :action => "edit" }
          format.json { render :json => @conference.errors.to_json, :status => :bad_request }
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
        generate_new_page_view
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

  def close
    if authorized_action(@conference, @current_user, :close)
      if @conference.close
        render :json => @conference.to_json(:permissions => {:user => @current_user, :session => session},
                                            :url => named_context_url(@context, :context_conference_url, @conference))
      else
        render :json => @conference.errors.to_json
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
      @conference.destroy
      respond_to do |format|
        format.html { redirect_to named_context_url(@context, :context_conferences_url) }
        format.json { render :json => @conference.to_json }
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
      members += @context.users.find_all_by_id(ids).to_a
    else
      members += @context.users.to_a
    end
    members - @conference.invitees
  end

  def get_conference
    @conference = @context.web_conferences.find(params[:conference_id] || params[:id])
  end
  private :get_conference
end
