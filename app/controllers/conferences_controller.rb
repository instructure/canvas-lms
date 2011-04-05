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
  before_filter :require_context
  add_crumb("Conferences") { |c| c.send(:named_context_url, c.instance_variable_get("@context"), :context_conferences_url) }
  before_filter { |c| c.active_tab = "conferences" }
  before_filter :require_config
  
  def index
    @conferences = @context.web_conferences.select{|c| c.grants_right?(@current_user, session, :read) }
    if authorized_action(@context, @current_user, :read)
      return unless tab_enabled?(@context.class::TAB_CONFERENCES)
      log_asset_access("conferences:#{@context.asset_string}", "conferences", "other")
      @users = @context.users
    end
  end
  
  def show
    get_conference
    if authorized_action(@conference, @current_user, :read)
      log_asset_access(@conference, "conferences", "conferences")
    end
  end
  
  def create
    if authorized_action(@context.web_conferences.new, @current_user, :create)
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
          format.html { redirect_to named_context_url(@context, :context_conference_url, @conference.id) }
          format.json { render :json => @conference.to_json(:permissions => {:user => @current_user, :session => session}) }
        else
          format.html { render :action => "new" }
          format.xml { render :xml => @conference.errors.to_xml }
          format.json { render :json => @conference.errors.to_json }
        end
      end
    end
  end
  
  def update
    get_conference
    if authorized_action(@conference, @current_user, :update)
      @conference.user ||= @current_user
      members = get_new_members
      respond_to do |format|
        if @conference.update_attributes(params[:web_conference].delete_if{|k,v| k.to_sym == :conference_type})
          # TODO: ability to dis-invite people
          members.uniq.each do |u|
            @conference.add_invitee(u)
          end
          format.html { redirect_to named_context_url(@context, :context_conference_url, @conference.id) }
          format.json { render :json => @conference.to_json(:permissions => {:user => @current_user, :session => session}) }
        else
          format.html { render :action => "edit" }
          format.xml { render :xml => @conference.errors.to_xml }
          format.json { render :json => @conference.errors.to_json }
        end
      end
    end
  end
  
  def join
    get_conference
    if authorized_action(@conference, @current_user, :join)
      unless @conference.valid_config?
        flash[:error] = "This type of conference is no longer enabled for this Canvas site"
        redirect_to named_context_url(@context, :context_conferences_url)
        return
      end
      if @conference.grants_right?(@current_user, session, :initiate) || @conference.active?(true)
        @conference.add_attendee(@current_user)
        @conference.restart if @conference.ended_at && @conference.grants_right?(@current_user, session, :initiate)
        log_asset_access(@conference, "conferences", "conferences", 'participate')
        @conference.touch
        if url = @conference.craft_url(@current_user, session, named_context_url(@context, :context_url, :include_host => true))
          redirect_to url
        else
          flash[:error] = "There was an error joining the conference"
          redirect_to named_context_url(@context, :context_url)
        end
      else
        flash[:notice] = "That conference is not currently active"
        redirect_to named_context_url(@context, :context_url)
      end
    end
  end
  
  def destroy
    get_conference
    if authorized_action(@conference, @current_user, :delete)
      @conference.destroy
      respond_to do |format|
        format.html { redirect_to named_context_url(@context, :context_conferences_url) }
        format.xml { head :ok }
        format.json { render :json => @conference.to_json }
      end      
    end
  end

  protected

  def require_config
    unless WebConference.config
      flash[:error] = "Web conferencing has not been enabled for this Canvas site"
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
