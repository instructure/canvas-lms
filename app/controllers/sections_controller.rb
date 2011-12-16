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

class SectionsController < ApplicationController
  before_filter :require_context
  
  def create
    if authorized_action(@context.course_sections.new, @current_user, :create)
      @section = @context.course_sections.build(params[:course_section])
      respond_to do |format|
        if @section.save
          flash[:notice] = t('section_created', "Section successfully created!")
          format.html { redirect_to course_settings_url(@context) }
          format.json { render :json => @section.to_json }
        else
          flash[:error] = t('section_creation_failed', "Section creation failed")
          format.html { redirect_to course_settings_url(@context) }
          format.json { render :json => @section.errors.to_json, :status => :bad_request }
        end
      end
    end
  end
  
  def crosslist_check
    @section = @context.course_sections.find(params[:section_id])
    course_id = params[:new_course_id]
    # cross-listing should only be allowed within the same root account
    @new_course = @section.root_account.all_courses.find_by_id(course_id) if course_id.present?
    @new_course ||= @section.root_account.all_courses.find_by_sis_source_id(course_id) if course_id.present?
    allowed = @new_course && @section.grants_right?(@current_user, session, :update) && @new_course.grants_right?(@current_user, session, :manage_admin_users)
    res = {:allowed => !!allowed}
    if allowed
      @account = @new_course.account
      res[:section] = @section
      res[:course] = @new_course
      res[:account] = @account
    end
    render :json => res.to_json(:include_root => false)
  end
  
  def crosslist
    @section = @context.course_sections.find(params[:section_id])
    course_id = params[:new_course_id]
    @new_course = Course.find_by_id(course_id) if course_id.present?
    if authorized_action(@section, @current_user, :update) && authorized_action(@new_course, @current_user, :manage)
      @section.crosslist_to_course @new_course
      respond_to do |format|
        flash[:notice] = t('section_crosslisted', "Section successfully cross-listed!")
        format.html { redirect_to named_context_url(@new_course, :context_section_url, @section.id) }
        format.json { render :json => @section.to_json }
      end
    end
  end
  
  def uncrosslist
    @section = @context.course_sections.find(params[:section_id])
    @new_course = @section.nonxlist_course
    if authorized_action(@section, @current_user, :update) && authorized_action(@new_course, @current_user, :manage)
      @section.uncrosslist
      respond_to do |format|
        flash[:notice] = t('section_decrosslisted', "Section successfully de-cross-listed!")
        format.html { redirect_to named_context_url(@new_course, :context_section_url, @section.id) }
        format.json { render :json => @section.to_json }
      end
    end
  end
  
  def update
    @section = @context.course_sections.find(params[:id])
    if authorized_action(@section, @current_user, :update)
      if sis_id = params[:course_section].delete(:sis_source_id)
        if sis_id != @section.sis_source_id && @section.root_account.grants_right?(@current_user, session, :manage_sis)
          if sis_id == ''
            @section.sis_source_id = nil
          else
            @section.sis_source_id = sis_id
          end
        end
      end
      respond_to do |format|
        if @section.update_attributes(params[:course_section])
          flash[:notice] = t('section_updated', "Section successfully updated!")
          format.html { redirect_to course_section_url(@context, @section) }
          format.json { render :json => @section.to_json }
        else
          flash[:error] = t('section_update_error', "Section update failed")
          format.html { redirect_to course_section_url(@context, @section) }
          format.json { render :json => @section.errors.to_json, :status => :bad_request }
        end
      end
    end
  end
  
  def show
    @section = @context.course_sections.find(params[:id])
    if authorized_action(@section, @current_user, :read)
      add_crumb(@section.name, named_context_url(@context, :context_section_url, @section))
      @enrollments = @section.enrollments.sort_by{|e| e.user.sortable_name.downcase }
      @student_enrollments = @enrollments.select{|e| e.student? }
      @current_enrollments = @enrollments.select{|e| !e.completed? }
      @completed_enrollments = @enrollments.select{|e| e.completed? }
    end
  end
  
  def destroy
    @section = @context.course_sections.find(params[:id])
    if authorized_action(@section, @current_user, :delete)
      respond_to do |format|
        if @section.enrollments.empty?
          @section.destroy
          flash[:notice] = t('section_deleted', "Course section successfully deleted!")
          format.html { redirect_to course_settings_url(@context) }
          format.json { render :json => @section.to_json }
        else
          flash[:error] = t('section_delete_not_allowed', "You can't delete a section that has enrollments")
          format.html { redirect_to course_section_url(@context, @section) }
          format.json { render :json => @section.to_json, :status => :bad_request  }
        end
      end
    end
  end
  
  
end
