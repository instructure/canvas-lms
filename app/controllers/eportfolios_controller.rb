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

class EportfoliosController < ApplicationController
  include EportfolioPage
  before_filter :require_user, :only => [:index, :user_index]
  before_filter :reject_student_view_student
  
  def index
    user_index
  end
  
  def user_index
    @context = @current_user.profile
    return unless tab_enabled?(UserProfile::TAB_EPORTFOLIOS)
    @active_tab = "eportfolios"
    add_crumb(@current_user.short_name, user_profile_url(@current_user))
    add_crumb(t(:crumb, "ePortfolios"))
    @portfolios = @current_user.eportfolios.active.order(:updated_at).all
    render :action => 'user_index'
  end
  
  def create
    if authorized_action(Eportfolio.new, @current_user, :create)
      @portfolio = @current_user.eportfolios.build(params[:eportfolio])
      respond_to do |format|
        if @portfolio.save
          @portfolio.ensure_defaults
          flash[:notice] = t('notices.created', "Porfolio successfully created")
          format.html { redirect_to eportfolio_url(@portfolio) }
          format.json { render :json => @portfolio.as_json(:permissions => {:user => @current_user, :session => session}) }
        else
          format.html { render :action => "new" }
          format.json { render :json => @portfolio.errors, :status => :bad_request }
        end
      end
    end
  end
  
  def show
    @portfolio = Eportfolio.active.find(params[:id])
    if params[:verifier] == @portfolio.uuid
      session[:eportfolio_ids] ||= []
      session[:eportfolio_ids] << @portfolio.id
      session[:permissions_key] = CanvasUUID.generate
    end
    if authorized_action(@portfolio, @current_user, :read)
      @portfolio.ensure_defaults
      @category = @portfolio.eportfolio_categories.first
      @page = @category.eportfolio_entries.first
      @owner_view = @portfolio.user == @current_user && params[:view] != 'preview'
      if @owner_view
        @used_submission_ids = []
        @portfolio.eportfolio_entries.each do |entry|
          entry.content_sections.each do |s|
            if s.is_a?(Hash) && s[:section_type] == "submission"
              @used_submission_ids << s[:submission_id].to_i
            end
          end
        end
      end
      @show_left_side = true
      eportfolio_page_attributes
      if @current_user
        # if profiles are enabled and I can message the portfolio's owner, link
        # to their profile
        @owner_url = user_profile_url(@portfolio.user) if @domain_root_account.enable_profiles? && @current_user.load_messageable_user(@portfolio.user)

        # otherwise, if I'm the portfolio's owner (implying I can message
        # myself, so therefore profiles just aren't enabled), link to my
        # profile
        @owner_url ||= profile_url if @current_user == @portfolio.user

        # otherwise, if  I can otherwise view the user, link directly to them
        @owner_url ||= user_url(@portfolio.user) if @portfolio.user.grants_right?(@current_user, :view_statistics)

        js_env :folder_id => Folder.unfiled_folder(@current_user).id,
               :context_code => @current_user.asset_string
      end
      render :template => "eportfolios/show"
    end
  end
  
  def update
    @portfolio = Eportfolio.find(params[:id])
    if authorized_action(@portfolio, @current_user, :update)
      respond_to do |format|
        if @portfolio.update_attributes(params[:eportfolio])
          @portfolio.ensure_defaults
          flash[:notice] = t('notices.updated', "Porfolio successfully updated")
          format.html { redirect_to eportfolio_url(@portfolio) }
          format.json { render :json => @portfolio.as_json(:permissions => {:user => @current_user, :session => session}) }
        else
          format.html { render :action => "edit" }
          format.json { render :json => @portfolio.errors, :status => :bad_request }
        end
      end
    end
  end
  
  def destroy
    @portfolio = Eportfolio.find(params[:id])
    if authorized_action(@portfolio, @current_user, :delete)
      respond_to do |format|
        if @portfolio.destroy
          flash[:notice] = t('notices.deleted', "Portfolio successfully deleted")
          format.html { redirect_to user_profile_url(@current_user) }
          format.json { render :json => @portfolio }
        else
          format.html { render :action => "delete" }
          format.json { render :json => @portfolio.errors, :status => :bad_request }
        end
      end
    end
  end
  
  def reorder_categories
    @portfolio = Eportfolio.find(params[:eportfolio_id])
    if authorized_action(@portfolio, @current_user, :update)
      @portfolio.eportfolio_categories.build.update_order(params[:order].split(","))
      render :json => @portfolio.eportfolio_categories.map{|c| [c.id, c.position]}, :status => :ok
    end
  end
  
  def reorder_entries
    @portfolio = Eportfolio.find(params[:eportfolio_id])
    if authorized_action(@portfolio, @current_user, :update)
      @category = @portfolio.eportfolio_categories.find(params[:eportfolio_category_id])
      @category.eportfolio_entries.build.update_order(params[:order].split(","))
      render :json => @portfolio.eportfolio_entries.map{|c| [c.id, c.position]}, :status => :ok
    end
  end
  
  def export
    zip_filename = "eportfolio.zip"
    @portfolio = Eportfolio.find(params[:eportfolio_id])
    if authorized_action(@portfolio, @current_user, :update)
      @attachments = @portfolio.attachments.where(display_name: zip_filename, workflow_state: ['to_be_zipped', 'zipping', 'zipped', 'unattached']).order(:created_at).to_a
      @attachment = @attachments.pop
      @attachments.each{|a| a.destroy! }
      if @attachment && (@attachment.created_at < 1.hour.ago || @attachment.created_at < (@portfolio.eportfolio_entries.map{|s| s.updated_at}.compact.max || @attachment.created_at))
        @attachment.destroy!
        @attachment = nil
      end

      if !@attachment
        @attachment = @portfolio.attachments.build(:display_name => zip_filename)
        @attachment.workflow_state = 'to_be_zipped'
        @attachment.file_state = '0'
        @attachment.save!
        ContentZipper.send_later_enqueue_args(:process_attachment, { :priority => Delayed::LOW_PRIORITY, :max_attempts => 1 }, @attachment)
        render :json => @attachment
      else
        respond_to do |format|
          if @attachment.zipped?
            if Attachment.s3_storage?
              format.html { redirect_to @attachment.cacheable_s3_inline_url }
              format.zip { redirect_to @attachment.cacheable_s3_inline_url }
            else
              cancel_cache_buster
              format.html { send_file(@attachment.full_filename, :type => @attachment.content_type_with_encoding, :disposition => 'inline') }
              format.zip { send_file(@attachment.full_filename, :type => @attachment.content_type_with_encoding, :disposition => 'inline') }
            end
            format.json { render :json => @attachment.as_json(:methods => :readable_size) }
          else
            flash[:notice] = t('notices.zipping', "File zipping still in process...")
            format.html { redirect_to eportfolio_url(@portfolio.id) }
            format.zip { redirect_to eportfolio_url(@portfolio.id) }
            format.json { render :json => @attachment }
          end
        end
      end
    end
  end
  
  def public_feed
    @portfolio = Eportfolio.find(params[:eportfolio_id])
    if @portfolio.public || params[:verifier] == @portfolio.uuid
      @entries = @portfolio.eportfolio_entries.order('eportfolio_entries.created_at DESC').all
      feed = Atom::Feed.new do |f|
        f.title = t(:title, "%{portfolio_name} Feed", :portfolio_name => @portfolio.name)
        f.links << Atom::Link.new(:href => eportfolio_url(@portfolio.id), :rel => 'self')
        f.updated = @entries.first.updated_at rescue Time.now
        f.id = eportfolio_url(@portfolio.id)
      end
      @entries.each do |e|
        feed.entries << e.to_atom(:private => params[:verifier] == @portfolio.uuid)
      end
      respond_to do |format|
        format.atom { render :text => feed.to_xml }
      end
    else
      authorized_action(nil, nil, :bad_permission)
    end
  end
end
