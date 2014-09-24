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

class UserNotesController < ApplicationController
  def index
    @user = params[:user_id] ? User.find(params[:user_id]) : nil
    if authorized_action(@user, @current_user, :read_user_notes)
      @can_delete_user_notes = @user.grants_right?(@current_user, session, :delete_user_notes)
      @user_note = UserNote.new
      @user_notes = @user.user_notes.active.desc_by_date
      @user_notes = @user_notes.paginate(:page => params[:page], :per_page => 20)
      if request.xhr?
        render :partial => @user_notes
      end
    end
  end
  
   def user_notes
    get_context
    return render_unauthorized_action unless @context.root_account.enable_user_notes
    if authorized_action(@context, @current_user, :manage_user_notes)
      if @context && @context.is_a?(Account)
        @users = @context.all_users.active.has_current_student_enrollments
      else #it's a course
        @users = @context.students_visible_to(@current_user).order_by_sortable_name
        @is_course = true
      end
      count = @users.count
      @users = @users.select("name, users.id, last_user_note").order("last_user_note").order_by_sortable_name
      @users = @users.paginate(:page => params[:page], :per_page => 20, :total_entries=>count)
      # rails gets confused by :include => :courses, because has_current_student_enrollments above references courses in a subquery
      ActiveRecord::Associations::Preloader.new(@users, :courses).run
    end
  end

  def show
    @user_note = UserNote.where(id: params[:id]).first
    if authorized_action(@user_note, @current_user, :read)
      respond_to do |format|
        format.html { redirect_to user_user_notes_path }
        format.json { render :json => @user_note.as_json(:methods=>[:creator_name]), :status => :created }
        format.text { render :json => @user_note, :status => :created }
      end
    end
  end

  def create
    params[:user_note] = {} unless params[:user_note].is_a? Hash
    params[:user_note][:user] = User.where(id: params[:user_note].delete(:user_id)).first if params[:user_note][:user_id]
    params[:user_note][:user] ||= User.where(id: params[:user_id]).first
    # We want notes to be an html field, but we're only using a plaintext box for now. That's why we're
    # doing the trip to html now, instead of on the way out. This should be removed once the user notes
    # entry form is replaced with the rich text editor.
    self.extend TextHelper
    params[:user_note][:note] = format_message(params[:user_note][:note]).first if params[:user_note][:note]
    @user_note = UserNote.new(params[:user_note])
    @user_note.creator = @current_user
    
    if authorized_action(@user_note.user, @current_user, :create_user_notes)
      respond_to do |format|
        if @user_note.save
          flash[:notice] = t 'notices.created', "Journal Entry was successfully created."
          format.html { redirect_to user_user_notes_path }
          format.json { render :json => @user_note.as_json(:methods=>[:creator_name, :formatted_note]), :status => :created }
          format.text { render :json => @user_note, :status => :created }
        else
          format.html { redirect_to(user_user_notes_path) }
          format.json { render :json => @user_note.errors, :status => :bad_request }
          format.text { render :json => @user_note.errors, :status => :bad_request }
        end
      end
    end
  end

  def destroy
    @user_note = UserNote.find(params[:id])
    if authorized_action(@user_note, @current_user, :delete)
      @user_note.destroy

      respond_to do |format|
        format.html { redirect_to user_user_notes_path }
        format.json { render :json => @user_note.as_json(:methods=>[:creator_name]), :status => :ok }
      end 
    end
  end
end
