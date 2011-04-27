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

class CommunicationChannelsController < ApplicationController
  before_filter :require_user, :only => [:create, :show, :edit, :update, :merge, :try_merge, :confirm]
  
  def create
    if params[:pseudonym][:unique_id]
      params[:pseudonym][:path] = params[:pseudonym][:unique_id]
      params[:pseudonym][:path_type] = params[:path_type] || "email"
    end
    if !params[:pseudonym][:password]
      @existing_pseudonym = @current_user.pseudonyms.active.select{|p| p.account == Account.default }.first
    end
    params[:pseudonym][:account] = @domain_root_account
    if params[:build_pseudonym]
      @pseudonym = @current_user.pseudonyms.build(params[:pseudonym])
      @pseudonym.generate_temporary_password if !params[:pseudonym][:password] 
      if !@pseudonym.valid?
        respond_to do |format|
          format.html { render :action => :new }
          format.json { render :json => @pseudonym.errors.to_json }
        end
        return
      end
    end
    @cc = @current_user.communication_channels.build(:path => params[:pseudonym][:path], :path_type => (params[:path_type] || 'email'), :build_pseudonym_on_confirm => params[:build_pseudonym] == '1')
    if @cc.save
      @cc.send_confirmation!
      respond_to do |format|
        flash[:notice] = "Contact method registered!"
        format.html { redirect_to profile_url }
        format.json { render :json => @cc.to_json(:only => [:id, :user_id, :path, :path_type], :include => {:pseudonym => {:only => [:id, :unique_id]}}) }
      end
    else
      respond_to do |format|
        format.html { render :action => :new }
        format.json { render :json => @cc.errors.to_json }
      end
    end
  end
  
  def confirm
    id = params[:communication_channel_id]
    nonce = params[:nonce]
    cc = @current_user.communication_channels.find_by_id_and_confirmation_code(id, nonce) if id.present?
    # cc = nil if cc && cc.confirmation_code != nonce
    if cc
      @communication_channel = cc
      if cc.active? || cc.confirm
        flash[:notice] = "Registration confirmed."
        @current_user.register
        respond_to do |format|
          format.html { redirect_to profile_url }
          format.json { render :json => cc.to_json(:except => [:confirmation_code] ) }
        end
      else
        @failed = "Can't Confirm"
      end
    else
      @failed = "Invalid Confirmation"
    end
    if @failed
      #flash[:notice] = "Registration failed."
      respond_to do |format|
        flash[:error] = "Confirmation failed"
        format.html { redirect_to profile_url }
        format.json { render :json => {:error => @failed}.to_json, :status => :bad_request }
      end
    end
  end
  
  def try_merge
    @ccs = CommunicationChannel.find_all_by_path(params[:path] || params[:communication_channel][:path]).sort_by{|cc| cc.active? ? 0 : 1 }
    @cc = @ccs.first
    respond_to do |format|
      if @cc
        @cc.send_merge_notification!
        format.json { render :json => @cc.to_json }
        format.html
      else
        flash[:error] = "Email address not found"
        format.json { render :json => {:errors => {:base => "Email address not found"}} }
        format.html { redirect_to profile_url }
      end
    end
  end
  
  def merge
    @cc = if params[:communication_channel_id].present?
      CommunicationChannel.find_by_id_and_confirmation_code_and_path_type(params[:communication_channel_id], params[:code], 'email')
    end
    if @cc.user_id == @current_user.id
      flash[:notice] = "You have already claimed that email address"
      redirect_to profile_url
      return
    end
    if !params[:communication_channel]
      render
    else
      success = false
      if @cc && params[:communication_channel] && params[:communication_channel][:event]
        if params[:communication_channel][:event] == 'merge_users'
          if @cc.user.pseudonyms.all?{|p| p.never_logged_in? }
            @cc.user.move_to_user(@current_user)
            flash[:notice] = "User accounts successfully merged!"
            success = true
          else
            flash[:error] = "User accounts could not be merged."
          end
        elsif params[:communication_channel][:event] == 'claim_channel'
          if @cc.user.communication_channels.email.unretired.count > 1
            @cc.move_to_user(@current_user)
            flash[:notice] = "Email address successfully claimed!"
            success = true
          else
            flash[:error] = "Email address could not be claimed."
          end
        end
      end
      if !success
        flash[:notice] = nil
        flash[:error] = "Failed to claim the email address"
        flash[:error] = "Failed to merge users" if params[:communication_channel] && params[:communication_channel][:event] == 'merge_users'
      end
      redirect_to profile_url
    end
  end

  def destroy
    @cc = @current_user.communication_channels.find_by_id(params[:id]) if params[:id]
    if !@cc || @cc.destroy
      render :json => @cc.to_json
    else
      render :json => @cc.errors.to_json, :status => :bad_request
    end
  end
  
end
